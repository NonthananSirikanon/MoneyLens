import '../domain/import_ports.dart';
import '../domain/scan_record.dart';
import '../domain/scan_repository.dart';

/// Flags re-imports of the exact same image file.
///
/// This is only the image-fingerprint layer of DATABASE.md §6. Provider
/// reference and normalized transaction fingerprints come in ROADMAP
/// week 8. Amount + date alone must never be treated as a duplicate key.
class FingerprintDuplicateDetector implements DuplicateDetector {
  const FingerprintDuplicateDetector(this._scans);

  final ScanRepository _scans;

  @override
  Future<DuplicateCheck> check(ScanRecord scan) async {
    final fingerprint = scan.imageFingerprint;
    if (fingerprint == null) return DuplicateCheck.none;
    final matches = await _scans.findByFingerprint(fingerprint);
    for (final other in matches) {
      if (other.id != scan.id) {
        return DuplicateCheck(duplicateOfScanId: other.id);
      }
    }
    return DuplicateCheck.none;
  }
}
