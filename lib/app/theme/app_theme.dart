import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

import 'text_styles.dart';
import 'tokens.dart';

/// Forui theme built from the index.html tokens.
///
/// Only a light palette exists in the design system, so there is no dark
/// variant; the Settings theme row stores a preference but does not change
/// colours until a dark palette is designed.
abstract final class AppTheme {
  static final FColors colors = FColors(
    brightness: Brightness.light,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    barrier: MlColors.scrim,
    background: MlColors.bgApp,
    foreground: MlColors.textPrimary,
    primary: MlColors.inverse,
    primaryForeground: MlColors.textInverse,
    secondary: MlColors.soft,
    secondaryForeground: MlColors.textPrimary,
    muted: MlColors.soft,
    mutedForeground: MlColors.textSecondary,
    destructive: MlColors.amountExpense,
    destructiveForeground: MlColors.textInverse,
    error: MlColors.error,
    errorForeground: MlColors.textInverse,
    card: MlColors.surface,
    border: MlColors.border,
    disabledOpacity: 0.4,
  );

  static final FThemeData light = FThemeData(
    colors: colors,
    touch: true,
    debugLabel: 'MoneyLens light',
    typography: FTypography(
      display: FTypeface.inherit(
        colors: colors,
        touch: true,
        fontFamily: MlFonts.text,
        fontFamilyFallback: MlFonts.textFallback,
      ),
      body: FTypeface.inherit(
        colors: colors,
        touch: true,
        fontFamily: MlFonts.text,
        fontFamilyFallback: MlFonts.textFallback,
      ),
    ),
  );

  /// Material theme for the few Material widgets still in the tree
  /// (`MaterialApp`, `Scaffold`), so their defaults don't clash with Forui.
  ///
  /// Built by hand: Forui's `toApproximateMaterialTheme` targets the
  /// separate `material_ui` package, not `package:flutter/material.dart`.
  static ThemeData material() => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: MlColors.inverse,
      onPrimary: MlColors.textInverse,
      secondary: MlColors.soft,
      onSecondary: MlColors.textPrimary,
      surface: MlColors.bgApp,
      onSurface: MlColors.textPrimary,
      error: MlColors.error,
      onError: MlColors.textInverse,
      outline: MlColors.border,
    ),
    scaffoldBackgroundColor: MlColors.bgApp,
    fontFamily: MlFonts.text,
    fontFamilyFallback: MlFonts.textFallback,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: MlColors.inverse,
      selectionColor: MlColors.sageSoft,
      selectionHandleColor: MlColors.inverse,
    ),
  );
}
