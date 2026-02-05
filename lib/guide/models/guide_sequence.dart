import 'package:gymaipro/guide/models/guide_step.dart';

/// یک دنباله کامل از مراحل راهنما
class GuideSequence {
  /// شناسه یکتا
  final String id;

  /// نام
  final String name;

  /// توضیحات
  final String? description;

  /// لیست مراحل
  final List<GuideStep> steps;

  /// آیا این راهنما فقط یکبار نمایش داده شود؟
  final bool showOnce;

  /// پیش‌نیاز (اگر راهنمای دیگری باید قبل از این نمایش داده شود)
  final String? prerequisiteId;

  const GuideSequence({
    required this.id,
    required this.name,
    this.description,
    required this.steps,
    this.showOnce = true,
    this.prerequisiteId,
  });

  int get stepCount => steps.length;

  GuideStep? getStep(int index) {
    if (index >= 0 && index < steps.length) {
      return steps[index];
    }
    return null;
  }

  bool get hasSteps => steps.isNotEmpty;

  GuideSequence copyWith({
    String? id,
    String? name,
    String? description,
    List<GuideStep>? steps,
    bool? showOnce,
    String? prerequisiteId,
  }) {
    return GuideSequence(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      steps: steps ?? this.steps,
      showOnce: showOnce ?? this.showOnce,
      prerequisiteId: prerequisiteId ?? this.prerequisiteId,
    );
  }
}

