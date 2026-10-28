import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_preferences.dart';
import '../../../app/theme/icons.dart';
import '../../../app/theme/text_styles.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/ml_badges.dart';
import '../../../core/widgets/ml_button.dart';
import '../../../core/widgets/ml_controls.dart';
import '../../../core/widgets/ml_fields.dart';
import '../../../core/widgets/ml_overlays.dart';
import '../../../core/widgets/ml_surfaces.dart';
import '../../../demo/demo_store.dart';
import '../../../l10n/formatting.dart';
import '../../../l10n/l10n.dart';
import '../domain/account.dart';
import 'account_display.dart';

/// "บัญชี": total, banks vs e-wallets/cash, and the add-account sheet.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ref.watch(demoStoreProvider);
    final hide = ref.watch(
      appPreferencesProvider.select((p) => p.hideBalances),
    );
    final groups = [
      (
        l10n.accountsGroupBank,
        s.accounts.where((a) => a.kind == AccountKind.bank).toList(),
      ),
      (
        l10n.accountsGroupOther,
        s.accounts.where((a) => a.kind != AccountKind.bank).toList(),
      ),
    ].where((g) => g.$2.isNotEmpty);

    return ColoredBox(
      color: MlColors.bgApp,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Transform.translate(
              offset: const Offset(-8, 0),
              child: MlAppBar(
                title: l10n.accountsTitle,
                onLeading: () => context.pop(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.accountsTotal,
                    style: MlText.meta.copyWith(
                      fontWeight: FontWeight.w400,
                      color: MlColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hide ? l10n.hiddenBalance : context.baht(s.totalBalance),
                    style: MlText.amtL.copyWith(
                      fontSize: 30,
                      letterSpacing: -.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.accountsCount(s.accounts.length),
                    style: MlText.caption.copyWith(
                      color: MlColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            for (final (title, accounts) in groups) ...[
              MlGroupTitle(title, top: MlSpace.xs),
              MlListGroup(
                children: [
                  for (final a in accounts)
                    FTappable(
                      semanticsLabel: a.name,
                      onPress: () => showMlToast(l10n.toastAccountEdit(a.name)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            TintIcon(
                              icon: accountIcon(a.kind),
                              tint:
                                  s.accountDetails[a.id]?.tint ?? MlColors.soft,
                              size: 44,
                              iconSize: 19,
                            ),
                            const SizedBox(width: MlSpace.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.name, style: MlText.title),
                                  Text(
                                    accountSubtitle(
                                      context,
                                      a.kind,
                                      s.accountDetails[a.id],
                                    ),
                                    style: MlText.caption.copyWith(
                                      color: MlColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              hide
                                  ? l10n.hiddenAmount
                                  : context.baht(s.balanceOf(a.id)),
                              style: MlText.amtM.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: MlSpace.xs),
            ],
            const SizedBox(height: MlSpace.xs),
            MlButton(
              label: l10n.addAccount,
              icon: MlIcons.plus,
              variant: MlButtonVariant.outline,
              height: 52,
              onPressed: () => showMlSheet<void>(
                context,
                builder: (_) => const _AddAccountSheet(),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.accountsMaskNote,
              textAlign: TextAlign.center,
              style: MlText.caption.copyWith(color: MlColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAccountSheet extends ConsumerStatefulWidget {
  const _AddAccountSheet();

  @override
  ConsumerState<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends ConsumerState<_AddAccountSheet> {
  var _kind = AccountKind.bank;
  final _name = TextEditingController();
  final _last4 = TextEditingController();
  final _balance = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _last4.dispose();
    _balance.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final opening = Money.tryParse(_balance.text, Currency.thb)?.minor ?? 0;
    await ref
        .read(demoStoreProvider.notifier)
        .addAccount(
          name: name,
          kind: _kind,
          // Only a complete set of four digits is kept.
          last4: _last4.text.length == 4 ? _last4.text : null,
          openingBalanceMinor: opening,
        );
    if (!mounted) return;
    Navigator.of(context).pop();
    showMlToast(context.l10n.toastAccountAdded(name));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MlSheet(
      gap: 14,
      children: [
        MlSheetHeader(title: l10n.newAccountTitle),
        MlSegmented<AccountKind>(
          segments: [
            MlSegment(AccountKind.bank, l10n.accountKindBank),
            MlSegment(AccountKind.ewallet, l10n.accountKindEwallet),
            MlSegment(AccountKind.cash, l10n.accountKindCash),
          ],
          selected: _kind,
          onChanged: (k) => setState(() => _kind = k),
        ),
        MlField(
          label: l10n.accountNameLabel,
          child: MlFieldBox(
            height: 52,
            focused: true,
            child: MlInput(
              controller: _name,
              placeholder: l10n.accountNamePlaceholder,
              semanticLabel: l10n.accountNameLabel,
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        MlField(
          label: l10n.accountLast4Label,
          help: l10n.accountLast4Hint,
          child: MlFieldBox(
            height: 52,
            child: Row(
              children: [
                Text(
                  '••••',
                  style: MlText.title.copyWith(
                    fontWeight: FontWeight.w400,
                    color: MlColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: MlInput(
                    controller: _last4,
                    placeholder: '3456',
                    semanticLabel: l10n.accountLast4Label,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        MlField(
          label: l10n.accountOpeningLabel,
          child: MlFieldBox(
            height: 52,
            child: Row(
              children: [
                Text('฿', style: MlText.title),
                const SizedBox(width: 6),
                Expanded(
                  child: MlInput(
                    controller: _balance,
                    placeholder: '0.00',
                    semanticLabel: l10n.accountOpeningLabel,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: amountInputFormatters,
                  ),
                ),
              ],
            ),
          ),
        ),
        MlButton(
          label: l10n.saveAccount,
          enabled: _name.text.trim().isNotEmpty,
          onPressed: _save,
        ),
      ],
    );
  }
}
