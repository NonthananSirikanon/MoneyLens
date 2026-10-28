import 'package:flutter/widgets.dart';

import '../../app/theme/icons.dart';
import '../../app/theme/text_styles.dart';
import '../../app/theme/tokens.dart';
import 'ml_button.dart';

/// Shared loading / empty / error placeholders for whole-screen states such
/// as app startup. Feature screens use the richer views in
/// `ml_state_views.dart`.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: MlColors.bgApp,
    child: Center(
      child: Text(
        'MoneyLens',
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
          color: MlColors.textPrimary,
        ),
      ),
    ),
  );
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(MlSpace.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: MlSpace.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: MlText.small.copyWith(color: MlColors.textSecondary),
          ),
        ],
      ),
    ),
  );
}

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel,
  });

  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: MlColors.bgApp,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(MlSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: MlColors.errorSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                MlIcons.database,
                size: 26,
                color: MlColors.amountExpense,
              ),
            ),
            const SizedBox(height: MlSpace.md),
            Text(message, textAlign: TextAlign.center, style: MlText.small),
            if (onRetry != null && retryLabel != null) ...[
              const SizedBox(height: MlSpace.lg),
              MlButton(
                label: retryLabel!,
                icon: MlIcons.refreshCw,
                height: 48,
                expand: false,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
