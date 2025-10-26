class AppConfig {
  // Supabase configuration
  static const String supabaseUrl = 'https://oaztoennovtcfcxvnswa.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9henRvZW5ub3Z0Y2ZjeHZuc3dhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY4NzYzNzEsImV4cCI6MjA2MjQ1MjM3MX0.UywfAvKyqUjByLQHRnRqJ85Bal6NdvAOwQQJXVaQfGk';

  // App configuration
  static const String appName = 'GymAI Pro';
  static const String appVersion = '1.0.0';

  // API configuration
  static const int apiTimeout = 30000; // 30 seconds
  static const int maxRetries = 3;

  // OpenAI configuration
  static const String openaiApiKey = String.fromEnvironment('OPENAI_API_KEY');

  // Payment gateway configuration
  static const String zibalMerchantId = String.fromEnvironment(
    'ZIBAL_MERCHANT_ID',
  );
  static const String zibalApiKey = String.fromEnvironment('ZIBAL_API_KEY');
  static const String zarinpalMerchantId = String.fromEnvironment(
    'ZARINPAL_MERCHANT_ID',
  );
  // Zibal requires callbackUrl domain to match merchant; use gymaipro.ir
  static const String zibalCallbackUrl = 'https://gymaipro.ir/payment/callback';

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
