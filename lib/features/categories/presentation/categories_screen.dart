import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/icons.dart';
import '../../../app/theme/text_styles.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ml_badges.dart';
import '../../../core/widgets/ml_button.dart';
import '../../../core/widgets/ml_controls.dart';
import '../../../core/widgets/ml_fields.dart';
import '../../../core/widgets/ml_overlays.dart';
import '../../../core/widgets/ml_surfaces.dart';
import '../../../demo/demo_models.dart';
import '../../../app/app_store.dart';
import '../../../l10n/l10n.dart';
import '../../dashboard/application/home_view_providers.dart';
import '../../transactions/application/transaction_view_providers.dart';
import '../domain/category.dart';

/// Accent colours offered by the "new category" sheet; the icon tint is
/// derived from the chosen one (same rule as every other category).
const _accents = [
  Color(0xFFE09A88),
  Color(0xFF93ABCB),
  Color(0xFFE2BC6E),
  Color(0xFFA8B89A),
  Color(0xFFB9B3CC),
  Color(0xFF4F8A68),
];

final _categoryTabProvider = NotifierProvider<_CategoryTab, CategoryKind>(
  _CategoryTab.new,
);

class _CategoryTab extends Notifier<CategoryKind> {
  @override
  CategoryKind build() => CategoryKind.expense;

  void set(CategoryKind kind) => state = kind;
}

/// "หมวดหมู่": expense/income lists; tapping a category shows its
/// transactions.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final kind = ref.watch(_categoryTabProvider);
    final store = ref.watch(appStoreProvider);
    final counts = ref.watch(categoryCountsProvider);
    final categories = store.categories.where((c) => c.kind == kind).toList();
    return ColoredBox(
      color: MlColors.bgApp,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Transform.translate(
              offset: const Offset(-8, 0),
              child: MlAppBar(
                title: l10n.categoriesTitle,
                onLeading: () => context.pop(),
              ),
            ),
            const SizedBox(height: MlSpace.xs),
            MlSegmented<CategoryKind>(
              segments: [
                MlSegment(CategoryKind.expense, l10n.typeExpense),
                MlSegment(CategoryKind.income, l10n.typeIncome),
              ],
              selected: kind,
              onChanged: ref.read(_categoryTabProvider.notifier).set,
            ),
            const SizedBox(height: MlSpace.md),
            MlListGroup(
              children: [
                for (final c in categories)
                  FTappable(
                    semanticsLabel: c.name,
                    onPress: () {
                      ref
                          .read(transactionFilterProvider.notifier)
                          .showCategory(c);
                      context.go(AppRoutes.transactions);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: MlSpace.sm),
                      child: Row(
                        children: [
                          TintIcon(
                            icon: MlIconKeys.of(c.iconKey),
                            tint:
                                store.categoryStyles[c.id]?.tint ??
                                MlColors.soft,
                            size: 40,
                          ),
                          const SizedBox(width: MlSpace.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  style: MlText.title.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  l10n.transactionCount(counts[c.id] ?? 0),
                                  style: MlText.caption.copyWith(
                                    color: MlColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            MlIcons.chevronRight,
                            size: 17,
                            color: MlColors.textTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: MlSpace.md),
            MlButton(
              label: l10n.addCategory,
              icon: MlIcons.plus,
              variant: MlButtonVariant.outline,
              height: 52,
              onPressed: () => showMlSheet<void>(
                context,
                builder: (_) => _AddCategorySheet(initialKind: kind),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCategorySheet extends ConsumerStatefulWidget {
  const _AddCategorySheet({required this.initialKind});

  final CategoryKind initialKind;

  @override
  ConsumerState<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends ConsumerState<_AddCategorySheet> {
  late var _kind = widget.initialKind;
  final _name = TextEditingController();
  var _icon = 0;
  var _tint = 0;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    await ref
        .read(appStoreProvider.notifier)
        .addCategory(
          name: name,
          kind: _kind,
          iconKey: MlIconKeys.newCategoryChoices[_icon],
          accent: _accents[_tint],
        );
    if (!mounted) return;
    ref.read(_categoryTabProvider.notifier).set(_kind);
    Navigator.of(context).pop();
    showMlToast(context.l10n.toastCategoryAdded(name));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MlSheet(
      gap: 14,
      children: [
        MlSheetHeader(title: l10n.newCategoryTitle),
        MlSegmented<CategoryKind>(
          segments: [
            MlSegment(CategoryKind.expense, l10n.typeExpense),
            MlSegment(CategoryKind.income, l10n.typeIncome),
          ],
          selected: _kind,
          onChanged: (k) => setState(() => _kind = k),
        ),
        MlField(
          label: l10n.categoryNameLabel,
          child: MlFieldBox(
            height: 52,
            focused: true,
            child: MlInput(
              controller: _name,
              placeholder: l10n.categoryNamePlaceholder,
              semanticLabel: l10n.categoryNameLabel,
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        MlField(
          label: l10n.categoryIconLabel,
          child: GridView.count(
            crossAxisCount: 6,
            mainAxisSpacing: MlSpace.xs,
            crossAxisSpacing: MlSpace.xs,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final (i, key) in MlIconKeys.newCategoryChoices.indexed)
                FTappable(
                  semanticsLabel: key,
                  selected: i == _icon,
                  onPress: () => setState(() => _icon = i),
                  child: AnimatedContainer(
                    duration: MlDurations.fast,
                    decoration: BoxDecoration(
                      color: i == _icon ? MlColors.inverse : MlColors.soft,
                      borderRadius: BorderRadius.circular(MlRadius.md),
                    ),
                    child: Icon(
                      MlIconKeys.of(key),
                      size: 19,
                      color: i == _icon
                          ? MlColors.textInverse
                          : MlColors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        MlField(
          label: l10n.categoryColorLabel,
          child: Row(
            children: [
              for (final (i, accent) in _accents.indexed) ...[
                if (i > 0) const SizedBox(width: 10),
                FTappable(
                  semanticsLabel: l10n.categoryColorOption(i + 1),
                  selected: i == _tint,
                  onPress: () => setState(() => _tint = i),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: CategoryStyle.fromAccent(accent).tint,
                      shape: BoxShape.circle,
                      border: i == _tint
                          ? null
                          : Border.all(color: MlColors.border),
                      boxShadow: i == _tint
                          ? const [
                              BoxShadow(
                                color: MlColors.surface,
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: MlColors.inverse,
                                spreadRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        MlButton(
          label: l10n.saveCategory,
          enabled: _name.text.trim().isNotEmpty,
          onPressed: _save,
        ),
      ],
    );
  }
}
