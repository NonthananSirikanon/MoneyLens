import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_preferences.dart';
import '../../../app/router.dart';
import '../../auth/application/session.dart';
import '../../../app/theme/icons.dart';
import '../../../app/theme/text_styles.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ml_badges.dart';
import '../../../l10n/l10n.dart';

/// Three-slide introduction. "ข้าม" and the last slide's CTA go to the
/// permission screen.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  var _page = 0;

  static const _images = [
    MlImages.onboarding,
    MlImages.reviewFirst,
    MlImages.localData,
  ];

  /// Signed-in users replaying onboarding go home; everyone else signs in.
  void _finish() {
    if (ref.read(sessionProvider).isSignedIn) {
      ref
          .read(appPreferencesProvider.notifier)
          .finishOnboarding(
            permissionsGranted: ref
                .read(appPreferencesProvider)
                .permissionsGranted,
          );
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  void _next() {
    if (_page == _images.length - 1) {
      _finish();
    } else {
      setState(() => _page++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final slides = [
      (l10n.onboardingTitle1, l10n.onboardingBody1),
      (l10n.onboardingTitle2, l10n.onboardingBody2),
      (l10n.onboardingTitle3, l10n.onboardingBody3),
    ];
    final last = _page == slides.length - 1;
    return ColoredBox(
      color: MlColors.bgApp,
      child: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: (d) {
            final v = d.primaryVelocity ?? 0;
            if (v < -200) _next();
            if (v > 200 && _page > 0) setState(() => _page--);
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 44,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: last
                        ? null
                        : FTappable(
                            semanticsLabel: l10n.onboardingSkip,
                            onPress: _finish,
                            child: Padding(
                              padding: const EdgeInsets.all(MlSpace.xxs),
                              child: Text(
                                l10n.onboardingSkip,
                                style: MlText.smallM.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: MlColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: MlDurations.medium,
                      child: Illustration(
                        _images[_page],
                        key: ValueKey(_page),
                        width: 300,
                        height: 270,
                      ),
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: MlDurations.medium,
                  child: Column(
                    key: ValueKey(_page),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(slides[_page].$1, style: MlText.hero),
                      ),
                      const SizedBox(height: MlSpace.sm),
                      Text(
                        slides[_page].$2,
                        style: MlText.body.copyWith(
                          color: MlColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                Row(
                  children: [
                    for (var i = 0; i < slides.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      AnimatedContainer(
                        duration: MlDurations.medium,
                        width: i == _page ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page
                              ? MlColors.inverse
                              : MlColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                    const Spacer(),
                    FTappable(
                      semanticsLabel: last
                          ? l10n.onboardingStart
                          : l10n.actionNext,
                      onPress: _next,
                      child: AnimatedContainer(
                        duration: MlDurations.medium,
                        height: 56,
                        constraints: const BoxConstraints(minWidth: 56),
                        padding: EdgeInsets.symmetric(
                          horizontal: last ? 24 : 0,
                        ),
                        decoration: BoxDecoration(
                          color: MlColors.inverse,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (last) ...[
                              Text(
                                l10n.onboardingStart,
                                style: MlText.button.copyWith(
                                  color: MlColors.textInverse,
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            const Icon(
                              MlIcons.arrowRight,
                              size: 22,
                              color: MlColors.textInverse,
                            ),
                          ],
                        ),
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
  }
}
