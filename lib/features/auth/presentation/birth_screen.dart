import 'package:flutter/services.dart';
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

/// "วันเกิดของคุณ": day, month (picker) and Buddhist-era year. With
/// [edit] it changes the saved date instead of finishing sign-up.
class BirthScreen extends ConsumerStatefulWidget {
  const BirthScreen({super.key, this.edit = false});

  final bool edit;

  @override
  ConsumerState<BirthScreen> createState() => _BirthScreenState();
}

class _BirthScreenState extends ConsumerState<BirthScreen> {
  final _day = TextEditingController();
  final _year = TextEditingController();
  int? _month; // 1-12
  var _showError = false;
  var _saving = false;
  AuthFailureKind? _saveFailure;

  @override
  void initState() {
    super.initState();
    final saved = widget.edit ? ref.read(sessionProvider).birthDate : null;
    if (saved != null) {
      _day.text = '${saved.day}';
      _month = saved.month;
      _year.text = '${saved.year + 543}';
    }
  }

  @override
  void dispose() {
    _day.dispose();
    _year.dispose();
    super.dispose();
  }

  DateTime get _today =>
      ReportingTimeZone.bangkok.wallClock(ref.read(clockProvider).nowUtc());

  BirthDateResult get _result => BirthDateValidator.validate(
    day: _day.text,
    month: _month,
    yearBuddhist: _year.text,
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
        int.tryParse(_day.text) ?? 0,
        _monthName(context, _month ?? 1),
        _year.text,
      ),
    };
  }

  Future<void> _pickMonth() {
    final l10n = context.l10n;
    return showMlSheet<void>(
      context,
      builder: (sheetContext) => MlSheet(
        children: [
          MlSheetHeader(title: l10n.authPickMonthTitle, closable: true),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.2,
            children: [
              for (var m = 1; m <= 12; m++)
                MlChip(
                  label: _monthName(context, m),
                  selected: m == _month,
                  onPressed: () {
                    setState(() {
                      _month = m;
                      _showError = false;
                    });
                    Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

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
    MlFieldState state(bool flag) =>
        flag ? MlFieldState.error : MlFieldState.normal;

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
                width: 88,
                child: MlField(
                  label: l10n.authDay,
                  child: MlFieldBox(
                    height: 52,
                    state: state(bad?.badDay ?? false),
                    child: MlInput(
                      controller: _day,
                      placeholder: l10n.authDayHint,
                      semanticLabel: l10n.authDay,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      onChanged: (_) => setState(() => _showError = false),
                      style: MlText.body,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MlField(
                  label: l10n.authMonth,
                  child: MlFieldBox(
                    height: 52,
                    state: state(bad?.badMonth ?? false),
                    padding: const EdgeInsets.only(left: 14, right: 12),
                    onPressed: _pickMonth,
                    semanticLabel: l10n.authPickMonth,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _month == null
                                ? l10n.authPickMonth
                                : DateFormat.MMMM(context.localeTag)
                                      .format(DateTime(2000, _month!)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MlText.body.copyWith(
                              color: _month == null
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
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 112,
                child: MlField(
                  label: l10n.authYear,
                  child: MlFieldBox(
                    height: 52,
                    state: state(bad?.badYear ?? false),
                    child: MlInput(
                      controller: _year,
                      placeholder: l10n.authYearHint,
                      semanticLabel: l10n.authYear,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      onChanged: (_) => setState(() => _showError = false),
                      style: MlText.body,
                    ),
                  ),
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
