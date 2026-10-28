import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Theme choice shown in Settings. Only a light palette is designed, so this
/// is stored but does not change colours yet.
enum ThemePreference { light, dark, system }

/// App-wide UI preferences and simulated permission state.
///
/// Held in memory only: persisting them needs a storage dependency that the
/// MVP has not chosen yet, so onboarding shows on every cold start, as it
/// does in the prototype.
@immutable
class AppPreferences {
  const AppPreferences({
    this.onboardingDone = false,
    this.permissionsGranted = true,
    this.hideBalances = false,
    this.notifications = true,
    this.faceId = false,
    this.autoDeleteSlips = true,
    this.theme = ThemePreference.light,
    this.locale = const Locale('th'),
  });

  final bool onboardingDone;

  /// SIMULATED camera/photo permission (no permission plugin yet).
  final bool permissionsGranted;
  final bool hideBalances;
  final bool notifications;

  /// SIMULATED: no biometric plugin yet.
  final bool faceId;
  final bool autoDeleteSlips;
  final ThemePreference theme;
  final Locale locale;

  AppPreferences copyWith({
    bool? onboardingDone,
    bool? permissionsGranted,
    bool? hideBalances,
    bool? notifications,
    bool? faceId,
    bool? autoDeleteSlips,
    ThemePreference? theme,
    Locale? locale,
  }) => AppPreferences(
    onboardingDone: onboardingDone ?? this.onboardingDone,
    permissionsGranted: permissionsGranted ?? this.permissionsGranted,
    hideBalances: hideBalances ?? this.hideBalances,
    notifications: notifications ?? this.notifications,
    faceId: faceId ?? this.faceId,
    autoDeleteSlips: autoDeleteSlips ?? this.autoDeleteSlips,
    theme: theme ?? this.theme,
    locale: locale ?? this.locale,
  );
}

class AppPreferencesController extends Notifier<AppPreferences> {
  @override
  AppPreferences build() => const AppPreferences();

  void finishOnboarding({required bool permissionsGranted}) => state = state
      .copyWith(onboardingDone: true, permissionsGranted: permissionsGranted);

  void restartOnboarding() => state = state.copyWith(onboardingDone: false);

  void setPermissionsGranted(bool value) =>
      state = state.copyWith(permissionsGranted: value);

  void toggleHideBalances() =>
      state = state.copyWith(hideBalances: !state.hideBalances);

  void toggleNotifications() =>
      state = state.copyWith(notifications: !state.notifications);

  void toggleFaceId() => state = state.copyWith(faceId: !state.faceId);

  void toggleAutoDelete() =>
      state = state.copyWith(autoDeleteSlips: !state.autoDeleteSlips);

  void cycleTheme() => state = state.copyWith(
    theme: ThemePreference
        .values[(state.theme.index + 1) % ThemePreference.values.length],
  );

  void toggleLanguage() => state = state.copyWith(
    locale: state.locale.languageCode == 'th'
        ? const Locale('en')
        : const Locale('th'),
  );
}

final appPreferencesProvider =
    NotifierProvider<AppPreferencesController, AppPreferences>(
      AppPreferencesController.new,
    );
