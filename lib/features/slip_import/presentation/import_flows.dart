import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_preferences.dart';
import '../../../app/router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/ml_overlays.dart';
import '../../../demo/demo_config.dart';
import '../../../demo/demo_store.dart';
import '../../../l10n/l10n.dart';
import '../../transactions/application/entry_form.dart';
import '../domain/scan_record.dart';
import '../domain/scan_status.dart';
import '../../../l10n/failure_messages.dart';
import 'denied_screen.dart';

/// Navigation for the import flows, shared by Home, the add sheet, the
/// queue and the empty states (prototype `startCamera`, `startGallery`,
/// `openScan`).
abstract final class ImportFlows {
  /// Real mode (everything but sample data): the system camera or photo
  /// picker, then the slip is stored and read on the device. Sample mode
  /// keeps the simulated flow below.
  static bool _real(WidgetRef ref) => !ref.read(sampleDataEnabledProvider);

  /// Picks a photo, queues it and opens the screen that follows its reading.
  /// A cancelled picker does nothing; a refused permission opens the "no
  /// access" screen; any other problem is explained in a message.
  static Future<void> _importReal(
    BuildContext context,
    WidgetRef ref,
    ImportSource source, {
    bool replace = false,
  }) async {
    final l10n = context.l10n;
    try {
      final scan = await ref
          .read(demoStoreProvider.notifier)
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

  /// Opens the camera, or the "no access" screen when permission is off.
  static void startCamera(BuildContext context, WidgetRef ref) {
    if (_real(ref)) {
      unawaited(_importReal(context, ref, ImportSource.camera));
      return;
    }
    if (!ref.read(appPreferencesProvider).permissionsGranted) {
      context.push(AppRoutes.denied(DeniedKind.camera));
      return;
    }
    context.push(AppRoutes.camera);
  }

  /// Picks a photo from the gallery. With [replace] the current screen is
  /// swapped out (from the camera or denied screen). In sample mode this
  /// simulates picking two images, then shows the queue.
  static void startGallery(
    BuildContext context,
    WidgetRef ref, {
    bool replace = false,
  }) {
    if (_real(ref)) {
      unawaited(
        _importReal(context, ref, ImportSource.gallery, replace: replace),
      );
      return;
    }
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
