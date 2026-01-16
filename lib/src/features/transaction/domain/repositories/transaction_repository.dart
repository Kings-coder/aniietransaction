import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../data/datasources/mock_api_service.dart';
import '../../data/datasources/transaction_storage.dart';
import '../models/amount.dart';
import '../models/transaction.dart';


/// Failure types for transaction operations.
abstract class TransactionFailure {
  final String message;
  const TransactionFailure(this.message);
}

class NetworkFailure extends TransactionFailure {
  const NetworkFailure(super.message);
}

class TimeoutFailure extends TransactionFailure {
  const TimeoutFailure(super.message);
}

class RiskChallengeFailure extends TransactionFailure {
  final String transactionId;
  final RiskChallengeType challengeType;
  
  const RiskChallengeFailure(
    super.message, {
    required this.transactionId,
    required this.challengeType,
  });
}

class ValidationFailure extends TransactionFailure {
  const ValidationFailure(super.message);
}

class OtpVerificationFailure extends TransactionFailure {
  const OtpVerificationFailure(super.message);
}

/// Result wrapper for successful transactions.
class TransactionResult {
  final Transaction transaction;
  final String? serverTransactionId;
  final String message;

  TransactionResult({
    required this.transaction,
    this.serverTransactionId,
    this.message = 'Success',
  });
}

/// Repository for managing transaction operations.
/// 
/// Key responsibilities:
/// 1. Generate client_transaction_id for idempotency
/// 2. Persist transaction BEFORE network call (crash recovery)
/// 3. Handle all response scenarios (200, 403, 504)
/// 4. Update transaction state after each operation
class TransactionRepository {
  final MockApiService _apiService;
  final TransactionStorage _storage;
  
  // Stream controller for transaction state changes
  final _transactionStateController = StreamController<Transaction>.broadcast();
  
  // Stream controller for risk challenge events
  final _riskChallengeController = StreamController<RiskChallengeFailure>.broadcast();

  TransactionRepository({
    required MockApiService apiService,
    required TransactionStorage storage,
  })  : _apiService = apiService,
        _storage = storage;

  /// Stream of transaction state changes.
  Stream<Transaction> get transactionStateStream => _transactionStateController.stream;
  
  /// Stream of risk challenge events.
  Stream<RiskChallengeFailure> get riskChallengeStream => _riskChallengeController.stream;

  /// Submits a new transaction.
  /// 
  /// Flow:
  /// 1. Create transaction with PENDING state
  /// 2. PERSIST to storage (critical for crash recovery)
  /// 3. Send to API
  /// 4. Handle response and update state
  Future<Either<TransactionFailure, TransactionResult>> submitTransaction({
    required Amount amount,
    String? recipient,
    String? description,
  }) async {
    // Validate amount
    if (amount.cents <= 0) {
      return Left(ValidationFailure('Amount must be greater than zero'));
    }

    // 1. Create transaction with client-generated ID
    final transaction = Transaction.create(
      amount: amount,
      recipient: recipient,
      description: description,
    ).markAsPending();

    // 2. PERSIST BEFORE sending - critical for crash recovery
    await _storage.saveTransaction(transaction);
    _transactionStateController.add(transaction);

    // 3. Send to API
    return _executeTransaction(transaction);
  }

  /// Retries a failed or timed-out transaction.
  Future<Either<TransactionFailure, TransactionResult>> retryTransaction(
    String clientTransactionId,
  ) async {
    final transaction = await _storage.getTransaction(clientTransactionId);
    
    if (transaction == null) {
      return Left(ValidationFailure('Transaction not found'));
    }

    if (!transaction.canRetry) {
      return Left(ValidationFailure('Transaction cannot be retried'));
    }

    // Increment retry count and update state
    final updated = transaction.incrementRetry().markAsPending();
    await _storage.saveTransaction(updated);
    _transactionStateController.add(updated);

    return _executeTransaction(updated);
  }

