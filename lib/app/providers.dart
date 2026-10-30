import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_failure.dart';
import '../features/auth/application/session.dart';
import 'app_preferences.dart';
import '../core/logging/app_logger.dart';
import '../demo/demo_config.dart';
import '../demo/demo_store.dart';
import '../demo/sample_ledger.dart';
import '../features/accounts/application/account_providers.dart';
import '../features/categories/application/category_providers.dart';
import '../features/slip_import/application/slip_import_providers.dart';
import '../features/transactions/application/transaction_providers.dart';
import '../infrastructure/database/app_database.dart';

/// One-time startup work that must finish before the UI shows data:
/// recover interrupted scans, load the ledger from the database (so the UI
/// never flashes empty) and start listening for shared images.
final appStartupProvider = FutureProvider<void>((ref) async {
  final pipeline = ref.watch(slipImportPipelineProvider);
  final logger = ref.watch(appLoggerProvider);

  await pipeline.recoverInterrupted();

  // Restore the sign-in session before any screen is shown. A returning,
  // fully signed-up user does not see onboarding again.
  final session = ref.read(sessionProvider.notifier);
  await session.initialized;
  if (ref.read(sessionProvider).status == SessionStatus.ready) {
    final prefs = ref.read(appPreferencesProvider);
    ref
        .read(appPreferencesProvider.notifier)
        .finishOnboarding(permissionsGranted: prefs.permissionsGranted);
  }

  if (ref.read(sampleDataEnabledProvider)) {
    await insertSampleLedger(
      ref.read(appDatabaseProvider),
      ref.read(demoSeedProvider),
    );
  }
  await Future.wait([
    ref.watch(activeAccountsProvider.future),
    ref.watch(activeCategoriesProvider.future),
    ref.watch(allTransactionsProvider.future),
  ]);
  // Build the store now that its sources have data, and load the slip queue
  // (resuming any slip the app was closed in the middle of reading).
  ref.read(demoStoreProvider);
  await ref.read(demoStoreProvider.notifier).loadScans();

  // Shared images take the same pipeline as camera and gallery imports.
  final subscription = ref.watch(shareSheetSourceProvider).incoming.listen((
    request,
  ) {
    unawaited(
      pipeline
          .ingest(request)
          .then<void>(
            (_) => ref.read(demoStoreProvider.notifier).loadScans(),
            onError: (Object e) {
              logger.event('share_import_rejected', {
                'code': e is AppFailure ? e.code : FailureCode.unexpected,
              });
            },
          ),
    );
  });
  ref.onDispose(subscription.cancel);
});
