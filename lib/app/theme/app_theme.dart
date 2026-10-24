import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _seed = Color(0xFF0F766E);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      cardTheme: const CardThemeData(margin: EdgeInsets.zero),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}

/// Semantic colours for amounts, kept out of individual widgets.
extension AmountColors on ColorScheme {
  Color get incomeColor => brightness == Brightness.light
      ? const Color(0xFF15803D)
      : const Color(0xFF4ADE80);

  Color get expenseColor => error;
}
