import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/skills/intelligence/skill_response_builder.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_response.dart';

/// Renders local skill responses from existing [CoachContext] data only.
///
/// Delegates product intelligence to [SkillResponseBuilder].
class CoachSkillRenderer {
  const CoachSkillRenderer({
    SkillResponseBuilder builder = const SkillResponseBuilder(),
  }) : _builder = builder;

  final SkillResponseBuilder _builder;

  /// Renders today's workout summary from active program context.
  CoachSkillResponse renderWorkoutToday(CoachContext context) {
    return _builder.buildWorkoutToday(context);
  }

  /// Renders weekly heatmap explanation from context snapshot.
  CoachSkillResponse renderHeatmap(CoachContext context) {
    return _builder.buildHeatmap(context);
  }

  /// Renders a personalized motivational response from the current question.
  CoachSkillResponse renderMotivation(CoachContext context) {
    return _builder.buildMotivation(context);
  }

  /// Renders local app-help guidance from the current question.
  CoachSkillResponse renderAppHelp({
    required CoachContext context,
    required AIIntent intent,
  }) {
    return _builder.buildAppHelp(context: context, intent: intent);
  }
}
