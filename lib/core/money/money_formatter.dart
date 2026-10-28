import 'package:intl/intl.dart';

import 'money.dart';

/// Locale-aware display formatting for [Money].
///
/// Groups the integer major part with `intl` and appends the fraction
/// manually, so the amount never passes through `double`.
class MoneyFormatter {
  const MoneyFormatter(this.locale);

  final String locale;

  String format(Money money, {bool withSymbol = true}) {
    final currency = money.currency;
    final abs = money.minor.abs();
    final numberFormat = NumberFormat.decimalPattern(locale);
    final major = numberFormat.format(abs ~/ currency.minorPerMajor);
    final sign = money.isNegative ? '-' : '';
    final symbol = withSymbol ? currency.symbol : '';
    if (currency.minorDigits == 0) return '$sign$symbol$major';

    final fraction = (abs % currency.minorPerMajor).toString().padLeft(
      currency.minorDigits,
      '0',
    );
    return '$sign$symbol$major${numberFormat.symbols.DECIMAL_SEP}$fraction';
  }

  /// Rounded to whole major units, e.g. `฿12,350`, as used in summaries and
  /// charts. Rounds half away from zero on the integer minor value.
  String compact(Money money) {
    final currency = money.currency;
    final abs = money.minor.abs();
    final half = currency.minorPerMajor ~/ 2;
    final major = (abs + half) ~/ currency.minorPerMajor;
    final sign = money.isNegative && major > 0 ? '-' : '';
    final grouped = NumberFormat.decimalPattern(locale).format(major);
    return '$sign${currency.symbol}$grouped';
  }
}
