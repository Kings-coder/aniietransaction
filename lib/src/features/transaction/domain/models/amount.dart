import 'package:equatable/equatable.dart';

/// Represents a monetary amount using integer cents to avoid floating-point precision issues.
/// 
/// This is critical for financial applications where precision loss from double
/// arithmetic (e.g., 0.1 + 0.2 != 0.3) could cause balance discrepancies.
class Amount extends Equatable {
  /// The amount in the smallest currency unit (cents for USD/EUR, etc.)
  final int cents;

  const Amount._({required this.cents});

  /// Creates an Amount from cents (smallest currency unit)
  factory Amount.fromCents(int cents) {
    return Amount._(cents: cents);
  }

  /// Creates an Amount from a string like "12.34" or "1234.56"
  /// Throws [FormatException] if the string is invalid
  factory Amount.fromString(String value) {
    final cleaned = value.replaceAll(',', '').trim();
    
    if (cleaned.isEmpty) {
      return const Amount._(cents: 0);
    }

    final parts = cleaned.split('.');
    
    if (parts.length > 2) {
      throw const FormatException('Invalid amount format: multiple decimal points');
    }

    final wholePart = int.tryParse(parts[0]);
    if (wholePart == null) {
      throw FormatException('Invalid amount format: ${parts[0]}');
    }

    int fractionalCents = 0;
    if (parts.length == 2) {
      var fractionalStr = parts[1];
      
      // Pad or truncate to 2 decimal places
      if (fractionalStr.length == 1) {
        fractionalStr = '${fractionalStr}0';
      } else if (fractionalStr.length > 2) {
        fractionalStr = fractionalStr.substring(0, 2);
      }
      
      fractionalCents = int.tryParse(fractionalStr) ?? 0;
    }

    final totalCents = (wholePart.abs() * 100) + fractionalCents;
    return Amount._(cents: wholePart.isNegative ? -totalCents : totalCents);
  }

  /// Creates an Amount from a double (use with caution - only for display purposes)
  /// Prefer [fromString] or [fromCents] for accuracy
  factory Amount.fromDouble(double value) {
    return Amount._(cents: (value * 100).round());
  }

  /// Zero amount constant
  static const zero = Amount._(cents: 0);

  /// Returns the amount as a double (for display only, not calculations)
  double toDouble() => cents / 100;

  /// Returns formatted string like "1,234.56"
  String toDisplayString({String symbol = '\$', bool showSymbol = true}) {
    final isNegative = cents < 0;
    final absoluteCents = cents.abs();
    final dollars = absoluteCents ~/ 100;
    final remainingCents = absoluteCents % 100;
    
    // Add thousands separators
    final dollarsStr = _addThousandsSeparator(dollars.toString());
    final centsStr = remainingCents.toString().padLeft(2, '0');
    
    final formatted = '$dollarsStr.$centsStr';
    if (showSymbol) {
      return isNegative ? '-$symbol$formatted' : '$symbol$formatted';
    }
    return isNegative ? '-$formatted' : formatted;
  }

  String _addThousandsSeparator(String number) {
    final buffer = StringBuffer();
    final length = number.length;
    
    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(number[i]);
    }
    
    return buffer.toString();
  }

  /// Arithmetic operations - all preserve precision
  Amount operator +(Amount other) => Amount._(cents: cents + other.cents);
  Amount operator -(Amount other) => Amount._(cents: cents - other.cents);
  Amount operator *(int multiplier) => Amount._(cents: cents * multiplier);
  
  /// Division with proper rounding
  Amount divide(int divisor) {
    if (divisor == 0) throw ArgumentError('Cannot divide by zero');
    return Amount._(cents: (cents / divisor).round());
  }

  /// Comparison operators
  bool operator <(Amount other) => cents < other.cents;
  bool operator <=(Amount other) => cents <= other.cents;
  bool operator >(Amount other) => cents > other.cents;
  bool operator >=(Amount other) => cents >= other.cents;

  /// Returns true if amount is positive
  bool get isPositive => cents > 0;

  /// Returns true if amount is zero
  bool get isZero => cents == 0;

  /// Returns true if amount is negative
  bool get isNegative => cents < 0;

  /// JSON serialization - stores as integer cents
  Map<String, dynamic> toJson() => {'cents': cents};

  factory Amount.fromJson(Map<String, dynamic> json) {
    return Amount._(cents: json['cents'] as int);
  }

  @override
  List<Object?> get props => [cents];

  @override
  String toString() => 'Amount(cents: $cents, display: ${toDisplayString()})';
}
