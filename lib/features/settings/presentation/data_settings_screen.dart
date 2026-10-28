import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_preferences.dart';
import '../../../app/theme/icons.dart';
import '../../../app/theme/text_styles.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/dates/clock.dart';
import '../../../core/dates/reporting_time_zone.dart';
import '../../../core/widgets/ml_controls.dart';
import '../../../core/widgets/ml_overlays.dart';
import '../../../core/widgets/ml_surfaces.dart';
import '../../../demo/demo_store.dart';
import '../../../l10n/formatting.dart';
import '../../../l10n/l10n.dart';

/// "ข้อมูลและการส่งออก". CSV export and the stored-image figures are
/// SIMULATED (toast only); "delete all data" clears the demo store.
class DataSettingsScreen extends ConsumerWidget {
  const DataSettingsScreen({super.key});

  Future<void> _wipe(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showMlConfirmDialog(
      context,
      title: l10n.wipeTitle,
      body: l10n.wipeBody,
      confirmLabel: l10n.wipeConfirm,
    );
    if (!confirmed) return;
    ref.read(demoStoreProvider.notifier).wipeAll();
    showMlToast(l10n.toastWiped);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final prefs = ref.watch(appPreferencesProvider);
    final txCount = ref.watch(
      demoStoreProvider.select((s) => s.transactions.length),
    );
    final now = ReportingTimeZone.bangkok.wallClock(
      ref.watch(clockProvider).nowUtc(),
    );
    final first = DateTime.utc(now.year, now.month);
    final last = DateTime.utc(now.year, now.month + 1, 0);
    final fmt = context.dateFormat;
    final range = '${first.day} – ${fmt.dayMonthYear(last)}';
    final year = context.localeTag.startsWith('th') ? now.year + 543 : now.year;
    final file = 'moneylens-$year-${now.month.toString().padLeft(2, '0')}.csv';

    return _SubSettingsPage(
      title: l10n.dataTitle,
      children: [
        MlGroupTitle(l10n.dataGroupCsv, top: 12),
        MlBanner(
          tone: MlBannerTone.warning,
          icon: MlIcons.triangleAlert,
          iconSize: 15,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          body: l10n.dataCsvWarning,
        ),
        const SizedBox(height: MlSpace.xs),
        MlListGroup(
          children: [
            MlListRow(
              icon: MlIcons.calendar,
              label: l10n.dataRange,
              value: range,
              onPressed: () => showMlToast(l10n.toastPickRange),
            ),
            MlListRow(
              icon: MlIcons.download,
              label: l10n.dataExportCsv,
              sub: l10n.dataExportCount(txCount),
              chevron: false,
              onPressed: () => showMlToast(l10n.toastExported(file)),
            ),
          ],
        ),
        MlGroupTitle(l10n.dataGroupSlips),
        MlListGroup(
          children: [
            MlListRow(
              icon: MlIcons.image,
              label: l10n.dataSlipsOnDevice,
              value: l10n.dataSlipsSize(128, '46 MB'),
              chevron: false,
              onPressed: null,
            ),
            MlListRow(
              icon: MlIcons.clock,
              label: l10n.dataAutoDelete,
              sub: l10n.dataAutoDeleteSub,
              toggle: prefs.autoDeleteSlips,
              onPressed: ref
                  .read(appPreferencesProvider.notifier)
                  .toggleAutoDelete,
            ),
          ],
        ),
        const SizedBox(height: MlSpace.lg),
        MlListGroup(
          children: [
            MlListRow(
              icon: MlIcons.trash2,
              label: l10n.dataWipe,
              sub: l10n.dataWipeSub,
              danger: true,
              chevron: false,
              onPressed: () => _wipe(context, ref),
            ),
          ],
        ),
      ],
    );
  }
}

/// Shared layout for Settings sub-pages: back header + content.
class _SubSettingsPage extends StatelessWidget {
  const _SubSettingsPage({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: MlColors.bgApp,
    child: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Transform.translate(
            offset: const Offset(-8, 0),
            child: MlAppBar(title: title, onLeading: () => context.pop()),
          ),
          DefaultTextStyle(
            style: MlText.small,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    ),
  );
}
