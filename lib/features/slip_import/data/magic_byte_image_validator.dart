import 'dart:typed_data';

import '../../../core/errors/app_failure.dart';
import '../domain/import_ports.dart';

/// Identifies images by their file signature instead of trusting the file
/// name or extension (ARCHITECTURE.md §5.2).
class MagicByteImageValidator implements ImageValidator {
  const MagicByteImageValidator({this.maxBytes = 20 * 1024 * 1024});

  final int maxBytes;

  static const _heifBrands = {
    'heic',
    'heix',
    'hevc',
    'heim',
    'heis',
    'mif1',
    'msf1',
  };

  @override
  ImageFormat validate(Uint8List bytes) {
    if (bytes.isEmpty) throw const AppFailure(FailureCode.unreadableImage);
    if (bytes.length > maxBytes) {
      throw const AppFailure(FailureCode.fileTooLarge);
    }
    final format = _sniff(bytes);
    if (format == null) throw const AppFailure(FailureCode.unsupportedFile);
    return format;
  }

  static ImageFormat? _sniff(Uint8List b) {
    if (_startsWith(b, const [0xFF, 0xD8, 0xFF])) return ImageFormat.jpeg;
    if (_startsWith(b, const [
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
    ])) {
      return ImageFormat.png;
    }
    if (b.length >= 12 &&
        _ascii(b, 0, 4) == 'RIFF' &&
        _ascii(b, 8, 12) == 'WEBP') {
      return ImageFormat.webp;
    }
    if (b.length >= 12 &&
        _ascii(b, 4, 8) == 'ftyp' &&
        _heifBrands.contains(_ascii(b, 8, 12))) {
      return ImageFormat.heic;
    }
    return null;
  }

  static bool _startsWith(Uint8List b, List<int> signature) {
    if (b.length < signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (b[i] != signature[i]) return false;
    }
    return true;
  }

  static String _ascii(Uint8List b, int start, int end) =>
      String.fromCharCodes(b.sublist(start, end));
}
