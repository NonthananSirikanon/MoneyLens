import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/text_styles.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ml_badges.dart';
import '../../../core/widgets/ml_button.dart';
import '../../../core/widgets/ml_state_views.dart';
import '../../../l10n/formatting.dart';
import '../../../l10n/l10n.dart';
import '../../transactions/application/transaction_view_providers.dart';
import '../application/import_view_providers.dart';
import 'import_flows.dart';

/// "บันทึกแล้ว" success screen after saving a new transaction.
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final v = ref.watch(transactionViewProvider(transactionId));
    final pending = ref.watch(pendingScansProvider);
    final summary = v == null
        ? ''
        : [
            v.title.split(' ').first,
            context.signedAmount(v.type, v.transaction.amount),
            v.isTransfer ? l10n.transferCategoryName : (v.category?.name ?? ''),
          ].join(' · ');

    return ColoredBox(
      color: MlColors.bgApp,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight - 60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Illustration(MlImages.saved, width: 240, height: 200),
                  const SizedBox(height: MlSpace.sm),
                  const MlSuccessRing(),
                  const SizedBox(height: MlSpace.sm),
                  Semantics(
                    header: true,
                    liveRegion: true,
                    child: Text(
                      l10n.savedTitle,
                      style: MlText.h1.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    summary,
                    textAlign: TextAlign.center,
                    style: MlText.title.copyWith(
                      fontWeight: FontWeight.w400,
                      color: MlColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 36),
                  MlButton(
                    label: l10n.savedView,
                    onPressed: () => context.pushReplacement(
                      AppRoutes.transaction(transactionId),
                    ),
                  ),
                  if (pending.isNotEmpty) ...[
                    const SizedBox(height: MlSpace.xs),
                    MlButton(
                      label: l10n.savedNext(pending.length),
                      variant: MlButtonVariant.outline,
                      height: 52,
                      onPressed: () => ImportFlows.openScan(
                        context,
                        pending.first,
                        replace: true,
                      ),
                    ),
                  ],
                  const SizedBox(height: MlSpace.xs),
                  MlButton(
                    label: l10n.savedHome,
                    variant: MlButtonVariant.ghost,
                    height: 44,
                    onPressed: () => context.go(AppRoutes.home),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
