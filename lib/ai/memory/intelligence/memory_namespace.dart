import 'package:gymaipro/ai/memory/memory_category.dart';

/// Standard namespaces for coach memories.
enum MemoryNamespace {
  profile,
  goals,
  preferences,
  restrictions,
  medical,
  equipment,
  workout,
  nutrition,
  recovery,
  behavior,
  app,
  temporary,
}

/// Namespace helpers for stable memory keys.
extension MemoryNamespaceKeys on MemoryNamespace {
  /// Stable namespace prefix.
  String get prefix {
    switch (this) {
      case MemoryNamespace.profile:
        return 'profile';
      case MemoryNamespace.goals:
        return 'goals';
      case MemoryNamespace.preferences:
        return 'preferences';
      case MemoryNamespace.restrictions:
        return 'restrictions';
      case MemoryNamespace.medical:
        return 'medical';
      case MemoryNamespace.equipment:
        return 'equipment';
      case MemoryNamespace.workout:
        return 'workout';
      case MemoryNamespace.nutrition:
        return 'nutrition';
      case MemoryNamespace.recovery:
        return 'recovery';
      case MemoryNamespace.behavior:
        return 'behavior';
      case MemoryNamespace.app:
        return 'app';
      case MemoryNamespace.temporary:
        return 'temporary';
    }
  }

  /// Builds a stable memory key in this namespace.
  String key(String name) => '$prefix.${_normalizeName(name)}';

  static String _normalizeName(String name) {
    return name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9_]+'), '_')
        .replaceAll(RegExp('_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}

/// Maps memory categories to default namespaces.
class MemoryNamespaceMapper {
  const MemoryNamespaceMapper._();

  /// Returns the default namespace for a memory category.
  static MemoryNamespace forCategory(MemoryCategory category) {
    switch (category) {
      case MemoryCategory.profile:
        return MemoryNamespace.profile;
      case MemoryCategory.goal:
        return MemoryNamespace.goals;
      case MemoryCategory.preference:
        return MemoryNamespace.preferences;
      case MemoryCategory.restriction:
        return MemoryNamespace.restrictions;
      case MemoryCategory.medical:
        return MemoryNamespace.medical;
      case MemoryCategory.equipment:
        return MemoryNamespace.equipment;
      case MemoryCategory.workout:
        return MemoryNamespace.workout;
      case MemoryCategory.nutrition:
        return MemoryNamespace.nutrition;
      case MemoryCategory.recovery:
        return MemoryNamespace.recovery;
      case MemoryCategory.behavior:
        return MemoryNamespace.behavior;
      case MemoryCategory.app:
        return MemoryNamespace.app;
      case MemoryCategory.relationship:
        return MemoryNamespace.profile;
      case MemoryCategory.temporary:
        return MemoryNamespace.temporary;
      case MemoryCategory.other:
        return MemoryNamespace.temporary;
    }
  }
}
