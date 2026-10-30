import 'dart:io' show Platform;

import 'package:flutter/services.dart';

import '../../core/errors/app_failure.dart';
import '../../features/slip_import/domain/import_ports.dart';

/// On-device text recognition through the native side: Apple Vision on iOS
/// and Tesseract (Thai + English) on Android (`MainActivity.kt`,
/// `AppDelegate.swift`). The image never leaves the device.
class PlatformOcrService implements OcrService {
  const PlatformOcrService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('moneylens/ocr');

  final MethodChannel _channel;

  @override
  Future<OcrResult> recognize(String absoluteImagePath) async {
    final String? text;
    try {
      text = await _channel.invokeMethod<String>('recognize', {
        'path': absoluteImagePath,
      });
    } on MissingPluginException {
      // A platform without an engine (desktop, tests).
      throw const AppFailure(FailureCode.ocrUnavailable);
    } on PlatformException catch (e) {
      throw AppFailure(switch (e.code) {
        'unreadable_image' => FailureCode.unreadableImage,
        'ocr_unavailable' => FailureCode.ocrUnavailable,
        _ => FailureCode.unexpected,
      });
    }
    // Nothing recognised: a blank, blurred or non-text picture.
    if (text == null || text.trim().isEmpty) {
      throw const AppFailure(FailureCode.unreadableImage);
    }
    return OcrResult(text: text, engineId: _engineId);
  }

  static String get _engineId {
    try {
      return Platform.isIOS ? 'apple-vision' : 'tesseract-tha';
    } on Object {
      return 'unknown';
    }
  }
}
