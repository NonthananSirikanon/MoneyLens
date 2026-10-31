import '../../../core/errors/app_failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/utils/id_generator.dart';
import '../domain/import_ports.dart';
import '../domain/scan_record.dart';
import '../domain/scan_repository.dart';
import '../domain/scan_status.dart';

/// The single processing pipeline for every import source
/// (ARCHITECTURE.md §5, PROJECT.md SL-04).
///
/// validate → store → scan record (queued) → processing → image duplicate
/// check → OCR → extraction → reading duplicate check → `needs_review`, or
/// `duplicate` / `failed`.
///
/// It never confirms a transaction. Confirmation is a separate user action
/// (see `ConfirmScan`).
class SlipImportPipeline {
  const SlipImportPipeline({
    required this._validator,
    required this._store,
    required this._scans,
    required this._duplicates,
    required this._readingDuplicates,
    required this._ocr,
    required this._extraction,
    required this._ids,
    required this._logger,
  });

  /// Recorded on each scan for debugging and evaluation. Bump it whenever
  /// the way a slip is read changes, so older scans stay comparable.
  static const processorVersion = 'ocr-vote-1';

  final ImageValidator _validator;
  final SlipImageStore _store;
  final ScanRepository _scans;
  final DuplicateDetector _duplicates;
  final ReadingDuplicateDetector _readingDuplicates;
  final OcrService _ocr;
  final ExtractionService _extraction;
  final IdGenerator _ids;
  final AppLogger _logger;

  /// Accepts an image and runs it through the pipeline.
  ///
  /// Throws [AppFailure] when the file itself is rejected; no scan record
  /// is created for it. Every failure after that is recorded on the scan.
  Future<ScanRecord> ingest(ImportRequest request) async {
    final scan = await accept(request);
    return process(scan.id);
  }

  /// The first half of [ingest]: validate, store the image and create the
  /// scan as `queued`, without reading it yet. The caller then runs
  /// [process], which lets the UI show the scan straight away while it is
  /// being read.
  Future<ScanRecord> accept(ImportRequest request) async {
    final format = _validator.validate(request.bytes);
    final stored = await _store.save(request.bytes, format);
    final scan = await _scans.create(
      id: _ids.newId(),
      source: request.source,
      attachmentPath: stored.relativePath,
      imageFingerprint: stored.fingerprint,
    );
    _logger.event('scan_created', {'source': request.source, 'format': format});
    return scan;
  }

  /// Processes a `queued` scan. Safe to call again after [retry].
  Future<ScanRecord> process(String scanId) async {
    final scan = await _scans.transition(scanId, ScanStatus.processing);
    final stopwatch = Stopwatch()..start();
    try {
      // Exact re-imports are caught before spending OCR effort.
      final duplicate = await _duplicates.check(scan);
      if (duplicate.isDuplicate) {
        _logger.event('scan_duplicate', {'layer': 'image'});
        return await _scans.transition(
          scanId,
          ScanStatus.duplicate,
          duplicateOfScanId: duplicate.duplicateOfScanId,
          processorVersion: processorVersion,
        );
      }

      final path = scan.attachmentPath;
      if (path == null) throw const AppFailure(FailureCode.unreadableImage);
      final ocrResult = await _ocr.recognize(await _store.resolve(path));
      final fields = await _extraction.extract(ocrResult);

      // A different file of a slip that is already saved (a screenshot of
      // it, a second photo) is caught from what was read.
      final sameReading = await _readingDuplicates.check(scan, fields);
      if (sameReading.isDuplicate) {
        _logger.event('scan_duplicate', {'layer': 'reading'});
        return await _scans.transition(
          scanId,
          ScanStatus.duplicate,
          extracted: fields,
          duplicateOfScanId: sameReading.duplicateOfScanId,
          processorVersion: processorVersion,
        );
      }

      _logger.event('scan_needs_review', {
        'missingFields': fields.missingRequiredFields.length,
        'elapsed': stopwatch.elapsed,
      });
      return await _scans.transition(
        scanId,
        ScanStatus.needsReview,
        extracted: fields,
        processorVersion: processorVersion,
      );
    } on AppFailure catch (failure) {
      return _fail(scanId, failure.code);
    } catch (_) {
      // Unknown errors may embed provider output, so record only a code.
      return _fail(scanId, FailureCode.unexpected);
    }
  }

  /// Re-runs a `failed` scan, one the user sends back from review, or a
  /// `queued` scan left over from startup recovery.
  Future<ScanRecord> retry(String scanId) async {
    final scan = await _scans.findById(scanId);
    if (scan == null) throw const AppFailure(FailureCode.notFound);
    if (scan.status != ScanStatus.queued) {
      await _scans.transition(scanId, ScanStatus.queued);
    }
    return process(scanId);
  }

  /// "This is not a duplicate": reads a `duplicate` scan after all and moves
  /// it to review. Throws [AppFailure] (the scan stays a duplicate) when the
  /// image cannot be read.
  Future<ScanRecord> keepDuplicate(String scanId) async {
    final scan = await _scans.findById(scanId);
    if (scan == null) throw const AppFailure(FailureCode.notFound);
    if (scan.status != ScanStatus.duplicate) return scan;
    final path = scan.attachmentPath;
    if (path == null) throw const AppFailure(FailureCode.unreadableImage);
    final ocrResult = await _ocr.recognize(await _store.resolve(path));
    final fields = await _extraction.extract(ocrResult);
    _logger.event('scan_duplicate_kept');
    return _scans.transition(
      scanId,
      ScanStatus.needsReview,
      extracted: fields,
      processorVersion: processorVersion,
    );
  }

  /// Removes a scan from the workflow and deletes its app-owned image.
  Future<ScanRecord> discard(String scanId) async {
    final scan = await _scans.findById(scanId);
    if (scan == null) throw const AppFailure(FailureCode.notFound);
    final discarded = await _scans.transition(
      scanId,
      ScanStatus.discarded,
      clearAttachment: true,
    );
    final path = scan.attachmentPath;
    if (path != null) await _store.delete(path);
    return discarded;
  }

  /// Startup recovery: scans interrupted mid-processing become `queued`
  /// again, then are processed (ARCHITECTURE.md §7).
  Future<void> recoverInterrupted() async {
    final recovered = await _scans.requeueInterrupted();
    if (recovered > 0) _logger.event('scans_requeued', {'count': recovered});
  }

  Future<ScanRecord> _fail(String scanId, FailureCode code) {
    _logger.event('scan_failed', {'code': code});
    return _scans.transition(
      scanId,
      ScanStatus.failed,
      failureCode: code,
      processorVersion: processorVersion,
    );
  }
}
