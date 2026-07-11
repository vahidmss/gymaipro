import 'package:gymaipro/ai/context/adapters/confidential_context_adapter.dart';
import 'package:gymaipro/ai/context/adapters/context_field_reader.dart';
import 'package:gymaipro/ai/context/adapters/profile_context_adapter.dart';
import 'package:gymaipro/ai/context/adapters/questionnaire_context_adapter.dart';
import 'package:gymaipro/workout_questionnaire/models/workout_questionnaire_models.dart';

/// Snapshot of user-owned fields used by multiple context providers.
class UserFieldsSnapshot {
  const UserFieldsSnapshot({
    required this.profile,
    required this.confidential,
    required this.questionnaire,
  });

  final Map<String, Object?>? profile;
  final Map<String, Object?>? confidential;
  final Map<String, WorkoutQuestionResponse> questionnaire;
}

/// Unified read-only adapter for profile-derived user fields.
///
/// Data sources:
/// - `ProfileRepository.fetchProfile`
/// - `ConfidentialUserInfoService.loadUserDataForProfile`
/// - `QuestionnaireLocalStorageService.getResponses`
class UserFieldsContextAdapter {
  UserFieldsContextAdapter({
    ProfileContextAdapter? profileAdapter,
    ConfidentialContextAdapter? confidentialAdapter,
    QuestionnaireContextAdapter? questionnaireAdapter,
  }) : _profileAdapter = profileAdapter ?? ProfileContextAdapter(),
       _confidentialAdapter =
           confidentialAdapter ?? ConfidentialContextAdapter(),
       _questionnaireAdapter =
           questionnaireAdapter ?? QuestionnaireContextAdapter();

  final ProfileContextAdapter _profileAdapter;
  final ConfidentialContextAdapter _confidentialAdapter;
  final QuestionnaireContextAdapter _questionnaireAdapter;

  Future<UserFieldsSnapshot> load(String userId) async {
    final profile = await _profileAdapter.getProfile(userId);
    final confidential = await _confidentialAdapter.getForProfile(userId);
    final questionnaire = await _questionnaireAdapter.getResponses(userId);
    return UserFieldsSnapshot(
      profile: profile,
      confidential: confidential,
      questionnaire: questionnaire,
    );
  }

  List<String> goalsFrom(UserFieldsSnapshot snapshot) {
    final profileGoals = ContextFieldReader.stringList(
      snapshot.profile?['fitness_goals'],
    );
    if (profileGoals.isNotEmpty) return profileGoals;

    final lifestyle = _lifestylePreferences(snapshot);
    final lifestyleGoal = ContextFieldReader.nonEmptyString(
      lifestyle['fitness_goal'] ?? lifestyle['fitness_goals'],
    );
    if (lifestyleGoal != null) return <String>[lifestyleGoal];

    final questionnaireGoal = _questionnaireText(snapshot, 'bb_goal_primary');
    if (questionnaireGoal != null) return <String>[questionnaireGoal];

    return const <String>[];
  }

  List<String> equipmentFrom(UserFieldsSnapshot snapshot) {
    final values = <String>[];

    final profileEquipment = ContextFieldReader.nonEmptyString(
      snapshot.profile?['bb_equipment_access'],
    );
    if (profileEquipment != null) values.add(profileEquipment);

    values.addAll(_questionnaireChoices(snapshot, 'bb_equipment_access'));
    if (values.isEmpty) {
      final questionnaireEquipment = _questionnaireText(
        snapshot,
        'bb_equipment_access',
      );
      if (questionnaireEquipment != null) values.add(questionnaireEquipment);
    }

    values.addAll(
      ContextFieldReader.stringList(
        snapshot.profile?['available_equipment'] ??
            snapshot.profile?['equipment'],
      ),
    );

    return ContextFieldReader.mergeUnique(values);
  }

  List<String> restrictionsFrom(UserFieldsSnapshot snapshot) {
    final values = <String>[
      ...ContextFieldReader.stringList(snapshot.profile?['medical_conditions']),
      ...ContextFieldReader.stringList(snapshot.profile?['bb_injury_areas']),
      ..._questionnaireChoices(snapshot, 'bb_injury_areas'),
    ];

    final injuryDetails = ContextFieldReader.nonEmptyString(
      snapshot.profile?['bb_injury_details'],
    );
    if (injuryDetails != null) values.add(injuryDetails);

    final questionnaireDetails = _questionnaireText(
      snapshot,
      'bb_injury_details',
    );
    if (questionnaireDetails != null) values.add(questionnaireDetails);

    final lifestyle = _lifestylePreferences(snapshot);
    for (final key in <String>[
      'medical_conditions',
      'medications',
      'allergies',
      'injuries',
    ]) {
      final value = ContextFieldReader.nonEmptyString(lifestyle[key]);
      if (value != null) values.add(value);
    }

    return ContextFieldReader.mergeUnique(
      values.where((value) => value != 'ندارم').toList(growable: false),
    );
  }

  Map<String, Object?> preferencesFrom(UserFieldsSnapshot snapshot) {
    final preferences = <String, Object?>{};

    void addIfPresent(String key, Object? value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      if (value is List && value.isEmpty) return;
      if (value is Map && value.isEmpty) return;
      preferences[key] = value;
    }

    final profile = snapshot.profile ?? const <String, Object?>{};
    addIfPresent('experience_level', profile['experience_level']);
    addIfPresent('preferred_training_days', profile['preferred_training_days']);
    addIfPresent('preferred_training_time', profile['preferred_training_time']);
    addIfPresent('dietary_preferences', profile['dietary_preferences']);
    addIfPresent('gender', profile['gender']);

    final lifestyle = _lifestylePreferences(snapshot);
    if (lifestyle.isNotEmpty) {
      preferences['lifestyle_preferences'] = lifestyle;
    }

    for (final questionId in <String>[
      'bb_experience_level',
      'bb_training_consistency',
      'bb_days_per_week',
      'bb_session_minutes',
      'bb_style_preference',
      'bb_split_preference',
      'bb_priority_muscles',
      'bb_effort_level',
      'bb_sleep_hours',
      'bb_extra_notes',
    ]) {
      final text = _questionnaireText(snapshot, questionId);
      final choices = _questionnaireChoices(snapshot, questionId);
      if (text != null) {
        preferences[questionId] = text;
      } else if (choices.isNotEmpty) {
        preferences[questionId] = choices;
      } else {
        final number = snapshot.questionnaire[questionId]?.answerNumber;
        if (number != null) preferences[questionId] = number;
      }
    }

    return Map<String, Object?>.unmodifiable(preferences);
  }

  Map<String, Object?> _lifestylePreferences(UserFieldsSnapshot snapshot) {
    return ContextFieldReader.objectMap(
      snapshot.confidential?['lifestyle_preferences'],
    );
  }

  String? _questionnaireText(UserFieldsSnapshot snapshot, String questionId) {
    return ContextFieldReader.nonEmptyString(
      snapshot.questionnaire[questionId]?.answerText,
    );
  }

  List<String> _questionnaireChoices(
    UserFieldsSnapshot snapshot,
    String questionId,
  ) {
    return ContextFieldReader.stringList(
      snapshot.questionnaire[questionId]?.answerChoices,
    );
  }
}
