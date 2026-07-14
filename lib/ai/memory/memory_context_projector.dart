import 'package:gymaipro/ai/memory/coach_memory.dart';

/// Projects stored coach memories into CoachContext field buckets.
///
/// This does not extract information from user text. It only turns stable
/// memory keys into context fields after memory has already been written.
class MemoryContextProjection {
  const MemoryContextProjection({
    this.profile = const <String, Object?>{},
    this.goals = const <String>[],
    this.restrictions = const <String>[],
    this.equipment = const <String>[],
    this.preferences = const <String, Object?>{},
  });

  final Map<String, Object?> profile;
  final List<String> goals;
  final List<String> restrictions;
  final List<String> equipment;
  final Map<String, Object?> preferences;
}

class MemoryContextProjector {
  const MemoryContextProjector();

  MemoryContextProjection project(List<CoachMemory> memories) {
    final profile = <String, Object?>{};
    final goals = <String>[];
    final restrictions = <String>[];
    final equipment = <String>[];
    final preferences = <String, Object?>{};

    for (final memory in memories) {
      if (memory.isExpired()) continue;

      switch (memory.key) {
        case 'profile.height':
          profile['height'] = _numericOrText(memory.value);
        case 'profile.weight':
          profile['weight'] = _numericOrText(memory.value);
        case 'profile.age':
          profile['age'] = _numericOrText(memory.value);
        case 'profile.gender':
          profile['gender'] = memory.value;
        case 'profile.experience':
          profile['experience_level'] = memory.value;
        case 'goals.primary':
          goals.add(memory.value);
        case 'equipment.available':
          equipment.add(memory.value);
        case 'restrictions.injury':
          restrictions.add(memory.value);
        case 'medical.condition':
          restrictions.add(memory.value);
        default:
          if (memory.key.startsWith('preferences.')) {
            preferences[memory.key.substring('preferences.'.length)] =
                memory.value;
          }
      }
    }

    return MemoryContextProjection(
      profile: Map<String, Object?>.unmodifiable(profile),
      goals: List<String>.unmodifiable(_uniqueStrings(goals)),
      restrictions: List<String>.unmodifiable(_uniqueStrings(restrictions)),
      equipment: List<String>.unmodifiable(_uniqueStrings(equipment)),
      preferences: Map<String, Object?>.unmodifiable(preferences),
    );
  }

  Object _numericOrText(String value) {
    final parsed = double.tryParse(value);
    if (parsed == null) return value;
    if (parsed == parsed.roundToDouble()) return parsed.toInt();
    return parsed;
  }

  List<String> _uniqueStrings(List<String> values) {
    final seen = <String>{};
    final unique = <String>[];
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) continue;
      if (seen.add(trimmed)) unique.add(trimmed);
    }
    return unique;
  }
}
