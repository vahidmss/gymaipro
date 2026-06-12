// GymAI Foods — BATCH 8 (خوراکی 71–80)
// Code Snippets: Run everywhere | بدون تگ php
// یا کپی در: wp-content/gymai-seed/food-batch8.php

if (!function_exists('gymai_food_batch8_definitions')) {
    function gymai_food_batch8_definitions() {
        static $cache = null;
        if ($cache !== null) {
            return $cache;
        }
        $cache = json_decode(<<<'GYMAI_FOOD_BATCH8'
[
  {
    "slug": "آش-رشته",
    "title": "آش رشته",
    "excerpt": "مرجع علمی آش رشته: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "غذاهای ایرانی",
    "rank_math_title": "آش رشته | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای آش رشته در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "آش رشته",
    "name_app": "آش رشته",
    "other_names": "آش رشته, Ash reshteh",
    "food_group": "غذای آماده",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "4.5",
    "calories": "95",
    "carbohydrates": "14",
    "fat": "2.8",
    "saturated_fat": "1.0",
    "fiber": "2.5",
    "sugar": "1.7",
    "cholesterol": "0",
    "sodium": "450",
    "potassium": "220",
    "glycemic_index": "40",
    "allergens": "گلوتن",
    "short_description": "آش رشته حبوبات، رشته و سبزی؛ پروتئین گیاهی و کربو.",
    "serving_notes": "ارزش‌ها برای آش رشته در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "کشک و پیازداغ را جدا حساب.",
    "tip_2": "وعده یک کاسه متوسط.",
    "tip_3": "روغن کم.",
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
    "legacy_slug": "ash-reshteh",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1498837167922-ddd27525b352?w=800&q=80",
    "aliases_en": [
      "Ash reshteh",
      "Persian noodle soup"
    ],
    "related_slugs": [
      "عدسی",
      "حلیم",
      "خیار"
    ],
    "intro": "آش غذای سنتی فیبر و انرژی.",
    "substitutes": [
      {
        "slug": "عدسی",
        "ratio": 1.0
      },
      {
        "slug": "حلیم",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "حلیم",
    "title": "حلیم",
    "excerpt": "مرجع علمی حلیم: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "غذاهای ایرانی",
    "rank_math_title": "حلیم | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای حلیم در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "حلیم",
    "name_app": "حلیم",
    "other_names": "حلیم, Haleem",
    "food_group": "غذای آماده",
    "food_type": "solid",
    "meal_times": "صبحانه,ناهار",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "6",
    "calories": "130",
    "carbohydrates": "18",
    "fat": "4.0",
    "saturated_fat": "1.4",
    "fiber": "1.5",
    "sugar": "2.2",
    "cholesterol": "0",
    "sodium": "280",
    "potassium": "180",
    "glycemic_index": "45",
    "allergens": "گلوتن",
    "short_description": "حلیم گندم و گوشت؛ پروتئین و کربوهیدرات برای صبحانه سنگین.",
    "serving_notes": "ارزش‌ها برای حلیم در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "بدون روغن زیاد.",
    "tip_2": "با دارچین و شکر کم.",
    "tip_3": "وعده ورزشکار.",
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
    "legacy_slug": "haleem",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80",
    "aliases_en": [
      "Haleem",
      "Wheat and meat porridge"
    ],
    "related_slugs": [
      "عدسی",
      "آش-رشته",
      "خیار"
    ],
    "intro": "حلیم انرژی فشرده صبح.",
    "substitutes": [
      {
        "slug": "عدسی",
        "ratio": 1.0
      },
      {
        "slug": "آش-رشته",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "سالاد-شیرازی",
    "title": "سالاد شیرازی",
    "excerpt": "مرجع علمی سالاد شیرازی: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "غذاهای ایرانی",
    "rank_math_title": "سالاد شیرازی | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای سالاد شیرازی در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "سالاد شیرازی",
    "name_app": "سالاد شیرازی",
    "other_names": "سالاد شیرازی, Shirazi salad",
    "food_group": "سبزیجات",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "1.2",
    "calories": "35",
    "carbohydrates": "6",
    "fat": "0.5",
    "saturated_fat": "0.2",
    "fiber": "2",
    "sugar": "0.7",
    "cholesterol": "0",
    "sodium": "180",
    "potassium": "250",
    "glycemic_index": "15",
    "allergens": "",
    "short_description": "سالاد شیرazi خیار، گوجه، پیاز؛ کم‌کالری و hydration.",
    "serving_notes": "ارزش‌ها برای سالاد شیرازی در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "آبلیمو به جای سرکه زیاد.",
    "tip_2": "با کباب.",
    "tip_3": "تازه.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "cup",
      "units": [
        {
          "key": "cup",
          "label": "پیمانه",
          "grams": 100,
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
    "legacy_slug": "shirazi-salad",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80",
    "aliases_en": [
      "Shirazi salad",
      "Persian cucumber salad"
    ],
    "related_slugs": [
      "خیار",
      "گوجه‌فرنگی",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "سالاد سنتی کنار غذا.",
    "substitutes": [
      {
        "slug": "خیار",
        "ratio": 1.0
      },
      {
        "slug": "گوجه‌فرنگی",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "خورشت-قیمه",
    "title": "خورشت قیمه",
    "excerpt": "مرجع علمی خورشت قیمه: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "غذاهای ایرانی",
    "rank_math_title": "خورشت قیمه | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای خورشت قیمه در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "خورشت قیمه",
    "name_app": "خورشت قیمه",
    "other_names": "قیمه, Gheymeh",
    "food_group": "غذای آماده",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "9",
    "calories": "125",
    "carbohydrates": "8",
    "fat": "6.5",
    "saturated_fat": "2.3",
    "fiber": "2.5",
    "sugar": "1.0",
    "cholesterol": "0",
    "sodium": "520",
    "potassium": "310",
    "glycemic_index": "35",
    "allergens": "",
    "short_description": "خورشت قیمه لپه و گوشت — فقط خورشت، بدون برنج؛ برنج را جدا در برنامه بچینید.",
    "serving_notes": "ارزش‌ها برای خورشت قیمه در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "برنج سفید یا قهوه‌ای را جدا اضافه کنید.",
    "tip_2": "یک پیمانه خورشت حدود ۲۰۰ گرم.",
    "tip_3": "با سالاد شیرازی کنار غذا.",
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
    "legacy_slug": "gheymeh-stew-with-rice",
    "migrate_slugs": [
      "خورشت-قیمه-با-برنج"
    ],
    "image_url": "https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800&q=80",
    "aliases_en": [
      "Gheymeh stew",
      "Persian split pea stew"
    ],
    "related_slugs": [
      "عدسی",
      "آش-رشته",
      "خیار"
    ],
    "intro": "خورشت قیمه منبع آهن و پروتئین در آشپزی ایرانی است.",
    "substitutes": [
      {
        "slug": "عدسی",
        "ratio": 1.0
      },
      {
        "slug": "آش-رشته",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "کباب-کوبیده",
    "title": "کباب کوبیده",
    "excerpt": "مرجع علمی کباب کوبیده: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "پروتئین‌ها",
    "rank_math_title": "کباب کوبیده | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای کباب کوبیده در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "کباب کوبیده",
    "name_app": "کباب کوبیده",
    "other_names": "کباب کوبیده, Koobideh",
    "food_group": "پروتئین",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "palm_protein",
    "protein": "26",
    "calories": "268",
    "carbohydrates": "0",
    "fat": "17.0",
    "saturated_fat": "5.9",
    "fiber": "0",
    "sugar": "0",
    "cholesterol": "15",
    "sodium": "420",
    "potassium": "340",
    "glycemic_index": "0",
    "allergens": "",
    "short_description": "کباب کوبیده گوشت کبابی — فقط کباب، بدون برنج؛ چلو را با برنج جدا بسازید.",
    "serving_notes": "ارزش‌ها برای کباب کوبیده در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "برنج و سالاد را جدا در برنامه اضافه کنید.",
    "tip_2": "گوشت کم‌چرب و بدون روغن اضافه.",
    "tip_3": "یک وعده حدود ۱۲۰–۱۵۰ گرم گوشت کبابی.",
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
    "legacy_slug": "chelo-koobideh",
    "migrate_slugs": [
      "چلوکباب-کوبیده"
    ],
    "image_url": "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80",
    "aliases_en": [
      "Koobideh kebab",
      "Ground meat kebab"
    ],
    "related_slugs": [
      "سینه-مرغ-گریل-شده",
      "تخم‌مرغ-آب‌پز",
      "نان-سنگک-کامل"
    ],
    "intro": "کباب کوبیده پایه پروتئین در غذای ایرانی و برنامه‌های بدنسازی است.",
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
    "slug": "عدس-پلو",
    "title": "عدس پلو",
    "excerpt": "مرجع علمی عدس پلو: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "غذاهای ایرانی",
    "rank_math_title": "عدس پلو | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای عدس پلو در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "عدس پلو",
    "name_app": "عدس پلو",
    "other_names": "عدس پلو, Adas polo",
    "food_group": "غذای آماده",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "7",
    "calories": "155",
    "carbohydrates": "24",
    "fat": "4.0",
    "saturated_fat": "1.4",
    "fiber": "3",
    "sugar": "2.9",
    "cholesterol": "0",
    "sodium": "380",
    "potassium": "290",
    "glycemic_index": "48",
    "allergens": "",
    "short_description": "عدس پلو عدس و برنج با گوشت؛ فیبر و پروتئین.",
    "serving_notes": "ارزش‌ها برای عدس پلو در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "مقدار برنج.",
    "tip_2": "با سالاد.",
    "tip_3": "گوشت اضافه پروتئین.",
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
    "legacy_slug": "adas-polo",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1482049016688-a7bd8fa7e6a1?w=800&q=80",
    "aliases_en": [
      "Adas polo",
      "Lentil rice"
    ],
    "related_slugs": [
      "عدسی",
      "آش-رشته",
      "خیار"
    ],
    "intro": "غذای یک‌پخت ایرانی.",
    "substitutes": [
      {
        "slug": "عدسی",
        "ratio": 1.0
      },
      {
        "slug": "آش-رشته",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "میرزا-قاسمی",
    "title": "میرزا قاسمی",
    "excerpt": "مرجع علمی میرزا قاسمی: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "غذاهای ایرانی",
    "rank_math_title": "میرزا قاسمی | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای میرزا قاسمی در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "میرزا قاسمی",
    "name_app": "میرزا قاسمی",
    "other_names": "میرزا قاسمی, Mirza ghasemi",
    "food_group": "غذای آماده",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "2.5",
    "calories": "75",
    "carbohydrates": "8",
    "fat": "4.0",
    "saturated_fat": "1.4",
    "fiber": "3",
    "sugar": "1.0",
    "cholesterol": "0",
    "sodium": "320",
    "potassium": "280",
    "glycemic_index": "35",
    "allergens": "تخم‌مرغ",
    "short_description": "میرزا قاسمی بادمجان، تخم‌مرغ و گوجه؛ سبزیجات و پروتئین.",
    "serving_notes": "ارزش‌ها برای میرزا قاسمی در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "روغن کم.",
    "tip_2": "با نان.",
    "tip_3": "وعده شمالی.",
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
    "legacy_slug": "mirza-ghasemi",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800&q=80",
    "aliases_en": [
      "Mirza ghasemi",
      "Eggplant dish"
    ],
    "related_slugs": [
      "عدسی",
      "آش-رشته",
      "خیار"
    ],
    "intro": "غذای گیاهی-پروتئینی ایرانی.",
    "substitutes": [
      {
        "slug": "عدسی",
        "ratio": 1.0
      },
      {
        "slug": "آش-رشته",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "کتلت-مرغ",
    "title": "کتلت مرغ",
    "excerpt": "مرجع علمی کتلت مرغ: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "غذاهای ایرانی",
    "rank_math_title": "کتلت مرغ | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای کتلت مرغ در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "کتلت مرغ",
    "name_app": "کتلت مرغ",
    "other_names": "کتلت, Cutlet",
    "food_group": "غذای آماده",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "18",
    "calories": "195",
    "carbohydrates": "12",
    "fat": "8.0",
    "saturated_fat": "2.8",
    "fiber": "1",
    "sugar": "1.4",
    "cholesterol": "0",
    "sodium": "420",
    "potassium": "260",
    "glycemic_index": "45",
    "allergens": "تخم‌مرغ, گلوتن",
    "short_description": "کتلت مرغ و سیب‌زمینی سرخ‌کرده؛ پروتئین و کربو.",
    "serving_notes": "ارزش‌ها برای کتلت مرغ در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "سرخ‌کردن کم یا فر.",
    "tip_2": "با سالاد.",
    "tip_3": "یک عدد متوسط.",
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
    "legacy_slug": "chicken-cutlet",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1511690743698-d9d85f2fbf38?w=800&q=80",
    "aliases_en": [
      "Chicken cutlet",
      "Persian cutlet"
    ],
    "related_slugs": [
      "عدسی",
      "آش-رشته",
      "خیار"
    ],
    "intro": "کتلت میان‌وعده یا ناهار.",
    "substitutes": [
      {
        "slug": "عدسی",
        "ratio": 1.0
      },
      {
        "slug": "آش-رشته",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "خوراک-لوبیا",
    "title": "خوراک لوبیا",
    "excerpt": "مرجع علمی خوراک لوبیا: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "غذاهای ایرانی",
    "rank_math_title": "خوراک لوبیا | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای خوراک لوبیا در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "خوراک لوبیا",
    "name_app": "خوراک لوبیا",
    "other_names": "خوراک لوبیا, Bean stew",
    "food_group": "غذای آماده",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "6",
    "calories": "110",
    "carbohydrates": "16",
    "fat": "3.0",
    "saturated_fat": "1.0",
    "fiber": "4",
    "sugar": "1.9",
    "cholesterol": "0",
    "sodium": "400",
    "potassium": "320",
    "glycemic_index": "35",
    "allergens": "",
    "short_description": "خوراک لوبیا لوبیا و گوشت؛ فیبر و آهن.",
    "serving_notes": "ارزش‌ها برای خوراک لوبیا در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "با برنج یا نان.",
    "tip_2": "روغن متعادل.",
    "tip_3": "غذای خانگی.",
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
    "legacy_slug": "khoresht-loobia",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1473093295045-ddd4c915dc20?w=800&q=80",
    "aliases_en": [
      "Khoresht loobia",
      "Bean stew"
    ],
    "related_slugs": [
      "عدسی",
      "آش-رشته",
      "خیار"
    ],
    "intro": "حبوبات در خوراک ایرانی.",
    "substitutes": [
      {
        "slug": "عدسی",
        "ratio": 1.0
      },
      {
        "slug": "آش-رشته",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "کوکو-سبزی",
    "title": "کوکو سبزی",
    "excerpt": "مرجع علمی کوکو سبزی: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "غذاهای ایرانی",
    "rank_math_title": "کوکو سبزی | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای کوکو سبزی در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "کوکو سبزی",
    "name_app": "کوکو سبزی",
    "other_names": "کوکو سبزی, Kuku sabzi",
    "food_group": "غذای آماده",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "8",
    "calories": "145",
    "carbohydrates": "6",
    "fat": "10.0",
    "saturated_fat": "3.5",
    "fiber": "2.5",
    "sugar": "0.7",
    "cholesterol": "0",
    "sodium": "280",
    "potassium": "220",
    "glycemic_index": "30",
    "allergens": "تخم‌مرغ",
    "short_description": "کوکو سبزی تخم‌مرغ و سبزی؛ پروتئین و micronutrients.",
    "serving_notes": "ارزش‌ها برای کوکو سبزی در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "فر بهتر از سرخ.",
    "tip_2": "با نان و ماست.",
    "tip_3": "وعده گیاهی-پروتئین.",
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
    "legacy_slug": "kuku-sabzi",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1455619452474-d2be8b1e70cb?w=800&q=80",
    "aliases_en": [
      "Kuku sabzi",
      "Herb frittata"
    ],
    "related_slugs": [
      "عدسی",
      "آش-رشته",
      "خیار"
    ],
    "intro": "کوکو غذای سبک ایرانی.",
    "substitutes": [
      {
        "slug": "عدسی",
        "ratio": 1.0
      },
      {
        "slug": "آش-رشته",
        "ratio": 1.0
      }
    ]
  }
]
GYMAI_FOOD_BATCH8
        , true);
        return is_array($cache) ? $cache : array();
    }
}
