import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/text_styles.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ml_button.dart';
import '../../../core/widgets/ml_overlays.dart';
import '../../../l10n/l10n.dart';

/// A day / month / Buddhist-era year chosen in [showBirthPickerSheet].
typedef BirthPick = ({int day, int month, int year});

/// How many Buddhist years the year wheel reaches back from this year.
const _yearSpan = 120;

/// Birth date sheet: three wheels (day, month, year) and a Done button, so
/// no keyboard is ever needed. The day wheel shortens to fit the month, so
/// an impossible date such as 31 February cannot be picked.
///
/// [initial] seeds the wheels; null starts at 1 January, 25 years back.
Future<BirthPick?> showBirthPickerSheet(
  BuildContext context, {
  required int currentYearBuddhist,
  BirthPick? initial,
}) => showMlSheet<BirthPick>(
  context,
  builder: (_) => _BirthPickerSheet(
    currentYear: currentYearBuddhist,
    initial: initial ?? (day: 1, month: 1, year: currentYearBuddhist - 25),
  ),
);

class _BirthPickerSheet extends StatefulWidget {
  const _BirthPickerSheet({required this.currentYear, required this.initial});

  final int currentYear;
  final BirthPick initial;

  @override
  State<_BirthPickerSheet> createState() => _BirthPickerSheetState();
}

class _BirthPickerSheetState extends State<_BirthPickerSheet> {
  static const _itemExtent = 46.0;

  late int _day = widget.initial.day;
  late int _month = widget.initial.month;
  late int _year = widget.initial.year;

  late final _dayController = FixedExtentScrollController(
    initialItem: _day - 1,
  );
  late final _monthController = FixedExtentScrollController(
    initialItem: _month - 1,
  );
  // Newest year first, so the wheel opens near the top of a short list.
  late final _yearController = FixedExtentScrollController(
    initialItem: widget.currentYear - _year,
  );

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  int get _daysInMonth => DateTime.utc(_year - 543, _month + 1, 0).day;

  /// After the month or year changed, pull the day back inside the month.
  void _clampDay() {
    final max = _daysInMonth;
    if (_day <= max) return;
    _day = max;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_dayController.hasClients) _dayController.jumpToItem(max - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tag = context.localeTag;
    return MlSheet(
      gap: MlSpace.md,
      children: [
        MlSheetHeader(title: l10n.authPickBirthTitle, closable: true),
        SizedBox(
          height: _itemExtent * 5,
          child: Stack(
            children: [
              // The band the selected row sits in.
              Center(
                child: Container(
                  height: _itemExtent,
                  decoration: BoxDecoration(
                    color: MlColors.soft,
                    borderRadius: BorderRadius.circular(MlRadius.field),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _Wheel(
                      semanticLabel: l10n.authDay,
                      controller: _dayController,
                      itemExtent: _itemExtent,
                      labels: [for (var d = 1; d <= _daysInMonth; d++) '$d'],
                      onChanged: (i) => setState(() => _day = i + 1),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: _Wheel(
                      semanticLabel: l10n.authMonth,
                      controller: _monthController,
                      itemExtent: _itemExtent,
                      labels: [
                        for (var m = 1; m <= 12; m++)
                          DateFormat.MMMM(tag).format(DateTime(2000, m)),
                      ],
                      onChanged: (i) => setState(() {
                        _month = i + 1;
                        _clampDay();
                      }),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: _Wheel(
                      semanticLabel: l10n.authYear,
                      controller: _yearController,
                      itemExtent: _itemExtent,
                      labels: [
                        for (var i = 0; i <= _yearSpan; i++)
                          '${widget.currentYear - i}',
                      ],
                      onChanged: (i) => setState(() {
                        _year = widget.currentYear - i;
                        _clampDay();
                      }),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        MlButton(
          label: l10n.actionDone,
          onPressed: () =>
              Navigator.of(context)
                  .pop<BirthPick>((day: _day, month: _month, year: _year)),
        ),
      ],
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.semanticLabel,
    required this.controller,
    required this.itemExtent,
    required this.labels,
    required this.onChanged,
  });

  final String semanticLabel;
  final FixedExtentScrollController controller;
  final double itemExtent;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    child: ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: itemExtent,
      physics: const FixedExtentScrollPhysics(),
      diameterRatio: 2.2,
      perspective: .002,
      overAndUnderCenterOpacity: .32,
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildListDelegate(
        children: [
          for (final label in labels)
            Center(
              child: Text(
                label,
                maxLines: 1,
                style: MlText.h2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: MlColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
