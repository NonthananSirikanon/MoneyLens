import 'dart:typed_data';

/// What happened to a shared file, as far as the platform tells us.
enum ShareOutcome {
  /// The user picked a destination.
  shared,

  /// The user closed the share sheet.
  dismissed,

  /// The file was handed over but the platform does not say what happened
  /// (Android often does this).
  unknown,
}

/// Hands a file to the operating system's share sheet (Save to Files,
/// e-mail, ...).
abstract interface class FileSharer {
  Future<ShareOutcome> shareFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  });
}
