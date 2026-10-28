import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/core/dates/clock.dart';
import 'package:moneylens/core/dates/reporting_time_zone.dart';
import 'package:moneylens/core/money/currency.dart';
import 'package:moneylens/features/accounts/application/account_providers.dart';
import 'package:moneylens/features/accounts/domain/account.dart';
import 'package:moneylens/features/export/application/export_service.dart';
import 'package:moneylens/features/export/application/transaction_csv.dart';
import 'package:moneylens/features/export/domain/export_period.dart';
import 'package:moneylens/features/transactions/application/transaction_providers.dart';
import 'package:moneylens/features/transactions/domain/transaction.dart';
import 'package:moneylens/features/transactions/domain/transaction_type.dart';
import 'package:moneylens/infrastructure/database/app_database.dart';

import '../support/test_support.dart';

void main() {
  final now = ReportingTimeZone.bangkok.toUtc(2026, 10, 24, 12);
  const labels = CsvLabels(
    date: 'Date',
    time: 'Time',
    type: 'Type',
    amount: 'Amount',
    currency: 'Currency',
    account: 'Account',
    toAccount: 'To account',
    category: 'Category',
    merchant: 'Merchant',
    note: 'Note',
    source: 'Source',
    income: 'Income',
    expense: 'Expense',
    transfer: 'Transfer',
  );

  late ProviderContainer container;
  late RecordingSharer sharer;

  setUp(() {
    final db = openTestDatabase();
    sharer = RecordingSharer();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(FixedClock(now)),
        fileSharerProvider.overrideWithValue(sharer),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
  });

  Future<void> record(String account, DateTime at, String merchant) async {
    await container
        .read(createTransactionProvider)
        .call(
          TransactionDraft(
            type: TransactionType.expense,
            amount: thb(12345),
            accountId: account,
            categoryId: 'default-expense-food',
            merchant: merchant,
            occurredAt: at,
          ),
        );
  }

  test('exports only the chosen period, with real account names', () async {
    final bank = await container
        .read(accountRepositoryProvider)
        .create(name: 'Bank Z', kind: AccountKind.bank, currency: Currency.thb);
    await record(bank.id, now, 'This month');
    await record(
      bank.id,
      ReportingTimeZone.bangkok.toUtc(2026, 9, 30, 10),
      'Last month',
    );

    final service = container.read(csvExportServiceProvider);
    final month = await service.export(ExportPeriod.thisMonth, labels);
    expect(month.count, 1);
    expect(month.fileName, 'moneylens-2026-10.csv');
    var csv = utf8.decode(sharer.files.last.bytes.skip(3).toList());
    expect(csv, contains('This month'));
    expect(csv, isNot(contains('Last month')));
    expect(csv, contains('Bank Z'));
    expect(csv, contains('อาหารและเครื่องดื่ม'));
    expect(csv, contains('123.45'));

    final all = await service.export(ExportPeriod.all, labels);
    expect(all.count, 2);
    expect(all.fileName, 'moneylens-all.csv');
    csv = utf8.decode(sharer.files.last.bytes.skip(3).toList());
    expect(csv, contains('Last month'));
  });

  test('an empty period writes and shares nothing', () async {
    final service = container.read(csvExportServiceProvider);
    final result = await service.export(ExportPeriod.thisMonth, labels);
    expect(result.count, 0);
    expect(result.outcome, isNull);
    expect(sharer.files, isEmpty);
  });

  test('file names say what they cover', () {
    final service = container.read(csvExportServiceProvider);
    expect(service.fileName(ExportPeriod.thisMonth), 'moneylens-2026-10.csv');
    expect(
      service.fileName(ExportPeriod.last3Months),
      'moneylens-last-3-months-2026-10.csv',
    );
    expect(service.fileName(ExportPeriod.thisYear), 'moneylens-2026.csv');
    expect(service.fileName(ExportPeriod.all), 'moneylens-all.csv');
  });
}
