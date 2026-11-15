import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/core/money/amount_input_formatter.dart';
import 'package:moneylens/core/money/currency.dart';
import 'package:moneylens/core/money/money.dart';

void main() {
  final formatter = AmountInputFormatter();

  TextEditingValue value(String text, [int? cursor]) => TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: cursor ?? text.length),
  );

  /// Types [keys] one character at a time at the cursor, like a keyboard.
  TextEditingValue typeKeys(String keys, [TextEditingValue? from]) {
    var current = from ?? value('', 0);
    for (final key in keys.split('')) {
      final at = current.selection.baseOffset;
      final raw = current.text.replaceRange(at, at, key);
      current = formatter.formatEditUpdate(current, value(raw, at + 1));
    }
    return current;
  }

  /// A single edit of [old] into [text] with the cursor at [cursor].
  TextEditingValue edit(TextEditingValue old, String text, int cursor) =>
      formatter.formatEditUpdate(old, value(text, cursor));

  group('typing', () {
    test('groups thousands as the digits arrive', () {
      final shown = <String>[];
      var current = value('', 0);
      for (final key in '1234567'.split('')) {
        current = typeKeys(key, current);
        shown.add(current.text);
      }
      expect(shown, [
        '1',
        '12',
        '123',
        '1,234',
        '12,345',
        '123,456',
        '1,234,567',
      ]);
    });

    test('10000 shows as 10,000 with the cursor at the end', () {
      final v = typeKeys('10000');
      expect(v.text, '10,000');
      expect(v.selection, const TextSelection.collapsed(offset: 6));
    });

    test('keeps decimals while typing', () {
      expect(typeKeys('1234.').text, '1,234.');
      expect(typeKeys('1234.5').text, '1,234.5');
      expect(typeKeys('1234.50').text, '1,234.50');
      expect(typeKeys('1234.0').text, '1,234.0');
    });

    test('rejects a third decimal digit', () {
      final v = typeKeys('1234.50');
      final after = typeKeys('9', v);
      expect(after.text, '1,234.50');
      expect(after.selection, v.selection);
    });

    test('ignores a second decimal point and non-numeric keys', () {
      expect(typeKeys('1.2.3').text, '1.23');
      expect(typeKeys('1a2b').text, '12');
    });

    test('a user-typed comma is dropped and grouping regenerated', () {
      expect(typeKeys('1,234').text, '1,234');
      expect(typeKeys('12,34').text, '1,234');
      expect(typeKeys(',').text, '');
    });

    test('leading zeros', () {
      expect(typeKeys('0').text, '0');
      expect(typeKeys('00').text, '0');
      expect(typeKeys('007').text, '7');
      expect(typeKeys('0.5').text, '0.5');
      expect(typeKeys('0.05').text, '0.05');
      expect(typeKeys('05').text, '5');
    });

    test('a leading point becomes 0.', () {
      final v = typeKeys('.');
      expect(v.text, '0.');
      expect(v.selection, const TextSelection.collapsed(offset: 2));
      expect(typeKeys('.5').text, '0.5');
    });

    test('caps the whole part at what Money.tryParse accepts', () {
      final fifteen = '9' * 15;
      final v = typeKeys(fifteen);
      expect(Money.tryParse(v.text, Currency.thb), isNotNull);
      final after = typeKeys('1', v);
      expect(after.text, v.text);
      expect(after.selection, v.selection);
    });

    test('empty stays empty', () {
      expect(formatter.formatEditUpdate(value('1'), value('', 0)).text, '');
      expect(typeKeys('').text, '');
    });
  });

  group('editing in the middle', () {
    test('inserting a digit mid-string regroups and keeps the cursor', () {
      // 1,234 with the cursor after the 1; type 9 -> 19,234.
      final v = edit(value('1,234', 1), '19,234', 2);
      expect(v.text, '19,234');
      expect(v.selection, const TextSelection.collapsed(offset: 2));
    });

    test('a digit typed just after a comma lands before the next group', () {
      // 12,345 with the cursor after the comma; type 9 -> 129,345.
      final v = edit(value('12,345', 3), '12,9345', 4);
      expect(v.text, '129,345');
      expect(v.selection, const TextSelection.collapsed(offset: 3));
    });

    test('deleting a digit removes a comma when the number shrinks', () {
      // 1,234 with the cursor after the 1; backspace -> 234.
      final v = edit(value('1,234', 1), ',234', 0);
      expect(v.text, '234');
      expect(v.selection, const TextSelection.collapsed(offset: 0));
    });

    test('deleting inside the number keeps the cursor on the same digit', () {
      // 12,345 with the cursor after the 4; backspace -> 1,235.
      final v = edit(value('12,345', 5), '12,35', 4);
      expect(v.text, '1,235');
      expect(v.selection, const TextSelection.collapsed(offset: 4));
    });

    test('backspace over a comma deletes the digit before it', () {
      // 1,234 with the cursor after the comma.
      final v = edit(value('1,234', 2), '1234', 1);
      expect(v.text, '234');
      expect(v.selection, const TextSelection.collapsed(offset: 0));
    });

    test('forward delete over a comma deletes the digit after it', () {
      // 1,234 with the cursor before the comma.
      final v = edit(value('1,234', 1), '1234', 1);
      expect(v.text, '134');
      expect(v.selection, const TextSelection.collapsed(offset: 1));
    });

    test('backspace over a comma in a longer number', () {
      // 12,345 with the cursor after the comma -> 1,345.
      final v = edit(value('12,345', 3), '12345', 2);
      expect(v.text, '1,345');
      expect(v.selection, const TextSelection.collapsed(offset: 1));
    });

    test('deleting the decimal point joins the fraction to the number', () {
      final v = edit(value('1,234.5', 6), '1,2345', 5);
      expect(v.text, '12,345');
      expect(v.selection, const TextSelection.collapsed(offset: 5));
    });
  });

  group('paste', () {
    test('plain digits with a decimal', () {
      final v = edit(TextEditingValue.empty, '1234567.8', 9);
      expect(v.text, '1,234,567.8');
      expect(v.selection, const TextSelection.collapsed(offset: 11));
    });

    test('currency symbol and grouping from another app', () {
      final v = edit(TextEditingValue.empty, '฿1,234', 6);
      expect(v.text, '1,234');
      expect(v.selection, const TextSelection.collapsed(offset: 5));
    });

    test('a long fraction is cut to two digits', () {
      final v = edit(TextEditingValue.empty, '12.3456', 7);
      expect(v.text, '12.34');
      expect(v.selection, const TextSelection.collapsed(offset: 5));
    });

    test('pasting over a selection', () {
      final v = formatter.formatEditUpdate(
        TextEditingValue(
          text: '1,234',
          selection: const TextSelection(baseOffset: 0, extentOffset: 5),
        ),
        value('5000', 4),
      );
      expect(v.text, '5,000');
      expect(v.selection, const TextSelection.collapsed(offset: 5));
    });
  });

  group('validation accepts the formatted text', () {
    test('every typed intermediate parses or is empty', () {
      for (final keys in ['10000', '1234.5', '1234.50', '0.5', '1234567.8']) {
        final text = typeKeys(keys).text;
        expect(Money.tryParse(text, Currency.thb), isNotNull, reason: text);
      }
    });

    test('1,234.50 is 123450 satang', () {
      expect(
        Money.tryParse(typeKeys('1234.50').text, Currency.thb)!.minor,
        123450,
      );
    });
  });
}
