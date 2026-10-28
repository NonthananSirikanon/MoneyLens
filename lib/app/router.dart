import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/accounts/presentation/accounts_screen.dart';
import '../features/analytics/presentation/analytics_screen.dart';
import '../features/categories/presentation/categories_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/onboarding/presentation/permissions_screen.dart';
import '../features/settings/presentation/data_settings_screen.dart';
import '../features/settings/presentation/security_settings_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/slip_import/presentation/camera_screen.dart';
import '../features/slip_import/presentation/denied_screen.dart';
import '../features/slip_import/presentation/duplicate_screen.dart';
import '../features/slip_import/presentation/import_screen.dart';
import '../features/slip_import/presentation/ocr_failed_screen.dart';
import '../features/slip_import/presentation/processing_screen.dart';
import '../features/slip_import/presentation/saved_screen.dart';
import '../features/transactions/application/entry_form.dart';
import '../features/transactions/presentation/entry_screen.dart';
import '../features/transactions/presentation/transaction_detail_screen.dart';
import '../features/transactions/presentation/transactions_screen.dart';
import '../features/auth/application/session.dart';
import '../features/auth/presentation/account_screen.dart';
import '../features/auth/presentation/birth_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import 'app_preferences.dart';
import 'auth_redirect.dart';
import 'shell/app_shell.dart';

/// Route paths. Flows map the prototype's navigation verbs onto GoRouter:
/// `go` → `push`, `replace` → `pushReplacement`, `tab` → `go` to a branch.
abstract final class AppRoutes {
  static const onboarding = '/onboarding';
  static const permissions = '/permissions';
  static const home = '/home';
  static const transactions = '/transactions';
  static const analytics = '/analytics';
  static const settings = '/settings';
  static const queue = '/queue';
  static const entry = '/entry';
  static const camera = '/camera';
  static const cameraPreview = '/camera/preview';
  static const categories = '/categories';
  static const accounts = '/accounts';
  static const dataSettings = '/data';
  static const securitySettings = '/security';
  static const login = '/login';
  static const signIn = '/signin';
  static const register = '/register';
  static const birth = '/birth';
  static const account = '/account';

  static String transaction(String id) => '/tx/$id';
  static String processing(String scanId) => '/processing/$scanId';
  static String duplicate(String scanId) => '/duplicate/$scanId';
  static String ocrFailed(String scanId) => '/ocr-failed/$scanId';
  static String saved(String transactionId) => '/saved/$transactionId';
  static String denied(DeniedKind kind) => '/denied/${kind.name}';
}

final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run the onboarding redirect whenever preferences change.
  final refresh = ValueNotifier(0);
  ref.listen(appPreferencesProvider, (_, _) => refresh.value++);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  GoRoute page(String path, Widget Function(GoRouterState s) build) => GoRoute(
    path: path,
    parentNavigatorKey: rootNavigatorKey,
    builder: (context, state) => build(state),
  );

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    // The redirect sends signed-out users to onboarding / sign-in.
    initialLocation: AppRoutes.home,
    refreshListenable: refresh,
    redirect: (context, state) => authRedirect(
      uri: state.uri,
      status: ref.read(sessionProvider).status,
      onboardingDone: ref.read(appPreferencesProvider).onboardingDone,
    ),
    routes: [
      page(AppRoutes.onboarding, (_) => const OnboardingScreen()),
      page(AppRoutes.permissions, (_) => const PermissionsScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          for (final (path, screen) in [
            (AppRoutes.home, const DashboardScreen()),
            (AppRoutes.transactions, const TransactionsScreen()),
            (AppRoutes.analytics, const AnalyticsScreen()),
            (AppRoutes.settings, const SettingsScreen()),
          ])
            StatefulShellBranch(
              routes: [GoRoute(path: path, builder: (_, _) => screen)],
            ),
        ],
      ),
      page(AppRoutes.queue, (_) => const ImportScreen()),
      page(
        AppRoutes.entry,
        (s) => EntryScreen(
          args: s.extra is EntryArgs
              ? s.extra! as EntryArgs
              : const ManualEntryArgs(),
        ),
      ),
      page(
        '/tx/:id',
        (s) => TransactionDetailScreen(id: s.pathParameters['id']!),
      ),
      page(AppRoutes.camera, (_) => const CameraScreen()),
      page(AppRoutes.cameraPreview, (_) => const CameraPreviewScreen()),
      page(
        '/processing/:scanId',
        (s) => ProcessingScreen(scanId: s.pathParameters['scanId']!),
      ),
      page(
        '/duplicate/:scanId',
        (s) => DuplicateScreen(scanId: s.pathParameters['scanId']!),
      ),
      page(
        '/ocr-failed/:scanId',
        (s) => OcrFailedScreen(scanId: s.pathParameters['scanId']!),
      ),
      page(
        '/saved/:txId',
        (s) => SavedScreen(transactionId: s.pathParameters['txId']!),
      ),
      page(
        '/denied/:kind',
        (s) => DeniedScreen(
          kind: DeniedKind.values.byName(s.pathParameters['kind']!),
        ),
      ),
      page(AppRoutes.categories, (_) => const CategoriesScreen()),
      page(AppRoutes.accounts, (_) => const AccountsScreen()),
      page(AppRoutes.login, (_) => const LoginScreen()),
      page(AppRoutes.signIn, (_) => const SignInScreen()),
      page(AppRoutes.register, (_) => const RegisterScreen()),
      page(
        AppRoutes.birth,
        (s) => BirthScreen(edit: s.uri.queryParameters['edit'] == '1'),
      ),
      page(AppRoutes.account, (_) => const AccountScreen()),
      page(AppRoutes.dataSettings, (_) => const DataSettingsScreen()),
      page(AppRoutes.securitySettings, (_) => const SecuritySettingsScreen()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
