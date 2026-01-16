import 'dart:async';
import 'dart:math';

/// Mock API service that simulates real server behavior.
/// 
/// Returns random responses to test different scenarios:
/// - 200 SUCCESS (60%)
/// - 504 TIMEOUT (20%)
/// - 403 RISK_CHALLENGE_REQUIRED (20%)
class MockApiService {
  final Random _random = Random();
  
  // Track processed transaction IDs for idempotency demo
  final Map<String, MockApiResponse> _processedTransactions = {};

  /// Simulates submitting a transaction to the server.
  /// 
  /// If the same clientTransactionId is sent again, returns the original
  /// cached response (demonstrates idempotency).
  Future<MockApiResponse> submitTransaction({
    required String clientTransactionId,
    required int amountCents,
    String? recipient,
  }) async {
    // Simulate network delay (500-2000ms)
    await Future.delayed(
      Duration(milliseconds: 500 + _random.nextInt(1500)),
    );

    // Check if we've already processed this transaction (idempotency)
    if (_processedTransactions.containsKey(clientTransactionId)) {
      // Return cached response - prevents duplicate processing
      return _processedTransactions[clientTransactionId]!;
    }

    // Generate random response
    final roll = _random.nextDouble();
    
    MockApiResponse response;
    
    if (roll < 0.60) {
      // 60% - Success
      response = MockApiResponse(
        statusCode: 200,
        success: true,
        serverTransactionId: 'SRV-${DateTime.now().millisecondsSinceEpoch}',
        message: 'Transaction processed successfully',
      );
    } else if (roll < 0.80) {
      // 20% - Timeout
      response = MockApiResponse(
        statusCode: 504,
        success: false,
        message: 'Gateway Timeout - Please retry',
      );
    } else {
      // 20% - Risk challenge required
      response = MockApiResponse(
        statusCode: 403,
        success: false,
        riskChallengeRequired: true,
        challengeType: 'SMS_OTP',
        message: 'Risk verification required',
      );
    }

    // Cache successful responses for idempotency
    if (response.statusCode == 200) {
      _processedTransactions[clientTransactionId] = response;
    }

    return response;
  }

  /// Simulates OTP verification.
  /// 
  /// In a real system, this would validate the OTP with the server.
  /// For demo, accepts "123456" as valid OTP.
  Future<MockApiResponse> verifyOtp({
    required String clientTransactionId,
    required String otp,
  }) async {
    // Simulate network delay
    await Future.delayed(
      Duration(milliseconds: 300 + _random.nextInt(500)),
    );

    // Accept "123456" as valid OTP for demo
    if (otp == '123456') {
      return MockApiResponse(
        statusCode: 200,
        success: true,
        message: 'OTP verified successfully',
      );
    } else {
      return MockApiResponse(
        statusCode: 401,
        success: false,
        message: 'Invalid OTP. Please try again.',
      );
    }
  }

  /// Queries the server for transaction status.
  /// 
  /// Used for recovery when transaction state is unknown.
  Future<MockApiResponse> queryTransactionStatus({
    required String clientTransactionId,
  }) async {
    // Simulate network delay
    await Future.delayed(
      Duration(milliseconds: 200 + _random.nextInt(300)),
    );

    if (_processedTransactions.containsKey(clientTransactionId)) {
      return _processedTransactions[clientTransactionId]!;
    }

    // Transaction not found on server
    return MockApiResponse(
      statusCode: 404,
      success: false,
      message: 'Transaction not found',
    );
  }

  /// Clears cached transactions (for testing).
  void clearCache() {
    _processedTransactions.clear();
  }
}

/// Response model from mock API.
class MockApiResponse {
  final int statusCode;
  final bool success;
  final String? serverTransactionId;
  final String? message;
  final bool riskChallengeRequired;
  final String? challengeType;

  MockApiResponse({
    required this.statusCode,
    required this.success,
    this.serverTransactionId,
    this.message,
    this.riskChallengeRequired = false,
    this.challengeType,
  });

  Map<String, dynamic> toJson() => {
    'statusCode': statusCode,
    'success': success,
    'serverTransactionId': serverTransactionId,
    'message': message,
    'riskChallengeRequired': riskChallengeRequired,
    'challengeType': challengeType,
  };

  @override
  String toString() => 'MockApiResponse(status: $statusCode, success: $success, message: $message)';
}
