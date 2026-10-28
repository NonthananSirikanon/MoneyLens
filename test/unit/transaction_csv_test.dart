import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/core/dates/reporting_time_zone.dart';
import 'package:moneylens/features/export/application/transaction_csv.dart';
import 'package:moneylens/features/export/domain/export_period.dart';
import 'package:moneylens/features/transactions/domain/transaction.dart';
import 'package:moneylens/features/transactions/domain/transaction_type.dart';

import '../support/test_support.dart';

void main() {
  const labels = CsvLabels(
    date: 'วันที่',
    time: 'เวลา',
    type: 'ประเภท',
    amount: 'จำนวนเงิน',
    currency: 'สกุลเงิน',
    account: 'บัญชี',
    toAccount: 'บัญชีปลายทาง',
    category: 'หมวดหมู่',
    merchant: 'ร้านค้า/ผู้รับ',
    note: 'หมายเหตุ',
    source: 'แหล่งที่มา',
    income: 'รายรับ',
    expense: 'รายจ่าย',
    transfer: 'โอน',
  );

  final noon = ReportingTimeZone.bangkok.toUtc(2026, 10, 24, 12, 30);

  MoneyTransaction tx(
    String id, {
    TransactionType type = TransactionType.expense,
    int minor = 4500,
    DateTime? at,
    String? merchant = 'Shop',
    String? note,
    String account = 'acc',
    String? to,
    String? category = 'cat',
    TransactionSource source = TransactionSource.manual,
  }) => MoneyTransaction(
    id: id,
    type: type,
    amount: thb(minor),
    accountId: account,
    destinationAccountId: to,
    categoryId: category,
    merchant: merchant,
    note: note,
    occurredAt: at ?? noon,
    source: source,
    providerReference: 'SECRET-REF',
    attachmentPath: 'slips/secret.jpg',
    createdAt: noon,
    updatedAt: noon,
  );

  String build(List<MoneyTransaction> list) => TransactionCsv.build(
    transactions: list,
    labels: labels,
    accountName: (id) => 'Account $id',
    categoryName: (id) => 'Category $id',
  );

  List<String> lines(String csv) => csv.split('\r\n')..removeLast();

  test('starts with a BOM and the header, and ends every line with CRLF', () {
    final csv = build([tx('1')]);
    expect(csv.startsWith('﻿'), isTrue);
    final rows = lines(csv);
    expect(
      rows.first.substring(1),
      'วันที่,เวลา,ประเภท,จำนวนเงิน,สกุลเงิน,บัญชี,บัญชีปลายทาง,หมวดหมู่,'
      'ร้านค้า/ผู้รับ,หมายเหตุ,แหล่งที่มา',
    );
    expect(csv.endsWith('\r\n'), isTrue);
    expect(rows.length, 2);
  });

  test('a row holds Bangkok time, a plain decimal amount and names', () {
    final row = lines(build([tx('1')]))[1];
    expect(
      row,
      '2026-10-24,12:30,รายจ่าย,45.00,THB,Account acc,,Category cat,Shop,,manual',
    );
  });

  test('the date is the Bangkok day, not the UTC day', () {
    // 23:30 UTC on the 24th is 06:30 on the 25th in Bangkok.
    final late = DateTime.utc(2026, 10, 24, 23, 30);
    final row = lines(build([tx('1', at: late)]))[1];
    expect(row.startsWith('2026-10-25,06:30,'), isTrue);
  });

  test('transfers show the destination and no category', () {
    final row = lines(
      build([
        tx('1', type: TransactionType.transfer, to: 'dest', category: null),
      ]),
    )[1];
    expect(row, contains(',โอน,'));
    expect(row, contains(',Account acc,Account dest,,'));
  });

  test('commas, quotes and line breaks are quoted', () {
    final row = build([tx('1', merchant: 'A, "B"', note: 'line1\nline2')]);
    expect(row, contains('"A, ""B"""'));
    expect(row, contains('"line1\nline2"'));
    // The quoted newline does not add a record.
    expect(
      lines(row).where((l) => l.isNotEmpty).length,
      greaterThanOrEqualTo(2),
    );
  });

  test('text a spreadsheet would run as a formula is neutralised', () {
    for (final danger in ['=1+1', '+1', '-1', '@SUM(A1)', '\tx']) {
      final csv = build([tx('1', merchant: danger, note: danger)]);
      expect(csv, contains("'$danger"), reason: danger);
    }
    // Numbers and dates produced by the app are left alone.
    final row = lines(build([tx('1', minor: 100)]))[1];
    expect(row, contains(',1.00,THB,'));
  });

  test('Thai text and empty fields survive', () {
    final row = lines(
      build([tx('1', merchant: 'ร้านข้าวมันไก่', note: null)]),
    )[1];
    expect(row, contains('ร้านข้าวมันไก่,,manual'));
  });

  test('provider references and slip paths are never exported', () {
    final csv = build([tx('1')]);
    expect(csv, isNot(contains('SECRET-REF')));
    expect(csv, isNot(contains('slips/secret.jpg')));
  });

  test('rows are oldest first, ties by id', () {
    final older = DateTime.utc(2026, 10, 1, 3);
    final rows = lines(
      build([
        tx('b', at: noon),
        tx('c', at: older, merchant: 'Old'),
        tx('a', at: noon),
      ]),
    );
    expect(rows[1], contains('Old'));
    expect(rows.length, 4);
  });

  test('an empty list is just the header', () {
    expect(lines(build([])).length, 1);
  });

  group('ExportPeriod', () {
    final now = ReportingTimeZone.bangkok.toUtc(2026, 10, 24, 12);

    test('this month is half-open in Bangkok time', () {
      final range = ExportPeriod.thisMonth.rangeAt(now)!;
      expect(range.startUtc, ReportingTimeZone.bangkok.toUtc(2026, 10, 1));
      expect(range.endUtc, ReportingTimeZone.bangkok.toUtc(2026, 11, 1));
      expect(ExportPeriod.thisMonth.includes(range.startUtc, now), isTrue);
      expect(ExportPeriod.thisMonth.includes(range.endUtc, now), isFalse);
      // 17:00 UTC on 31 Oct is 00:00 on 1 Nov in Bangkok.
      expect(
        ExportPeriod.thisMonth.includes(DateTime.utc(2026, 10, 31, 17), now),
        isFalse,
      );
      expect(
        ExportPeriod.thisMonth.includes(
          DateTime.utc(2026, 10, 31, 16, 59),
          now,
        ),
        isTrue,
      );
    });

    test('the last 3 months reach back over a year boundary', () {
      final jan = ReportingTimeZone.bangkok.toUtc(2026, 1, 15);
      final range = ExportPeriod.last3Months.rangeAt(jan)!;
      expect(range.startUtc, ReportingTimeZone.bangkok.toUtc(2025, 11, 1));
      expect(range.endUtc, ReportingTimeZone.bangkok.toUtc(2026, 2, 1));
    });

    test('this year and all', () {
      final year = ExportPeriod.thisYear.rangeAt(now)!;
      expect(year.startUtc, ReportingTimeZone.bangkok.toUtc(2026, 1, 1));
      expect(year.endUtc, ReportingTimeZone.bangkok.toUtc(2027, 1, 1));
      expect(ExportPeriod.all.rangeAt(now), isNull);
      expect(ExportPeriod.all.includes(DateTime.utc(1999), now), isTrue);
    });
  });
}
