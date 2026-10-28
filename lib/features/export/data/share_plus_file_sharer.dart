import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/file_sharer.dart';

/// Writes the file to the temporary directory and opens the share sheet.
///
/// The exported file holds financial data, so older exports are deleted
/// before a new one is written, and it lives only in the app's cache.
class SharePlusFileSharer implements FileSharer {
  const SharePlusFileSharer();

  static const _folder = 'moneylens_export';

  @override
  Future<ShareOutcome> shareFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final dir = Directory('${(await getTemporaryDirectory()).path}/$_folder');
    if (await dir.exists()) await dir.delete(recursive: true);
    await dir.create(recursive: true);
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType)],
        fileNameOverrides: [fileName],
        subject: fileName,
      ),
    );
    return switch (result.status) {
      ShareResultStatus.success => ShareOutcome.shared,
      ShareResultStatus.dismissed => ShareOutcome.dismissed,
      ShareResultStatus.unavailable => ShareOutcome.unknown,
    };
  }
}
