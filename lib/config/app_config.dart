import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  /// Safe read from `.env` after dotenv.load; returns null if unset or not loaded.
  static String? dotenvValue(String key) {
    if (!dotenv.isInitialized) return null;
    final value = dotenv.env[key]?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  static String _envString(String key) {
    final fromDefine = String.fromEnvironment(key);
    if (fromDefine.isNotEmpty) return fromDefine;
    return dotenvValue(key) ?? '';
  }

  static bool _isTruthy(String value) {
    final normalized = value.toLowerCase().trim();
    return normalized == 'true' || normalized == '1';
  }

  /// Health endpoint used to decide if "online app backend" is reachable.
  ///
  /// Prefer setting BACKEND_HEALTHCHECK_URL in .env / --dart-define.
  /// Default is compatible with Supabase-compatible self-hosted auth.
  static String get backendHealthCheckUrl {
    const envUrl = String.fromEnvironment('BACKEND_HEALTHCHECK_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    final dotenvUrl = dotenvValue('BACKEND_HEALTHCHECK_URL');
    if (dotenvUrl != null) return dotenvUrl;
    return '${supabaseUrl.replaceFirst(RegExp(r'/$'), '')}/auth/v1/health';
  }

  // Supabase configuration
  static String get supabaseUrl {
    const envUrl = String.fromEnvironment('SUPABASE_URL');
    if (envUrl.isNotEmpty) {
      return _supabaseUrlWithExplicitPort(envUrl);
    }
    final dotenvUrl = dotenvValue('SUPABASE_URL');
    if (dotenvUrl != null) return _supabaseUrlWithExplicitPort(dotenvUrl);
    // Default fallback: production API domain.
    // This avoids web mixed-content failures when .env is missing on hosting.
    return _supabaseUrlWithExplicitPort('https://api.gymaipro.ir');
  }

  /// Dart reports port 0 for `wss://` without an explicit port, which breaks
  /// Realtime WebSocket (`https://host:0/...`). Keep `:443` / `:80` in the
  /// string so `replaceAll('http','ws')` yields `wss://host:443/...`.
  static String _supabaseUrlWithExplicitPort(String url) {
    final trimmed = url.trim().replaceFirst(RegExp(r'/$'), '');
    if (RegExp(r'^https://[^/:]+$').hasMatch(trimmed)) {
      return trimmed.replaceFirstMapped(
        RegExp(r'^https://([^/]+)'),
        (match) => 'https://${match.group(1)}:443',
      );
    }
    if (RegExp(r'^http://[^/:]+$').hasMatch(trimmed)) {
      return trimmed.replaceFirstMapped(
        RegExp(r'^http://([^/]+)'),
        (match) => 'http://${match.group(1)}:80',
      );
    }
    return trimmed;
  }

  static String get supabaseAnonKey {
    const envKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (envKey.isNotEmpty) {
      return envKey;
    }
    return dotenvValue('SUPABASE_ANON_KEY') ?? '';
  }

  /// اگر روی self-hosted هنوز Edge Functions راه نیفتاده، در .env بگذار false تا فراخوانی نشود.
  static bool get supabaseEdgeFunctionsEnabled {
    const env = String.fromEnvironment('SUPABASE_EDGE_FUNCTIONS_ENABLED');
    if (env.isNotEmpty) {
      return _isTruthy(env);
    }
    final v = dotenvValue('SUPABASE_EDGE_FUNCTIONS_ENABLED');
    if (v != null) return _isTruthy(v);
    return true;
  }

  /// FCM push — پیش‌فرض خاموش؛ درون‌برنامه‌ای همیشه فعال است.
  static bool get firebasePushEnabled {
    const env = String.fromEnvironment('FIREBASE_PUSH_ENABLED');
    if (env.isNotEmpty) {
      return _isTruthy(env);
    }
    final v = dotenvValue('FIREBASE_PUSH_ENABLED');
    if (v != null) return _isTruthy(v);
    return false;
  }

  /// پایه آدرس سایت وردپرس (بدون `/` انتهایی)، برای REST و لینک‌های نسبی.
  /// اگر موقتاً فقط HTTP در دسترس است، مثلاً `http://gymaipro.ir` در `.env` بگذارید.
  static String get wordpressApiOrigin {
    const envUrl = String.fromEnvironment('WORDPRESS_API_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl.replaceFirst(RegExp(r'/$'), '');
    }
    final dotenvUrl = dotenvValue('WORDPRESS_API_BASE_URL');
    if (dotenvUrl != null) {
      return dotenvUrl.replaceFirst(RegExp(r'/$'), '');
    }
    return 'https://gymaipro.ir';
  }

  /// مسیر کامل زیر دامنهٔ وردپرس، مثلاً `wordpressPath('wp-json/wp/v2/exercises')`.
  static String wordpressPath(String path) {
    final p = path.startsWith('/') ? path.substring(1) : path;
    return '$wordpressApiOrigin/$p';
  }

  // App configuration
  static const String appName = 'GymAI Pro';

  /// نام فارسی دستیار هوش مصنوعی (یکدست در UI)
  static const String gymAiDisplayName = 'جیم اِی آی';

  /// شناسه پروفایل مربی سیستم در Supabase (profiles.id).
  /// اگر در دیتابیس حساب `gymai_trainer` دارید، UUID آن را اینجا بگذارید.
  static String get aiTrainerProfileId {
    const env = String.fromEnvironment('AI_TRAINER_PROFILE_ID');
    if (env.isNotEmpty) return env;
    final v = dotenvValue('AI_TRAINER_PROFILE_ID');
    if (v != null) return v;
    return 'ddb977b5-0d39-4d9f-9a11-8dabbf301c02';
  }

  static const String appVersion = '1.0.0';

  static bool get onlinePaymentEnabled {
    const env = String.fromEnvironment('ONLINE_PAYMENT_ENABLED');
    if (env.isNotEmpty) {
      return _isTruthy(env);
    }
    final v = dotenvValue('ONLINE_PAYMENT_ENABLED');
    if (v != null) return _isTruthy(v);
    return true;
  }

  static String get supportPhone => _envString('SUPPORT_PHONE');

  static String get supportWhatsApp => _envString('SUPPORT_WHATSAPP');

  static String get supportTelegram => _envString('SUPPORT_TELEGRAM');

  // API configuration
  static const int apiTimeout = 30000; // 30 seconds
  static const int maxRetries = 3;

  /// مدل پیش‌فرض DeepSeek (Chat Completions — سازگار با OpenAI)
  static const String aiDefaultModel = 'deepseek-v4-flash';

  /// مدل قوی‌تر برای پرامپت‌های سنگین
  static const String aiReasoningModel = 'deepseek-v4-pro';

  /// اگر true باشد، درخواست‌های AI از طریق Edge Function روی api.gymaipro.ir
  /// به DeepSeek پروکسی می‌شوند (برای انتشار عمومی + امنیت کلید).
  /// پیش‌فرض false: هر دستگاه مستقیم به DeepSeek می‌زند (مناسب بتا/تست).
  static bool get openaiUseProxy {
    const env = String.fromEnvironment('OPENAI_USE_PROXY');
    if (env.isNotEmpty) {
      return _isTruthy(env);
    }
    final v = dotenvValue('OPENAI_USE_PROXY');
    if (v != null) return _isTruthy(v);
    return false;
  }

  /// مسیر فعلی: درخواست AI از خود گوشی (بدون وابستگی به نت بین‌الملل سرور).
  static bool get aiUsesDeviceDirectRoute =>
      !openaiUseProxy && openaiApiKey.isNotEmpty;

  /// آدرس مستقیم DeepSeek (فقط وقتی OPENAI_USE_PROXY=false)
  static String get openaiDirectBaseUrl {
    const env = String.fromEnvironment('OPENAI_BASE_URL');
    if (env.isNotEmpty) {
      return env.replaceFirst(RegExp(r'/$'), '');
    }
    const deepseekEnv = String.fromEnvironment('DEEPSEEK_BASE_URL');
    if (deepseekEnv.isNotEmpty) {
      return deepseekEnv.replaceFirst(RegExp(r'/$'), '');
    }
    final dotenvUrl =
        dotenvValue('OPENAI_BASE_URL') ?? dotenvValue('DEEPSEEK_BASE_URL');
    if (dotenvUrl != null) return dotenvUrl.replaceFirst(RegExp(r'/$'), '');
    return 'https://api.deepseek.com';
  }

  // DeepSeek / OpenAI-compatible API key (OPENAI_* نام legacy برای سازگاری)
  static String get openaiApiKey {
    const envKey = String.fromEnvironment('OPENAI_API_KEY');
    if (envKey.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('AppConfig: Using API key from --dart-define');
      }
      return envKey;
    }
    const deepseekKey = String.fromEnvironment('DEEPSEEK_API_KEY');
    if (deepseekKey.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('AppConfig: Using DeepSeek API key from --dart-define');
      }
      return deepseekKey;
    }
    final dotenvKey =
        dotenvValue('OPENAI_API_KEY') ?? dotenvValue('DEEPSEEK_API_KEY');
    if (dotenvKey != null) {
      if (kDebugMode) {
        debugPrint('AppConfig: Using API key from .env file');
      }
      return dotenvKey;
    }
    if (kDebugMode) {
      debugPrint('AppConfig: No API key found');
    }
    return '';
  }

  static String get aiChatUnavailableMessage {
    const env = String.fromEnvironment('AI_CHAT_UNAVAILABLE_MESSAGE');
    if (env.isNotEmpty) return env;
    final v = dotenvValue('AI_CHAT_UNAVAILABLE_MESSAGE');
    if (v != null) return v;
    return 'فعلاً چت با هوش مصنوعی در دسترس نیست!';
  }

  /// Insecure TLS fallback must be explicitly enabled.
  ///
  /// Default is `false` حتی در debug تا ریسک MITM کاهش پیدا کند.
  /// فقط برای محیط‌های کنترل‌شده توسعه فعال شود.
  static bool get allowInsecureTlsFallback {
    const env = String.fromEnvironment('ALLOW_INSECURE_TLS_FALLBACK');
    if (env.isNotEmpty) {
      return _isTruthy(env);
    }
    final v = dotenvValue('ALLOW_INSECURE_TLS_FALLBACK');
    if (v != null) return _isTruthy(v);
    return false;
  }

  // Payment gateway configuration
  static String get zibalMerchantId => _envString('ZIBAL_MERCHANT_ID');

  static String get zibalApiKey => _envString('ZIBAL_API_KEY');

  static String get zarinpalMerchantId => _envString('ZARINPAL_MERCHANT_ID');

  // Zibal requires callbackUrl domain to match merchant; use gymaipro.ir
  static const String zibalCallbackUrl = 'https://gymaipro.ir/payment/callback';

  // OTP/SMS configuration
  static String get smsApiBaseUrl {
    const envUrl = String.fromEnvironment('SMS_API_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    final dotenvUrl = dotenvValue('SMS_API_BASE_URL');
    if (dotenvUrl != null) return dotenvUrl;
    // Default fallback (should not be used in production)
    return 'https://rest.payamak-panel.com/api/SendSMS/BaseServiceNumber';
  }

  static String get smsApiUsername {
    const envUsername = String.fromEnvironment('SMS_API_USERNAME');
    if (envUsername.isNotEmpty) {
      return envUsername;
    }
    final dotenvUsername = dotenvValue('SMS_API_USERNAME');
    if (dotenvUsername != null) return dotenvUsername;
    if (kDebugMode) {
      debugPrint('AppConfig: SMS API username not found');
    }
    return '';
  }

  static String get smsApiPassword {
    const envPassword = String.fromEnvironment('SMS_API_PASSWORD');
    if (envPassword.isNotEmpty) {
      return envPassword;
    }
    final dotenvPassword = dotenvValue('SMS_API_PASSWORD');
    if (dotenvPassword != null) return dotenvPassword;
    if (kDebugMode) {
      debugPrint('AppConfig: SMS API password not found');
    }
    return '';
  }

  static int get smsApiBodyId {
    const envBodyId = String.fromEnvironment('SMS_API_BODY_ID');
    if (envBodyId.isNotEmpty) {
      final parsed = int.tryParse(envBodyId);
      if (parsed != null && parsed > 0) return parsed;
      if (kDebugMode) {
        debugPrint('AppConfig: Invalid SMS_API_BODY_ID format: $envBodyId');
      }
    }
    final dotenvBodyId = dotenvValue('SMS_API_BODY_ID');
    if (dotenvBodyId != null) {
      final parsed = int.tryParse(dotenvBodyId);
      if (parsed != null && parsed > 0) return parsed;
      if (kDebugMode) {
        debugPrint('AppConfig: Invalid SMS_API_BODY_ID format in .env');
      }
    }
    if (kDebugMode) {
      debugPrint('AppConfig: SMS API body ID not found');
    }
    return 0;
  }

  /// مربی: «{0} عزیز شما درخواست برنامه دارید…» — bodyId 450989
  static int get smsBodyIdTrainerProgramRequest =>
      _smsBodyIdFromEnv('SMS_BODY_ID_TRAINER_PROGRAM_REQUEST', 450989);

  /// کاربر: «با سلام {0} عزیز خرید برنامه برای شما ثبت شد…» — bodyId 450988
  static int get smsBodyIdUserProgramPurchase =>
      _smsBodyIdFromEnv('SMS_BODY_ID_USER_PROGRAM_PURCHASE', 450988);

  static int _smsBodyIdFromEnv(String key, int defaultValue) {
    final fromDefine = switch (key) {
      'SMS_BODY_ID_TRAINER_PROGRAM_REQUEST' =>
        const String.fromEnvironment('SMS_BODY_ID_TRAINER_PROGRAM_REQUEST'),
      'SMS_BODY_ID_USER_PROGRAM_PURCHASE' =>
        const String.fromEnvironment('SMS_BODY_ID_USER_PROGRAM_PURCHASE'),
      _ => '',
    };
    if (fromDefine.isNotEmpty) {
      final parsed = int.tryParse(fromDefine);
      if (parsed != null && parsed > 0) return parsed;
    }
    final fromDotenv = dotenvValue(key);
    if (fromDotenv != null) {
      final parsed = int.tryParse(fromDotenv);
      if (parsed != null && parsed > 0) return parsed;
    }
    return defaultValue;
  }

  // Activity levels
  static const Map<String, String> activityLevels = {
    'sedentary': 'کم تحرک (کار پشت میز)',
    'lightly_active': 'کم فعال (ورزش سبک 1-3 روز در هفته)',
    'moderately_active': 'نسبتاً فعال (ورزش متوسط 3-5 روز در هفته)',
    'very_active': 'خیلی فعال (ورزش سنگین 6-7 روز در هفته)',
    'extra_active': 'فوق فعال (ورزش خیلی سنگین و کار فیزیکی)',
  };

  // Fitness goals
  static const Map<String, String> fitnessGoals = {
    'weight_loss': 'کاهش وزن',
    'muscle_gain': 'افزایش حجم عضلات',
    'strength': 'افزایش قدرت',
    'endurance': 'افزایش استقامت',
    'flexibility': 'افزایش انعطاف‌پذیری',
    'general_fitness': 'تناسب اندام عمومی',
  };

  // Muscle groups
  static const Map<String, String> muscleGroups = {
    'chest': 'سینه',
    'back': 'پشت',
    'shoulders': 'شانه',
    'legs': 'پا',
    'arms': 'بازو',
    'abs': 'شکم',
  };

  // Equipment types
  static const Map<String, String> equipmentTypes = {
    'barbell': 'هالتر',
    'dumbbell': 'دمبل',
    'machine': 'دستگاه',
    'bodyweight': 'وزن بدن',
    'cable': 'کابل',
    'kettlebell': 'کتل‌بل',
    'resistance_band': 'کش',
  };

  // Difficulty levels
  static const Map<String, String> difficultyLevels = {
    'beginner': 'مبتدی',
    'intermediate': 'متوسط',
    'advanced': 'پیشرفته',
  };

  // Gender options
  static const Map<String, String> genderOptions = {
    'male': 'مرد',
    'female': 'زن',
  };

  // BMI categories
  static const Map<String, Map<String, dynamic>> bmiCategories = {
    'underweight': {
      'name': 'کمبود وزن',
      'range': '< 18.5',
      'color': 0xFFFFA726,
      'description': 'نیاز به افزایش وزن',
    },
    'normal': {
      'name': 'نرمال',
      'range': '18.5 - 24.9',
      'color': 0xFF66BB6A,
      'description': 'وزن سالم',
    },
    'overweight': {
      'name': 'اضافه وزن',
      'range': '25 - 29.9',
      'color': 0xFFEF5350,
      'description': 'نیاز به کاهش وزن',
    },
    'obese': {
      'name': 'چاقی',
      'range': '≥ 30',
      'color': 0xFFD32F2F,
      'description': 'نیاز به کاهش وزن جدی',
    },
  };

  // Body fat percentage categories
  static const Map<String, Map<String, dynamic>> bodyFatCategories = {
    'essential': {
      'name': 'چربی ضروری',
      'male_range': '2-5%',
      'female_range': '10-13%',
      'description': 'حداقل چربی مورد نیاز بدن',
    },
    'athletes': {
      'name': 'ورزشکاری',
      'male_range': '6-13%',
      'female_range': '14-20%',
      'description': 'سطح چربی ورزشکاران',
    },
    'fitness': {
      'name': 'تناسب اندام',
      'male_range': '14-17%',
      'female_range': '21-24%',
      'description': 'سطح چربی افراد ورزشکار',
    },
    'acceptable': {
      'name': 'قابل قبول',
      'male_range': '18-24%',
      'female_range': '25-31%',
      'description': 'سطح چربی نرمال',
    },
    'obese': {
      'name': 'چاقی',
      'male_range': '≥25%',
      'female_range': '≥32%',
      'description': 'نیاز به کاهش چربی',
    },
  };

  static const Map<String, String> experienceLevels = {
    'beginner': 'مبتدی',
    'intermediate': 'متوسط',
    'advanced': 'پیشرفته',
    'expert': 'حرفه‌ای',
  };

  static const Map<String, String> weekDays = {
    'saturday': 'شنبه',
    'sunday': 'یکشنبه',
    'monday': 'دوشنبه',
    'tuesday': 'سه‌شنبه',
    'wednesday': 'چهارشنبه',
    'thursday': 'پنجشنبه',
    'friday': 'جمعه',
  };

  static const Map<String, String> trainingTimes = {
    'morning': 'صبح',
    'afternoon': 'بعد از ظهر',
    'evening': 'عصر',
    'night': 'شب',
  };

  static const Map<String, String> medicalConditions = {
    'none': 'هیچکدام',
    'back_pain': 'کمردرد',
    'knee_pain': 'درد زانو',
    'shoulder_pain': 'درد شانه',
    'diabetes': 'دیابت',
    'heart_condition': 'مشکلات قلبی',
    'high_blood_pressure': 'فشار خون بالا',
    'asthma': 'آسم',
  };

  static const Map<String, String> dietaryPreferences = {
    'none': 'بدون محدودیت',
    'vegetarian': 'گیاهخواری',
    'vegan': 'وگان',
    'keto': 'کتوژنیک',
    'low_carb': 'کم کربوهیدرات',
    'gluten_free': 'بدون گلوتن',
    'lactose_free': 'بدون لاکتوز',
  };
}
