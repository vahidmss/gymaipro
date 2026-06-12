// GymAI Foods — BATCH 6 (خوراکی 51–60)
// Code Snippets: Run everywhere | بدون تگ php
// یا کپی در: wp-content/gymai-seed/food-batch6.php

if (!function_exists('gymai_food_batch6_definitions')) {
    function gymai_food_batch6_definitions() {
        static $cache = null;
        if ($cache !== null) {
            return $cache;
        }
        $cache = json_decode(<<<'GYMAI_FOOD_BATCH6'
[
  {
    "slug": "خیار",
    "title": "خیار",
    "excerpt": "مرجع علمی خیار: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "سبزیجات",
    "rank_math_title": "خیار | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای خیار در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "خیار",
    "name_app": "خیار",
    "other_names": "خیار, Cucumber",
    "food_group": "سبزیجات",
    "food_type": "solid",
    "meal_times": "ناهار,شام,میان‌وعده",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "0.7",
    "calories": "15",
    "carbohydrates": "3.6",
    "fat": "0.1",
    "saturated_fat": "0.0",
    "fiber": "0.5",
    "sugar": "0.4",
    "cholesterol": "0",
    "sodium": "2",
    "potassium": "147",
    "glycemic_index": "15",
    "allergens": "",
    "short_description": "خیار کم‌کالری و آب بالا؛ حجم غذایی بدون کالری.",
    "serving_notes": "ارزش‌ها برای خیار در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "با ماست و نعنا.",
    "tip_2": "پوست را بخورید.",
    "tip_3": "در سالاد شیرازی.",
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
    "legacy_slug": "cucumber",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1498837167922-ddd27525b352?w=800&q=80",
    "aliases_en": [
      "Cucumber",
      "Fresh cucumber"
    ],
    "related_slugs": [
      "گوجه‌فرنگی",
      "اسفناج-خام",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "سبزیجات آب‌دار برای سیری.",
    "substitutes": [
      {
        "slug": "گوجه‌فرنگی",
        "ratio": 1.0
      },
      {
        "slug": "اسفناج-خام",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "گوجه‌فرنگی",
    "title": "گوجه‌فرنگی",
    "excerpt": "مرجع علمی گوجه‌فرنگی: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "سبزیجات",
    "rank_math_title": "گوجه‌فرنگی | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای گوجه‌فرنگی در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "گوجه‌فرنگی",
    "name_app": "گوجه‌فرنگی",
    "other_names": "گوجه, Tomato",
    "food_group": "سبزیجات",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "0.9",
    "calories": "18",
    "carbohydrates": "3.9",
    "fat": "0.2",
    "saturated_fat": "0.1",
    "fiber": "1.2",
    "sugar": "0.5",
    "cholesterol": "0",
    "sodium": "5",
    "potassium": "237",
    "glycemic_index": "15",
    "allergens": "",
    "short_description": "گوجه lycopene و ویتامین C دارد؛ خام یا پخته.",
    "serving_notes": "ارزش‌ها برای گوجه‌فرنگی در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "پخته lycopene بیشتر.",
    "tip_2": "در سالاد.",
    "tip_3": "یک عدد متوسط.",
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
    "legacy_slug": "tomato",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80",
    "aliases_en": [
      "Tomato",
      "Fresh tomato"
    ],
    "related_slugs": [
      "خیار",
      "اسفناج-خام",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "lycopene آنتی‌اکسیدant چربی‌محل است.",
    "substitutes": [
      {
        "slug": "خیار",
        "ratio": 1.0
      },
      {
        "slug": "اسفناج-خام",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "اسفناج-خام",
    "title": "اسفناج خام",
    "excerpt": "مرجع علمی اسفناج خام: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "سبزیجات",
    "rank_math_title": "اسفناج خام | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای اسفناج خام در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "اسفناج خام",
    "name_app": "اسفناج خام",
    "other_names": "اسفناج, Spinach",
    "food_group": "سبزیجات",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "2.9",
    "calories": "23",
    "carbohydrates": "3.6",
    "fat": "0.4",
    "saturated_fat": "0.1",
    "fiber": "2.2",
    "sugar": "0.4",
    "cholesterol": "0",
    "sodium": "79",
    "potassium": "558",
    "glycemic_index": "15",
    "allergens": "",
    "short_description": "اسفناج آهن، folate و nitrate دارد؛ برای جریان خون.",
    "serving_notes": "ارزش‌ها برای اسفناج خام در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "با ویتامین C جذب آهن.",
    "tip_2": "در اسموتی یا سالاد.",
    "tip_3": "پخت کوتاه حجم کم.",
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
    "legacy_slug": "spinach-raw",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80",
    "aliases_en": [
      "Spinach raw",
      "Fresh spinach"
    ],
    "related_slugs": [
      "خیار",
      "گوجه‌فرنگی",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "nitrate در اسفناج برای performance مطرح است.",
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
    "slug": "کاهو",
    "title": "کاهو",
    "excerpt": "مرجع علمی کاهو: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "سبزیجات",
    "rank_math_title": "کاهو | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای کاهو در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "کاهو",
    "name_app": "کاهو",
    "other_names": "کاهو, Lettuce",
    "food_group": "سبزیجات",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "1.4",
    "calories": "15",
    "carbohydrates": "2.9",
    "fat": "0.2",
    "saturated_fat": "0.1",
    "fiber": "1.3",
    "sugar": "0.3",
    "cholesterol": "0",
    "sodium": "28",
    "potassium": "194",
    "glycemic_index": "15",
    "allergens": "",
    "short_description": "کاهو حجم بالا و کالری ناچیز؛ پایه سالاد.",
    "serving_notes": "ارزش‌ها برای کاهو در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "کاهو رومaine مواد بیشتر.",
    "tip_2": "با پروتئین و چربی dressing.",
    "tip_3": "۲–۳ پیمانه.",
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
    "legacy_slug": "lettuce",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800&q=80",
    "aliases_en": [
      "Lettuce",
      "Romaine lettuce"
    ],
    "related_slugs": [
      "خیار",
      "گوجه‌فرنگی",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "سبزیجات برگ‌دار برای micronutrients.",
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
    "slug": "بروکلی-پخته",
    "title": "بروکلی پخته",
    "excerpt": "مرجع علمی بروکلی پخته: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "سبزیجات",
    "rank_math_title": "بروکلی پخته | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای بروکلی پخته در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "بروکلی پخته",
    "name_app": "بروکلی پخته",
    "other_names": "بروکلی, Broccoli",
    "food_group": "سبزیجات",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "2.4",
    "calories": "35",
    "carbohydrates": "7",
    "fat": "0.4",
    "saturated_fat": "0.1",
    "fiber": "3.3",
    "sugar": "0.8",
    "cholesterol": "0",
    "sodium": "41",
    "potassium": "293",
    "glycemic_index": "15",
    "allergens": "",
    "short_description": "بروکلی sulforaphane و فیبر؛ cruciferous برای سلامت.",
    "serving_notes": "ارزش‌ها برای بروکلی پخته در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "بخارپز ۳–۵ دقیقه.",
    "tip_2": "با سیر و لیمو.",
    "tip_3": "نیم بشقاب.",
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
    "legacy_slug": "broccoli-cooked",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80",
    "aliases_en": [
      "Broccoli cooked",
      "Steamed broccoli"
    ],
    "related_slugs": [
      "خیار",
      "گوجه‌فرنگی",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "cruciferous در رژیم ضدالتهاب.",
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
    "slug": "هویج-خام",
    "title": "هویج خام",
    "excerpt": "مرجع علمی هویج خام: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "سبزیجات",
    "rank_math_title": "هویج خام | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای هویج خام در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "هویج خام",
    "name_app": "هویج خام",
    "other_names": "هویج, Carrot",
    "food_group": "سبزیجات",
    "food_type": "solid",
    "meal_times": "میان‌وعده,ناهار",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "0.9",
    "calories": "41",
    "carbohydrates": "10",
    "fat": "0.2",
    "saturated_fat": "0.1",
    "fiber": "2.8",
    "sugar": "1.2",
    "cholesterol": "0",
    "sodium": "69",
    "potassium": "320",
    "glycemic_index": "39",
    "allergens": "",
    "short_description": "هویج beta-carotene و فیبر؛ GI متوسط.",
    "serving_notes": "ارزش‌ها برای هویج خام در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "با hummus dip.",
    "tip_2": "پخته نرم‌تر برای هضم.",
    "tip_3": "یک عدد متوسط.",
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
    "legacy_slug": "carrot-raw",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1482049016688-a7bd8fa7e6a1?w=800&q=80",
    "aliases_en": [
      "Carrot raw",
      "Fresh carrot"
    ],
    "related_slugs": [
      "خیار",
      "گوجه‌فرنگی",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "carotenoids برای بینایی و immunity.",
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
    "slug": "فلفل-دلمه‌ای",
    "title": "فلفل دلمه‌ای",
    "excerpt": "مرجع علمی فلفل دلمه‌ای: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "سبزیجات",
    "rank_math_title": "فلفل دلمه‌ای | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای فلفل دلمه‌ای در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "فلفل دلمه‌ای",
    "name_app": "فلفل دلمه‌ای",
    "other_names": "فلفل دلمه‌ای, Bell pepper",
    "food_group": "سبزیجات",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "1",
    "calories": "31",
    "carbohydrates": "6",
    "fat": "0.3",
    "saturated_fat": "0.1",
    "fiber": "2.1",
    "sugar": "0.7",
    "cholesterol": "0",
    "sodium": "4",
    "potassium": "211",
    "glycemic_index": "15",
    "allergens": "",
    "short_description": "فلفل ویتامین C بسیار بالا؛ رنگی آنتی‌اکسیدant.",
    "serving_notes": "ارزش‌ها برای فلفل دلمه‌ای در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "خام در سالاد.",
    "tip_2": "تفت با مرغ.",
    "tip_3": "نیم عدد بزرگ.",
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
    "legacy_slug": "bell-pepper",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800&q=80",
    "aliases_en": [
      "Bell pepper",
      "Sweet pepper"
    ],
    "related_slugs": [
      "خیار",
      "گوجه‌فرنگی",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "ویتامین C در ریکاوری collagen.",
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
    "slug": "کدو-سبز-پخته",
    "title": "کدو سبز پخته",
    "excerpt": "مرجع علمی کدو سبز پخته: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "سبزیجات",
    "rank_math_title": "کدو سبز پخته | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای کدو سبز پخته در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "کدو سبز پخته",
    "name_app": "کدو سبز پخته",
    "other_names": "کدو, Zucchini",
    "food_group": "سبزیجات",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "1.2",
    "calories": "17",
    "carbohydrates": "3.1",
    "fat": "0.3",
    "saturated_fat": "0.1",
    "fiber": "1",
    "sugar": "0.4",
    "cholesterol": "0",
    "sodium": "2",
    "potassium": "261",
    "glycemic_index": "15",
    "allergens": "",
    "short_description": "کدو کم‌کالری و آب بالا؛ حجم غذایی.",
    "serving_notes": "ارزش‌ها برای کدو سبز پخته در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "کبابی یا تفت.",
    "tip_2": "در کوکو سبزی.",
    "tip_3": "یک عدد متوسط.",
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
    "legacy_slug": "zucchini-cooked",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1511690743698-d9d85f2fbf38?w=800&q=80",
    "aliases_en": [
      "Zucchini cooked",
      "Courgette"
    ],
    "related_slugs": [
      "خیار",
      "گوجه‌فرنگی",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "سبزیجات summer برای تعریف.",
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
    "slug": "بادمجان-پخته",
    "title": "بادمجان پخته",
    "excerpt": "مرجع علمی بادمجان پخته: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "سبزیجات",
    "rank_math_title": "بادمجان پخته | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای بادمجان پخته در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "بادمجان پخته",
    "name_app": "بادمجان پخته",
    "other_names": "بادمجان, Eggplant",
    "food_group": "سبزیجات",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "0.8",
    "calories": "35",
    "carbohydrates": "8.7",
    "fat": "0.2",
    "saturated_fat": "0.1",
    "fiber": "2.5",
    "sugar": "1.0",
    "cholesterol": "0",
    "sodium": "2",
    "potassium": "123",
    "glycemic_index": "15",
    "allergens": "",
    "short_description": "بادمجان فیبر و antioxidant nasunin؛ کبابی یا خوراک.",
    "serving_notes": "ارزش‌ها برای بادمجان پخته در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "روغن کم جذب می‌کند.",
    "tip_2": "کباب بادمجان.",
    "tip_3": "با ماست موسیر.",
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
    "legacy_slug": "eggplant-cooked",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1473093295045-ddd4c915dc20?w=800&q=80",
    "aliases_en": [
      "Eggplant cooked",
      "Aubergine"
    ],
    "related_slugs": [
      "خیار",
      "گوجه‌فرنگی",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "بادمجان در غذای ایرانی رایج است.",
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
    "slug": "پیاز-خام",
    "title": "پیاز خام",
    "excerpt": "مرجع علمی پیاز خام: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "سبزیجات",
    "rank_math_title": "پیاز خام | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای پیاز خام در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "پیاز خام",
    "name_app": "پیاز خام",
    "other_names": "پیاز, Onion",
    "food_group": "سبزیجات",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "1.1",
    "calories": "40",
    "carbohydrates": "9.3",
    "fat": "0.1",
    "saturated_fat": "0.0",
    "fiber": "1.7",
    "sugar": "1.1",
    "cholesterol": "0",
    "sodium": "4",
    "potassium": "146",
    "glycemic_index": "15",
    "allergens": "",
    "short_description": "پیاز quercetin و prebiotic دارد؛ طعم‌دهنده سالم.",
    "serving_notes": "ارزش‌ها برای پیاز خام در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "پخت caramelize شیرین.",
    "tip_2": "در سالاد مقدار کم.",
    "tip_3": "برای طعم غذا.",
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
    "legacy_slug": "onion-raw",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1455619452474-d2be8b1e70cb?w=800&q=80",
    "aliases_en": [
      "Onion raw",
      "Fresh onion"
    ],
    "related_slugs": [
      "خیار",
      "گوجه‌فرنگی",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "prebiotic برای میکروbiome.",
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
  }
]
GYMAI_FOOD_BATCH6
        , true);
        return is_array($cache) ? $cache : array();
    }
}
