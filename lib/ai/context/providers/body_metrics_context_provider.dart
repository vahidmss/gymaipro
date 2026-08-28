import 'package:gymaipro/ai/context/coach_context_patch.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/providers/base_context_provider.dart';
import 'package:gymaipro/services/streak_service.dart';
import 'package:gymaipro/services/weekly_weight_service.dart';

/// Enriches the profile context with real weight-trend and streak data.
///
/// Coach answers about weight loss/gain progress must reference the user's
/// recorded weigh-ins, not just the static profile weight field.
class BodyMetricsContextProvider implements AIContextProvider {
  BodyMetricsContextProvider();

  /// Architecture documentation for this provider.
  AIContextProviderDescriptor get descriptor =>
      const AIContextProviderDescriptor(
        dataSource:
            'WeeklyWeightService.getFullWeightHistory + StreakService',
        readStrategy: 'Read-only weekly weight records and login/workout streak.',
        cacheStrategy: 'No local cache; records change at most weekly.',
        missingBehaviour: 'Return an empty patch when no records exist.',
        futureMigrationNotes:
            'Add body measurements (circumferences) trend when available.',
      );

  @override
  String get id => 'body_metrics_context_provider';

  @override
  String get name => 'Body Metrics Context Provider';

  @override
  Set<AIContextProviderKey> get providedKeys => const <AIContextProviderKey>{
    AIContextProviderKey.profile,
  };

  @override
  Set<AIContextSection> get providedSections => const <AIContextSection>{
    AIContextSection.userProfile,
  };

  @override
  AIContextProviderMetadata get metadata => AIContextProviderMetadata(
    name: name,
    priority: priority,
    estimatedCost: estimatedCost,
    estimatedLatency: estimatedLatency,
    cacheable: cacheable,
    ttl: ttl,
  );

  @override
  ContextPriority get priority => ContextPriority.medium;

  @override
  double get estimatedCost => 0;

  @override
  Duration get estimatedLatency => const Duration(milliseconds: 250);

  @override
  bool get cacheable => true;

  @override
  Duration get ttl => const Duration(minutes: 30);

  @override
  Future<CoachContextPatch> build(AIContextRequest request) async {
    final profile = <String, Object?>{};

    try {
      final streak = await StreakService.getStreakForUser(request.userId);
      if (streak.current > 0 || streak.longest > 0) {
        profile['current_streak_days'] = streak.current;
        profile['longest_streak_days'] = streak.longest;
      }
    } on Object {
      // Streak is optional enrichment.
    }

    try {
      final history = await WeeklyWeightService.getFullWeightHistory(
        request.userId,
      );
      final records = history
          .map(_readRecord)
          .whereType<({DateTime date, double weight})>()
          .toList(growable: false);

      if (records.isNotEmpty) {
        final latest = records.last;
        profile['latest_recorded_weight_kg'] = latest.weight;
        profile['latest_weight_recorded_at'] = _formatDate(latest.date);
        profile['weight_records_count'] = records.length;

        final monthAgo = latest.date.subtract(const Duration(days: 31));
        ({DateTime date, double weight})? baseline;
        for (final record in records) {
          if (!record.date.isAfter(monthAgo)) baseline = record;
        }
        final reference = baseline ?? records.first;
        if (!identical(reference, latest)) {
          final delta = latest.weight - reference.weight;
          profile['weight_change_kg'] = double.parse(delta.toStringAsFixed(1));
          profile['weight_change_since'] = _formatDate(reference.date);
        }

        final recent = records.length <= 5
            ? records
            : records.sublist(records.length - 5);
        profile['recent_weigh_ins'] = <Object?>[
          for (final record in recent)
            <String, Object?>{
              'date': _formatDate(record.date),
              'weight_kg': record.weight,
            },
        ];
      }
    } on Object {
      // Weight history is optional enrichment.
    }

    if (profile.isEmpty) return CoachContextPatch.empty;
    return CoachContextPatch(profile: profile);
  }

  ({DateTime date, double weight})? _readRecord(Map<String, dynamic> row) {
    final weight = double.tryParse(row['weight']?.toString() ?? '');
    final date = DateTime.tryParse(row['recorded_at']?.toString() ?? '');
    if (weight == null || weight <= 0 || date == null) return null;
    return (date: date, weight: weight);
  }

  String _formatDate(DateTime date) =>
      date.toIso8601String().substring(0, 10);
}
