import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/utils/id_generator.dart';
import '../domain/import_ports.dart';

/// Stores imported slips in app-private storage and references them by a
/// relative path, never by a temporary external URI (ARCHITECTURE.md §9).
class LocalSlipImageStore implements SlipImageStore {
  LocalSlipImageStore(this._ids, {Future<Directory> Function()? baseDirectory})
    : _baseDirectory = baseDirectory ?? getApplicationSupportDirectory;

  static const _folder = 'slips';

  final IdGenerator _ids;
  final Future<Directory> Function() _baseDirectory;

  @override
  Future<StoredImage> save(Uint8List bytes, ImageFormat format) async {
    final relativePath = '$_folder/${_ids.newId()}.${_extension(format)}';
    final file = File(await resolve(relativePath));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return StoredImage(
      relativePath: relativePath,
      fingerprint: 'sha256:${sha256.convert(bytes)}',
    );
  }

  @override
  Future<String> resolve(String relativePath) async {
    if (relativePath.contains('..') || relativePath.startsWith('/')) {
      throw ArgumentError('Slip paths must be relative to the slip store');
    }
    final base = await _baseDirectory();
    return '${base.path}/$relativePath';
  }

  @override
  Future<void> delete(String relativePath) async {
    final file = File(await resolve(relativePath));
    if (await file.exists()) await file.delete();
  }

  static String _extension(ImageFormat format) => switch (format) {
    ImageFormat.jpeg => 'jpg',
    ImageFormat.png => 'png',
    ImageFormat.heic => 'heic',
    ImageFormat.webp => 'webp',
  };
}
