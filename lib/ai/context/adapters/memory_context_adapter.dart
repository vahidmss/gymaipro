import 'package:gymaipro/ai/memory/coach_memory.dart';
import 'package:gymaipro/ai/memory/memory_repository.dart';

/// Read-only adapter for coach memory used by CoachContext assembly.
class MemoryContextAdapter {
  MemoryContextAdapter({MemoryRepository? memoryRepository})
    : _memoryRepository = memoryRepository ?? MemoryRepository();

  final MemoryRepository _memoryRepository;

  /// Loads non-expired memories for [userId] without writing or pruning.
  Future<List<CoachMemory>> loadActiveMemories(String userId) async {
    final memories = await _memoryRepository.loadMemories(userId);
    return List<CoachMemory>.unmodifiable(
      memories.where((memory) => !memory.isExpired()).toList(growable: false),
    );
  }
}
