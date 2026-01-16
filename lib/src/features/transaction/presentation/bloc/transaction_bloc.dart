import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/transaction.dart' as model;
import '../../domain/repositories/transaction_repository.dart';
import 'transaction_event.dart';
import 'transaction_state.dart' as bloc_state;

/// BLoC for managing transaction flow.
/// 
/// Handles:
/// - Transaction submission with persistence
/// - OTP verification and automatic request resumption
/// - Timeout handling and retry
/// - Recovery of pending transactions on app restart
class TransactionBloc extends Bloc<TransactionEvent, bloc_state.TransactionState> {
  final TransactionRepository _repository;

  TransactionBloc({required TransactionRepository repository})
      : _repository = repository,
        super(bloc_state.TransactionInitial()) {
    on<SubmitTransaction>(_onSubmitTransaction);
    on<VerifyOtp>(_onVerifyOtp);
    on<CancelOtpVerification>(_onCancelOtpVerification);
    on<RetryTransaction>(_onRetryTransaction);
    on<CancelTransaction>(_onCancelTransaction);
    on<LoadPendingTransactions>(_onLoadPendingTransactions);
    on<LoadTransactionHistory>(_onLoadTransactionHistory);
    on<QueryTransactionStatus>(_onQueryTransactionStatus);
    on<ResetTransactionState>(_onResetTransactionState);
  }

  /// Submits a new transaction.
  Future<void> _onSubmitTransaction(
    SubmitTransaction event,
    Emitter<bloc_state.TransactionState> emit,
  ) async {
    emit(const bloc_state.TransactionSubmitting(transactionId: 'pending'));

    final result = await _repository.submitTransaction(
      amount: event.amount,
      recipient: event.recipient,
      description: event.description,
    );

    await result.fold(
      (failure) async {
        if (failure is RiskChallengeFailure) {
          await _loadAndEmitOtpRequired(failure, emit);
        } else if (failure is TimeoutFailure) {
          await _handleTimeoutFailure(failure, emit);
        } else {
          emit(bloc_state.TransactionFailed(
            transactionId: 'unknown',
            error: failure.message,
            canRetry: false,
          ));
        }
      },
      (success) async {
        emit(bloc_state.TransactionSuccess(
          transaction: success.transaction,
          serverTransactionId: success.serverTransactionId,
          message: success.message,
        ));
      },
    );
  }

  /// Verifies OTP and resumes original transaction.
  Future<void> _onVerifyOtp(
    VerifyOtp event,
    Emitter<bloc_state.TransactionState> emit,
  ) async {
    emit(bloc_state.TransactionVerifyingOtp(transactionId: event.transactionId));

    final result = await _repository.verifyOtpAndComplete(
      clientTransactionId: event.transactionId,
      otp: event.otp,
    );

    await result.fold(
      (failure) async {
        if (failure is OtpVerificationFailure) {
          emit(bloc_state.OtpVerificationFailed(
            transactionId: event.transactionId,
            error: failure.message,
            challengeType: model.RiskChallengeType.smsOtp,
          ));
        } else if (failure is RiskChallengeFailure) {
          await _loadAndEmitOtpRequired(failure, emit);
        } else if (failure is TimeoutFailure) {
          await _handleTimeoutFailure(failure, emit);
        } else {
          emit(bloc_state.TransactionFailed(
            transactionId: event.transactionId,
            error: failure.message,
            canRetry: true,
          ));
        }
      },
      (success) async {
        emit(bloc_state.TransactionSuccess(
          transaction: success.transaction,
          serverTransactionId: success.serverTransactionId,
          message: success.message,
        ));
      },
    );
  }

  /// Cancels OTP verification.
  Future<void> _onCancelOtpVerification(
    CancelOtpVerification event,
    Emitter<bloc_state.TransactionState> emit,
  ) async {
    await _repository.cancelTransaction(event.transactionId);
    emit(bloc_state.TransactionInitial());
  }

