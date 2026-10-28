import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../features/slip_import/presentation/add_sheet.dart';
import '../../l10n/l10n.dart';
import '../theme/icons.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';

/// Hosts the four tab roots with the prototype's bottom nav: two tabs, a
/// raised add button, two tabs.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: MlColors.bgApp,
    child: Stack(
      children: [
        Positioned.fill(child: navigationShell),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: MlBottomNav(
            currentIndex: navigationShell.currentIndex,
            onTab: (i) => navigationShell.goBranch(i, initialLocation: true),
            onAdd: () => showAddSheet(context),
          ),
        ),
      ],
    ),
  );
}

/// `.bottom-nav`: translucent white bar with a 60px ink FAB ringed in the
/// app background colour.
class MlBottomNav extends StatelessWidget {
  const MlBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTab,
    required this.onAdd,
  });

  final int currentIndex;
  final ValueChanged<int> onTab;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final tabs = [
      (MlIcons.house, l10n.navHome),
      (MlIcons.receipt, l10n.navTransactions),
      (MlIcons.chartPie, l10n.navAnalytics),
      (MlIcons.settings, l10n.navSettings),
    ];
    Widget tab(int i) {
      final on = i == currentIndex;
      final color = on ? MlColors.textPrimary : MlColors.textTertiary;
      return Expanded(
        child: FTappable(
          semanticsLabel: tabs[i].$2,
          selected: on,
          onPress: () => onTab(i),
          child: SizedBox(
            height: 52,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(tabs[i].$1, size: 22, color: color),
                const SizedBox(height: 3),
                Text(
                  tabs[i].$2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MlText.caption.copyWith(
                    color: color,
                    fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 88 + (bottom > 34 ? bottom - 34 : 0),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      decoration: const BoxDecoration(
        color: MlColors.navBg,
        border: Border(top: BorderSide(color: MlColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          tab(0),
          tab(1),
          Expanded(
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -28),
                child: FTappable(
                  semanticsLabel: l10n.navAdd,
                  onPress: onAdd,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: MlColors.inverse,
                      shape: BoxShape.circle,
                      border: Border.all(color: MlColors.bgApp, width: 4),
                      boxShadow: MlShadows.fab,
                    ),
                    child: const Icon(
                      MlIcons.plus,
                      size: 26,
                      color: MlColors.textInverse,
                    ),
                  ),
                ),
              ),
            ),
          ),
          tab(2),
          tab(3),
        ],
      ),
    );
  }
}
