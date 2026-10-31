import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/core/dates/reporting_time_zone.dart';
import 'package:moneylens/features/slip_import/data/thai_slip_extraction_service.dart';
import 'package:moneylens/features/slip_import/domain/extracted_fields.dart';
import 'package:moneylens/features/transactions/domain/transaction_type.dart';

/// The fixtures are invented: they follow the layout of each bank's slip but
/// every name, amount and number in them is made up.
void main() {
  ExtractedFields read(String name) => ThaiSlipExtractionService.parse(
    File('test/fixtures/slips/$name.txt').readAsStringSync(),
  );

  DateTime bangkok(int y, int m, int d, int h, int min) =>
      ReportingTimeZone.bangkok.toUtc(y, m, d, h, min);

  // name, amount (satang), when, payee, has reference
  final cases = <(String, int, DateTime, String, bool)>[
    (
      'kbank_transfer',
      125050,
      bangkok(2026, 2, 12, 9, 5),
      'นาย สมชาย ทดสอบ',
      true,
    ),
    (
      'kbank_memo',
      200000,
      bangkok(2026, 6, 30, 20, 57),
      'นาย สมชาย ทดสอบ',
      true,
    ),
    (
      'scb_transfer',
      15000,
      bangkok(2026, 9, 21, 18, 57),
      'น.ส. สมหญิง ตัวอย่าง',
      true,
    ),
    (
      'scb_bill',
      6500,
      bangkok(2026, 1, 30, 19, 17),
      'ร้านกาแฟตัวอย่าง สาขา สถานีบริการน้ำมัน',
      true,
    ),
    (
      'scb_large',
      2500000,
      bangkok(2026, 5, 29, 14, 34),
      'นาย ประยุทธ ตัวอย่าง',
      true,
    ),
    (
      'krungthai_transfer',
      5000,
      bangkok(2026, 7, 29, 19, 58),
      'นาย วิชัย ตัวอย่าง',
      true,
    ),
    (
      'krungthai_memo',
      3115,
      bangkok(2026, 7, 21, 11, 54),
      'นาย วิชัย ตัวอย่าง',
      true,
    ),
    (
      'kkp_bill',
      65500,
      bangkok(2026, 3, 29, 19, 21),
      'ร้านอาหารตัวอย่าง',
      true,
    ),
    (
      'kkp_transfer',
      100000,
      bangkok(2026, 3, 27, 7, 59),
      'นาย ประยุทธ ตัวอย่าง',
      true,
    ),
    (
      'ttb_transfer',
      100000,
      bangkok(2026, 5, 27, 16, 28),
      'นาย ประยุทธ ตัวอย่าง',
      true,
    ),
    (
      'ttb_previous_year',
      100000,
      bangkok(2025, 12, 29, 13, 39),
      'นาง สมศรี ตัวอย่าง',
      true,
    ),
    (
      'gsb_company',
      197000,
      bangkok(2025, 10, 20, 9, 22),
      'บริษัท ตัวอย่างการบิน จำกัด',
      false,
    ),
    (
      'bbl_transfer',
      425000,
      bangkok(2026, 8, 12, 14, 35),
      'น.ส. สมหญิง ตัวอย่าง',
      true,
    ),
    (
      'krungsri_transfer',
      235000,
      bangkok(2026, 10, 9, 8, 41),
      'นาย วิชัย ตัวอย่าง',
      true,
    ),
    (
      'gsb_mymo_transfer',
      80000,
      bangkok(2026, 11, 3, 17, 20),
      'น.ส. สมหญิง ตัวอย่าง',
      true,
    ),
    (
      'truemoney_transfer',
      15000,
      bangkok(2026, 12, 15, 21, 3),
      'นาย วิชัย ตัวอย่าง',
      true,
    ),
  ];

  for (final (name, amount, at, payee, hasRef) in cases) {
    test('reads the $name slip', () {
      final f = read(name);
      expect(f.amountMinor?.value, amount, reason: 'amount');
      expect(f.currencyCode, 'THB');
      expect(f.occurredAt?.value, at, reason: 'date and time');
      expect(f.merchant?.value, payee, reason: 'payee');
      expect(f.type?.value, TransactionType.expense);
      expect(f.providerReference != null, hasRef, reason: 'reference');
      // Nothing is missing, so the review screen only has to confirm.
      expect(f.missingRequiredFields, isEmpty);
    });
  }

  test('the reference is the value next to its label', () {
    expect(
      read('scb_transfer').providerReference?.value,
      '2026092100AB12CDEFGH',
    );
    expect(
      read('krungthai_transfer').providerReference?.value,
      'N001234567890123456789012',
    );
    expect(read('kkp_bill').providerReference?.value, '123456789012345');
    // The bill's "รหัสอ้างอิง" is preferred over the other ids on that slip.
    expect(read('scb_bill').providerReference?.value, '2026013000XY98ZYXWVU');
  });

  test('a received transfer is income and the payee is the sender', () {
    final f = read('incoming_transfer');
    expect(f.type?.value, TransactionType.income);
    expect(f.amountMinor?.value, 30000);
    expect(f.merchant?.value, 'นาย ประยุทธ ตัวอย่าง');
  });

  test('the fee is never taken for the amount', () {
    for (final n in [
      'kkp_bill',
      'ttb_transfer',
      'krungthai_transfer',
      'kbank_transfer',
    ]) {
      expect(read(n).amountMinor?.value, isNot(0), reason: n);
    }
  });

  test('text that is not a slip gives nothing, so every field is asked', () {
    final f = read('junk');
    expect(f.amountMinor, isNull);
    expect(f.occurredAt, isNull);
    expect(f.merchant, isNull);
    expect(f.missingRequiredFields, isNotEmpty);
    expect(ThaiSlipExtractionService.parse(''), isA<ExtractedFields>());
  });

  group('years and dates', () {
    ExtractedFields p(String line) =>
        ThaiSlipExtractionService.parse('จำนวนเงิน\n10.00\n$line');

    test('a two-digit Buddhist year', () {
      expect(
        p('1 ม.ค. 69 11:25 น.').occurredAt?.value,
        bangkok(2026, 1, 1, 11, 25),
      );
    });

    test('a four-digit Buddhist year and a dashed time', () {
      expect(
        p('20 ต.ค. 2568 09-22').occurredAt?.value,
        bangkok(2025, 10, 20, 9, 22),
      );
    });

    test('a Gregorian year is kept', () {
      expect(
        p('5 ก.ย. 2026 10:00').occurredAt?.value,
        bangkok(2026, 9, 5, 10, 0),
      );
    });

    test('full month names', () {
      expect(
        p('7 มีนาคม 2569 08:30').occurredAt?.value,
        bangkok(2026, 3, 7, 8, 30),
      );
    });

    test('a date with no time is noon and less certain', () {
      final d = p('7 มี.ค. 2569').occurredAt!;
      expect(d.value, bangkok(2026, 3, 7, 12, 0));
      expect(d.confidence, lessThan(0.7));
    });

    test('stray vowel marks and lost dots do not hide the month', () {
      // OCR wrote "ก.ุค." for ก.ค. and dropped the dots of ก.ย.
      expect(
        p('29 ก.ุค. 2569 - 19:58').occurredAt?.value,
        bangkok(2026, 7, 29, 19, 58),
      );
      expect(
        p('21 กย 2569 18:57').occurredAt?.value,
        bangkok(2026, 9, 21, 18, 57),
      );
    });

    test('months that differ only by a vowel are told apart by it', () {
      expect(
        p('5 มี.ค. 2569 10:00').occurredAt?.value,
        bangkok(2026, 3, 5, 10, 0),
      );
      expect(
        p('5 ม.ค. 2569 10:00').occurredAt?.value,
        bangkok(2026, 1, 5, 10, 0),
      );
      expect(
        p('5 เม.ย. 2569 10:00').occurredAt?.value,
        bangkok(2026, 4, 5, 10, 0),
      );
      expect(
        p('5 มิ.ย. 2569 10:00').occurredAt?.value,
        bangkok(2026, 6, 5, 10, 0),
      );
    });

    test('an unclear month is left unknown, never guessed', () {
      // "ม.ย." without the vowel could be เม.ย. or มิ.ย.
      expect(p('5 ม.ย. 2569 10:00').occurredAt, isNull);
      // Not a month at all.
      expect(p('5 ปกติ 2569 10:00').occurredAt, isNull);
    });

    test('an impossible date is ignored, not rolled over', () {
      expect(p('31 ก.พ. 2569 10:00').occurredAt, isNull);
    });
  });

  group('payee', () {
    ExtractedFields p(String text) => ThaiSlipExtractionService.parse(text);

    test('on the same line as the label (two columns read as one row)', () {
      final f = p(
        'จาก     นาย สมชาย ทดสอบ\nไปยัง    นาย ประยุทธ ตัวอย่าง\nจำนวนเงิน 10.00',
      );
      expect(f.merchant?.value, 'นาย ประยุทธ ตัวอย่าง');
    });

    test('a wrapped business name is joined, a person is not', () {
      final shop = p(
        'ไปยัง  ร้านกาแฟตัวอย่าง สาขา\nสถานีบริการน้ำมัน\nBiller ID : 1',
      );
      expect(shop.merchant?.value, 'ร้านกาแฟตัวอย่าง สาขา สถานีบริการน้ำมัน');
      final person = p('ไปยัง  นาย ประยุทธ ตัวอย่าง\nสถานีบริการน้ำมัน');
      expect(person.merchant?.value, 'นาย ประยุทธ ตัวอย่าง');
    });

    test('Tesseract writes "ำ" as two characters; labels still match', () {
      final f = p('จํานวนเงิน\n12.50\n20 ต.ค. 2569 10:00');
      expect(f.amountMinor?.value, 1250);
    });
  });

  group('amounts', () {
    ExtractedFields p(String text) => ThaiSlipExtractionService.parse(text);

    test('a labelled amount on the next line', () {
      final a = p('จำนวนเงิน\n1,234.56').amountMinor!;
      expect(a.value, 123456);
      expect(a.confidence, greaterThan(0.8));
    });

    test('an amount followed by บาท without a label', () {
      expect(
        p('โอนเงิน\n99.00 บาท\nค่าธรรมเนียม 5.00 บาท').amountMinor?.value,
        9900,
      );
    });

    test('a clock time is not an amount', () {
      expect(p('19.21 น.').amountMinor, isNull);
    });

    test('a zero amount is not an amount', () {
      expect(p('จำนวนเงิน\n0.00').amountMinor, isNull);
    });

    test('an amount without a comma separator', () {
      expect(p('จำนวน: 2000.00 บาท').amountMinor?.value, 200000);
    });

    test('doubled or dotted thousands separators are repaired', () {
      expect(p('1,.000.00 บาท').amountMinor?.value, 100000);
      expect(p('จำนวนเงิน 2.500.00 บาท').amountMinor?.value, 250000);
    });

    test('Thai digits are read as the digits they stand for', () {
      expect(p('จำนวนเงิน ๕๐.๐๐ บาท').amountMinor?.value, 5000);
    });
  });

  group('OCR slips Tesseract makes', () {
    ExtractedFields p(String text) => ThaiSlipExtractionService.parse(text);

    test('a month with one stray letter is found, but flagged', () {
      final d = p('จำนวนเงิน\n10.00\n29 ธร.ค. 68, 13:39 น.').occurredAt!;
      expect(d.value, bangkok(2025, 12, 29, 13, 39));
      expect(d.confidence, lessThan(0.8));
    });

    test('a stray letter that leaves two possible months is not guessed', () {
      // Dropping one letter of "มคย" leaves ม.ค./มี.ค. or เม.ย./มิ.ย.,
      // which only a vowel tells apart.
      expect(p('จำนวนเงิน\n10.00\n5 ม.ค.ย 2569 10:00').occurredAt, isNull);
    });

    test('a mark between the month and the year', () {
      expect(
        p('จำนวนเงิน\n10.00\n21 ก.ย=2569 18:57').occurredAt?.value,
        bangkok(2026, 9, 21, 18, 57),
      );
    });

    test('icons and masked account numbers around a name are dropped', () {
      String? payee(String line) =>
          p('จาก นาย สมชาย ทดสอบ\nไปยัง\n$line\nจำนวนเงิน 10.00')
              .merchant
              ?.value;
      expect(payee('(6) นาย ประยุทธ ตัวอย่าง %-8782'), 'นาย ประยุทธ ตัวอย่าง');
      expect(payee('แนายประยุทธ ตัวอย่าง'), 'นายประยุทธ ตัวอย่าง');
      expect(payee('= บ.ส.สมหญิง ตัวอย่าง'), 'น.ส.สมหญิง ตัวอย่าง');
      expect(payee('ซ น.ส.สมหญิง ตัวอย่าง'), 'น.ส.สมหญิง ตัวอย่าง');
      expect(payee('นายประยุทธ ตัวอย่าง 1'), 'นายประยุทธ ตัวอย่าง');
    });
  });

  group('several readings of one slip', () {
    const a =
        'ไปยัง\nนาย ประยุทธ ตัวอย่าง\nจำนวนเงิน 50.00 บาท\n'
        '29 มี.ค. 2569 - 19:21 น.';
    const b =
        'ไปยัง\nนาย ประยุทธ ตัวอย่าง\nจำนวนเงิน 50.00 บาท\n'
        '29 มี.ค. 2569 - 19:21 น.';
    // A third reading that misread the amount and lost the date.
    const c = 'ไปยัง\nนาย ประยุทธ ตัวอยาง\nจำนวนเงิน 30.00 บาท';

    test('each field takes the value most readings agree on', () {
      final f = ThaiSlipExtractionService.combine([c, a, b]);
      expect(f.amountMinor?.value, 5000);
      expect(f.amountMinor?.confidence, greaterThanOrEqualTo(0.8));
      expect(f.occurredAt?.value, bangkok(2026, 3, 29, 19, 21));
      expect(f.merchant?.value, 'นาย ประยุทธ ตัวอย่าง');
    });

    test('a value only one reading found is kept but flagged', () {
      final f = ThaiSlipExtractionService.combine([
        c,
        'ไปยัง\nนาย ประยุทธ ตัวอย่าง\nจำนวนเงิน\n29 มี.ค. 2569 - 19:21 น.',
      ]);
      expect(f.occurredAt?.value, bangkok(2026, 3, 29, 19, 21));
      expect(f.occurredAt?.confidence, lessThan(0.8));
      expect(f.amountMinor?.value, 3000);
      expect(f.amountMinor?.confidence, lessThan(0.8));
    });

    test('when no two names match, the one closest to the rest wins', () {
      final f = ThaiSlipExtractionService.combine([
        'ไปยัง\nนาย ประยุทธ ตัวอยาง',
        'ไปยัง\nนาย ประยุทธ ตัวอย่าง',
        'ไปยัง\nนาย ประยุทร ตัวอย่าง',
      ]);
      expect(f.merchant?.value, 'นาย ประยุทธ ตัวอย่าง');
      expect(f.merchant?.confidence, lessThan(0.8));
    });

    test('two readings agree when amount, date and payee match', () {
      expect(ThaiSlipExtractionService.readingsAgree(a, b), isTrue);
      expect(ThaiSlipExtractionService.readingsAgree(a, c), isFalse);
    });
  });
}
