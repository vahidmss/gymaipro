/// Normalizes athlete body metrics for coach chat / prompt context.
///
/// Prefers explicit profile fields, then questionnaire aliases (`bb_*`).
abstract final class CoachProfileMetrics {
  static const List<String> heightKeys = <String>[
    'height',
    'height_cm',
    'bb_height_cm',
  ];
  static const List<String> weightKeys = <String>[
    'weight',
    'weight_kg',
    'bb_weight_kg',
    'current_weight',
  ];
  static const List<String> bodyFatKeys = <String>[
    'body_fat',
    'bodyfat',
    'bb_bodyfat_estimate',
    'body_fat_percent',
  ];

  /// WHO healthy BMI band used for excess/deficit kg estimates.
  static const double healthyBmiMin = 18.5;
  static const double healthyBmiMax = 24.9;

  /// Mutates [profile] in place: canonical height/weight + computed BMI.
  static void enrich(Map<String, Object?> profile) {
    final height = readDouble(profile, heightKeys);
    final weight = readDouble(profile, weightKeys);
    final bodyFat = readDouble(profile, bodyFatKeys);

    if (height != null && height > 0) {
      profile['height'] = height;
      profile['height_cm'] = height;
    }
    if (weight != null && weight > 0) {
      profile['weight'] = weight;
      profile['weight_kg'] = weight;
    }
    if (bodyFat != null && bodyFat > 0) {
      profile['body_fat'] = bodyFat;
      profile['body_fat_percent'] = bodyFat;
    }

    if (height != null &&
        weight != null &&
        height >= 100 &&
        height <= 250 &&
        weight >= 30 &&
        weight <= 300) {
      final meters = height / 100;
      final bmi = weight / (meters * meters);
      final rounded = double.parse(bmi.toStringAsFixed(1));
      final maxHealthy = weightForBmi(heightCm: height, bmi: healthyBmiMax);
      final minHealthy = weightForBmi(heightCm: height, bmi: healthyBmiMin);
      final excessKg = double.parse((weight - maxHealthy).toStringAsFixed(1));
      final deficitKg = double.parse((minHealthy - weight).toStringAsFixed(1));

      profile['bmi'] = rounded;
      profile['bmi_category'] = categoryFa(rounded);
      profile['bmi_verdict'] = overweightVerdictFa(rounded);
      profile['healthy_weight_min_kg'] = minHealthy;
      profile['healthy_weight_max_kg'] = maxHealthy;
      profile['excess_weight_kg'] = excessKg > 0 ? excessKg : 0;
      profile['weight_deficit_kg'] = deficitKg > 0 ? deficitKg : 0;
      profile['body_metrics_summary_fa'] = summaryFa(
        heightCm: height,
        weightKg: weight,
        bmi: rounded,
        bodyFat: bodyFat,
      );
      profile['excess_weight_answer_fa'] = excessWeightAnswerFa(
        heightCm: height,
        weightKg: weight,
        bmi: rounded,
      );
    }
  }

