/// بونوس زمانی / کمپین / چالش (مثلاً «امروز دو تمرین عمومی → ۲۰ امتیاز»).
///
/// فعلاً همیشه ۰؛ بعداً `resolver` را به تابعی وصل کن که از Supabase یا Edge
/// بخواند — امضای `TrainerLeaguePointsInput.eventBonusPoints` عوض نمی‌شود.
typedef TrainerLeagueEventBonusResolver = Future<int> Function({
  required String trainerId,
  required DateTime asOf,
});

Future<int> _defaultTrainerLeagueEventBonus({
  required String trainerId,
  required DateTime asOf,
}) async =>
    0;

class TrainerLeagueBonusRegistry {
  TrainerLeagueBonusRegistry._();

  /// در `main` یا تست عوضش کن، مثلاً: `TrainerLeagueBonusRegistry.resolver = myFn;`
  static TrainerLeagueEventBonusResolver resolver =
      _defaultTrainerLeagueEventBonus;

  static Future<int> eventBonusFor(
    String trainerId, {
    DateTime? asOf,
  }) =>
      resolver(
        trainerId: trainerId,
        asOf: asOf ?? DateTime.now(),
      );
}
