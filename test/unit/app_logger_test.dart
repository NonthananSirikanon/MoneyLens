import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/core/errors/app_failure.dart';
import 'package:moneylens/core/logging/app_logger.dart';

void main() {
  test('redacts free-text metadata so slip content cannot leak (PR-04)', () {
    final logged = <String, Object>{};
    final logger = AppLogger(sink: (_, metadata) => logged.addAll(metadata));

    logger.event('scan_failed', {
      'code': FailureCode.ocrUnavailable,
      'count': 2,
      'ok': false,
      'ocrText': 'โอนเงิน 1,234.00 บาท บัญชี 123-4-56789-0',
    });

    expect(logged, {
      'code': 'ocrUnavailable',
      'count': 2,
      'ok': false,
      'ocrText': '<redacted>',
    });
  });
}
