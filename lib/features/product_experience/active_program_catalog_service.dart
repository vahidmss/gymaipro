import 'package:flutter/foundation.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/features/product_experience/program_display_labels.dart';
import 'package:gymaipro/services/active_program_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/utils/auth_helper.dart';
import 'package:gymaipro/workout_log/services/beginner_starter_program_service.dart';
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
  }) : _client = client ?? Supabase.instance.client,
       _activeProgramService = activeProgramService ?? ActiveProgramService();

  final SupabaseClient _client;
  final ActiveProgramService _activeProgramService;

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
      final rows = await _fetchProgramRows(effectiveUserId);
      final options = <ActiveProgramOption>[];

      for (final row in rows) {
        final id = row['id']?.toString() ?? '';
        if (id.isEmpty) continue;

        final data = row['data'];
        final isStarter = BeginnerStarterProgramService.isStarterProgramData(
          data,
        );
        final isAi = _isAiProgramData(data);
        final trainer = row['trainer'];
        final trainerMap = trainer is Map
            ? Map<String, dynamic>.from(trainer)
            : null;
        final trainerName = formatTrainerName(trainerMap);
        final creatorName = isAi || isStarter
            ? AppConfig.gymAiDisplayName
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
            isAiSupervised: isAi || isStarter,
            isStarter: isStarter,
          ),
        );
      }

      return options;
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint('[ActiveProgramCatalog] listWorkoutPrograms error: $error');
      }
      return const <ActiveProgramOption>[];
    }
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

  static bool _isAiProgramData(Object? data) {
    if (data is! Map) return false;
    final map = Map<String, dynamic>.from(data);
    return map['is_self_service_ai'] == true ||
        map['generated_by'] == 'gymai_starter';
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
