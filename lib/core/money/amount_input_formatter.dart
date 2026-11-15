import 'package:flutter/services.dart';

import 'currency.dart';
import 'money.dart';

/// Formats an amount field as the user types: `10000` shows as `10,000` and
/// `1234.5` as `1,234.5`.
///
/// The field keeps only digits and one decimal point, so commas the user types
/// or pastes are discarded and regenerated. The fraction is limited to the
/// currency's minor digits and the whole part to what [Money.tryParse]
/// accepts. A trailing `.` is kept while the user is still typing; the save
/// paths drop it with [withoutTrailingPoint].
class AmountInputFormatter extends TextInputFormatter {
  AmountInputFormatter({this.currency = Currency.thb});

  final Currency currency;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    var cursor = _cursorOf(newValue);

    // Backspace or delete on a comma would only move the cursor, because the
    // comma is regenerated. Delete the neighbouring digit instead.
    final commaAt = _deletedCommaAt(oldValue, newValue);
    if (commaAt != null) {
      final backspace = oldValue.selection.baseOffset == commaAt + 1;
      final digitAt = backspace ? commaAt - 1 : commaAt + 1;
      if (digitAt >= 0 && digitAt < oldValue.text.length) {
        text = oldValue.text.replaceRange(digitAt, digitAt + 1, '');
        cursor = backspace ? digitAt : commaAt;
      }
    }

    final canon = _canonical(text, cursor);
    final overflowed = canon.truncated;
    // One key press that would add a digit past the limit is refused, so the
    // field does not silently change other digits.
    if (overflowed && _isSingleInsert(oldValue, newValue)) return oldValue;

    final shown = StringBuffer();
    var cursorOut = 0;
    var seen = 0;
    final whole = canon.whole;
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) shown.write(',');
      shown.write(whole[i]);
      if (++seen <= canon.cursor) cursorOut = shown.length;
    }
    if (canon.hasPoint) {
      shown.write('.');
      if (++seen <= canon.cursor) cursorOut = shown.length;
      for (var i = 0; i < canon.fraction.length; i++) {
        shown.write(canon.fraction[i]);
        if (++seen <= canon.cursor) cursorOut = shown.length;
      }
    }
    return TextEditingValue(
      text: shown.toString(),
      selection: TextSelection.collapsed(offset: cursorOut),
    );
  }

  static int _cursorOf(TextEditingValue v) {
    final offset = v.selection.baseOffset;
    return offset < 0 || offset > v.text.length ? v.text.length : offset;
  }

  /// Whether [now] is [old] plus one character typed at the cursor, as
  /// opposed to a paste or a programmatic replacement.
  static bool _isSingleInsert(TextEditingValue old, TextEditingValue now) {
    final at = now.selection.baseOffset;
    return now.selection.isCollapsed &&
        at >= 1 &&
        at <= now.text.length &&
        now.text.replaceRange(at - 1, at, '') == old.text;
  }

  /// The index of the comma removed by a one-character deletion, if that is
  /// what [newValue] is.
  static int? _deletedCommaAt(TextEditingValue old, TextEditingValue now) {
    if (!now.selection.isCollapsed ||
        !old.selection.isCollapsed ||
        old.text.length != now.text.length + 1) {
      return null;
    }
    final at = now.selection.baseOffset;
    if (at < 0 || at >= old.text.length || old.text[at] != ',') return null;
    return old.text.replaceRange(at, at + 1, '') == now.text ? at : null;
  }

  /// Reduces [text] to digits and at most one point, drops leading zeros and
  /// excess digits, and counts how many of the remaining characters sit
  /// before [cursor].
  _Canonical _canonical(String text, int cursor) {
    final whole = <(String, bool)>[];
    final fraction = <(String, bool)>[];
    var pointBefore = false;
    var hasPoint = false;
    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      final before = i < cursor;
      final isDigit = ch.codeUnitAt(0) >= 0x30 && ch.codeUnitAt(0) <= 0x39;
      if (isDigit) {
        (hasPoint ? fraction : whole).add((ch, before));
      } else if (ch == '.' && !hasPoint && currency.minorDigits > 0) {
        hasPoint = true;
        pointBefore = before;
      }
    }

    var truncated = false;
    while (whole.length > 1 && whole.first.$1 == '0') {
      whole.removeAt(0);
    }
    if (whole.isEmpty && hasPoint) whole.add(('0', pointBefore));
    if (whole.length > Money.maxMajorDigits) {
      whole.removeRange(Money.maxMajorDigits, whole.length);
      truncated = true;
    }
    if (fraction.length > currency.minorDigits) {
      fraction.removeRange(currency.minorDigits, fraction.length);
      truncated = true;
    }

    final kept = [...whole, if (hasPoint) ('.', pointBefore), ...fraction];
    return _Canonical(
      whole: whole.map((e) => e.$1).join(),
      hasPoint: hasPoint,
      fraction: fraction.map((e) => e.$1).join(),
      cursor: kept.where((e) => e.$2).length,
      truncated: truncated,
    );
  }
}

class _Canonical {
  const _Canonical({
    required this.whole,
    required this.hasPoint,
    required this.fraction,
    required this.cursor,
    required this.truncated,
  });

  final String whole;
  final bool hasPoint;
  final String fraction;

  /// How many of the characters of the formatted number (digits and the
  /// point) are before the cursor.
  final int cursor;

  /// Whether digits were cut off to fit the limits.
  final bool truncated;
}
