import 'package:gymaipro/models/exercise.dart';

/// Soft popularity signals for Iranian commercial-gym staples.
///
/// Used only to rank the catalog shown to the LLM — never to hardcode a program.
abstract final class LlmIranGymPopularity {
  const LlmIranGymPopularity._();

  /// Higher = more familiar in typical Iranian club / free-program culture.
  static int score(Exercise exercise) {
    final name = exercise.name.trim().toLowerCase();
    if (name.isEmpty) return 0;

    var score = 0;

    // Social / catalog popularity when available.
    score += (exercise.likes.clamp(0, 200) / 10).floor();

    for (final token in _highFamiliarity) {
      if (name.contains(token)) score += 12;
    }
    for (final token in _mediumFamiliarity) {
      if (name.contains(token)) score += 6;
    }
    for (final token in _nichePenalty) {
      if (name.contains(token)) score -= 10;
    }

    // Prefer simple equipment wording people recognize in clubs.
    final eq = exercise.equipment.toLowerCase();
    if (eq.contains('هالتر') || eq.contains('دمبل') || eq.contains('دستگاه')) {
      score += 2;
    }
    if (eq.contains('کابل') || eq.contains('سیم')) score += 2;

    // Slight preference for clearer difficulty for most users.
    final diff = exercise.difficulty;
    if (diff.contains('مبتدی') || diff.contains('متوسط')) score += 1;
    if (diff.contains('پیشرفته') || diff.contains('حرفه')) score -= 2;

    return score;
  }

  /// Tokens that appear constantly in free Iranian gym templates.
  static const List<String> _highFamiliarity = <String>[
    'پرس سینه',
    'بالا سینه',
    'بالاسینه',
    'کراس اور',
    'کrossover',
    'قفسه سینه',
    'اسکوات',
    'اسکات',
    'پرس پا',
    'ددلیفت',
    'رومانیایی',
    'بارفیکس',
    'لت پول',
    'لت‌پول',
    'زیربغل سیم',
    'زیربغل سیمکش',
    'قایقی',
    'رویینگ',
    'پرس سرشانه',
    'نشر جانب',
    'نشر از جانب',
    'جلو بازو',
    'پشت بازو سیم',
    'پشت بازو سیمکش',
    'لانج',
    'لانگز',
    'هیپ تراست',
    'پل باسن',
    'ساق',
    'کرانچ',
    'پلانک',
    'زیرشکم',
  ];

  static const List<String> _mediumFamiliarity = <String>[
    'پرس',
    'فلای',
    'قفسه',
    'دیپ',
    'شنا سوئدی',
    'پول اور',
    'فیس پول',
    'شراگ',
    'جلو پا',
    'پشت پا',
    'چرخش روسی',
    'بورپی',
    'طناب',
    'دوچرخه ثابت',
    'الپتیکال',
    'تردمیل',
  ];

  /// Unusual / advanced variants that confuse average club users.
  static const List<String> _nichePenalty = <String>[
    'آرچر',
    'مدوز',
    'نوردیک',
    'کوزاک',
    'اسکی',
    'سوندر',
    'لندماین',
    'تراپ بار',
    'بلوک',
    'رک ',
    'استرالیایی',
    'حلقه',
    'اسپایدر',
    'پالوف',
  ];
}

/// Persian coach guidance based on what Iranian free programs usually look like.
abstract final class LlmIranGymStyleGuide {
  const LlmIranGymStyleGuide._();

