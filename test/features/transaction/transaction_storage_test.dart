import 'package:bloctutorial/src/features/transaction/data/datasources/transaction_storage.dart';
import 'package:bloctutorial/src/features/transaction/domain/models/amount.dart';
import 'package:bloctutorial/src/features/transaction/domain/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late TransactionStorage storage;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = TransactionStorage(prefs);
  });

  group('TransactionStorage Tests', () {
    test('should save and retrieve a transaction', () async {
      final tx = Transaction.create(
        amount: Amount.fromCents(1000),
        recipient: 'Test User',
      );

      await storage.saveTransaction(tx);
      
      final retrieved = await storage.getTransaction(tx.clientTransactionId);
      expect(retrieved, isNotNull);
      expect(retrieved?.clientTransactionId, tx.clientTransactionId);
      expect(retrieved?.amount.cents, 1000);
    });

    test('should update transaction state correctly', () async {
      final tx = Transaction.create(amount: Amount.fromCents(500));
      await storage.saveTransaction(tx);

      await storage.updateTransactionState(
        tx.clientTransactionId, 
        TransactionState.completed,
        serverTransactionId: 'SRV-123',
      );

      final updated = await storage.getTransaction(tx.clientTransactionId);
      expect(updated?.state, TransactionState.completed);
      expect(updated?.serverTransactionId, 'SRV-123');
    });

    test('should retrieve only pending transactions', () async {
      final tx1 = Transaction.create(amount: Amount.fromCents(100)).markAsPending();
      final tx2 = Transaction.create(amount: Amount.fromCents(200)).markAsCompleted();
      
      await storage.saveTransaction(tx1);
      await storage.saveTransaction(tx2);

      final pending = await storage.getPendingTransactions();
      expect(pending.length, 1);
      expect(pending.first.clientTransactionId, tx1.clientTransactionId);
    });

    test('should clear all transactions', () async {
      await storage.saveTransaction(Transaction.create(amount: Amount.fromCents(10)));
      await storage.clearAll();
      
      final all = await storage.getAllTransactions();
      expect(all.isEmpty, true);
    });
  });
}
