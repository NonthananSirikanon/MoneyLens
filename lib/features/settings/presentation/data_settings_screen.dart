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
import '../../export/application/export_service.dart';
import '../../export/application/transaction_csv.dart';
import '../../export/domain/export_period.dart';
import '../../export/domain/file_sharer.dart';
import '../../transactions/application/transaction_providers.dart';
import '../../../l10n/formatting.dart';
import '../../../l10n/l10n.dart';

/// "ข้อมูลและการส่งออก". CSV export is real (period picker, share sheet).
/// The stored-image figures are still SIMULATED; "delete all data" clears the
/// database and, through sync, the server copy.
class DataSettingsScreen extends ConsumerStatefulWidget {
  const DataSettingsScreen({super.key});

  @override
  ConsumerState<DataSettingsScreen> createState() => _DataSettingsScreenState();
}

class _DataSettingsScreenState extends ConsumerState<DataSettingsScreen> {
  var _exporting = false;

  String _periodLabel(ExportPeriod p) {
    final l10n = context.l10n;
    return switch (p) {
      ExportPeriod.thisMonth => l10n.exportPeriodThisMonth,
      ExportPeriod.last3Months => l10n.exportPeriodLast3,
      ExportPeriod.thisYear => l10n.exportPeriodThisYear,
      ExportPeriod.all => l10n.exportPeriodAll,
    };
  }

  CsvLabels _csvLabels() {
    final l10n = context.l10n;
    return CsvLabels(
      date: l10n.csvColDate,
      time: l10n.csvColTime,
      type: l10n.csvColType,
      amount: l10n.csvColAmount,
      currency: l10n.csvColCurrency,
      account: l10n.csvColAccount,
      toAccount: l10n.csvColToAccount,
      category: l10n.csvColCategory,
      merchant: l10n.csvColMerchant,
      note: l10n.csvColNote,
      source: l10n.csvColSource,
      income: l10n.typeIncome,
      expense: l10n.typeExpense,
      transfer: l10n.typeTransfer,
    );
  }

  Future<void> _pickPeriod() async {
    final l10n = context.l10n;
    final current = ref.read(exportPeriodProvider);
    await showMlPickSheet(
      context,
      title: l10n.dataRange,
      items: [
        for (final p in ExportPeriod.values)
          MlPickItem(
            title: _periodLabel(p),
            subtitle: _periodRange(p),
            icon: MlIcons.calendar,
            tint: MlColors.soft,
            selected: p == current,
            onSelected: () => ref.read(exportPeriodProvider.notifier).choose(p),
          ),
      ],
    );
  }

  /// "1 – 31 ต.ค. 2569" under each choice, or empty for "all".
  String _periodRange(ExportPeriod p) {
    final now = ref.read(clockProvider).nowUtc();
    final range = p.rangeAt(now);
    if (range == null) return '';
    final fmt = context.dateFormat;
    final zone = ReportingTimeZone.bangkok;
    final first = zone.wallClock(range.startUtc);
    final last = zone.wallClock(range.endUtc.subtract(const Duration(days: 1)));
    return '${fmt.dayMonthYear(first)} – ${fmt.dayMonthYear(last)}';
  }

  Future<void> _export() async {
    if (_exporting) return;
    final l10n = context.l10n;
    final labels = _csvLabels();
    setState(() => _exporting = true);
    try {
      final result = await ref
          .read(csvExportServiceProvider)
          .export(ref.read(exportPeriodProvider), labels);
      if (result.count == 0) {
        showMlToast(l10n.exportEmpty);
      } else if (result.outcome == ShareOutcome.shared) {
        showMlToast(l10n.toastExported(result.fileName));
      }
    } on Object {
      showMlToast(l10n.exportFailed);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _wipe() async {
    final l10n = context.l10n;
    final confirmed = await showMlConfirmDialog(
      context,
      title: l10n.wipeTitle,
      body: l10n.wipeBody,
      confirmLabel: l10n.wipeConfirm,
    );
    if (!confirmed) return;
    await ref.read(demoStoreProvider.notifier).wipeAll();
    if (!context.mounted) return;
    showMlToast(l10n.toastWiped);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final prefs = ref.watch(appPreferencesProvider);
    final period = ref.watch(exportPeriodProvider);
    final now = ref.watch(clockProvider).nowUtc();
    final txCount =
        ref
            .watch(allTransactionsProvider)
            .value
            ?.where((t) => period.includes(t.occurredAt, now))
            .length ??
        0;
    final slipImages = ref.watch(
      demoStoreProvider.select(
        (s) => s.transactions.where((t) => t.attachmentPath != null).length,
      ),
    );
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
              value: _periodLabel(period),
              onPressed: _pickPeriod,
            ),
            MlListRow(
              icon: MlIcons.download,
              label: l10n.dataExportCsv,
              sub: l10n.dataExportCount(txCount),
              chevron: false,
              onPressed: _exporting ? null : _export,
            ),
          ],
        ),
        MlGroupTitle(l10n.dataGroupSlips),
        MlListGroup(
          children: [
            MlListRow(
              icon: MlIcons.image,
              label: l10n.dataSlipsOnDevice,
              value: l10n.dataSlipsSize(slipImages, '–'),
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
              onPressed: _wipe,
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
