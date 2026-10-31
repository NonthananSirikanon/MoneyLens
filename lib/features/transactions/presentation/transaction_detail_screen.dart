import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/icons.dart';
import '../../../app/theme/text_styles.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ml_badges.dart';
import '../../../core/widgets/ml_button.dart';
import '../../../core/widgets/ml_controls.dart';
import '../../../core/widgets/ml_overlays.dart';
import '../../../core/widgets/ml_surfaces.dart';
import '../../../app/app_store.dart';
import '../../../l10n/formatting.dart';
import '../../../l10n/l10n.dart';
import '../../slip_import/domain/scan_status.dart';
import '../application/entry_form.dart';
import '../application/transaction_view_providers.dart';
import '../domain/transaction_type.dart';
import 'transaction_tile.dart';
import '../../slip_import/presentation/scan_photo.dart';

/// "รายละเอียดรายการ" (prototype `is.detail`).
class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.id});

  final String id;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    TransactionView v,
  ) async {
    final l10n = context.l10n;
    final (icon, tint) = transactionAvatar(v);
    final confirmed = await showMlConfirmDialog(
      context,
      title: l10n.deleteTitle,
      body: l10n.deleteBody,
      confirmLabel: l10n.deleteConfirm,
      chip: MlDialogChip(
        title: v.title,
        icon: icon,
        tint: tint,
        amount: context.signedAmount(v.type, v.transaction.amount),
        amountColor: v.type.tone.color,
      ),
    );
    if (!confirmed || !context.mounted) return;
    await ref.read(appStoreProvider.notifier).deleteTransaction(v.id);
    if (!context.mounted) return;
    context.pop();
    showMlToast(l10n.toastDeleted);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final v = ref.watch(transactionViewProvider(id));
    if (v == null) return const ColoredBox(color: MlColors.bgApp);

    final (icon, tint) = transactionAvatar(v);
    final (badgeBg, badgeIcon) = switch (v.type) {
      TransactionType.transfer => (
        MlColors.transferSoft,
        MlIcons.arrowLeftRight,
      ),
      TransactionType.income => (MlColors.successSoft, MlIcons.arrowUp),
      TransactionType.expense => (MlColors.errorSoft, MlIcons.arrowDown),
    };
    String accountLabel(String? name, String? mask) =>
        [name ?? '', mask ?? ''].where((s) => s.isNotEmpty).join(' ');
    final from = accountLabel(
      v.accountDetails?.shortName ?? v.account?.name,
      v.accountDetails?.mask,
    );
    final importSource = ref.watch(
      appStoreProvider.select((s) => s.transactionImportSources[v.id]),
    );
    final source = v.transaction.scanRecordId == null && importSource == null
        ? l10n.sourceManual
        : l10n.sourceSlip(_sourceLabel(context, importSource));

    final rows = [
      (
        l10n.detailDate,
        '${context.dateFormat.dayMonthYear(v.wallClock)} · ${context.dateFormat.time(v.wallClock)}',
      ),
      if (v.isTransfer) ...[
        (l10n.detailFrom, from),
        (
          l10n.detailTo,
          accountLabel(
            v.destinationDetails?.shortName ?? v.destination?.name,
            v.destinationDetails?.mask,
          ),
        ),
      ] else ...[
        (l10n.detailCategory, v.category?.name ?? '-'),
        (l10n.detailAccount, from),
      ],
      if ((v.transaction.note ?? '').isNotEmpty)
        (l10n.detailNote, v.transaction.note!),
      (l10n.detailSource, source),
    ];

    return ColoredBox(
      color: MlColors.bgApp,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 0, 20, 32),
          children: [
            MlAppBar(onLeading: () => context.pop()),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 4),
                  Center(
                    child: TintIcon(
                      icon: icon,
                      tint: tint,
                      size: 64,
                      iconSize: 28,
                    ),
                  ),
                  const SizedBox(height: MlSpace.xs),
                  Text(
                    v.title,
                    textAlign: TextAlign.center,
                    style: MlText.h3.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: MlSpace.xs),
                  Center(
                    child: MlPill(
                      label: context.typeLabel(v.type),
                      icon: badgeIcon,
                      background: badgeBg,
                      foreground: v.type.tone.color,
                    ),
                  ),
                  const SizedBox(height: MlSpace.xs),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      context.signedAmount(v.type, v.transaction.amount),
                      style: MlText.amtXl.copyWith(color: v.type.tone.color),
                    ),
                  ),
                  const SizedBox(height: 22),
                  MlListGroup(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    children: [
                      for (final (k, value) in rows)
                        MlKeyValueRow(keyText: k, value: value),
                    ],
                  ),
                  if (v.hasSlip) ...[
                    const SizedBox(height: MlSpace.sm),
                    MlCard(
                      padding: const EdgeInsets.all(MlSpace.sm),
                      semanticLabel: l10n.slipOriginal,
                      onPressed: () => showSlipViewer(
                        context,
                        photo: (_) => ScanPhoto(
                          attachmentPath: v.transaction.attachmentPath,
                          radius: MlRadius.md,
                          fit: BoxFit.contain,
                        ),
                      ),
                      child: Row(
                        children: [
                          ScanPhoto(
                            attachmentPath: v.transaction.attachmentPath,
                            width: 52,
                            height: 68,
                            radius: 10,
                          ),
                          const SizedBox(width: MlSpace.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.slipOriginal,
                                  style: MlText.small.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.slipTapToView,
                                  style: MlText.caption.copyWith(
                                    color: MlColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            MlIcons.maximize2,
                            size: 17,
                            color: MlColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: MlSpace.xl),
                  Row(
                    children: [
                      // Delete : edit = 1 : 1.4, as in the prototype.
                      Expanded(
                        flex: 10,
                        child: MlButton(
                          label: l10n.actionDelete,
                          icon: MlIcons.trash2,
                          variant: MlButtonVariant.destructive,
                          height: 52,
                          horizontalPadding: MlSpace.sm,
                          onPressed: () => _delete(context, ref, v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 14,
                        child: MlButton(
                          label: l10n.actionEdit,
                          icon: MlIcons.pencil,
                          height: 52,
                          fontWeight: FontWeight.w600,
                          onPressed: () => context.push(
                            AppRoutes.entry,
                            extra: EditEntryArgs(v.id),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _sourceLabel(BuildContext context, ImportSource? source) {
    final l10n = context.l10n;
    return switch (source) {
      ImportSource.camera => l10n.scanSourceCamera,
      ImportSource.shareSheet => l10n.scanSourceShareSheet,
      ImportSource.discovery => l10n.scanSourceDiscovery,
      ImportSource.gallery || null => l10n.scanSourceGallery,
    };
  }
}