  /// Executes the API call for a transaction.
  Future<Either<TransactionFailure, TransactionResult>> _executeTransaction(
    Transaction transaction,
  ) async {
    try {
      final response = await _apiService.submitTransaction(
        clientTransactionId: transaction.clientTransactionId,
        amountCents: transaction.amount.cents,
        recipient: transaction.recipient,
      );

      if (response.statusCode == 200 && response.success) {
        // SUCCESS - Update to completed
        final completed = transaction.markAsCompleted(
          serverTxId: response.serverTransactionId,
        );
        await _storage.saveTransaction(completed);
        _transactionStateController.add(completed);

        return Right(TransactionResult(
          transaction: completed,
          serverTransactionId: response.serverTransactionId,
          message: response.message ?? 'Transaction successful',
        ));
      } else if (response.statusCode == 504) {
        // TIMEOUT - Mark as timeout for retry
        final timedOut = transaction.markAsTimeout();
        await _storage.saveTransaction(timedOut);
        _transactionStateController.add(timedOut);

        return Left(TimeoutFailure(
          response.message ?? 'Request timed out. Please retry.',
        ));
      } else if (response.statusCode == 403 && response.riskChallengeRequired) {
        // RISK CHALLENGE - Mark as awaiting OTP
        final challengeType = _parseChallengeType(response.challengeType);
        final awaitingOtp = transaction.markAsAwaitingOtp(challengeType);
        await _storage.saveTransaction(awaitingOtp);
        _transactionStateController.add(awaitingOtp);

        final failure = RiskChallengeFailure(
          response.message ?? 'Verification required',
          transactionId: transaction.clientTransactionId,
          challengeType: challengeType,
        );
        _riskChallengeController.add(failure);

        return Left(failure);
      } else {
        // Other failure
        final failed = transaction.markAsFailed(
          response.message ?? 'Transaction failed',
        );
        await _storage.saveTransaction(failed);
        _transactionStateController.add(failed);

        return Left(NetworkFailure(response.message ?? 'Transaction failed'));
      }
    } catch (e) {
      // Network error
      final failed = transaction.markAsFailed(e.toString());
      await _storage.saveTransaction(failed);
      _transactionStateController.add(failed);

      return Left(NetworkFailure('Network error: ${e.toString()}'));
    }
  }

  /// Verifies OTP and completes the pending transaction.
  Future<Either<TransactionFailure, TransactionResult>> verifyOtpAndComplete({
    required String clientTransactionId,
    required String otp,
  }) async {
    final transaction = await _storage.getTransaction(clientTransactionId);
    
    if (transaction == null) {
      return Left(ValidationFailure('Transaction not found'));
    }

    if (transaction.state != TransactionState.awaitingOtp) {
      return Left(ValidationFailure('Transaction is not awaiting OTP'));
    }

    // Verify OTP with API
    final otpResponse = await _apiService.verifyOtp(
      clientTransactionId: clientTransactionId,
      otp: otp,
    );

    if (!otpResponse.success) {
      return Left(OtpVerificationFailure(
        otpResponse.message ?? 'OTP verification failed',
      ));
    }

    // OTP verified - retry the original transaction
    final retrying = transaction.markAsPending();
    await _storage.saveTransaction(retrying);
    _transactionStateController.add(retrying);

    return _executeTransaction(retrying);
  }

  /// Cancels a pending transaction.
  Future<void> cancelTransaction(String clientTransactionId) async {
    final transaction = await _storage.getTransaction(clientTransactionId);
    
    if (transaction != null && !transaction.isFinal) {
      final cancelled = transaction.markAsCancelled();
      await _storage.saveTransaction(cancelled);
      _transactionStateController.add(cancelled);
    }
  }

  /// Gets all pending transactions (for recovery on app restart).
  Future<List<Transaction>> getPendingTransactions() {
    return _storage.getPendingTransactions();
  }

  /// Gets transactions awaiting OTP.
  Future<List<Transaction>> getAwaitingOtpTransactions() {
    return _storage.getAwaitingOtpTransactions();
  }

  /// Gets all transaction history.
  Future<List<Transaction>> getTransactionHistory() {
    return _storage.getAllTransactions();
  }

  /// Gets a specific transaction.
  Future<Transaction?> getTransaction(String clientTransactionId) {
    return _storage.getTransaction(clientTransactionId);
  }

  /// Queries server for transaction status (recovery scenario).
  Future<Either<TransactionFailure, TransactionResult>> queryTransactionStatus(
    String clientTransactionId,
  ) async {
    final transaction = await _storage.getTransaction(clientTransactionId);
    
    if (transaction == null) {
      return Left(ValidationFailure('Transaction not found locally'));
    }

    final response = await _apiService.queryTransactionStatus(
      clientTransactionId: clientTransactionId,
    );

    if (response.statusCode == 200 && response.success) {
      // Found on server - it was processed
      final completed = transaction.markAsCompleted(
        serverTxId: response.serverTransactionId,
      );
      await _storage.saveTransaction(completed);
      _transactionStateController.add(completed);

      return Right(TransactionResult(
        transaction: completed,
        serverTransactionId: response.serverTransactionId,
        message: 'Transaction was already processed',
      ));
    } else if (response.statusCode == 404) {
      // Not found on server - can be retried
      return Left(NetworkFailure('Transaction not found on server. You may retry.'));
    } else {
      return Left(NetworkFailure(response.message ?? 'Failed to query status'));
    }
  }

  RiskChallengeType _parseChallengeType(String? type) {
    switch (type?.toUpperCase()) {
      case 'SMS_OTP':
        return RiskChallengeType.smsOtp;
      case 'EMAIL_OTP':
        return RiskChallengeType.emailOtp;
      default:
        return RiskChallengeType.unknown;
    }
  }

  /// Cleanup resources.
  void dispose() {
    _transactionStateController.close();
    _riskChallengeController.close();
  }
}
