import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_preferences.dart';
import '../../../app/router.dart';
import '../../../app/theme/icons.dart';
import '../../../app/theme/text_styles.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/dates/clock.dart';
import '../../../core/dates/reporting_time_zone.dart';
import '../../../core/widgets/ml_badges.dart';
import '../../../core/widgets/ml_button.dart';
import '../../../core/widgets/ml_controls.dart';
import '../../../core/widgets/ml_surfaces.dart';
import '../../../demo/demo_scenario.dart';
import '../../../demo/demo_store.dart';
import '../../../l10n/formatting.dart';
import '../../../l10n/l10n.dart';
import '../../analytics/application/analytics_view_providers.dart';
import '../../slip_import/application/import_view_providers.dart';
import '../../slip_import/presentation/import_flows.dart';
import '../../transactions/presentation/transaction_tile.dart';
import '../../transactions/application/transaction_view_providers.dart';
import '../../auth/application/session.dart';
import '../../auth/domain/auth_models.dart';
import '../application/home_view_providers.dart';

/// First name for the greeting: the first word of the Google name or the
/// username, or a neutral fallback.
String _firstName(AppUser? user, String fallback) {
  final name = user?.displayName;
  if (name == null || name.trim().isEmpty) return fallback;
  return name.trim().split(RegExp(r'\s+')).first;
}

