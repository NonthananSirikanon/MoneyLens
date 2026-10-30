import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/core/dates/clock.dart';
import 'package:moneylens/core/errors/app_failure.dart';
import 'package:moneylens/core/dates/reporting_time_zone.dart';
import 'package:moneylens/demo/demo_config.dart';
import 'package:moneylens/demo/demo_models.dart';
import 'package:moneylens/demo/demo_store.dart';
import 'package:moneylens/features/slip_import/application/slip_import_providers.dart';
import 'package:moneylens/features/slip_import/domain/import_ports.dart';
import 'package:moneylens/features/slip_import/domain/scan_record.dart';
import 'package:moneylens/features/slip_import/domain/scan_status.dart';
import 'package:moneylens/features/transactions/domain/transaction_type.dart';
import 'package:moneylens/infrastructure/database/app_database.dart';

import '../support/test_support.dart';

/// The whole real path behind the UI: pick a photo, read it, review, save.
/// The "engine" is a stub that returns text laid out like a Thai bank slip.
void main() {
  final slipText = File('test/fixtures/slips/kbank_transfer.txt')
      .readAsStringSync();
  final now = ReportingTimeZone.bangkok.toUtc(2026, 10, 30, 12);

  late AppDatabase db;
  late ProviderContainer container;
  late StubOcrService ocr;
  late FakeImageSource gallery;
  late DemoStore store;

  setUp(() async {
    db = openTestDatabase();
    ocr = StubOcrService(text: slipText);
    gallery = FakeImageSource(ImportSource.gallery, bytes: fakeJpeg(1));
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sampleDataEnabledProvider.overrideWithValue(false),
        clockProvider.overrideWithValue(FixedClock(now)),
        slipImageStoreProvider.overrideWithValue(MemorySlipImageStore()),
        ocrServiceProvider.overrideWithValue(ocr),
        imageSourcesProvider.overrideWithValue({ImportSource.gallery: gallery}),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    // Let the ledger load, as app startup does.
    await container.read(demoStoreProvider.notifier).loadScans();
    store = container.read(demoStoreProvider.notifier);
  });

  DemoState st() => container.read(demoStoreProvider);

  /// Waits until the background read of [id] ends.
  Future<ScanRecord> settled(String id) async {
    for (var i = 0; i < 200; i++) {
      await pumpEventQueue();
      final scan = st().scan(id);
      if (scan != null &&
          scan.status != ScanStatus.queued &&
          scan.status != ScanStatus.processing) {
        return scan;
      }
    }
    fail('the scan never finished');
  }

  Future<ScanRecord> importSlip() async {
    final queued = await store.importFrom(ImportSource.gallery);
    expect(queued, isNotNull);
    return settled(queued!.id);
  }

  test(
    'a picked photo is read and waits for review with what it found',
    () async {
      final scan = await importSlip();
      expect(scan.status, ScanStatus.needsReview);
      expect(store.pending.map((e) => e.id), [scan.id]);

      final r = st().scanDetails[scan.id]!.reading!;
      expect(r.amountText, '1250.50');
      expect(r.merchant, 'นาย สมชาย ทดสอบ');
      expect(r.occurredAt, ReportingTimeZone.bangkok.toUtc(2026, 2, 12, 9, 5));
      expect(r.providerReference, isNotNull);
      expect(r.accountId, isNull); // a slip does not say which account
      expect(r.confidence[ReadingField.amount], FieldConfidence.verified);
      // The category is always for the user to choose.
      expect(r.confidence[ReadingField.category], FieldConfidence.missing);
    },
  );

  test(
    'saving the reviewed slip creates one transaction and confirms the scan',
    () async {
      final scan = await importSlip();
      final r = st().scanDetails[scan.id]!.reading!;
      final id = await store.addTransaction(
        TransactionInput(
          type: TransactionType.expense,
          amount: thb(125050),
          accountId: 'default-cash',
          categoryId: 'default-expense-food',
          merchant: r.merchant,
          occurredAt: r.occurredAt,
          scanId: scan.id,
        ),
      );

      final tx = st().transaction(id)!;
      expect(tx.amount, thb(125050));
      expect(tx.scanRecordId, scan.id);
      expect(tx.attachmentPath, scan.attachmentPath);
      expect(st().scan(scan.id)!.status, ScanStatus.confirmed);
      expect(st().scan(scan.id)!.transactionId, id);
      expect(store.pending, isEmpty);
      expect(st().transactionImportSources[id], ImportSource.gallery);

      // Saving the same slip again does not add a second transaction.
      final again = await store.addTransaction(
        TransactionInput(
          type: TransactionType.expense,
          amount: thb(125050),
          accountId: 'default-cash',
          categoryId: 'default-expense-food',
          merchant: r.merchant,
          occurredAt: r.occurredAt,
          scanId: scan.id,
        ),
      );
      expect(again, id);
      expect(
        st().transactions.where((t) => t.scanRecordId == scan.id),
        hasLength(1),
      );
    },
  );

  test(
    'the same picture twice is a duplicate that points at the first',
    () async {
      final first = await importSlip();
      final saved = await store.addTransaction(
        TransactionInput(
          type: TransactionType.expense,
          amount: thb(125050),
          accountId: 'default-cash',
          categoryId: 'default-expense-food',
          merchant: 'x',
          occurredAt: now,
          scanId: first.id,
        ),
      );

      final second = await importSlip();
      expect(second.status, ScanStatus.duplicate);
      final d = st().scanDetails[second.id]!;
      expect(d.duplicateOfTransactionId, saved);
      // It shows what the first one read.
      expect(d.reading?.amountText, '1250.50');
      expect(store.pending.map((e) => e.id), contains(second.id));

      // "Not a duplicate": it is read after all and goes to review.
      await store.keepDuplicate(second.id);
      expect(st().scan(second.id)!.status, ScanStatus.needsReview);
      expect(ocr.calls, 2);
    },
  );

  test('discarding a duplicate takes it out of the queue', () async {
    await importSlip();
    final dup = await importSlip();
    store.discardScan(dup.id);
    await pumpEventQueue();
    expect(st().scans.map((e) => e.id), isNot(contains(dup.id)));
  });

  test('a read that fails says why and can be retried', () async {
    ocr.failWith = FailureCode.unreadableImage;
    final failed = await importSlip();
    expect(failed.status, ScanStatus.failed);
    expect(failed.failureCode, FailureCode.unreadableImage);
    expect(store.pending, isEmpty);

    ocr.failWith = null;
    store.retryFailed(failed.id);
    final again = await settled(failed.id);
    expect(again.status, ScanStatus.needsReview);
    expect(st().scanDetails[failed.id]!.reading!.amountText, '1250.50');
  });

  test(
    'text that is not a slip still reaches review, with everything missing',
    () async {
      ocr.text = 'hello world';
      final scan = await importSlip();
      expect(scan.status, ScanStatus.needsReview);
      final r = st().scanDetails[scan.id]!.reading!;
      expect(r.amountText, isEmpty);
      expect(r.merchant, isEmpty);
      expect(r.confidence[ReadingField.amount], FieldConfidence.missing);
    },
  );

  test(
    'a cancelled picker adds nothing and a refused permission is reported',
    () async {
      gallery.bytes = null;
      expect(await store.importFrom(ImportSource.gallery), isNull);
      expect(st().scans, isEmpty);

      gallery.failWith = FailureCode.permissionDenied;
      await expectLater(
        store.importFrom(ImportSource.gallery),
        throwsA(
          isA<AppFailure>().having(
            (e) => e.code,
            'code',
            FailureCode.permissionDenied,
          ),
        ),
      );
    },
  );

  test('a file that is not a picture is refused and leaves no scan', () async {
    gallery.bytes = Uint8List.fromList([1, 2, 3]);
    await expectLater(
      store.importFrom(ImportSource.gallery),
      throwsA(isA<AppFailure>()),
    );
    expect(st().scans, isEmpty);
  });

  test('a scan left queued by a crash is read when the app starts', () async {
    final repo = container.read(scanRepositoryProvider);
    final stored = await container
        .read(slipImageStoreProvider)
        .save(fakeJpeg(9), ImageFormat.jpeg);
    final queued = await repo.create(
      id: 'left-over',
      source: ImportSource.camera,
      attachmentPath: stored.relativePath,
      imageFingerprint: stored.fingerprint,
    );
    expect(queued.status, ScanStatus.queued);

    await store.loadScans();
    final scan = await settled('left-over');
    expect(scan.status, ScanStatus.needsReview);
  });
}
