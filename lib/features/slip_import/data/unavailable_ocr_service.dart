import '../../../core/errors/app_failure.dart';
import '../domain/extracted_fields.dart';
import '../domain/import_ports.dart';

/// Placeholder until an OCR engine is chosen (ROADMAP week 2 spike).
///
/// Fails honestly with `ocrUnavailable`, so scans land in a visible,
/// retryable `failed` state instead of fabricating results.
class UnavailableOcrService implements OcrService {
  const UnavailableOcrService();

  @override
  Future<OcrResult> recognize(String absoluteImagePath) async =>
      throw const AppFailure(FailureCode.ocrUnavailable);
}

/// Placeholder extractor that recognises nothing. Every required field is
/// reported missing, so the review step asks the user to supply it.
class EmptyExtractionService implements ExtractionService {
  const EmptyExtractionService();

  @override
  Future<ExtractedFields> extract(OcrResult ocr) async =>
      const ExtractedFields();
}
