import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../app/theme/text_styles.dart';
import '../../app/theme/tokens.dart';

/// `.btn--*` variants from index.html.
enum MlButtonVariant {
  primary(MlColors.inverse, MlColors.textInverse, null),
  secondary(MlColors.soft, MlColors.textPrimary, null),
  outline(MlColors.surface, MlColors.textPrimary, MlColors.border),
  ghost(Color(0x00000000), MlColors.textSecondary, null),
  destructive(MlColors.errorSoft, MlColors.amountExpense, null),
  destructiveSolid(MlColors.amountExpense, MlColors.textInverse, null),
  destructiveGhost(Color(0x00000000), MlColors.amountExpense, null),
  light(MlColors.surface, MlColors.textPrimary, null),
  darkOutline(Color(0x00000000), MlColors.textInverse, MlColors.cameraOutline);

  const MlButtonVariant(this.background, this.foreground, this.border);

  final Color background;
  final Color foreground;
  final Color? border;
}

/// `.btn`: pill button. [height] is 54 for primary CTAs, 52 for secondary
/// rows, 48 for compact and 44 for ghost links, matching the prototype.
class MlButton extends StatelessWidget {
  const MlButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = MlButtonVariant.primary,
    this.icon,
    this.trailingIcon,
    this.height = 54,
    this.expand = true,
    this.enabled = true,
    this.fontWeight,
    this.horizontalPadding = MlSpace.xl,
  });

  final String label;
  final VoidCallback? onPressed;
  final MlButtonVariant variant;
  final IconData? icon;
  final IconData? trailingIcon;
  final double height;
  final bool expand;

  /// When false the button is shown at 40% opacity (`.btn.disabled`) and
  /// taps are ignored.
  final bool enabled;
  final FontWeight? fontWeight;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final fg = variant.foreground;
    final weight =
        fontWeight ??
        (variant == MlButtonVariant.primary && height >= 54
            ? FontWeight.w700
            : FontWeight.w600);
    final style = MlText.button.copyWith(
      color: fg,
      fontWeight: weight,
      fontSize: height <= 48 ? 14 : 15,
    );
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: MlSpace.xs),
        ],
        Flexible(
          child: Text(
            label,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: MlSpace.xs),
          Icon(trailingIcon, size: 18, color: fg),
        ],
      ],
    );
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: FTappable(
        semanticsLabel: label,
        onPress: enabled ? onPressed : null,
        builder: (context, variants, child) => AnimatedScale(
          scale: variants.contains(FTappableVariant.pressed) ? 0.98 : 1,
          duration: const Duration(milliseconds: 100),
          child: child,
        ),
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          decoration: BoxDecoration(
            color: variant.background,
            borderRadius: BorderRadius.circular(height / 2),
            border: variant.border == null
                ? null
                : Border.all(color: variant.border!),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// `.icon-btn--*` variants.
enum MlIconButtonVariant { plain, filled, soft, outline, glass }

/// 44×44 icon button (`.icon-btn`). [semanticLabel] is required because
/// these buttons have no visible text.
class MlIconButton extends StatelessWidget {
  const MlIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.variant = MlIconButtonVariant.plain,
    this.size = 44,
    this.iconSize = 22,
    this.color,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final MlIconButtonVariant variant;
  final double size;
  final double iconSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (variant) {
      .plain => (null, MlColors.textPrimary, null),
      .filled => (MlColors.inverse, MlColors.textInverse, null),
      .soft => (MlColors.soft, MlColors.textPrimary, null),
      .outline => (MlColors.surface, MlColors.textPrimary, MlColors.border),
      .glass => (MlColors.glass, MlColors.textInverse, null),
    };
    return FTappable(
      semanticsLabel: semanticLabel,
      onPress: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: border == null ? null : Border.all(color: border),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: iconSize, color: color ?? fg),
      ),
    );
  }
}

/// A borderless text link such as "ดูทั้งหมด" in section headers.
class MlTextLink extends StatelessWidget {
  const MlTextLink({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FTappable(
    semanticsLabel: label,
    onPress: onPressed,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: MlSpace.xs),
      child: Text(
        label,
        style: MlText.meta.copyWith(
          fontWeight: FontWeight.w400,
          color: MlColors.textSecondary,
        ),
      ),
    ),
  );
}
