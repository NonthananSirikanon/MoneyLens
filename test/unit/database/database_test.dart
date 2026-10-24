import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/core/errors/app_failure.dart';
import 'package:moneylens/core/money/currency.dart';
import 'package:moneylens/features/accounts/data/drift_account_repository.dart';
import 'package:moneylens/features/accounts/domain/account.dart';
import 'package:moneylens/features/categories/domain/category.dart';
import 'package:moneylens/features/slip_import/data/drift_scan_repository.dart';
import 'package:moneylens/features/slip_import/domain/scan_status.dart';
import 'package:moneylens/features/transactions/data/drift_transaction_repository.dart';
import 'package:moneylens/features/transactions/domain/transaction.dart';
import 'package:moneylens/features/transactions/domain/transaction_type.dart';
import 'package:moneylens/infrastructure/database/app_database.dart';
import 'package:moneylens/infrastructure/database/seed/default_categories.dart';
import 'package:drift/native.dart' show SqliteException;

import '../../support/test_support.dart';

void main() {
  late AppDatabase db;
  late FixedClock clock;
  late SequentialIds ids;
  late DriftTransactionRepository transactions;
  late DriftScanRepository scans;
  late String cash;
  late String bank;

  setUp(() async {
    db = openTestDatabase();
    clock = FixedClock(DateTime.utc(2026, 10, 14, 5));
    ids = SequentialIds();
    transactions = DriftTransactionRepository(db, clock, ids);
    scans = DriftScanRepository(db, clock);
    final accounts = DriftAccountRepository(db, clock, ids);
    cash = (await accounts.create(
      name: 'Cash',
      kind: AccountKind.cash,
      currency: Currency.thb,
    )).id;
    bank = (await accounts.create(
      name: 'Bank',
      kind: AccountKind.bank,
      currency: Currency.thb,
    )).id;
  });

  tearDown(() => db.close());

  TransactionDraft expense({int minor = 4500}) => TransactionDraft(
    type: TransactionType.expense,
    amount: thb(minor),
    accountId: cash,
    categoryId: 'default-expense-food',
    occurredAt: clock.now,
  );

  Future<String> reviewableScan() async {
    final scan = await scans.create(
      id: ids.newId(),
      source: ImportSource.gallery,
      attachmentPath: 'slips/a.jpg',
      imageFingerprint: 'fp',
    );
    await scans.transition(scan.id, ScanStatus.processing);
    await scans.transition(scan.id, ScanStatus.needsReview);
    return scan.id;
  }

  group('schema and seed', () {
    test('seeds default categories on create, idempotently', () async {
      final before = await db.select(db.categories).get();
      expect(before, isNotEmpty);
      expect(before.every((c) => c.isDefault), isTrue);

      await seedDefaultCategories(db, clock.now);
      final after = await db.select(db.categories).get();
      expect(after.length, before.length);
    });

    test('CHECK constraints accept every domain enum value', () async {
      // Guards against the SQL CHECK lists drifting from the Dart enums.
      for (final kind in AccountKind.values) {
        await db
            .into(db.accounts)
            .insert(
              AccountsCompanion.insert(
                id: 'acc-${kind.dbValue}',
                name: kind.name,
                kind: kind.dbValue,
                currencyCode: 'THB',
                createdAt: clock.now,
                updatedAt: clock.now,
              ),
            );
      }
      for (final kind in CategoryKind.values) {
        await db
            .into(db.categories)
            .insert(
              CategoriesCompanion.insert(
                id: 'cat-${kind.dbValue}',
                name: kind.name,
                kind: kind.dbValue,
                createdAt: clock.now,
                updatedAt: clock.now,
              ),
            );
      }
      for (final source in TransactionSource.values) {
        await transactions.create(
          TransactionDraft(
            type: TransactionType.expense,
            amount: thb(1),
            accountId: cash,
            occurredAt: clock.now,
            source: source,
          ),
        );
      }
      for (final source in ImportSource.values) {
        await scans.create(
          id: 'scan-${source.dbValue}',
          source: source,
          attachmentPath: 'p',
          imageFingerprint: source.dbValue,
        );
      }
      for (final status in ScanStatus.values) {
        await (db.update(db.scanRecords)
              ..where((s) => s.id.equals('scan-camera')))
            .write(ScanRecordsCompanion(status: Value(status.dbValue)));
      }
    });

    test('rejects non-positive amounts at the database level', () async {
      expect(
        () => transactions.create(expense(minor: 0)),
        throwsA(isA<SqliteException>()),
      );
    });

    test('rejects a transfer to the same account', () async {
      expect(
        () => transactions.create(
          TransactionDraft(
            type: TransactionType.transfer,
            amount: thb(100),
            accountId: cash,
            destinationAccountId: cash,
            occurredAt: clock.now,
          ),
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('rejects a transfer with a category', () async {
      expect(
        () => transactions.create(
          TransactionDraft(
            type: TransactionType.transfer,
            amount: thb(100),
            accountId: cash,
            destinationAccountId: bank,
            categoryId: 'default-expense-food',
            occurredAt: clock.now,
          ),
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('rejects an expense with a destination account', () async {
      expect(
        () => transactions.create(
          TransactionDraft(
            type: TransactionType.expense,
            amount: thb(100),
            accountId: cash,
            destinationAccountId: bank,
            occurredAt: clock.now,
          ),
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('enforces foreign keys', () async {
      expect(
        () => transactions.create(
          TransactionDraft(
            type: TransactionType.expense,
            amount: thb(100),
            accountId: 'missing',
            occurredAt: clock.now,
          ),
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('allows two identical payments on the same day', () async {
      // Amount + date must never act as a uniqueness key (DATABASE.md §6).
      await transactions.create(expense());
      await transactions.create(expense());
      expect(await db.select(db.transactions).get(), hasLength(2));
    });

    test('stores and returns instants in UTC', () async {
      final created = await transactions.create(expense());
      expect(created.occurredAt.isUtc, isTrue);
      expect(created.occurredAt, clock.now);
    });
  });

  group('confirmFromScan', () {
    test('creates one transaction and links the scan', () async {
      final scanId = await reviewableScan();
      final result = await transactions.confirmFromScan(
        scanRecordId: scanId,
        draft: expense(),
      );

      expect(result.alreadyConfirmed, isFalse);
      expect(result.transaction.scanRecordId, scanId);
      expect(result.transaction.source, TransactionSource.ocr);
      expect(result.transaction.attachmentPath, 'slips/a.jpg');

      final scan = await scans.findById(scanId);
      expect(scan!.status, ScanStatus.confirmed);
      expect(scan.transactionId, result.transaction.id);
    });

    test('is idempotent: a repeat returns the existing row', () async {
      final scanId = await reviewableScan();
      final first = await transactions.confirmFromScan(
        scanRecordId: scanId,
        draft: expense(),
      );
      final second = await transactions.confirmFromScan(
        scanRecordId: scanId,
        draft: expense(minor: 9999),
      );

      expect(second.alreadyConfirmed, isTrue);
      expect(second.transaction.id, first.transaction.id);
      expect(await db.select(db.transactions).get(), hasLength(1));
    });

    test('concurrent double-tap still yields one transaction', () async {
      final scanId = await reviewableScan();
      final results = await Future.wait([
        transactions.confirmFromScan(scanRecordId: scanId, draft: expense()),
        transactions.confirmFromScan(scanRecordId: scanId, draft: expense()),
      ]);

      expect(results.where((r) => !r.alreadyConfirmed), hasLength(1));
      expect(await db.select(db.transactions).get(), hasLength(1));
    });

    test(
      'the UNIQUE scan link blocks a second row even past app checks',
      () async {
        final scanId = await reviewableScan();
        await transactions.confirmFromScan(
          scanRecordId: scanId,
          draft: expense(),
        );
        expect(
          () => db
              .into(db.transactions)
              .insert(
                TransactionsCompanion.insert(
                  id: 'sneaky',
                  type: 'expense',
                  amountMinor: 1,
                  currencyCode: 'THB',
                  accountId: cash,
                  occurredAt: clock.now,
                  source: 'ocr',
                  scanRecordId: Value(scanId),
                  createdAt: clock.now,
                  updatedAt: clock.now,
                ),
              ),
          throwsA(isA<SqliteException>()),
        );
      },
    );

    test('refuses scans that have not been reviewed', () async {
      final scan = await scans.create(
        id: 'raw',
        source: ImportSource.camera,
        attachmentPath: 'p',
        imageFingerprint: 'f',
      );
      expect(
        () => transactions.confirmFromScan(
          scanRecordId: scan.id,
          draft: expense(),
        ),
        throwsA(
          isA<AppFailure>().having(
            (f) => f.code,
            'code',
            FailureCode.invalidScanState,
          ),
        ),
      );
      expect(await db.select(db.transactions).get(), isEmpty);
    });
  });

  group('scan repository', () {
    test('rejects illegal transitions', () async {
      final scan = await scans.create(
        id: 's',
        source: ImportSource.camera,
        attachmentPath: 'p',
        imageFingerprint: 'f',
      );
      expect(
        () => scans.transition(scan.id, ScanStatus.needsReview),
        throwsA(isA<AppFailure>()),
      );
      expect(
        () => scans.transition(scan.id, ScanStatus.confirmed),
        throwsA(isA<AppFailure>()),
      );
    });

    test('requeues scans interrupted mid-processing', () async {
      final scan = await scans.create(
        id: 's',
        source: ImportSource.camera,
        attachmentPath: 'p',
        imageFingerprint: 'f',
      );
      await scans.transition(scan.id, ScanStatus.processing);

      expect(await scans.requeueInterrupted(), 1);
      expect((await scans.findById(scan.id))!.status, ScanStatus.queued);
    });
  });
}
