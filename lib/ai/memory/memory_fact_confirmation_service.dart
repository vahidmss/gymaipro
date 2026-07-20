import 'package:gymaipro/ai/memory/coach_memory.dart';
import 'package:gymaipro/ai/memory/memory_category.dart';
import 'package:gymaipro/ai/memory/memory_importance.dart';
import 'package:gymaipro/ai/memory/memory_manager.dart';
import 'package:gymaipro/ai/memory/memory_source.dart';
import 'package:gymaipro/ai/memory/memory_updater.dart';
import 'package:gymaipro/services/simple_profile_service.dart';

/// A sensitive memory fact waiting for explicit user confirmation.
class PendingMemoryConfirmation {
  const PendingMemoryConfirmation({
    required this.originalKey,
    required this.value,
    required this.category,
    required this.confidence,
    required this.prompt,
  });

  final String originalKey;
  final String value;
  final MemoryCategory category;
  final double confidence;
  final String prompt;

  String get pendingKey => pendingKeyFor(originalKey);

  static String pendingKeyFor(String originalKey) => 'pending.confirm.$originalKey';

  static String? originalKeyFromPending(String key) {
    const prefix = 'pending.confirm.';
    if (!key.startsWith(prefix)) return null;
    return key.substring(prefix.length);
  }
}

/// Confirms / rejects pending sensitive memories and syncs durable facts to profile.
class MemoryFactConfirmationService {
  MemoryFactConfirmationService({
    MemoryManager? memoryManager,
    MemoryUpdater updater = const MemoryUpdater(),
  }) : _memoryManager = memoryManager ?? MemoryManager(),
       _updater = updater;

  final MemoryManager _memoryManager;
  final MemoryUpdater _updater;

  static const sensitiveCategories = <MemoryCategory>{
    MemoryCategory.medical,
    MemoryCategory.restriction,
  };

  /// True when this category should never auto-persist without confirmation.
  static bool requiresConfirmation(MemoryCategory category) {
    return sensitiveCategories.contains(category);
  }

  Future<List<PendingMemoryConfirmation>> loadPending(String userId) async {
    final memories = await _memoryManager.loadActiveMemories(userId);
    return memories
        .map(_fromMemory)
        .whereType<PendingMemoryConfirmation>()
        .toList(growable: false);
  }

  Future<void> savePending({
    required String userId,
    required List<MemoryUpdateRequest> requests,
  }) async {
    for (final request in requests) {
      await _memoryManager.addOrUpdateMemory(
        userId,
        MemoryUpdateRequest(
          key: PendingMemoryConfirmation.pendingKeyFor(request.key),
          value: request.value,
          category: MemoryCategory.temporary,
          source: request.source,
          confidence: request.confidence,
          importance: MemoryImportance.high,
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
          aiGenerated: true,
        ),
      );
    }
  }

  /// Interprets a short yes/no reply against the newest pending confirmation.
  Future<MemoryConfirmationResolution?> tryResolveFromUserMessage({
    required String userId,
    required String message,
  }) async {
    final pending = await loadPending(userId);
    if (pending.isEmpty) return null;

    final verdict = _parseVerdict(message);
    if (verdict == null) return null;

    final target = pending.last;
    if (verdict) {
      await confirm(userId: userId, pending: target);
      return MemoryConfirmationResolution(
        confirmed: true,
        pending: target,
        reply: 'ثبت شد. از این به بعد توی برنامه و توصیه‌ها لحاظش می‌کنم.',
      );
    }

    await reject(userId: userId, pending: target);
    return MemoryConfirmationResolution(
      confirmed: false,
      pending: target,
      reply: 'باشه، ذخیره‌اش نکردم. هر وقت خواستی دوباره بگو.',
    );
  }

  Future<void> confirm({
    required String userId,
    required PendingMemoryConfirmation pending,
  }) async {
    await _memoryManager.addOrUpdateMemory(
      userId,
      MemoryUpdateRequest(
        key: pending.originalKey,
        value: pending.value,
        category: pending.category,
        source: MemorySource.user,
        confidence: pending.confidence.clamp(0.85, 1.0),
        importance: MemoryImportance.critical,
        aiGenerated: false,
      ),
    );
    await _memoryManager.deleteMemory(userId, pending.pendingKey);
    await _syncToProfile(pending);
  }

