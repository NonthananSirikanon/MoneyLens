import 'package:flutter/widgets.dart';

import 'tokens.dart';

/// Font families bundled in `assets/fonts` (see pubspec.yaml).
abstract final class MlFonts {
  /// `--font-th`: Thai text first, Latin from Plus Jakarta Sans.
  static const text = 'NotoSansThai';
  static const textFallback = ['PlusJakartaSans'];

  /// `--font-num`: amounts and Latin display text.
  static const number = 'PlusJakartaSans';
  static const numberFallback = ['NotoSansThai'];
}

/// The type scale from index.html (`.hero` … `.caption`, `.amt-*`), which
/// mirrors the Figma text styles. Colour defaults to the primary text colour.
abstract final class MlText {
  static TextStyle _t(
    double size,
    double height,
    FontWeight weight, {
    double letterSpacing = 0,
  }) => TextStyle(
    fontFamily: MlFonts.text,
    fontFamilyFallback: MlFonts.textFallback,
    fontSize: size,
    height: height / size,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    color: MlColors.textPrimary,
    leadingDistribution: TextLeadingDistribution.even,
  );

  static TextStyle _n(
    double size,
    double height,
    FontWeight weight, {
    double letterSpacing = 0,
  }) => TextStyle(
    fontFamily: MlFonts.number,
    fontFamilyFallback: MlFonts.numberFallback,
    fontSize: size,
    height: height / size,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    color: MlColors.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
    leadingDistribution: TextLeadingDistribution.even,
  );

  static final hero = _t(34, 46, FontWeight.w700, letterSpacing: -.4);
  static final h1 = _t(26, 36, FontWeight.w700, letterSpacing: -.2);
  static final h2 = _t(20, 30, FontWeight.w600);
  static final h3 = _t(17, 26, FontWeight.w600);
  static final body = _t(16, 26, FontWeight.w400);
  static final bodyM = _t(16, 26, FontWeight.w500);
  static final small = _t(14, 22, FontWeight.w400);
  static final smallM = _t(14, 22, FontWeight.w500);
  static final label = _t(12, 18, FontWeight.w500);
  static final caption = _t(12, 18, FontWeight.w400);

  /// 15px row titles and button labels used throughout the prototype.
  static final title = _t(15, 22, FontWeight.w600);
  static final button = _t(15, 22, FontWeight.w600);

  /// 13px secondary labels (field labels, date headers).
  static final meta = _t(13, 20, FontWeight.w500);

  /// 11px chart axis labels and tags.
  static final micro = _t(11, 16, FontWeight.w400);

  static final amtXl = _n(36, 44, FontWeight.w800, letterSpacing: -1);
  static final amtL = _n(28, 36, FontWeight.w800, letterSpacing: -.6);
  static final amtM = _n(16, 24, FontWeight.w600);
  static final amtS = _n(14, 20, FontWeight.w600);

  /// Balance card total (34px) and the big amount input (44px).
  static final amtHero = _n(34, 42, FontWeight.w800, letterSpacing: -1);
  static final amtInput = _n(44, 52, FontWeight.w800, letterSpacing: -1);

  /// Wordmark on onboarding-style surfaces.
  static final brand = _n(20, 24, FontWeight.w800, letterSpacing: -.8);

  static final mono = const TextStyle(
    fontFamily: 'Menlo',
    fontFamilyFallback: ['Courier'],
    fontSize: 12,
    height: 18 / 12,
    color: MlColors.textTertiary,
  );
}

/// `.amt--expense/income/transfer/neutral`.
enum AmountTone {
  expense(MlColors.amountExpense),
  income(MlColors.amountIncome),
  transfer(MlColors.transfer),
  neutral(MlColors.textPrimary);

  const AmountTone(this.color);

  final Color color;
}
