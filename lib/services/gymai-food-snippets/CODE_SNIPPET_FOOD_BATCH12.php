// GymAI Foods — BATCH 12 (خوراکی 111–120)
// Code Snippets: Run everywhere | بدون تگ php
// یا کپی در: wp-content/gymai-seed/food-batch12.php

if (!function_exists('gymai_food_batch12_definitions')) {
    function gymai_food_batch12_definitions() {
        static $cache = null;
        if ($cache !== null) {
            return $cache;
        }
        $cache = json_decode(<<<'GYMAI_FOOD_BATCH12'
[
  {
    "slug": "ساردین-کنسروی-در-روغن-زیتون",
    "title": "ساردین کنسروی در روغن زیتون",
    "excerpt": "مرجع علمی ساردین کنسروی در روغن زیتون: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "پروتئین‌ها",
    "rank_math_title": "ساردین کنسروی در روغن زیتون | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای ساردین کنسروی در روغن زیتون در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "ساردین کنسروی در روغن زیتون",
    "name_app": "ساردین کنسروی در روغن زیتون",
    "other_names": "ساردین, Sardines",
    "food_group": "پروتئین",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "palm_protein",
    "protein": "25",
    "calories": "208",
    "carbohydrates": "0",
    "fat": "11.0",
    "saturated_fat": "3.8",
    "fiber": "0",
    "sugar": "0",
    "cholesterol": "15",
    "sodium": "505",
    "potassium": "397",
    "glycemic_index": "0",
    "allergens": "ماهی",
    "short_description": "ساردین پروتئین، کلسیم و امگا۳؛ اقتصادی و سریع.",
    "serving_notes": "ارزش‌ها برای ساردین کنسروی در روغن زیتون در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "روغن اضافه را کنترل کنید.",
    "tip_2": "با نان سنگک یا برنج.",
    "tip_3": "یک قوطی کوچک حدود ۹۰ گرم.",
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
    "legacy_slug": "canned-sardines",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1498837167922-ddd27525b352?w=800&q=80",
    "aliases_en": [
      "Canned sardines",
      "Sardines"
    ],
    "related_slugs": [
      "سینه-مرغ-گریل-شده",
      "تخم‌مرغ-آب‌پز",
      "نان-سنگک-کامل"
    ],
    "intro": "ساردین از ماهی‌های پرچرب مقرون‌به‌صرفه است.",
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
    "slug": "ران-مرغ-بدون-پوست-پخته",
    "title": "ران مرغ بدون پوست پخته",
    "excerpt": "مرجع علمی ران مرغ بدون پوست پخته: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "پروتئین‌ها",
    "rank_math_title": "ران مرغ بدون پوست پخته | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای ران مرغ بدون پوست پخته در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "ران مرغ بدون پوست پخته",
    "name_app": "ران مرغ بدون پوست پخته",
    "other_names": "ران مرغ, Chicken thigh",
    "food_group": "پروتئین",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "palm_protein",
    "protein": "24",
    "calories": "177",
    "carbohydrates": "0",
    "fat": "8.0",
    "saturated_fat": "2.8",
    "fiber": "0",
    "sugar": "0",
    "cholesterol": "15",
    "sodium": "82",
    "potassium": "240",
    "glycemic_index": "0",
    "allergens": "",
    "short_description": "ران مرغ بدون پوست طعم بهتر با چربی متعادل‌تر از سینه.",
    "serving_notes": "ارزش‌ها برای ران مرغ بدون پوست پخته در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "پوست را جدا کنید.",
    "tip_2": "در فر بدون روغن اضافه.",
    "tip_3": "برای حجم‌گیری گزینه خوبی است.",
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
    "legacy_slug": "chicken-thigh-cooked",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80",
    "aliases_en": [
      "Chicken thigh cooked",
      "Chicken leg"
    ],
    "related_slugs": [
      "سینه-مرغ-گریل-شده",
      "تخم‌مرغ-آب‌پز",
      "نان-سنگک-کامل"
    ],
    "intro": "ران مرغ جایگزین سینه برای تنوع طعم است.",
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
    "slug": "فیله-قزل‌آلای-دودی",
    "title": "فیله قزل‌آلای دودی",
    "excerpt": "مرجع علمی فیله قزل‌آلای دودی: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "پروتئین‌ها",
    "rank_math_title": "فیله قزل‌آلای دودی | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای فیله قزل‌آلای دودی در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "فیله قزل‌آلای دودی",
    "name_app": "فیله قزل‌آلای دودی",
    "other_names": "قزل دودی, Smoked fish",
    "food_group": "پروتئین",
    "food_type": "solid",
    "meal_times": "صبحانه,ناهار",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "palm_protein",
    "protein": "18",
    "calories": "117",
    "carbohydrates": "0",
    "fat": "4.3",
    "saturated_fat": "1.5",
    "fiber": "0",
    "sugar": "0",
    "cholesterol": "15",
    "sodium": "672",
    "potassium": "175",
    "glycemic_index": "0",
    "allergens": "ماهی",
    "short_description": "ماهی دودی پروتئین و چربی سالم؛ صبحانه یا سالاد.",
    "serving_notes": "ارزش‌ها برای فیله قزل‌آلای دودی در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "سدیم دودی را در نظر بگیرید.",
    "tip_2": "با تخم‌مرغ و نان.",
    "tip_3": "برش نازک ۸۰–۱۰۰ گرم.",
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
    "legacy_slug": "smoked-salmon",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80",
    "aliases_en": [
      "Smoked salmon",
      "Smoked trout"
    ],
    "related_slugs": [
      "سینه-مرغ-گریل-شده",
      "تخم‌مرغ-آب‌پز",
      "نان-سنگک-کامل"
    ],
    "intro": "ماهی دودی در رژیم‌های حرفه‌ای رایج است.",
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
    "slug": "پروتئین-بار",
    "title": "پروتئین بار",
    "excerpt": "مرجع علمی پروتئین بار: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "مکمل‌ها",
    "rank_math_title": "پروتئین بار | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای پروتئین بار در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "پروتئین بار",
    "name_app": "پروتئین بار",
    "other_names": "پروتئین بار, Protein bar",
    "food_group": "مکمل",
    "food_type": "solid",
    "meal_times": "میان‌وعده,بعد تمرین",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "20",
    "calories": "350",
    "carbohydrates": "35",
    "fat": "12.0",
    "saturated_fat": "4.2",
    "fiber": "5",
    "sugar": "4.2",
    "cholesterol": "0",
    "sodium": "200",
    "potassium": "180",
    "glycemic_index": "45",
    "allergens": "گلوتن, لبنیات, سویا",
    "short_description": "پروتئین بار میان‌وعده سریع؛ برچسب قند را بخوانید.",
    "serving_notes": "ارزش‌ها برای پروتئین بار در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "یک عدد معمولاً ۶۰–۷۰ گرم.",
    "tip_2": "برای سفر و بین وعده.",
    "tip_3": "جایگزین کامل وعده نیست.",
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
    "legacy_slug": "protein-bar",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800&q=80",
    "aliases_en": [
      "Protein bar",
      "Energy protein bar"
    ],
    "related_slugs": [
      "پودر-وی-پروتئین",
      "پودر-کراتین-مونوهیدرات",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "پروتئین بار در برنامه‌های شلوغ کاربرد دارد.",
    "substitutes": [
      {
        "slug": "پودر-وی-پروتئین",
        "ratio": 1.0
      },
      {
        "slug": "پودر-کراتین-مونوهیدرات",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "شیر-سویا",
    "title": "شیر سویا",
    "excerpt": "مرجع علمی شیر سویا: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "لبنیات",
    "rank_math_title": "شیر سویا | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای شیر سویا در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "شیر سویا",
    "name_app": "شیر سویا",
    "other_names": "شیر سویا, Soy milk",
    "food_group": "لبنیات",
    "food_type": "liquid",
    "meal_times": "صبحانه,میان‌وعده",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "2.9",
    "calories": "33",
    "carbohydrates": "1.8",
    "fat": "1.6",
    "saturated_fat": "0.6",
    "fiber": "0.3",
    "sugar": "0.2",
    "cholesterol": "15",
    "sodium": "51",
    "potassium": "118",
    "glycemic_index": "30",
    "allergens": "سویا",
    "short_description": "شیر سویا جایگزین گیاهی شیر؛ پروتئین متوسط.",
    "serving_notes": "ارزش‌ها برای شیر سویا در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "نسخه بدون قند اضافه.",
    "tip_2": "با جو دوسر صبحانه.",
    "tip_3": "برای حساسیت به لبنیات.",
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
    "legacy_slug": "soy-milk",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80",
    "aliases_en": [
      "Soy milk",
      "Unsweetened soy milk"
    ],
    "related_slugs": [
      "ماست-یونانی-کم‌چرب",
      "پنیر-سفید-کم‌چرب",
      "نان-سنگک-کامل"
    ],
    "intro": "شیر سویا در رژیم گیاهخواری ورزشی رایج است.",
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
    "slug": "جو-دوسر-خام",
    "title": "جو دوسر خام",
    "excerpt": "مرجع علمی جو دوسر خام: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "کربوهیدرات‌ها",
    "rank_math_title": "جو دوسر خام | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای جو دوسر خام در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "جو دوسر خام",
    "name_app": "جو دوسر خام",
    "other_names": "جو پرک خام, Oats dry",
    "food_group": "کربوهیدرات",
    "food_type": "solid",
    "meal_times": "صبحانه,قبل تمرین",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "tablespoon",
    "protein": "17",
    "calories": "389",
    "carbohydrates": "66",
    "fat": "7.0",
    "saturated_fat": "2.4",
    "fiber": "10",
    "sugar": "7.9",
    "cholesterol": "0",
    "sodium": "2",
    "potassium": "429",
    "glycemic_index": "55",
    "allergens": "گلوتن",
    "short_description": "جو دوسر خام فیبر و انرژی پایدار؛ صبحانه بدنسازی.",
    "serving_notes": "ارزش‌ها برای جو دوسر خام در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "۴۰–۶۰ گرم خشک قبل پخت.",
    "tip_2": "با شیر یا وی ترکیب شود.",
    "tip_3": "قبل تمرین صبحگاهی.",
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
    "legacy_slug": "raw-oats",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1482049016688-a7bd8fa7e6a1?w=800&q=80",
    "aliases_en": [
      "Raw oats",
      "Rolled oats dry"
    ],
    "related_slugs": [
      "نان-سنگک-کامل",
      "برنج-سفید-پخته",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "جو دوسر خام پایه اصلی صبحانه ورزشکاران است.",
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
    "slug": "برنجکیک",
    "title": "برنجکیک",
    "excerpt": "مرجع علمی برنجکیک: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "کربوهیدرات‌ها",
    "rank_math_title": "برنجکیک | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای برنجکیک در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "برنجکیک",
    "name_app": "برنجکیک",
    "other_names": "برنجکیک, Rice cake",
    "food_group": "کربوهیدرات",
    "food_type": "solid",
    "meal_times": "قبل تمرین,میان‌وعده",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "piece",
    "protein": "8",
    "calories": "387",
    "carbohydrates": "82",
    "fat": "2.8",
    "saturated_fat": "1.0",
    "fiber": "2.4",
    "sugar": "9.8",
    "cholesterol": "0",
    "sodium": "29",
    "potassium": "280",
    "glycemic_index": "82",
    "allergens": "",
    "short_description": "برنجکیک کربو سریع و کم‌حجم؛ قبل تمرین محبوب.",
    "serving_notes": "ارزش‌ها برای برنجکیک در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "۱–۲ عدد با عسل یا کره بادام‌زمینی.",
    "tip_2": "۱۵–۳۰ دقیقه قبل تمرین.",
    "tip_3": "هر عدد حدود ۹ گرم.",
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
    "legacy_slug": "rice-cake",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800&q=80",
    "aliases_en": [
      "Rice cake",
      "Rice cakes"
    ],
    "related_slugs": [
      "نان-سنگک-کامل",
      "برنج-سفید-پخته",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "برنجکیک در پرورش اندام بسیار شناخته شده است.",
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
    "slug": "نان-پروتئینی",
    "title": "نان پروتئینی",
    "excerpt": "مرجع علمی نان پروتئینی: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "کربوهیدرات‌ها",
    "rank_math_title": "نان پروتئینی | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای نان پروتئینی در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "نان پروتئینی",
    "name_app": "نان پروتئینی",
    "other_names": "نان پرو, Protein bread",
    "food_group": "کربوهیدرات",
    "food_type": "solid",
    "meal_times": "صبحانه,میان‌وعده",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "piece",
    "protein": "22",
    "calories": "250",
    "carbohydrates": "28",
    "fat": "5.0",
    "saturated_fat": "1.8",
    "fiber": "8",
    "sugar": "3.4",
    "cholesterol": "0",
    "sodium": "420",
    "potassium": "160",
    "glycemic_index": "45",
    "allergens": "گلوتن, سویا",
    "short_description": "نان پروتئینی کربو + پروتئین؛ صبحانه یا میان‌وعده.",
    "serving_notes": "ارزش‌ها برای نان پروتئینی در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "یک برش ۳۵–۴۰ گرم.",
    "tip_2": "با تخم‌مرغ یا پنیر.",
    "tip_3": "برچسب فیبر را ببینید.",
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
    "legacy_slug": "protein-bread",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1511690743698-d9d85f2fbf38?w=800&q=80",
    "aliases_en": [
      "Protein bread",
      "High protein bread"
    ],
    "related_slugs": [
      "نان-سنگک-کامل",
      "برنج-سفید-پخته",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "نان پروتئینی ترکیب کربو و پروتئین در یک آیتم است.",
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
    "slug": "ذرت-فلک",
    "title": "ذرت فلک",
    "excerpt": "مرجع علمی ذرت فلک: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "کربوهیدرات‌ها",
    "rank_math_title": "ذرت فلک | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای ذرت فلک در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "ذرت فلک",
    "name_app": "ذرت فلک",
    "other_names": "کورن فلکس, Corn flakes",
    "food_group": "کربوهیدرات",
    "food_type": "solid",
    "meal_times": "صبحانه,میان‌وعده",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "tablespoon",
    "protein": "8",
    "calories": "357",
    "carbohydrates": "84",
    "fat": "0.4",
    "saturated_fat": "0.1",
    "fiber": "3",
    "sugar": "10.1",
    "cholesterol": "0",
    "sodium": "268",
    "potassium": "52",
    "glycemic_index": "81",
    "allergens": "گلوتن",
    "short_description": "ذرت فلک صبحانه سریع؛ با شیر پروتئین بالا می‌رود.",
    "serving_notes": "ارزش‌ها برای ذرت فلک در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "۴۰–۵۰ گرم با شیر.",
    "tip_2": "قند افزوده را کنترل کنید.",
    "tip_3": "قبل تمرین صبحگاهی.",
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
    "legacy_slug": "corn-flakes",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1473093295045-ddd4c915dc20?w=800&q=80",
    "aliases_en": [
      "Corn flakes",
      "Breakfast cereal"
    ],
    "related_slugs": [
      "نان-سنگک-کامل",
      "برنج-سفید-پخته",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "غلات صبحانه در برنامه حجم رایج است.",
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
    "slug": "نان-تست-سفید",
    "title": "نان تست سفید",
    "excerpt": "مرجع علمی نان تست سفید: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "کربوهیدرات‌ها",
    "rank_math_title": "نان تست سفید | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای نان تست سفید در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "نان تست سفید",
    "name_app": "نان تست سفید",
    "other_names": "نان تست, Toast",
    "food_group": "کربوهیدرات",
    "food_type": "solid",
    "meal_times": "صبحانه,میان‌وعده",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "piece",
    "protein": "9",
    "calories": "265",
    "carbohydrates": "49",
    "fat": "3.2",
    "saturated_fat": "1.1",
    "fiber": "2.7",
    "sugar": "5.9",
    "cholesterol": "0",
    "sodium": "491",
    "potassium": "115",
    "glycemic_index": "75",
    "allergens": "گلوتن",
    "short_description": "نان تست سفید کربو سریع؛ با ژامبون یا تخم‌مرغ.",
    "serving_notes": "ارزش‌ها برای نان تست سفید در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "۱–۲ برش در هر وعده.",
    "tip_2": "با پروتئین ترکیب کنید.",
    "tip_3": "برای قبل تمرین سریع.",
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
    "legacy_slug": "white-toast",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1455619452474-d2be8b1e70cb?w=800&q=80",
    "aliases_en": [
      "White toast",
      "White bread toast"
    ],
    "related_slugs": [
      "نان-سنگک-کامل",
      "برنج-سفید-پخته",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "نان تست ساده و در دسترس است.",
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
GYMAI_FOOD_BATCH12
        , true);
        return is_array($cache) ? $cache : array();
    }
}
