/// Typed, user-safe failure categories (ARCHITECTURE.md §10).
///
/// [dbValue] is stored in `scan_records.failure_code` and may appear in
/// diagnostics, so codes must never carry financial or OCR content.
enum FailureCode {
  unsupportedFile('unsupported_file'),
  fileTooLarge('file_too_large'),
  permissionDenied('permission_denied'),
  unreadableImage('unreadable_image'),
  ocrUnavailable('ocr_unavailable'),
  extractionFailed('extraction_failed'),
  missingRequiredField('missing_required_field'),
  likelyDuplicate('likely_duplicate'),
  invalidTransaction('invalid_transaction'),
  invalidScanState('invalid_scan_state'),
  notFound('not_found'),
  localDatabase('local_database'),
  remoteProviderUnavailable('remote_provider_unavailable'),
  notImplemented('not_implemented'),
  unexpected('unexpected');

  const FailureCode(this.dbValue);

  final String dbValue;

  static FailureCode fromDb(String value) =>
      values.firstWhere((c) => c.dbValue == value, orElse: () => unexpected);
}

/// An expected, recoverable failure. Carries only a [code]; never attach
/// raw provider output or user data.
class AppFailure implements Exception {
  const AppFailure(this.code);

  final FailureCode code;

  @override
  String toString() => 'AppFailure(${code.dbValue})';
}
