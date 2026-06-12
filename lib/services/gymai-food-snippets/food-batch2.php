// GymAI Foods — BATCH 2 (خوراکی 11–20)
// Code Snippets: Run everywhere | بدون تگ php
// یا کپی در: wp-content/gymai-seed/food-batch2.php

if (!function_exists('gymai_food_batch2_definitions')) {
    function gymai_food_batch2_definitions() {
        static $cache = null;
        if ($cache !== null) {
            return $cache;
        }
        $cache = json_decode(<<<'GYMAI_FOOD_BATCH2'
[
  {
    "slug": "ماهی-شیر-گریل-شده",
    "title": "ماهی شیر گریل شده",
    "excerpt": "مرجع علمی ماهی شیر گریل شده: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "پروتئین‌ها",
    "rank_math_title": "ماهی شیر گریل شده | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای ماهی شیر گریل شده در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "ماهی شیر گریل شده",
    "name_app": "ماهی شیر گریل شده",
    "other_names": "ماهی شیر, Mackerel",
    "food_group": "پروتئین",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "palm_protein",
    "protein": "25",
    "calories": "231",
    "carbohydrates": "0",
    "fat": "14.0",
    "saturated_fat": "4.9",
    "fiber": "0",
    "sugar": "0",
    "cholesterol": "15",
    "sodium": "65",
    "potassium": "380",
    "glycemic_index": "0",
    "allergens": "ماهی",
    "short_description": "ماهی شیر منبع پروتئین و امگا۳ است؛ چربی آن برای سلامت قلب و التهاب در ورزشکاران ارزشمند است.",
    "serving_notes": "ارزش‌ها برای ماهی شیر گریل شده در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "بدون روغن اضافه گریل کنید تا کالری کنترل شود.",
    "tip_2": "با سبزیجات و برنج قهوه‌ای وعده متعادل بسازید.",
    "tip_3": "در هفته ۲–۳ وعده ماهی چرب توصیه می‌شود.",
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
    "legacy_slug": "grilled-mackerel",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1498837167922-ddd27525b352?w=800&q=80",
    "aliases_en": [
      "Grilled mackerel",
      "Mackerel"
    ],
    "related_slugs": [
      "سینه-مرغ-گریل-شده",
      "تخم‌مرغ-آب‌پز",
      "نان-سنگک-کامل"
    ],
    "intro": "ماهی شیر در مطالعات تغذیه‌ای به‌عنوان منبع DHA و EPA شناخته می‌شود.",
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
    "slug": "میگو-پخته",
    "title": "میگو پخته",
    "excerpt": "مرجع علمی میگو پخته: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "پروتئین‌ها",
    "rank_math_title": "میگو پخته | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای میگو پخته در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "میگو پخته",
    "name_app": "میگو پخته",
    "other_names": "میگو, Shrimp",
    "food_group": "پروتئین",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "palm_protein",
    "protein": "24",
    "calories": "99",
    "carbohydrates": "0.2",
    "fat": "0.3",
    "saturated_fat": "0.1",
    "fiber": "0",
    "sugar": "0",
    "cholesterol": "15",
    "sodium": "111",
    "potassium": "259",
    "glycemic_index": "0",
    "allergens": "میگو, صدف",
    "short_description": "میگو پروتئین بالا و چربی بسیار کم دارد؛ برای دوره تعریف و رژیم کم‌کالری مناسب است.",
    "serving_notes": "ارزش‌ها برای میگو پخته در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "پخت کوتاه از خشکی جلوگیری می‌کند.",
    "tip_2": "کلسترول میگو برای اکثر افراد سالم مشکل‌ساز نیست.",
    "tip_3": "با سیر و لیمو طعم بدون سس پرچرب بدهید.",
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
    "legacy_slug": "cooked-shrimp",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80",
    "aliases_en": [
      "Cooked shrimp",
      "Shrimp"
    ],
    "related_slugs": [
      "سینه-مرغ-گریل-شده",
      "تخم‌مرغ-آب‌پز",
      "نان-سنگک-کامل"
    ],
    "intro": "میگو در تغذیه ورزشی به‌خاطر نسبت پروتئین به کالری بالا محبوب است.",
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
    "slug": "گوشت-چرخ‌کرده-کم‌چرب-پخته",
    "title": "گوشت چرخ‌کرده کم‌چرب پخته",
    "excerpt": "مرجع علمی گوشت چرخ‌کرده کم‌چرب پخته: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "پروتئین‌ها",
    "rank_math_title": "گوشت چرخ‌کرده کم‌چرب پخته | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای گوشت چرخ‌کرده کم‌چرب پخته در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "گوشت چرخ‌کرده کم‌چرب پخته",
    "name_app": "گوشت چرخ‌کرده کم‌چرب پخته",
    "other_names": "گوشت چرخ‌کرده, Ground beef",
    "food_group": "پروتئین",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "palm_protein",
    "protein": "26",
    "calories": "250",
    "carbohydrates": "0",
    "fat": "15.0",
    "saturated_fat": "5.2",
    "fiber": "0",
    "sugar": "0",
    "cholesterol": "15",
    "sodium": "72",
    "potassium": "318",
    "glycemic_index": "0",
    "allergens": "",
    "short_description": "گوشت چرخ‌کرده ۹۰٪ کم‌چرب پروتئین و آهن هم‌زمان فراهم می‌کند؛ برای حجم‌گیری مفید است.",
    "serving_notes": "ارزش‌ها برای گوشت چرخ‌کرده کم‌چرب پخته در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "چربی اضافه را در تفت بگیرید.",
    "tip_2": "با لوبیا و گوجه خوراک ایرانی متعادل بسازید.",
    "tip_3": "دمای پخت کامل برای ایمنی رعایت شود.",
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
    "legacy_slug": "lean-ground-beef-cooked",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80",
    "aliases_en": [
      "Lean ground beef cooked",
      "Ground beef"
    ],
    "related_slugs": [
      "سینه-مرغ-گریل-شده",
      "تخم‌مرغ-آب‌پز",
      "نان-سنگک-کامل"
    ],
    "intro": "گوشت قرمز کم‌چرب منبع کراتین طبیعی در تغذیه قدرتی است.",
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
    "slug": "جوجه-کباب",
    "title": "جوجه کباب",
    "excerpt": "مرجع علمی جوجه کباب: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "پروتئین‌ها",
    "rank_math_title": "جوجه کباب | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای جوجه کباب در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "جوجه کباب",
    "name_app": "جوجه کباب",
    "other_names": "جوجه کباب, Joojeh kebab",
    "food_group": "پروتئین",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "palm_protein",
    "protein": "31",
    "calories": "165",
    "carbohydrates": "0",
    "fat": "3.5",
    "saturated_fat": "1.2",
    "fiber": "0",
    "sugar": "0",
    "cholesterol": "15",
    "sodium": "75",
    "potassium": "280",
    "glycemic_index": "0",
    "allergens": "",
    "short_description": "جوجه کباب سینه مرغ کبابی؛ پرکاربرد در برنامه‌های ایرانی — بدون برنج، با برنج یا نان جدا ترکیب شود.",
    "serving_notes": "ارزش‌ها برای جوجه کباب در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "برنج و سالاد را جدا در برنامه بچینید.",
    "tip_2": "بدون روغن اضافه یا سس پرچرب.",
    "tip_3": "یک سیخ متوسط حدود ۱۲۰–۱۵۰ گرم.",
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
    "legacy_slug": "grilled-lean-burger",
    "migrate_slugs": [
      "همبرگر-گریل-کم‌چرب"
    ],
    "image_url": "https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800&q=80",
    "aliases_en": [
      "Chicken kebab",
      "Joojeh kebab"
    ],
    "related_slugs": [
      "سینه-مرغ-گریل-شده",
      "تخم‌مرغ-آب‌پز",
      "نان-سنگک-کامل"
    ],
    "intro": "جوجه کباب یکی از پایه‌های پروتئین در رژیم ایرانی و بدنسازی است.",
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
    "slug": "جگر-مرغ-پخته",
    "title": "جگر مرغ پخته",
    "excerpt": "مرجع علمی جگر مرغ پخته: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "پروتئین‌ها",
    "rank_math_title": "جگر مرغ پخته | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای جگر مرغ پخته در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "جگر مرغ پخته",
    "name_app": "جگر مرغ پخته",
    "other_names": "جگر, Chicken liver",
    "food_group": "پروتئین",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "palm_protein",
    "protein": "25",
    "calories": "167",
    "carbohydrates": "1",
    "fat": "6.0",
    "saturated_fat": "2.1",
    "fiber": "0",
    "sugar": "0.1",
    "cholesterol": "15",
    "sodium": "69",
    "potassium": "230",
    "glycemic_index": "0",
    "allergens": "",
    "short_description": "جگر مرغ سرشار از آهن، B12 و ویتامین A است؛ مصرف هفته‌ای محدود توصیه می‌شود.",
    "serving_notes": "ارزش‌ها برای جگر مرغ پخته در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "یک وعده ۸۰–۱۰۰ گرم برای اکثر افراد کافی است.",
    "tip_2": "با پیاز و ادویه ایرانی پخت کنید.",
    "tip_3": "در بارداری یا افراد خاص با پزشک مشورت کنید.",
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
    "legacy_slug": "chicken-liver-cooked",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80",
    "aliases_en": [
      "Chicken liver cooked",
      "Liver"
    ],
    "related_slugs": [
      "سینه-مرغ-گریل-شده",
      "تخم‌مرغ-آب‌پز",
      "نان-سنگک-کامل"
    ],
    "intro": "جگر یکی از متراکم‌ترین منابع ریزمغذی در رژیم پروتئینی است.",
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
    "slug": "پستانک-گوسفند-گریل",
    "title": "پستانک گوسفند گریل",
    "excerpt": "مرجع علمی پستانک گوسفند گریل: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "پروتئین‌ها",
    "rank_math_title": "پستانک گوسفند گریل | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای پستانک گوسفند گریل در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "پستانک گوسفند گریل",
    "name_app": "پستانک گوسفند گریل",
    "other_names": "پستانک, Lamb breast",
    "food_group": "پروتئین",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "palm_protein",
    "protein": "28",
    "calories": "206",
    "carbohydrates": "0",
    "fat": "10.0",
    "saturated_fat": "3.5",
    "fiber": "0",
    "sugar": "0",
    "cholesterol": "15",
    "sodium": "65",
    "potassium": "315",
    "glycemic_index": "0",
    "allergens": "لبنیات",
    "short_description": "پستانک پروتئین و چربی متوسط دارد؛ در رژیم حجم انرژی بیشتری نسبت به سینه مرغ فراهم می‌کند.",
    "serving_notes": "ارزش‌ها برای پستانک گوسفند گریل در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "چربی قابل‌رؤیت را جدا کنید.",
    "tip_2": "با سبزیجات و نان سنگک سهم کربو را کنترل کنید.",
    "tip_3": "پخت آهسته طعم بهتری می‌دهد.",
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
    "legacy_slug": "grilled-lamb-breast",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1482049016688-a7bd8fa7e6a1?w=800&q=80",
    "aliases_en": [
      "Grilled lamb breast",
      "Lamb"
    ],
    "related_slugs": [
      "سینه-مرغ-گریل-شده",
      "تخم‌مرغ-آب‌پز",
      "نان-سنگک-کامل"
    ],
    "intro": "گوشت گوسفند در رژیم ایرانی منبع آهن هِم است.",
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
    "slug": "کباب-برگ-کم‌چرب",
    "title": "کباب برگ کم‌چرب",
    "excerpt": "مرجع علمی کباب برگ کم‌چرب: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "پروتئین‌ها",
    "rank_math_title": "کباب برگ کم‌چرب | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای کباب برگ کم‌چرب در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "کباب برگ کم‌چرب",
    "name_app": "کباب برگ کم‌چرب",
    "other_names": "برگ, Barg kebab",
    "food_group": "پروتئین",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "palm_protein",
    "protein": "27",
    "calories": "220",
    "carbohydrates": "0",
    "fat": "12.0",
    "saturated_fat": "4.2",
    "fiber": "0",
    "sugar": "0",
    "cholesterol": "15",
    "sodium": "58",
    "potassium": "340",
    "glycemic_index": "0",
    "allergens": "",
    "short_description": "کباب برگ با فیله گوساله پروتئین با کیفیت و چربی کنترل‌شده دارد.",
    "serving_notes": "ارزش‌ها برای کباب برگ کم‌چرب در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "Marinade شیرین نباشد تا قند اضافه نیاید.",
    "tip_2": "با برنج یا نان سنگک و سالاد سرو کنید.",
    "tip_3": "برش نازک پخت یکنواخت‌تر است.",
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
    "legacy_slug": "barg-kebab-lean",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800&q=80",
    "aliases_en": [
      "Barg kebab lean",
      "Beef kebab"
    ],
    "related_slugs": [
      "سینه-مرغ-گریل-شده",
      "تخم‌مرغ-آب‌پز",
      "نان-سنگک-کامل"
    ],
    "intro": "کباب برگ از غذاهای پرپروتئین سنتی در رژیم ورزشکاران است.",
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
    "slug": "ماهی-سفید-پخته",
    "title": "ماهی سفید پخته",
    "excerpt": "مرجع علمی ماهی سفید پخته: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "پروتئین‌ها",
    "rank_math_title": "ماهی سفید پخته | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای ماهی سفید پخته در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "ماهی سفید پخته",
    "name_app": "ماهی سفید پخته",
    "other_names": "ماهی سفید, Cod",
    "food_group": "پروتئین",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "palm_protein",
    "protein": "22",
    "calories": "105",
    "carbohydrates": "0",
    "fat": "1.5",
    "saturated_fat": "0.5",
    "fiber": "0",
    "sugar": "0",
    "cholesterol": "15",
    "sodium": "78",
    "potassium": "356",
    "glycemic_index": "0",
    "allergens": "ماهی",
    "short_description": "ماهی سفید کم‌چرب و پروتئین بالا است؛ برای وعده سبک بعد تمرین مناسب است.",
    "serving_notes": "ارزش‌ها برای ماهی سفید پخته در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "بخارپز یا گریل بدون روغن.",
    "tip_2": "با لیمو و سبزی تازه طعم دهید.",
    "tip_3": "فریز کیفیت پروتئین را حفظ می‌کند.",
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
    "legacy_slug": "white-fish-cooked",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1511690743698-d9d85f2fbf38?w=800&q=80",
    "aliases_en": [
      "White fish cooked",
      "Cod"
    ],
    "related_slugs": [
      "سینه-مرغ-گریل-شده",
      "تخم‌مرغ-آب‌پز",
      "نان-سنگک-کامل"
    ],
    "intro": "ماهی سفید در رژیم کم‌چرب جایگزین مرغ است.",
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
    "slug": "پنیر-سفید-کم‌چرب",
    "title": "پنیر سفید کم‌چرب",
    "excerpt": "مرجع علمی پنیر سفید کم‌چرب: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "لبنیات",
    "rank_math_title": "پنیر سفید کم‌چرب | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای پنیر سفید کم‌چرب در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "پنیر سفید کم‌چرب",
    "name_app": "پنیر سفید کم‌چرب",
    "other_names": "پنیر سفید, Cottage cheese",
    "food_group": "لبنیات",
    "food_type": "solid",
    "meal_times": "صبحانه,میان‌وعده",
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
    "potassium": "86",
    "glycemic_index": "10",
    "allergens": "لبنیات",
    "short_description": "پنیر سفید کم‌چرب کازئین کند جذب دارد؛ برای میان‌وعده شب یا صبح مناسب است.",
    "serving_notes": "ارزش‌ها برای پنیر سفید کم‌چرب در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "با میوه یا خیار ترکیب کنید.",
    "tip_2": "نمک را در کل روز لحاظ کنید.",
    "tip_3": "نسخه کم‌چرب برای تعریف بهتر است.",
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
    "legacy_slug": "low-fat-cottage-cheese",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1473093295045-ddd4c915dc20?w=800&q=80",
    "aliases_en": [
      "Low fat cottage cheese",
      "Cottage cheese"
    ],
    "related_slugs": [
      "ماست-یونانی-کم‌چرب",
      "ماست-چکیده",
      "نان-سنگک-کامل"
    ],
    "intro": "کازئین در پنیر سفید برای MPS طولانی‌مدت مطرح است.",
    "substitutes": [
      {
        "slug": "ماست-یونانی-کم‌چرب",
        "ratio": 1.0
      },
      {
        "slug": "ماست-چکیده",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "مرغ-کامل-پخته-بدون-پوست",
    "title": "مرغ کامل پخته بدون پوست",
    "excerpt": "مرجع علمی مرغ کامل پخته بدون پوست: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "پروتئین‌ها",
    "rank_math_title": "مرغ کامل پخته بدون پوست | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای مرغ کامل پخته بدون پوست در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "مرغ کامل پخته بدون پوست",
    "name_app": "مرغ کامل پخته بدون پوست",
    "other_names": "مرغ کامل, Whole chicken",
    "food_group": "پروتئین",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "palm_protein",
    "protein": "29",
    "calories": "190",
    "carbohydrates": "0",
    "fat": "7.4",
    "saturated_fat": "2.6",
    "fiber": "0",
    "sugar": "0",
    "cholesterol": "15",
    "sodium": "82",
    "potassium": "220",
    "glycemic_index": "0",
    "allergens": "",
    "short_description": "مرغ کامل بدون پوست ترکیب سینه و ران است؛ پروتئین بالا با چربی متوسط.",
    "serving_notes": "ارزش‌ها برای مرغ کامل پخته بدون پوست در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "پوست را قبل پخت جدا کنید.",
    "tip_2": "باقیمانده را برای سالاد فردا استفاده کنید.",
    "tip_3": "پخت یکپارچه در فر یکنواخت‌تر است.",
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
    "legacy_slug": "whole-chicken-cooked",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1455619452474-d2be8b1e70cb?w=800&q=80",
    "aliases_en": [
      "Whole chicken cooked",
      "Roasted chicken"
    ],
    "related_slugs": [
      "سینه-مرغ-گریل-شده",
      "تخم‌مرغ-آب‌پز",
      "نان-سنگک-کامل"
    ],
    "intro": "مرغ کامل گزینه اقتصادی پروتئین در برنامه هفتگی است.",
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
  }
]
GYMAI_FOOD_BATCH2
        , true);
        return is_array($cache) ? $cache : array();
    }
}
