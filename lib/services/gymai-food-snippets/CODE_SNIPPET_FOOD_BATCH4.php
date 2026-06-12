// GymAI Foods — BATCH 4 (خوراکی 31–40)
// Code Snippets: Run everywhere | بدون تگ php
// یا کپی در: wp-content/gymai-seed/food-batch4.php

if (!function_exists('gymai_food_batch4_definitions')) {
    function gymai_food_batch4_definitions() {
        static $cache = null;
        if ($cache !== null) {
            return $cache;
        }
        $cache = json_decode(<<<'GYMAI_FOOD_BATCH4'
[
  {
    "slug": "لوبیا-قرمز-پخته",
    "title": "لوبیا قرمز پخته",
    "excerpt": "مرجع علمی لوبیا قرمز پخته: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "حبوبات",
    "rank_math_title": "لوبیا قرمز پخته | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای لوبیا قرمز پخته در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "لوبیا قرمز پخته",
    "name_app": "لوبیا قرمز پخته",
    "other_names": "لوبیا قرمز, Kidney beans",
    "food_group": "حبوبات",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "tablespoon",
    "protein": "8.7",
    "calories": "127",
    "carbohydrates": "23",
    "fat": "0.5",
    "saturated_fat": "0.2",
    "fiber": "6.4",
    "sugar": "2.8",
    "cholesterol": "0",
    "sodium": "2",
    "potassium": "405",
    "glycemic_index": "29",
    "allergens": "",
    "short_description": "لوبیا قرمز پروتئین گیاهی، فیبر و آهن دارد؛ GI پایین برای سیری طولانی.",
    "serving_notes": "ارزش‌ها برای لوبیا قرمز پخته در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "خیساندن و پخت کامل هضم را بهتر می‌کند.",
    "tip_2": "با برنج پروتئین کامل‌تر.",
    "tip_3": "در خوراک لوبیا ایرانی.",
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
    "legacy_slug": "cooked-kidney-beans",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1498837167922-ddd27525b352?w=800&q=80",
    "aliases_en": [
      "Cooked kidney beans",
      "Kidney beans"
    ],
    "related_slugs": [
      "عدس-پخته",
      "نخود-پخته",
      "نان-سنگک-کامل"
    ],
    "intro": "حبوبات در رژیم گیاهخواران ورزشکار پایه است.",
    "substitutes": [
      {
        "slug": "عدس-پخته",
        "ratio": 1.0
      },
      {
        "slug": "نخود-پخته",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "نخود-پخته",
    "title": "نخود پخته",
    "excerpt": "مرجع علمی نخود پخته: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "حبوبات",
    "rank_math_title": "نخود پخته | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای نخود پخته در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "نخود پخته",
    "name_app": "نخود پخته",
    "other_names": "نخود, Chickpeas",
    "food_group": "حبوبات",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "tablespoon",
    "protein": "8.9",
    "calories": "164",
    "carbohydrates": "27",
    "fat": "2.6",
    "saturated_fat": "0.9",
    "fiber": "7.6",
    "sugar": "3.2",
    "cholesterol": "0",
    "sodium": "7",
    "potassium": "291",
    "glycemic_index": "28",
    "allergens": "",
    "short_description": "نخود پروتئین و فیبر بالا؛ پایه حمص و غذاهای گیاهی.",
    "serving_notes": "ارزش‌ها برای نخود پخته در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "حمص خانگی بدون روغن زیاد.",
    "tip_2": "با برنج یا نان سنگک.",
    "tip_3": "کنسرو را آبکش کنید.",
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
    "legacy_slug": "cooked-chickpeas",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80",
    "aliases_en": [
      "Cooked chickpeas",
      "Chickpeas"
    ],
    "related_slugs": [
      "عدس-پخته",
      "لوبیا-قرمز-پخته",
      "نان-سنگک-کامل"
    ],
    "intro": "نخود در مطالعات سیتری satiety مورد بررسی است.",
    "substitutes": [
      {
        "slug": "عدس-پخته",
        "ratio": 1.0
      },
      {
        "slug": "لوبیا-قرمز-پخته",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "لپه-پخته",
    "title": "لپه پخته",
    "excerpt": "مرجع علمی لپه پخته: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "حبوبات",
    "rank_math_title": "لپه پخته | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای لپه پخته در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "لپه پخته",
    "name_app": "لپه پخته",
    "other_names": "لپه, Split peas",
    "food_group": "حبوبات",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "tablespoon",
    "protein": "9",
    "calories": "116",
    "carbohydrates": "20",
    "fat": "0.4",
    "saturated_fat": "0.1",
    "fiber": "7.9",
    "sugar": "2.4",
    "cholesterol": "0",
    "sodium": "2",
    "potassium": "384",
    "glycemic_index": "32",
    "allergens": "",
    "short_description": "لپه فیبر محلول و پروتئین دارد؛ برای آش و خوراک ایرانی.",
    "serving_notes": "ارزش‌ها برای لپه پخته در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "پخت در آش انرژی یکنواخت.",
    "tip_2": "هضم آسان‌تر از برخی حبوبات.",
    "tip_3": "با سبزی آش.",
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
    "legacy_slug": "cooked-lentils-split",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80",
    "aliases_en": [
      "Cooked lentils split",
      "Split peas"
    ],
    "related_slugs": [
      "عدس-پخته",
      "لوبیا-قرمز-پخته",
      "نان-سنگک-کامل"
    ],
    "intro": "لپه منبع folate در رژیم گیاهی است.",
    "substitutes": [
      {
        "slug": "عدس-پخته",
        "ratio": 1.0
      },
      {
        "slug": "لوبیا-قرمز-پخته",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "لوبیا-چیتی-پخته",
    "title": "لوبیا چیتی پخته",
    "excerpt": "مرجع علمی لوبیا چیتی پخته: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "حبوبات",
    "rank_math_title": "لوبیا چیتی پخته | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای لوبیا چیتی پخته در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "لوبیا چیتی پخته",
    "name_app": "لوبیا چیتی پخته",
    "other_names": "لوبیا چیتی, Pinto beans",
    "food_group": "حبوبات",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "tablespoon",
    "protein": "9",
    "calories": "140",
    "carbohydrates": "25",
    "fat": "0.6",
    "saturated_fat": "0.2",
    "fiber": "6",
    "sugar": "3.0",
    "cholesterol": "0",
    "sodium": "2",
    "potassium": "355",
    "glycemic_index": "30",
    "allergens": "",
    "short_description": "لوبیا چیتی مشابه لوبیا قرمز؛ پروتئین گیاهی و فیبر.",
    "serving_notes": "ارزش‌ها برای لوبیا چیتی پخته در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "در خوراک لوبیا با قارچ.",
    "tip_2": "خیساندن شبانه.",
    "tip_3": "با برنج نسبت متعادل.",
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
    "legacy_slug": "cooked-pinto-beans",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800&q=80",
    "aliases_en": [
      "Cooked pinto beans",
      "Pintos"
    ],
    "related_slugs": [
      "عدس-پخته",
      "لوبیا-قرمز-پخته",
      "نان-سنگک-کامل"
    ],
    "intro": "حبوبات چندرنگ تنوع ریزمغذی می‌دهند.",
    "substitutes": [
      {
        "slug": "عدس-پخته",
        "ratio": 1.0
      },
      {
        "slug": "لوبیا-قرمز-پخته",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "عدسی",
    "title": "عدسی",
    "excerpt": "مرجع علمی عدسی: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "غذاهای ایرانی",
    "rank_math_title": "عدسی | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای عدسی در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "عدسی",
    "name_app": "عدسی",
    "other_names": "عدسی, Adasi",
    "food_group": "غذای آماده",
    "food_type": "solid",
    "meal_times": "صبحانه,ناهار",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "5",
    "calories": "105",
    "carbohydrates": "16",
    "fat": "2.5",
    "saturated_fat": "0.9",
    "fiber": "3.5",
    "sugar": "1.9",
    "cholesterol": "0",
    "sodium": "320",
    "potassium": "280",
    "glycemic_index": "35",
    "allergens": "",
    "short_description": "عدسی غذای سنتی پروتئین گیاهی و کربوهیدرات پیچیده؛ وعده گرم و سبک.",
    "serving_notes": "ارزش‌ها برای عدسی در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "روغن را کم کنید.",
    "tip_2": "با نان سنگک و پیاز.",
    "tip_3": "برای صبحانه انرژی پایدار.",
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
    "legacy_slug": "adasi-stew",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80",
    "aliases_en": [
      "Adasi stew",
      "Persian lentil soup"
    ],
    "related_slugs": [
      "آش-رشته",
      "حلیم",
      "خیار"
    ],
    "intro": "عدسی در فرهنگ غذایی ایرانی منبع فیبر است.",
    "substitutes": [
      {
        "slug": "آش-رشته",
        "ratio": 1.0
      },
      {
        "slug": "حلیم",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "حمص",
    "title": "حمص",
    "excerpt": "مرجع علمی حمص: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "حبوبات",
    "rank_math_title": "حمص | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای حمص در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "حمص",
    "name_app": "حمص",
    "other_names": "حمص, Hummus",
    "food_group": "حبوبات",
    "food_type": "solid",
    "meal_times": "میان‌وعده,ناهار",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "8",
    "calories": "166",
    "carbohydrates": "14",
    "fat": "9.6",
    "saturated_fat": "3.4",
    "fiber": "6",
    "sugar": "1.7",
    "cholesterol": "0",
    "sodium": "379",
    "potassium": "228",
    "glycemic_index": "25",
    "allergens": "کنجد",
    "short_description": "حمص نخود و tahini؛ پروتئین و چربی سالم با GI پایین.",
    "serving_notes": "ارزش‌ها برای حمص در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "با سبزی خام dip کنید.",
    "tip_2": "نسخه خانگی روغن کمتر.",
    "tip_3": "۲–۳ قاشق یک میان‌وعده.",
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
    "legacy_slug": "hummus",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1482049016688-a7bd8fa7e6a1?w=800&q=80",
    "aliases_en": [
      "Hummus",
      "Chickpea dip"
    ],
    "related_slugs": [
      "عدس-پخته",
      "لوبیا-قرمز-پخته",
      "نان-سنگک-کامل"
    ],
    "intro": "حمص میان‌وعده گیاهی در رژیم ورزشکاران رایج است.",
    "substitutes": [
      {
        "slug": "عدس-پخته",
        "ratio": 1.0
      },
      {
        "slug": "لوبیا-قرمز-پخته",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "سویا-پخته",
    "title": "سویا پخته",
    "excerpt": "مرجع علمی سویا پخته: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "حبوبات",
    "rank_math_title": "سویا پخته | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای سویا پخته در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "سویا پخته",
    "name_app": "سویا پخته",
    "other_names": "لوبیا سویا, Soybeans",
    "food_group": "حبوبات",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "tablespoon",
    "protein": "18",
    "calories": "172",
    "carbohydrates": "8.4",
    "fat": "9.0",
    "saturated_fat": "3.1",
    "fiber": "6",
    "sugar": "1.0",
    "cholesterol": "0",
    "sodium": "1",
    "potassium": "515",
    "glycemic_index": "18",
    "allergens": "سویا",
    "short_description": "سویا پروتئین کامل گیاهی و isoflavones دارد.",
    "serving_notes": "ارزش‌ها برای سویا پخته در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "با برنج یا در سالاد.",
    "tip_2": "Edamame میان‌وعده پروتئینی.",
    "tip_3": "حساسیت سویا را در نظر بگیرید.",
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
    "legacy_slug": "cooked-soybeans",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800&q=80",
    "aliases_en": [
      "Cooked soybeans",
      "Edamame"
    ],
    "related_slugs": [
      "عدس-پخته",
      "لوبیا-قرمز-پخته",
      "نان-سنگک-کامل"
    ],
    "intro": "سویا بالاترین پروتئین در حبوبات است.",
    "substitutes": [
      {
        "slug": "عدس-پخته",
        "ratio": 1.0
      },
      {
        "slug": "لوبیا-قرمز-پخته",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "نان-جو",
    "title": "نان جو",
    "excerpt": "مرجع علمی نان جو: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "کربوهیدرات‌ها",
    "rank_math_title": "نان جو | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای نان جو در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "نان جو",
    "name_app": "نان جو",
    "other_names": "نان جو, Barley bread",
    "food_group": "کربوهیدرات",
    "food_type": "solid",
    "meal_times": "صبحانه,ناهار",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "piece",
    "protein": "10",
    "calories": "250",
    "carbohydrates": "45",
    "fat": "3.0",
    "saturated_fat": "1.0",
    "fiber": "6",
    "sugar": "5.4",
    "cholesterol": "0",
    "sodium": "450",
    "potassium": "180",
    "glycemic_index": "50",
    "allergens": "گلوتن",
    "short_description": "نان جو فیبر beta-glucan دارد؛ GI پایین‌تر از نان سفید.",
    "serving_notes": "ارزش‌ها برای نان جو در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "با پنیر و گردو.",
    "tip_2": "یک تکه با صبحانه.",
    "tip_3": "تازه یا منجمد.",
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
    "legacy_slug": "barley-bread",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1511690743698-d9d85f2fbf38?w=800&q=80",
    "aliases_en": [
      "Barley bread",
      "Whole grain bread"
    ],
    "related_slugs": [
      "نان-سنگک-کامل",
      "برنج-سفید-پخته",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "نان جو در کنترل قند خون مطالعه شده.",
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
    "slug": "سیب‌زمینی-شیرین-پخته",
    "title": "سیب‌زمینی شیرین پخته",
    "excerpt": "مرجع علمی سیب‌زمینی شیرین پخته: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "کربوهیدرات‌ها",
    "rank_math_title": "سیب‌زمینی شیرین پخته | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای سیب‌زمینی شیرین پخته در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "سیب‌زمینی شیرین پخته",
    "name_app": "سیب‌زمینی شیرین پخته",
    "other_names": "سیب‌زمینی شیرین, Sweet potato",
    "food_group": "کربوهیدرات",
    "food_type": "solid",
    "meal_times": "ناهار,بعد تمرین",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "tablespoon",
    "protein": "1.6",
    "calories": "86",
    "carbohydrates": "20",
    "fat": "0.1",
    "saturated_fat": "0.0",
    "fiber": "3",
    "sugar": "2.4",
    "cholesterol": "0",
    "sodium": "41",
    "potassium": "337",
    "glycemic_index": "63",
    "allergens": "",
    "short_description": "سیب‌زمینی شیرین beta-carotene و کربوهیدرات دارد؛ GI متوسط.",
    "serving_notes": "ارزش‌ها برای سیب‌زمینی شیرین پخته در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "پوست را بپزید فیبر بیشتر.",
    "tip_2": "بدون شکر و کره.",
    "tip_3": "جایگزین سیب‌زمینی سفید.",
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
    "legacy_slug": "baked-sweet-potato",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1473093295045-ddd4c915dc20?w=800&q=80",
    "aliases_en": [
      "Baked sweet potato",
      "Sweet potato"
    ],
    "related_slugs": [
      "نان-سنگک-کامل",
      "برنج-سفید-پخته",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "سیب‌زمینی شیرین منبع ویتامین A است.",
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
    "slug": "پاستا-گندم-کامل-پخته",
    "title": "پاستا گندم کامل پخته",
    "excerpt": "مرجع علمی پاستا گندم کامل پخته: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "کربوهیدرات‌ها",
    "rank_math_title": "پاستا گندم کامل پخته | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای پاستا گندم کامل پخته در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "پاستا گندم کامل پخته",
    "name_app": "پاستا گندم کامل پخته",
    "other_names": "پاستا کامل, Whole wheat pasta",
    "food_group": "کربوهیدرات",
    "food_type": "solid",
    "meal_times": "ناهار,بعد تمرین",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "tablespoon",
    "protein": "5.5",
    "calories": "124",
    "carbohydrates": "26",
    "fat": "0.5",
    "saturated_fat": "0.2",
    "fiber": "3.5",
    "sugar": "3.1",
    "cholesterol": "0",
    "sodium": "3",
    "potassium": "75",
    "glycemic_index": "42",
    "allergens": "گلوتن",
    "short_description": "پاستا کامل فیبر بیشتر و GI پایین‌تر از سفید.",
    "serving_notes": "ارزش‌ها برای پاستا گندم کامل پخته در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "با سس گوجه و مرغ.",
    "tip_2": "al dente بهتر.",
    "tip_3": "بعد تمرین glycogen.",
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
    "legacy_slug": "whole-wheat-pasta",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1455619452474-d2be8b1e70cb?w=800&q=80",
    "aliases_en": [
      "Whole wheat pasta",
      "Whole grain pasta"
    ],
    "related_slugs": [
      "نان-سنگک-کامل",
      "برنج-سفید-پخته",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "غلات کامل در رژیم ورزشی توصیه می‌شود.",
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
GYMAI_FOOD_BATCH4
        , true);
        return is_array($cache) ? $cache : array();
    }
}
