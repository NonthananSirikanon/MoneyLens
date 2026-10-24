import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/widgets/async_states.dart';
import '../l10n/app_localizations.dart';
import 'providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class MoneyLensApp extends ConsumerWidget {
  const MoneyLensApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: ref.watch(routerProvider),
      // Thai is listed first so it is the fallback locale.
      supportedLocales: const [Locale('th'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => _StartupGate(child: child!),
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
          loading: () => const Material(child: LoadingView()),
          error: (_, _) => Material(
            child: ErrorView(
              message: l10n.startupError,
              retryLabel: l10n.retry,
              onRetry: () => ref.invalidate(appStartupProvider),
            ),
          ),
        );
  }
}
