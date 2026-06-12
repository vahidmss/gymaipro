import 'package:gymaipro/config/app_config.dart';

/// تحلیل پیشرفت بدون LLM — گزارش فارسی از داده‌های واقعی کاربر.
class RuleBasedProgressAnalysisEngine {
  String buildReport(Map<String, dynamic> data) {
    final periodDays = data['period_days'] as int? ?? 30;
    final workoutStats = Map<String, dynamic>.from(
      data['workout_stats'] as Map? ?? {},
    );
    final weightStats = Map<String, dynamic>.from(
      data['weight_stats'] as Map? ?? {},
    );
    final weightHistory = (data['weight_history'] as List?) ?? [];
    final bodyMeasurements = Map<String, dynamic>.from(
      data['body_measurements'] as Map? ?? {},
    );
    final profile = Map<String, dynamic>.from(data['profile'] as Map? ?? {});

    final totalWorkouts = workoutStats['total_workouts'] as int? ?? 0;
    final totalSessions = workoutStats['total_sessions'] as int? ?? 0;
    final totalExercises = workoutStats['total_exercises'] as int? ?? 0;
    final avgPerWeek =
        (workoutStats['average_workouts_per_week'] as num?)?.toDouble() ?? 0;

    final buf = StringBuffer();
    buf.writeln('📊 گزارش پیشرفت شما ($periodDays روز گذشته)');
    buf.writeln('────────────────────────────');
    buf.writeln();

    buf.writeln(_sectionTraining(
      totalWorkouts: totalWorkouts,
      totalSessions: totalSessions,
      totalExercises: totalExercises,
      avgPerWeek: avgPerWeek,
      periodDays: periodDays,
    ));
    buf.writeln();

    buf.writeln(_sectionWeight(weightStats, weightHistory));
    buf.writeln();

    final bodySection = _sectionBody(bodyMeasurements, profile);
    if (bodySection.isNotEmpty) {
      buf.writeln(bodySection);
      buf.writeln();
    }

    buf.writeln(_sectionRecommendations(
      totalWorkouts: totalWorkouts,
      avgPerWeek: avgPerWeek,
      weightStats: weightStats,
      periodDays: periodDays,
    ));
    buf.writeln();
    buf.writeln(
      'ℹ️ این تحلیل با موتور علمی داخلی ${AppConfig.gymAiDisplayName} تهیه شده است.',
    );

    return buf.toString().trim();
  }

  String _sectionTraining({
    required int totalWorkouts,
    required int totalSessions,
    required int totalExercises,
    required double avgPerWeek,
    required int periodDays,
  }) {
    final buf = StringBuffer();
    buf.writeln('🏋️ تمرینات');
    if (totalWorkouts == 0) {
      buf.writeln(
        'در این بازه هیچ جلسهٔ ثبت‌شده‌ای ندارید. برای پیشرفت پایدار، هدف اول: حداقل ۲ جلسه در هفته.',
      );
      return buf.toString();
    }

    buf.writeln('• تعداد روزهای تمرین: $totalWorkouts');
    buf.writeln('• جلسات ثبت‌شده: $totalSessions');
    buf.writeln('• حرکات انجام‌شده: $totalExercises');
    buf.writeln(
      '• میانگین روز تمرین در هفته: ${avgPerWeek.toStringAsFixed(1)}',
    );

    if (avgPerWeek < 2) {
      buf.writeln(
        '\n📌 وضعیت: فرکانس تمرین پایین‌تر از حداقل پیشنهادی (۲ جلسه/هفته برای حفظ سطح).',
      );
    } else if (avgPerWeek >= 4) {
      buf.writeln(
        '\n✅ وضعیت: فرکانس تمرین خوب — برای پیشرفت عضلانی/قدرتی مناسب است.',
      );
    } else {
      buf.writeln(
        '\n✅ وضعیت: فرکانس متعادل — با ثبات در همین روند می‌توانید پیشرفت کنید.',
      );
    }

    if (totalSessions > 0 && totalExercises > 0) {
      final perSession = totalExercises / totalSessions;
      buf.writeln(
        '• میانگین حرکات در هر جلسه: ${perSession.toStringAsFixed(1)}',
      );
      if (perSession < 4) {
        buf.writeln(
          '  → حجم جلسات کم است؛ در صورت آمادگی، ۱–۲ حرکت بیشتر اضافه کنید.',
        );
      } else if (perSession > 8) {
        buf.writeln(
          '  → حجم جلسات بالا — به کیفیت و ریکاوری توجه کنید.',
        );
      }
    }

    return buf.toString();
  }

