import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:forui/forui.dart';

import '../../app/theme/icons.dart';
import '../../app/theme/text_styles.dart';
import '../../app/theme/tokens.dart';
import '../../l10n/l10n.dart';
import 'ml_badges.dart';
import 'ml_button.dart';

/// Opens a bottom sheet (`.sheet`) through Forui's modal sheet route, so the
/// scrim, drag-to-dismiss and back handling come from Forui.
Future<T?> showMlSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  double? maxHeightRatio,
}) => showFSheet<T>(
  context: context,
  side: FLayout.btt,
  useRootNavigator: true,
  mainAxisMaxRatio: maxHeightRatio,
  builder: builder,
);

/// White sheet body with the 40×5 handle and 24px top corners.
class MlSheet extends StatelessWidget {
  const MlSheet({
    super.key,
    required this.children,
    this.gap = MlSpace.sm,
    this.scrollable = false,
    this.padding = const EdgeInsets.fromLTRB(20, 10, 20, 34),
  });

  final List<Widget> children;
  final double gap;
  final bool scrollable;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: MlColors.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        for (final child in children) ...[SizedBox(height: gap), child],
      ],
    );
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: MlColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(MlRadius.xxl)),
      ),
      padding: padding.add(EdgeInsets.only(bottom: bottomInset)),
      child: scrollable ? SingleChildScrollView(child: content) : content,
    );
  }
}

/// Sheet title row, optionally with a soft close button (`.sheet-h`).
class MlSheetHeader extends StatelessWidget {
  const MlSheetHeader({super.key, required this.title, this.closable = false});

  final String title;
  final bool closable;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Semantics(
          header: true,
          child: Text(
            title,
            style: MlText.h2.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      if (closable)
        MlIconButton(
          icon: MlIcons.x,
          semanticLabel: context.l10n.actionClose,
          variant: MlIconButtonVariant.soft,
          iconSize: 18,
          onPressed: () => Navigator.of(context).pop(),
        ),
    ],
  );
}

/// One row of a picker sheet (category, account, filter).
class MlPickItem {
  const MlPickItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final bool selected;
  final VoidCallback onSelected;
}

/// Picker sheet (`sh.pick`): title and a list of tinted rows, max 72% high.
Future<void> showMlPickSheet(
  BuildContext context, {
  required String title,
  required List<MlPickItem> items,
}) => showMlSheet<void>(
  context,
  maxHeightRatio: 0.72,
  builder: (context) => MlSheet(
    scrollable: true,
    gap: 0,
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
    children: [
      const SizedBox(height: 14),
      Semantics(
        header: true,
        child: Text(
          title,
          style: MlText.h2.copyWith(fontSize: 19, fontWeight: FontWeight.w700),
        ),
      ),
      const SizedBox(height: 6),
      for (final item in items)
        FTappable(
          semanticsLabel: item.title,
          selected: item.selected,
          onPress: () {
            Navigator.of(context).pop();
            item.onSelected();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: MlColors.soft)),
            ),
            child: Row(
              children: [
                TintIcon(icon: item.icon, tint: item.tint, size: 40),
                const SizedBox(width: MlSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: MlText.title.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        item.subtitle,
                        style: MlText.caption.copyWith(
                          color: MlColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.selected)
                  const Icon(
                    MlIcons.circleCheck,
                    size: 20,
                    color: MlColors.success,
                  ),
              ],
            ),
          ),
        ),
    ],
  ),
);

/// Optional summary chip at the top of a delete dialog.
class MlDialogChip {
  const MlDialogChip({
    required this.title,
    required this.icon,
    required this.tint,
    required this.amount,
    required this.amountColor,
  });

  final String title;
  final IconData icon;
  final Color tint;
  final String amount;
  final Color amountColor;
}

/// Destructive confirmation (`.dialog`). Resolves to true when confirmed.
Future<bool> showMlConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  MlDialogChip? chip,
}) async {
  final result = await showFDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (context, style, animation) => Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Container(
          padding: const EdgeInsets.all(MlSpace.xl),
          decoration: BoxDecoration(
            color: MlColors.surface,
            borderRadius: BorderRadius.circular(MlRadius.xxl),
            boxShadow: MlShadows.dialog,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (chip != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: MlColors.bgApp,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      TintIcon(
                        icon: chip.icon,
                        tint: chip.tint,
                        size: 32,
                        iconSize: 15,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          chip.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: MlText.smallM,
                        ),
                      ),
                      Text(
                        chip.amount,
                        style: MlText.amtS.copyWith(
                          fontWeight: FontWeight.w700,
                          color: chip.amountColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                title,
                style: MlText.h2.copyWith(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: MlSpace.xs),
              Text(
                body,
                style: MlText.small.copyWith(color: MlColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: MlButton(
                      label: context.l10n.actionCancel,
                      variant: MlButtonVariant.secondary,
                      height: 48,
                      horizontalPadding: MlSpace.sm,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: MlSpace.xs),
                  Expanded(
                    child: MlButton(
                      label: confirmLabel,
                      variant: MlButtonVariant.destructiveSolid,
                      height: 48,
                      fontWeight: FontWeight.w700,
                      horizontalPadding: MlSpace.sm,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return result ?? false;
}

/// The single [FToaster] above the navigator; toasts are shown through it so
/// they survive the route pops that often precede them.
final mlToasterKey = GlobalKey<FToasterState>();

/// Ink pill toast at the top with a sage check, shown for 1.9s.
void showMlToast(String message) {
  final toaster = mlToasterKey.currentState;
  if (toaster == null) return;
  toaster.show(
    alignment: FToastAlignment.topCenter,
    duration: MlDurations.toast,
    builder: (context, entry) => Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: MlColors.inverse,
          borderRadius: BorderRadius.circular(20),
          boxShadow: MlShadows.toast,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(MlIcons.circleCheck, size: 16, color: MlColors.sage),
            const SizedBox(width: MlSpace.xs),
            Flexible(
              child: Text(
                message,
                style: MlText.meta.copyWith(
                  fontWeight: FontWeight.w600,
                  color: MlColors.textInverse,
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: MlDurations.fast).slideY(begin: -0.3),
    ),
  );
}

/// Full-screen original-slip viewer (`sh.viewer`). [photo] builds the slip's
/// own picture; without it the sample receipt is shown.
Future<void> showSlipViewer(
  BuildContext context, {
  Widget Function(BuildContext context)? photo,
}) => Navigator.of(context, rootNavigator: true).push(
  PageRouteBuilder<void>(
    opaque: false,
    barrierDismissible: true,
    pageBuilder: (context, _, _) => _SlipViewer(photo: photo),
    transitionsBuilder: (context, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  ),
);

class _SlipViewer extends StatelessWidget {
  const _SlipViewer({this.photo});

  final Widget Function(BuildContext context)? photo;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ColoredBox(
      color: MlColors.cameraBg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.slipOriginal,
                      style: MlText.title.copyWith(color: MlColors.textInverse),
                    ),
                  ),
                  MlIconButton(
                    icon: MlIcons.x,
                    semanticLabel: l10n.actionClose,
                    variant: MlIconButtonVariant.glass,
                    iconSize: 20,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: MlSpace.md),
              Expanded(
                child: InteractiveViewer(
                  maxScale: 4,
                  child:
                      photo?.call(context) ??
                      SlipImage(
                        radius: MlRadius.md,
                        fit: BoxFit.contain,
                        semanticLabel: l10n.slipOriginal,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
