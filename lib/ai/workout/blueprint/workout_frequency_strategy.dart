/// Training frequency expressed as sessions per week.
enum WorkoutFrequencyStrategy {
  two(2),
  three(3),
  four(4),
  five(5),
  six(6);

  const WorkoutFrequencyStrategy(this.daysPerWeek);

  final int daysPerWeek;
}
