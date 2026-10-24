import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_states.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/failure_messages.dart';
import '../application/slip_import_controller.dart';
import '../application/slip_import_providers.dart';
import '../domain/scan_status.dart';
import 'scan_tile.dart';

class ImportScreen extends ConsumerWidget {
  const ImportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scans = ref.watch(visibleScansProvider);
    final action = ref.watch(slipImportControllerProvider);
    final controller = ref.read(slipImportControllerProvider.notifier);

    ref.listen(slipImportControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.errorMessage(error))));
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.importTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: action.isLoading
                        ? null
                        : () => controller.importFrom(ImportSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(l10n.importFromCamera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: action.isLoading
                        ? null
                        : () => controller.importFrom(ImportSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(l10n.importFromGallery),
                  ),
                ),
              ],
            ),
          ),
          if (action.isLoading) const LinearProgressIndicator(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.importReviewNotice),
            subtitle: Text(l10n.importShareSheetHint),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              l10n.scansTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...switch (scans) {
            AsyncData(:final value) when value.isEmpty => [
              EmptyView(
                icon: Icons.document_scanner_outlined,
                message: l10n.scansEmpty,
              ),
            ],
            AsyncData(:final value) => [
              for (final scan in value)
                ScanTile(
                  scan: scan,
                  onRetry: () => controller.retry(scan.id),
                  onDiscard: () => controller.discard(scan.id),
                ),
            ],
            AsyncError() => [
              ErrorView(
                message: l10n.loadError,
                retryLabel: l10n.retry,
                onRetry: () => ref.invalidate(visibleScansProvider),
              ),
            ],
            _ => [
              const Padding(padding: EdgeInsets.all(24), child: LoadingView()),
            ],
          },
        ],
      ),
    );
  }
}
