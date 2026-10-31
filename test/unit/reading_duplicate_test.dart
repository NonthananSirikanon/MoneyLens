import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/core/logging/app_logger.dart';
import 'package:moneylens/core/money/currency.dart';
import 'package:moneylens/features/accounts/data/drift_account_repository.dart';
import 'package:moneylens/features/accounts/domain/account.dart';
import 'package:moneylens/features/categories/data/drift_category_repository.dart';
import 'package:moneylens/features/slip_import/application/confirm_scan.dart';
import 'package:moneylens/features/slip_import/application/slip_import_pipeline.dart';
import 'package:moneylens/features/slip_import/data/drift_scan_repository.dart';
import 'package:moneylens/features/slip_import/data/fingerprint_duplicate_detector.dart';
import 'package:moneylens/features/slip_import/data/magic_byte_image_validator.dart';
import 'package:moneylens/features/slip_import/data/reference_duplicate_detector.dart';
import 'package:moneylens/features/slip_import/data/thai_slip_extraction_service.dart';
import 'package:moneylens/features/slip_import/domain/import_ports.dart';
import 'package:moneylens/features/slip_import/domain/scan_record.dart';
import 'package:moneylens/features/slip_import/domain/scan_status.dart';
import 'package:moneylens/features/transactions/application/transaction_draft_checker.dart';
import 'package:moneylens/features/transactions/data/drift_transaction_repository.dart';
import 'package:moneylens/features/transactions/domain/transaction.dart';
import 'package:moneylens/features/transactions/domain/transaction_type.dart';
import 'package:moneylens/infrastructure/database/app_database.dart';

import '../support/test_support.dart';