  String _sectionWeight(
    Map<String, dynamic> weightStats,
    List<dynamic> weightHistory,
  ) {
    final buf = StringBuffer();
    buf.writeln('⚖️ وزن و ترکیب بدن');

    final records = weightStats['total_records'] as int? ?? 0;
    if (records == 0 && weightHistory.isEmpty) {
      buf.writeln(
        'ثبت وزن در این بازه انجام نشده. هفتگی یک‌بار وزن ثابت (صبح ناشتا) به دقت روند کمک می‌کند.',
      );
      return buf.toString();
    }

    final avg = (weightStats['average_weight'] as num?)?.toDouble();
    final min = (weightStats['min_weight'] as num?)?.toDouble();
    final max = (weightStats['max_weight'] as num?)?.toDouble();
    final trend = (weightStats['trend'] as String?) ?? 'نامشخص';

    if (avg != null) {
      buf.writeln('• میانگین وزن: ${avg.toStringAsFixed(1)} کیلوگرم');
    }
    if (min != null && max != null) {
      buf.writeln(
        '• بازه: ${min.toStringAsFixed(1)} تا ${max.toStringAsFixed(1)} کیلوگرم',
      );
    }
    buf.writeln('• روند کلی: ${_trendLabel(trend)}');

    if (weightHistory.length >= 2) {
      final first = _weightFromRecord(weightHistory.last);
      final last = _weightFromRecord(weightHistory.first);
      if (first != null && last != null) {
        final delta = last - first;
        final sign = delta > 0 ? '+' : '';
        buf.writeln(
          '• تغییر در بازه: $sign${delta.toStringAsFixed(1)} کیلوگرم',
        );
        if (delta.abs() > 2) {
          buf.writeln(
            '  → نوسان محسوس — بررسی کنید آبیاری، خواب و کالری با هدف هم‌خوان باشد.',
          );
        }
      }
    }

    return buf.toString();
  }

  double? _weightFromRecord(dynamic record) {
    if (record is! Map) return null;
    final w = record['weight'];
    if (w is num) return w.toDouble();
    return double.tryParse(w?.toString() ?? '');
  }

  String _trendLabel(String trend) {
    final t = trend.toLowerCase();
    if (t.contains('up') || t.contains('صعود') || t.contains('افزایش')) {
      return 'افزایشی';
    }
    if (t.contains('down') || t.contains('نزول') || t.contains('کاهش')) {
      return 'کاهشی';
    }
    if (t.contains('stable') || t.contains('ثابت')) return 'تقریباً ثابت';
    return trend;
  }

  String _sectionBody(
    Map<String, dynamic> bodyMeasurements,
    Map<String, dynamic> profile,
  ) {
    if (bodyMeasurements.isEmpty && profile.isEmpty) return '';

    final buf = StringBuffer();
    buf.writeln('📏 اندازه‌ها');
    final bf = bodyMeasurements['body_fat_percentage'];
    if (bf is num) {
      buf.writeln('• درصد چربی تخمینی: ${bf.toStringAsFixed(1)}٪');
    }
    final muscle = bodyMeasurements['muscle_mass'];
    if (muscle is num) {
      buf.writeln('• توده عضلانی: ${muscle.toStringAsFixed(1)} کیلوگرم');
    }
    return buf.toString();
  }

  String _sectionRecommendations({
    required int totalWorkouts,
    required double avgPerWeek,
    required Map<String, dynamic> weightStats,
    required int periodDays,
  }) {
    final buf = StringBuffer();
    buf.writeln('💡 پیشنهادهای عملی (۷ روز آینده)');

    if (totalWorkouts == 0) {
      buf.writeln('۱. یک برنامه ۳ روزه از بخش برنامه‌ها بسازید یا انتخاب کنید.');
      buf.writeln('۲. وزن امروز را ثبت کنید.');
      buf.writeln('۳. خواب ۷+ ساعت را اولویت دهید.');
      return buf.toString();
    }

    if (avgPerWeek < 2) {
      buf.writeln('۱. هدف: حداقل ۲ جلسه در هفته — حتی ۳۵–۴۵ دقیقه کافی است.');
    } else {
      buf.writeln('۱. همان تعداد جلسات را حفظ کنید؛ کیفیت مهم‌تر از افزایش ناگهانی حجم است.');
    }

    buf.writeln('۲. در هر جلسه ۱ حرکت اصلی (اسکوات/پرس/زیربغل) را ثبت کنید تا پیشرفت قابل مقایسه شود.');

    final trend = (weightStats['trend'] as String?) ?? '';
    if (trend.contains('up') || trend.contains('صعود')) {
      buf.writeln('۳. روند وزن صعودی — اگر هدف چربی‌سوزی است، کالری و قدم‌روز را مرور کنید.');
    } else if (trend.contains('down') || trend.contains('نزول')) {
      buf.writeln('۳. روند وزن نزولی — اگر هدف حجم است، پروتئین و کالری کافی را چک کنید.');
    } else {
      buf.writeln('۳. ثبات وزن — برای تغییر ترکیب بدن، پروتئین کافی (~۱٫۶–۲٫۲ گرم/کیلو) را رعایت کنید.');
    }

    buf.writeln('۴. یک روز استراحت فعال (پیاده‌روی سبک) بین جلسات سنگین بگذارید.');

    if (periodDays >= 28 && avgPerWeek >= 3) {
      buf.writeln('۵. هر ۴–۶ هفته یک هفته دلود (کاهش ۳۰–۴۰٪ حجم) برای ریکاوری پیشنهاد می‌شود.');
    }

    return buf.toString();
  }
}