  static double? readDouble(
    Map<String, Object?> source,
    List<String> keys,
  ) {
    for (final key in keys) {
      final raw = source[key];
      if (raw == null) continue;
      if (raw is num) {
        final value = raw.toDouble();
        if (value > 0) return value;
      }
      final parsed = double.tryParse(raw.toString().trim().replaceAll(',', '.'));
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }

  static double weightForBmi({
    required double heightCm,
    required double bmi,
  }) {
    final meters = heightCm / 100;
    return double.parse((bmi * meters * meters).toStringAsFixed(1));
  }

  static String categoryFa(double bmi) {
    if (bmi < 18.5) return 'کمبود وزن';
    if (bmi < 25) return 'محدودهٔ طبیعی';
    if (bmi < 30) return 'اضافه وزن';
    return 'چاقی';
  }

  static String _fmtKg(double kg) =>
      kg.toStringAsFixed(kg % 1 == 0 ? 0 : 1);

  /// Direct answer style for «آیا اضافه وزن دارم؟»
  static String overweightVerdictFa(double bmi) {
    if (bmi < 18.5) {
      return 'بر اساس قد و وزن ثبت‌شده‌ات، الان کمبود وزن داری — نه اضافه وزن.';
    }
    if (bmi < 25) {
      return 'بر اساس قد و وزن ثبت‌شده‌ات، اضافه وزن نداری؛ BMI در محدودهٔ طبیعی است.';
    }
    if (bmi < 30) {
      return 'بر اساس قد و وزن ثبت‌شده‌ات، بله — در محدودهٔ اضافه وزن هستی.';
    }
    return 'بر اساس قد و وزن ثبت‌شده‌ات، بله — BMI در محدودهٔ چاقی است.';
  }

  /// Answers «چند کیلو اضافه وزن دارم؟» with kg vs healthy BMI ceiling.
  static String excessWeightAnswerFa({
    required double heightCm,
    required double weightKg,
    required double bmi,
  }) {
    final maxHealthy = weightForBmi(heightCm: heightCm, bmi: healthyBmiMax);
    final minHealthy = weightForBmi(heightCm: heightCm, bmi: healthyBmiMin);
    final excess = double.parse((weightKg - maxHealthy).toStringAsFixed(1));
    final deficit = double.parse((minHealthy - weightKg).toStringAsFixed(1));

    if (bmi < 18.5) {
      return 'با قد ${heightCm.round()} سانتی‌متر و وزن ${_fmtKg(weightKg)} کیلو، '
          'حدود ${_fmtKg(deficit)} کیلو کمتر از کف محدودهٔ طبیعی BMI هستی '
          '(محدودهٔ تقریبی ${_fmtKg(minHealthy)} تا ${_fmtKg(maxHealthy)} کیلو). '
          'اضافه وزن نداری.';
    }
    if (bmi < 25) {
      return 'با قد ${heightCm.round()} سانتی‌متر و وزن ${_fmtKg(weightKg)} کیلو '
          '(BMI $bmi)، اضافه‌وزنی نسبت به سقف محدودهٔ طبیعی نداری. '
          'محدودهٔ تقریبی سالم برای قد تو حدود ${_fmtKg(minHealthy)} تا '
          '${_fmtKg(maxHealthy)} کیلو است.';
    }
    return 'با قد ${heightCm.round()} سانتی‌متر و وزن ${_fmtKg(weightKg)} کیلو '
        '(BMI $bmi)، حدود ${_fmtKg(excess)} کیلو اضافه وزن داری '
        '(نسبت به سقف محدودهٔ طبیعی حدود ${_fmtKg(maxHealthy)} کیلو). '
        'این برآورد بر اساس BMI است، نه درصد چربی دقیق.';
  }

  static String summaryFa({
    required double heightCm,
    required double weightKg,
    required double bmi,
    double? bodyFat,
  }) {
    final buffer = StringBuffer()
      ..write('قد ${heightCm.round()} سانتی‌متر، ')
      ..write('وزن ${_fmtKg(weightKg)} کیلو، ')
      ..write('BMI $bmi (${categoryFa(bmi)})');
    if (bodyFat != null && bodyFat > 0) {
      buffer.write('، چربی بدن حدود ${bodyFat.toStringAsFixed(1)}٪');
    }
    buffer.write('. ${overweightVerdictFa(bmi)}');

    final maxHealthy = weightForBmi(heightCm: heightCm, bmi: healthyBmiMax);
    final excess = weightKg - maxHealthy;
    if (excess >= 0.5) {
      buffer.write(
        ' تقریباً حدود ${_fmtKg(double.parse(excess.toStringAsFixed(1)))} '
        'کیلو بالاتر از سقف محدودهٔ طبیعی هستی.',
      );
    }
    return buffer.toString();
  }

  /// Picks the right local answer for body-composition questions.
  static String? answerForQuestion({
    required Map<String, Object?> enrichedProfile,
    required String userMessage,
    List<String> recentUserMessages = const <String>[],
  }) {
    final height = readDouble(enrichedProfile, heightKeys);
    final weight = readDouble(enrichedProfile, weightKeys);
    final bmiRaw = enrichedProfile['bmi'];
    final bmi = bmiRaw is num
        ? bmiRaw.toDouble()
        : double.tryParse(bmiRaw?.toString() ?? '');
    if (height == null || weight == null || bmi == null) return null;

    final text = userMessage.trim().toLowerCase();
    final recent =
        recentUserMessages.map((m) => m.trim().toLowerCase()).toList();
    final contextAboutExcess =
        recent.any(_mentionsExcessOrBmi) || _mentionsExcessOrBmi(text);

    if (_asksExcessKgAmount(text) ||
        (_asksHowManyKg(text) && contextAboutExcess)) {
      return excessWeightAnswerFa(
        heightCm: height,
        weightKg: weight,
        bmi: bmi,
      );
    }

    if (_asksCurrentWeightOnly(text) && !contextAboutExcess) {
      return 'وزن ثبت‌شده‌ات ${_fmtKg(weight)} کیلوگرم است.';
    }

    if (_asksYesNoOverweight(text)) {
      // Include kg estimate when overweight so the user does not need a follow-up.
      if (bmi >= 25) {
        return excessWeightAnswerFa(
          heightCm: height,
          weightKg: weight,
          bmi: bmi,
        );
      }
      return overweightVerdictFa(bmi);
    }

    final summary =
        enrichedProfile['body_metrics_summary_fa']?.toString().trim();
    if (summary != null && summary.isNotEmpty) return summary;
    return overweightVerdictFa(bmi);
  }

  static bool _mentionsExcessOrBmi(String text) {
    return text.contains('اضافه وزن') ||
        text.contains('اضافه‌وزن') ||
        text.contains('چاقی') ||
        text.contains('چاق') ||
        text.contains('bmi') ||
        text.contains('بی ام آی') ||
        text.contains('بی‌ام‌آی') ||
        text.contains('کمبود وزن');
  }

  static bool _asksExcessKgAmount(String text) {
    if (text.contains('چند کیلو اضافه') ||
        text.contains('چقدر اضافه وزن') ||
        text.contains('چه قدر اضافه وزن') ||
        text.contains('مقدار اضافه وزن') ||
        text.contains('میزان اضافه وزن') ||
        (text.contains('اضافه وزن') &&
            (text.contains('چند') ||
                text.contains('چقدر') ||
                text.contains('چه قدر')))) {
      return true;
    }
    return false;
  }

  static bool _asksHowManyKg(String text) {
    final t = text.replaceAll('؟', '').replaceAll('?', '').trim();
    return t == 'چند کیلو' ||
        t == 'چندکیلو' ||
        t == 'چقدر' ||
        t == 'چه قدر' ||
        t == 'چقد' ||
        t.startsWith('چند کیلو') ||
        t.startsWith('چقدر کیلو');
  }

  static bool _asksCurrentWeightOnly(String text) {
    return text.contains('وزنم چند') ||
        text.contains('وزن من چند') ||
        text.contains('چند کیلوام') ||
        text.contains('چند کیلو هستم') ||
        text == 'وزنم؟' ||
        text == 'وزنم';
  }

  static bool _asksYesNoOverweight(String text) {
    return text.contains('اضافه وزن دارم') ||
        text.contains('اضافه‌وزن دارم') ||
        text.contains('آیا اضافه وزن') ||
        text.contains('ایا اضافه وزن') ||
        text.contains('چاقم') ||
        text.contains('چاقم؟');
  }
}
