import 'package:gymaipro/ai/entity/entity_match.dart';
import 'package:gymaipro/ai/entity/entity_type.dart';

/// Normalizes user text and extracted entity values.
class EntityNormalizer {
  const EntityNormalizer();

  /// Normalizes message text before matching.
  String normalizeMessage(String message) {
    final digitsNormalized = _normalizeDigits(message);
    return digitsNormalized.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  static const String _persianDigits = '۰۱۲۳۴۵۶۷۸۹';
  static const String _arabicDigits = '٠١٢٣٤٥٦٧٨٩';

  String _normalizeDigits(String message) {
    final buffer = StringBuffer();
    for (final codeUnit in message.runes) {
      final char = String.fromCharCode(codeUnit);
      final persianIndex = _persianDigits.indexOf(char);
      if (persianIndex >= 0) {
        buffer.write(persianIndex);
        continue;
      }
      final arabicIndex = _arabicDigits.indexOf(char);
      if (arabicIndex >= 0) {
        buffer.write(arabicIndex);
        continue;
      }
      buffer.write(char);
    }
    return buffer.toString();
  }

  /// Converts raw match data into canonical value/unit.
  NormalizedEntity normalizeMatch({
    required EntityMatch match,
    required double confidence,
    List<EntityAlternative> alternatives = const <EntityAlternative>[],
  }) {
    final normalized = _normalizeValue(match);
    return NormalizedEntity(
      type: match.type,
      value: normalized.value,
      unit: normalized.unit,
      confidence: confidence,
      source: match,
      alternatives: alternatives,
    );
  }

  _NormalizedValue _normalizeValue(EntityMatch match) {
    switch (match.type) {
      case EntityType.height:
        return _normalizeHeight(match.rawValue, match.rawUnit);
      case EntityType.weight:
        return _normalizeNumber(match.rawValue, 'kg');
      case EntityType.age:
        return _normalizeNumber(match.rawValue, null);
      case EntityType.sleepDuration:
        return _normalizeNumber(match.rawValue, 'hour');
      case EntityType.waterIntake:
        return _normalizeWater(match.rawValue, match.rawUnit);
      case EntityType.gender:
      case EntityType.goal:
      case EntityType.equipment:
      case EntityType.experience:
      case EntityType.injury:
      case EntityType.medicalCondition:
      case EntityType.muscleGroup:
      case EntityType.exerciseName:
      case EntityType.workoutDay:
      case EntityType.timeExpression:
      case EntityType.supplement:
      case EntityType.food:
        return _NormalizedValue(match.rawValue, null);
    }
  }

  _NormalizedValue _normalizeHeight(String rawValue, String? rawUnit) {
    final value = _parseNumber(rawValue);
    final unit = _normalizeUnit(rawUnit);
    if (value == null) return _NormalizedValue(rawValue, unit ?? 'cm');
    if (unit == 'm') return _NormalizedValue(value * 100, 'cm');
    return _NormalizedValue(value, 'cm');
  }

  _NormalizedValue _normalizeWater(String rawValue, String? rawUnit) {
    final value = _parseNumber(rawValue);
    final unit = _normalizeUnit(rawUnit);
    if (value == null) return _NormalizedValue(rawValue, unit ?? 'liter');
    if (unit == 'ml') return _NormalizedValue(value / 1000, 'liter');
    return _NormalizedValue(value, 'liter');
  }

  _NormalizedValue _normalizeNumber(String rawValue, String? unit) {
    final value = _parseNumber(rawValue);
    return _NormalizedValue(value ?? rawValue, unit);
  }

  double? _parseNumber(String value) {
    return double.tryParse(value.replaceAll(',', '.'));
  }

  String? _normalizeUnit(String? rawUnit) {
    if (rawUnit == null || rawUnit.trim().isEmpty) return null;
    final unit = rawUnit.trim().toLowerCase();
    if (unit == 'سانت' || unit == 'سانتی') return 'cm';
    if (unit == 'متر') return 'm';
    if (unit == 'کیلو' || unit == 'کیلوگرم') return 'kg';
    if (unit == 'ساعت' || unit == 'hours' || unit == 'h') return 'hour';
    if (unit == 'لیتر' || unit == 'l') return 'liter';
    if (unit == 'میلی لیتر') return 'ml';
    return unit;
  }
}

class _NormalizedValue {
  const _NormalizedValue(this.value, this.unit);

  final Object value;
  final String? unit;
}