  static String splitGuidance({
    required int daysPerWeek,
    required String experience,
    required List<String> goals,
  }) {
    final isBeginner =
        experience.contains('مبتدی') || experience.toLowerCase().contains('beginner');
    final isAdvanced =
        experience.contains('پیشرفته') ||
        experience.contains('حرفه') ||
        experience.toLowerCase().contains('advanced');
    final fatLoss = goals.any(
      (g) => g.contains('چربی') || g.toLowerCase().contains('fat'),
    );

    final buffer = StringBuffer()
      ..writeln(
        'در باشگاه‌های ایران و برنامه‌های رایگان رایج، مردم این سبک‌ها را '
        'بیشتر می‌پسندند و می‌فهمند:',
      )
      ..writeln(
        '- مبتدی ۳ روز: تمام‌بدن با حرکات پایه (پرس سینه، اسکوات/پرس پا، '
        'زیربغل/بارفیکس، سرشانه، بازو، شکم) — هر روز ۵ تا ۶ حرکت، بین روزها '
        'تنوع حرکت ولی همان ساختار آشنا.',
      )
      ..writeln(
        '- متوسط ۳ روز: فشار / کشش / پا (PPL) با ۵ تا ۷ حرکت؛ روز فشار = '
        'سینه+سرشانه+پشت‌بازو؛ کشش = پشت+جلوبازو؛ پا = اسکوات/پرس‌پا+پشت‌پا+ساق+شکم.',
      )
      ..writeln(
        '- ۴ روز: بالاتنه / پایین‌تنه (هر کدام ۲ بار در هفته).',
      )
      ..writeln(
        '- ۵–۶ روز: اسپلیت عضلانی کلاسیک ایرانی '
        '(مثلاً سینه+پشت‌بازو، پشت+جلوبازو، پا، سرشانه، اختیاری بازو/شکم).',
      )
      ..writeln(
        '- چربی‌سوزی: ستون اصلی همان تمرین مقاومتی باشگاهی است؛ کاردیو کوتاه '
        '(۱۰–۲۰ دقیقه) در انتهای جلسات — نه یک روز فقط با ۲–۳ حرکت عجیب.',
      )
      ..writeln();

    if (daysPerWeek <= 3 && isBeginner) {
      buffer.writeln(
        'برای این کاربر: اسپلیت پیشنهادی = تمام‌بدن ۳ روزه با حرکات رایج باشگاهی.',
      );
    } else if (daysPerWeek == 3) {
      buffer.writeln(
        'برای این کاربر: اسپلیت پیشنهادی = فشار / کشش / پا با برچسب‌های فارسی '
        'واضح (مثلاً «روز فشار — سینه و سرشانه»).',
      );
    } else if (daysPerWeek == 4) {
      buffer.writeln(
        'برای این کاربر: اسپلیت پیشنهادی = بالاتنه / پایین‌تنه با نام‌های یکتا '
        '(روز ۱ — بالاتنه ۱، روز ۲ — پایین‌تنه ۱، روز ۳ — بالاتنه ۲، روز ۴ — پایین‌تنه ۲). '
        'هرگز دو جلسه را فقط «فشار» یا فقط «بالاتنه» نام نگذار.',
      );
    } else if (daysPerWeek >= 5) {
      buffer.writeln(
        isAdvanced
            ? 'برای این کاربر: اسپلیت عضلانی کلاسیک باشگاهی ایران.'
            : 'برای این کاربر: اسپلیت عضلانی ساده و آشنا برای باشگاه ایران.',
      );
    }

    if (fatLoss) {
      buffer.writeln(
        'هدف چربی‌سوزی: حجم مقاومتی کافی + در صورت تمایل یک حرکت کاردیو '
        'زمان‌محور در پایان هر روز (نه جایگزین کل جلسه).',
      );
    }

    buffer
      ..writeln()
      ..writeln(
        'اولویت انتخاب حرکت: از میان فهرست، ترجیحاً مواردی که با ★ رایج علامت '
        'خورده‌اند (پرس سینه هالتر/دمبل/دستگاه، کراس‌اور، اسکوات، پرس پا، '
        'زیربغل سیم‌کش، قایقی، بارفیکس، پرس سرشانه، جلوبازو/پشت‌بازو سیم‌کش و …). '
        'حرکات نادر و نام‌های عجیب را فقط وقتی انتخاب کن که جایگزین رایج‌تری '
        'در فهرست نباشد. برنامه را با لیست ثابت هاردکد نکن؛ از idهای همین فهرست انتخاب کن.\n'
        'نام برنامه را طبیعی بگذار؛ هرگز داخل اسم ننویس «حرکات آشنا/پایه/رایج».',
      );

    return buffer.toString();
  }
}
