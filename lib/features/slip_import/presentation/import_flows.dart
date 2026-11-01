import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../transactions/application/entry_form.dart';
import '../domain/scan_record.dart';
import '../domain/scan_status.dart';
import 'import_launcher.dart';

/// Navigation for the import flows, shared by Home, the add sheet, the
/// queue and the empty states (prototype `startCamera`, `startGallery`,
/// `openScan`).
abstract final class ImportFlows {
  /// Opens the camera (the system camera, or the simulated one in sample
  /// mode); see [ImportLauncher].
  static void startCamera(
    BuildContext context,
    WidgetRef ref, {
    bool replace = false,
  }) => ref
      .read(importLauncherProvider)
      .startCamera(context, ref, replace: replace);

  /// Picks a photo from the gallery. With [replace] the current screen is
  /// swapped out (from the camera or denied screen).
  static void startGallery(
    BuildContext context,
    WidgetRef ref, {
    bool replace = false,
  }) => ref
      .read(importLauncherProvider)
      .startGallery(context, ref, replace: replace);

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
