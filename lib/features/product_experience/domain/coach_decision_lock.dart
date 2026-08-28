import 'package:gymaipro/features/product_experience/domain/coach_observation.dart';
import 'package:gymaipro/features/product_experience/domain/exercise_coach_decision.dart';
import 'package:gymaipro/features/product_experience/domain/session_debrief.dart';

/// Builds locked coach facts for LLM context packages.
///
/// The model may narrate these facts; it must not invent new kg/reps/actions.
abstract final class CoachDecisionLock {
  static const String sectionId = 'decisions.lock';
  static const String systemRule =
      'Never invent training loads (kg/reps/sets) or progression actions '
      'that are not in decisions.lock. '
      'If incomplete_volume is true, do not recommend adding weight. '
      'If first_session is true or chase_load is false, do not tell the user '
      'to add kg. Completing the prescribed session is success. '
      'If decisions.lock has no per-exercise decisions, do not invent '
      'specific kg/reps/sets. '
      'You MAY and SHOULD use numbers from User Profile / Goals / context '
      '(height, weight, BMI, body fat, age, goals) and compute BMI from '
      'height+weight when both exist. '
      'Answer the user question directly first with their real data — '
      'do not lecture generically about BMI formulas, do not stall with '
      'unnecessary follow-up questions when the needed facts are already '
      'in context, and do not invent a medical diagnosis. '
      'Disagree with fluff when facts say otherwise. '
      'Never write a full workout or meal plan in chat.';

  static Map<String, Object?> buildPackage({
    List<ExerciseDecision> decisions = const <ExerciseDecision>[],
    SessionDebrief? debrief,
    List<CoachObservation> observations = const <CoachObservation>[],
    List<String> forbiddenClaims = const <String>[
      'clinical_diagnosis',
      'invented_load',
      'full_program_in_chat',
    ],
  }) {
    return <String, Object?>{
      'version': 1,
      'decisions': decisions.map((d) => d.toLockJson()).toList(growable: false),
      if (debrief != null) 'debrief': debrief.toLockJson(),
      'observations': observations
          .map((o) => o.toLockJson())
          .toList(growable: false),
      'forbidden_claims': forbiddenClaims,
      'allowed_actions': decisions
          .map((d) => d.action.name)
          .toSet()
          .toList(growable: false),
    };
  }

  static bool systemMentionsNumericLock(String systemContent) {
    final lower = systemContent.toLowerCase();
    return lower.contains('never invent') &&
        (lower.contains('kg') || lower.contains('reps')) &&
        lower.contains('decisions.lock');
  }
}
