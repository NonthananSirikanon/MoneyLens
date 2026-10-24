import '../core/errors/app_failure.dart';
import 'app_localizations.dart';

/// User-facing text for a failure code. Messages are generic by design and
/// never echo provider output or user data.
extension FailureMessages on AppLocalizations {
  String failureMessage(FailureCode code) => switch (code) {
    FailureCode.unsupportedFile => failureUnsupportedFile,
    FailureCode.fileTooLarge => failureFileTooLarge,
    FailureCode.permissionDenied => failurePermissionDenied,
    FailureCode.unreadableImage => failureUnreadableImage,
    FailureCode.ocrUnavailable => failureOcrUnavailable,
    FailureCode.extractionFailed => failureExtractionFailed,
    _ => failureGeneric,
  };

  String errorMessage(Object error) =>
      error is AppFailure ? failureMessage(error.code) : failureGeneric;
}
