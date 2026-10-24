import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/scan_status.dart';
import 'slip_import_providers.dart';

/// UI-facing import actions. State is the outcome of the latest action:
/// loading while busy, or an error carrying an [AppFailure].
class SlipImportController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> importFrom(ImportSource source) => _run(() async {
    final adapter = ref.read(imageSourcesProvider)[source];
    if (adapter == null) throw const AppFailure(FailureCode.notImplemented);
    final request = await adapter.acquire();
    if (request == null) return; // Cancelled by the user.
    await ref.read(slipImportPipelineProvider).ingest(request);
  });

  Future<void> retry(String scanId) =>
      _run(() => ref.read(slipImportPipelineProvider).retry(scanId));

  Future<void> discard(String scanId) =>
      _run(() => ref.read(slipImportPipelineProvider).discard(scanId));

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);
    if (ref.mounted) state = result;
  }
}

final slipImportControllerProvider =
    AsyncNotifierProvider<SlipImportController, void>(SlipImportController.new);
