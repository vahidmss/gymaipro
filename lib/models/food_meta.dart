import 'package:flutter/material.dart';
import 'package:gymaipro/models/food_serving_units.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Rich metadata for foods (WordPress meta fields).
class FoodMeta {
  const FoodMeta({
    this.nameApp = '',
    this.otherNames = const [],
    this.foodGroup = '',
    this.foodType = '',
    this.mealTimes = const [],
    this.shortDescription = '',
    this.servingNotes = '',
    this.nutritionBasis = 'per_100g',
    this.servingSizeGrams = '100',
    this.defaultServingUnit = 'gram',
    this.servingUnits = const FoodServingUnits(
      defaultUnitKey: 'gram',
      units: [],
    ),
    this.allergens = '',
    this.glycemicIndex = '',
    this.tips = const [],
  });

  factory FoodMeta.empty() => const FoodMeta();

  factory FoodMeta.fromJson(Map<String, dynamic> json) {
    final defaultUnit = _str(json['default_serving_unit']).isEmpty
        ? 'gram'
        : _str(json['default_serving_unit']);
    final servingSize = _str(json['serving_size_grams']).isEmpty
        ? '100'
        : _str(json['serving_size_grams']);

    return FoodMeta(
      nameApp: _str(json['name_app']),
      otherNames: _splitCsv(_str(json['other_names'])),
      foodGroup: _str(json['food_group']),
      foodType: _str(json['food_type']),
      mealTimes: _splitCsv(_str(json['meal_times'])),
      shortDescription: _str(json['short_description']),
      servingNotes: _str(json['serving_notes']),
      nutritionBasis: _str(json['nutrition_basis']).isEmpty
          ? 'per_100g'
          : _str(json['nutrition_basis']),
      servingSizeGrams: servingSize,
      defaultServingUnit: defaultUnit,
      servingUnits: FoodServingUnits.parse(
        json['serving_units_json'] ?? json['serving_units'],
        defaultUnitKey: defaultUnit,
        servingSizeGrams: servingSize,
      ),
      allergens: _str(json['allergens']),
      glycemicIndex: _str(json['glycemic_index']),
      tips: [
        _str(json['tip_1']),
        _str(json['tip_2']),
        _str(json['tip_3']),
      ].where((t) => t.isNotEmpty).toList(),
    );
  }

  factory FoodMeta.fromStoredJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return FoodMeta.empty();
    return FoodMeta.fromJson(json);
  }

  final String nameApp;
  final List<String> otherNames;
  final String foodGroup;
  final String foodType;
  final List<String> mealTimes;
  final String shortDescription;
  final String servingNotes;
  final String nutritionBasis;
  final String servingSizeGrams;
  final String defaultServingUnit;
  final FoodServingUnits servingUnits;
  final String allergens;
  final String glycemicIndex;
  final List<String> tips;

  String get nutritionBasisLabel {
    switch (nutritionBasis) {
      case 'per_serving':
        final grams = servingSizeGrams.trim();
        return grams.isNotEmpty ? 'هر $grams گرم' : 'هر وعده';
      case 'per_100g':
      default:
        return 'هر ۱۰۰ گرم';
    }
  }

  bool get hasTips => tips.isNotEmpty;

  bool get hasAllergens => allergens.trim().isNotEmpty;

  double? get glycemicIndexValue {
    final v = double.tryParse(glycemicIndex.trim().replaceAll(',', '.'));
    if (v == null || v <= 0) return null;
    return v;
  }

  bool matchesSearch(String query) {
    final q = query.toLowerCase();
    if (nameApp.toLowerCase().contains(q)) return true;
    if (foodGroup.toLowerCase().contains(q)) return true;
    if (shortDescription.toLowerCase().contains(q)) return true;
    for (final name in otherNames) {
      if (name.toLowerCase().contains(q)) return true;
    }
    for (final meal in mealTimes) {
      if (meal.toLowerCase().contains(q)) return true;
    }
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'name_app': nameApp,
      'other_names': otherNames.join(','),
      'food_group': foodGroup,
      'food_type': foodType,
      'meal_times': mealTimes.join(','),
      'short_description': shortDescription,
      'serving_notes': servingNotes,
      'nutrition_basis': nutritionBasis,
      'serving_size_grams': servingSizeGrams,
      'default_serving_unit': defaultServingUnit,
      'serving_units': servingUnits.toJson(),
      'allergens': allergens,
      'glycemic_index': glycemicIndex,
      'tip_1': tips.isNotEmpty ? tips[0] : '',
      'tip_2': tips.length > 1 ? tips[1] : '',
      'tip_3': tips.length > 2 ? tips[2] : '',
    };
  }

  static String _str(dynamic value) {
    if (value == null) return '';
    if (value is List) {
      return value.map((e) => e.toString()).join(', ');
    }
    return value.toString().trim();
  }

  static List<String> _splitCsv(String raw) {
    if (raw.isEmpty) return const [];
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}

/// Persian labels and colors for food metadata in UI.
class FoodDisplayLabels {
  FoodDisplayLabels._();

  static const Map<String, String> foodType = {
    'solid': 'جامد',
    'liquid': 'مایع',
    'powder': 'پودری',
    'supplement': 'مکمل',
  };

  static const Map<String, Color> groupColors = {
    'پروتئین': Color(0xFF2E7D32),
    'کربوهیدرات': Color(0xFF1565C0),
    'چربی': Color(0xFFEF6C00),
    'لبنیات': Color(0xFF5C6BC0),
    'سبزیجات': Color(0xFF43A047),
    'میوه': Color(0xFFE91E63),
    'حبوبات': Color(0xFF795548),
    'مکمل': Color(0xFF7B1FA2),
    'نوشیدنی': Color(0xFF00838F),
    'سایر': Color(0xFF757575),
  };

  static String foodTypeLabel(String type) =>
      foodType[type.trim()] ?? type.trim();

  static Color groupColor(String group) =>
      groupColors[group.trim()] ?? const Color(0xFFD4AF37);

  static IconData groupIcon(String group) {
    switch (group.trim()) {
      case 'پروتئین':
        return LucideIcons.beef;
      case 'کربوهیدرات':
        return LucideIcons.wheat;
      case 'چربی':
        return LucideIcons.droplet;
      case 'لبنیات':
        return LucideIcons.milk;
      case 'سبزیجات':
        return LucideIcons.leaf;
      case 'میوه':
        return LucideIcons.apple;
      case 'حبوبات':
        return LucideIcons.bean;
      case 'مکمل':
        return LucideIcons.pill;
      case 'نوشیدنی':
        return LucideIcons.cupSoda;
      default:
        return LucideIcons.utensils;
    }
  }

  static String glycemicLabel(double gi) {
    if (gi <= 55) return 'GI پایین';
    if (gi <= 69) return 'GI متوسط';
    return 'GI بالا';
  }

  static Color glycemicColor(double gi) {
    if (gi <= 55) return const Color(0xFF2E7D32);
    if (gi <= 69) return const Color(0xFFEF6C00);
    return const Color(0xFFC62828);
  }
}
