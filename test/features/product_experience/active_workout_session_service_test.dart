import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/features/product_experience/active_workout_session_service.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  setUpAll(() async {
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-anon-key',
    );
  });

  late final ActiveWorkoutSessionService service;

  setUpAll(() {
    service = ActiveWorkoutSessionService();
  });

  group('ActiveWorkoutSessionService.draftMatchesSelection', () {
    test('matches same program and session day', () {
      expect(
        ActiveWorkoutSessionService.draftMatchesSelection(
          programId: 'p1',
          sessionDay: 'روز ۱',
          draftProgramId: 'p1',
          draftFocus: 'روز ۱',
        ),
        isTrue,
      );
    });

    test('rejects different program', () {
      expect(
        ActiveWorkoutSessionService.draftMatchesSelection(
          programId: 'p2',
          sessionDay: 'روز ۱',
          draftProgramId: 'p1',
          draftFocus: 'روز ۱',
        ),
        isFalse,
      );
    });

    test('rejects different session day', () {
      expect(
        ActiveWorkoutSessionService.draftMatchesSelection(
          programId: 'p1',
          sessionDay: 'روز ۲',
          draftProgramId: 'p1',
          draftFocus: 'روز ۱',
        ),
        isFalse,
      );
    });

    test('rejects draft without programId', () {
      expect(
        ActiveWorkoutSessionService.draftMatchesSelection(
          programId: 'p1',
          sessionDay: 'روز ۱',
          draftProgramId: null,
          draftFocus: 'روز ۱',
        ),
        isFalse,
      );
    });
  });

  group('ActiveWorkoutSessionService.evaluateSessionChange', () {
    test('no confirm when draft is empty shell (hasLiveDraft false)', () {
      const context = ActiveWorkoutSessionContext(
        programId: 'p1',
        programName: 'Test',
        sessions: <WorkoutSession>[],
        selectedSessionDay: 'روز ۱',
        loggedSessionDay: null,
        hasSavedLog: false,
        hasLiveDraft: false,
      );

      final evaluation = service.evaluateSessionChange(
        context: context,
        newSessionDay: 'روز ۲',
        currentSessionDay: 'روز ۱',
      );

      expect(evaluation.requiresConfirmation, isFalse);
    });

    test('no confirm when picking the draft session with null selection', () {
      const context = ActiveWorkoutSessionContext(
        programId: 'p1',
        programName: 'Test',
        sessions: <WorkoutSession>[],
        selectedSessionDay: null,
        loggedSessionDay: null,
        hasSavedLog: false,
        hasLiveDraft: true,
        draftSessionDay: 'روز ۱',
      );

      final evaluation = service.evaluateSessionChange(
        context: context,
        newSessionDay: 'روز ۱',
        currentSessionDay: null,
      );

      expect(evaluation.requiresConfirmation, isFalse);
    });

    test('requires confirm when draft conflicts with a different session', () {
      const context = ActiveWorkoutSessionContext(
        programId: 'p1',
        programName: 'Test',
        sessions: <WorkoutSession>[],
        selectedSessionDay: null,
        loggedSessionDay: null,
        hasSavedLog: false,
        hasLiveDraft: true,
        draftSessionDay: 'روز ۱',
      );

      final evaluation = service.evaluateSessionChange(
        context: context,
        newSessionDay: 'روز ۲',
        currentSessionDay: null,
      );

      expect(evaluation.requiresConfirmation, isTrue);
      expect(evaluation.hasUnsavedData, isTrue);
    });

    test('requires confirm when saved log conflicts', () {
      const context = ActiveWorkoutSessionContext(
        programId: 'p1',
        programName: 'Test',
        sessions: <WorkoutSession>[],
        selectedSessionDay: 'روز ۱',
        loggedSessionDay: 'روز ۱',
        hasSavedLog: true,
        hasLiveDraft: false,
      );

      final evaluation = service.evaluateSessionChange(
        context: context,
        newSessionDay: 'روز ۲',
        currentSessionDay: 'روز ۱',
      );

      expect(evaluation.requiresConfirmation, isTrue);
      expect(evaluation.hasSavedLog, isTrue);
      expect(evaluation.sessionDayToDelete, 'روز ۱');
    });

    test('no confirm when selecting same day', () {
      const context = ActiveWorkoutSessionContext(
        programId: 'p1',
        programName: 'Test',
        sessions: <WorkoutSession>[],
        selectedSessionDay: 'روز ۱',
        loggedSessionDay: 'روز ۱',
        hasSavedLog: true,
        hasLiveDraft: true,
      );

      final evaluation = service.evaluateSessionChange(
        context: context,
        newSessionDay: 'روز ۱',
        currentSessionDay: 'روز ۱',
      );

      expect(evaluation.requiresConfirmation, isFalse);
    });

    test('no confirm when neither saved log nor draft progress', () {
      const context = ActiveWorkoutSessionContext(
        programId: 'p1',
        programName: 'Test',
        sessions: <WorkoutSession>[],
        selectedSessionDay: 'روز ۱',
        loggedSessionDay: null,
        hasSavedLog: false,
        hasLiveDraft: false,
      );

      final evaluation = service.evaluateSessionChange(
        context: context,
        newSessionDay: 'روز ۲',
      );

      expect(evaluation.requiresConfirmation, isFalse);
      expect(evaluation.hasSavedLog, isFalse);
      expect(evaluation.hasUnsavedData, isFalse);
    });
  });

  group('ActiveWorkoutSessionService.evaluateProgramChange', () {
    test('requires confirm when draft or log exists', () {
      const context = ActiveWorkoutSessionContext(
        programId: 'p1',
        programName: 'Test',
        sessions: <WorkoutSession>[],
        selectedSessionDay: 'روز ۱',
        loggedSessionDay: 'روز ۱',
        hasSavedLog: true,
        hasLiveDraft: false,
      );

      final evaluation = service.evaluateProgramChange(context: context);
      expect(evaluation.requiresConfirmation, isTrue);
      expect(evaluation.hasSavedLog, isTrue);
    });

    test('no confirm when nothing to clear', () {
      const context = ActiveWorkoutSessionContext(
        programId: 'p1',
        programName: 'Test',
        sessions: <WorkoutSession>[],
        selectedSessionDay: null,
        loggedSessionDay: null,
        hasSavedLog: false,
        hasLiveDraft: false,
      );

      final evaluation = service.evaluateProgramChange(context: context);
      expect(evaluation.requiresConfirmation, isFalse);
    });
  });
}
