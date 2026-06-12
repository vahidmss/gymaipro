// GymAI Foods — BATCH 7 (خوراکی 61–70)
// Code Snippets: Run everywhere | بدون تگ php
// یا کپی در: wp-content/gymai-seed/food-batch7.php

if (!function_exists('gymai_food_batch7_definitions')) {
    function gymai_food_batch7_definitions() {
        static $cache = null;
        if ($cache !== null) {
            return $cache;
        }
        $cache = json_decode(<<<'GYMAI_FOOD_BATCH7'
[
  {
    "slug": "گردو-خام",
    "title": "گردو خام",
    "excerpt": "مرجع علمی گردو خام: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "چربی‌های سالم",
    "rank_math_title": "گردو خام | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای گردو خام در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "گردو خام",
    "name_app": "گردو خام",
    "other_names": "گردو, Walnuts",
    "food_group": "چربی",
    "food_type": "solid",
    "meal_times": "میان‌وعده,صبحانه",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "gram",
    "protein": "15",
    "calories": "654",
    "carbohydrates": "14",
    "fat": "65.0",
    "saturated_fat": "22.8",
    "fiber": "6.7",
    "sugar": "1.7",
    "cholesterol": "0",
    "sodium": "2",
    "potassium": "441",
    "glycemic_index": "15",
    "allergens": "گردو",
    "short_description": "گردو ALA omega-3 و چربی unsaturated دارد.",
    "serving_notes": "ارزش‌ها برای گردو خام در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "وعده ۲۵–۳۰ گرم.",
    "tip_2": "روی ماست یا سالاد.",
    "tip_3": "بدون نمک.",
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
    "legacy_slug": "walnuts-raw",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1498837167922-ddd27525b352?w=800&q=80",
    "aliases_en": [
      "Walnuts raw",
      "Walnuts"
    ],
    "related_slugs": [
      "روغن-زیتون",
      "بادام-خام",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "مغزها در رژیم قلب و مغز.",
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
    "slug": "پسته-خام",
    "title": "پسته خام",
    "excerpt": "مرجع علمی پسته خام: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "چربی‌های سالم",
    "rank_math_title": "پسته خام | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای پسته خام در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "پسته خام",
    "name_app": "پسته خام",
    "other_names": "پسته, Pistachios",
    "food_group": "چربی",
    "food_type": "solid",
    "meal_times": "میان‌وعده",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "gram",
    "protein": "20",
    "calories": "560",
    "carbohydrates": "28",
    "fat": "45.0",
    "saturated_fat": "15.7",
    "fiber": "10",
    "sugar": "3.4",
    "cholesterol": "0",
    "sodium": "1",
    "potassium": "1025",
    "glycemic_index": "15",
    "allergens": "پسته",
    "short_description": "پسته پروتئین و فیبر در مغزها؛ پوست کند کردن مصرف.",
    "serving_notes": "ارزش‌ها برای پسته خام در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "وعده ۳۰ گرم.",
    "tip_2": "بدون نمک اضافه.",
    "tip_3": "میان‌وعده سیری.",
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
    "legacy_slug": "pistachios-raw",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80",
    "aliases_en": [
      "Pistachios raw",
      "Pistachios"
    ],
    "related_slugs": [
      "روغن-زیتون",
      "بادام-خام",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "پسته در مطالعات lipid profile مثبت است.",
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
    "slug": "تخمه-آفتابگردان",
    "title": "تخمه آفتابگردان",
    "excerpt": "مرجع علمی تخمه آفتابگردان: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "چربی‌های سالم",
    "rank_math_title": "تخمه آفتابگردان | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای تخمه آفتابگردان در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "تخمه آفتابگردان",
    "name_app": "تخمه آفتابگردان",
    "other_names": "تخمه, Sunflower seeds",
    "food_group": "چربی",
    "food_type": "solid",
    "meal_times": "میان‌وعده",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "gram",
    "protein": "21",
    "calories": "584",
    "carbohydrates": "20",
    "fat": "51.0",
    "saturated_fat": "17.8",
    "fiber": "8.6",
    "sugar": "2.4",
    "cholesterol": "0",
    "sodium": "9",
    "potassium": "645",
    "glycemic_index": "20",
    "allergens": "",
    "short_description": "تخمه ویتامین E و چربی سالم.",
    "serving_notes": "ارزش‌ها برای تخمه آفتابگردان در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "وعده کوچک کالری بالا.",
    "tip_2": "روی سالاد.",
    "tip_3": "بدون نمک.",
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
    "legacy_slug": "sunflower-seeds",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80",
    "aliases_en": [
      "Sunflower seeds",
      "Sunflower seeds"
    ],
    "related_slugs": [
      "روغن-زیتون",
      "بادام-خام",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "ویتامین E آنتی‌اکسیدant lipid-soluble.",
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
    "slug": "کره-بادام‌زمینی",
    "title": "کره بادام‌زمینی",
    "excerpt": "مرجع علمی کره بادام‌زمینی: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "چربی‌های سالم",
    "rank_math_title": "کره بادام‌زمینی | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای کره بادام‌زمینی در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "کره بادام‌زمینی",
    "name_app": "کره بادام‌زمینی",
    "other_names": "کره بادام‌زمینی, Peanut butter",
    "food_group": "چربی",
    "food_type": "solid",
    "meal_times": "صبحانه,میان‌وعده",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "gram",
    "protein": "25",
    "calories": "588",
    "carbohydrates": "20",
    "fat": "50.0",
    "saturated_fat": "17.5",
    "fiber": "6",
    "sugar": "2.4",
    "cholesterol": "0",
    "sodium": "459",
    "potassium": "649",
    "glycemic_index": "25",
    "allergens": "بادام‌زمندی",
    "short_description": "کره بادام‌زمندی پروتئین و چربی؛ انرژی فشرده.",
    "serving_notes": "ارزش‌ها برای کره بادام‌زمینی در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "نسخه بدون شکر.",
    "tip_2": "یک قاشق غذاخوری.",
    "tip_3": "با سیب یا نان.",
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
    "legacy_slug": "peanut-butter",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800&q=80",
    "aliases_en": [
      "Peanut butter",
      "Natural peanut butter"
    ],
    "related_slugs": [
      "روغن-زیتون",
      "بادام-خام",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "nut butter در حجم‌گیری محبوب.",
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
    "slug": "کره",
    "title": "کره",
    "excerpt": "مرجع علمی کره: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "چربی‌های سالم",
    "rank_math_title": "کره | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای کره در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "کره",
    "name_app": "کره",
    "other_names": "کره, Butter",
    "food_group": "چربی",
    "food_type": "liquid",
    "meal_times": "صبحانه",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "tablespoon",
    "protein": "0.9",
    "calories": "717",
    "carbohydrates": "0.1",
    "fat": "81.0",
    "saturated_fat": "28.3",
    "fiber": "0",
    "sugar": "0",
    "cholesterol": "0",
    "sodium": "11",
    "potassium": "24",
    "glycemic_index": "0",
    "allergens": "لبنیات",
    "short_description": "کره چربی saturated؛ مصرف محدود.",
    "serving_notes": "ارزش‌ها برای کره در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "کم برای طعم.",
    "tip_2": "جایگزین روغن زیتون.",
    "tip_3": "در پخت حساب کنید.",
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
    "legacy_slug": "butter",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80",
    "aliases_en": [
      "Butter",
      "Unsalted butter"
    ],
    "related_slugs": [
      "روغن-زیتون",
      "بادام-خام",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "saturated fat moderation.",
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
    "slug": "ماست-چکیده",
    "title": "ماست چکیده",
    "excerpt": "مرجع علمی ماست چکیده: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "لبنیات",
    "rank_math_title": "ماست چکیده | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای ماست چکیده در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "ماست چکیده",
    "name_app": "ماست چکیده",
    "other_names": "ماست چکیده, Labneh",
    "food_group": "لبنیات",
    "food_type": "solid",
    "meal_times": "صبحانه,ناهار,میان‌وعده",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "10",
    "calories": "120",
    "carbohydrates": "4",
    "fat": "6.0",
    "saturated_fat": "2.1",
    "fiber": "0",
    "sugar": "0.5",
    "cholesterol": "15",
    "sodium": "40",
    "potassium": "150",
    "glycemic_index": "11",
    "allergens": "لبنیات",
    "short_description": "ماست چکیده پروتئین غلیظ و probiotic دارد.",
    "serving_notes": "ارزش‌ها برای ماست چکیده در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "با زیتون و نان.",
    "tip_2": "جایگزین خامه.",
    "tip_3": "صبحانه پروتئینی.",
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
    "legacy_slug": "strained-yogurt",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1482049016688-a7bd8fa7e6a1?w=800&q=80",
    "aliases_en": [
      "Strained yogurt",
      "Labneh"
    ],
    "related_slugs": [
      "ماست-یونانی-کم‌چرب",
      "پنیر-سفید-کم‌چرب",
      "نان-سنگک-کامل"
    ],
    "intro": "fermented dairy برای gut.",
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
    "slug": "دوغ-کم‌نمک",
    "title": "دوغ کم‌نمک",
    "excerpt": "مرجع علمی دوغ کم‌نمک: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "لبنیات",
    "rank_math_title": "دوغ کم‌نمک | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای دوغ کم‌نمک در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "دوغ کم‌نمک",
    "name_app": "دوغ کم‌نمک",
    "other_names": "دوغ, Doogh",
    "food_group": "لبنیات",
    "food_type": "liquid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "3.3",
    "calories": "40",
    "carbohydrates": "4",
    "fat": "1.5",
    "saturated_fat": "0.5",
    "fiber": "0",
    "sugar": "0.5",
    "cholesterol": "15",
    "sodium": "120",
    "potassium": "150",
    "glycemic_index": "32",
    "allergens": "لبنیات",
    "short_description": "دوغ probiotic و hydration؛ سنتی ایرانی.",
    "serving_notes": "ارزش‌ها برای دوغ کم‌نمک در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "کم‌نمک.",
    "tip_2": "با کباب.",
    "tip_3": "بعد غذای چرب.",
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
    "legacy_slug": "doogh-low-salt",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800&q=80",
    "aliases_en": [
      "Doogh low salt",
      "Ayran"
    ],
    "related_slugs": [
      "ماست-یونانی-کم‌چرب",
      "پنیر-سفید-کم‌چرب",
      "نان-سنگک-کامل"
    ],
    "intro": "fermented drink electrolytes.",
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
    "slug": "پنیر-لبنه",
    "title": "پنیر لبنه",
    "excerpt": "مرجع علمی پنیر لبنه: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "لبنیات",
    "rank_math_title": "پنیر لبنه | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای پنیر لبنه در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "پنیر لبنه",
    "name_app": "پنیر لبنه",
    "other_names": "لبنه, Labneh",
    "food_group": "لبنیات",
    "food_type": "solid",
    "meal_times": "صبحانه,میان‌وعده",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "8",
    "calories": "175",
    "carbohydrates": "6",
    "fat": "14.0",
    "saturated_fat": "4.9",
    "fiber": "0",
    "sugar": "0.7",
    "cholesterol": "15",
    "sodium": "380",
    "potassium": "120",
    "glycemic_index": "27",
    "allergens": "لبنیات",
    "short_description": "لبنه پروتئین و چربی متوسط.",
    "serving_notes": "ارزش‌ها برای پنیر لبنه در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "با خیار.",
    "tip_2": "روی نان سنگک.",
    "tip_3": "صبحانه.",
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
    "legacy_slug": "labneh-cheese",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1511690743698-d9d85f2fbf38?w=800&q=80",
    "aliases_en": [
      "Labneh cheese",
      "Soft cheese"
    ],
    "related_slugs": [
      "ماست-یونانی-کم‌چرب",
      "پنیر-سفید-کم‌چرب",
      "نان-سنگک-کامل"
    ],
    "intro": "لبنه در رژیم مدیترانه‌ای.",
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
    "slug": "روغن-کانولا",
    "title": "روغن کانولا",
    "excerpt": "مرجع علمی روغن کانولا: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "چربی‌های سالم",
    "rank_math_title": "روغن کانولا | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای روغن کانولا در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "روغن کانولا",
    "name_app": "روغن کانولا",
    "other_names": "روغن کانولا, Canola oil",
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
    "short_description": "روغن کانولا unsaturated و omega-6/3 متعادل.",
    "serving_notes": "ارزش‌ها برای روغن کانولا در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "یک قاشق برای پخت.",
    "tip_2": "دمای دود بالا.",
    "tip_3": "جایگزین روغن نباتی.",
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
    "legacy_slug": "canola-oil",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1473093295045-ddd4c915dc20?w=800&q=80",
    "aliases_en": [
      "Canola oil",
      "Rapeseed oil"
    ],
    "related_slugs": [
      "روغن-زیتون",
      "بادام-خام",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "oil moderation در رژیم.",
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
    "slug": "آووکادو",
    "title": "آووکادو",
    "excerpt": "مرجع علمی آووکادو: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "چربی‌های سالم",
    "rank_math_title": "آووکادو | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای آووکادو در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "آووکادو",
    "name_app": "آووکادو",
    "other_names": "آووکادو, Avocado",
    "food_group": "چربی",
    "food_type": "solid",
    "meal_times": "صبحانه,ناهار",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "piece",
    "protein": "2",
    "calories": "160",
    "carbohydrates": "9",
    "fat": "15.0",
    "saturated_fat": "5.2",
    "fiber": "7",
    "sugar": "1.1",
    "cholesterol": "0",
    "sodium": "7",
    "potassium": "485",
    "glycemic_index": "15",
    "allergens": "",
    "short_description": "آووکادو MUFA و فیبر؛ چربی سالم.",
    "serving_notes": "ارزش‌ها برای آووکادو در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "نیم عدد وعده.",
    "tip_2": "با تخم‌مرغ.",
    "tip_3": "در سالاد.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "piece",
      "units": [
        {
          "key": "piece",
          "label": "عدد متوسط",
          "grams": 120,
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
    "legacy_slug": "avocado",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1455619452474-d2be8b1e70cb?w=800&q=80",
    "aliases_en": [
      "Avocado",
      "Fresh avocado"
    ],
    "related_slugs": [
      "روغن-زیتون",
      "بادام-خام",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "MUFA برای satiety.",
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
GYMAI_FOOD_BATCH7
        , true);
        return is_array($cache) ? $cache : array();
    }
}
