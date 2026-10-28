import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';

import '../../app/theme/icons.dart';
import '../../app/theme/text_styles.dart';
import '../../app/theme/tokens.dart';

/// Rounded pill with an icon and label (`.pill`, `.badge`).
class MlPill extends StatelessWidget {
  const MlPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
    this.iconColor,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 2, 10, 2),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(MlRadius.full),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: iconColor ?? foreground),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MlText.label.copyWith(color: foreground),
          ),
        ),
      ],
    ),
  );
}

/// Small square tag: "เร็วๆ นี้" (soon), "กำลังทดสอบ" (testing), "P1".
enum MlTagTone {
  soft(MlColors.soft, MlColors.textSecondary),
  warning(MlColors.warningSoft, MlColors.warningPillText),
  p1(MlColors.warningSoft, MlColors.p1Text);

  const MlTagTone(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

class MlTag extends StatelessWidget {
  const MlTag(this.label, {super.key, this.tone = MlTagTone.soft});

  final String label;
  final MlTagTone tone;

  @override
  Widget build(BuildContext context) => Container(
    padding: tone == MlTagTone.p1
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: tone.background,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style:
          (tone == MlTagTone.p1
                  ? MlText.micro.copyWith(fontSize: 10)
                  : MlText.micro)
              .copyWith(
                fontWeight: FontWeight.w600,
                color: tone.foreground,
                height: 1.1,
              ),
    ),
  );
}

/// Tinted circle (or rounded square) holding an icon — category, account
/// and permission avatars.
class TintIcon extends StatelessWidget {
  const TintIcon({
    super.key,
    required this.icon,
    required this.tint,
    this.size = 42,
    this.iconSize = 18,
    this.radius,
    this.iconColor = MlColors.textPrimary,
  });

  final IconData icon;
  final Color tint;
  final double size;
  final double iconSize;

  /// Null for a circle.
  final double? radius;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: tint,
      shape: radius == null ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: radius == null ? null : BorderRadius.circular(radius!),
    ),
    alignment: Alignment.center,
    child: Icon(icon, size: iconSize, color: iconColor),
  );
}

/// `.progress`: 6px soft track with a sage fill.
class MlProgressBar extends StatelessWidget {
  const MlProgressBar({
    super.key,
    required this.value,
    this.color = MlColors.sage,
    this.animate = true,
  });

  /// 0–1.
  final double value;
  final Color color;
  final bool animate;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(3),
    child: Container(
      height: 6,
      color: MlColors.soft,
      alignment: Alignment.centerLeft,
      child: LayoutBuilder(
        builder: (context, c) => AnimatedContainer(
          duration: animate ? MlDurations.fast : Duration.zero,
          width: c.maxWidth * value.clamp(0, 1),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    ),
  );
}

enum MlStepState { done, now, todo }

/// `.steps`: processing checklist with a numbered/checked/spinning dot.
class MlStepList extends StatelessWidget {
  const MlStepList({super.key, required this.steps});

  final List<(String, MlStepState)> steps;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < steps.length; i++) ...[
        if (i > 0) const SizedBox(height: 14),
        _step(i + 1, steps[i].$1, steps[i].$2),
      ],
    ],
  );

  Widget _step(int n, String label, MlStepState state) {
    final (bg, fg) = switch (state) {
      .done => (MlColors.successSoft, MlColors.success),
      .now => (MlColors.inverse, MlColors.textInverse),
      .todo => (MlColors.soft, MlColors.textTertiary),
    };
    return Row(
      children: [
        AnimatedContainer(
          duration: MlDurations.medium,
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: switch (state) {
            .done => Icon(MlIcons.check, size: 15, color: fg),
            .now => _Spinner(color: fg),
            .todo => Text(
              '$n',
              style: MlText.meta.copyWith(
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          },
        ),
        const SizedBox(width: MlSpace.sm),
        Expanded(
          child: Text(
            label,
            style: MlText.title.copyWith(
              fontWeight: FontWeight.w400,
              color: state == MlStepState.todo
                  ? MlColors.textTertiary
                  : MlColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _Spinner extends StatefulWidget {
  const _Spinner({required this.color});

  final Color color;

  @override
  State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
    turns: _c,
    child: Icon(MlIcons.loader, size: 15, color: widget.color),
  );
}

/// Hand-drawn ink illustration. The PNGs have white paper backgrounds; the
/// mockups use `mix-blend-mode:multiply`, reproduced by multiplying with the
/// surface colour behind them.
class Illustration extends StatelessWidget {
  const Illustration(
    this.asset, {
    super.key,
    this.width,
    this.height,
    this.background = MlColors.bgApp,
  });

  final String asset;
  final double? width;
  final double? height;
  final Color background;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Image.asset(
      asset,
      width: width,
      height: height,
      fit: BoxFit.contain,
      color: background,
      colorBlendMode: BlendMode.multiply,
    ),
  );
}

/// Asset paths for the illustrations copied from design/mockups/assets.
abstract final class MlImages {
  static const onboarding = 'assets/images/ill-onboard.png';
  static const reviewFirst = 'assets/images/ill-i5.png';
  static const localData = 'assets/images/ill-i1.png';
  static const permission = 'assets/images/ill-i6.png';
  static const denied = 'assets/images/ill-i4.png';
  static const balanceCard = 'assets/images/ill-card.png';
  static const emptyTransactions = 'assets/images/ill-empty1.png';
  static const emptyAnalytics = 'assets/images/ill-empty2.png';
  static const saved = 'assets/images/ill-saved.png';
  static const receipt = 'assets/images/receipt.png';
}

/// The slip photo, cropped to cover. [degraded] adds the blur/greyscale
/// used for failed reads.
class SlipImage extends StatelessWidget {
  const SlipImage({
    super.key,
    this.width,
    this.height,
    this.radius = MlRadius.sm,
    this.degraded = false,
    this.border = false,
    this.fit = BoxFit.cover,
    this.semanticLabel,
  });

  final double? width;
  final double? height;
  final double radius;
  final bool degraded;
  final bool border;
  final BoxFit fit;
  final String? semanticLabel;

  static const _greyscale = ColorFilter.matrix([
    0.6, 0.3, 0.1, 0, 0, //
    0.2, 0.7, 0.1, 0, 0,
    0.2, 0.3, 0.5, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      MlImages.receipt,
      width: width,
      height: height,
      fit: fit,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
    if (degraded) {
      image = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
        child: ColorFiltered(colorFilter: _greyscale, child: image),
      );
    }
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: border ? Border.all(color: MlColors.border) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: image,
    );
  }
}
