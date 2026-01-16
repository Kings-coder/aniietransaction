import 'package:equatable/equatable.dart';

import '../../domain/models/transaction.dart';

/// Base class for all transaction states.
abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

/// Initial state - ready to submit.
class TransactionInitial extends TransactionState {}

/// Submitting transaction to server.
class TransactionSubmitting extends TransactionState {
  final String transactionId;
  
  const TransactionSubmitting({required this.transactionId});
  
  @override
  List<Object?> get props => [transactionId];
}

/// OTP verification required.
class TransactionOtpRequired extends TransactionState {
  final String transactionId;
  final RiskChallengeType challengeType;
  final Transaction transaction;

  const TransactionOtpRequired({
    required this.transactionId,
    required this.challengeType,
    required this.transaction,
  });

  @override
  List<Object?> get props => [transactionId, challengeType, transaction];
}

/// Verifying OTP.
class TransactionVerifyingOtp extends TransactionState {
  final String transactionId;

  const TransactionVerifyingOtp({required this.transactionId});

  @override
  List<Object?> get props => [transactionId];
}

/// Transaction completed successfully.
class TransactionSuccess extends TransactionState {
  final Transaction transaction;
  final String? serverTransactionId;
  final String message;

  const TransactionSuccess({
    required this.transaction,
    this.serverTransactionId,
    required this.message,
  });

  @override
  List<Object?> get props => [transaction, serverTransactionId, message];
}

/// Transaction failed.
class TransactionFailed extends TransactionState {
  final String transactionId;
  final String error;
  final bool canRetry;

  const TransactionFailed({
    required this.transactionId,
    required this.error,
    this.canRetry = false,
  });

  @override
  List<Object?> get props => [transactionId, error, canRetry];
}

/// Transaction timed out - can retry.
class TransactionTimeout extends TransactionState {
  final String transactionId;
  final String message;
  final Transaction transaction;

  const TransactionTimeout({
    required this.transactionId,
    required this.message,
    required this.transaction,
  });

  @override
  List<Object?> get props => [transactionId, message, transaction];
}

/// OTP verification failed but can retry.
class OtpVerificationFailed extends TransactionState {
  final String transactionId;
  final String error;
  final RiskChallengeType challengeType;

  const OtpVerificationFailed({
    required this.transactionId,
    required this.error,
    required this.challengeType,
  });

  @override
  List<Object?> get props => [transactionId, error, challengeType];
}

/// Pending transactions loaded (for recovery).
class PendingTransactionsLoaded extends TransactionState {
  final List<Transaction> pendingTransactions;
  final List<Transaction> awaitingOtpTransactions;

  const PendingTransactionsLoaded({
    required this.pendingTransactions,
    required this.awaitingOtpTransactions,
  });

  bool get hasPendingTransactions => 
    pendingTransactions.isNotEmpty || awaitingOtpTransactions.isNotEmpty;

  @override
  List<Object?> get props => [pendingTransactions, awaitingOtpTransactions];
}

/// Transaction history loaded.
class TransactionHistoryLoaded extends TransactionState {
  final List<Transaction> transactions;

  const TransactionHistoryLoaded({required this.transactions});

  @override
  List<Object?> get props => [transactions];
}

/// Loading state for various operations.
class TransactionLoading extends TransactionState {
  final String? message;

  const TransactionLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// Error state.
class TransactionError extends TransactionState {
  final String message;

  const TransactionError({required this.message});

  @override
  List<Object?> get props => [message];
}
