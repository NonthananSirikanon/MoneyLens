import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_preferences.dart';
import '../../../app/router.dart';
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
import '../../../core/widgets/ml_surfaces.dart';
import '../../../demo/demo_models.dart';
import '../../../demo/demo_store.dart';
import '../../../l10n/formatting.dart';
import '../../../l10n/l10n.dart';
import '../../accounts/presentation/account_display.dart';
import '../../categories/domain/category.dart';
import '../../dashboard/application/home_view_providers.dart';
import '../application/entry_form.dart';
import '../domain/transaction_type.dart';
import '../../slip_import/presentation/scan_photo.dart';

/// Add / edit / slip-review form (prototype `is.review`, one screen with
/// three modes).
class EntryScreen extends ConsumerStatefulWidget {
  const EntryScreen({super.key, required this.args});

  final EntryArgs args;

  @override
  ConsumerState<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends ConsumerState<EntryScreen> {
  late final EntryDraft _initial = ref.read(entryFormProvider(widget.args));
  late final _amount = TextEditingController(text: _initial.amountText);
  late final _merchant = TextEditingController(text: _initial.merchant);
  late final _note = TextEditingController(text: _initial.note);

  EntryFormController get _form =>
      ref.read(entryFormProvider(widget.args).notifier);

  @override
  void dispose() {
    _amount.dispose();
    _merchant.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final saved = await _form.save();
    if (saved == null || !mounted) return;
    if (saved.mode == EntryMode.edit) {
      context.pop();
      showMlToast(context.l10n.toastEditSaved);
    } else {
      context.pushReplacement(AppRoutes.saved(saved.transactionId));
    }
  }

  void _discard() {
    _form.discardScan();
    context.pop();
    showMlToast(context.l10n.toastSlipDiscarded);
  }

  Future<void> _pickCategory(EntryDraft d) {
    final l10n = context.l10n;
    final s = ref.read(demoStoreProvider);
    final counts = ref.read(categoryCountsProvider);
    final kind = d.type == TransactionType.income
        ? CategoryKind.income
        : CategoryKind.expense;
    return showMlPickSheet(
      context,
      title: l10n.pickCategory,
      items: [
        for (final c in s.categories.where((c) => c.kind == kind))
          MlPickItem(
            title: c.name,
            subtitle: l10n.transactionCount(counts[c.id] ?? 0),
            icon: MlIconKeys.of(c.iconKey),
            tint: s.categoryStyles[c.id]?.tint ?? MlColors.soft,
            selected: c.id == d.categoryId,
            onSelected: () => _form.setCategory(c.id),
          ),
      ],
    );
  }

  Future<void> _pickAccount(
    String title,
    String selected,
    ValueChanged<String> onPick,
  ) {
    final s = ref.read(demoStoreProvider);
    final hide = ref.read(appPreferencesProvider).hideBalances;
    return showMlPickSheet(
      context,
      title: title,
      items: [
        for (final a in s.accounts)
          MlPickItem(
            title: a.name,
            subtitle:
                '${accountSubtitle(context, a.kind, s.accountDetails[a.id])} · '
                '${hide ? context.l10n.hiddenAmount : context.bahtCompact(s.balanceOf(a.id))}',
            icon: accountIcon(a.kind),
            tint: s.accountDetails[a.id]?.tint ?? MlColors.soft,
            selected: a.id == selected,
            onSelected: () => onPick(a.id),
          ),
      ],
    );
  }

  Future<void> _pickDate(EntryDraft d) {
    final today = ReportingTimeZone.bangkok.wallClock(
      ref.read(clockProvider).nowUtc(),
    );
    final todayDate = DateTime.utc(today.year, today.month, today.day);
    return showMlSheet<void>(
      context,
      builder: (context) => MlSheet(
        children: [
          MlSheetHeader(title: context.l10n.detailDate, closable: true),
          FCalendar.grid(
            control: FGridCalendarControl(
              initial: d.date,
              today: todayDate,
              end: todayDate.add(const Duration(days: 1)),
            ),
            selectionControl: FDateSelectionControl.managedSingle(
              initial: d.date,
              toggleable: false,
              onChange: (date) {
                if (date == null) return;
                _form.setDate(date);
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime(EntryDraft d) {
    var picked = FTime(d.hour, d.minute);
    return showMlSheet<void>(
      context,
      builder: (context) => MlSheet(
        children: [
          MlSheetHeader(title: context.l10n.entryTime, closable: true),
          SizedBox(
            height: 200,
            child: FTimePicker(
              hour24: true,
              control: FTimePickerControl.managed(
                initial: picked,
                onChange: (t) => picked = t,
              ),
            ),
          ),
          MlButton(
            label: context.l10n.actionDone,
            onPressed: () {
              _form.setTime(picked.hour, picked.minute);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final d = ref.watch(entryFormProvider(widget.args));
    final store = ref.watch(demoStoreProvider);
    final hide = ref.watch(
      appPreferencesProvider.select((p) => p.hideBalances),
    );
    final fromSlip = d.mode == EntryMode.scan;
    final slipPath = d.scanId == null
        ? null
        : store.scan(d.scanId!)?.attachmentPath;

    final title = switch (d.mode) {
      EntryMode.scan => l10n.entryTitleReview,
      EntryMode.edit => l10n.entryTitleEdit,
      EntryMode.manual => l10n.entryTitleAdd,
    };
    final saveLabel = fromSlip
        ? l10n.entrySaveReview
        : d.isTransfer
        ? l10n.entrySaveTransfer
        : d.mode == EntryMode.edit
        ? l10n.entrySaveEdit
        : l10n.entrySaveAdd;

    final amountError = d.errors[EntryField.amount];
    final merchantError = d.errors[EntryField.merchant];
    final categoryError = d.errors[EntryField.category];
    final category = store.category(d.categoryId);
    final firstError = d.errors.values.isEmpty ? null : d.errors.values.first;

    return ColoredBox(
      color: MlColors.bgApp,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Transform.translate(
                offset: const Offset(-8, 0),
                child: MlAppBar(
                  title: title,
                  leading: MlAppBarLeading.close,
                  onLeading: () => context.pop(),
                ),
              ),
            ),
            if (fromSlip) ...[
              const SizedBox(height: 4),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FTappable(
                      semanticsLabel: l10n.viewSlip,
                      onPress: () => showSlipViewer(
                        context,
                        photo: (_) => ScanPhoto(
                          attachmentPath: slipPath,
                          radius: MlRadius.md,
                          fit: BoxFit.contain,
                        ),
                      ),
                      child: ScanPhoto(
                        attachmentPath: slipPath,
                        width: 72,
                        height: 94,
                        radius: MlRadius.md,
                        border: true,
                      ),
                    ),
                    const SizedBox(width: MlSpace.sm),
                    Expanded(
                      child: MlBanner(
                        tone: d.highlightCount > 0
                            ? MlBannerTone.warning
                            : MlBannerTone.success,
                        icon: d.highlightCount > 0
                            ? MlIcons.triangleAlert
                            : MlIcons.circleCheck,
                        iconSize: 19,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        title: d.highlightCount > 0
                            ? l10n.reviewHighlightTitle(d.highlightCount)
                            : l10n.reviewAllReadTitle,
                        body: d.highlightCount > 0
                            ? l10n.reviewHighlightBody
                            : l10n.reviewAllReadBody,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            const SizedBox(height: 4),
            MlSegmented<TransactionType>(
              segments: [
                MlSegment(TransactionType.expense, l10n.typeExpense),
                MlSegment(TransactionType.income, l10n.typeIncome),
                MlSegment(TransactionType.transfer, l10n.typeTransfer),
              ],
              selected: d.type,
              onChanged: _form.setType,
            ),
            const SizedBox(height: 14),
            if (!fromSlip) ...[
              _BigAmount(
                controller: _amount,
                onChanged: _form.setAmount,
                error: amountError == null
                    ? null
                    : _errorText(context, amountError),
              ),
              const SizedBox(height: 14),
            ] else ...[
              _statusField(
                context,
                label: l10n.entryAmount,
                status: d.status(ReadingField.amount),
                error: amountError,
                height: 52,
                child: Row(
                  children: [
                    Text(
                      '฿',
                      style: MlText.amtM.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: MlInput(
                        controller: _amount,
                        onChanged: _form.setAmount,
                        placeholder: '0.00',
                        semanticLabel: l10n.entryAmount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: amountInputFormatters,
                        style: MlText.amtM.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MlSpace.sm),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 14,
                  child: _pickerField(
                    context,
                    label: l10n.detailDate,
                    icon: MlIcons.calendar,
                    value: context.dateFormat.dayMonthYear(d.date),
                    status: d.status(ReadingField.date),
                    onPressed: () => _pickDate(d),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 10,
                  child: _pickerField(
                    context,
                    label: l10n.entryTime,
                    icon: MlIcons.clock,
                    value:
                        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}',
                    status: d.status(ReadingField.time),
                    onPressed: () => _pickTime(d),
                  ),
                ),
              ],
            ),
            const SizedBox(height: MlSpace.sm),
            _statusField(
              context,
              label: switch (d.type) {
                TransactionType.transfer => l10n.entryTransferDetail,
                TransactionType.income => l10n.entryPayer,
                TransactionType.expense => l10n.entryMerchant,
              },
              status: d.status(ReadingField.merchant),
              error: merchantError,
              child: MlInput(
                controller: _merchant,
                onChanged: _form.setMerchant,
                semanticLabel: l10n.entryMerchant,
                placeholder: d.isTransfer
                    ? l10n.entryTransferPlaceholder
                    : l10n.entryMerchantPlaceholder,
              ),
            ),
            const SizedBox(height: MlSpace.sm),
            if (!d.isTransfer) ...[
              _statusField(
                context,
                label: l10n.detailCategory,
                status: d.status(ReadingField.category),
                error: categoryError,
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                onPressed: () => _pickCategory(d),
                semanticLabel: l10n.pickCategory,
                child: Row(
                  children: [
                    TintIcon(
                      icon: category == null
                          ? MlIcons.shapes
                          : MlIconKeys.of(category.iconKey),
                      tint:
                          store.categoryStyles[category?.id]?.tint ??
                          MlColors.soft,
                      size: 32,
                      iconSize: 15,
                      radius: 10,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        category?.name ?? l10n.pickCategory,
                        style: MlText.title.copyWith(
                          fontWeight: FontWeight.w400,
                          color: category == null
                              ? MlColors.textTertiary
                              : MlColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(
                      MlIcons.chevronDown,
                      size: 17,
                      color: MlColors.textSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MlSpace.sm),
              MlField(
                label: l10n.detailAccount,
                child: _AccountBox(
                  accountId: d.accountId,
                  height: 52,
                  radius: MlRadius.field,
                  avatar: 32,
                  onPressed: () => _pickAccount(
                    l10n.pickAccount,
                    d.accountId,
                    _form.setAccount,
                  ),
                ),
              ),
            ] else ...[
              MlField(
                label: l10n.detailFrom,
                child: _AccountBox(
                  accountId: d.accountId,
                  showBalance: true,
                  hideBalance: hide,
                  onPressed: () => _pickAccount(
                    l10n.detailFrom,
                    d.accountId,
                    _form.setAccount,
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, 4),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: MlColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: MlColors.border),
                    ),
                    child: const Icon(MlIcons.arrowDown, size: 16),
                  ),
                ),
              ),
              MlField(
                label: l10n.detailTo,
                help: d.sameAccount ? l10n.entrySameAccount : null,
                helpTone: MlHelpTone.error,
                child: _AccountBox(
                  accountId: d.destinationAccountId,
                  showBalance: true,
                  hideBalance: hide,
                  error: d.sameAccount,
                  onPressed: () => _pickAccount(
                    l10n.detailTo,
                    d.destinationAccountId,
                    _form.setDestination,
                  ),
                ),
              ),
              const SizedBox(height: MlSpace.sm),
              MlBanner(
                tone: MlBannerTone.info,
                icon: MlIcons.info,
                iconSize: 17,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                title: l10n.entryTransferNoteTitle,
                body: l10n.entryTransferNoteBody,
              ),
            ],
            const SizedBox(height: MlSpace.sm),
            MlField(
              label: l10n.detailNote,
              child: MlFieldBox(
                child: MlInput(
                  controller: _note,
                  onChanged: _form.setNote,
                  semanticLabel: l10n.detailNote,
                  placeholder: l10n.entryOptional,
                ),
              ),
            ),
            if (firstError != null) ...[
              const SizedBox(height: MlSpace.sm),
              MlHelpLine(
                text: _errorText(context, firstError),
                tone: MlHelpTone.error,
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                if (fromSlip) ...[
                  Expanded(
                    child: MlButton(
                      label: l10n.entryDiscard,
                      variant: MlButtonVariant.secondary,
                      horizontalPadding: MlSpace.sm,
                      onPressed: _discard,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  flex: 2,
                  child: MlButton(
                    label: saveLabel,
                    icon: MlIcons.check,
                    enabled: !d.sameAccount,
                    horizontalPadding: MlSpace.md,
                    onPressed: _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// A field whose look follows its OCR status or validation error.
  Widget _statusField(
    BuildContext context, {
    required String label,
    required EntryFieldStatus status,
    required EntryError? error,
    required Widget child,
    double height = 48,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 14),
    VoidCallback? onPressed,
    String? semanticLabel,
  }) {
    final l10n = context.l10n;
    final (state, help, tone) = error != null
        ? (MlFieldState.error, _errorText(context, error), MlHelpTone.error)
        : switch (status) {
            EntryFieldStatus.verified => (
              MlFieldState.normal,
              l10n.fieldVerified,
              MlHelpTone.verified,
            ),
            EntryFieldStatus.uncertain => (
              MlFieldState.uncertain,
              l10n.fieldUncertain,
              MlHelpTone.uncertain,
            ),
            EntryFieldStatus.missing => (
              MlFieldState.missing,
              l10n.fieldMissing,
              MlHelpTone.error,
            ),
            EntryFieldStatus.plain => (
              MlFieldState.normal,
              null,
              MlHelpTone.neutral,
            ),
          };
    return MlField(
      label: label,
      help: help,
      helpTone: tone,
      child: MlFieldBox(
        state: state,
        height: height,
        padding: padding,
        onPressed: onPressed,
        semanticLabel: semanticLabel,
        child: child,
      ),
    );
  }

  Widget _pickerField(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String value,
    required EntryFieldStatus status,
    required VoidCallback onPressed,
  }) => MlField(
    label: label,
    child: MlFieldBox(
      state: status == EntryFieldStatus.uncertain
          ? MlFieldState.uncertain
          : MlFieldState.normal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      onPressed: onPressed,
      semanticLabel: '$label $value',
      child: Row(
        children: [
          Icon(icon, size: 16, color: MlColors.textSecondary),
          const SizedBox(width: MlSpace.xs),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MlText.small,
            ),
          ),
        ],
      ),
    ),
  );

  static String _errorText(BuildContext context, EntryError e) {
    final l10n = context.l10n;
    return switch (e) {
      EntryError.amountFormat => l10n.errorAmountFormat,
      EntryError.amountRequired => l10n.errorAmountRequired,
      EntryError.categoryRequired => l10n.fieldMissing,
      EntryError.merchantRequired => l10n.errorMerchantRequired,
      EntryError.transferDetailRequired => l10n.errorTransferDetailRequired,
    };
  }
}

/// The 44px centred amount input used for manual entry.
class _BigAmount extends StatelessWidget {
  const _BigAmount({
    required this.controller,
    required this.onChanged,
    this.error,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Column(
      children: [
        Text(
          context.l10n.entryAmount,
          style: MlText.meta.copyWith(
            fontWeight: FontWeight.w400,
            color: MlColors.textSecondary,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '฿',
              style: MlText.amtL.copyWith(
                fontWeight: FontWeight.w700,
                color: MlColors.textTertiary,
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 220,
              child: MlInput(
                controller: controller,
                onChanged: onChanged,
                placeholder: '0.00',
                textAlign: TextAlign.center,
                semanticLabel: context.l10n.entryAmount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: amountInputFormatters,
                style: MlText.amtInput,
              ),
            ),
          ],
        ),
        if (error != null)
          Text(
            error!,
            style: MlText.caption.copyWith(color: MlColors.amountExpense),
          ),
      ],
    ),
  );
}

/// Account selector box (category-form 52px or transfer 56px variant).
class _AccountBox extends ConsumerWidget {
  const _AccountBox({
    required this.accountId,
    required this.onPressed,
    this.height = 56,
    this.radius = MlRadius.lg,
    this.avatar = 34,
    this.showBalance = false,
    this.hideBalance = false,
    this.error = false,
  });

  final String accountId;
  final VoidCallback onPressed;
  final double height;
  final double radius;
  final double avatar;
  final bool showBalance;
  final bool hideBalance;
  final bool error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(demoStoreProvider);
    final account = s.account(accountId);
    final details = s.accountDetails[accountId];
    final name = details?.shortName ?? account?.name ?? '';
    return MlFieldBox(
      state: error ? MlFieldState.error : MlFieldState.normal,
      height: height,
      radius: radius,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      onPressed: onPressed,
      semanticLabel: name,
      child: Row(
        children: [
          TintIcon(
            icon: account == null ? MlIcons.wallet : accountIcon(account.kind),
            tint: details?.tint ?? MlColors.soft,
            size: avatar,
            iconSize: avatar < 34 ? 15 : 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: name,
                children: [
                  if ((details?.mask ?? '').isNotEmpty)
                    TextSpan(
                      text: ' ${details!.mask}',
                      style: const TextStyle(color: MlColors.textSecondary),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MlText.title.copyWith(fontWeight: FontWeight.w400),
            ),
          ),
          if (showBalance)
            Text(
              hideBalance
                  ? context.l10n.hiddenAmount
                  : context.bahtCompact(s.balanceOf(accountId)),
              style: MlText.meta.copyWith(
                fontWeight: FontWeight.w400,
                color: MlColors.textSecondary,
              ),
            )
          else
            const Icon(
              MlIcons.chevronDown,
              size: 17,
              color: MlColors.textSecondary,
            ),
        ],
      ),
    );
  }
}
