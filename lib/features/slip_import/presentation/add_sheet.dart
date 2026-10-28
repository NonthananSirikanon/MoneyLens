import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../../app/theme/icons.dart';
import '../../../app/theme/text_styles.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ml_badges.dart';
import '../../../core/widgets/ml_overlays.dart';
import '../../../demo/demo_config.dart';
import '../../../l10n/l10n.dart';
import 'import_flows.dart';

/// "เพิ่มรายการ" sheet opened from the bottom-nav add button.
Future<void> showAddSheet(BuildContext context) =>
    showMlSheet<void>(context, builder: (_) => const _AddSheet());

class _AddSheet extends ConsumerWidget {
  const _AddSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final slipsReady = ref.watch(sampleDataEnabledProvider);
    // Each option closes the sheet first, then navigates from the shell.
    final navContext = Navigator.of(context, rootNavigator: true).context;
    void then(void Function() action) {
      Navigator.of(context).pop();
      action();
    }

    return MlSheet(
      children: [
        MlSheetHeader(title: l10n.addSheetTitle, closable: true),
        _AddOption(
          icon: MlIcons.camera,
          label: l10n.addOptionCamera,
          sub: l10n.addOptionCameraSub,
          soon: !slipsReady,
          onPressed: () => then(() => ImportFlows.startCamera(navContext, ref)),
        ),
        _AddOption(
          icon: MlIcons.image,
          label: l10n.addOptionGallery,
          sub: l10n.addOptionGallerySub,
          soon: !slipsReady,
          onPressed: () =>
              then(() => ImportFlows.startGallery(navContext, ref)),
        ),
        _AddOption(
          icon: MlIcons.pencil,
          label: l10n.addOptionManual,
          sub: l10n.addOptionManualSub,
          onPressed: () => then(() => ImportFlows.startManual(navContext)),
        ),
        _AddOption(
          icon: MlIcons.sparkles,
          label: l10n.addOptionAuto,
          sub: l10n.addOptionAutoSub,
          soon: true,
          onPressed: () => showMlToast(l10n.toastFeatureTesting),
        ),
        Row(
          children: [
            const Icon(MlIcons.share, size: 14, color: MlColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l10n.addSheetShareHint,
                style: MlText.caption.copyWith(color: MlColors.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// `.option` row.
class _AddOption extends StatelessWidget {
  const _AddOption({
    required this.icon,
    required this.label,
    required this.sub,
    required this.onPressed,
    this.soon = false,
  });

  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback onPressed;
  final bool soon;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: soon ? 0.55 : 1,
    child: FTappable(
      semanticsLabel: label,
      onPress: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: MlColors.bgApp,
          borderRadius: BorderRadius.circular(MlRadius.lg),
          border: Border.all(color: MlColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: MlColors.surface,
                borderRadius: BorderRadius.circular(MlRadius.md),
                border: Border.all(color: MlColors.border),
              ),
              child: Icon(icon, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: MlText.title),
                  Text(
                    sub,
                    style: MlText.caption.copyWith(
                      color: MlColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (soon) MlTag(context.l10n.soonTag),
          ],
        ),
      ),
    ),
  );
}
