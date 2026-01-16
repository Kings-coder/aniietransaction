import 'package:bloctutorial/src/features/transaction/domain/models/amount.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Amount Model Tests', () {
    test('should create Amount from cents correctly', () {
      final amount = Amount.fromCents(100);
      expect(amount.cents, 100);
      expect(amount.toDouble(), 1.0);
    });

    test('should create Amount from string correctly', () {
      expect(Amount.fromString('10.50').cents, 1050);
      expect(Amount.fromString('1,000.00').cents, 100000);
      expect(Amount.fromString('0.05').cents, 5);
      expect(Amount.fromString('12').cents, 1200);
    });

    test('should handle negative amounts correctly', () {
      expect(Amount.fromString('-10.00').cents, -1000);
      expect(Amount.fromCents(-500).toDouble(), -5.0);
    });

    test('should format display string correctly', () {
      expect(Amount.fromCents(123456).toDisplayString(), '\$1,234.56');
      expect(Amount.fromCents(5).toDisplayString(), '\$0.05');
      expect(Amount.fromCents(-1000).toDisplayString(), '-\$10.00');
    });

    test('should perform operations without precision loss', () {
      final a = Amount.fromString('0.1');
      final b = Amount.fromString('0.2');
      final sum = a + b;
      
      expect(sum.cents, 30);
      expect(sum.toDisplayString(), '\$0.30');
      // Proof: 0.1 + 0.2 double would be 0.30000000000000004
      expect(sum.toDouble(), 0.3);
    });

    test('should handle invalid string formats', () {
      expect(() => Amount.fromString('invalid'), throwsFormatException);
      expect(() => Amount.fromString('10.50.20'), throwsFormatException);
    });
  });
}
