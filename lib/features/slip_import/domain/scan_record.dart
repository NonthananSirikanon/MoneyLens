import '../../../core/errors/app_failure.dart';
import 'extracted_fields.dart';
import 'scan_status.dart';

/// One imported image and its processing/review lifecycle. A scan is not a
/// confirmed transaction (DATABASE.md §3.4).
class ScanRecord {
  const ScanRecord({
    required this.id,
    required this.source,
    this.attachmentPath,
    this.imageFingerprint,
    this.extracted,
    required this.status,
    this.failureCode,
    this.duplicateOfScanId,
    this.transactionId,
    this.processorVersion,
    required this.createdAt,
    required this.updatedAt,
    this.processedAt,
  });

  final String id;
  final ImportSource source;

  /// App-owned relative path while the image is retained.
  final String? attachmentPath;
  final String? imageFingerprint;
  final ExtractedFields? extracted;
  final ScanStatus status;
  final FailureCode? failureCode;
  final String? duplicateOfScanId;
  final String? transactionId;
  final String? processorVersion;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? processedAt;
}
