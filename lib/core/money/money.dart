import 'currency.dart';

/// An exact monetary amount stored as integer minor units (e.g. satang).
///
/// Floating-point values are never used for money (DATABASE.md §4).
class Money implements Comparable<Money> {
  const Money(this.minor, this.currency);

  const Money.zero(this.currency) : minor = 0;

  final int minor;
  final Currency currency;

  bool get isPositive => minor > 0;
  bool get isNegative => minor < 0;

  Money operator +(Money other) {
    _requireSameCurrency(other);
    return Money(minor + other.minor, currency);
  }

  Money operator -(Money other) {
    _requireSameCurrency(other);
    return Money(minor - other.minor, currency);
  }

  /// Parses a decimal string such as `1,234.50` or `฿99` without going
  /// through `double`.
  ///
  /// Returns `null` for malformed input or when the input has more fraction
  /// digits than [currency] allows. Values are rejected, never rounded.
  static Money? tryParse(String input, Currency currency) {
    final cleaned = input
        .replaceAll(currency.symbol, '')
        .replaceAll(currency.code, '')
        .replaceAll(',', '')
        .replaceAll(RegExp(r'\s'), '');
    final match = RegExp(r'^(-?)(\d{1,15})(?:\.(\d+))?$').firstMatch(cleaned);
    if (match == null) return null;

    final fraction = match.group(3) ?? '';
    if (fraction.length > currency.minorDigits) return null;

    final major = int.parse(match.group(2)!);
    final paddedFraction = fraction.padRight(currency.minorDigits, '0');
    final minorPart = paddedFraction.isEmpty ? 0 : int.parse(paddedFraction);
    final magnitude = major * currency.minorPerMajor + minorPart;
    return Money(match.group(1) == '-' ? -magnitude : magnitude, currency);
  }

  /// Plain decimal representation, e.g. `1234.50`. No grouping or symbol.
  String toDecimalString() {
    final abs = minor.abs();
    final major = abs ~/ currency.minorPerMajor;
    final sign = minor < 0 ? '-' : '';
    if (currency.minorDigits == 0) return '$sign$major';
    final fraction = (abs % currency.minorPerMajor).toString().padLeft(
      currency.minorDigits,
      '0',
    );
    return '$sign$major.$fraction';
  }

  void _requireSameCurrency(Money other) {
    if (other.currency != currency) {
      throw ArgumentError(
        'Cannot combine ${currency.code} with ${other.currency.code}',
      );
    }
  }

  @override
  int compareTo(Money other) {
    _requireSameCurrency(other);
    return minor.compareTo(other.minor);
  }

  @override
  bool operator ==(Object other) =>
      other is Money && other.minor == minor && other.currency == currency;

  @override
  int get hashCode => Object.hash(minor, currency);

  @override
  String toString() => '${toDecimalString()} ${currency.code}';
}
