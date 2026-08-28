import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/features/product_experience/program_display_labels.dart';
import 'package:gymaipro/payment/services/subscription_service.dart';
import 'package:gymaipro/services/active_program_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/utils/auth_helper.dart';
import 'package:gymaipro/workout_log/services/beginner_starter_program_service.dart';
import 'package:gymaipro/workout_plan_builder/services/workout_program_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// One selectable workout program with human-readable title and creator.
class ActiveProgramOption {
  const ActiveProgramOption({
    required this.id,
    required this.title,
    required this.creatorLabel,
    this.creatorLine,
    required this.isActive,
    this.isAiSupervised = false,
    this.isStarter = false,
  });

  final String id;
  final String title;
  final String creatorLabel;
  final String? creatorLine;
  final bool isActive;

  /// True only for real Coach AI / self-service AI programs.
  /// Starter («شروع باشگاه») is never AI-supervised.
  final bool isAiSupervised;
  final bool isStarter;

  String get displaySubtitle {
    if (creatorLine != null && creatorLine!.trim().isNotEmpty) {
      return 'سازنده: $creatorLine';
    }
    return 'سازنده: $creatorLabel';
  }
}

/// Lists workout programs and activates the shared profile selection.
class ActiveProgramCatalogService {
  ActiveProgramCatalogService({
    SupabaseClient? client,
    ActiveProgramService? activeProgramService,
  }) : _clientOverride = client,
       _activeProgramService = activeProgramService ?? ActiveProgramService();

  final SupabaseClient? _clientOverride;
  final ActiveProgramService _activeProgramService;

  SupabaseClient get _client => _clientOverride ?? Supabase.instance.client;

  Future<String?> getActiveProgramId() async {
    final state = await _activeProgramService.getActiveProgramState();
    return state?['active_program_id']?.toString();
  }

  Future<bool> activateProgram(String programId) async {
    return _activeProgramService.setActiveProgram(programId);
  }

  Future<List<ActiveProgramOption>> listWorkoutPrograms() async {
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) return const <ActiveProgramOption>[];

      final profile = await SimpleProfileService.getCurrentProfile();
      final profileId = (profile?['id'] as String?)?.trim();
      final effectiveUserId =
          (profileId != null && profileId.isNotEmpty) ? profileId : userId;

      final activeId = await getActiveProgramId();
      try {
        await WorkoutProgramService().ensureStarterPublished();
      } on Object catch (e) {
        if (kDebugMode) {
          debugPrint('[ActiveProgramCatalog] ensureStarterPublished: $e');
        }
      }
      try {
        await WorkoutProgramService().ensureSelfServiceAiPublished();
      } on Object catch (e) {
        if (kDebugMode) {
          debugPrint(
            '[ActiveProgramCatalog] ensureSelfServiceAiPublished: $e',
          );
        }
      }
      final rows = await _fetchProgramRows(effectiveUserId);
      final options = <ActiveProgramOption>[];

      for (final row in rows) {
        final id = row['id']?.toString() ?? '';
        if (id.isEmpty) continue;

        final data = row['data'];
        final isStarter = BeginnerStarterProgramService.isStarterProgramData(
          data,
        );
        final isAi = isRealAiProgramData(data);
        final trainer = row['trainer'];
        final trainerMap = trainer is Map
            ? Map<String, dynamic>.from(trainer)
            : null;
        final trainerName = formatTrainerName(trainerMap);
        final creatorName = isAi
            ? AppConfig.gymAiDisplayName
            : isStarter
            ? 'شروع باشگاه'
            : trainerName;

        final labels = ProgramDisplayLabels.resolve(
          rawName: row['program_name']?.toString() ?? '',
          creatorName: creatorName,
        );

        options.add(
          ActiveProgramOption(
            id: id,
            title: labels.title,
            creatorLabel: creatorName,
            creatorLine: labels.creatorLine,
            isActive: activeId == id,
            isAiSupervised: isAi,
            isStarter: isStarter,
          ),
        );
      }

