import 'package:gymaipro/ai/workout_review/models/workout_review_enums.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_issue.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_result.dart';

/// Turns post-generation review into LLM repair notes.
///
/// High/critical issues get one extra repair round. The paid flow still
/// delivers if the structural validator already passed — review is quality,
/// not a hard fail after payment.
abstract final class LlmWorkoutQualityGate {
  const LlmWorkoutQualityGate._();

  static const Set<WorkoutReviewIssueSeverity> _blocking = {
    WorkoutReviewIssueSeverity.high,
    WorkoutReviewIssueSeverity.critical,
  };

  static List<WorkoutReviewIssue> blockingIssues(WorkoutReviewResult review) {
    if (!review.enabled) return const <WorkoutReviewIssue>[];
    return review.issues
        .where((issue) => _blocking.contains(issue.severity))
        .toList(growable: false);
  }

  static List<String> repairNotes(WorkoutReviewResult review) {
    return blockingIssues(review).map(_toPersian).toList(growable: false);
  }

  static String _toPersian(WorkoutReviewIssue issue) {
    switch (issue.code) {
      case WorkoutReviewIssueCode.chestOverloaded:
        return 'حجم سینه نسبت به پشت زیاد است؛ یک حرکت سینه را کم کن یا پشت اضافه کن.';
      case WorkoutReviewIssueCode.noPosteriorChain:
        return 'زنجیره خلفی (همسترینگ/باسن) نسبت به پا کم است؛ لگ‌کرل یا هیپ‌تراست اضافه کن.';
      case WorkoutReviewIssueCode.tooMuchKneeStress:
        return 'فشار زانو بالاست؛ اسکوات/لانج سنگین را با پرس پا یا حرکت ایمن‌تر عوض کن.';
      case WorkoutReviewIssueCode.recoveryTooLow:
        return 'فشار ریکاوری زیاد است؛ حجم جلسه را کمی کم کن.';
      case WorkoutReviewIssueCode.tooManyCompoundExercises:
        return 'حرکات مرکب بیش از حدند؛ یکی را با ایزوله همان عضله عوض کن.';
      case WorkoutReviewIssueCode.missingDeload:
        return 'برنامه چند‌هفته‌ای دیلود ندارد.';
      case WorkoutReviewIssueCode.weakShoulderBalance:
        return 'پرس شانه زیاد است و تعادل پشت‌شانه کم؛ فیس‌پول یا نشر خم اضافه کن.';
      case WorkoutReviewIssueCode.noPullingVolume:
        return 'حجم کشش/پشت نسبت به فشار کم است؛ لت یا روئینگ اضافه کن.';
      case WorkoutReviewIssueCode.excessiveIsolation:
        return 'ایزوله‌ها زیادند؛ یک حرکت مرکب اصلی اضافه کن.';
      case WorkoutReviewIssueCode.equipmentConflict:
        return 'بعضی حرکات با تجهیزات کاربر جور نیستند؛ فقط از فهرست مجاز بردار.';
      case WorkoutReviewIssueCode.beginnerVolumeTooHigh:
        return 'حجم برای مبتدی زیاد است؛ حرکت هر جلسه را کم کن.';
      case WorkoutReviewIssueCode.advancedVolumeTooLow:
        return 'حجم برای سطح پیشرفته کم است.';
      case WorkoutReviewIssueCode.goalMismatch:
        return 'ست/تکرار با هدف کاربر هم‌خوان نیست.';
      case WorkoutReviewIssueCode.emptyProgram:
        return 'برنامه خالی است؛ هر روز حداقل ۵ حرکت بگذار.';
    }
  }
}
