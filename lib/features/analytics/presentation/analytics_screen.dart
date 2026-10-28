import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/icons.dart';
import '../../../app/theme/text_styles.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ml_badges.dart';
import '../../../core/widgets/ml_button.dart';
import '../../../core/widgets/ml_controls.dart';
import '../../../core/widgets/ml_state_views.dart';
import '../../../core/widgets/ml_surfaces.dart';
import '../../../l10n/formatting.dart';
import '../../../l10n/l10n.dart';
import '../application/analytics_view_providers.dart';

/// "วิเคราะห์" tab: category breakdown and six-month trend.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ui = ref.watch(analyticsProvider);
    final controller = ref.read(analyticsProvider.notifier);
    return ColoredBox(
      color: MlColors.bgApp,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, MlSpace.navClearance),
          children: [
            MlLargeTitle(l10n.analyticsTitle),
            MlSegmented<AnalyticsTab>(
              segments: [
                MlSegment(AnalyticsTab.breakdown, l10n.analyticsTabBreakdown),
                MlSegment(AnalyticsTab.trend, l10n.analyticsTabTrend),
              ],
              selected: ui.tab,
              onChanged: controller.setTab,
            ),
            const SizedBox(height: 14),
            if (ui.tab == AnalyticsTab.breakdown)
              const _BreakdownView()
            else
              const _TrendView(),
          ],
        ),
      ),
    );
  }
}

