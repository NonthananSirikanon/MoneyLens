import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../app/theme/icons.dart';
import '../../app/theme/text_styles.dart';
import '../../app/theme/tokens.dart';
import 'ml_controls.dart';

/// `.card`: white surface, 1px border, 20px radius.
class MlCard extends StatelessWidget {
  const MlCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(MlSpace.md),
    this.radius = MlRadius.xl,
    this.onPressed,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: MlColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: MlColors.border),
      ),
      child: child,
    );
    if (onPressed == null) return card;
    return FTappable(
      semanticsLabel: semanticLabel,
      onPress: onPressed,
      child: card,
    );
  }
}

/// A white card holding rows separated by hairlines (settings, categories,
/// accounts, key/value lists).
class MlListGroup extends StatelessWidget {
  const MlListGroup({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
    this.dividerColor = MlColors.soft,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) => MlCard(
    padding: padding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++)
          DecoratedBox(
            decoration: BoxDecoration(
              border: i == children.length - 1
                  ? null
                  : Border(bottom: BorderSide(color: dividerColor)),
            ),
            child: children[i],
          ),
      ],
    ),
  );
}

/// Settings-style row: 36px tinted lead icon, label (+ P1 tag, + sub),
/// optional value, toggle or chevron.
class MlListRow extends StatelessWidget {
  const MlListRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.sub,
    this.value,
    this.toggle,
    this.chevron = true,
    this.danger = false,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final String? sub;
  final String? value;

  /// When non-null a toggle is shown in this state and the row is announced
  /// as a switch.
  final bool? toggle;
  final bool chevron;
  final bool danger;

  /// Inline tag after the label (e.g. the P1 tag).
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final fg = danger ? MlColors.amountExpense : MlColors.textPrimary;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: MlSpace.xs),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: danger ? MlColors.errorSoft : MlColors.soft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 17, color: fg),
            ),
            const SizedBox(width: MlSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
                      text: label,
                      children: [
                        if (badge != null) ...[
                          const WidgetSpan(child: SizedBox(width: 6)),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: badge!,
                          ),
                        ],
                      ],
                    ),
                    style: MlText.title.copyWith(
                      fontWeight: FontWeight.w500,
                      color: fg,
                    ),
                  ),
                  if (sub != null)
                    Text(
                      sub!,
                      style: MlText.caption.copyWith(
                        color: MlColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (value != null && value!.isNotEmpty) ...[
              const SizedBox(width: MlSpace.xs),
              Flexible(
                flex: 0,
                child: Text(
                  value!,
                  textAlign: TextAlign.right,
                  style: MlText.meta.copyWith(
                    fontWeight: FontWeight.w400,
                    color: MlColors.textSecondary,
                  ),
                ),
              ),
            ],
            if (toggle != null) ...[
              const SizedBox(width: MlSpace.sm),
              MlToggle(value: toggle!),
            ] else if (chevron) ...[
              const SizedBox(width: MlSpace.xs),
              const Icon(
                MlIcons.chevronRight,
                size: 17,
                color: MlColors.textTertiary,
              ),
            ],
          ],
        ),
      ),
    );
    if (onPressed == null) return row;
    return Semantics(
      toggled: toggle,
      child: FTappable(semanticsLabel: label, onPress: onPressed, child: row),
    );
  }
}

/// `.kv-list` row: secondary key on the left, value on the right.
class MlKeyValueRow extends StatelessWidget {
  const MlKeyValueRow({super.key, required this.keyText, required this.value});

  final String keyText;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: MlSpace.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          keyText,
          style: MlText.small.copyWith(color: MlColors.textSecondary),
        ),
        const SizedBox(width: MlSpace.md),
        Expanded(
          child: Text(value, textAlign: TextAlign.right, style: MlText.smallM),
        ),
      ],
    ),
  );
}

/// `.banner--*` tones.
enum MlBannerTone {
  info(MlColors.transferSoft, MlColors.transfer),
  warning(MlColors.warningSoft, MlColors.warningText),
  error(MlColors.errorSoft, MlColors.amountExpense),
  success(MlColors.successSoft, MlColors.success);

  const MlBannerTone(this.background, this.iconColor);

  final Color background;
  final Color iconColor;
}

/// `.banner`: tinted 16px-radius strip with an icon, title and body.
class MlBanner extends StatelessWidget {
  const MlBanner({
    super.key,
    required this.tone,
    required this.icon,
    this.title,
    this.body,
    this.onPressed,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.iconSize = 20,
  });

  final MlBannerTone tone;
  final IconData icon;
  final String? title;
  final String? body;
  final VoidCallback? onPressed;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final banner = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(MlRadius.lg),
      ),
      child: Row(
        children: [
          Icon(icon, size: iconSize, color: tone.iconColor),
          const SizedBox(width: MlSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: MlText.small.copyWith(fontWeight: FontWeight.w600),
                  ),
                if (body != null)
                  Text(
                    body!,
                    style: (title == null ? MlText.meta : MlText.caption)
                        .copyWith(
                          fontWeight: FontWeight.w400,
                          color: title == null
                              ? MlColors.textPrimary
                              : MlColors.textBody,
                        ),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
    if (onPressed == null) return banner;
    return FTappable(semanticsLabel: title, onPress: onPressed, child: banner);
  }
}

/// Section header with an optional trailing link (`.sec-h`).
class MlSectionHeader extends StatelessWidget {
  const MlSectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Semantics(
          header: true,
          child: Text(
            title,
            style: MlText.h3.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      ?trailing,
    ],
  );
}

/// The 13px muted heading above grouped lists ("ธนาคาร", "การเงิน").
class MlGroupTitle extends StatelessWidget {
  const MlGroupTitle(this.text, {super.key, this.top = MlSpace.lg});

  final String text;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(4, top, 0, MlSpace.xs),
    child: Text(
      text,
      style: MlText.meta.copyWith(color: MlColors.textSecondary),
    ),
  );
}
