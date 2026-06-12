import 'package:gymaipro/trainer_ranking/services/certificate_service.dart';
import 'package:gymaipro/trainer_ranking/services/trainer_kpi_service.dart';
import 'package:gymaipro/trainer_ranking/services/trainer_league_bonus_policy.dart';
import 'package:gymaipro/trainer_ranking/services/trainer_league_points.dart';

/// محاسبهٔ امتیاز تجمعی لیگ برای یک مربی (همان منطق صفحهٔ دیتیل).
class TrainerLeaguePointsService {
  TrainerLeaguePointsService({TrainerKpiService? kpiService})
      : _kpi = kpiService ?? TrainerKpiService();

  final TrainerKpiService _kpi;

  Future<TrainerLeaguePointsBreakdown> computeBreakdown(String trainerId) async {
    if (trainerId.trim().isEmpty) {
      return TrainerLeaguePoints.compute(
        const TrainerLeaguePointsInput(
          totalStudents: 0,
          sentWorkoutPrograms: 0,
          sumReviewStars: 0,
          medianDeliveryHours: double.nan,
          deliverySampleCount: 0,
          privateCustomExercises: 0,
          publicCustomExercises: 0,
          customMusicCount: 0,
          approvedCertificateCount: 0,
        ),
      );
    }

    final kpis = await _kpi.getTrainerKpis(trainerId);
    final delivery = await _kpi.getProgramDeliveryStats(trainerId);
    final certN =
        await CertificateService.countApprovedTrainerCertificates(trainerId);
    final starSum = await _kpi.sumReviewStarPoints(trainerId);
    final exVis = await _kpi.countCustomExercisesByVisibility(trainerId);
    final eventBonus = await TrainerLeagueBonusRegistry.eventBonusFor(trainerId);

    return TrainerLeaguePoints.compute(
      TrainerLeaguePointsInput(
        totalStudents: kpis.totalStudents,
        sentWorkoutPrograms: kpis.activeWorkoutPrograms,
        sumReviewStars: starSum,
        medianDeliveryHours: delivery.medianHours,
        deliverySampleCount: delivery.sampleCount,
        privateCustomExercises: exVis.privateCount,
        publicCustomExercises: exVis.publicCount,
        customMusicCount: kpis.totalCustomMusics,
        approvedCertificateCount: certN,
        eventBonusPoints: eventBonus,
      ),
    );
  }

  Future<int> computeTotalPoints(String trainerId) async =>
      (await computeBreakdown(trainerId)).totalPoints;
}
