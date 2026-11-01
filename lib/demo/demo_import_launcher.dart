import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_preferences.dart';
import '../app/router.dart';
import '../core/widgets/ml_overlays.dart';
import '../features/slip_import/application/slip_queue.dart';
import '../features/slip_import/domain/scan_status.dart';
import '../features/slip_import/presentation/denied_screen.dart';
import '../features/slip_import/presentation/import_launcher.dart';
import '../l10n/l10n.dart';

/// The simulated camera and gallery of sample mode: the in-app viewfinder
/// (`camera_screen.dart`) and a gallery pick that adds two slips to the
/// simulated queue.
class DemoImportLauncher implements ImportLauncher {
  const DemoImportLauncher();

  @override
  void startCamera(
    BuildContext context,
    WidgetRef ref, {
    bool replace = false,
  }) {
    final route = ref.read(appPreferencesProvider).permissionsGranted
        ? AppRoutes.camera
        : AppRoutes.denied(DeniedKind.camera);
    replace ? context.pushReplacement(route) : context.push(route);
  }

  @override
  void startGallery(
    BuildContext context,
    WidgetRef ref, {
    bool replace = false,
  }) {
    if (!ref.read(appPreferencesProvider).permissionsGranted) {
      final route = AppRoutes.denied(DeniedKind.photos);
      replace ? context.pushReplacement(route) : context.push(route);
      return;
    }
    unawaited(
      ref.read(slipQueueProvider.notifier).importFrom(ImportSource.gallery),
    );
    showMlToast(context.l10n.toastImportedPhotos(2));
    replace
        ? context.pushReplacement(AppRoutes.queue)
        : context.push(AppRoutes.queue);
  }
}
