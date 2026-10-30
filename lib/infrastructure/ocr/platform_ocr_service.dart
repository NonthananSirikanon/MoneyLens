import 'dart:io' show Platform;

import 'package:flutter/services.dart';

import '../../core/errors/app_failure.dart';
import '../../features/slip_import/domain/import_ports.dart';

/// On-device text recognition through the native side: Apple Vision on iOS
/// and Tesseract (Thai) on Android (`MainActivity.kt`, `AppDelegate.swift`).
/// The image never leaves the device.
///
/// Tesseract misreads differ with how the picture is prepared, so on Android
/// the slip is read up to [passes] times, each pass preparing the image
/// differently (`SlipOcr.kt`). The extractor then compares the readings. It
/// stops early once [enough] says the readings so far agree.
class PlatformOcrService implements OcrService {
  const PlatformOcrService({
    MethodChannel? channel,
    this.passes = 1,
    this.enough,
  }) : _channel = channel ?? const MethodChannel('moneylens/ocr');

  final MethodChannel _channel;
  final int passes;
  final bool Function(List<String> readings)? enough;

  @override
  Future<OcrResult> recognize(String absoluteImagePath) async {
    final readings = <String>[];
    for (var pass = 0; pass < passes; pass++) {
      final String? text;
      try {
        text = await _read(absoluteImagePath, pass);
      } on AppFailure {
        // A later pass failing still leaves the earlier readings.
        if (readings.isNotEmpty) break;
        rethrow;
      }
      if (text != null && text.trim().isNotEmpty) readings.add(text);
      if (readings.length >= 2 && (enough?.call(readings) ?? false)) break;
    }
    // Nothing recognised: a blank, blurred or non-text picture.
    if (readings.isEmpty) {
      throw const AppFailure(FailureCode.unreadableImage);
    }
    return OcrResult(
      text: readings.first,
      alternatives: readings.sublist(1),
      engineId: _engineId,
    );
  }

  Future<String?> _read(String path, int pass) async {
    try {
      return await _channel.invokeMethod<String>('recognize', {
        'path': path,
        'pass': pass,
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
  }

  static String get _engineId {
    try {
      return Platform.isIOS ? 'apple-vision' : 'tesseract-tha';
    } on Object {
      return 'unknown';
    }
  }
}