      final delivered = options.cast<ActiveProgramOption?>().where(
        (o) => o!.isAiSupervised,
      ).firstOrNull;
      if (delivered != null) {
        try {
          await SubscriptionService().repairCoachEntitlementIfProgramExists(
            userId: effectiveUserId,
            programId: delivered.id,
          );
        } on Object catch (e) {
          if (kDebugMode) {
            debugPrint('[ActiveProgramCatalog] repair entitlement: $e');
          }
        }
      }

      return options;
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint('[ActiveProgramCatalog] listWorkoutPrograms error: $error');
      }
      return const <ActiveProgramOption>[];
    }
  }

  /// Coach / Live / Workout Today — only real AI programs (no starter, no human).
  Future<List<ActiveProgramOption>> listAiWorkoutPrograms() async {
    final all = await listWorkoutPrograms();
    return all
        .where((program) => program.isAiSupervised)
        .toList(growable: false);
  }

  Future<ActiveProgramOption?> getActiveProgramOption() async {
    final activeId = await getActiveProgramId();
    if (activeId == null || activeId.isEmpty) return null;
    final programs = await listWorkoutPrograms();
    for (final program in programs) {
      if (program.id == activeId) return program;
    }
    return null;
  }

  /// Active program only if it is a real Coach AI program.
  Future<ActiveProgramOption?> getActiveAiProgramOption() async {
    final active = await getActiveProgramOption();
    if (active == null || !active.isAiSupervised) return null;
    return active;
  }

  /// True for Coach-generated / self-service AI programs.
  /// Starter onboarding is explicitly excluded.
  ///
  /// Supabase may return `data` as a Map (jsonb) or as a JSON string
  /// (especially when clients historically wrote `jsonEncode(...)`).
  static bool isRealAiProgramData(Object? data) {
    if (BeginnerStarterProgramService.isStarterProgramData(data)) {
      return false;
    }
    final map = _asDataMap(data);
    if (map == null) return false;
    return map['is_self_service_ai'] == true;
  }

  static Map<String, dynamic>? _asDataMap(Object? data) {
    if (data == null) return null;
    try {
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      if (data is String && data.trim().isNotEmpty) {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
        // Rare double-encoded payload.
        if (decoded is String && decoded.trim().isNotEmpty) {
          final nested = jsonDecode(decoded);
          if (nested is Map) {
            return Map<String, dynamic>.from(nested);
          }
        }
      }
    } on Object {
      return null;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _fetchProgramRows(String userId) async {
    try {
      final rows = await _client
          .from('workout_programs')
          .select('''
            id, program_name, data, trainer_id, sent_at,
            trainer:profiles!workout_programs_trainer_id_fkey(
              id, username, first_name, last_name, avatar_url
            )
          ''')
          .eq('user_id', userId)
          .eq('is_deleted', false)
          .not('sent_at', 'is', null)
          .order('created_at', ascending: false);
      return rows
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(growable: false);
    } on Object {
      try {
        final rows = await _client
            .from('workout_programs')
            .select('''
              id, program_name, data, trainer_id,
              trainer:profiles!workout_programs_trainer_id_fkey(
                id, username, first_name, last_name, avatar_url
              )
            ''')
            .eq('user_id', userId)
            .eq('is_deleted', false)
            .order('created_at', ascending: false);
        return rows
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList(growable: false);
      } on Object {
        return const <Map<String, dynamic>>[];
      }
    }
  }

  static String formatTrainerName(Map<String, dynamic>? trainer) {
    if (trainer == null) return 'آزمایشی';
    final fullName =
        '${trainer['first_name'] ?? ''} ${trainer['last_name'] ?? ''}'.trim();
    if (fullName.isNotEmpty) return fullName;
    final username = trainer['username']?.toString().trim();
    if (username != null && username.isNotEmpty) return username;
    return 'آزمایشی';
  }
}
