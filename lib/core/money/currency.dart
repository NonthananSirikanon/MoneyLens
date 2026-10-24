/// A currency the app can store and display.
///
/// [minorDigits] is the number of minor-unit digits, defined per currency
/// rather than assumed globally (DATABASE.md §4).
class Currency {
  const Currency._(this.code, this.minorDigits, this.symbol);

  /// ISO 4217 code, e.g. `THB`.
  final String code;
  final int minorDigits;
  final String symbol;

  static const thb = Currency._('THB', 2, '฿');

  /// The MVP supports THB only. Add entries here to support more currencies.
  static const Map<String, Currency> supported = {'THB': thb};

  static Currency? tryFromCode(String code) => supported[code.toUpperCase()];

  /// Number of minor units in one major unit, e.g. 100 satang per baht.
  int get minorPerMajor {
    var factor = 1;
    for (var i = 0; i < minorDigits; i++) {
      factor *= 10;
    }
    return factor;
  }

  @override
  bool operator ==(Object other) => other is Currency && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => code;
}
