import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_preferences.dart';
import '../../../app/router.dart';
import '../../../core/widgets/ml_overlays.dart';
import '../../../demo/demo_store.dart';
import '../../../l10n/l10n.dart';
import '../../transactions/application/entry_form.dart';
import '../domain/scan_record.dart';
import '../domain/scan_status.dart';
import 'denied_screen.dart';

/// Navigation for the import flows, shared by Home, the add sheet, the
/// queue and the empty states (prototype `startCamera`, `startGallery`,
/// `openScan`).
abstract final class ImportFlows {
  /// Opens the camera, or the "no access" screen when permission is off.
  static void startCamera(BuildContext context, WidgetRef ref) {
    if (!ref.read(appPreferencesProvider).permissionsGranted) {
      context.push(AppRoutes.denied(DeniedKind.camera));
      return;
    }
    context.push(AppRoutes.camera);
  }

  /// Simulates picking two images, then shows the queue. With [replace]
  /// the current screen is swapped out (from the camera or denied screen).
  static void startGallery(
    BuildContext context,
    WidgetRef ref, {
    bool replace = false,
  }) {
    if (!ref.read(appPreferencesProvider).permissionsGranted) {
      final route = AppRoutes.denied(DeniedKind.photos);
      replace ? context.pushReplacement(route) : context.push(route);
      return;
    }
    ref.read(demoStoreProvider.notifier).importFromGallery();
    showMlToast(context.l10n.toastImportedPhotos(2));
    replace
        ? context.pushReplacement(AppRoutes.queue)
        : context.push(AppRoutes.queue);
  }

  static void startManual(BuildContext context, {bool replace = false}) {
    const args = ManualEntryArgs();
    replace
        ? context.pushReplacement(AppRoutes.entry, extra: args)
        : context.push(AppRoutes.entry, extra: args);
  }

  /// Opens the screen for a scan that needs a decision.
  static void openScan(
    BuildContext context,
    ScanRecord scan, {
    bool replace = false,
  }) {
    void open(String route, {Object? extra}) => replace
        ? context.pushReplacement(route, extra: extra)
        : context.push(route, extra: extra);
    switch (scan.status) {
      case ScanStatus.needsReview:
        open(AppRoutes.entry, extra: ScanEntryArgs(scan.id));
      case ScanStatus.duplicate:
        open(AppRoutes.duplicate(scan.id));
      case ScanStatus.failed:
        open(AppRoutes.ocrFailed(scan.id));
      case _:
        break;
    }
  }
}
