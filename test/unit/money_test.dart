import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/core/money/currency.dart';
import 'package:moneylens/core/money/money.dart';
import 'package:moneylens/core/money/money_formatter.dart';

void main() {
  const thb = Currency.thb;

  group('Money.tryParse', () {
    test('converts baht to integer satang (DATABASE.md §4 examples)', () {
      expect(Money.tryParse('123.45', thb), const Money(12345, thb));
      expect(Money.tryParse('1,000.00', thb), const Money(100000, thb));
      expect(Money.tryParse('฿ 99', thb), const Money(9900, thb));
      expect(Money.tryParse('0.5', thb), const Money(50, thb));
    });

    test('is exact where floating point is not', () {
      // 0.1 + 0.2 != 0.3 in double arithmetic; integer minor units are exact.
      final sum = Money.tryParse('0.1', thb)! + Money.tryParse('0.2', thb)!;
      expect(sum, Money.tryParse('0.3', thb));
      expect(Money.tryParse('19.99', thb)!.minor, 1999);
    });

    test('rejects extra precision instead of rounding', () {
      expect(Money.tryParse('1.005', thb), isNull);
    });

    test('rejects malformed input', () {
      for (final input in ['', 'abc', '1.2.3', '1e5', '.5', '12.']) {
        expect(Money.tryParse(input, thb), isNull, reason: input);
      }
    });

    test('keeps the sign so validation can reject it', () {
      expect(Money.tryParse('-10', thb), const Money(-1000, thb));
    });
  });

  group('Money', () {
    test('formats as a plain decimal string', () {
      expect(const Money(12345, thb).toDecimalString(), '123.45');
      expect(const Money(5, thb).toDecimalString(), '0.05');
      expect(const Money(-100, thb).toDecimalString(), '-1.00');
    });

    test('formats for display with grouping and symbol', () {
      expect(
        const MoneyFormatter('en').format(Money(123456789, thb)),
        '฿1,234,567.89',
      );
      expect(const MoneyFormatter('th').format(Money(-50, thb)), '-฿0.50');
    });

    test('refuses to mix currencies', () {
      const other = Money(1, thb);
      expect(() => other + const Money(1, _Usd()), throwsArgumentError);
    });
  });
}

/// Not registered in `Currency.supported`; exists only to test mixing.
class _Usd implements Currency {
  const _Usd();

  @override
  String get code => 'USD';
  @override
  int get minorDigits => 2;
  @override
  String get symbol => r'$';
  @override
  int get minorPerMajor => 100;
}
