import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/icons.dart';
import '../../../app/theme/text_styles.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ml_badges.dart';
import '../../../core/widgets/ml_controls.dart';
import '../../../core/widgets/ml_state_views.dart';
import '../../../l10n/l10n.dart';
import '../application/import_view_providers.dart';
import 'import_flows.dart';
import 'scan_tile.dart';

/// "สลิปที่นำเข้า" queue showing every scan status (SL-10).
class ImportScreen extends ConsumerWidget {
  const ImportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scans = ref.watch(scanViewsProvider);
    return ColoredBox(
      color: MlColors.bgApp,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Transform.translate(
              offset: const Offset(-8, 0),
              child: MlAppBar(
                title: l10n.queueTitle(scans.length),
                onLeading: () => context.pop(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      MlIcons.shieldCheck,
                      size: 14,
                      color: MlColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.queueNotice,
                      style: MlText.caption.copyWith(
                        color: MlColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (scans.isEmpty)
              MlEmptyState(
                illustration: MlImages.emptyTransactions,
                title: l10n.scansEmpty,
                body: l10n.scansEmptyBody,
              ),
            for (final (i, v) in scans.indexed) ...[
              if (i > 0) const SizedBox(height: 10),
              ScanTile(
                key: ValueKey(v.scan.id),
                view: v,
                onAction: () => ImportFlows.openScan(context, v.scan),
              ).animate().fadeIn(duration: MlDurations.medium),
            ],
          ],
        ),
      ),
    );
  }
}