  Future<void> reject({
    required String userId,
    required PendingMemoryConfirmation pending,
  }) {
    return _memoryManager.deleteMemory(userId, pending.pendingKey);
  }

  String confirmationPrompt(MemoryUpdateRequest request) {
    final label = _humanLabel(request);
    return 'درست فهمیدم که $label؟ اگه درسته بگو «بله» تا ذخیره کنم.';
  }

  PendingMemoryConfirmation? _fromMemory(CoachMemory memory) {
    final originalKey =
        PendingMemoryConfirmation.originalKeyFromPending(memory.key);
    if (originalKey == null) return null;

    final category = _categoryForKey(originalKey);
    final request = MemoryUpdateRequest(
      key: originalKey,
      value: memory.value,
      category: category,
      source: memory.source,
      confidence: memory.confidence,
    );
    return PendingMemoryConfirmation(
      originalKey: originalKey,
      value: memory.value,
      category: category,
      confidence: memory.confidence,
      prompt: confirmationPrompt(request),
    );
  }

  MemoryCategory _categoryForKey(String key) {
    if (key.startsWith('medical.')) return MemoryCategory.medical;
    if (key.startsWith('restrictions.')) return MemoryCategory.restriction;
    if (key.startsWith('goals.')) return MemoryCategory.goal;
    return MemoryCategory.other;
  }

  String _humanLabel(MemoryUpdateRequest request) {
    switch (request.key) {
      case 'restrictions.injury':
        return 'محدودیت/آسیب «${request.value}» داری';
      case 'medical.condition':
        return 'شرایط پزشکی «${request.value}» برات مهمه';
      case 'goals.primary':
        return 'هدفت «${request.value}» هست';
      default:
        return '«${request.value}» رو برای مربی ذخیره کنم';
    }
  }

  bool? _parseVerdict(String message) {
    final normalized = message.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    const yes = <String>[
      'بله',
      'آره',
      'اره',
      'درسته',
      'درست',
      'اوکی',
      'باشه',
      'yes',
      'y',
      'ok',
      'okay',
      'confirm',
    ];
    const no = <String>[
      'نه',
      'نخیر',
      'اشتباه',
      'غلط',
      'no',
      'n',
      'cancel',
    ];

    if (yes.contains(normalized)) return true;
    if (no.contains(normalized)) return false;

    for (final token in yes) {
      if (normalized == token ||
          normalized.startsWith('$token ') ||
          normalized.endsWith(' $token')) {
        return true;
      }
    }
    for (final token in no) {
      if (normalized == token ||
          normalized.startsWith('$token ') ||
          normalized.endsWith(' $token')) {
        return false;
      }
    }
    return null;
  }

  Future<void> _syncToProfile(PendingMemoryConfirmation pending) async {
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      switch (pending.originalKey) {
        case 'restrictions.injury':
          final existing = _stringList(profile?['medical_conditions']);
          final injuries = _stringList(profile?['bb_injury_areas']);
          await SimpleProfileService.updateMedicalConditions(
            _uniqueAppend(existing, pending.value),
          );
          await SimpleProfileService.updateProfile(<String, dynamic>{
            'bb_injury_areas': _uniqueAppend(injuries, pending.value),
            'bb_injury_details': pending.value,
          });
        case 'medical.condition':
          final existing = _stringList(profile?['medical_conditions']);
          await SimpleProfileService.updateMedicalConditions(
            _uniqueAppend(existing, pending.value),
          );
        case 'goals.primary':
          final existing = _stringList(profile?['fitness_goals']);
          await SimpleProfileService.updateFitnessGoals(
            _uniqueAppend(existing, pending.value),
          );
        default:
          break;
      }
    } on Object {
      // Profile sync is best-effort; memory already persisted.
    }
  }

  List<String> _stringList(Object? raw) {
    if (raw is List) {
      return raw
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return <String>[raw.trim()];
    }
    return const <String>[];
  }

  List<String> _uniqueAppend(List<String> existing, String value) {
    final next = <String>[...existing];
    if (!next.any((item) => item.toLowerCase() == value.toLowerCase())) {
      next.add(value);
    }
    return next;
  }
}

class MemoryConfirmationResolution {
  const MemoryConfirmationResolution({
    required this.confirmed,
    required this.pending,
    required this.reply,
  });

  final bool confirmed;
  final PendingMemoryConfirmation pending;
  final String reply;
}
