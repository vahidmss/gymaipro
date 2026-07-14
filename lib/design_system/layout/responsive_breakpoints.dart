/// GymAI responsive breakpoints.
abstract final class GymBreakpoints {
  static const double compact = 360;
  static const double medium = 600;
  static const double expanded = 840;
  static const double wide = 1200;

  static bool isCompact(double width) => width < medium;
  static bool isMedium(double width) => width >= medium && width < expanded;
  static bool isExpanded(double width) => width >= expanded && width < wide;
  static bool isWide(double width) => width >= wide;

  static double contentMaxWidth(double width) {
    if (isWide(width)) return 960;
    if (isExpanded(width)) return 820;
    return width;
  }
}
