import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_failure.dart';
import '../core/logging/app_logger.dart';
import '../features/slip_import/application/slip_import_providers.dart';

/// One-time startup work that must finish before the UI shows data:
/// recover interrupted scans and start listening for shared images.
final appStartupProvider = FutureProvider<void>((ref) async {
  final pipeline = ref.watch(slipImportPipelineProvider);
  final logger = ref.watch(appLoggerProvider);

  await pipeline.recoverInterrupted();

  // Shared images take the same pipeline as camera and gallery imports.
  final subscription = ref.watch(shareSheetSourceProvider).incoming.listen((
    request,
  ) {
    unawaited(
      pipeline
          .ingest(request)
          .then<void>(
            (_) {},
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
