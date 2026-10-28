import 'package:flutter/services.dart';

/// Thai mobile numbers are entered without the leading 0 after `TH +66`:
/// nine digits starting with 6, 8 or 9.
abstract final class ThaiPhone {
  static final _valid = RegExp(r'^[689]\d{8}$');

  /// Keeps digits only, drops leading zeros (so `081…` and `81…` are the
  /// same) and caps at nine digits.
  static String normalize(String input) => input
      .replaceAll(RegExp(r'\D'), '')
      .replaceFirst(RegExp(r'^0+'), '')
      .let((d) => d.length > 9 ? d.substring(0, 9) : d);

  static bool isValid(String digits) => _valid.hasMatch(digits);

  /// `81 234 5678`
  static String format(String digits) {
    if (digits.length > 5) {
      return '${digits.substring(0, 2)} ${digits.substring(2, 5)} '
          '${digits.substring(5)}';
    }
    if (digits.length > 2) {
      return '${digits.substring(0, 2)} ${digits.substring(2)}';
    }
    return digits;
  }

  /// `+66812345678`
  static String toE164(String digits) => '+66$digits';
}

extension on String {
  R let<R>(R Function(String) f) => f(this);
}

/// Formats the field as `81 234 5678` while typing.
class ThaiPhoneFormatter extends TextInputFormatter {
  const ThaiPhoneFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = ThaiPhone.format(ThaiPhone.normalize(newValue.text));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
