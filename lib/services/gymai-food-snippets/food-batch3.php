// GymAI Foods — BATCH 3 (خوراکی 21–30)
// Code Snippets: Run everywhere | بدون تگ php
// یا کپی در: wp-content/gymai-seed/food-batch3.php

if (!function_exists('gymai_food_batch3_definitions')) {
    function gymai_food_batch3_definitions() {
        static $cache = null;
        if ($cache !== null) {
            return $cache;
        }
        $cache = json_decode(<<<'GYMAI_FOOD_BATCH3'
[
  {
    "slug": "برنج-قهوه‌ای-پخته",
    "title": "برنج قهوه‌ای پخته",
    "excerpt": "مرجع علمی برنج قهوه‌ای پخته: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "کربوهیدرات‌ها",
    "rank_math_title": "برنج قهوه‌ای پخته | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای برنج قهوه‌ای پخته در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "برنج قهوه‌ای پخته",
    "name_app": "برنج قهوه‌ای پخته",
    "other_names": "برنج قهوه‌ای, Brown rice",
    "food_group": "کربوهیدرات",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "tablespoon",
    "protein": "2.7",
    "calories": "123",
    "carbohydrates": "26",
    "fat": "1.0",
    "saturated_fat": "0.3",
    "fiber": "1.8",
    "sugar": "3.1",
    "cholesterol": "0",
    "sodium": "4",
    "potassium": "86",
    "glycemic_index": "50",
    "allergens": "",
    "short_description": "برنج قهوه‌ای فیبر و مواد معدنی بیشتری از برنج سفید دارد؛ GI پایین‌تر برای کنترل قند خون.",
    "serving_notes": "ارزش‌ها برای برنج قهوه‌ای پخته در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "نسبت آب بیشتر پخت نرم‌تر می‌دهد.",
    "tip_2": "با پروتئین و چربی سالم GI کاهش می‌یابد.",
    "tip_3": "برای حجم ۱–۲ پیمانه بسته به هدف.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "tablespoon",
      "units": [
        {
          "key": "tablespoon",
          "label": "قاشق غذاخوری",
          "grams": 15,
          "step": 0.5,
          "decimals": 1,
          "is_primary": true,
          "hint": "پخته"
        },
        {
          "key": "cup",
          "label": "پیمانه / لیوان",
          "grams": 150,
          "step": 0.5,
          "decimals": 1,
          "is_primary": false,
          "hint": ""
        },
        {
          "key": "palm_carb",
          "label": "کف دست (کربو)",
          "grams": 20,
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
    "legacy_slug": "cooked-brown-rice",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1498837167922-ddd27525b352?w=800&q=80",
    "aliases_en": [
      "Cooked brown rice",
      "Brown rice"
    ],
    "related_slugs": [
      "نان-سنگک-کامل",
      "برنج-سفید-پخته",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "برنج کامل در رژیم کربوهیدرات پیچیده جایگاه دارد.",
    "substitutes": [
      {
        "slug": "نان-سنگک-کامل",
        "ratio": 1.0
      },
      {
        "slug": "برنج-سفید-پخته",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "جو-دوسر-پخته",
    "title": "جو دوسر پخته",
    "excerpt": "مرجع علمی جو دوسر پخته: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "کربوهیدرات‌ها",
    "rank_math_title": "جو دوسر پخته | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای جو دوسر پخته در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "جو دوسر پخته",
    "name_app": "جو دوسر پخته",
    "other_names": "اوتمیل, Oatmeal",
    "food_group": "کربوهیدرات",
    "food_type": "solid",
    "meal_times": "صبحانه,قبل تمرین",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "tablespoon",
    "protein": "2.5",
    "calories": "71",
    "carbohydrates": "12",
    "fat": "1.5",
    "saturated_fat": "0.5",
    "fiber": "1.7",
    "sugar": "1.4",
    "cholesterol": "0",
    "sodium": "4",
    "potassium": "61",
    "glycemic_index": "55",
    "allergens": "گلوتن",
    "short_description": "جو دوسر بتاگلوکان soluble fiber دارد؛ برای صبحانه و قبل تمرین انرژی پایدار می‌دهد.",
    "serving_notes": "ارزش‌ها برای جو دوسر پخته در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "با شیر یا آب بپزید.",
    "tip_2": "میوه و دارچین بدون قند اضافه.",
    "tip_3": "جو دوسر فوری GI بالاتر دارد.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "tablespoon",
      "units": [
        {
          "key": "tablespoon",
          "label": "قاشق غذاخوری",
          "grams": 15,
          "step": 0.5,
          "decimals": 1,
          "is_primary": true,
          "hint": "پخته"
        },
        {
          "key": "cup",
          "label": "پیمانه / لیوان",
          "grams": 150,
          "step": 0.5,
          "decimals": 1,
          "is_primary": false,
          "hint": ""
        },
        {
          "key": "palm_carb",
          "label": "کف دست (کربو)",
          "grams": 20,
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
    "legacy_slug": "cooked-oatmeal",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80",
    "aliases_en": [
      "Cooked oatmeal",
      "Oats"
    ],
    "related_slugs": [
      "نان-سنگک-کامل",
      "برنج-سفید-پخته",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "جو دوسر در مطالعات LDL و GI مورد بررسی است.",
    "substitutes": [
      {
        "slug": "نان-سنگک-کامل",
        "ratio": 1.0
      },
      {
        "slug": "برنج-سفید-پخته",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "ماکارونی-پخته",
    "title": "ماکارونی پخته",
    "excerpt": "مرجع علمی ماکارونی پخته: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "کربوهیدرات‌ها",
    "rank_math_title": "ماکارونی پخته | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای ماکارونی پخته در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "ماکارونی پخته",
    "name_app": "ماکارونی پخته",
    "other_names": "پاستا, Pasta",
    "food_group": "کربوهیدرات",
    "food_type": "solid",
    "meal_times": "ناهار,بعد تمرین",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "tablespoon",
    "protein": "5",
    "calories": "131",
    "carbohydrates": "25",
    "fat": "1.1",
    "saturated_fat": "0.4",
    "fiber": "1.8",
    "sugar": "3.0",
    "cholesterol": "0",
    "sodium": "1",
    "potassium": "44",
    "glycemic_index": "49",
    "allergens": "گلوتن",
    "short_description": "ماکارونی پخته کربوهیدرات ریکاوری سریع است؛ با سس سبک و پروتئین وعده کامل می‌شود.",
    "serving_notes": "ارزش‌ها برای ماکارونی پخته در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "al dente GI کمی پایین‌تر دارد.",
    "tip_2": "سس خامه‌ای کالری را چند برابر می‌کند.",
    "tip_3": "بعد تمرین با مرغ یا تن عالی است.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "tablespoon",
      "units": [
        {
          "key": "tablespoon",
          "label": "قاشق غذاخوری",
          "grams": 15,
          "step": 0.5,
          "decimals": 1,
          "is_primary": true,
          "hint": "پخته"
        },
        {
          "key": "cup",
          "label": "پیمانه / لیوان",
          "grams": 150,
          "step": 0.5,
          "decimals": 1,
          "is_primary": false,
          "hint": ""
        },
        {
          "key": "palm_carb",
          "label": "کف دست (کربو)",
          "grams": 20,
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
    "legacy_slug": "cooked-pasta",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80",
    "aliases_en": [
      "Cooked pasta",
      "Pasta"
    ],
    "related_slugs": [
      "نان-سنگک-کامل",
      "برنج-سفید-پخته",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "پاستا در تغذیه ورزشی برای glycogen refill استفاده می‌شود.",
    "substitutes": [
      {
        "slug": "نان-سنگک-کامل",
        "ratio": 1.0
      },
      {
        "slug": "برنج-سفید-پخته",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "نان-بربری",
    "title": "نان بربری",
    "excerpt": "مرجع علمی نان بربری: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "کربوهیدرات‌ها",
    "rank_math_title": "نان بربری | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای نان بربری در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "نان بربری",
    "name_app": "نان بربری",
    "other_names": "بربری, Barbari",
    "food_group": "کربوهیدرات",
    "food_type": "solid",
    "meal_times": "صبحانه,ناهار",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "piece",
    "protein": "9",
    "calories": "275",
    "carbohydrates": "52",
    "fat": "3.0",
    "saturated_fat": "1.0",
    "fiber": "4",
    "sugar": "6.2",
    "cholesterol": "0",
    "sodium": "520",
    "potassium": "120",
    "glycemic_index": "58",
    "allergens": "گلوتن",
    "short_description": "نان بربری کربوهیدرات سنتی ایرانی است؛ نسبت به سنگک کامل فیبر کمتر دارد.",
    "serving_notes": "ارزش‌ها برای نان بربری در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "یک تکه با پنیر و سبزی وعده متعادل است.",
    "tip_2": "نسخه سبوس‌دار اگر موجود انتخاب کنید.",
    "tip_3": "کالری را با تعداد تکه کنترل کنید.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "piece",
      "units": [
        {
          "key": "piece",
          "label": "عدد / تکه",
          "grams": 35,
          "step": 0.5,
          "decimals": 1,
          "is_primary": true,
          "hint": ""
        },
        {
          "key": "palm_carb",
          "label": "کف دست (کربو)",
          "grams": 20,
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
    "legacy_slug": "barbari-bread",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800&q=80",
    "aliases_en": [
      "Barbari bread",
      "Persian bread"
    ],
    "related_slugs": [
      "نان-سنگک-کامل",
      "برنج-سفید-پخته",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "نان بربری جزو منابع انرژی سریع در رژیم ایرانی است.",
    "substitutes": [
      {
        "slug": "نان-سنگک-کامل",
        "ratio": 1.0
      },
      {
        "slug": "برنج-سفید-پخته",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "نان-لواش",
    "title": "نان لواش",
    "excerpt": "مرجع علمی نان لواش: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "کربوهیدرات‌ها",
    "rank_math_title": "نان لواش | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای نان لواش در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "نان لواش",
    "name_app": "نان لواش",
    "other_names": "لواش, Lavash",
    "food_group": "کربوهیدرات",
    "food_type": "solid",
    "meal_times": "صبحانه,ناهار",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "piece",
    "protein": "8",
    "calories": "260",
    "carbohydrates": "50",
    "fat": "2.0",
    "saturated_fat": "0.7",
    "fiber": "2",
    "sugar": "6.0",
    "cholesterol": "0",
    "sodium": "480",
    "potassium": "100",
    "glycemic_index": "60",
    "allergens": "گلوتن",
    "short_description": "نان لواش نازک و کم‌حجم است؛ برای کنترل کربوهیدرات با تعداد برگه حساب کنید.",
    "serving_notes": "ارزش‌ها برای نان لواش در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "۲–۳ برگه معمولاً یک واحد کربو است.",
    "tip_2": "با کباب و سالاد ترکیب رایج است.",
    "tip_3": "لواش کامل فیبر بیشتری دارد.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "piece",
      "units": [
        {
          "key": "piece",
          "label": "عدد / تکه",
          "grams": 35,
          "step": 0.5,
          "decimals": 1,
          "is_primary": true,
          "hint": ""
        },
        {
          "key": "palm_carb",
          "label": "کف دست (کربو)",
          "grams": 20,
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
    "legacy_slug": "lavash-bread",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80",
    "aliases_en": [
      "Lavash bread",
      "Flatbread"
    ],
    "related_slugs": [
      "نان-سنگک-کامل",
      "برنج-سفید-پخته",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "نان لواش در وعده‌های سبک ایرانی پرکاربرد است.",
    "substitutes": [
      {
        "slug": "نان-سنگک-کامل",
        "ratio": 1.0
      },
      {
        "slug": "برنج-سفید-پخته",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "نودل-برنج-پخته",
    "title": "نودل برنج پخته",
    "excerpt": "مرجع علمی نودل برنج پخته: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "کربوهیدرات‌ها",
    "rank_math_title": "نودل برنج پخته | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای نودل برنج پخته در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "نودل برنج پخته",
    "name_app": "نودل برنج پخته",
    "other_names": "نودل برنج, Rice noodles",
    "food_group": "کربوهیدرات",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "tablespoon",
    "protein": "1.8",
    "calories": "109",
    "carbohydrates": "24",
    "fat": "0.2",
    "saturated_fat": "0.1",
    "fiber": "0.4",
    "sugar": "2.9",
    "cholesterol": "0",
    "sodium": "1",
    "potassium": "4",
    "glycemic_index": "61",
    "allergens": "",
    "short_description": "نودل برنج بدون گلوتن است؛ کربوهیدرات سبک برای حساسیت به گندم.",
    "serving_notes": "ارزش‌ها برای نودل برنج پخته در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "با سبزی و مرغ stir-fry سالم بپزید.",
    "tip_2": "سس سویا کم‌نمک.",
    "tip_3": "حجم پخت را در ۱۰۰ گرم خشک/پخته دقت کنید.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "tablespoon",
      "units": [
        {
          "key": "tablespoon",
          "label": "قاشق غذاخوری",
          "grams": 15,
          "step": 0.5,
          "decimals": 1,
          "is_primary": true,
          "hint": "پخته"
        },
        {
          "key": "cup",
          "label": "پیمانه / لیوان",
          "grams": 150,
          "step": 0.5,
          "decimals": 1,
          "is_primary": false,
          "hint": ""
        },
        {
          "key": "palm_carb",
          "label": "کف دست (کربو)",
          "grams": 20,
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
    "legacy_slug": "rice-noodles-cooked",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1482049016688-a7bd8fa7e6a1?w=800&q=80",
    "aliases_en": [
      "Rice noodles cooked",
      "Rice noodles"
    ],
    "related_slugs": [
      "نان-سنگک-کامل",
      "برنج-سفید-پخته",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "نودل برنج در غذاهای آسیایی رژیم ورزشکاران رایج است.",
    "substitutes": [
      {
        "slug": "نان-سنگک-کامل",
        "ratio": 1.0
      },
      {
        "slug": "برنج-سفید-پخته",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "کینوا-پخته",
    "title": "کینوا پخته",
    "excerpt": "مرجع علمی کینوا پخته: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "کربوهیدرات‌ها",
    "rank_math_title": "کینوا پخته | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای کینوا پخته در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "کینوا پخته",
    "name_app": "کینوا پخته",
    "other_names": "کینوا, Quinoa",
    "food_group": "کربوهیدرات",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "tablespoon",
    "protein": "4.4",
    "calories": "120",
    "carbohydrates": "21",
    "fat": "1.9",
    "saturated_fat": "0.7",
    "fiber": "2.8",
    "sugar": "2.5",
    "cholesterol": "0",
    "sodium": "7",
    "potassium": "172",
    "glycemic_index": "53",
    "allergens": "",
    "short_description": "کینوا پروتئین گیاهی و فیبر دارد؛ یکی از معدود پروتئین‌های کامل گیاهی است.",
    "serving_notes": "ارزش‌ها برای کینوا پخته در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "قبل پخت آبکش کنید تا تلخی از بین برود.",
    "tip_2": "با سبزیجات سالاد پروتئینی بسازید.",
    "tip_3": "جایگزین برنج در رژیم متنوع.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "tablespoon",
      "units": [
        {
          "key": "tablespoon",
          "label": "قاشق غذاخوری",
          "grams": 15,
          "step": 0.5,
          "decimals": 1,
          "is_primary": true,
          "hint": "پخته"
        },
        {
          "key": "cup",
          "label": "پیمانه / لیوان",
          "grams": 150,
          "step": 0.5,
          "decimals": 1,
          "is_primary": false,
          "hint": ""
        },
        {
          "key": "palm_carb",
          "label": "کف دست (کربو)",
          "grams": 20,
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
    "legacy_slug": "cooked-quinoa",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800&q=80",
    "aliases_en": [
      "Cooked quinoa",
      "Quinoa"
    ],
    "related_slugs": [
      "نان-سنگک-کامل",
      "برنج-سفید-پخته",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "کینوا در تغذیه گیاهخواران ورزشکار محبوب است.",
    "substitutes": [
      {
        "slug": "نان-سنگک-کامل",
        "ratio": 1.0
      },
      {
        "slug": "برنج-سفید-پخته",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "بلغور-پخته",
    "title": "بلغور پخته",
    "excerpt": "مرجع علمی بلغور پخته: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "کربوهیدرات‌ها",
    "rank_math_title": "بلغور پخته | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای بلغور پخته در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "بلغور پخته",
    "name_app": "بلغور پخته",
    "other_names": "بلغور, Bulgur",
    "food_group": "کربوهیدرات",
    "food_type": "solid",
    "meal_times": "صبحانه,ناهار",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "tablespoon",
    "protein": "3.1",
    "calories": "83",
    "carbohydrates": "19",
    "fat": "0.2",
    "saturated_fat": "0.1",
    "fiber": "4.5",
    "sugar": "2.3",
    "cholesterol": "0",
    "sodium": "5",
    "potassium": "68",
    "glycemic_index": "48",
    "allergens": "گلوتن",
    "short_description": "بلغور گندم پارboiled است؛ فیبر بالا و پخت سریع برای وعده کربوهیدرات.",
    "serving_notes": "ارزش‌ها برای بلغور پخته در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "در سالاد تبوله یا با عدس.",
    "tip_2": "GI پایین‌تر از برنج سفید.",
    "tip_3": "یک پیمانه پخته حجم مناسب.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "tablespoon",
      "units": [
        {
          "key": "tablespoon",
          "label": "قاشق غذاخوری",
          "grams": 15,
          "step": 0.5,
          "decimals": 1,
          "is_primary": true,
          "hint": "پخته"
        },
        {
          "key": "cup",
          "label": "پیمانه / لیوان",
          "grams": 150,
          "step": 0.5,
          "decimals": 1,
          "is_primary": false,
          "hint": ""
        },
        {
          "key": "palm_carb",
          "label": "کف دست (کربو)",
          "grams": 20,
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
    "legacy_slug": "cooked-bulgur",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1511690743698-d9d85f2fbf38?w=800&q=80",
    "aliases_en": [
      "Cooked bulgur",
      "Bulgur wheat"
    ],
    "related_slugs": [
      "نان-سنگک-کامل",
      "برنج-سفید-پخته",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "بلغور در غذای مدیترانه‌ای و ایرانی (کوفته) کاربرد دارد.",
    "substitutes": [
      {
        "slug": "نان-سنگک-کامل",
        "ratio": 1.0
      },
      {
        "slug": "برنج-سفید-پخته",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "ذرت-پخته",
    "title": "ذرت پخته",
    "excerpt": "مرجع علمی ذرت پخته: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "کربوهیدرات‌ها",
    "rank_math_title": "ذرت پخته | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای ذرت پخته در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "ذرت پخته",
    "name_app": "ذرت پخته",
    "other_names": "ذرت, Corn",
    "food_group": "کربوهیدرات",
    "food_type": "solid",
    "meal_times": "ناهار,بعد تمرین",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "tablespoon",
    "protein": "3.4",
    "calories": "96",
    "carbohydrates": "21",
    "fat": "1.5",
    "saturated_fat": "0.5",
    "fiber": "2.4",
    "sugar": "2.5",
    "cholesterol": "0",
    "sodium": "1",
    "potassium": "270",
    "glycemic_index": "52",
    "allergens": "",
    "short_description": "ذرت پخته کربوهیدرات و فیبر با GI متوسط دارد؛ انرژی برای تمرین.",
    "serving_notes": "ارزش‌ها برای ذرت پخته در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "کره اضافه کالری را بالا می‌برد.",
    "tip_2": "تازه یا فریز شده فرقی در ماکرو کم دارد.",
    "tip_3": "با مرغ یا لوبیا وعده کامل.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "tablespoon",
      "units": [
        {
          "key": "tablespoon",
          "label": "قاشق غذاخوری",
          "grams": 15,
          "step": 0.5,
          "decimals": 1,
          "is_primary": true,
          "hint": "پخته"
        },
        {
          "key": "cup",
          "label": "پیمانه / لیوان",
          "grams": 150,
          "step": 0.5,
          "decimals": 1,
          "is_primary": false,
          "hint": ""
        },
        {
          "key": "palm_carb",
          "label": "کف دست (کربو)",
          "grams": 20,
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
    "legacy_slug": "cooked-corn",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1473093295045-ddd4c915dc20?w=800&q=80",
    "aliases_en": [
      "Cooked corn",
      "Sweet corn"
    ],
    "related_slugs": [
      "نان-سنگک-کامل",
      "برنج-سفید-پخته",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "ذرت منبع آنتی‌اکسیدant lutein است.",
    "substitutes": [
      {
        "slug": "نان-سنگک-کامل",
        "ratio": 1.0
      },
      {
        "slug": "برنج-سفید-پخته",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "نان-تست-گندم-کامل",
    "title": "نان تست گندم کامل",
    "excerpt": "مرجع علمی نان تست گندم کامل: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "کربوهیدرات‌ها",
    "rank_math_title": "نان تست گندم کامل | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای نان تست گندم کامل در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "نان تست گندم کامل",
    "name_app": "نان تست گندم کامل",
    "other_names": "نان تست, Toast",
    "food_group": "کربوهیدرات",
    "food_type": "solid",
    "meal_times": "صبحانه,میان‌وعده",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "piece",
    "protein": "13",
    "calories": "247",
    "carbohydrates": "41",
    "fat": "3.4",
    "saturated_fat": "1.2",
    "fiber": "7",
    "sugar": "4.9",
    "cholesterol": "0",
    "sodium": "400",
    "potassium": "230",
    "glycemic_index": "52",
    "allergens": "گلوتن",
    "short_description": "نان تست گندم کامل فیبر و پروتئین بیشتری از نان سفید دارد.",
    "serving_notes": "ارزش‌ها برای نان تست گندم کامل در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "با تخم‌مرغ و آووکادو صبحانه پروتئینی.",
    "tip_2": "۲ برش معمولاً یک واحد کربو.",
    "tip_3": "برش نازک کالری کمتر.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "piece",
      "units": [
        {
          "key": "piece",
          "label": "عدد / تکه",
          "grams": 35,
          "step": 0.5,
          "decimals": 1,
          "is_primary": true,
          "hint": ""
        },
        {
          "key": "palm_carb",
          "label": "کف دست (کربو)",
          "grams": 20,
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
    "legacy_slug": "whole-wheat-toast",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1455619452474-d2be8b1e70cb?w=800&q=80",
    "aliases_en": [
      "Whole wheat toast",
      "Whole grain bread"
    ],
    "related_slugs": [
      "نان-سنگک-کامل",
      "برنج-سفید-پخته",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "نان کامل در رژیم GI پایین‌تر توصیه می‌شود.",
    "substitutes": [
      {
        "slug": "نان-سنگک-کامل",
        "ratio": 1.0
      },
      {
        "slug": "برنج-سفید-پخته",
        "ratio": 1.0
      }
    ]
  }
]
GYMAI_FOOD_BATCH3
        , true);
        return is_array($cache) ? $cache : array();
    }
}