/// Home dashboard (prototype `is.home`).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _openAnalytics(BuildContext context, WidgetRef ref, AnalyticsTab tab) {
    ref.read(analyticsProvider.notifier).open(tab);
    context.go(AppRoutes.analytics);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final now = ReportingTimeZone.bangkok.wallClock(
      ref.watch(clockProvider).nowUtc(),
    );
    final offline = ref.watch(demoScenarioProvider) == DemoScenario.offline;
    final pending = ref.watch(pendingScansProvider).length;
    final recent = ref.watch(recentTransactionViewsProvider);

    final greeting = switch (now.hour) {
      < 12 => l10n.greetingMorning,
      < 17 => l10n.greetingAfternoon,
      _ => l10n.greetingEvening,
    };

    return ColoredBox(
      color: MlColors.bgApp,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, MlSpace.navClearance),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: MlText.title.copyWith(
                          fontWeight: FontWeight.w400,
                          color: MlColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _firstName(
                                ref.watch(sessionProvider).user,
                                l10n.profileFallbackName,
                              ),
                              overflow: TextOverflow.ellipsis,
                              style: MlText.h1.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: MlSpace.xs),
                          const Icon(
                            MlIcons.sun,
                            size: 22,
                            color: MlColors.warning,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                MlPeriodButton(
                  label: context.dateFormat.monthYear(now),
                  onPressed: () =>
                      _openAnalytics(context, ref, AnalyticsTab.breakdown),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (offline) ...[
              MlBanner(
                tone: MlBannerTone.info,
                icon: MlIcons.wifiOff,
                title: l10n.offlineTitle,
                body: l10n.offlineBody,
              ),
              const SizedBox(height: 20),
            ],
            if (pending > 0) ...[
              MlBanner(
                tone: MlBannerTone.warning,
                icon: MlIcons.receipt,
                title: l10n.pendingSlipsTitle(pending),
                body: l10n.pendingSlipsBody,
                trailing: const Icon(MlIcons.chevronRight, size: 18),
                onPressed: () => context.push(AppRoutes.queue),
              ),
              const SizedBox(height: 20),
            ],
            const _BalanceCard(),
            const SizedBox(height: 20),
            Row(
              children: [
                for (final (i, (icon, label, action)) in [
                  (
                    MlIcons.scanLine,
                    l10n.quickScan,
                    () => ImportFlows.startCamera(context, ref),
                  ),
                  (
                    MlIcons.pencil,
                    l10n.quickManual,
                    () => ImportFlows.startManual(context),
                  ),
                  (
                    MlIcons.chartPie,
                    l10n.quickReport,
                    () => _openAnalytics(context, ref, AnalyticsTab.trend),
                  ),
                ].indexed) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: icon,
                      label: label,
                      onPressed: action,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            MlSectionHeader(
              title: l10n.recentTitle,
              trailing: MlTextLink(
                label: l10n.seeAll,
                onPressed: () => context.go(AppRoutes.transactions),
              ),
            ),
            const SizedBox(height: 4),
            if (recent.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: MlSpace.md),
                child: Text(
                  l10n.transactionsEmptyBody,
                  style: MlText.small.copyWith(color: MlColors.textSecondary),
                ),
              ),
            for (final v in recent)
              TransactionTile(
                view: v,
                onPressed: () => context.push(AppRoutes.transaction(v.id)),
              ),
            const SizedBox(height: 20),
            _DailyCard(month: now),
            const SizedBox(height: 20),
            MlSectionHeader(
              title: l10n.topCategoriesTitle,
              trailing: MlTextLink(
                label: l10n.seeAllShort,
                onPressed: () =>
                    _openAnalytics(context, ref, AnalyticsTab.breakdown),
              ),
            ),
            const SizedBox(height: 10),
            const _TopCategories(),
          ].animate(interval: 30.ms).fadeIn(duration: MlDurations.medium),
        ),
      ),
    );
  }
}

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final hide = ref.watch(
      appPreferencesProvider.select((p) => p.hideBalances),
    );
    final balance = ref.watch(demoStoreProvider.select((s) => s.totalBalance));
    final totals = ref.watch(monthTotalsProvider);
    final muted = MlText.caption.copyWith(color: MlColors.balanceMuted);

    Widget figure(IconData icon, String label, int minor) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: MlColors.balanceMuted),
            const SizedBox(width: 4),
            Text(label, style: muted),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          hide ? l10n.hiddenAmount : context.bahtCompact(minor),
          style: MlText.amtM.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );

    return Container(
      constraints: const BoxConstraints(minHeight: 176),
      decoration: BoxDecoration(
        color: MlColors.balance,
        borderRadius: BorderRadius.circular(MlRadius.xxl),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned(
            right: 6,
            bottom: -4,
            child: Illustration(
              MlImages.balanceCard,
              height: 150,
              background: MlColors.balance,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(l10n.totalBalance, style: MlText.meta),
                    const SizedBox(width: 6),
                    FTappable(
                      semanticsLabel: l10n.toggleBalanceVisibility,
                      onPress: () => ref
                          .read(appPreferencesProvider.notifier)
                          .toggleHideBalances(),
                      child: SizedBox(
                        width: 32,
                        height: 24,
                        child: Icon(
                          hide ? MlIcons.eyeOff : MlIcons.eye,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    hide ? l10n.hiddenBalance : context.baht(balance),
                    style: MlText.amtHero,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 26,
                  runSpacing: 8,
                  children: [
                    figure(MlIcons.arrowUp, l10n.typeIncome, totals.income),
                    figure(MlIcons.arrowDown, l10n.typeExpense, totals.expense),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.transfersExcludedShort,
                  style: muted.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => MlCard(
    radius: 18,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    onPressed: onPressed,
    semanticLabel: label,
    child: SizedBox(
      height: 82,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22),
          const SizedBox(height: MlSpace.xs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MlText.label.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

/// "ใช้จ่ายรายวัน": one bar per day this month; tapping selects a day.
class _DailyCard extends ConsumerWidget {
  const _DailyCard({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final days = ref.watch(dailySpendProvider);
    final selected = ref
        .watch(selectedDayProvider)
        .clamp(0, math.max(0, days.length - 1))
        .toInt();
    final maxValue = days.fold<int>(0, math.max).toDouble();
    final date = DateTime.utc(month.year, month.month, selected + 1);

    return MlCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.dailySpendTitle,
                  style: MlText.title.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                context.dateFormat.monthYear(month),
                style: MlText.caption.copyWith(color: MlColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                l10n.dailySpendDay(context.dateFormat.dayMonth(date)),
                style: MlText.caption.copyWith(color: MlColors.textSecondary),
              ),
              const SizedBox(width: MlSpace.xs),
              Text(
                days.isEmpty ? '' : context.bahtCompact(days[selected]),
                style: MlText.amtS.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            child: days.isEmpty || maxValue == 0
                ? const SizedBox.shrink()
                : LayoutBuilder(
                    builder: (context, c) {
                      final barWidth = math.max(
                        2.0,
                        (c.maxWidth - 4 * (days.length - 1)) / days.length,
                      );
                      return BarChart(
                        BarChartData(
                          maxY: maxValue,
                          alignment: BarChartAlignment.spaceBetween,
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          barTouchData: BarTouchData(
                            handleBuiltInTouches: false,
                            touchCallback: (event, response) {
                              final spot = response?.spot;
                              if (event is FlTapUpEvent && spot != null) {
                                ref
                                    .read(selectedDayProvider.notifier)
                                    .select(spot.touchedBarGroupIndex);
                              }
                            },
                          ),
                          barGroups: [
                            for (var i = 0; i < days.length; i++)
                              BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: math.max(
                                      days[i].toDouble(),
                                      maxValue * .04,
                                    ),
                                    width: barWidth,
                                    color: i == selected
                                        ? MlColors.inverse
                                        : MlColors.chartSoft,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        duration: MlDurations.medium,
                      );
                    },
                  ),
          ),
          const SizedBox(height: MlSpace.xs),
          DefaultTextStyle(
            style: MlText.micro.copyWith(color: MlColors.textSecondary),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.dateFormat.dayMonth(
                    DateTime.utc(month.year, month.month),
                  ),
                ),
                const Text('8'),
                const Text('15'),
                const Text('22'),
                Text(
                  l10n.today,
                  style: MlText.micro.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopCategories extends ConsumerWidget {
  const _TopCategories();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final top = ref.watch(topCategoriesProvider);
    if (top.isEmpty) {
      return Text(
        l10n.analyticsEmptyBody,
        style: MlText.small.copyWith(color: MlColors.textSecondary),
      );
    }
    return Column(
      children: [
        for (final (i, c) in top.indexed) ...[
          if (i > 0) const SizedBox(height: 14),
          Row(
            children: [
              TintIcon(
                icon: MlIconKeys.of(c.category.iconKey),
                tint: c.style?.tint ?? MlColors.soft,
                size: 38,
                iconSize: 17,
                radius: MlRadius.md,
              ),
              const SizedBox(width: MlSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.category.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MlText.small.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(context.bahtCompact(c.amount), style: MlText.amtS),
                      ],
                    ),
                    const SizedBox(height: 6),
                    MlProgressBar(
                      value: c.shareOfTop,
                      color: c.style?.chart ?? MlColors.sage,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.topCategoryMeta(
                        (c.shareOfTotal * 100).round(),
                        c.count,
                      ),
                      style: MlText.caption.copyWith(
                        color: MlColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
