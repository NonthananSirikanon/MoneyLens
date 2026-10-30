import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/ml_badges.dart';
import '../../../app/theme/tokens.dart';
import '../application/slip_import_providers.dart';

/// Absolute path of a stored slip image, or null for the bundled sample
/// receipt (an `assets/` path) and for no image at all.
final slipFileProvider = FutureProvider.family<String?, String?>((
  ref,
  relativePath,
) async {
  if (relativePath == null || relativePath.startsWith('assets/')) return null;
  return ref.read(slipImageStoreProvider).resolve(relativePath);
});

/// A slip's picture: its stored photo when it has one, the sample receipt
/// otherwise (sample data and while the file is being located).
class ScanPhoto extends ConsumerWidget {
  const ScanPhoto({
    super.key,
    required this.attachmentPath,
    this.width,
    this.height,
    this.radius = MlRadius.sm,
    this.degraded = false,
    this.border = false,
    this.fit = BoxFit.cover,
    this.semanticLabel,
  });

  final String? attachmentPath;
  final double? width;
  final double? height;
  final double radius;
  final bool degraded;
  final bool border;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = ref.watch(slipFileProvider(attachmentPath)).value;
    return SlipImage(
      width: width,
      height: height,
      radius: radius,
      degraded: degraded,
      border: border,
      fit: fit,
      semanticLabel: semanticLabel,
      image: path == null ? null : FileImage(File(path)),
    );
  }
}
