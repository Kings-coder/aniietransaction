import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import 'amount.dart';

/// Represents the lifecycle state of a transaction.
/// 
/// State transitions:
/// CREATED → PENDING → COMPLETED/FAILED
/// PENDING → AWAITING_OTP → PENDING (after OTP verified) → COMPLETED/FAILED
/// PENDING → TIMEOUT → PENDING (on retry) → COMPLETED/FAILED
enum TransactionState {
  /// Transaction created locally, not yet sent to server
  created,
  
  /// Sent to server, awaiting response
  pending,
  
  /// Server returned 403, waiting for OTP verification
  awaitingOtp,
  
  /// Transaction completed successfully
  completed,
  
  /// Transaction failed (non-recoverable)
  failed,
  
  /// Server returned 504 timeout, eligible for retry
  timeout,
  
  /// User cancelled the transaction
  cancelled,
}

/// Risk challenge type returned by server on 403
enum RiskChallengeType {
  smsOtp,
  emailOtp,
  unknown,
}

/// Represents a financial transaction with full state tracking.
/// 
/// Key design decisions:
/// 1. clientTransactionId is generated CLIENT-SIDE for idempotency
/// 2. State persisted BEFORE network call for crash recovery
/// 3. Immutable - creates new instance on state change
class Transaction extends Equatable {
  /// Unique identifier generated client-side (UUID v4)
  /// Used by server for idempotency - prevents duplicate debits
  final String clientTransactionId;
  
  /// The monetary amount (stored as integer cents)
  final Amount amount;
  
  /// Current state in the transaction lifecycle
  final TransactionState state;
  
  /// Server-assigned transaction ID (if available)
  final String? serverTransactionId;
  
  /// When the transaction was created locally
  final DateTime createdAt;
  
  /// When the transaction state was last updated
  final DateTime updatedAt;
  
  /// Number of retry attempts
  final int retryCount;
  
  /// Type of risk challenge if state is AWAITING_OTP
  final RiskChallengeType? challengeType;
  
  /// Error message if state is FAILED
  final String? errorMessage;
  
  /// Recipient identifier (for demo purposes)
  final String? recipient;
  
  /// Description/note for the transaction
  final String? description;

  const Transaction._({
    required this.clientTransactionId,
    required this.amount,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
    this.serverTransactionId,
    this.retryCount = 0,
    this.challengeType,
    this.errorMessage,
    this.recipient,
    this.description,
  });

  /// Creates a new transaction with CREATED state
  factory Transaction.create({
    required Amount amount,
    String? recipient,
    String? description,
  }) {
    final now = DateTime.now();
    return Transaction._(
      clientTransactionId: const Uuid().v4(),
      amount: amount,
      state: TransactionState.created,
      createdAt: now,
      updatedAt: now,
      recipient: recipient,
      description: description,
    );
  }

  /// Creates a copy with updated state
  Transaction copyWith({
    TransactionState? state,
    String? serverTransactionId,
    int? retryCount,
    RiskChallengeType? challengeType,
    String? errorMessage,
  }) {
    return Transaction._(
      clientTransactionId: clientTransactionId,
      amount: amount,
      state: state ?? this.state,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      serverTransactionId: serverTransactionId ?? this.serverTransactionId,
      retryCount: retryCount ?? this.retryCount,
      challengeType: challengeType ?? this.challengeType,
      errorMessage: errorMessage ?? this.errorMessage,
      recipient: recipient,
      description: description,
    );
  }

  /// State transition helpers
  Transaction markAsPending() => copyWith(state: TransactionState.pending);
  
  Transaction markAsAwaitingOtp(RiskChallengeType challenge) => copyWith(
    state: TransactionState.awaitingOtp,
    challengeType: challenge,
  );
  
  Transaction markAsCompleted({String? serverTxId}) => copyWith(
    state: TransactionState.completed,
    serverTransactionId: serverTxId,
  );
  
  Transaction markAsFailed(String error) => copyWith(
    state: TransactionState.failed,
    errorMessage: error,
  );
  
  Transaction markAsTimeout() => copyWith(state: TransactionState.timeout);
  
  Transaction markAsCancelled() => copyWith(state: TransactionState.cancelled);
  
  Transaction incrementRetry() => copyWith(retryCount: retryCount + 1);

  /// Returns true if transaction can be retried
  bool get canRetry => state == TransactionState.timeout || 
                       state == TransactionState.awaitingOtp;

  /// Returns true if transaction is in a final state
  bool get isFinal => state == TransactionState.completed || 
                      state == TransactionState.failed ||
                      state == TransactionState.cancelled;

  /// Returns true if transaction needs user action
  bool get needsUserAction => state == TransactionState.awaitingOtp ||
                              state == TransactionState.timeout;

  /// JSON serialization
  Map<String, dynamic> toJson() => {
    'clientTransactionId': clientTransactionId,
    'amount': amount.toJson(),
    'state': state.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'serverTransactionId': serverTransactionId,
    'retryCount': retryCount,
    'challengeType': challengeType?.name,
    'errorMessage': errorMessage,
    'recipient': recipient,
    'description': description,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction._(
      clientTransactionId: json['clientTransactionId'] as String,
      amount: Amount.fromJson(json['amount'] as Map<String, dynamic>),
      state: TransactionState.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => TransactionState.created,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      serverTransactionId: json['serverTransactionId'] as String?,
      retryCount: json['retryCount'] as int? ?? 0,
      challengeType: json['challengeType'] != null
          ? RiskChallengeType.values.firstWhere(
              (e) => e.name == json['challengeType'],
              orElse: () => RiskChallengeType.unknown,
            )
          : null,
      errorMessage: json['errorMessage'] as String?,
      recipient: json['recipient'] as String?,
      description: json['description'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    clientTransactionId,
    amount,
    state,
    createdAt,
    updatedAt,
    serverTransactionId,
    retryCount,
    challengeType,
    errorMessage,
    recipient,
    description,
  ];

  @override
  String toString() => 'Transaction(id: $clientTransactionId, amount: ${amount.toDisplayString()}, state: ${state.name})';
}
