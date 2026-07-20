import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/features/product_experience/domain/program_modify_coach_voice.dart';
import 'package:gymaipro/features/product_experience/domain/program_modify_options.dart';

void main() {
  group('ProgramModifyCoachVoice', () {
    test('detects key lifts', () {
      expect(ProgramModifyCoachVoice.isKeyLift('پرس سینه هالتر'), isTrue);
      expect(ProgramModifyCoachVoice.isKeyLift('اسکوات پشت'), isTrue);
      expect(ProgramModifyCoachVoice.isKeyLift('پشت بازو سیم‌کش'), isFalse);
    });

    test('soft refuses removing bench without injury reason', () {
      final decision = ProgramModifyCoachVoice.softRefuseRemove(
        exerciseName: 'پرس سینه دمبل',
        reasonId: 'boring',
      );
      expect(decision, isNotNull);
      expect(decision!.softRefused, isTrue);
      expect(decision.suggestedGoals, contains(ProgramModifyGoal.replaceExercise));
    });

    test('allows remove of key lift with pain reason', () {
      final decision = ProgramModifyCoachVoice.softRefuseRemove(
        exerciseName: 'پرس سینه',
        reasonId: 'pain',
      );
      expect(decision, isNull);
    });

    test('request summary is clear without duplicate شنیدم', () {
      final text = ProgramModifyCoachVoice.requestSummary(
        goal: ProgramModifyGoal.tiredAdapt,
        reasonLabel: 'خواب کم',
      );
      expect(text.contains('شنیدم'), isFalse);
      expect(text.contains('خواب کم'), isTrue);
      expect(text.contains('سبک'), isTrue);
    });

    test('tired decision message stays short', () {
      final text = ProgramModifyCoachVoice.decisionMessage(
        goal: ProgramModifyGoal.tiredAdapt,
        reasonLabel: 'خواب کم',
        volumeReduced: true,
        replaceCount: 2,
      );
      expect(text.contains('فشار'), isFalse);
      expect(text.contains('خواب کم'), isTrue);
      expect(text.contains('ست'), isTrue);
      expect(text.contains('عوض نشدند'), isTrue);
      expect(text.length < 180, isTrue);
    });

    test('reduce volume decision avoids فشار wording', () {
      final text = ProgramModifyCoachVoice.decisionMessage(
        goal: ProgramModifyGoal.reduceVolume,
      );
      expect(text.contains('فشار'), isFalse);
      expect(text.contains('سبک'), isTrue);
    });
  });
}
