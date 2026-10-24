import '../../../core/errors/app_failure.dart';
import 'extracted_fields.dart';
import 'scan_record.dart';
import 'scan_status.dart';

abstract interface class ScanRepository {
  Future<ScanRecord> create({
    required String id,
    required ImportSource source,
    required String attachmentPath,
    required String imageFingerprint,
  });

  Future<ScanRecord?> findById(String id);

  /// Live scans with the same image fingerprint, excluding discarded ones.
  Future<List<ScanRecord>> findByFingerprint(String fingerprint);

  /// Scans the user still needs to see, newest first. Discarded scans are
  /// excluded.
  Stream<List<ScanRecord>> watchVisible();

  /// Moves a scan to [next], enforcing [ScanStatus.canTransitionTo].
  ///
  /// Throws `AppFailure(invalidScanState)` for an illegal move. Moving to
  /// `confirmed` is not allowed here; that happens only through
  /// `TransactionRepository.confirmFromScan`.
  Future<ScanRecord> transition(
    String id,
    ScanStatus next, {
    ExtractedFields? extracted,
    FailureCode? failureCode,
    String? duplicateOfScanId,
    String? processorVersion,
    bool clearAttachment = false,
  });

  /// Returns scans stuck in `processing` (e.g. the app was killed) to
  /// `queued`. Returns the number recovered.
  Future<int> requeueInterrupted();
}
