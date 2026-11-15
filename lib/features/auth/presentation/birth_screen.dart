import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/icons.dart';
import '../../../app/theme/text_styles.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/dates/clock.dart';
import '../../../core/dates/reporting_time_zone.dart';
import '../../../core/widgets/ml_badges.dart';
import '../../../core/widgets/ml_button.dart';
import '../../../core/widgets/ml_controls.dart';
import '../../../core/widgets/ml_fields.dart';
import '../../../core/widgets/ml_overlays.dart';
import '../../../l10n/l10n.dart';
import '../application/birth_date.dart';
import '../application/session.dart';
import '../domain/auth_models.dart';
import 'auth_widgets.dart';
import 'birth_picker_sheet.dart';

/// "วันเกิดของคุณ": day, month and Buddhist-era year, all chosen from one
/// wheel sheet (no keyboard). With [edit] it changes the saved date instead
/// of finishing sign-up.
class BirthScreen extends ConsumerStatefulWidget {
  const BirthScreen({super.key, this.edit = false});

  final bool edit;

  @override
  ConsumerState<BirthScreen> createState() => _BirthScreenState();
}

class _BirthScreenState extends ConsumerState<BirthScreen> {
  int? _day;
  int? _month; // 1-12
  int? _year; // Buddhist era
  var _showError = false;
  var _saving = false;
  AuthFailureKind? _saveFailure;

  @override
  void initState() {
    super.initState();
    final saved = widget.edit ? ref.read(sessionProvider).birthDate : null;
    if (saved != null) {
      _day = saved.day;
      _month = saved.month;
      _year = saved.year + 543;
    }
  }

  DateTime get _today =>
      ReportingTimeZone.bangkok.wallClock(ref.read(clockProvider).nowUtc());

  BirthDateResult get _result => BirthDateValidator.validate(
    day: _day?.toString() ?? '',
    month: _month,
    yearBuddhist: _year?.toString() ?? '',
    today: _today,
  );

  String _monthName(BuildContext context, int month) =>
      DateFormat.MMM(context.localeTag).format(DateTime(2000, month));

  String _errorText(BuildContext context, BirthDateResult r) {
    final l10n = context.l10n;
    return switch (r.error!) {
      BirthDateError.incomplete => l10n.authBirthIncomplete,
      BirthDateError.yearFormat => l10n.authBirthYearFormat,
      BirthDateError.future => l10n.authBirthFuture,
      BirthDateError.noSuchDate => l10n.authBirthNoSuch(
        _day ?? 0,
        _monthName(context, _month ?? 1),
        '${_year ?? ''}',
      ),
    };
  }

  Future<void> _pickDate() async {
    final picked = await showBirthPickerSheet(
      context,
      currentYearBuddhist: _today.year + 543,
      initial: _day != null && _month != null && _year != null
          ? (day: _day!, month: _month!, year: _year!)
          : null,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _day = picked.day;
      _month = picked.month;
      _year = picked.year;
      _showError = false;
    });
  }

  /// One of the three tappable boxes; each opens the same wheel sheet.
  Widget _pickerBox({
    required String label,
    required String? value,
    required String placeholder,
    required bool bad,
  }) => MlField(
    label: label,
    child: MlFieldBox(
      height: 52,
      state: bad ? MlFieldState.error : MlFieldState.normal,
      padding: const EdgeInsets.only(left: 14, right: 10),
      onPressed: _pickDate,
      semanticLabel: '$label ${value ?? placeholder}',
      child: Row(
        children: [
          Expanded(
            child: Text(
              value ?? placeholder,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MlText.body.copyWith(
                color: value == null
                    ? MlColors.textTertiary
                    : MlColors.textPrimary,
              ),
            ),
          ),
          const Icon(
            MlIcons.chevronDown,
            size: 18,
            color: MlColors.textTertiary,
          ),
        ],
      ),
    ),
  );

  Future<void> _save() async {
    final r = _result;
    if (!r.isValid) {
      setState(() => _showError = true);
      return;
    }
    setState(() {
      _saving = true;
      _saveFailure = null;
    });
    try {
      await ref.read(sessionProvider.notifier).saveBirthDate(r.date!);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _saveFailure = e.kind);
      if (mounted) setState(() => _saving = false);
      return;
    }
    if (!mounted) return;
    if (widget.edit) {
      context.pop();
      showMlToast(context.l10n.toastBirthSaved);
    }
    // First time: the session becomes ready and the router moves on.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = _result;
    final bad = _showError && !r.isValid ? r : null;

    return AuthPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Transform.translate(
            offset: const Offset(-8, 0),
            child: MlAppBar(
              title: widget.edit
                  ? l10n.authBirthEditTitle
                  : l10n.authBirthTitle,
              // Signing out is the only way back during first-time setup.
              onLeading: widget.edit
                  ? () => context.pop()
                  : () => ref.read(sessionProvider.notifier).signOut(),
            ),
          ),
          const SizedBox(height: 4),
          AuthHeading(
            title: l10n.authBirthHeading,
            body: Text(
              l10n.authBirthBody,
              style: MlText.small.copyWith(color: MlColors.textSecondary),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 92,
                child: _pickerBox(
                  label: l10n.authDay,
                  value: _day?.toString(),
                  placeholder: l10n.authDayHint,
                  bad: bad?.badDay ?? false,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _pickerBox(
                  label: l10n.authMonth,
                  value: _month == null
                      ? null
                      : DateFormat.MMMM(context.localeTag)
                            .format(DateTime(2000, _month!)),
                  placeholder: l10n.authPickMonth,
                  bad: bad?.badMonth ?? false,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 116,
                child: _pickerBox(
                  label: l10n.authYear,
                  value: _year?.toString(),
                  placeholder: l10n.authYearHint,
                  bad: bad?.badYear ?? false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (bad != null)
            AuthError(_errorText(context, bad))
          else if (_saveFailure != null &&
              authFailureMessage(context, _saveFailure!) != null)
            AuthError(l10n.authBirthSaveFailed)
          else if (r.isValid)
            Row(
              children: [
                MlPill(
                  label: l10n.authAge(r.age!),
                  icon: MlIcons.circleCheck,
                  background: MlColors.successSoft,
                  foreground: MlColors.amountIncome,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.authYearNote,
                    style: MlText.caption.copyWith(
                      color: MlColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          const Spacer(),
          MlButton(
            label: widget.edit ? l10n.authSave : l10n.authContinue,
            enabled: !_saving,
            dimmed: !r.isValid,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
