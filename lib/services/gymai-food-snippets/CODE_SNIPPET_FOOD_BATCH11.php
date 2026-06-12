// GymAI Foods — BATCH 11 (خوراکی 101–110)
// Code Snippets: Run everywhere | بدون تگ php
// یا کپی در: wp-content/gymai-seed/food-batch11.php

if (!function_exists('gymai_food_batch11_definitions')) {
    function gymai_food_batch11_definitions() {
        static $cache = null;
        if ($cache !== null) {
            return $cache;
        }
        $cache = json_decode(<<<'GYMAI_FOOD_BATCH11'
[
  {
    "slug": "پودر-وی-پروتئین",
    "title": "پودر وی پروتئین",
    "excerpt": "مرجع علمی پودر وی پروتئین: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "مکمل‌ها",
    "rank_math_title": "پودر وی پروتئین | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای پودر وی پروتئین در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "پودر وی پروتئین",
    "name_app": "پودر وی پروتئین",
    "other_names": "وی, Whey protein",
    "food_group": "مکمل",
    "food_type": "solid",
    "meal_times": "صبحانه,بعد تمرین,میان‌وعده",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "scoop",
    "protein": "78",
    "calories": "380",
    "carbohydrates": "8",
    "fat": "4.0",
    "saturated_fat": "1.4",
    "fiber": "0",
    "sugar": "1.0",
    "cholesterol": "0",
    "sodium": "180",
    "potassium": "520",
    "glycemic_index": "0",
    "allergens": "لبنیات",
    "short_description": "پودر وی پروتئین سریع‌جذب؛ پرکاربرد بعد از تمرین و بین وعده‌ها.",
    "serving_notes": "ارزش‌ها برای پودر وی پروتئین در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "با آب یا شیر کم‌چرب مخلوط کنید.",
    "tip_2": "یک اسکوپ معمولاً ۲۵–۳۰ گرم پودر است.",
    "tip_3": "در کسری کالری جایگزین یک وعده پروتئین.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "scoop",
      "units": [
        {
          "key": "scoop",
          "label": "اسکوپ",
          "grams": 30,
          "step": 0.5,
          "decimals": 1,
          "is_primary": true,
          "hint": "حدود ۳۰ گرم پودر"
        },
        {
          "key": "gram",
          "label": "گرم",
          "grams": 1,
          "step": 1,
          "decimals": 0,
          "is_primary": false,
          "hint": ""
        }
      ]
    },
    "legacy_slug": "whey-protein-powder",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1498837167922-ddd27525b352?w=800&q=80",
    "aliases_en": [
      "Whey protein powder",
      "Whey"
    ],
    "related_slugs": [
      "پروتئین-بار",
      "پودر-کراتین-مونوهیدرات",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "وی شاخص‌ترین مکمل پروتئینی در بدنسازی است.",
    "substitutes": [
      {
        "slug": "پروتئین-بار",
        "ratio": 1.0
      },
      {
        "slug": "پودر-کراتین-مونوهیدرات",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "شیر-کم‌چرب",
    "title": "شیر کم‌چرب",
    "excerpt": "مرجع علمی شیر کم‌چرب: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "لبنیات",
    "rank_math_title": "شیر کم‌چرب | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای شیر کم‌چرب در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "شیر کم‌چرب",
    "name_app": "شیر کم‌چرب",
    "other_names": "شیر, Milk",
    "food_group": "لبنیات",
    "food_type": "liquid",
    "meal_times": "صبحانه,میان‌وعده,بعد تمرین",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "3.4",
    "calories": "42",
    "carbohydrates": "5",
    "fat": "1.0",
    "saturated_fat": "0.3",
    "fiber": "0",
    "sugar": "0.6",
    "cholesterol": "15",
    "sodium": "44",
    "potassium": "150",
    "glycemic_index": "30",
    "allergens": "لبنیات",
    "short_description": "شیر کم‌چرب پروتئین، کلسیم و کربوهیدرات؛ پایه شیک پروتئین.",
    "serving_notes": "ارزش‌ها برای شیر کم‌چرب در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "یک لیوان حدود ۲۴۰ میلی‌لیتر.",
    "tip_2": "با وی یا کاکائو کم‌قند ترکیب شود.",
    "tip_3": "برای حجم‌گیری در صبحانه مناسب است.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "cup",
      "units": [
        {
          "key": "cup",
          "label": "لیوان",
          "grams": 240,
          "step": 0.5,
          "decimals": 1,
          "is_primary": true,
          "hint": ""
        },
        {
          "key": "tablespoon",
          "label": "قاشق غذاخوری",
          "grams": 15,
          "step": 0.5,
          "decimals": 1,
          "is_primary": false,
          "hint": ""
        },
        {
          "key": "gram",
          "label": "گرم",
          "grams": 1,
          "step": 1,
          "decimals": 0,
          "is_primary": false,
          "hint": ""
        }
      ]
    },
    "legacy_slug": "skim-milk",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80",
    "aliases_en": [
      "Skim milk",
      "Low fat milk"
    ],
    "related_slugs": [
      "ماست-یونانی-کم‌چرب",
      "پنیر-سفید-کم‌چرب",
      "نان-سنگک-کامل"
    ],
    "intro": "شیر یکی از ساده‌ترین منابع پروتئین مایع است.",
    "substitutes": [
      {
        "slug": "ماست-یونانی-کم‌چرب",
        "ratio": 1.0
      },
      {
        "slug": "پنیر-سفید-کم‌چرب",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "سینه-بوقلمون-گریل",
    "title": "سینه بوقلمون گریل",
    "excerpt": "مرجع علمی سینه بوقلمون گریل: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "پروتئین‌ها",
    "rank_math_title": "سینه بوقلمون گریل | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای سینه بوقلمون گریل در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "سینه بوقلمون گریل",
    "name_app": "سینه بوقلمون گریل",
    "other_names": "بوقلمون, Turkey",
    "food_group": "پروتئین",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "palm_protein",
    "protein": "30",
    "calories": "135",
    "carbohydrates": "0",
    "fat": "1.0",
    "saturated_fat": "0.3",
    "fiber": "0",
    "sugar": "0",
    "cholesterol": "15",
    "sodium": "55",
    "potassium": "290",
    "glycemic_index": "0",
    "allergens": "",
    "short_description": "سینه بوقلمون کم‌چرب و پروتئین بالا؛ جایگزین مرغ در کات.",
    "serving_notes": "ارزش‌ها برای سینه بوقلمون گریل در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "بدون پوست گریل شود.",
    "tip_2": "با برنج یا سیب‌زمینی ترکیب کنید.",
    "tip_3": "برش نازک از خشکی جلوگیری می‌کند.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "palm_protein",
      "units": [
        {
          "key": "palm_protein",
          "label": "کف دست (پروتئین)",
          "grams": 85,
          "step": 0.5,
          "decimals": 1,
          "is_primary": true,
          "hint": "یک وعده پروتئین"
        },
        {
          "key": "gram",
          "label": "گرم",
          "grams": 1,
          "step": 1,
          "decimals": 0,
          "is_primary": false,
          "hint": ""
        }
      ]
    },
    "legacy_slug": "grilled-turkey-breast",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80",
    "aliases_en": [
      "Grilled turkey breast",
      "Turkey breast"
    ],
    "related_slugs": [
      "سینه-مرغ-گریل-شده",
      "تخم‌مرغ-آب‌پز",
      "نان-سنگک-کامل"
    ],
    "intro": "بوقلمون در رژیم‌های کم‌چربی بسیار رایج است.",
    "substitutes": [
      {
        "slug": "سینه-مرغ-گریل-شده",
        "ratio": 1.0
      },
      {
        "slug": "تخم‌مرغ-آب‌پز",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "ماهی-سالمون-گریل",
    "title": "ماهی سالمون گریل",
    "excerpt": "مرجع علمی ماهی سالمون گریل: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "پروتئین‌ها",
    "rank_math_title": "ماهی سالمون گریل | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای ماهی سالمون گریل در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "ماهی سالمون گریل",
    "name_app": "ماهی سالمون گریل",
    "other_names": "سالمون, Salmon",
    "food_group": "پروتئین",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "palm_protein",
    "protein": "22",
    "calories": "206",
    "carbohydrates": "0",
    "fat": "12.0",
    "saturated_fat": "4.2",
    "fiber": "0",
    "sugar": "0",
    "cholesterol": "15",
    "sodium": "59",
    "potassium": "384",
    "glycemic_index": "0",
    "allergens": "ماهی",
    "short_description": "سالمون پروتئین و امگا۳؛ برای ریکاوری و سلامت قلب.",
    "serving_notes": "ارزش‌ها برای ماهی سالمون گریل در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "بدون روغن اضافه در فر یا گریل.",
    "tip_2": "هفته‌ای ۲ وعده ماهی چرب توصیه می‌شود.",
    "tip_3": "با سبزیجات بخارپز سرو شود.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "palm_protein",
      "units": [
        {
          "key": "palm_protein",
          "label": "کف دست (پروتئین)",
          "grams": 85,
          "step": 0.5,
          "decimals": 1,
          "is_primary": true,
          "hint": "یک وعده پروتئین"
        },
        {
          "key": "gram",
          "label": "گرم",
          "grams": 1,
          "step": 1,
          "decimals": 0,
          "is_primary": false,
          "hint": ""
        }
      ]
    },
    "legacy_slug": "grilled-salmon",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800&q=80",
    "aliases_en": [
      "Grilled salmon",
      "Salmon"
    ],
    "related_slugs": [
      "سینه-مرغ-گریل-شده",
      "تخم‌مرغ-آب‌پز",
      "نان-سنگک-کامل"
    ],
    "intro": "سالمون از منابع برتر امگا۳ در تغذیه ورزشی است.",
    "substitutes": [
      {
        "slug": "سینه-مرغ-گریل-شده",
        "ratio": 1.0
      },
      {
        "slug": "تخم‌مرغ-آب‌پز",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "استیک-گوساله-گریل",
    "title": "استیک گوساله گریل",
    "excerpt": "مرجع علمی استیک گوساله گریل: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "پروتئین‌ها",
    "rank_math_title": "استیک گوساله گریل | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای استیک گوساله گریل در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "استیک گوساله گریل",
    "name_app": "استیک گوساله گریل",
    "other_names": "استیک, Steak",
    "food_group": "پروتئین",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "palm_protein",
    "protein": "26",
    "calories": "271",
    "carbohydrates": "0",
    "fat": "18.0",
    "saturated_fat": "6.3",
    "fiber": "0",
    "sugar": "0",
    "cholesterol": "15",
    "sodium": "54",
    "potassium": "315",
    "glycemic_index": "0",
    "allergens": "",
    "short_description": "استیک گوساله منبع کراتین و آهن؛ برای حجم‌گیری.",
    "serving_notes": "ارزش‌ها برای استیک گوساله گریل در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "برش کم‌چرب انتخاب کنید.",
    "tip_2": "چربی اضافه در تفت را در نظر بگیرید.",
    "tip_3": "با سالاد یا سبزیجات کبابی.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "palm_protein",
      "units": [
        {
          "key": "palm_protein",
          "label": "کف دست (پروتئین)",
          "grams": 85,
          "step": 0.5,
          "decimals": 1,
          "is_primary": true,
          "hint": "یک وعده پروتئین"
        },
        {
          "key": "gram",
          "label": "گرم",
          "grams": 1,
          "step": 1,
          "decimals": 0,
          "is_primary": false,
          "hint": ""
        }
      ]
    },
    "legacy_slug": "grilled-beef-steak",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80",
    "aliases_en": [
      "Grilled beef steak",
      "Beef steak"
    ],
    "related_slugs": [
      "سینه-مرغ-گریل-شده",
      "تخم‌مرغ-آب‌پز",
      "نان-سنگک-کامل"
    ],
    "intro": "گوشت قرمز در دوره حجم جایگاه مشخصی دارد.",
    "substitutes": [
      {
        "slug": "سینه-مرغ-گریل-شده",
        "ratio": 1.0
      },
      {
        "slug": "تخم‌مرغ-آب‌پز",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "سفیده-تخم‌مرغ",
    "title": "سفیده تخم‌مرغ",
    "excerpt": "مرجع علمی سفیده تخم‌مرغ: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "پروتئین‌ها",
    "rank_math_title": "سفیده تخم‌مرغ | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای سفیده تخم‌مرغ در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "سفیده تخم‌مرغ",
    "name_app": "سفیده تخم‌مرغ",
    "other_names": "سفیده, Egg white",
    "food_group": "پروتئین",
    "food_type": "solid",
    "meal_times": "صبحانه,میان‌وعده",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "piece",
    "protein": "11",
    "calories": "52",
    "carbohydrates": "0.7",
    "fat": "0.2",
    "saturated_fat": "0.1",
    "fiber": "0",
    "sugar": "0.1",
    "cholesterol": "15",
    "sodium": "166",
    "potassium": "163",
    "glycemic_index": "0",
    "allergens": "تخم‌مرغ",
    "short_description": "سفیده تخم‌مرغ پروتئین خالص با چربی ناچیز؛ محبوب در کات.",
    "serving_notes": "ارزش‌ها برای سفیده تخم‌مرغ در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "هر سفیده بزرگ حدود ۳۳ گرم.",
    "tip_2": "با یک زرده برای ویتامین‌ها ترکیب کنید.",
    "tip_3": "املت سفیده با سبزیجات.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "piece",
      "units": [
        {
          "key": "piece",
          "label": "عدد",
          "grams": 50,
          "step": 1,
          "decimals": 0,
          "is_primary": true,
          "hint": "یک عدد بزرگ"
        },
        {
          "key": "gram",
          "label": "گرم",
          "grams": 1,
          "step": 1,
          "decimals": 0,
          "is_primary": false,
          "hint": ""
        }
      ]
    },
    "legacy_slug": "egg-white",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1482049016688-a7bd8fa7e6a1?w=800&q=80",
    "aliases_en": [
      "Egg white",
      "Egg whites"
    ],
    "related_slugs": [
      "سینه-مرغ-گریل-شده",
      "تخم‌مرغ-آب‌پز",
      "نان-سنگک-کامل"
    ],
    "intro": "سفیده گزینه کلاسیک پروتئین کم‌کالری است.",
    "substitutes": [
      {
        "slug": "سینه-مرغ-گریل-شده",
        "ratio": 1.0
      },
      {
        "slug": "تخم‌مرغ-آب‌پز",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "ژامبون-مرغ-کم‌نمک",
    "title": "ژامبون مرغ کم‌نمک",
    "excerpt": "مرجع علمی ژامبون مرغ کم‌نمک: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "پروتئین‌ها",
    "rank_math_title": "ژامبون مرغ کم‌نمک | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای ژامبون مرغ کم‌نمک در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "ژامبون مرغ کم‌نمک",
    "name_app": "ژامبون مرغ کم‌نمک",
    "other_names": "ژامبون مرغ, Chicken ham",
    "food_group": "پروتئین",
    "food_type": "solid",
    "meal_times": "صبحانه,میان‌وعده",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "palm_protein",
    "protein": "18",
    "calories": "105",
    "carbohydrates": "2",
    "fat": "3.0",
    "saturated_fat": "1.0",
    "fiber": "0",
    "sugar": "0.2",
    "cholesterol": "15",
    "sodium": "680",
    "potassium": "220",
    "glycemic_index": "0",
    "allergens": "",
    "short_description": "ژامبون مرغ سریع برای ساندویچ پروتئینی؛ سدیم را کنترل کنید.",
    "serving_notes": "ارزش‌ها برای ژامبون مرغ کم‌نمک در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "نسخه کم‌نمک انتخاب کنید.",
    "tip_2": "با نان تست و سبزیجات.",
    "tip_3": "جایگزین سریع بین وعده‌ها.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "palm_protein",
      "units": [
        {
          "key": "palm_protein",
          "label": "کف دست (پروتئین)",
          "grams": 85,
          "step": 0.5,
          "decimals": 1,
          "is_primary": true,
          "hint": "یک وعده پروتئین"
        },
        {
          "key": "gram",
          "label": "گرم",
          "grams": 1,
          "step": 1,
          "decimals": 0,
          "is_primary": false,
          "hint": ""
        }
      ]
    },
    "legacy_slug": "chicken-deli-slice",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800&q=80",
    "aliases_en": [
      "Chicken deli slice",
      "Chicken ham"
    ],
    "related_slugs": [
      "سینه-مرغ-گریل-شده",
      "تخم‌مرغ-آب‌پز",
      "نان-سنگک-کامل"
    ],
    "intro": "ژامبون مرغ در برنامه‌های عملی مربیان رایج است.",
    "substitutes": [
      {
        "slug": "سینه-مرغ-گریل-شده",
        "ratio": 1.0
      },
      {
        "slug": "تخم‌مرغ-آب‌پز",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "پنیر-پیتزایی-کم‌چرب",
    "title": "پنیر پیتزایی کم‌چرب",
    "excerpt": "مرجع علمی پنیر پیتزایی کم‌چرب: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "لبنیات",
    "rank_math_title": "پنیر پیتزایی کم‌چرب | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای پنیر پیتزایی کم‌چرب در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "پنیر پیتزایی کم‌چرب",
    "name_app": "پنیر پیتزایی کم‌چرب",
    "other_names": "پنیر پیتزایی, Mozzarella",
    "food_group": "لبنیات",
    "food_type": "solid",
    "meal_times": "صبحانه,میان‌وعده",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "28",
    "calories": "195",
    "carbohydrates": "3",
    "fat": "7.0",
    "saturated_fat": "2.4",
    "fiber": "0",
    "sugar": "0.4",
    "cholesterol": "15",
    "sodium": "620",
    "potassium": "120",
    "glycemic_index": "0",
    "allergens": "لبنیات",
    "short_description": "پنیر پیتزایی کم‌چرب پروتئین بالا؛ برای کات و میان‌وعده.",
    "serving_notes": "ارزش‌ها برای پنیر پیتزایی کم‌چرب در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "۳۰–۴۰ گرم در هر وعده.",
    "tip_2": "با خیار یا گوجه.",
    "tip_3": "سدیم را در کل روز ببینید.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "cup",
      "units": [
        {
          "key": "cup",
          "label": "پیمانه",
          "grams": 150,
          "step": 0.5,
          "decimals": 1,
          "is_primary": true,
          "hint": ""
        },
        {
          "key": "tablespoon",
          "label": "قاشق غذاخوری",
          "grams": 20,
          "step": 1,
          "decimals": 0,
          "is_primary": false,
          "hint": ""
        },
        {
          "key": "gram",
          "label": "گرم",
          "grams": 1,
          "step": 1,
          "decimals": 0,
          "is_primary": false,
          "hint": ""
        }
      ]
    },
    "legacy_slug": "low-fat-pizza-cheese",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1511690743698-d9d85f2fbf38?w=800&q=80",
    "aliases_en": [
      "Low fat pizza cheese",
      "Part skim mozzarella"
    ],
    "related_slugs": [
      "ماست-یونانی-کم‌چرب",
      "پنیر-سفید-کم‌چرب",
      "نان-سنگک-کامل"
    ],
    "intro": "پنیر کم‌چرب منبع کازئین کند‌جذب است.",
    "substitutes": [
      {
        "slug": "ماست-یونانی-کم‌چرب",
        "ratio": 1.0
      },
      {
        "slug": "پنیر-سفید-کم‌چرب",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "پنیر-کوتاژ",
    "title": "پنیر کوتاژ",
    "excerpt": "مرجع علمی پنیر کوتاژ: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "لبنیات",
    "rank_math_title": "پنیر کوتاژ | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای پنیر کوتاژ در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "پنیر کوتاژ",
    "name_app": "پنیر کوتاژ",
    "other_names": "کوتاژ, Cottage cheese",
    "food_group": "لبنیات",
    "food_type": "solid",
    "meal_times": "صبحانه,میان‌وعده,قبل خواب",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "11",
    "calories": "98",
    "carbohydrates": "3.4",
    "fat": "4.3",
    "saturated_fat": "1.5",
    "fiber": "0",
    "sugar": "0.4",
    "cholesterol": "15",
    "sodium": "364",
    "potassium": "104",
    "glycemic_index": "15",
    "allergens": "لبنیات",
    "short_description": "پنیر کوتاژ کازئین و پروتئین؛ مناسب قبل خواب.",
    "serving_notes": "ارزش‌ها برای پنیر کوتاژ در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "نسخه کم‌چرب برای کات.",
    "tip_2": "با میوه یا عسل کم.",
    "tip_3": "یک پیمانه حدود ۱۵۰ گرم.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "cup",
      "units": [
        {
          "key": "cup",
          "label": "پیمانه",
          "grams": 150,
          "step": 0.5,
          "decimals": 1,
          "is_primary": true,
          "hint": ""
        },
        {
          "key": "tablespoon",
          "label": "قاشق غذاخوری",
          "grams": 20,
          "step": 1,
          "decimals": 0,
          "is_primary": false,
          "hint": ""
        },
        {
          "key": "gram",
          "label": "گرم",
          "grams": 1,
          "step": 1,
          "decimals": 0,
          "is_primary": false,
          "hint": ""
        }
      ]
    },
    "legacy_slug": "cottage-cheese",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1473093295045-ddd4c915dc20?w=800&q=80",
    "aliases_en": [
      "Cottage cheese",
      "Cottage"
    ],
    "related_slugs": [
      "ماست-یونانی-کم‌چرب",
      "پنیر-سفید-کم‌چرب",
      "نان-سنگک-کامل"
    ],
    "intro": "کوتاژ در رژیم‌های بدنسازی بسیار پرکاربرد است.",
    "substitutes": [
      {
        "slug": "ماست-یونانی-کم‌چرب",
        "ratio": 1.0
      },
      {
        "slug": "پنیر-سفید-کم‌چرب",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "ماست-پروتئین",
    "title": "ماست پروتئین",
    "excerpt": "مرجع علمی ماست پروتئین: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "لبنیات",
    "rank_math_title": "ماست پروتئین | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای ماست پروتئین در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "ماست پروتئین",
    "name_app": "ماست پروتئین",
    "other_names": "ماست پرو, Protein yogurt",
    "food_group": "لبنیات",
    "food_type": "solid",
    "meal_times": "صبحانه,میان‌وعده,بعد تمرین",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "10",
    "calories": "75",
    "carbohydrates": "6",
    "fat": "0.5",
    "saturated_fat": "0.2",
    "fiber": "0",
    "sugar": "0.7",
    "cholesterol": "15",
    "sodium": "55",
    "potassium": "180",
    "glycemic_index": "20",
    "allergens": "لبنیات",
    "short_description": "ماست پروتئین میان‌وعده سریع با پروتئین بالا.",
    "serving_notes": "ارزش‌ها برای ماست پروتئین در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "بدون افزودنی قند زیاد.",
    "tip_2": "بعد تمرین یا صبحانه.",
    "tip_3": "با توت‌فرنگی یا موز.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "cup",
      "units": [
        {
          "key": "cup",
          "label": "پیمانه",
          "grams": 150,
          "step": 0.5,
          "decimals": 1,
          "is_primary": true,
          "hint": ""
        },
        {
          "key": "tablespoon",
          "label": "قاشق غذاخوری",
          "grams": 20,
          "step": 1,
          "decimals": 0,
          "is_primary": false,
          "hint": ""
        },
        {
          "key": "gram",
          "label": "گرم",
          "grams": 1,
          "step": 1,
          "decimals": 0,
          "is_primary": false,
          "hint": ""
        }
      ]
    },
    "legacy_slug": "protein-yogurt",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1455619452474-d2be8b1e70cb?w=800&q=80",
    "aliases_en": [
      "Protein yogurt",
      "High protein yogurt"
    ],
    "related_slugs": [
      "ماست-یونانی-کم‌چرب",
      "پنیر-سفید-کم‌چرب",
      "نان-سنگک-کامل"
    ],
    "intro": "ماست پروتئین جایگزین عملی وی در سفر است.",
    "substitutes": [
      {
        "slug": "ماست-یونانی-کم‌چرب",
        "ratio": 1.0
      },
      {
        "slug": "پنیر-سفید-کم‌چرب",
        "ratio": 1.0
      }
    ]
  }
]
GYMAI_FOOD_BATCH11
        , true);
        return is_array($cache) ? $cache : array();
    }
}
