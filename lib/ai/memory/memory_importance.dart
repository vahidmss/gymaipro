/// Importance level used for merge and retention decisions.
enum MemoryImportance { low, medium, high, critical }

/// Ordering helpers for memory importance.
extension MemoryImportanceRank on MemoryImportance {
  /// Numeric rank for comparisons.
  int get rank {
    switch (this) {
      case MemoryImportance.low:
        return 1;
      case MemoryImportance.medium:
        return 2;
      case MemoryImportance.high:
        return 3;
      case MemoryImportance.critical:
        return 4;
    }
  }
}
