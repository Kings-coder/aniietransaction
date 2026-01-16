import 'dart:async';

import 'package:dio/dio.dart';

import '../../features/transaction/domain/models/transaction.dart';

/// Callback type for when a risk challenge is triggered.
typedef RiskChallengeCallback = Future<String?> Function(
  String transactionId,
  RiskChallengeType challengeType,
);

/// Dio Interceptor that handles 403 RISK_CHALLENGE_REQUIRED responses.
/// 
/// When a 403 is received:
/// 1. Extracts the challenge type from the response
/// 2. Triggers the callback to show OTP dialog
/// 3. Waits for OTP verification
/// 4. Retries the ORIGINAL request automatically
/// 
/// Key design: Uses Completer to pause the request chain until OTP is verified.
class RiskInterceptor extends Interceptor {
  /// Callback invoked when risk challenge is required.
  /// Should return the OTP if verified, null if cancelled.
  RiskChallengeCallback? onRiskChallenge;
  
  /// Stores pending requests waiting for OTP verification.
  /// Maps transactionId -> (RequestOptions, Completer)
  final Map<String, _PendingRequest> _pendingRequests = {};

  RiskInterceptor({this.onRiskChallenge});

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Check for 403 with risk challenge
    if (response.statusCode == 403) {
      final data = response.data;
      
      if (data is Map && data['riskChallengeRequired'] == true) {
        _handleRiskChallenge(response, handler);
        return;
      }
    }
    
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle 403 error responses
    if (err.response?.statusCode == 403) {
      final data = err.response?.data;
      
      if (data is Map && data['riskChallengeRequired'] == true) {
        _handleRiskChallengeError(err, handler);
        return;
      }
    }
    
    handler.next(err);
  }

  Future<void> _handleRiskChallenge(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    if (onRiskChallenge == null) {
      handler.next(response);
      return;
    }

    final requestOptions = response.requestOptions;
    final transactionId = _extractTransactionId(requestOptions);
    final challengeType = _extractChallengeType(response.data);

    // Store the pending request
    final completer = Completer<Response>();
    _pendingRequests[transactionId] = _PendingRequest(
      options: requestOptions,
      completer: completer,
      originalResponse: response,
    );

    try {
      // Trigger OTP dialog and wait for result
      final otp = await onRiskChallenge!(transactionId, challengeType);

      if (otp != null && otp.isNotEmpty) {
        // OTP provided - retry the original request
        final dio = Dio();
        
        // Add OTP header to the retry request
        requestOptions.headers['X-OTP-Token'] = otp;
        requestOptions.headers['X-Risk-Verified'] = 'true';
        
        try {
          final retryResponse = await dio.fetch(requestOptions);
          _pendingRequests.remove(transactionId);
          handler.next(retryResponse);
        } catch (retryError) {
          _pendingRequests.remove(transactionId);
          if (retryError is DioException) {
            handler.reject(retryError);
          } else {
            handler.next(response);
          }
        }
      } else {
        // User cancelled - return original 403 response
        _pendingRequests.remove(transactionId);
        handler.next(response);
      }
    } catch (e) {
      _pendingRequests.remove(transactionId);
      handler.next(response);
    }
  }

  Future<void> _handleRiskChallengeError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (onRiskChallenge == null || err.response == null) {
      handler.next(err);
      return;
    }

    final requestOptions = err.requestOptions;
    final transactionId = _extractTransactionId(requestOptions);
    final challengeType = _extractChallengeType(err.response?.data);

    try {
      final otp = await onRiskChallenge!(transactionId, challengeType);

      if (otp != null && otp.isNotEmpty) {
        final dio = Dio();
        
        requestOptions.headers['X-OTP-Token'] = otp;
        requestOptions.headers['X-Risk-Verified'] = 'true';
        
        try {
          final retryResponse = await dio.fetch(requestOptions);
          handler.resolve(retryResponse);
        } catch (retryError) {
          if (retryError is DioException) {
            handler.next(retryError);
          } else {
            handler.next(err);
          }
        }
      } else {
        handler.next(err);
      }
    } catch (e) {
      handler.next(err);
    }
  }

  /// Extracts transaction ID from request options.
  String _extractTransactionId(RequestOptions options) {
    // Try to get from request data
    if (options.data is Map) {
      return options.data['clientTransactionId'] ?? 'unknown';
    }
    // Fallback to query params or generate
    return options.queryParameters['txId'] ?? 'unknown-${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Extracts challenge type from response data.
  RiskChallengeType _extractChallengeType(dynamic data) {
    if (data is Map) {
      final type = data['challengeType']?.toString().toUpperCase();
      switch (type) {
        case 'SMS_OTP':
          return RiskChallengeType.smsOtp;
        case 'EMAIL_OTP':
          return RiskChallengeType.emailOtp;
        default:
          return RiskChallengeType.unknown;
      }
    }
    return RiskChallengeType.smsOtp; // Default
  }

  /// Manually complete a pending request (for testing or external verification).
  void completeVerification(String transactionId, String otp) {
    // This could be used if OTP verification happens externally
    _pendingRequests.remove(transactionId);
  }

  /// Cancel a pending verification.
  void cancelVerification(String transactionId) {
    _pendingRequests.remove(transactionId);
  }

  /// Check if there are pending verifications.
  bool get hasPendingVerifications => _pendingRequests.isNotEmpty;

  /// Get list of pending transaction IDs.
  List<String> get pendingTransactionIds => _pendingRequests.keys.toList();
}

/// Internal class to track pending requests.
class _PendingRequest {
  final RequestOptions options;
  final Completer<Response> completer;
  final Response originalResponse;

  _PendingRequest({
    required this.options,
    required this.completer,
    required this.originalResponse,
  });
}
