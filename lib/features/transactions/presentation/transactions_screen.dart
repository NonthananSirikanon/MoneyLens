import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/icons.dart';
import '../../../app/theme/text_styles.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/dates/clock.dart';
import '../../../core/dates/reporting_time_zone.dart';
import '../../../core/widgets/ml_badges.dart';
import '../../../core/widgets/ml_button.dart';
import '../../../core/widgets/ml_controls.dart';
import '../../../core/widgets/ml_fields.dart';
import '../../../core/widgets/ml_overlays.dart';
import '../../../core/widgets/ml_state_views.dart';
import '../../../core/widgets/ml_surfaces.dart';
import '../../../demo/demo_store.dart';
import '../../../l10n/formatting.dart';
import '../../../l10n/l10n.dart';
import '../../categories/domain/category.dart';
import '../../slip_import/presentation/import_flows.dart';
import '../application/transaction_view_providers.dart';
import '../domain/transaction_type.dart';
import 'transaction_tile.dart';

/// "รายการ" tab: search, type chips, category filter and day-grouped list.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  late final _search = TextEditingController(
    text: ref.read(transactionFilterProvider).query,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openCategoryFilter() {
    final l10n = context.l10n;
    final state = ref.read(appStoreProvider);
    final filter = ref.read(transactionFilterProvider);
    final controller = ref.read(transactionFilterProvider.notifier);
    return showMlPickSheet(
      context,
      title: l10n.filterByCategory,
      items: [
        MlPickItem(
          title: l10n.allCategories,
          subtitle: l10n.clearFilter,
          icon: MlIcons.layers,
          tint: MlColors.soft,
          selected: filter.categoryId == null,
          onSelected: () => controller.setCategory(null),
        ),
        for (final c in state.categories)
          MlPickItem(
            title: c.name,
            subtitle: c.kind == CategoryKind.income
                ? l10n.typeIncome
                : l10n.typeExpense,
            icon: MlIconKeys.of(c.iconKey),
            tint: state.categoryStyles[c.id]?.tint ?? MlColors.soft,
            selected: filter.categoryId == c.id,
            onSelected: () => controller.setCategory(c),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filter = ref.watch(transactionFilterProvider);
    final controller = ref.read(transactionFilterProvider.notifier);
    final load = ref.watch(transactionLoadProvider);
    final groups = ref.watch(transactionGroupsProvider);
    final hasAny = ref.watch(hasTransactionsProvider);
    final category = ref.watch(
      appStoreProvider.select((s) => s.category(filter.categoryId)),
    );

    // Keep the field in sync when the filter is changed elsewhere
    // (e.g. opening a category from the Categories screen clears the query).
    if (_search.text != filter.query) _search.text = filter.query;

    final types = [
      (null, l10n.typeAll),
      (TransactionType.expense, l10n.typeExpense),
      (TransactionType.income, l10n.typeIncome),
      (TransactionType.transfer, l10n.typeTransfer),
    ];

    final List<Widget> body = switch (load) {
      TransactionLoadStatus.loading => [
        const SizedBox(height: 20),
        const MlSkeletonList(),
      ],
      TransactionLoadStatus.error => [
        MlErrorState(
          title: l10n.loadErrorTitle,
          body: l10n.loadErrorBody,
          code: l10n.errorCode('DB_READ_FAILED'),
          retryLabel: l10n.actionRetry,
          onRetry: ref.read(transactionLoadProvider.notifier).retry,
        ),
      ],
      TransactionLoadStatus.ready when !hasAny => [
        MlEmptyState(
          illustration: MlImages.emptyTransactions,
          title: l10n.transactionsEmptyTitle,
          body: l10n.transactionsEmptyBody,
          actions: [
            MlButton(
              label: l10n.quickManual,
              variant: MlButtonVariant.outline,
              height: 48,
              expand: false,
              onPressed: () => ImportFlows.startManual(context),
            ),
            MlButton(
              label: l10n.quickScan,
              icon: MlIcons.scanLine,
              height: 48,
              expand: false,
              onPressed: () => ImportFlows.startCamera(context, ref),
            ),
          ],
        ),
      ],
      TransactionLoadStatus.ready when groups.isEmpty => [
        MlEmptyState(
          icon: MlIcons.searchX,
          title: l10n.noMatchesTitle,
          body: l10n.noMatchesBody,
          topPadding: 56,
        ),
      ],
      TransactionLoadStatus.ready => [
        for (final g in groups) ...[
          Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _dayLabel(context, g.day),
                    style: MlText.meta.copyWith(color: MlColors.textSecondary),
                  ),
                ),
                if (g.expenseMinor > 0)
                  Text(
                    '-${context.bahtCompact(g.expenseMinor)}',
                    style: MlText.meta.copyWith(color: MlColors.textSecondary),
                  ),
              ],
            ),
          ),
          for (final v in g.rows)
            TransactionTile(
              view: v,
              onPressed: () => context.push(AppRoutes.transaction(v.id)),
            ),
        ],
      ].animate(interval: 20.ms).fadeIn(duration: MlDurations.medium),
    };

    return ColoredBox(
      color: MlColors.bgApp,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, MlSpace.navClearance),
          children: [
            MlLargeTitle(l10n.transactionsTitle),
            MlSearchField(
              controller: _search,
              placeholder: l10n.searchPlaceholder,
              onChanged: controller.setQuery,
            ),
            const SizedBox(height: MlSpace.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  for (final (type, label) in types) ...[
                    MlChip(
                      label: label,
                      selected: filter.type == type,
                      onPressed: () => controller.setType(type),
                    ),
                    const SizedBox(width: MlSpace.xs),
                  ],
                  MlChip(
                    label: category?.name ?? l10n.categoryChip,
                    selected: false,
                    highlight: category != null,
                    trailingIcon: MlIcons.chevronDown,
                    onPressed: _openCategoryFilter,
                  ),
                ],
              ),
            ),
            if (filter.type == TransactionType.transfer &&
                load == TransactionLoadStatus.ready) ...[
              const SizedBox(height: MlSpace.sm),
              MlBanner(
                tone: MlBannerTone.info,
                icon: MlIcons.info,
                iconSize: 18,
                title: l10n.transferInfoTitle,
                body: l10n.transferInfoBody,
              ),
            ],
            ...body,
          ],
        ),
      ),
    );
  }

  String _dayLabel(BuildContext context, DateTime day) {
    final l10n = context.l10n;
    final fmt = context.dateFormat;
    final now = ReportingTimeZone.bangkok.wallClock(
      ref.read(clockProvider).nowUtc(),
    );
    final today = DateTime.utc(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return l10n.dayToday(fmt.dayMonthYear(day));
    if (diff == 1) return l10n.dayYesterday(fmt.dayMonth(day));
    return fmt.dayMonthYear(day);
  }
}
