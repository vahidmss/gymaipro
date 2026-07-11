import 'package:gymaipro/workout_questionnaire/models/workout_questionnaire_models.dart';
import 'package:gymaipro/workout_questionnaire/services/questionnaire_local_storage_service.dart';

/// Read-only adapter for locally stored workout questionnaire responses.
class QuestionnaireContextAdapter {
  QuestionnaireContextAdapter({
    QuestionnaireLocalStorageService? storageService,
  }) : _storageService = storageService ?? QuestionnaireLocalStorageService();

  final QuestionnaireLocalStorageService _storageService;

  /// Returns questionnaire responses stored on device for [userId].
  Future<Map<String, WorkoutQuestionResponse>> getResponses(String userId) {
    return _storageService.getResponses(userId);
  }
}