/// Second duplicate layer (DATABASE.md section 6): a slip whose bank
/// reference, amount, time and counterparty match a saved transaction is
/// flagged as a duplicate, even when the image file is different. Slips are
/// the invented fixtures in test/fixtures/slips.
void main() {
  String slip(String name) =>
      File('test/fixtures/slips/$name.txt').readAsStringSync();

  late AppDatabase db;
  late FixedClock clock;
  late SequentialIds ids;
  late DriftScanRepository scans;
  late DriftTransactionRepository transactions;
  late ConfirmScan confirm;
  late StubOcrService ocr;
  late SlipImportPipeline pipeline;
  late String account;
  late List<String> logLines;
  var salt = 0;

  setUp(() async {
    db = openTestDatabase();
    clock = FixedClock(DateTime.utc(2026, 10, 14, 5));
    ids = SequentialIds();
    logLines = [];
    salt = 0;
    scans = DriftScanRepository(db, clock);
    transactions = DriftTransactionRepository(db, clock, ids);
    final accounts = DriftAccountRepository(db, clock, ids);
    account = (await accounts.create(
      name: 'Bank',
      kind: AccountKind.bank,
      currency: Currency.thb,
    )).id;
    confirm = ConfirmScan(
      TransactionDraftChecker(
        accounts,
        DriftCategoryRepository(db, clock, ids),
      ),
      transactions,
    );
    ocr = StubOcrService();
    pipeline = SlipImportPipeline(
      validator: const MagicByteImageValidator(),
      store: MemorySlipImageStore(),
      scans: scans,
      duplicates: FingerprintDuplicateDetector(scans),
      readingDuplicates: ReferenceDuplicateDetector(transactions),
      ocr: ocr,
      extraction: const ThaiSlipExtractionService(),
      ids: ids,
      logger: AppLogger(sink: (code, meta) => logLines.add('$code $meta')),
    );
  });

  tearDown(() => db.close());

  /// Shares [fixture] as a new file (different bytes each time).
  Future<ScanRecord> share(String fixture) {
    ocr.text = slip(fixture);
    return pipeline.ingest(
      ImportRequest(source: ImportSource.gallery, bytes: fakeJpeg(++salt)),
    );
  }

  /// The user accepts what was read, as the review screen would.
  Future<ConfirmResult> save(ScanRecord scan) {
    final f = scan.extracted!;
    return confirm(
      scanId: scan.id,
      reviewedDraft: TransactionDraft(
        type: TransactionType.expense,
        amount: thb(f.amountMinor!.value),
        accountId: account,
        categoryId: 'default-expense-food',
        merchant: f.merchant?.value,
        occurredAt: f.occurredAt!.value,
        source: TransactionSource.ocr,
        providerReference: f.providerReference?.value,
      ),
    );
  }

  test('the same slip shared again as a different file is a duplicate '
      'of the saved transaction', () async {
    final first = await share('kbank_transfer');
    final saved = await save(first);

    final again = await share('kbank_transfer');

    expect(again.status, ScanStatus.duplicate);
    expect(again.duplicateOfScanId, first.id);
    // The same pointer the UI already follows: scan -> its transaction.
    final original = await scans.findById(again.duplicateOfScanId!);
    expect(original!.transactionId, saved.transaction.id);
    // The new reading is kept so the duplicate screen can show it.
    expect(again.extracted!.amountMinor!.value, 125050);
    expect(ocr.calls, 2, reason: 'a different file still has to be read');
    expect(await db.select(db.transactions).get(), hasLength(1));
  });

  test('"not a duplicate" still sends it to review', () async {
    final first = await share('kbank_transfer');
    await save(first);
    final again = await share('kbank_transfer');

    final kept = await pipeline.keepDuplicate(again.id);

    expect(kept.status, ScanStatus.needsReview);
  });

  test('the same amount at the same minute from a different person '
      'is not a duplicate', () async {
    await save(await share('kbank_transfer'));

    final other = await share('kbank_transfer_other_payee');

    expect(other.status, ScanStatus.needsReview);
  });

  test('the same amount to the same person later that day '
      'is not a duplicate', () async {
    await save(await share('kbank_transfer'));

    final repeat = await share('kbank_transfer_later_same_payee');

    expect(repeat.status, ScanStatus.needsReview);
  });

  test('the same reference with a different amount and time is not '
      'flagged: a reference is not trusted on its own', () async {
    // A reference can repeat for legitimate reasons (a bill reference paid
    // monthly) or be misread, so it only counts together with the rest of
    // the key. The user still sees both on the list.
    await save(await share('kbank_transfer'));

    final other = await share('kbank_transfer_same_ref_other_amount');

    expect(other.status, ScanStatus.needsReview);
  });

  test('a slip with no readable reference is never flagged by content, '
      'even if amount, time and payee match', () async {
    await save(await share('kbank_transfer'));

    final noRef = await share('kbank_transfer_no_reference');

    expect(noRef.extracted!.providerReference, isNull);
    expect(noRef.status, ScanStatus.needsReview);
  });

  test('spacing, case and dashes in the saved reference do not hide a '
      'match', () async {
    final first = await share('kbank_transfer');
    final f = first.extracted!;
    await confirm(
      scanId: first.id,
      reviewedDraft: TransactionDraft(
        type: TransactionType.expense,
        amount: thb(f.amountMinor!.value),
        accountId: account,
        categoryId: 'default-expense-food',
        merchant: f.merchant!.value,
        occurredAt: f.occurredAt!.value,
        providerReference: '0123-4567 8901 aor00000',
      ),
    );

    expect((await share('kbank_transfer')).status, ScanStatus.duplicate);
  });

  test('a transaction that was deleted no longer blocks the slip', () async {
    final saved = await save(await share('kbank_transfer'));
    await transactions.delete(saved.transaction.id);

    expect((await share('kbank_transfer')).status, ScanStatus.needsReview);
  });

  test('an unconfirmed earlier scan does not flag a new one', () async {
    await share('kbank_transfer'); // left in needs_review

    expect((await share('kbank_transfer')).status, ScanStatus.needsReview);
  });

  test('a manual transaction with the same reference cannot be pointed at, '
      'so it is not flagged', () async {
    // A duplicate scan links to another scan (duplicate_of_scan_id) and
    // there is no column for "duplicate of a transaction". Manual entries
    // have no scan, so there is nothing to link to without a schema change.
    final probe = await share('kbank_transfer');
    final f = probe.extracted!;
    await transactions.create(
      TransactionDraft(
        type: TransactionType.expense,
        amount: thb(f.amountMinor!.value),
        accountId: account,
        categoryId: 'default-expense-food',
        merchant: f.merchant!.value,
        occurredAt: f.occurredAt!.value,
        providerReference: f.providerReference!.value,
      ),
    );

    expect((await share('kbank_transfer')).status, ScanStatus.needsReview);
  });

  test('confirming the same scan twice returns the same transaction', () async {
    final scan = await share('kbank_transfer');

    final first = await save(scan);
    final second = await save(scan);

    expect(first.alreadyConfirmed, isFalse);
    expect(second.alreadyConfirmed, isTrue);
    expect(second.transaction.id, first.transaction.id);
    expect(await db.select(db.transactions).get(), hasLength(1));
  });

  test('flagging a duplicate logs no slip content', () async {
    await save(await share('kbank_transfer'));
    await share('kbank_transfer');

    final log = logLines.join('\n');
    expect(log, contains('scan_duplicate'));
    for (final secret in ['AOR00000', '1250', '1,250', 'สมชาย', '012345']) {
      expect(log, isNot(contains(secret)));
    }
  });
}
