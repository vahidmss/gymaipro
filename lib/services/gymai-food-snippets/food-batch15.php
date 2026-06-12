// GymAI Foods — BATCH 15 (خوراکی 141–150)
// Code Snippets: Run everywhere | بدون تگ php
// یا کپی در: wp-content/gymai-seed/food-batch15.php

if (!function_exists('gymai_food_batch15_definitions')) {
    function gymai_food_batch15_definitions() {
        static $cache = null;
        if ($cache !== null) {
            return $cache;
        }
        $cache = json_decode(<<<'GYMAI_FOOD_BATCH15'
[
  {
    "slug": "پنیر-پارمزان",
    "title": "پنیر پارمزان",
    "excerpt": "مرجع علمی پنیر پارمزان: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "لبنیات",
    "rank_math_title": "پنیر پارمزان | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای پنیر پارمزان در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "پنیر پارمزان",
    "name_app": "پنیر پارمزان",
    "other_names": "پارمزان, Parmesan",
    "food_group": "لبنیات",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "gram",
    "protein": "38",
    "calories": "431",
    "carbohydrates": "4",
    "fat": "29.0",
    "saturated_fat": "10.1",
    "fiber": "0",
    "sugar": "0.5",
    "cholesterol": "15",
    "sodium": "1529",
    "potassium": "207",
    "glycemic_index": "0",
    "allergens": "لبنیات",
    "short_description": "پنیر پارمزان پروتئین و طعم؛ مقدار کم ۱۰–۱۵ گرم.",
    "serving_notes": "ارزش‌ها برای پنیر پارمزان در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "روی سالاد یا ماکارونی.",
    "tip_2": "سدیم بسیار بالا.",
    "tip_3": "رنده شده اندازه بگیرید.",
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
    "legacy_slug": "parmesan-cheese",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1498837167922-ddd27525b352?w=800&q=80",
    "aliases_en": [
      "Parmesan cheese",
      "Parmesan"
    ],
    "related_slugs": [
      "ماست-یونانی-کم‌چرب",
      "پنیر-سفید-کم‌چرب",
      "نان-سنگک-کامل"
    ],
    "intro": "پارمزان طعم‌دهنده پروتئینی است.",
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
    "slug": "شیر-شکلاتی-کم‌چرب",
    "title": "شیر شکلاتی کم‌چرب",
    "excerpt": "مرجع علمی شیر شکلاتی کم‌چرب: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "لبنیات",
    "rank_math_title": "شیر شکلاتی کم‌چرب | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای شیر شکلاتی کم‌چرب در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "شیر شکلاتی کم‌چرب",
    "name_app": "شیر شکلاتی کم‌چرب",
    "other_names": "شیر کاکائو, Chocolate milk",
    "food_group": "لبنیات",
    "food_type": "liquid",
    "meal_times": "بعد تمرین,میان‌وعده",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "3.3",
    "calories": "63",
    "carbohydrates": "9",
    "fat": "1.0",
    "saturated_fat": "0.3",
    "fiber": "0.5",
    "sugar": "1.1",
    "cholesterol": "15",
    "sodium": "60",
    "potassium": "170",
    "glycemic_index": "35",
    "allergens": "لبنیات",
    "short_description": "شیر شکلاتی کم‌چرب ریکاوری کلاسیک بعد تمرین.",
    "serving_notes": "ارزش‌ها برای شیر شکلاتی کم‌چرب در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "یک لیوان بعد تمرین.",
    "tip_2": "قند را در کل روز ببینید.",
    "tip_3": "جایگزین شیک سریع.",
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
    "legacy_slug": "chocolate-milk-low-fat",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80",
    "aliases_en": [
      "Chocolate milk low fat",
      "Choc milk"
    ],
    "related_slugs": [
      "ماست-یونانی-کم‌چرب",
      "پنیر-سفید-کم‌چرب",
      "نان-سنگک-کامل"
    ],
    "intro": "شیر شکلاتی در مطالعات ریکاوری بررسی شده است.",
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
    "slug": "توفو-سفت",
    "title": "توفو سفت",
    "excerpt": "مرجع علمی توفو سفت: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "پروتئین‌ها",
    "rank_math_title": "توفو سفت | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای توفو سفت در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "توفو سفت",
    "name_app": "توفو سفت",
    "other_names": "توفو, Tofu",
    "food_group": "پروتئین",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "palm_protein",
    "protein": "15",
    "calories": "144",
    "carbohydrates": "3",
    "fat": "8.0",
    "saturated_fat": "2.8",
    "fiber": "2",
    "sugar": "0.4",
    "cholesterol": "15",
    "sodium": "14",
    "potassium": "120",
    "glycemic_index": "15",
    "allergens": "سویا",
    "short_description": "توفو پروتئین گیاهی؛ برای گیاهخواران ورزشکار.",
    "serving_notes": "ارزش‌ها برای توفو سفت در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "سرخ کردن کم‌روغن.",
    "tip_2": "۱۵۰ گرم در وعده.",
    "tip_3": "با برنج و سبزی.",
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
    "legacy_slug": "firm-tofu",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80",
    "aliases_en": [
      "Firm tofu",
      "Tofu"
    ],
    "related_slugs": [
      "سینه-مرغ-گریل-شده",
      "تخم‌مرغ-آب‌پز",
      "نان-سنگک-کامل"
    ],
    "intro": "توفو پایه پروتئین گیاهی است.",
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
    "slug": "کره-گیاهی",
    "title": "کره گیاهی",
    "excerpt": "مرجع علمی کره گیاهی: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "چربی‌ها",
    "rank_math_title": "کره گیاهی | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای کره گیاهی در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "کره گیاهی",
    "name_app": "کره گیاهی",
    "other_names": "کره گیاهی, Margarine",
    "food_group": "چربی",
    "food_type": "liquid",
    "meal_times": "صبحانه",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "tablespoon",
    "protein": "0",
    "calories": "720",
    "carbohydrates": "0",
    "fat": "80.0",
    "saturated_fat": "28.0",
    "fiber": "0",
    "sugar": "0",
    "cholesterol": "0",
    "sodium": "640",
    "potassium": "0",
    "glycemic_index": "0",
    "allergens": "",
    "short_description": "کره گیاهی چربی برای نان؛ مقدار کم.",
    "serving_notes": "ارزش‌ها برای کره گیاهی در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "یک قاشق چای‌خوری.",
    "tip_2": "جایگزین کره حیوانی.",
    "tip_3": "در کات محدود.",
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
    "legacy_slug": "margarine",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800&q=80",
    "aliases_en": [
      "Margarine",
      "Plant butter"
    ],
    "related_slugs": [
      "روغن-زیتون",
      "بادام-خام",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "چربی پخش روی نان در صبحانه.",
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
    "slug": "سینه-مرغ-کبابی-تندوری",
    "title": "سینه مرغ کبابی تندوری",
    "excerpt": "مرجع علمی سینه مرغ کبابی تندوری: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "پروتئین‌ها",
    "rank_math_title": "سینه مرغ کبابی تندوری | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای سینه مرغ کبابی تندوری در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "سینه مرغ کبابی تندوری",
    "name_app": "سینه مرغ کبابی تندوری",
    "other_names": "مرغ تندوری, Tandoori chicken",
    "food_group": "پروتئین",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "palm_protein",
    "protein": "31",
    "calories": "165",
    "carbohydrates": "0",
    "fat": "3.6",
    "saturated_fat": "1.3",
    "fiber": "0",
    "sugar": "0",
    "cholesterol": "15",
    "sodium": "95",
    "potassium": "256",
    "glycemic_index": "0",
    "allergens": "",
    "short_description": "سینه مرغ تندوری طعم‌دار بدون چلو؛ با برنج جدا.",
    "serving_notes": "ارزش‌ها برای سینه مرغ کبابی تندوری در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "بدون روغن اضافه.",
    "tip_2": "ادویه بدون شکر زیاد.",
    "tip_3": "با ماست و خیار.",
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
    "legacy_slug": "tandoori-chicken-breast",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80",
    "aliases_en": [
      "Tandoori chicken breast",
      "Spiced chicken"
    ],
    "related_slugs": [
      "سینه-مرغ-گریل-شده",
      "تخم‌مرغ-آب‌پز",
      "نان-سنگک-کامل"
    ],
    "intro": "مرغ تندوری تنوع طعم در رژیم است.",
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
    "slug": "ماکارونی-گندم-کامل-خشک",
    "title": "ماکارونی گندم کامل خشک",
    "excerpt": "مرجع علمی ماکارونی گندم کامل خشک: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "کربوهیدرات‌ها",
    "rank_math_title": "ماکارونی گندم کامل خشک | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای ماکارونی گندم کامل خشک در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "ماکارونی گندم کامل خشک",
    "name_app": "ماکارونی گندم کامل خشک",
    "other_names": "ماکارونی خشک, Dry pasta",
    "food_group": "کربوهیدرات",
    "food_type": "solid",
    "meal_times": "ناهار,بعد تمرین",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "tablespoon",
    "protein": "14",
    "calories": "348",
    "carbohydrates": "67",
    "fat": "2.5",
    "saturated_fat": "0.9",
    "fiber": "8",
    "sugar": "8.0",
    "cholesterol": "0",
    "sodium": "6",
    "potassium": "350",
    "glycemic_index": "50",
    "allergens": "گلوتن",
    "short_description": "ماکارونی گندم کامل خشک — ارزش برای ۱۰۰ گرم خشک؛ پخت جدا.",
    "serving_notes": "ارزش‌ها برای ماکارونی گندم کامل خشک در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "۷۰–۸۰ گرم خشک ≈ یک وعده.",
    "tip_2": "با سس گوجه و مرغ.",
    "tip_3": "بعد تمرین کربو.",
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
    "legacy_slug": "whole-wheat-pasta-dry",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1482049016688-a7bd8fa7e6a1?w=800&q=80",
    "aliases_en": [
      "Whole wheat pasta dry",
      "Dry pasta"
    ],
    "related_slugs": [
      "نان-سنگک-کامل",
      "برنج-سفید-پخته",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "پاستا خشک برای محاسبه دقیق‌تر کربو است.",
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
    "slug": "آب‌میوه-پرتقال-طبیعی",
    "title": "آب‌میوه پرتقال طبیعی",
    "excerpt": "مرجع علمی آب‌میوه پرتقال طبیعی: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "میوه‌ها",
    "rank_math_title": "آب‌میوه پرتقال طبیعی | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای آب‌میوه پرتقال طبیعی در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "آب‌میوه پرتقال طبیعی",
    "name_app": "آب‌میوه پرتقال طبیعی",
    "other_names": "آب پرتقال, OJ",
    "food_group": "میوه",
    "food_type": "liquid",
    "meal_times": "صبحانه,قبل تمرین",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "0.7",
    "calories": "45",
    "carbohydrates": "10",
    "fat": "0.2",
    "saturated_fat": "0.1",
    "fiber": "0.2",
    "sugar": "1.2",
    "cholesterol": "0",
    "sodium": "1",
    "potassium": "200",
    "glycemic_index": "50",
    "allergens": "",
    "short_description": "آب‌میوه پرتقال کربو سریع؛ قبل تمرین صبحگاهی.",
    "serving_notes": "ارزش‌ها برای آب‌میوه پرتقال طبیعی در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "یک لیوان کوچک ۱۵۰ میلی‌لیتر.",
    "tip_2": "میوه کامل فیبر بیشتر دارد.",
    "tip_3": "در کات مقدار کم.",
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
    "legacy_slug": "fresh-orange-juice",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800&q=80",
    "aliases_en": [
      "Fresh orange juice",
      "Orange juice"
    ],
    "related_slugs": [
      "موز",
      "سیب",
      "ماست-یونانی-کم‌چرب"
    ],
    "intro": "آب‌میوه طبیعی انرژی سریع فراهم می‌کند.",
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
    "slug": "نان-پیتا-گندم-کامل",
    "title": "نان پیتا گندم کامل",
    "excerpt": "مرجع علمی نان پیتا گندم کامل: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "کربوهیدرات‌ها",
    "rank_math_title": "نان پیتا گندم کامل | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای نان پیتا گندم کامل در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "نان پیتا گندم کامل",
    "name_app": "نان پیتا گندم کامل",
    "other_names": "نان پیتا, Pita",
    "food_group": "کربوهیدرات",
    "food_type": "solid",
    "meal_times": "صبحانه,ناهار",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "piece",
    "protein": "10",
    "calories": "262",
    "carbohydrates": "55",
    "fat": "2.0",
    "saturated_fat": "0.7",
    "fiber": "6",
    "sugar": "6.6",
    "cholesterol": "0",
    "sodium": "420",
    "potassium": "120",
    "glycemic_index": "57",
    "allergens": "گلوتن",
    "short_description": "نان پیتا گندم کامل برای ساندویچ پروتئین.",
    "serving_notes": "ارزش‌ها برای نان پیتا گندم کامل در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "نیم عدد یا یک عدد کوچک.",
    "tip_2": "با مرغ یا تن.",
    "tip_3": "فیبر بیشتر از نان سفید.",
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
    "legacy_slug": "whole-wheat-pita",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1511690743698-d9d85f2fbf38?w=800&q=80",
    "aliases_en": [
      "Whole wheat pita",
      "Pita bread"
    ],
    "related_slugs": [
      "نان-سنگک-کامل",
      "برنج-سفید-پخته",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "پیتا بسته‌بندی آسان برای meal prep است.",
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
    "slug": "سس-ماست-یونانی",
    "title": "سس ماست یونانی",
    "excerpt": "مرجع علمی سس ماست یونانی: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "لبنیات",
    "rank_math_title": "سس ماست یونانی | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای سس ماست یونانی در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "سس ماست یونانی",
    "name_app": "سس ماست یونانی",
    "other_names": "سس ماست, Yogurt sauce",
    "food_group": "لبنیات",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "8",
    "calories": "120",
    "carbohydrates": "4",
    "fat": "8.0",
    "saturated_fat": "2.8",
    "fiber": "0",
    "sugar": "0.5",
    "cholesterol": "15",
    "sodium": "280",
    "potassium": "140",
    "glycemic_index": "15",
    "allergens": "لبنیات",
    "short_description": "سس ماست یونانی طعم‌دهنده کم‌کالری نسبت به سس خامه.",
    "serving_notes": "ارزش‌ها برای سس ماست یونانی در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "۲–۳ قاشق غذاخوری.",
    "tip_2": "با سالاد یا کباب.",
    "tip_3": "خیار و سیر را در نظر بگیرید.",
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
    "legacy_slug": "greek-yogurt-sauce",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1473093295045-ddd4c915dc20?w=800&q=80",
    "aliases_en": [
      "Greek yogurt sauce",
      "Tzatziki style"
    ],
    "related_slugs": [
      "ماست-یونانی-کم‌چرب",
      "پنیر-سفید-کم‌چرب",
      "نان-سنگک-کامل"
    ],
    "intro": "سس ماست جایگزین سس پرچرب است.",
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
    "slug": "شکلات-تلخ-۸۵٪",
    "title": "شکلات تلخ ۸۵٪",
    "excerpt": "مرجع علمی شکلات تلخ ۸۵٪: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "چربی‌ها",
    "rank_math_title": "شکلات تلخ ۸۵٪ | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای شکلات تلخ ۸۵٪ در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "شکلات تلخ ۸۵٪",
    "name_app": "شکلات تلخ ۸۵٪",
    "other_names": "شکلات تلخ, Dark chocolate",
    "food_group": "چربی",
    "food_type": "solid",
    "meal_times": "میان‌وعده",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "gram",
    "protein": "7",
    "calories": "580",
    "carbohydrates": "34",
    "fat": "46.0",
    "saturated_fat": "16.1",
    "fiber": "11",
    "sugar": "4.1",
    "cholesterol": "0",
    "sodium": "12",
    "potassium": "420",
    "glycemic_index": "25",
    "allergens": "",
    "short_description": "شکلات تلخ آنتی‌اکسیدان و چربی؛ ۲۰–۲۵ گرم در کات.",
    "serving_notes": "ارزش‌ها برای شکلات تلخ ۸۵٪ در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "درصد کاکائو بالاتر = قند کمتر.",
    "tip_2": "بعد غذا مقدار کم.",
    "tip_3": "جایگزین دسر پرقند.",
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
    "legacy_slug": "dark-chocolate-85",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1455619452474-d2be8b1e70cb?w=800&q=80",
    "aliases_en": [
      "Dark chocolate 85",
      "Dark chocolate"
    ],
    "related_slugs": [
      "روغن-زیتون",
      "بادام-خام",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "شکلات تلخ در میان‌وعده کنترل‌شده رایج است.",
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
  }
]
GYMAI_FOOD_BATCH15
        , true);
        return is_array($cache) ? $cache : array();
    }
}
