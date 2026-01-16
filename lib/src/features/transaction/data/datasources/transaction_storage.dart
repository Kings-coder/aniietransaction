import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/transaction.dart';

/// Local storage service for persisting transaction state.
/// 
/// Critical for crash recovery - transactions are saved BEFORE network calls
/// so we can detect and recover unresolved transactions on app restart.
class TransactionStorage {
  static const String _storageKey = 'pending_transactions';
  static const String _historyKey = 'transaction_history';
  
  final SharedPreferences _prefs;

  TransactionStorage(this._prefs);

  /// Saves a transaction to local storage.
  /// 
  /// MUST be called BEFORE sending the network request to ensure
  /// crash recovery is possible.
  Future<void> saveTransaction(Transaction transaction) async {
    final transactions = await getAllTransactions();
    
    // Update existing or add new
    final index = transactions.indexWhere(
      (t) => t.clientTransactionId == transaction.clientTransactionId,
    );
    
    if (index >= 0) {
      transactions[index] = transaction;
    } else {
      transactions.add(transaction);
    }
    
    await _saveAll(transactions);
  }

  /// Updates the state of an existing transaction.
  Future<void> updateTransactionState(
    String clientTransactionId,
    TransactionState state, {
    String? serverTransactionId,
    String? errorMessage,
    RiskChallengeType? challengeType,
  }) async {
    final transactions = await getAllTransactions();
    final index = transactions.indexWhere(
      (t) => t.clientTransactionId == clientTransactionId,
    );
    
    if (index >= 0) {
      Transaction updated = transactions[index];
      
      switch (state) {
        case TransactionState.pending:
          updated = updated.markAsPending();
          break;
        case TransactionState.awaitingOtp:
          updated = updated.markAsAwaitingOtp(
            challengeType ?? RiskChallengeType.smsOtp,
          );
          break;
        case TransactionState.completed:
          updated = updated.markAsCompleted(serverTxId: serverTransactionId);
          break;
        case TransactionState.failed:
          updated = updated.markAsFailed(errorMessage ?? 'Unknown error');
          break;
        case TransactionState.timeout:
          updated = updated.markAsTimeout();
          break;
        case TransactionState.cancelled:
          updated = updated.markAsCancelled();
          break;
        default:
          break;
      }
      
      transactions[index] = updated;
      await _saveAll(transactions);
    }
  }

  /// Retrieves a specific transaction by ID.
  Future<Transaction?> getTransaction(String clientTransactionId) async {
    final transactions = await getAllTransactions();
    try {
      return transactions.firstWhere(
        (t) => t.clientTransactionId == clientTransactionId,
      );
    } catch (_) {
      return null;
    }
  }

  /// Retrieves all pending/unresolved transactions.
  /// 
  /// Used on app startup to detect transactions that need recovery.
  Future<List<Transaction>> getPendingTransactions() async {
    final transactions = await getAllTransactions();
    return transactions.where((t) => !t.isFinal).toList();
  }

  /// Retrieves transactions awaiting OTP verification.
  Future<List<Transaction>> getAwaitingOtpTransactions() async {
    final transactions = await getAllTransactions();
    return transactions
        .where((t) => t.state == TransactionState.awaitingOtp)
        .toList();
  }

  /// Retrieves all transactions (including completed/failed).
  Future<List<Transaction>> getAllTransactions() async {
    final jsonString = _prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((j) => Transaction.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Corrupted data - clear and return empty
      await _prefs.remove(_storageKey);
      return [];
    }
  }

  /// Retrieves transaction history (completed transactions).
  Future<List<Transaction>> getTransactionHistory() async {
    final transactions = await getAllTransactions();
    return transactions.where((t) => t.isFinal).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Deletes a specific transaction.
  Future<void> deleteTransaction(String clientTransactionId) async {
    final transactions = await getAllTransactions();
    transactions.removeWhere(
      (t) => t.clientTransactionId == clientTransactionId,
    );
    await _saveAll(transactions);
  }

  /// Moves completed transactions to history and clears pending.
  Future<void> archiveCompletedTransactions() async {
    final transactions = await getAllTransactions();
    final completed = transactions.where((t) => t.isFinal).toList();
    final pending = transactions.where((t) => !t.isFinal).toList();
    
    // Save only pending to main storage
    await _saveAll(pending);
    
    // Add completed to history
    final historyJson = _prefs.getString(_historyKey);
    List<Transaction> history = [];
    if (historyJson != null && historyJson.isNotEmpty) {
      try {
        final List<dynamic> jsonList = json.decode(historyJson);
        history = jsonList
            .map((j) => Transaction.fromJson(j as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    
    history.addAll(completed);
    
    // Keep only last 100 transactions in history
    if (history.length > 100) {
      history = history.sublist(history.length - 100);
    }
    
    await _prefs.setString(
      _historyKey,
      json.encode(history.map((t) => t.toJson()).toList()),
    );
  }

  /// Clears all stored transactions (for testing).
  Future<void> clearAll() async {
    await _prefs.remove(_storageKey);
    await _prefs.remove(_historyKey);
  }

  Future<void> _saveAll(List<Transaction> transactions) async {
    final jsonString = json.encode(
      transactions.map((t) => t.toJson()).toList(),
    );
    await _prefs.setString(_storageKey, jsonString);
  }
}
