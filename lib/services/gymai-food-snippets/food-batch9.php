// GymAI Foods — BATCH 9 (خوراکی 81–90)
// Code Snippets: Run everywhere | بدون تگ php
// یا کپی در: wp-content/gymai-seed/food-batch9.php

if (!function_exists('gymai_food_batch9_definitions')) {
    function gymai_food_batch9_definitions() {
        static $cache = null;
        if ($cache !== null) {
            return $cache;
        }
        $cache = json_decode(<<<'GYMAI_FOOD_BATCH9'
[
  {
    "slug": "آش-جو",
    "title": "آش جو",
    "excerpt": "مرجع علمی آش جو: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "غذاهای ایرانی",
    "rank_math_title": "آش جو | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای آش جو در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "آش جو",
    "name_app": "آش جو",
    "other_names": "آش جو, Barley soup",
    "food_group": "غذای آماده",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "4",
    "calories": "88",
    "carbohydrates": "13",
    "fat": "2.5",
    "saturated_fat": "0.9",
    "fiber": "2.2",
    "sugar": "1.6",
    "cholesterol": "0",
    "sodium": "420",
    "potassium": "200",
    "glycemic_index": "38",
    "allergens": "گلوتن",
    "short_description": "آش جو جو و حبوبات؛ فیبر beta-glucan.",
    "serving_notes": "ارزش‌ها برای آش جو در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "سبک و گرم.",
    "tip_2": "بدون روغن زیاد.",
    "tip_3": "زمستان.",
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
    "legacy_slug": "ash-jo",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1498837167922-ddd27525b352?w=800&q=80",
    "aliases_en": [
      "Ash jo",
      "Barley soup"
    ],
    "related_slugs": [
      "عدسی",
      "آش-رشته",
      "خیار"
    ],
    "intro": "آش جو سنت سنتی.",
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
    "slug": "شله‌زرد",
    "title": "شله‌زرد",
    "excerpt": "مرجع علمی شله‌زرد: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "غذاهای ایرانی",
    "rank_math_title": "شله‌زرد | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای شله‌زرد در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "شله‌زرد",
    "name_app": "شله‌زرد",
    "other_names": "شله‌زرد, Sholeh zard",
    "food_group": "غذای آماده",
    "food_type": "solid",
    "meal_times": "میان‌وعده,دسر",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "3",
    "calories": "120",
    "carbohydrates": "24",
    "fat": "2.0",
    "saturated_fat": "0.7",
    "fiber": "0.5",
    "sugar": "2.9",
    "cholesterol": "0",
    "sodium": "15",
    "potassium": "80",
    "glycemic_index": "65",
    "allergens": "",
    "short_description": "شله‌زرد برنج و زعفران؛ کربوهیدرات دسر.",
    "serving_notes": "ارزش‌ها برای شله‌زرد در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "قند کم.",
    "tip_2": "بعد تمرین سبک.",
    "tip_3": "وعده کوچک.",
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
    "legacy_slug": "sholeh-zard",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80",
    "aliases_en": [
      "Sholeh zard",
      "Saffron rice pudding"
    ],
    "related_slugs": [
      "عدسی",
      "آش-رشته",
      "خیار"
    ],
    "intro": "دسر سنتی انرژی.",
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
    "slug": "ماست-و-خیار",
    "title": "ماست و خیار",
    "excerpt": "مرجع علمی ماست و خیار: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "غذاهای ایرانی",
    "rank_math_title": "ماست و خیار | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای ماست و خیار در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "ماست و خیار",
    "name_app": "ماست و خیار",
    "other_names": "ماست و خیار, Mast o khiar",
    "food_group": "غذای آماده",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "4",
    "calories": "55",
    "carbohydrates": "5",
    "fat": "2.0",
    "saturated_fat": "0.7",
    "fiber": "0.5",
    "sugar": "0.6",
    "cholesterol": "0",
    "sodium": "180",
    "potassium": "160",
    "glycemic_index": "20",
    "allergens": "لبنیات",
    "short_description": "ماست و خیار probiotic و hydration؛ کنار غذا.",
    "serving_notes": "ارزش‌ها برای ماست و خیار در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "نعنا و کشمش اختیاری.",
    "tip_2": "کم‌نمک.",
    "tip_3": "با کباب.",
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
    "legacy_slug": "mast-o-khiar",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80",
    "aliases_en": [
      "Mast o khiar",
      "Yogurt cucumber"
    ],
    "related_slugs": [
      "عدسی",
      "آش-رشته",
      "خیار"
    ],
    "intro": "side dish ایرانی.",
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
    "slug": "کشک-بادمجان",
    "title": "کشک بادمجان",
    "excerpt": "مرجع علمی کشک بادمجان: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "غذاهای ایرانی",
    "rank_math_title": "کشک بادمجان | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای کشک بادمجان در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "کشک بادمجان",
    "name_app": "کشک بادمجان",
    "other_names": "کشک بادمجان, Kashk bademjan",
    "food_group": "غذای آماده",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "4",
    "calories": "95",
    "carbohydrates": "8",
    "fat": "5.5",
    "saturated_fat": "1.9",
    "fiber": "3",
    "sugar": "1.0",
    "cholesterol": "0",
    "sodium": "380",
    "potassium": "210",
    "glycemic_index": "30",
    "allergens": "لبنیات",
    "short_description": "کشک بادمجان بادمجان و کشک؛ سبزیجات و پروتئین لبنی.",
    "serving_notes": "ارزش‌ها برای کشک بادمجان در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
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
    "legacy_slug": "kashk-bademjan",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800&q=80",
    "aliases_en": [
      "Kashk bademjan",
      "Eggplant dip"
    ],
    "related_slugs": [
      "عدسی",
      "آش-رشته",
      "خیار"
    ],
    "intro": "غذای گیاهی-لبنی.",
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
    "slug": "دلمه-برگ-مو",
    "title": "دلمه برگ مو",
    "excerpt": "مرجع علمی دلمه برگ مو: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "غذاهای ایرانی",
    "rank_math_title": "دلمه برگ مو | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای دلمه برگ مو در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "دلمه برگ مو",
    "name_app": "دلمه برگ مو",
    "other_names": "دلمه, Dolmeh",
    "food_group": "غذای آماده",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "4",
    "calories": "115",
    "carbohydrates": "18",
    "fat": "3.5",
    "saturated_fat": "1.2",
    "fiber": "2",
    "sugar": "2.2",
    "cholesterol": "0",
    "sodium": "350",
    "potassium": "180",
    "glycemic_index": "45",
    "allergens": "",
    "short_description": "دلمه برنج و گوشت/سبزی در برگ مو؛ وعده کنترل‌شده.",
    "serving_notes": "ارزش‌ها برای دلمه برگ مو در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "۲–۳ عدد.",
    "tip_2": "با ماست.",
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
    "legacy_slug": "dolmeh",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80",
    "aliases_en": [
      "Dolmeh",
      "Stuffed grape leaves"
    ],
    "related_slugs": [
      "عدسی",
      "آش-رشته",
      "خیار"
    ],
    "intro": "دلمه غذای سنتی.",
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
    "slug": "ته‌چین-مرغ",
    "title": "ته‌چین مرغ",
    "excerpt": "مرجع علمی ته‌چین مرغ: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "غذاهای ایرانی",
    "rank_math_title": "ته‌چین مرغ | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای ته‌چین مرغ در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "ته‌چین مرغ",
    "name_app": "ته‌چین مرغ",
    "other_names": "ته‌چین, Tahchin",
    "food_group": "غذای آماده",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "12",
    "calories": "175",
    "carbohydrates": "22",
    "fat": "5.0",
    "saturated_fat": "1.8",
    "fiber": "0.5",
    "sugar": "2.6",
    "cholesterol": "0",
    "sodium": "420",
    "potassium": "180",
    "glycemic_index": "58",
    "allergens": "تخم‌مرغ",
    "short_description": "ته‌چین برنج و مرغ با زعفران؛ کربو و پروتئین.",
    "serving_notes": "ارزش‌ها برای ته‌چین مرغ در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "یک برش.",
    "tip_2": "با سالاد.",
    "tip_3": "روغن moderation.",
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
    "legacy_slug": "tahchin-chicken",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1482049016688-a7bd8fa7e6a1?w=800&q=80",
    "aliases_en": [
      "Tahchin chicken",
      "Persian rice cake"
    ],
    "related_slugs": [
      "عدسی",
      "آش-رشته",
      "خیار"
    ],
    "intro": "ته‌چین غذای مجلسی.",
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
    "slug": "خورشت-فسنجان",
    "title": "خورشت فسنجان",
    "excerpt": "مرجع علمی خورشت فسنجان: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "غذاهای ایرانی",
    "rank_math_title": "خورشت فسنجان | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای خورشت فسنجان در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "خورشت فسنجان",
    "name_app": "خورشت فسنجان",
    "other_names": "فسنجان, Fesenjan",
    "food_group": "غذای آماده",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "14",
    "calories": "185",
    "carbohydrates": "10",
    "fat": "11.0",
    "saturated_fat": "3.8",
    "fiber": "2.5",
    "sugar": "1.2",
    "cholesterol": "0",
    "sodium": "380",
    "potassium": "320",
    "glycemic_index": "25",
    "allergens": "گردو",
    "short_description": "خورشت فسنجان مرغ، گردو و رب انار — بدون برنج؛ برنج را جدا بچینید.",
    "serving_notes": "ارزش‌ها برای خورشت فسنجان در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "کالری از گردو را در نظر بگیرید.",
    "tip_2": "برنج را جدا اضافه کنید.",
    "tip_3": "وعده شمالی کلاسیک.",
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
    "legacy_slug": "fesenjan",
    "migrate_slugs": [
      "فسنجان-با-مرغ"
    ],
    "image_url": "https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800&q=80",
    "aliases_en": [
      "Fesenjan stew",
      "Walnut pomegranate stew"
    ],
    "related_slugs": [
      "عدسی",
      "آش-رشته",
      "خیار"
    ],
    "intro": "فسنجان منبع چربی غیراشباع و پروتئین در خورشت ایرانی است.",
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
    "slug": "خورشت-سبزی",
    "title": "خورشت سبزی",
    "excerpt": "مرجع علمی خورشت سبزی: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "غذاهای ایرانی",
    "rank_math_title": "خورشت سبزی | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای خورشت سبزی در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "خورشت سبزی",
    "name_app": "خورشت سبزی",
    "other_names": "قورمه سبزی, Ghormeh sabzi",
    "food_group": "غذای آماده",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "8",
    "calories": "118",
    "carbohydrates": "6",
    "fat": "6.0",
    "saturated_fat": "2.1",
    "fiber": "2.5",
    "sugar": "0.7",
    "cholesterol": "0",
    "sodium": "510",
    "potassium": "340",
    "glycemic_index": "30",
    "allergens": "",
    "short_description": "خورشت سبزی (قورمه سبزی) — فقط خورشت، بدون برنج؛ برنج را جدا در برنامه بچینید.",
    "serving_notes": "ارزش‌ها برای خورشت سبزی در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "برنج را جدا اضافه کنید.",
    "tip_2": "لیمو ترش کنار غذا.",
    "tip_3": "یک پیمانه خورشت حدود ۲۰۰ گرم.",
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
    "legacy_slug": "ghormeh-sabzi",
    "migrate_slugs": [
      "خورشت-سبزی-با-برنج"
    ],
    "image_url": "https://images.unsplash.com/photo-1511690743698-d9d85f2fbf38?w=800&q=80",
    "aliases_en": [
      "Ghormeh sabzi",
      "Herb stew"
    ],
    "related_slugs": [
      "عدسی",
      "آش-رشته",
      "خیار"
    ],
    "intro": "قورمه سبزی منبع فیبر، آهن و سبزیجات در آشپزی ایرانی است.",
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
    "slug": "کوکو-سیب‌زمینی",
    "title": "کوکو سیب‌زمینی",
    "excerpt": "مرجع علمی کوکو سیب‌زمینی: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "غذاهای ایرانی",
    "rank_math_title": "کوکو سیب‌زمینی | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای کوکو سیب‌زمینی در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "کوکو سیب‌زمینی",
    "name_app": "کوکو سیب‌زمینی",
    "other_names": "کوکو سیب‌زمینی, Potato kuku",
    "food_group": "غذای آماده",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "6",
    "calories": "155",
    "carbohydrates": "18",
    "fat": "7.0",
    "saturated_fat": "2.4",
    "fiber": "2",
    "sugar": "2.2",
    "cholesterol": "0",
    "sodium": "320",
    "potassium": "250",
    "glycemic_index": "50",
    "allergens": "تخم‌مرغ",
    "short_description": "کوکو سیب‌زمینی تخم‌مرغ و سیب‌زمینی؛ کربو و پروتئین.",
    "serving_notes": "ارزش‌ها برای کوکو سیب‌زمینی در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "فر بهتر.",
    "tip_2": "با ماست.",
    "tip_3": "یک برش.",
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
    "legacy_slug": "potato-kuku",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1473093295045-ddd4c915dc20?w=800&q=80",
    "aliases_en": [
      "Potato kuku",
      "Potato frittata"
    ],
    "related_slugs": [
      "عدسی",
      "آش-رشته",
      "خیار"
    ],
    "intro": "غذای ساده ایرانی.",
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
    "slug": "باقلاپلو-با-ماهیچه",
    "title": "باقلاپلو با ماهیچه",
    "excerpt": "مرجع علمی باقلاپلو با ماهیچه: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "غذاهای ایرانی",
    "rank_math_title": "باقلاپلو با ماهیچه | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای باقلاپلو با ماهیچه در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "باقلاپلو با ماهیچه",
    "name_app": "باقلاپلو با ماهیچه",
    "other_names": "باقلاپلو, Baghali polo",
    "food_group": "غذای آماده",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "13",
    "calories": "190",
    "carbohydrates": "24",
    "fat": "6.0",
    "saturated_fat": "2.1",
    "fiber": "3",
    "sugar": "2.9",
    "cholesterol": "0",
    "sodium": "450",
    "potassium": "310",
    "glycemic_index": "52",
    "allergens": "",
    "short_description": "باقلاپلو برنج، باقلا و گوشت؛ پروتئین و کربوهیدرات کامل.",
    "serving_notes": "ارزش‌ها برای باقلاپلو با ماهیچه در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "ماهیچه چربی دارد.",
    "tip_2": "سالاد کنار.",
    "tip_3": "غذای بهاری.",
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
    "legacy_slug": "baghali-polo",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1455619452474-d2be8b1e70cb?w=800&q=80",
    "aliases_en": [
      "Baghali polo",
      "Fava bean rice"
    ],
    "related_slugs": [
      "عدسی",
      "آش-رشته",
      "خیار"
    ],
    "intro": "باقلا فیبر و فولات دارد.",
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
GYMAI_FOOD_BATCH9
        , true);
        return is_array($cache) ? $cache : array();
    }
}
