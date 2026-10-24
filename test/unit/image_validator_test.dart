import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/core/errors/app_failure.dart';
import 'package:moneylens/features/slip_import/data/magic_byte_image_validator.dart';
import 'package:moneylens/features/slip_import/domain/import_ports.dart';

Matcher throwsFailure(FailureCode code) =>
    throwsA(isA<AppFailure>().having((f) => f.code, 'code', code));

void main() {
  const validator = MagicByteImageValidator(maxBytes: 64);

  Uint8List bytes(List<int> head) =>
      Uint8List.fromList([...head, ...List.filled(8, 0)]);

  test('detects formats by signature', () {
    expect(validator.validate(bytes([0xFF, 0xD8, 0xFF])), ImageFormat.jpeg);
    expect(
      validator.validate(
        bytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
      ),
      ImageFormat.png,
    );
    expect(
      validator.validate(bytes([0, 0, 0, 0x18, ...'ftypheic'.codeUnits])),
      ImageFormat.heic,
    );
    expect(
      validator.validate(
        bytes([...'RIFF'.codeUnits, 0, 0, 0, 0, ...'WEBP'.codeUnits]),
      ),
      ImageFormat.webp,
    );
  });

  test('rejects empty files', () {
    expect(
      () => validator.validate(Uint8List(0)),
      throwsFailure(FailureCode.unreadableImage),
    );
  });

  test('rejects oversized files', () {
    expect(
      () => validator.validate(
        Uint8List.fromList([0xFF, 0xD8, 0xFF, ...List.filled(100, 0)]),
      ),
      throwsFailure(FailureCode.fileTooLarge),
    );
  });

  test('does not trust content that is not an image', () {
    expect(
      () => validator.validate(
        Uint8List.fromList('%PDF-1.7 not an image'.codeUnits),
      ),
      throwsFailure(FailureCode.unsupportedFile),
    );
  });
}
