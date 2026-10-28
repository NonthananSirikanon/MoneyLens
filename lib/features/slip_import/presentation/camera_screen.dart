import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/icons.dart';
import '../../../app/theme/text_styles.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ml_badges.dart';
import '../../../core/widgets/ml_button.dart';
import '../../../core/widgets/ml_controls.dart';
import '../../../demo/demo_store.dart';
import '../../../l10n/l10n.dart';
import 'import_flows.dart';

/// Dark scaffold shared by the camera and preview screens.
class _DarkScreen extends StatelessWidget {
  const _DarkScreen({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: ColoredBox(
      color: MlColors.cameraBg,
      child: SafeArea(
        child: DefaultTextStyle(
          style: MlText.body.copyWith(color: MlColors.textInverse),
          child: child,
        ),
      ),
    ),
  );
}

/// "สแกนสลิป" viewfinder.
///
/// SIMULATED: there is no camera plugin yet, so the frame shows the sample
/// slip and the shutter "captures" it. The real capture should go through
/// the existing `ImagePickerSource.camera()` adapter and slip pipeline.
class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  var _flash = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _DarkScreen(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: MlAppBar(
              title: l10n.cameraTitle,
              leading: MlAppBarLeading.close,
              light: true,
              glass: true,
              onLeading: () => context.pop(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
            child: Text(
              l10n.cameraHint,
              textAlign: TextAlign.center,
              style: MlText.meta.copyWith(
                fontWeight: FontWeight.w400,
                color: MlColors.cameraHint,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(MlRadius.xxl),
                child: ColoredBox(
                  color: MlColors.cameraFrame,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const Opacity(opacity: .92, child: SlipImage(radius: 0)),
                      ..._corners(),
                      LayoutBuilder(
                        builder: (context, c) => const _ScanLine()
                            .animate(onPlay: (a) => a.repeat(reverse: true))
                            .moveY(
                              begin: c.maxHeight * .3,
                              end: c.maxHeight * .62,
                              duration: 1600.ms,
                              curve: Curves.easeInOut,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _CameraControl(
                  icon: MlIcons.image,
                  label: l10n.cameraGallery,
                  onPressed: () =>
                      ImportFlows.startGallery(context, ref, replace: true),
                ),
                FTappable(
                  semanticsLabel: l10n.cameraShutter,
                  onPress: () =>
                      context.pushReplacement(AppRoutes.cameraPreview),
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: MlColors.textInverse, width: 4),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: MlColors.textInverse,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                Semantics(
                  toggled: _flash,
                  child: _CameraControl(
                    icon: MlIcons.zap,
                    label: l10n.cameraFlash,
                    color: _flash
                        ? const Color(0xFFE2BC6E)
                        : MlColors.textInverse,
                    onPressed: () => setState(() => _flash = !_flash),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _corners() {
    const side = BorderSide(color: MlColors.textInverse, width: 3);
    Widget corner({
      double? top,
      double? left,
      double? right,
      double? bottom,
      required Border border,
      required BorderRadius radius,
    }) => Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(border: border, borderRadius: radius),
      ),
    );
    return [
      corner(
        top: 14,
        left: 14,
        border: const Border(top: side, left: side),
        radius: const BorderRadius.only(topLeft: Radius.circular(12)),
      ),
      corner(
        top: 14,
        right: 14,
        border: const Border(top: side, right: side),
        radius: const BorderRadius.only(topRight: Radius.circular(12)),
      ),
      corner(
        bottom: 14,
        left: 14,
        border: const Border(bottom: side, left: side),
        radius: const BorderRadius.only(bottomLeft: Radius.circular(12)),
      ),
      corner(
        bottom: 14,
        right: 14,
        border: const Border(bottom: side, right: side),
        radius: const BorderRadius.only(bottomRight: Radius.circular(12)),
      ),
    ];
  }
}

class _ScanLine extends StatelessWidget {
  const _ScanLine();

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: MlColors.sage,
        boxShadow: [
          BoxShadow(color: Color(0xB3A8B89A), blurRadius: 18, spreadRadius: 4),
        ],
      ),
    ),
  );
}

class _CameraControl extends StatelessWidget {
  const _CameraControl({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = MlColors.textInverse,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) => FTappable(
    semanticsLabel: label,
    onPress: onPressed,
    child: SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 6),
          Text(label, style: MlText.caption.copyWith(color: color)),
        ],
      ),
    ),
  );
}

/// "ตรวจรูป": confirm the captured image before it is read.
class CameraPreviewScreen extends ConsumerWidget {
  const CameraPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return _DarkScreen(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: MlAppBar(
              title: l10n.previewTitle,
              leading: MlAppBarLeading.close,
              light: true,
              glass: true,
              onLeading: () => context.pop(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
              child: SlipImage(
                radius: MlRadius.xxl,
                semanticLabel: l10n.previewImage,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Text(
              l10n.previewQuestion,
              style: MlText.small.copyWith(color: MlColors.border),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 36),
            child: Row(
              children: [
                Expanded(
                  child: MlButton(
                    label: l10n.previewRetake,
                    icon: MlIcons.rotateCcw,
                    variant: MlButtonVariant.darkOutline,
                    horizontalPadding: MlSpace.sm,
                    onPressed: () => context.pushReplacement(AppRoutes.camera),
                  ),
                ),
                const SizedBox(width: MlSpace.sm),
                Expanded(
                  child: MlButton(
                    label: l10n.previewUse,
                    trailingIcon: MlIcons.arrowRight,
                    variant: MlButtonVariant.light,
                    fontWeight: FontWeight.w700,
                    horizontalPadding: MlSpace.sm,
                    onPressed: () {
                      final id = ref
                          .read(demoStoreProvider.notifier)
                          .captureFromCamera();
                      context.pushReplacement(AppRoutes.processing(id));
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
