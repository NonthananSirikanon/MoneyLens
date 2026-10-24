import 'dart:typed_data';

import 'extracted_fields.dart';
import 'scan_record.dart';
import 'scan_status.dart';

/// A request to import one image, identical in shape for every source.
class ImportRequest {
  const ImportRequest({required this.source, required this.bytes});

  final ImportSource source;
  final Uint8List bytes;
}

/// Acquires one image from a user-initiated source (camera, gallery).
abstract interface class ImageSourceAdapter {
  ImportSource get source;

  /// Returns `null` when the user cancels. Throws `AppFailure` with
  /// `permissionDenied` when access is refused.
  Future<ImportRequest?> acquire();
}

/// Delivers images pushed into the app by the OS (Share Sheet).
abstract interface class IncomingImageSource {
  Stream<ImportRequest> get incoming;
}

enum ImageFormat { jpeg, png, heic, webp }

/// Validates content, not file extensions (ARCHITECTURE.md §5.2).
abstract interface class ImageValidator {
  /// Throws `AppFailure` when the bytes are empty, too large or not a
  /// supported image.
  ImageFormat validate(Uint8List bytes);
}

class StoredImage {
  const StoredImage({required this.relativePath, required this.fingerprint});

  /// Relative to the app-owned slip directory; never an external URI.
  final String relativePath;

  /// Exact content hash. Detects re-imports of the same file only; it is
  /// not a semantic duplicate key (DATABASE.md §3.4).
  final String fingerprint;
}

abstract interface class SlipImageStore {
  Future<StoredImage> save(Uint8List bytes, ImageFormat format);

  /// Absolute path for consumers that need a file, such as OCR engines.
  Future<String> resolve(String relativePath);

  Future<void> delete(String relativePath);
}

class OcrResult {
  const OcrResult({required this.text, required this.engineId});

  /// Sensitive. Never log it; persist only under a documented retention
  /// policy.
  final String text;
  final String engineId;
}

/// Replaceable OCR provider (ARCHITECTURE.md §5.3).
abstract interface class OcrService {
  Future<OcrResult> recognize(String absoluteImagePath);
}

/// Turns OCR text into candidate fields. Output is data, never commands.
abstract interface class ExtractionService {
  Future<ExtractedFields> extract(OcrResult ocr);
}

class DuplicateCheck {
  const DuplicateCheck({this.duplicateOfScanId});

  static const none = DuplicateCheck();

  final String? duplicateOfScanId;

  bool get isDuplicate => duplicateOfScanId != null;
}

abstract interface class DuplicateDetector {
  Future<DuplicateCheck> check(ScanRecord scan);
}
