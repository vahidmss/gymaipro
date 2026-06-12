// GymAI Foods — BATCH 13 (خوراکی 121–130)
// Code Snippets: Run everywhere | بدون تگ php
// یا کپی در: wp-content/gymai-seed/food-batch13.php

if (!function_exists('gymai_food_batch13_definitions')) {
    function gymai_food_batch13_definitions() {
        static $cache = null;
        if ($cache !== null) {
            return $cache;
        }
        $cache = json_decode(<<<'GYMAI_FOOD_BATCH13'
[
  {
    "slug": "سیب‌زمینی-تنوری",
    "title": "سیب‌زمینی تنوری",
    "excerpt": "مرجع علمی سیب‌زمینی تنوری: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "کربوهیدرات‌ها",
    "rank_math_title": "سیب‌زمینی تنوری | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای سیب‌زمینی تنوری در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "سیب‌زمینی تنوری",
    "name_app": "سیب‌زمینی تنوری",
    "other_names": "سیب‌زمینی فر, Baked potato",
    "food_group": "کربوهیدرات",
    "food_type": "solid",
    "meal_times": "ناهار,بعد تمرین",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "tablespoon",
    "protein": "2",
    "calories": "93",
    "carbohydrates": "21",
    "fat": "0.1",
    "saturated_fat": "0.0",
    "fiber": "2.2",
    "sugar": "2.5",
    "cholesterol": "0",
    "sodium": "6",
    "potassium": "535",
    "glycemic_index": "65",
    "allergens": "",
    "short_description": "سیب‌زمینی تنوری کربو و پتاسیم؛ بعد تمرین.",
    "serving_notes": "ارزش‌ها برای سیب‌زمینی تنوری در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "بدون روغن زیاد.",
    "tip_2": "یک عدد متوسط ۱۵۰–۲۰۰ گرم.",
    "tip_3": "با مرغ یا تن ماهی.",
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
    "legacy_slug": "baked-potato",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1498837167922-ddd27525b352?w=800&q=80",
    "aliases_en": [
      "Baked potato",
      "Oven potato"
    ],
    "related_slugs": [
      "نان-سنگک-کامل",
      "برنج-سفید-پخته",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "سیب‌زمینی منبع گلیکوژن طبیعی است.",
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
    "slug": "پوره-سیب‌زمینی",
    "title": "پوره سیب‌زمینی",
    "excerpt": "مرجع علمی پوره سیب‌زمینی: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "کربوهیدرات‌ها",
    "rank_math_title": "پوره سیب‌زمینی | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای پوره سیب‌زمینی در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "پوره سیب‌زمینی",
    "name_app": "پوره سیب‌زمینی",
    "other_names": "پوره سیب‌زمینی, Mash",
    "food_group": "کربوهیدرات",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "2.5",
    "calories": "105",
    "carbohydrates": "17",
    "fat": "3.5",
    "saturated_fat": "1.2",
    "fiber": "1.5",
    "sugar": "2.0",
    "cholesterol": "0",
    "sodium": "320",
    "potassium": "320",
    "glycemic_index": "70",
    "allergens": "لبنیات",
    "short_description": "پوره سیب‌زمینی کربو نرم؛ بعد تمرین سنگین.",
    "serving_notes": "ارزش‌ها برای پوره سیب‌زمینی در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "کره و شیر را در مقدار لحاظ کنید.",
    "tip_2": "یک پیمانه حدود ۲۰۰ گرم.",
    "tip_3": "با پروتئین کنار.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "cup",
      "units": [
        {
          "key": "cup",
          "label": "پیمانه",
          "grams": 200,
          "step": 0.5,
          "decimals": 1,
          "is_primary": true,
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
    "legacy_slug": "mashed-potato",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80",
    "aliases_en": [
      "Mashed potato",
      "Potato mash"
    ],
    "related_slugs": [
      "نان-سنگک-کامل",
      "برنج-سفید-پخته",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "پوره گزینه کربوهیدرات قابل‌جذب است.",
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
    "slug": "عسل-طبیعی",
    "title": "عسل طبیعی",
    "excerpt": "مرجع علمی عسل طبیعی: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "کربوهیدرات‌ها",
    "rank_math_title": "عسل طبیعی | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای عسل طبیعی در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "عسل طبیعی",
    "name_app": "عسل طبیعی",
    "other_names": "عسل, Honey",
    "food_group": "کربوهیدرات",
    "food_type": "liquid",
    "meal_times": "قبل تمرین,بعد تمرین,صبحانه",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "tablespoon",
    "protein": "0.3",
    "calories": "304",
    "carbohydrates": "82",
    "fat": "0.0",
    "saturated_fat": "0.0",
    "fiber": "0.2",
    "sugar": "9.8",
    "cholesterol": "0",
    "sodium": "4",
    "potassium": "52",
    "glycemic_index": "58",
    "allergens": "",
    "short_description": "عسل کربوهیدرات سریع؛ قبل/بعد تمرین با برنجکیک.",
    "serving_notes": "ارزش‌ها برای عسل طبیعی در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "یک قاشق غذاخوری حدود ۲۱ گرم.",
    "tip_2": "در کات مقدار کم.",
    "tip_3": "با جو دوسر یا موز.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "tablespoon",
      "units": [
        {
          "key": "tablespoon",
          "label": "قاشق غذاخوری",
          "grams": 14,
          "step": 0.5,
          "decimals": 1,
          "is_primary": true,
          "hint": ""
        },
        {
          "key": "teaspoon",
          "label": "قاشق چای‌خوری",
          "grams": 5,
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
    "legacy_slug": "honey",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80",
    "aliases_en": [
      "Honey",
      "Natural honey"
    ],
    "related_slugs": [
      "نان-سنگک-کامل",
      "برنج-سفید-پخته",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "عسل شیرین‌کننده طبیعی در رژیم ورزشی است.",
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
    "slug": "مربای-کم‌قند",
    "title": "مربای کم‌قند",
    "excerpt": "مرجع علمی مربای کم‌قند: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "کربوهیدرات‌ها",
    "rank_math_title": "مربای کم‌قند | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای مربای کم‌قند در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "مربای کم‌قند",
    "name_app": "مربای کم‌قند",
    "other_names": "مربا, Jam",
    "food_group": "کربوهیدرات",
    "food_type": "liquid",
    "meal_times": "صبحانه,میان‌وعده",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "tablespoon",
    "protein": "0.5",
    "calories": "180",
    "carbohydrates": "45",
    "fat": "0.1",
    "saturated_fat": "0.0",
    "fiber": "1",
    "sugar": "5.4",
    "cholesterol": "0",
    "sodium": "12",
    "potassium": "80",
    "glycemic_index": "65",
    "allergens": "",
    "short_description": "مربای کم‌قند طعم شیرین با کالری کنترل‌شده.",
    "serving_notes": "ارزش‌ها برای مربای کم‌قند در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "یک قاشق غذاخوری.",
    "tip_2": "با نان تست یا برنجکیک.",
    "tip_3": "قند کل روز را ببینید.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "tablespoon",
      "units": [
        {
          "key": "tablespoon",
          "label": "قاشق غذاخوری",
          "grams": 14,
          "step": 0.5,
          "decimals": 1,
          "is_primary": true,
          "hint": ""
        },
        {
          "key": "teaspoon",
          "label": "قاشق چای‌خوری",
          "grams": 5,
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
    "legacy_slug": "reduced-sugar-jam",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800&q=80",
    "aliases_en": [
      "Reduced sugar jam",
      "Light jam"
    ],
    "related_slugs": [
      "نان-سنگک-کامل",
      "برنج-سفید-پخته",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "مربا در صبحانه ورزشکاران ایرانی رایج است.",
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
    "slug": "نان-باگت",
    "title": "نان باگت",
    "excerpt": "مرجع علمی نان باگت: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "کربوهیدرات‌ها",
    "rank_math_title": "نان باگت | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای نان باگت در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "نان باگت",
    "name_app": "نان باگت",
    "other_names": "باگت, Baguette",
    "food_group": "کربوهیدرات",
    "food_type": "solid",
    "meal_times": "صبحانه,ناهار",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "piece",
    "protein": "9",
    "calories": "270",
    "carbohydrates": "56",
    "fat": "1.5",
    "saturated_fat": "0.5",
    "fiber": "2.5",
    "sugar": "6.7",
    "cholesterol": "0",
    "sodium": "540",
    "potassium": "110",
    "glycemic_index": "70",
    "allergens": "گلوتن",
    "short_description": "نان باگت کربوهیدرات سریع؛ با پروتئین ترکیب شود.",
    "serving_notes": "ارزش‌ها برای نان باگت در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "نیم باگت کوچک ۴۰–۵۰ گرم.",
    "tip_2": "با مرغ یا تن.",
    "tip_3": "سدیم نان را در نظر بگیرید.",
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
    "legacy_slug": "baguette",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80",
    "aliases_en": [
      "Baguette",
      "French bread"
    ],
    "related_slugs": [
      "نان-سنگک-کامل",
      "برنج-سفید-پخته",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "باگت در ساندویچ‌های پروتئینی استفاده می‌شود.",
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
    "slug": "روغن-نارگیل",
    "title": "روغن نارگیل",
    "excerpt": "مرجع علمی روغن نارگیل: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "چربی‌ها",
    "rank_math_title": "روغن نارگیل | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای روغن نارگیل در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "روغن نارگیل",
    "name_app": "روغن نارگیل",
    "other_names": "روغن نارگیل, Coconut oil",
    "food_group": "چربی",
    "food_type": "liquid",
    "meal_times": "صبحانه,ناهار",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "tablespoon",
    "protein": "0",
    "calories": "862",
    "carbohydrates": "0",
    "fat": "100.0",
    "saturated_fat": "35.0",
    "fiber": "0",
    "sugar": "0",
    "cholesterol": "0",
    "sodium": "0",
    "potassium": "0",
    "glycemic_index": "0",
    "allergens": "",
    "short_description": "روغن نارگیل چربی اشباع گیاهی؛ در پخت یا قهوه.",
    "serving_notes": "ارزش‌ها برای روغن نارگیل در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "یک قاشق چای‌خوری تا غذاخوری.",
    "tip_2": "کالری بالا — مقدار کم.",
    "tip_3": "برای پخت سالاد یا تخم‌مرغ.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "tablespoon",
      "units": [
        {
          "key": "tablespoon",
          "label": "قاشق غذاخوری",
          "grams": 14,
          "step": 0.5,
          "decimals": 1,
          "is_primary": true,
          "hint": ""
        },
        {
          "key": "teaspoon",
          "label": "قاشق چای‌خوری",
          "grams": 5,
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
    "legacy_slug": "coconut-oil",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1482049016688-a7bd8fa7e6a1?w=800&q=80",
    "aliases_en": [
      "Coconut oil",
      "MCT oil source"
    ],
    "related_slugs": [
      "روغن-زیتون",
      "بادام-خام",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "روغن نارگیل در رژیم‌های خاص کاربرد دارد.",
    "substitutes": [
      {
        "slug": "روغن-زیتون",
        "ratio": 1.0
      },
      {
        "slug": "بادام-خام",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "روغن-آفتابگردان",
    "title": "روغن آفتابگردان",
    "excerpt": "مرجع علمی روغن آفتابگردان: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "چربی‌ها",
    "rank_math_title": "روغن آفتابگردان | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای روغن آفتابگردان در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "روغن آفتابگردان",
    "name_app": "روغن آفتابگردان",
    "other_names": "روغن آفتابگردان, Sunflower oil",
    "food_group": "چربی",
    "food_type": "liquid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "tablespoon",
    "protein": "0",
    "calories": "884",
    "carbohydrates": "0",
    "fat": "100.0",
    "saturated_fat": "35.0",
    "fiber": "0",
    "sugar": "0",
    "cholesterol": "0",
    "sodium": "0",
    "potassium": "0",
    "glycemic_index": "0",
    "allergens": "",
    "short_description": "روغن آفتابگردان پخت روزمره؛ در مقدار کنترل‌شده.",
    "serving_notes": "ارزش‌ها برای روغن آفتابگردان در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "در سالاد یا تفت کم.",
    "tip_2": "یک قاشق غذاخوری ۱۴ گرم.",
    "tip_3": "چربی روز را جمع بزنید.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "tablespoon",
      "units": [
        {
          "key": "tablespoon",
          "label": "قاشق غذاخوری",
          "grams": 14,
          "step": 0.5,
          "decimals": 1,
          "is_primary": true,
          "hint": ""
        },
        {
          "key": "teaspoon",
          "label": "قاشق چای‌خوری",
          "grams": 5,
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
    "legacy_slug": "sunflower-oil",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800&q=80",
    "aliases_en": [
      "Sunflower oil",
      "Cooking oil"
    ],
    "related_slugs": [
      "روغن-زیتون",
      "بادام-خام",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "روغن پخت رایج در آشپزی خانگی است.",
    "substitutes": [
      {
        "slug": "روغن-زیتون",
        "ratio": 1.0
      },
      {
        "slug": "بادام-خام",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "کشمش",
    "title": "کشمش",
    "excerpt": "مرجع علمی کشمش: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "میوه‌ها",
    "rank_math_title": "کشمش | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای کشمش در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "کشمش",
    "name_app": "کشمش",
    "other_names": "کشمش, Raisins",
    "food_group": "میوه",
    "food_type": "solid",
    "meal_times": "میان‌وعده,قبل تمرین",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "gram",
    "protein": "3.1",
    "calories": "299",
    "carbohydrates": "79",
    "fat": "0.5",
    "saturated_fat": "0.2",
    "fiber": "3.7",
    "sugar": "9.5",
    "cholesterol": "0",
    "sodium": "11",
    "potassium": "749",
    "glycemic_index": "64",
    "allergens": "",
    "short_description": "کشمش انرژی سریع و قابل حمل؛ قبل تمرین.",
    "serving_notes": "ارزش‌ها برای کشمش در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "۲۰–۳۰ گرم در هر وعده.",
    "tip_2": "با آجیل ترکیب کنید.",
    "tip_3": "در کات مقدار کم.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "gram",
      "units": [
        {
          "key": "gram",
          "label": "گرم",
          "grams": 1,
          "step": 1,
          "decimals": 0,
          "is_primary": true,
          "hint": "وعده ۲۵–۳۰ گرم"
        },
        {
          "key": "piece",
          "label": "عدد",
          "grams": 1.2,
          "step": 1,
          "decimals": 0,
          "is_primary": false,
          "hint": ""
        }
      ]
    },
    "legacy_slug": "raisins",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1511690743698-d9d85f2fbf38?w=800&q=80",
    "aliases_en": [
      "Raisins",
      "Dried grapes"
    ],
    "related_slugs": [
      "موز",
      "سیب",
      "ماست-یونانی-کم‌چرب"
    ],
    "intro": "میوه خشک منبع کربوهیدرات متمرکز است.",
    "substitutes": [
      {
        "slug": "موز",
        "ratio": 1.0
      },
      {
        "slug": "سیب",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "مویز",
    "title": "مویز",
    "excerpt": "مرجع علمی مویز: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "میوه‌ها",
    "rank_math_title": "مویز | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای مویز در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "مویز",
    "name_app": "مویز",
    "other_names": "مویز, Currants",
    "food_group": "میوه",
    "food_type": "solid",
    "meal_times": "میان‌وعده,قبل تمرین",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "gram",
    "protein": "3.1",
    "calories": "299",
    "carbohydrates": "79",
    "fat": "0.5",
    "saturated_fat": "0.2",
    "fiber": "3.7",
    "sugar": "9.5",
    "cholesterol": "0",
    "sodium": "21",
    "potassium": "680",
    "glycemic_index": "62",
    "allergens": "",
    "short_description": "مویز کربوهیدرات شیرین؛ میان‌وعده کوچک.",
    "serving_notes": "ارزش‌ها برای مویز در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "۱۵–۲۵ گرم.",
    "tip_2": "در میکس آجیل.",
    "tip_3": "قبل تمرین سبک.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "gram",
      "units": [
        {
          "key": "gram",
          "label": "گرم",
          "grams": 1,
          "step": 1,
          "decimals": 0,
          "is_primary": true,
          "hint": "وعده ۲۵–۳۰ گرم"
        },
        {
          "key": "piece",
          "label": "عدد",
          "grams": 1.2,
          "step": 1,
          "decimals": 0,
          "is_primary": false,
          "hint": ""
        }
      ]
    },
    "legacy_slug": "dried-currants",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1473093295045-ddd4c915dc20?w=800&q=80",
    "aliases_en": [
      "Dried currants",
      "Currants"
    ],
    "related_slugs": [
      "موز",
      "سیب",
      "ماست-یونانی-کم‌چرب"
    ],
    "intro": "مویز در رژیم ایرانی رایج است.",
    "substitutes": [
      {
        "slug": "موز",
        "ratio": 1.0
      },
      {
        "slug": "سیب",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "زردآلو-خشک",
    "title": "زردآلو خشک",
    "excerpt": "مرجع علمی زردآلو خشک: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "میوه‌ها",
    "rank_math_title": "زردآلو خشک | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای زردآلو خشک در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "زردآلو خشک",
    "name_app": "زردآلو خشک",
    "other_names": "زردآلو خشک, Dried apricot",
    "food_group": "میوه",
    "food_type": "solid",
    "meal_times": "میان‌وعده",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "gram",
    "protein": "3.4",
    "calories": "241",
    "carbohydrates": "63",
    "fat": "0.5",
    "saturated_fat": "0.2",
    "fiber": "7.3",
    "sugar": "7.6",
    "cholesterol": "0",
    "sodium": "10",
    "potassium": "1162",
    "glycemic_index": "30",
    "allergens": "",
    "short_description": "زردآلو خشک فیبر و پتاسیم؛ میان‌وعده انرژی‌زا.",
    "serving_notes": "ارزش‌ها برای زردآلو خشک در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "۳–۴ عدد متوسط.",
    "tip_2": "آب کافی بنوشید.",
    "tip_3": "با ماست ترکیب شود.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "gram",
      "units": [
        {
          "key": "gram",
          "label": "گرم",
          "grams": 1,
          "step": 1,
          "decimals": 0,
          "is_primary": true,
          "hint": "وعده ۲۵–۳۰ گرم"
        },
        {
          "key": "piece",
          "label": "عدد",
          "grams": 1.2,
          "step": 1,
          "decimals": 0,
          "is_primary": false,
          "hint": ""
        }
      ]
    },
    "legacy_slug": "dried-apricot",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1455619452474-d2be8b1e70cb?w=800&q=80",
    "aliases_en": [
      "Dried apricot",
      "Apricots dried"
    ],
    "related_slugs": [
      "موز",
      "سیب",
      "ماست-یونانی-کم‌چرب"
    ],
    "intro": "میوه خشک فیبر محلول فراهم می‌کند.",
    "substitutes": [
      {
        "slug": "موز",
        "ratio": 1.0
      },
      {
        "slug": "سیب",
        "ratio": 1.0
      }
    ]
  }
]
GYMAI_FOOD_BATCH13
        , true);
        return is_array($cache) ? $cache : array();
    }
}