class _BreakdownView extends ConsumerWidget {
  const _BreakdownView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ui = ref.watch(analyticsProvider);
    final controller = ref.read(analyticsProvider.notifier);
    final b = ref.watch(breakdownProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Wraps rather than overflowing with long labels or large text.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: MlSpace.xs,
          runSpacing: MlSpace.xs,
          children: [
            MlPeriodButton(
              label: context.dateFormat.monthYear(b.month),
              leadingIcon: MlIcons.calendar,
              onPressed: controller.cyclePeriod,
            ),
            if (!b.isEmpty || ui.periodIndex == 0)
              MlSegmented<AnalyticsMode>(
                style: MlSegmentedStyle.white,
                expand: false,
                segments: [
                  MlSegment(AnalyticsMode.expense, l10n.typeExpense),
                  MlSegment(AnalyticsMode.income, l10n.typeIncome),
                ],
                selected: ui.mode,
                onChanged: controller.setMode,
              ),
          ],
        ),
        if (b.isEmpty)
          MlEmptyState(
            illustration: MlImages.emptyAnalytics,
            title: l10n.analyticsEmptyTitle,
            body: l10n.analyticsEmptyBody,
            topPadding: 44,
            actions: [
              MlButton(
                label: l10n.analyticsChangePeriod,
                variant: MlButtonVariant.outline,
                height: 48,
                expand: false,
                onPressed: controller.resetPeriod,
              ),
            ],
          )
        else ...[
          const SizedBox(height: MlSpace.sm),
          Row(
            children: [
              const Icon(
                MlIcons.arrowLeftRight,
                size: 13,
                color: MlColors.transfer,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.analyticsTransfersExcluded(
                    context.bahtCompact(b.transfers),
                  ),
                  style: MlText.caption.copyWith(color: MlColors.transfer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: SizedBox(
              width: 224,
              height: 224,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      startDegreeOffset: -90,
                      sectionsSpace: 2,
                      centerSpaceRadius: 80,
                      sections: [
                        for (final s in b.slices)
                          PieChartSectionData(
                            value: s.amount.toDouble(),
                            color: s.color,
                            radius: 32,
                            showTitle: false,
                          ),
                      ],
                    ),
                    duration: MlDurations.medium,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.bahtCompact(b.total),
                        style: MlText.amtL.copyWith(
                          fontSize: 26,
                          letterSpacing: -.6,
                        ),
                      ),
                      Text(
                        ui.mode == AnalyticsMode.expense
                            ? l10n.analyticsTotalExpense
                            : l10n.analyticsTotalIncome,
                        style: MlText.caption.copyWith(
                          color: MlColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: MlDurations.medium).scaleXY(begin: .96),
          const SizedBox(height: 18),
          for (final s in b.slices)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: MlColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: s.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(s.name, style: MlText.small)),
                  SizedBox(
                    width: 44,
                    child: Text(
                      '${(s.share * 100).round()}%',
                      textAlign: TextAlign.right,
                      style: MlText.small.copyWith(
                        color: MlColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Text(
                      context.bahtCompact(s.amount),
                      textAlign: TextAlign.right,
                      style: MlText.amtS.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _TrendView extends ConsumerWidget {
  const _TrendView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final trend = ref.watch(trendProvider);
    if (trend.isEmpty) return const SizedBox.shrink();
    final selected =
        ref.watch(analyticsProvider).trendIndex ?? trend.length - 1;
    final controller = ref.read(analyticsProvider.notifier);
    final fmt = context.dateFormat;
    final maxY = trend
        .expand((p) => [p.income, p.expense])
        .fold(0, (a, b) => a > b ? a : b)
        .toDouble();
    final avgIncome = trend.fold(0, (s, p) => s + p.income) ~/ trend.length;
    final avgExpense = trend.fold(0, (s, p) => s + p.expense) ~/ trend.length;
    final sel = trend[selected];
    final overspent = trend.where((p) => p.expense > p.income).firstOrNull;

    Widget stat(String label, int value) => Expanded(
      child: MlCard(
        radius: MlRadius.lg,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: MlText.caption.copyWith(color: MlColors.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              context.bahtCompact(value),
              style: MlText.amtL.copyWith(fontSize: 20),
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            stat(l10n.analyticsAvgIncome, avgIncome),
            const SizedBox(width: 10),
            stat(l10n.analyticsAvgExpense, avgExpense),
          ],
        ),
        const SizedBox(height: MlSpace.sm),
        MlCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.analyticsIncomeVsExpense,
                      style: MlText.title.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    l10n.analyticsSixMonths,
                    style: MlText.caption.copyWith(
                      color: MlColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MlSpace.md),
              Container(
                height: 140,
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: MlColors.border)),
                ),
                child: BarChart(
                  BarChartData(
                    maxY: maxY,
                    alignment: BarChartAlignment.spaceBetween,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    barTouchData: BarTouchData(
                      handleBuiltInTouches: false,
                      touchCallback: (event, response) {
                        final spot = response?.spot;
                        if (event is FlTapUpEvent && spot != null) {
                          controller.selectTrend(spot.touchedBarGroupIndex);
                        }
                      },
                    ),
                    barGroups: [
                      for (final (i, p) in trend.indexed)
                        BarChartGroupData(
                          x: i,
                          barsSpace: 4,
                          barRods: [
                            for (final (value, color) in [
                              (p.income, MlColors.sage),
                              (p.expense, MlColors.inverse),
                            ])
                              BarChartRodData(
                                toY: value.toDouble(),
                                width: 14,
                                color: color.withValues(
                                  alpha: i == selected ? 1 : .45,
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                  duration: MlDurations.medium,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final (i, p) in trend.indexed)
                    Semantics(
                      button: true,
                      selected: i == selected,
                      label: l10n.analyticsMonthBar(
                        fmt.monthShort(p.month),
                        context.bahtCompact(p.income),
                        context.bahtCompact(p.expense),
                      ),
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: () => controller.selectTrend(i),
                        child: SizedBox(
                          width: 36,
                          child: Text(
                            fmt.monthShort(p.month),
                            textAlign: TextAlign.center,
                            style: MlText.micro.copyWith(
                              color: i == selected
                                  ? MlColors.textPrimary
                                  : MlColors.textSecondary,
                              fontWeight: i == selected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: MlSpace.sm),
              Row(
                children: [
                  for (final (label, color) in [
                    (l10n.typeIncome, MlColors.sage),
                    (l10n.typeExpense, MlColors.inverse),
                  ]) ...[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: MlText.caption.copyWith(
                        color: MlColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: MlSpace.sm),
        MlCard(
          radius: MlRadius.lg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.analyticsNet(fmt.monthShort(sel.month)),
                  style: MlText.small.copyWith(color: MlColors.textSecondary),
                ),
              ),
              Text(
                '${sel.net >= 0 ? '+' : '-'}${context.bahtCompact(sel.net.abs())}',
                style: MlText.amtL.copyWith(
                  fontSize: 18,
                  color: sel.net >= 0
                      ? AmountTone.income.color
                      : AmountTone.expense.color,
                ),
              ),
            ],
          ),
        ),
        if (overspent != null) ...[
          const SizedBox(height: MlSpace.sm),
          MlBanner(
            tone: MlBannerTone.warning,
            icon: MlIcons.triangleAlert,
            iconSize: 17,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            body: l10n.analyticsOverspend(
              fmt.monthShort(overspent.month),
              context.bahtCompact(overspent.expense - overspent.income),
            ),
          ),
        ],
      ],
    );
  }
}
