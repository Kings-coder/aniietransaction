import 'package:equatable/equatable.dart';

import '../../domain/models/amount.dart';

/// Base class for all transaction events.
abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

/// Submit a new transaction.
class SubmitTransaction extends TransactionEvent {
  final Amount amount;
  final String? recipient;
  final String? description;

  const SubmitTransaction({
    required this.amount,
    this.recipient,
    this.description,
  });

  @override
  List<Object?> get props => [amount, recipient, description];
}

/// Verify OTP for a pending transaction.
class VerifyOtp extends TransactionEvent {
  final String transactionId;
  final String otp;

  const VerifyOtp({
    required this.transactionId,
    required this.otp,
  });

  @override
  List<Object?> get props => [transactionId, otp];
}

/// Cancel OTP verification.
class CancelOtpVerification extends TransactionEvent {
  final String transactionId;

  const CancelOtpVerification({required this.transactionId});

  @override
  List<Object?> get props => [transactionId];
}

/// Retry a failed or timed-out transaction.
class RetryTransaction extends TransactionEvent {
  final String transactionId;

  const RetryTransaction({required this.transactionId});

  @override
  List<Object?> get props => [transactionId];
}

/// Cancel a pending transaction.
class CancelTransaction extends TransactionEvent {
  final String transactionId;

  const CancelTransaction({required this.transactionId});

  @override
  List<Object?> get props => [transactionId];
}

/// Load pending transactions (for recovery on app start).
class LoadPendingTransactions extends TransactionEvent {}

/// Load transaction history.
class LoadTransactionHistory extends TransactionEvent {}

/// Query server for transaction status (recovery scenario).
class QueryTransactionStatus extends TransactionEvent {
  final String transactionId;

  const QueryTransactionStatus({required this.transactionId});

  @override
  List<Object?> get props => [transactionId];
}

/// Reset to initial state.
class ResetTransactionState extends TransactionEvent {}
