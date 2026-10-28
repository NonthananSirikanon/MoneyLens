import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../app/theme/icons.dart';
import '../../app/theme/text_styles.dart';
import '../../app/theme/tokens.dart';
import '../../l10n/l10n.dart';
import 'ml_button.dart';

enum MlAppBarLeading { back, close }

/// The prototype's 52px header: a 44px back/close button, centred title and
/// a matching spacer. [light] renders white content for the dark camera UI.
class MlAppBar extends StatelessWidget {
  const MlAppBar({
    super.key,
    this.title,
    this.leading = MlAppBarLeading.back,
    required this.onLeading,
    this.light = false,
    this.glass = false,
  });

  final String? title;
  final MlAppBarLeading leading;
  final VoidCallback onLeading;
  final bool light;

  /// Translucent round button used on the camera/preview screens.
  final bool glass;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isBack = leading == MlAppBarLeading.back;
    final button = MlIconButton(
      icon: isBack ? MlIcons.arrowLeft : MlIcons.x,
      semanticLabel: isBack ? l10n.actionBack : l10n.actionClose,
      onPressed: onLeading,
      variant: glass ? MlIconButtonVariant.glass : MlIconButtonVariant.plain,
      iconSize: glass ? 20 : 22,
      color: light ? MlColors.textInverse : null,
    );
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          button,
          Expanded(
            child: title == null
                ? const SizedBox.shrink()
                : Text(
                    title!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MlText.h3.copyWith(
                      fontWeight: FontWeight.w700,
                      color: light ? MlColors.textInverse : null,
                    ),
                  ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

/// Large page title on tab roots (`รายการ`, `วิเคราะห์`, `ตั้งค่า`).
class MlLargeTitle extends StatelessWidget {
  const MlLargeTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Semantics(header: true, child: Text(text, style: MlText.h1)),
  );
}

/// `.chip` (36px pill), selected = ink background.
class MlChip extends StatelessWidget {
  const MlChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.trailingIcon,
    this.highlight = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final IconData? trailingIcon;

  /// Sage "active filter" style used by the category chip.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = selected
        ? (MlColors.inverse, MlColors.textInverse, MlColors.inverse)
        : highlight
        ? (MlColors.sageSoft, MlColors.textPrimary, MlColors.sage)
        : (MlColors.surface, MlColors.textPrimary, MlColors.border);
    return FTappable(
      semanticsLabel: label,
      selected: selected,
      onPress: onPressed,
      child: Container(
        height: 36,
        padding: EdgeInsets.only(
          left: 16,
          right: trailingIcon == null ? 16 : 12,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: MlText.smallM.copyWith(color: fg, height: 1)),
            if (trailingIcon != null) ...[
              const SizedBox(width: 4),
              Icon(trailingIcon, size: 15, color: fg),
            ],
          ],
        ),
      ),
    );
  }
}

/// One option of an [MlSegmented].
class MlSegment<T> {
  const MlSegment(this.value, this.label);

  final T value;
  final String label;
}

enum MlSegmentedStyle {
  /// `.seg`: soft track, ink thumb, 36px.
  ink,

  /// Analytics expense/income switch: white thumb with a soft shadow, 34px.
  white,
}

/// `.seg` segmented control.
class MlSegmented<T> extends StatelessWidget {
  const MlSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.style = MlSegmentedStyle.ink,
    this.expand = true,
  });

  final List<MlSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final MlSegmentedStyle style;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final white = style == MlSegmentedStyle.white;
    final children = [
      for (final s in segments) _segment(s, s.value == selected, white),
    ];
    return Container(
      padding: EdgeInsets.all(white ? 3 : 4),
      decoration: BoxDecoration(
        color: MlColors.soft,
        borderRadius: BorderRadius.circular(MlRadius.full),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0 && !white) const SizedBox(width: 4),
            expand ? Expanded(child: children[i]) : children[i],
          ],
        ],
      ),
    );
  }

  Widget _segment(MlSegment<T> s, bool on, bool white) {
    final fg = white
        ? MlColors.textPrimary
        : on
        ? MlColors.textInverse
        : MlColors.textSecondary;
    return FTappable(
      semanticsLabel: s.label,
      selected: on,
      onPress: () => onChanged(s.value),
      child: AnimatedContainer(
        duration: MlDurations.fast,
        height: white ? 34 : 36,
        padding: EdgeInsets.symmetric(horizontal: white ? 14 : 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on
              ? (white ? MlColors.surface : MlColors.inverse)
              : const Color(0x00000000),
          borderRadius: BorderRadius.circular(MlRadius.full),
          boxShadow: on && white ? MlShadows.thumb : null,
        ),
        child: Text(
          s.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: (white ? MlText.meta : MlText.smallM).copyWith(
            color: fg,
            fontWeight: white ? FontWeight.w600 : FontWeight.w500,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

/// `.toggle` visual (48×28). Rows own the tap target and semantics.
class MlToggle extends StatelessWidget {
  const MlToggle({super.key, required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: MlDurations.fast,
    width: 48,
    height: 28,
    decoration: BoxDecoration(
      color: value ? MlColors.inverse : MlColors.border,
      borderRadius: BorderRadius.circular(14),
    ),
    child: AnimatedAlign(
      duration: MlDurations.fast,
      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 22,
        height: 22,
        margin: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          color: MlColors.surface,
          shape: BoxShape.circle,
          boxShadow: MlShadows.knob,
        ),
      ),
    ),
  );
}

/// The period selector pill (`.period`): optional leading icon, label and a
/// chevron.
class MlPeriodButton extends StatelessWidget {
  const MlPeriodButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) => FTappable(
    semanticsLabel: label,
    onPress: onPressed,
    child: Container(
      height: 40,
      padding: const EdgeInsets.only(left: 14, right: 12),
      decoration: BoxDecoration(
        color: MlColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MlColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 15),
            const SizedBox(width: 6),
          ],
          Text(label, style: MlText.meta.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          const Icon(MlIcons.chevronDown, size: 15),
        ],
      ),
    ),
  );
}
