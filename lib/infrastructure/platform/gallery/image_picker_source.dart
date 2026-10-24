import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_failure.dart';
import '../../../features/slip_import/domain/import_ports.dart';
import '../../../features/slip_import/domain/scan_status.dart';

/// Camera and Gallery/Photos import via `image_picker`.
///
/// One package covers both user-initiated sources, which avoids duplicate
/// camera abstractions (ARCHITECTURE.md §2). Images are not resized here:
/// OCR quality decisions belong to the pipeline.
class ImagePickerSource implements ImageSourceAdapter {
  ImagePickerSource.camera({ImagePicker? picker})
    : source = ImportSource.camera,
      _pickerSource = ImageSource.camera,
      _picker = picker ?? ImagePicker();

  ImagePickerSource.gallery({ImagePicker? picker})
    : source = ImportSource.gallery,
      _pickerSource = ImageSource.gallery,
      _picker = picker ?? ImagePicker();

  @override
  final ImportSource source;
  final ImageSource _pickerSource;
  final ImagePicker _picker;

  @override
  Future<ImportRequest?> acquire() async {
    final XFile? file;
    try {
      file = await _picker.pickImage(
        source: _pickerSource,
        requestFullMetadata: false,
      );
    } on PlatformException catch (e) {
      throw AppFailure(
        _isPermissionError(e.code)
            ? FailureCode.permissionDenied
            : FailureCode.unexpected,
      );
    }
    if (file == null) return null; // User cancelled.
    return ImportRequest(source: source, bytes: await file.readAsBytes());
  }

  static bool _isPermissionError(String code) =>
      code == 'camera_access_denied' || code == 'photo_access_denied';
}
