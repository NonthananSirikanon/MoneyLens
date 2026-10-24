import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Privacy-safe diagnostic logger.
///
/// There is deliberately no free-text message parameter. Callers log an
/// event code plus metadata, and any `String` metadata value is redacted,
/// so amounts, OCR text, account numbers and references cannot leak by
/// accident (PROJECT.md PR-04).
class AppLogger {
  const AppLogger({LogSink? sink}) : _sink = sink ?? _developerSink;

  final LogSink _sink;

  void event(String code, [Map<String, Object> metadata = const {}]) {
    _sink(code, {for (final e in metadata.entries) e.key: _safe(e.value)});
  }

  static Object _safe(Object value) => switch (value) {
    num() || bool() => value,
    Enum(:final name) => name,
    Duration(:final inMilliseconds) => '${inMilliseconds}ms',
    _ => '<redacted>',
  };

  static void _developerSink(String code, Map<String, Object> metadata) {
    developer.log(
      metadata.isEmpty ? code : '$code $metadata',
      name: 'moneylens',
    );
  }
}

typedef LogSink = void Function(String code, Map<String, Object> metadata);

final appLoggerProvider = Provider<AppLogger>((ref) => const AppLogger());
