import 'package:drift/native.dart' show SqliteException;
import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/core/errors/app_failure.dart';
import 'package:moneylens/core/money/currency.dart';
import 'package:moneylens/features/accounts/data/drift_account_repository.dart';
import 'package:moneylens/features/accounts/domain/account.dart';
import 'package:moneylens/features/accounts/domain/account_balance.dart';
import 'package:moneylens/features/categories/data/drift_category_repository.dart';
import 'package:moneylens/features/categories/domain/category.dart';
import 'package:moneylens/features/slip_import/data/drift_scan_repository.dart';
import 'package:moneylens/features/slip_import/domain/scan_status.dart';
import 'package:moneylens/features/transactions/application/transaction_draft_checker.dart';
import 'package:moneylens/features/transactions/application/update_transaction.dart';
import 'package:moneylens/features/transactions/data/drift_transaction_repository.dart';
import 'package:moneylens/features/transactions/domain/transaction.dart';
import 'package:moneylens/features/transactions/domain/transaction_type.dart';
import 'package:moneylens/features/transactions/domain/transaction_validator.dart';
import 'package:moneylens/infrastructure/database/app_database.dart';

import '../../support/test_support.dart';

void main() {
  late AppDatabase db;
  late FixedClock clock;
  late SequentialIds ids;
  late DriftTransactionRepository transactions;
  late DriftAccountRepository accounts;
  late DriftCategoryRepository categories;
  late String cash;
  late String bank;

  setUp(() async {
    db = openTestDatabase();
    clock = FixedClock(DateTime.utc(2026, 10, 14, 5));
    ids = SequentialIds();
    transactions = DriftTransactionRepository(db, clock, ids);
    accounts = DriftAccountRepository(db, clock, ids);
    categories = DriftCategoryRepository(db, clock, ids);
    cash = (await accounts.create(
      name: 'Cash',
      kind: AccountKind.cash,
      currency: Currency.thb,
      openingBalanceMinor: 100000,
    )).id;
    bank = (await accounts.create(
      name: 'Bank',
      kind: AccountKind.bank,
      currency: Currency.thb,
    )).id;
  });

  tearDown(() => db.close());

  TransactionDraft draft({
    TransactionType type = TransactionType.expense,
    int minor = 4500,
    String? account,
    String? to,
    String? category = 'default-expense-food',
  }) => TransactionDraft(
    type: type,
    amount: thb(minor),
    accountId: account ?? cash,
    destinationAccountId: to,
    categoryId: type == TransactionType.transfer ? null : category,
    merchant: 'Shop',
    occurredAt: clock.now,
  );

  group('update', () {
    test('changes the editable fields and keeps identity', () async {
      final created = await transactions.create(draft());
      clock.now = clock.now.add(const Duration(hours: 1));

      final updated = await transactions.update(
        created.id,
        draft(minor: 9900, account: bank),
      );

      expect(updated.id, created.id);
      expect(updated.amount, thb(9900));
      expect(updated.accountId, bank);
      expect(updated.source, TransactionSource.manual);
      expect(updated.createdAt, created.createdAt);
      expect(updated.updatedAt.isAfter(created.updatedAt), isTrue);
    });

    test('can turn an expense into a transfer', () async {
      final created = await transactions.create(draft());
      final updated = await transactions.update(
        created.id,
        draft(type: TransactionType.transfer, to: bank),
      );
      expect(updated.type, TransactionType.transfer);
      expect(updated.destinationAccountId, bank);
      expect(updated.categoryId, isNull);
    });

    test('keeps the scan link and attachment of a slip transaction', () async {
      final scans = DriftScanRepository(db, clock);
      final scan = await scans.create(
        id: ids.newId(),
        source: ImportSource.gallery,
        attachmentPath: 'slips/a.jpg',
        imageFingerprint: 'fp',
      );
      await scans.transition(scan.id, ScanStatus.processing);
      await scans.transition(scan.id, ScanStatus.needsReview);
      final confirmed = await transactions.confirmFromScan(
        scanRecordId: scan.id,
        draft: draft(),
      );

      final updated = await transactions.update(
        confirmed.transaction.id,
        draft(minor: 5000),
      );
      expect(updated.scanRecordId, scan.id);
      expect(updated.attachmentPath, 'slips/a.jpg');
      expect(updated.source, TransactionSource.ocr);
    });

    test('rejects an unknown id', () async {
      await expectLater(
        transactions.update('missing', draft()),
        throwsA(
          isA<AppFailure>().having((e) => e.code, 'code', FailureCode.notFound),
        ),
      );
    });

    test('the database still refuses a transfer to the same account', () async {
      final created = await transactions.create(draft());
      await expectLater(
        transactions.update(
          created.id,
          draft(type: TransactionType.transfer, to: cash),
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('the use case validates before writing', () async {
      final created = await transactions.create(draft());
      final useCase = UpdateTransaction(
        TransactionDraftChecker(accounts, categories),
        transactions,
      );
      await expectLater(
        useCase(created.id, draft(minor: 0)),
        throwsA(isA<InvalidTransactionException>()),
      );
      expect((await transactions.findById(created.id))!.amount, thb(4500));
    });
  });

  group('delete', () {
    test('removes the transaction', () async {
      final created = await transactions.create(draft());
      await transactions.delete(created.id);
      expect(await transactions.findById(created.id), isNull);
    });

    test('rejects an unknown id', () async {
      await expectLater(
        transactions.delete('missing'),
        throwsA(isA<AppFailure>()),
      );
    });

    test('a confirmed scan survives with its link cleared', () async {
      final scans = DriftScanRepository(db, clock);
      final scan = await scans.create(
        id: ids.newId(),
        source: ImportSource.camera,
        attachmentPath: 'slips/b.jpg',
        imageFingerprint: 'fp2',
      );
      await scans.transition(scan.id, ScanStatus.processing);
      await scans.transition(scan.id, ScanStatus.needsReview);
      final confirmed = await transactions.confirmFromScan(
        scanRecordId: scan.id,
        draft: draft(),
      );

      await transactions.delete(confirmed.transaction.id);

      final row = await (db.select(
        db.scanRecords,
      )..where((s) => s.id.equals(scan.id))).getSingle();
      expect(row.status, ScanStatus.confirmed.dbValue);
      expect(row.transactionId, isNull);
    });
  });

  group('categories', () {
    test('create adds an active user category', () async {
      final c = await categories.create(
        name: 'Pets',
        kind: CategoryKind.expense,
        iconKey: 'paw-print',
        colorValue: 0xFFE3E8EE,
      );
      expect(c.isDefault, isFalse);
      expect(c.iconKey, 'paw-print');
      final active = await categories
          .watchActive(kind: CategoryKind.expense)
          .first;
      expect(active.map((x) => x.name), contains('Pets'));
    });

    test('a new category can be used by a transaction', () async {
      final c = await categories.create(
        name: 'Pets',
        kind: CategoryKind.expense,
      );
      final tx = await transactions.create(draft(category: c.id));
      expect(tx.categoryId, c.id);
    });
  });

  group('account balances', () {
    const calc = AccountBalanceCalculator();

    Future<Map<String, int>> balances() async {
      final all = await transactions.watchAll().first;
      final accs = await accounts.watchActive().first;
      // Ignore the default cash account every install starts with.
      return {
        for (final e in calc.balances(accs, all).entries)
          if (e.key == cash || e.key == bank) e.key: e.value.minor,
      };
    }

    test('opening balance alone', () async {
      expect(await balances(), {cash: 100000, bank: 0});
    });

    test('income adds, expense subtracts, transfer moves money', () async {
      await transactions.create(
        draft(
          type: TransactionType.income,
          minor: 50000,
          category: 'default-income-salary',
        ),
      );
      await transactions.create(draft(minor: 4500));
      await transactions.create(
        draft(type: TransactionType.transfer, minor: 20000, to: bank),
      );
      expect(await balances(), {
        cash: 100000 + 50000 - 4500 - 20000,
        bank: 20000,
      });
    });

    test('a transfer leaves the total unchanged', () async {
      final before = (await balances()).values.fold(0, (a, b) => a + b);
      await transactions.create(
        draft(type: TransactionType.transfer, minor: 12345, to: bank),
      );
      final after = (await balances()).values.fold(0, (a, b) => a + b);
      expect(after, before);
    });

    test('editing and deleting keep balances correct', () async {
      final tx = await transactions.create(draft(minor: 4500));
      expect((await balances())[cash], 100000 - 4500);
      await transactions.update(tx.id, draft(minor: 1000));
      expect((await balances())[cash], 100000 - 1000);
      await transactions.delete(tx.id);
      expect((await balances())[cash], 100000);
    });
  });
}
