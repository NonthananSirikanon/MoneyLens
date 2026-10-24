import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/core/errors/app_failure.dart';
import 'package:moneylens/core/logging/app_logger.dart';
import 'package:moneylens/features/slip_import/application/slip_import_pipeline.dart';
import 'package:moneylens/features/slip_import/data/drift_scan_repository.dart';
import 'package:moneylens/features/slip_import/data/fingerprint_duplicate_detector.dart';
import 'package:moneylens/features/slip_import/data/magic_byte_image_validator.dart';
import 'package:moneylens/features/slip_import/data/unavailable_ocr_service.dart';
import 'package:moneylens/features/slip_import/domain/import_ports.dart';
import 'package:moneylens/features/slip_import/domain/scan_status.dart';
import 'package:moneylens/infrastructure/database/app_database.dart';

import '../support/test_support.dart';

void main() {
  late AppDatabase db;
  late MemorySlipImageStore store;
  late DriftScanRepository scans;
  late List<String> logLines;

  setUp(() {
    db = openTestDatabase();
    store = MemorySlipImageStore();
    scans = DriftScanRepository(db, FixedClock(DateTime.utc(2026, 10, 14)));
    logLines = [];
  });

  tearDown(() => db.close());

  SlipImportPipeline pipeline(OcrService ocr) => SlipImportPipeline(
    validator: const MagicByteImageValidator(),
    store: store,
    scans: scans,
    duplicates: FingerprintDuplicateDetector(scans),
    ocr: ocr,
    extraction: const EmptyExtractionService(),
    ids: SequentialIds(),
    logger: AppLogger(sink: (code, meta) => logLines.add('$code $meta')),
  );

  ImportRequest request(ImportSource source, [int salt = 0]) =>
      ImportRequest(source: source, bytes: fakeJpeg(salt));

  test('OCR success ends in needs_review, never confirmed', () async {
    final scan = await pipeline(StubOcrService())
        .ingest(request(ImportSource.camera));

    expect(scan.status, ScanStatus.needsReview);
    expect(scan.processorVersion, SlipImportPipeline.processorVersion);
    expect(scan.extracted, isNotNull);
    expect(await db.select(db.transactions).get(), isEmpty);
  });

  test('every source goes through the same pipeline (SL-04)', () async {
    final p = pipeline(StubOcrService());
    var salt = 0;
    for (final source in [
      ImportSource.camera,
      ImportSource.gallery,
      ImportSource.shareSheet,
    ]) {
      final scan = await p.ingest(request(source, salt++));
      expect(scan.status, ScanStatus.needsReview, reason: source.name);
      expect(scan.source, source);
    }
  });

  test('the placeholder OCR fails visibly and the scan is retryable', () async {
    final p = pipeline(const UnavailableOcrService());
    final failed = await p.ingest(request(ImportSource.gallery));

    expect(failed.status, ScanStatus.failed);
    expect(failed.failureCode, FailureCode.ocrUnavailable);
    expect(failed.status.canTransitionTo(ScanStatus.queued), isTrue);
  });

  test('retry re-runs a failed scan', () async {
    final failing = await pipeline(
      StubOcrService(failWith: FailureCode.ocrUnavailable),
    ).ingest(request(ImportSource.gallery));

    final retried = await pipeline(StubOcrService()).retry(failing.id);
    expect(retried.status, ScanStatus.needsReview);
    expect(retried.failureCode, isNull);
  });

  test(
    're-importing the same image is flagged as duplicate before OCR',
    () async {
      final ocr = StubOcrService();
      final p = pipeline(ocr);
      final first = await p.ingest(request(ImportSource.gallery));
      final second = await p.ingest(request(ImportSource.shareSheet));

      expect(second.status, ScanStatus.duplicate);
      expect(second.duplicateOfScanId, first.id);
      expect(ocr.calls, 1);
    },
  );

  test('rejected files create no scan record', () async {
    final p = pipeline(StubOcrService());
    final notAnImage = ImportRequest(
      source: ImportSource.gallery,
      bytes: fakeJpeg()..[0] = 0x00,
    );

    await expectLater(p.ingest(notAnImage), throwsA(isA<AppFailure>()));
    expect(await db.select(db.scanRecords).get(), isEmpty);
    expect(store.files, isEmpty);
  });

  test('discard removes the app-owned image', () async {
    final p = pipeline(const UnavailableOcrService());
    final scan = await p.ingest(request(ImportSource.camera));
    expect(store.files, hasLength(1));

    final discarded = await p.discard(scan.id);
    expect(discarded.status, ScanStatus.discarded);
    expect(discarded.attachmentPath, isNull);
    expect(store.files, isEmpty);
  });

  test('recovered scans can be processed again', () async {
    final p = pipeline(StubOcrService());
    final scan = await scans.create(
      id: 'stuck',
      source: ImportSource.camera,
      attachmentPath: 'slips/x.jpg',
      imageFingerprint: 'unique',
    );
    await scans.transition(scan.id, ScanStatus.processing);

    await p.recoverInterrupted();
    final resumed = await p.retry(scan.id);
    expect(resumed.status, ScanStatus.needsReview);
  });

  test('logs carry codes only, never OCR text or amounts', () async {
    await pipeline(StubOcrService()).ingest(request(ImportSource.camera));
    expect(logLines, isNotEmpty);
    expect(logLines.join('\n'), isNot(contains('stub')));
  });
}
