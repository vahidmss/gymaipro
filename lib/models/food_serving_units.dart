import 'dart:convert';

/// One selectable serving unit for a food (from WordPress `serving_units_json`).
class FoodServingUnit {
  const FoodServingUnit({
    required this.key,
    required this.label,
    required this.gramsPerUnit,
    this.step = 1,
    this.decimals = 0,
    this.isPrimary = false,
    this.hint = '',
  });

  factory FoodServingUnit.fromJson(Map<String, dynamic> json) {
    return FoodServingUnit(
      key: json['key']?.toString() ?? 'gram',
      label: json['label']?.toString() ?? 'گرم',
      gramsPerUnit: _toDouble(json['grams'], fallback: 1),
      step: _toDouble(json['step'], fallback: 1),
      decimals: (json['decimals'] as num?)?.toInt() ?? 0,
      isPrimary: json['is_primary'] == true,
      hint: json['hint']?.toString() ?? '',
    );
  }

  final String key;
  final String label;
  final double gramsPerUnit;
  final double step;
  final int decimals;
  final bool isPrimary;
  final String hint;

  /// Shorter label for UI chips; canonical [label] is still stored in logs.
  String get displayLabel {
    switch (key) {
      case 'palm_carb':
      case 'palm_protein':
      case 'palm_fat':
        return 'کف دست';
      case 'thumb_fat':
        return 'انگشت شست';
      case 'fist':
        return 'مشت';
      default:
        return label;
    }
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'grams': gramsPerUnit,
        'step': step,
        'decimals': decimals,
        'is_primary': isPrimary,
        'hint': hint,
      };

  static double _toDouble(dynamic value, {required double fallback}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ??
        fallback;
  }
}

/// Parsed `serving_units` config for a food item.
class FoodServingUnits {
  const FoodServingUnits({
    required this.defaultUnitKey,
    required this.units,
  });

  factory FoodServingUnits.fromJson(Map<String, dynamic> json) {
    final unitsRaw = json['units'];
    final units = <FoodServingUnit>[];
    if (unitsRaw is List) {
      for (final item in unitsRaw) {
        if (item is Map) {
          units.add(
            FoodServingUnit.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return FoodServingUnits(
      defaultUnitKey: json['default_unit']?.toString() ?? 'gram',
      units: units,
    );
  }

  static const Map<String, String> _presetLabels = {
    'gram': 'گرم',
    'piece': 'عدد',
    'tablespoon': 'قاشق غذاخوری',
    'teaspoon': 'قاشق چای‌خوری',
    'cup': 'پیمانه / لیوان',
    'palm_carb': 'کف دست (کربو)',
    'palm_protein': 'کف دست (پروتئین)',
    'palm_fat': 'کف دست (چربی)',
    'scoop': 'اسکوپ',
    'ml': 'میلی‌لیتر',
  };

  static const Map<String, double> _presetGrams = {
    'tablespoon': 15,
    'teaspoon': 5,
    'cup': 150,
    'palm_carb': 20,
    'palm_protein': 85,
    'palm_fat': 15,
    'scoop': 30,
    'ml': 1,
  };

  final String defaultUnitKey;
  final List<FoodServingUnit> units;

  static FoodServingUnits parse(
    dynamic raw, {
    required String defaultUnitKey,
    required String servingSizeGrams,
  }) {
    FoodServingUnits? parsed;
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          parsed = FoodServingUnits.fromJson(decoded);
        } else if (decoded is Map) {
          parsed = FoodServingUnits.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      } catch (_) {}
    } else if (raw is Map<String, dynamic>) {
      parsed = FoodServingUnits.fromJson(raw);
    } else if (raw is Map) {
      parsed = FoodServingUnits.fromJson(Map<String, dynamic>.from(raw));
    }

    if (parsed != null && parsed.units.isNotEmpty) {
      return parsed.withDefaultKey(defaultUnitKey);
    }

    return FoodServingUnits.fallback(
      defaultUnitKey: defaultUnitKey,
      servingSizeGrams: servingSizeGrams,
    );
  }

  static FoodServingUnits fallback({
    required String defaultUnitKey,
    required String servingSizeGrams,
  }) {
    final servingG = double.tryParse(servingSizeGrams.replaceAll(',', '.')) ??
        100;
    final key = defaultUnitKey.isEmpty ? 'gram' : defaultUnitKey;
    final units = <FoodServingUnit>[];

    void addUnit({
      required String unitKey,
      required String label,
      required double grams,
      required bool primary,
    }) {
      if (units.any((u) => u.key == unitKey)) return;
      units.add(
        FoodServingUnit(
          key: unitKey,
          label: label,
          gramsPerUnit: grams,
          step: unitKey == 'gram' ? 1 : 0.5,
          decimals: unitKey == 'gram' ? 0 : 1,
          isPrimary: primary,
        ),
      );
    }

    if (key != 'gram') {
      final label = _presetLabels[key] ?? key;
      final grams = key == 'piece'
          ? servingG
          : (_presetGrams[key] ?? servingG);
      addUnit(unitKey: key, label: label, grams: grams, primary: true);
    }

    addUnit(
      unitKey: 'gram',
      label: 'گرم',
      grams: 1,
      primary: key == 'gram',
    );

    if (key != 'piece' && !units.any((u) => u.key == 'piece')) {
      addUnit(
        unitKey: 'piece',
        label: 'عدد',
        grams: servingG,
        primary: false,
      );
    }

    return FoodServingUnits(defaultUnitKey: key, units: units);
  }

  FoodServingUnits withDefaultKey(String key) {
    if (key.isEmpty || key == defaultUnitKey) return this;
    return FoodServingUnits(defaultUnitKey: key, units: units);
  }

  FoodServingUnit? resolve(String unitOrKey) {
    final q = unitOrKey.trim();
    if (q.isEmpty) return null;
    for (final u in units) {
      if (u.key == q || u.label == q) return u;
    }
    if (q == 'گرم' || q == 'gram') {
      return units.where((u) => u.key == 'gram').firstOrNull;
    }
    if (q == 'عدد' || q == 'piece') {
      return units
          .where((u) => u.key == 'piece' || u.label.contains('عدد'))
          .firstOrNull;
    }
    return null;
  }

  FoodServingUnit get defaultUnit {
    return resolve(defaultUnitKey) ??
        units.where((u) => u.isPrimary).firstOrNull ??
        units.firstOrNull ??
        const FoodServingUnit(
          key: 'gram',
          label: 'گرم',
          gramsPerUnit: 1,
          isPrimary: true,
        );
  }

  String get defaultUnitLabel => defaultUnit.label;

  String displayLabelFor(String unitOrKey) =>
      resolve(unitOrKey)?.displayLabel ?? unitOrKey;

  List<String> get unitLabels =>
      units.map((u) => u.label).toList(growable: false);

  Map<String, dynamic> toJson() => {
        'default_unit': defaultUnitKey,
        'units': units.map((u) => u.toJson()).toList(),
      };
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
