import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/core/errors/app_failure.dart';
import 'package:moneylens/infrastructure/ocr/platform_ocr_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('moneylens/ocr');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// Answers pass n with `replies[n]`; a [PlatformException] is thrown.
  List<int> fake(List<Object?> replies) {
    final calls = <int>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      final pass = (call.arguments as Map)['pass'] as int;
      calls.add(pass);
      final reply = replies[pass];
      if (reply is PlatformException) throw reply;
      return reply;
    });
    return calls;
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('one pass by default (Apple Vision)', () async {
    final calls = fake(['text one']);
    final r = await const PlatformOcrService().recognize('/slip.jpg');
    expect(r.text, 'text one');
    expect(r.alternatives, isEmpty);
    expect(calls, [0]);
  });

  test('stops after two readings that agree', () async {
    final calls = fake(['a', 'b', 'c']);
    final r = await PlatformOcrService(
      passes: 3,
      enough: (readings) => true,
    ).recognize('/slip.jpg');
    expect(calls, [0, 1]);
    expect(r.text, 'a');
    expect(r.alternatives, ['b']);
  });

  test('takes every pass while the readings disagree', () async {
    final calls = fake(['a', 'b', 'c']);
    final r = await PlatformOcrService(
      passes: 3,
      enough: (readings) => false,
    ).recognize('/slip.jpg');
    expect(calls, [0, 1, 2]);
    expect(r.alternatives, ['b', 'c']);
  });

  test('empty readings are skipped', () async {
    fake(['  ', 'b', 'c']);
    final r = await const PlatformOcrService(passes: 3).recognize('/s.jpg');
    expect(r.text, 'b');
    expect(r.alternatives, ['c']);
  });

  test('a later pass failing keeps the earlier readings', () async {
    fake(['a', PlatformException(code: 'ocr_failed'), 'c']);
    final r = await const PlatformOcrService(passes: 3).recognize('/s.jpg');
    expect(r.text, 'a');
    expect(r.alternatives, isEmpty);
  });

  test('nothing read at all is an unreadable image', () async {
    fake(['', null, ' ']);
    expect(
      () => const PlatformOcrService(passes: 3).recognize('/s.jpg'),
      throwsA(
        isA<AppFailure>().having(
          (f) => f.code,
          'code',
          FailureCode.unreadableImage,
        ),
      ),
    );
  });

  test('a first pass that fails reports why', () async {
    fake([PlatformException(code: 'unreadable_image')]);
    expect(
      () => const PlatformOcrService(passes: 3).recognize('/s.jpg'),
      throwsA(
        isA<AppFailure>().having(
          (f) => f.code,
          'code',
          FailureCode.unreadableImage,
        ),
      ),
    );
  });
}
