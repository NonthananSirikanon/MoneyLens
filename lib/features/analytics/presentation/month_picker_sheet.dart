import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/icons.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/dates/clock.dart';
import '../../../core/dates/reporting_time_zone.dart';
import '../../../core/widgets/ml_button.dart';
import '../../../core/widgets/ml_controls.dart';
import '../../../core/widgets/ml_overlays.dart';
import '../../../l10n/formatting.dart';
import '../../../l10n/l10n.dart';
import '../../../demo/demo_store.dart';

/// Sheet for choosing the month the analytics breakdown shows: a year row
/// with arrows and a grid of the twelve months. Months after the current one
/// are disabled, and the earliest year is the year of the oldest transaction
/// (or this year when there are none).
Future<void> showMonthPickerSheet(
  BuildContext context,
  WidgetRef ref, {
  required DateTime selected,
  required void Function(int year, int month) onSelected,
}) {
  final now = ReportingTimeZone.bangkok.wallClock(
    ref.read(clockProvider).nowUtc(),
  );
  // The same list the breakdown is computed from.
  final transactions = ref.read(demoStoreProvider).transactions;
  var minYear = now.year;
  for (final t in transactions) {
    final year = ReportingTimeZone.bangkok.wallClock(t.occurredAt).year;
    if (year < minYear) minYear = year;
  }
  return showMlSheet<void>(
    context,
    builder: (sheetContext) => _MonthPickerSheet(
      selected: selected,
      now: now,
      minYear: minYear,
      onSelected: (year, month) {
        Navigator.of(sheetContext).pop();
        onSelected(year, month);
      },
    ),
  );
}

class _MonthPickerSheet extends StatefulWidget {
  const _MonthPickerSheet({
    required this.selected,
    required this.now,
    required this.minYear,
    required this.onSelected,
  });

  final DateTime selected;

  /// Wall-clock "now"; the latest month that can be chosen.
  final DateTime now;
  final int minYear;
  final void Function(int year, int month) onSelected;

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _year = widget.selected.year;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.dateFormat;
    final thai = context.localeTag.startsWith('th');
    final canGoBack = _year > widget.minYear;
    final canGoForward = _year < widget.now.year;
    return MlSheet(
      children: [
        MlSheetHeader(title: l10n.analyticsPickMonthTitle, closable: true),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Opacity(
              opacity: canGoBack ? 1 : .35,
              child: MlIconButton(
                icon: MlIcons.chevronLeft,
                semanticLabel: l10n.analyticsPreviousYear,
                variant: MlIconButtonVariant.soft,
                onPressed: canGoBack ? () => setState(() => _year--) : null,
              ),
            ),
            Semantics(
              liveRegion: true,
              child: Text(
                '${thai ? _year + 543 : _year}',
                style: MlText.h2.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Opacity(
              opacity: canGoForward ? 1 : .35,
              child: MlIconButton(
                icon: MlIcons.chevronRight,
                semanticLabel: l10n.analyticsNextYear,
                variant: MlIconButtonVariant.soft,
                onPressed: canGoForward ? () => setState(() => _year++) : null,
              ),
            ),
          ],
        ),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 3.2,
          children: [
            for (var m = 1; m <= 12; m++)
              _MonthCell(
                label: fmt.monthShort(DateTime.utc(_year, m)),
                selected:
                    _year == widget.selected.year && m == widget.selected.month,
                enabled:
                    (_year * 12 + m) <=
                    (widget.now.year * 12 + widget.now.month),
                onPressed: () => widget.onSelected(_year, m),
              ),
          ],
        ),
      ],
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: enabled ? 1 : .35,
    child: IgnorePointer(
      ignoring: !enabled,
      child: MlChip(label: label, selected: selected, onPressed: onPressed),
    ),
  );
}
