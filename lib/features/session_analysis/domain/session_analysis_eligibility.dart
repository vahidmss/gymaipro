import 'package:gymaipro/features/product_experience/active_program_catalog_service.dart';
import 'package:gymaipro/workout_log/services/beginner_starter_program_service.dart';

/// Who can open «پایان تمرین و شروع تحلیل».
enum SessionAnalysisProgramKind {
  /// Real Coach AI / self-service AI program.
  aiSupervised,

  /// Free public starter («شروع باشگاه») — analysis allowed, modify locked.
  starter,

  /// Human trainer or unknown — CTA hidden.
  unsupported,
}

abstract final class SessionAnalysisEligibility {
  static SessionAnalysisProgramKind classify({
    required bool isAiSupervised,
    required bool isStarter,
  }) {
    if (isAiSupervised) return SessionAnalysisProgramKind.aiSupervised;
    if (isStarter) return SessionAnalysisProgramKind.starter;
    return SessionAnalysisProgramKind.unsupported;
  }

  static SessionAnalysisProgramKind fromActiveOption(
    ActiveProgramOption? option,
  ) {
    if (option == null) return SessionAnalysisProgramKind.unsupported;
    return classify(
      isAiSupervised: option.isAiSupervised,
      isStarter: option.isStarter,
    );
  }

  static SessionAnalysisProgramKind fromProgramData(Object? data) {
    if (BeginnerStarterProgramService.isStarterProgramData(data)) {
      return SessionAnalysisProgramKind.starter;
    }
    if (ActiveProgramCatalogService.isRealAiProgramData(data)) {
      return SessionAnalysisProgramKind.aiSupervised;
    }
    return SessionAnalysisProgramKind.unsupported;
  }

  static bool canShowFinishCta(SessionAnalysisProgramKind kind) {
    return kind == SessionAnalysisProgramKind.aiSupervised ||
        kind == SessionAnalysisProgramKind.starter;
  }

  static bool canModifyProgram(SessionAnalysisProgramKind kind) {
    return kind == SessionAnalysisProgramKind.aiSupervised;
  }
}
