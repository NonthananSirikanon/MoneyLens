import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme/icons.dart';
import '../../app/theme/text_styles.dart';
import '../../app/theme/tokens.dart';
import 'ml_badges.dart';
import 'ml_button.dart';

/// Transaction-row skeleton (`.skel`) with a gentle shimmer.
class MlSkeletonList extends StatelessWidget {
  const MlSkeletonList({super.key, this.count = 6});

  final int count;

  static const _widths = [0.7, 0.55, 0.8, 0.5, 0.65, 0.58];

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading',
    child:
        Column(
              children: [
                for (var i = 0; i < count; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        const _Bone(width: 42, height: 42, radius: 21),
                        const SizedBox(width: MlSpace.sm),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, c) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Bone(
                                  width:
                                      c.maxWidth * _widths[i % _widths.length],
                                  height: 12,
                                  radius: 6,
                                ),
                                const SizedBox(height: 6),
                                _Bone(
                                  width: c.maxWidth * .4,
                                  height: 10,
                                  radius: 5,
                                  color: MlColors.soft,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: MlSpace.sm),
                        const _Bone(width: 64, height: 12, radius: 6),
                      ],
                    ),
                  ),
              ],
            )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1200.ms, color: const Color(0xFFF7F7F3)),
  );
}

class _Bone extends StatelessWidget {
  const _Bone({
    required this.width,
    required this.height,
    required this.radius,
    this.color = MlColors.skeleton,
  });

  final double width;
  final double height;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

/// Illustration + title + body + actions, centred (`ยังไม่มีรายการ`,
/// `ไม่มีข้อมูลในช่วงนี้`).
class MlEmptyState extends StatelessWidget {
  const MlEmptyState({
    super.key,
    required this.title,
    required this.body,
    this.illustration,
    this.icon,
    this.actions = const [],
    this.topPadding = 36,
  });

  final String title;
  final String body;
  final String? illustration;

  /// Used instead of an illustration (search "no matches").
  final IconData? icon;
  final List<Widget> actions;
  final double topPadding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(16, topPadding, 16, 0),
    child: Column(
      children: [
        if (illustration != null)
          Illustration(illustration!, width: 240, height: 180),
        if (icon != null) Icon(icon, size: 28),
        SizedBox(height: illustration != null ? 16 : 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style:
              (illustration != null
                      ? MlText.h2.copyWith(fontSize: 18)
                      : MlText.body)
                  .copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          textAlign: TextAlign.center,
          style: MlText.small.copyWith(color: MlColors.textSecondary),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: MlSpace.xs,
            runSpacing: MlSpace.xs,
            children: actions,
          ),
        ],
      ],
    ),
  ).animate().fadeIn(duration: MlDurations.medium);
}

/// Error state with a rose icon disc, message, monospace code and retry.
class MlErrorState extends StatelessWidget {
  const MlErrorState({
    super.key,
    required this.title,
    required this.body,
    required this.retryLabel,
    required this.onRetry,
    this.code,
    this.icon = MlIcons.database,
  });

  final String title;
  final String body;
  final String retryLabel;
  final VoidCallback onRetry;
  final String? code;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 64, 16, 0),
    child: Column(
      children: [
        TintIcon(
          icon: icon,
          tint: MlColors.errorSoft,
          size: 64,
          iconSize: 26,
          iconColor: MlColors.amountExpense,
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: MlText.h2.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          textAlign: TextAlign.center,
          style: MlText.small.copyWith(color: MlColors.textSecondary),
        ),
        if (code != null) ...[
          const SizedBox(height: 8),
          Text(code!, style: MlText.mono),
        ],
        const SizedBox(height: 20),
        MlButton(
          label: retryLabel,
          icon: MlIcons.refreshCw,
          height: 48,
          expand: false,
          onPressed: onRetry,
        ),
      ],
    ),
  );
}

/// `.success-ring`: green disc with a check.
class MlSuccessRing extends StatelessWidget {
  const MlSuccessRing({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) => TintIcon(
    icon: MlIcons.check,
    tint: MlColors.successSoft,
    size: size,
    iconSize: size / 2,
    iconColor: MlColors.success,
  ).animate().scale(duration: MlDurations.medium, curve: Curves.easeOutBack);
}