  /// Retries a failed or timed-out transaction.
  Future<void> _onRetryTransaction(
    RetryTransaction event,
    Emitter<bloc_state.TransactionState> emit,
  ) async {
    emit(bloc_state.TransactionSubmitting(transactionId: event.transactionId));

    final result = await _repository.retryTransaction(event.transactionId);

    await result.fold(
      (failure) async {
        if (failure is RiskChallengeFailure) {
          await _loadAndEmitOtpRequired(failure, emit);
        } else if (failure is TimeoutFailure) {
          await _handleTimeoutFailure(failure, emit);
        } else {
          emit(bloc_state.TransactionFailed(
            transactionId: event.transactionId,
            error: failure.message,
            canRetry: true,
          ));
        }
      },
      (success) async {
        emit(bloc_state.TransactionSuccess(
          transaction: success.transaction,
          serverTransactionId: success.serverTransactionId,
          message: success.message,
        ));
      },
    );
  }

  /// Cancels a pending transaction.
  Future<void> _onCancelTransaction(
    CancelTransaction event,
    Emitter<bloc_state.TransactionState> emit,
  ) async {
    await _repository.cancelTransaction(event.transactionId);
    emit(bloc_state.TransactionInitial());
  }

  /// Loads pending transactions for recovery.
  Future<void> _onLoadPendingTransactions(
    LoadPendingTransactions event,
    Emitter<bloc_state.TransactionState> emit,
  ) async {
    emit(const bloc_state.TransactionLoading(message: 'Checking for pending transactions...'));

    final pending = await _repository.getPendingTransactions();
    final awaitingOtp = await _repository.getAwaitingOtpTransactions();

    emit(bloc_state.PendingTransactionsLoaded(
      pendingTransactions: pending,
      awaitingOtpTransactions: awaitingOtp,
    ));
  }

  /// Loads transaction history.
  Future<void> _onLoadTransactionHistory(
    LoadTransactionHistory event,
    Emitter<bloc_state.TransactionState> emit,
  ) async {
    emit(const bloc_state.TransactionLoading(message: 'Loading history...'));

    final transactions = await _repository.getTransactionHistory();

    emit(bloc_state.TransactionHistoryLoaded(transactions: transactions));
  }

  /// Queries server for transaction status.
  Future<void> _onQueryTransactionStatus(
    QueryTransactionStatus event,
    Emitter<bloc_state.TransactionState> emit,
  ) async {
    emit(const bloc_state.TransactionLoading(message: 'Checking transaction status...'));

    final result = await _repository.queryTransactionStatus(event.transactionId);

    result.fold(
      (failure) {
        emit(bloc_state.TransactionFailed(
          transactionId: event.transactionId,
          error: failure.message,
          canRetry: true,
        ));
      },
      (success) {
        emit(bloc_state.TransactionSuccess(
          transaction: success.transaction,
          serverTransactionId: success.serverTransactionId,
          message: success.message,
        ));
      },
    );
  }

  /// Resets to initial state.
  Future<void> _onResetTransactionState(
    ResetTransactionState event,
    Emitter<bloc_state.TransactionState> emit,
  ) async {
    emit(bloc_state.TransactionInitial());
  }

  /// Helper to handle timeout failures.
  Future<void> _handleTimeoutFailure(
    TimeoutFailure failure,
    Emitter<bloc_state.TransactionState> emit,
  ) async {
    final pending = await _repository.getPendingTransactions();
    final timedOut = pending.where((t) => t.state == model.TransactionState.timeout).toList();
    
    if (timedOut.isNotEmpty) {
      emit(bloc_state.TransactionTimeout(
        transactionId: timedOut.first.clientTransactionId,
        message: failure.message,
        transaction: timedOut.first,
      ));
    } else {
      emit(bloc_state.TransactionFailed(
        transactionId: 'unknown',
        error: failure.message,
        canRetry: true,
      ));
    }
  }

  /// Helper to load and emit OTP required state.
  Future<void> _loadAndEmitOtpRequired(
    RiskChallengeFailure failure,
    Emitter<bloc_state.TransactionState> emit,
  ) async {
    final transaction = await _repository.getTransaction(failure.transactionId);
    
    if (transaction != null) {
      emit(bloc_state.TransactionOtpRequired(
        transactionId: failure.transactionId,
        challengeType: failure.challengeType,
        transaction: transaction,
      ));
    } else {
      emit(bloc_state.TransactionFailed(
        transactionId: failure.transactionId,
        error: 'Transaction not found',
        canRetry: false,
      ));
    }
  }
}
