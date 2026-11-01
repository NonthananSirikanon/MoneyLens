import 'package:flutter/widgets.dart';

import '../domain/category.dart';

/// Visual identity of a category: the tint behind its icon and the colour
/// used for it in charts.
@immutable
class CategoryStyle {
  const CategoryStyle({required this.tint, required this.chart});

  final Color tint;
  final Color chart;

  /// [colorValue] is the stored accent colour. The tint behind the icon is
  /// that colour at 22% over white.
  factory CategoryStyle.of(Category c) =>
      CategoryStyle.fromAccent(Color(c.colorValue ?? 0xFFC9C8C2));

  factory CategoryStyle.fromAccent(Color accent) => CategoryStyle(
    tint: Color.alphaBlend(
      accent.withValues(alpha: .22),
      const Color(0xFFFFFFFF),
    ),
    chart: accent,
  );
}
