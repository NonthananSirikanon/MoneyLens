import 'package:flutter/widgets.dart';

/// Colour tokens from the `:root` block of `design/mockups/index.html`
/// (mirrors the Figma "Color" collection). Widgets read colours from here,
/// never from literals.
abstract final class MlColors {
  // Backgrounds
  static const bgApp = Color(0xFFF8F7F3);
  static const surface = Color(0xFFFFFFFF);
  static const soft = Color(0xFFF0F0EC);
  static const inverse = Color(0xFF171717);
  static const sage = Color(0xFFA8B89A);
  static const balance = Color(0xFFCBD5C0);
  static const chartSoft = Color(0xFFC9D3BE);
  static const sageSoft = Color(0xFFE6EBDF);
  static const successSoft = Color(0xFFE3EFE7);
  static const errorSoft = Color(0xFFF6E4E2);
  static const warningSoft = Color(0xFFF7EDD6);
  static const transferSoft = Color(0xFFE3E8EE);
  static const lavenderSoft = Color(0xFFECEAF2);

  // Text
  static const textPrimary = Color(0xFF171717);
  static const textSecondary = Color(0xFF777771);
  static const textTertiary = Color(0xFFA3A39C);
  static const textInverse = Color(0xFFFFFFFF);
  static const textBody = Color(0xFF3F3F3B);

  // Borders
  static const border = Color(0xFFE7E6E0);
  static const borderStrong = Color(0xFF171717);

  // Status
  static const success = Color(0xFF4F8A68);
  static const error = Color(0xFFC96F68);
  static const warning = Color(0xFFD9AE58);
  static const transfer = Color(0xFF5F7487);
  static const accentYellow = Color(0xFFE8C26A);

  // Prototype-only semantic values (prototype.html `C` constants and pills).
  static const amountExpense = Color(0xFFB55A53);
  static const amountIncome = Color(0xFF3F7A57);
  static const warningText = Color(0xFF8A6416);
  static const warningPillText = Color(0xFF7D6020);
  static const p1Text = Color(0xFF8A6A22);
  static const balanceMuted = Color(0xFF3B4A35);
  static const skeleton = Color(0xFFECEBE6);
  static const scrim = Color(0x6B171717); // rgba(23,23,23,.42)
  static const cameraBg = Color(0xFF0F0F0E);
  static const cameraFrame = Color(0xFF2A2A28);
  static const cameraOutline = Color(0xFF4A4A46);
  static const cameraHint = Color(0xFFC9C8C2);
  static const glass = Color(0x24FFFFFF); // rgba(255,255,255,.14)
  static const navBg = Color(0xF5FFFFFF); // rgba(255,255,255,.96)
}

/// `--space-*` tokens.
abstract final class MlSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 40.0;

  /// Horizontal page gutter used by every prototype screen.
  static const gutter = lg;

  /// Bottom padding for scroll views that sit under the bottom nav.
  static const navClearance = 120.0;
}

/// `--radius-*` tokens.
abstract final class MlRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const full = 999.0;

  /// Form field boxes in the prototype use 14px.
  static const field = 14.0;
}

abstract final class MlShadows {
  static const fab = [
    BoxShadow(color: Color(0x33171717), blurRadius: 16, offset: Offset(0, 6)),
  ];
  static const dialog = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 32, offset: Offset(0, 12)),
  ];
  static const toast = [
    BoxShadow(color: Color(0x2E000000), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const thumb = [
    BoxShadow(color: Color(0x1A171717), blurRadius: 3, offset: Offset(0, 1)),
  ];
  static const knob = [
    BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1)),
  ];
}

abstract final class MlDurations {
  static const fast = Duration(milliseconds: 200);
  static const medium = Duration(milliseconds: 250);
  static const toast = Duration(milliseconds: 1900);
}
