import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/ml_overlays.dart';
import '../../../l10n/failure_messages.dart';
import '../../../l10n/l10n.dart';
import '../application/slip_queue.dart';
import '../domain/scan_status.dart';
import 'denied_screen.dart';

/// How "scan a slip" and "import from gallery" start. The device launcher
/// below is the real one; sample mode swaps in a simulated one from
/// `lib/demo`.
abstract interface class ImportLauncher {
  void startCamera(BuildContext context, WidgetRef ref, {bool replace = false});

  /// With [replace] the current screen is swapped out (from the camera or
  /// denied screen), for both methods.
  void startGallery(
    BuildContext context,
    WidgetRef ref, {
    bool replace = false,
  });
}

/// The system camera or photo picker, then the slip is stored and read on
/// the device.
class DeviceImportLauncher implements ImportLauncher {
  const DeviceImportLauncher();

  @override
  void startCamera(
    BuildContext context,
    WidgetRef ref, {
    bool replace = false,
  }) => unawaited(_import(context, ref, ImportSource.camera, replace: replace));

  @override
  void startGallery(
    BuildContext context,
    WidgetRef ref, {
    bool replace = false,
  }) =>
      unawaited(_import(context, ref, ImportSource.gallery, replace: replace));

  /// Picks a photo, queues it and opens the screen that follows its reading.
  /// A cancelled picker does nothing; a refused permission opens the "no
  /// access" screen; any other problem is explained in a message.
  Future<void> _import(
    BuildContext context,
    WidgetRef ref,
    ImportSource source, {
    bool replace = false,
  }) async {
    final l10n = context.l10n;
    try {
      final scan = await ref
          .read(slipQueueProvider.notifier)
          .importFrom(source);
      if (scan == null || !context.mounted) return;
      final route = AppRoutes.processing(scan.id);
      replace ? context.pushReplacement(route) : context.push(route);
    } on AppFailure catch (e) {
      if (!context.mounted) return;
      if (e.code == FailureCode.permissionDenied) {
        final route = AppRoutes.denied(
          source == ImportSource.camera ? DeniedKind.camera : DeniedKind.photos,
        );
        replace ? context.pushReplacement(route) : context.push(route);
      } else {
        showMlToast(l10n.failureMessage(e.code));
      }
    }
  }
}

final importLauncherProvider = Provider<ImportLauncher>(
  (ref) => const DeviceImportLauncher(),
);
