import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../core/widgets/async_states.dart';
import '../features/sync/application/sync_controller.dart';
import '../core/widgets/ml_overlays.dart';
import '../l10n/app_localizations.dart';
import 'app_preferences.dart';
import 'providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class MoneyLensApp extends ConsumerWidget {
  const MoneyLensApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appPreferencesProvider.select((p) => p.locale));
    // Keeps sync running for the whole session (it does nothing without a
    // signed-in user and a configured project).
    ref.listen(syncControllerProvider, (_, _) {});
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.material(),
      routerConfig: ref.watch(routerProvider),
      locale: locale,
      // Thai is listed first so it is the fallback locale.
      supportedLocales: const [Locale('th'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        FLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => FTheme(
        data: AppTheme.light,
        child: FToaster(
          key: mlToasterKey,
          child: _StartupGate(child: child!),
        ),
      ),
    );
  }
}

/// Shows loading/error states until [appStartupProvider] completes.
class _StartupGate extends ConsumerWidget {
  const _StartupGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ref
        .watch(appStartupProvider)
        .when(
          data: (_) => child,
          loading: () => const LoadingView(),
          error: (_, _) => ErrorView(
            message: l10n.startupError,
            retryLabel: l10n.retry,
            onRetry: () => ref.invalidate(appStartupProvider),
          ),
        );
  }
}
