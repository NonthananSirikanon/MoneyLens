import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';

import '../app/providers.dart';
import '../app/router.dart';
import '../core/dates/clock.dart';
import '../features/slip_import/application/slip_queue.dart';
import '../features/slip_import/presentation/import_launcher.dart';
import '../infrastructure/database/app_database.dart';
import 'camera_screen.dart';
import 'demo_import_launcher.dart';
import 'demo_seed.dart';
import 'demo_slip_queue.dart';
import 'sample_ledger.dart';

/// The prototype's sample data, built relative to the clock's current day.
final demoSeedProvider = Provider<DemoSeed>(
  (ref) => DemoSeed(ref.watch(clockProvider).nowUtc()),
);

/// Everything sample mode (`ML_SAMPLE_DATA`) swaps in, and the only place it
/// is wired: the sample accounts and transactions in the database, and a
/// simulated slip queue, camera and gallery in place of the real ones.
///
/// Pass these as `ProviderScope(overrides: ...)` for a sample run or a test
/// of it. A normal run passes nothing and starts empty.
List<Override> demoOverrides() => [
  sampleLedgerSeederProvider.overrideWith(
    (ref) =>
        () => insertSampleLedger(
          ref.read(appDatabaseProvider),
          ref.read(demoSeedProvider),
        ),
  ),
  extraRoutesProvider.overrideWithValue([
    GoRoute(
      path: AppRoutes.camera,
      parentNavigatorKey: rootNavigatorKey,
      builder: (_, _) => const CameraScreen(),
    ),
    GoRoute(
      path: AppRoutes.cameraPreview,
      parentNavigatorKey: rootNavigatorKey,
      builder: (_, _) => const CameraPreviewScreen(),
    ),
  ]),
  slipQueueProvider.overrideWith(DemoSlipQueue.new),
  importLauncherProvider.overrideWithValue(const DemoImportLauncher()),
];
