import 'package:flutter/material.dart'
    show InputDecoration, Material, MaterialType, TextField;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../app/theme/icons.dart';
import '../../app/theme/text_styles.dart';
import '../../app/theme/tokens.dart';

/// `.field--*` states from index.html. The review screen picks one from the
/// OCR confidence and the validation result.
enum MlFieldState {
  normal,

  /// `.field--uncertain`: yellow fill, 1.5px warning border.
  uncertain,

  /// `.field--missing`: 1.5px dashed error border.
  missing,

  /// `.field--error`: 1.5px error border.
  error,
}

/// The help line under a field (`.help--*`).
enum MlHelpTone {
  verified(MlColors.success, MlIcons.circleCheck),
  uncertain(MlColors.warningText, MlIcons.triangleAlert),
  error(MlColors.amountExpense, MlIcons.circleAlert),
  neutral(MlColors.textSecondary, null);

  const MlHelpTone(this.color, this.icon);

  final Color color;
  final IconData? icon;
}

/// Label + box + optional help line (`.field`).
class MlField extends StatelessWidget {
  const MlField({
    super.key,
    this.label,
    required this.child,
    this.help,
    this.helpTone = MlHelpTone.neutral,
  });

  final String? label;
  final Widget child;
  final String? help;
  final MlHelpTone helpTone;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (label != null) ...[
        Text(
          label!,
          style: MlText.meta.copyWith(color: MlColors.textSecondary),
        ),
        const SizedBox(height: 6),
      ],
      child,
      if (help != null) ...[
        const SizedBox(height: 6),
        MlHelpLine(text: help!, tone: helpTone),
      ],
    ],
  );
}

class MlHelpLine extends StatelessWidget {
  const MlHelpLine({super.key, required this.text, required this.tone});

  final String text;
  final MlHelpTone tone;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (tone.icon != null) ...[
        Padding(
          padding: const EdgeInsets.only(top: 2.5),
          child: Icon(tone.icon, size: 13, color: tone.color),
        ),
        const SizedBox(width: 4),
      ],
      Expanded(
        child: Text(text, style: MlText.caption.copyWith(color: tone.color)),
      ),
    ],
  );
}

/// The bordered box of a field. Tappable when [onPressed] is set (pickers).
class MlFieldBox extends StatelessWidget {
  const MlFieldBox({
    super.key,
    required this.child,
    this.state = MlFieldState.normal,
    this.height = 48,
    this.radius = MlRadius.field,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
    this.onPressed,
    this.semanticLabel,
    this.focused = false,
  });

  final Widget child;
  final MlFieldState state;
  final double height;
  final double radius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  /// `.field--focused`: 1.5px ink border.
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final (bg, color, width) = switch (state) {
      .uncertain => (MlColors.warningSoft, MlColors.warning, 1.5),
      .missing || .error => (MlColors.surface, MlColors.error, 1.5),
      .normal when focused => (MlColors.surface, MlColors.borderStrong, 1.5),
      .normal => (MlColors.surface, MlColors.border, 1.0),
    };
    final box = state == MlFieldState.missing
        ? CustomPaint(
            painter: _DashedBorderPainter(color: color, radius: radius),
            child: Container(
              height: height,
              padding: padding,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(radius),
              ),
              alignment: Alignment.centerLeft,
              child: child,
            ),
          )
        : AnimatedContainer(
            duration: MlDurations.fast,
            height: height,
            padding: padding,
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: color, width: width),
            ),
            child: child,
          );
    if (onPressed == null) return box;
    return FTappable(
      semanticsLabel: semanticLabel,
      onPress: onPressed,
      child: box,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    ).deflate(0.75);
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 5), paint);
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

/// A borderless text input that sits inside an [MlFieldBox] or a search
/// pill. Uses the framework's TextField with a collapsed decoration so the
/// surrounding box owns all styling.
class MlInput extends StatelessWidget {
  const MlInput({
    super.key,
    required this.controller,
    this.placeholder,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.style,
    this.textAlign = TextAlign.start,
    this.focusNode,
    this.semanticLabel,
    this.textInputAction,
    this.autofocus = false,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String? placeholder;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? style;
  final TextAlign textAlign;
  final FocusNode? focusNode;
  final String? semanticLabel;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final textStyle =
        style ?? MlText.title.copyWith(fontWeight: FontWeight.w400);
    return Semantics(
      label: semanticLabel,
      textField: true,
      // TextField needs a Material ancestor; screens are Forui-only.
      child: Material(
        type: MaterialType.transparency,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textAlign: textAlign,
          textInputAction: textInputAction,
          autofocus: autofocus,
          autofillHints: autofillHints,
          style: textStyle,
          cursorColor: MlColors.inverse,
          decoration: InputDecoration.collapsed(
            hintText: placeholder,
            hintStyle: textStyle.copyWith(color: MlColors.textTertiary),
          ),
        ),
      ),
    );
  }
}

/// `.search`: 48px pill with a search icon.
class MlSearchField extends StatelessWidget {
  const MlSearchField({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: MlSpace.md),
    decoration: BoxDecoration(
      color: MlColors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: MlColors.border),
    ),
    child: Row(
      children: [
        const Icon(MlIcons.search, size: 18, color: MlColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: MlInput(
            controller: controller,
            placeholder: placeholder,
            semanticLabel: placeholder,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
          ),
        ),
      ],
    ),
  );
}

/// Restricts input to digits, commas and one decimal point.
final amountInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
];
