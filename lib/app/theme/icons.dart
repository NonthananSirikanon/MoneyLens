import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Lucide icons used by the design, re-exported under one name so widgets
/// don't depend on the icon package directly.
typedef MlIcons = FLucideIcons;

/// Maps a stored category/account `iconKey` to an icon. Keys are the
/// prototype's lucide names (`coffee`, `bus`, …); the Drift seed's semantic
/// keys (`food`, `transport`, …) are accepted too.
abstract final class MlIconKeys {
  static const _byKey = <String, IconData>{
    'coffee': FLucideIcons.coffee,
    'shopping-bag': FLucideIcons.shoppingBag,
    'bus': FLucideIcons.bus,
    'clapperboard': FLucideIcons.clapperboard,
    'zap': FLucideIcons.zap,
    'ellipsis': FLucideIcons.ellipsis,
    'banknote': FLucideIcons.banknote,
    'laptop': FLucideIcons.laptop,
    'gift': FLucideIcons.gift,
    'circle-plus': FLucideIcons.circlePlus,
    'paw-print': FLucideIcons.pawPrint,
    'heart': FLucideIcons.heart,
    'book-open': FLucideIcons.bookOpen,
    'dumbbell': FLucideIcons.dumbbell,
    'plane': FLucideIcons.plane,
    'baby': FLucideIcons.baby,
    'landmark': FLucideIcons.landmark,
    'smartphone': FLucideIcons.smartphone,
    'wallet': FLucideIcons.wallet,
    'layers': FLucideIcons.layers,
    // Drift seed keys (infrastructure/database/seed/default_categories.dart).
    'food': FLucideIcons.coffee,
    'transport': FLucideIcons.bus,
    'shopping': FLucideIcons.shoppingBag,
    'bills': FLucideIcons.zap,
    'housing': FLucideIcons.house,
    'health': FLucideIcons.heartPulse,
    'entertainment': FLucideIcons.clapperboard,
    'salary': FLucideIcons.banknote,
    'other': FLucideIcons.ellipsis,
  };

  static IconData of(String? key) => _byKey[key] ?? FLucideIcons.shapes;

  /// Icon choices offered by the "new category" sheet (prototype NC_ICONS).
  static const newCategoryChoices = [
    'paw-print',
    'heart',
    'book-open',
    'dumbbell',
    'plane',
    'baby',
  ];
}
