// GymAI Foods — BATCH 1 (خوراکی 1–10)
// Code Snippets: Run everywhere | بدون تگ php
// یا کپی در: wp-content/gymai-seed/food-batch1.php

if (!function_exists('gymai_food_batch1_definitions')) {
    function gymai_food_batch1_definitions() {
        static $cache = null;
        if ($cache !== null) {
            return $cache;
        }
        $cache = json_decode(<<<'GYMAI_FOOD_BATCH1'
[
  {
    "slug": "نان-سنگک-کامل",
    "title": "نان سنگک کامل",
    "excerpt": "مرجع علمی نان سنگک کامل: کالری، کربوهیدرات، فیبر و شاخص گلیسمی در ۱۰۰ گرم — مناسب تغذیه ورزشی و برنامه غذایی.",
    "category": "کربوهیدرات‌ها",
    "rank_math_title": "نان سنگک کامل | کالری، پروتئین و واحد سرو برای بدنسازی",
    "rank_math_description": "جدول تغذیه‌ای نان سنگک کامل در ۱۰۰ گرم: کالری، کربوهیدرات، فیبر و GI. راهنمای علمی برای ورزشکاران و مربیان تغذیه.",
    "rank_math_focus_keyword": "نان سنگک کامل",
    "name_app": "نان سنگک کامل",
    "other_names": "نان سنگک, سنگک, Whole Wheat Sangak, نان سنتی",
    "food_group": "کربوهیدرات",
    "food_type": "solid",
    "meal_times": "صبحانه,ناهار,قبل تمرین",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "piece",
    "protein": "9",
    "calories": "265",
    "carbohydrates": "49",
    "fat": "2.5",
    "saturated_fat": "0.5",
    "fiber": "7",
    "sugar": "2",
    "cholesterol": "0",
    "sodium": "490",
    "potassium": "140",
    "glycemic_index": "55",
    "allergens": "گلوتن (گندم)",
    "short_description": "نان سنگک کامل یکی از بهترین منابع کربوهیدرات پیچیده در رژیم ایرانی است. فیبر بالا باعث آزادسازی آهسته انرژی می‌شود و برای صبحانه یا وعده قبل تمرین مناسب است.",
    "serving_notes": "ارزش‌ها برای نان پخته و بدون روغن اضافی است. یک تکه متوسط حدود ۳۵ گرم است.",
    "tip_1": "برای کاهش قند خون، نان را با پروتئین (تخم‌مرغ یا ماست) مصرف کنید.",
    "tip_2": "نان داغ و تازه کالری یکسان دارد؛ مهم حجم و گرمی مصرفی است.",
    "tip_3": "در دوره چربی‌سوزی، واحد کربوهیدرات را با کف دست اندازه بگیرید.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "piece",
      "units": [
        {
          "key": "piece",
          "label": "عدد (تکه)",
          "grams": 35,
          "step": 0.5,
          "decimals": 1,
          "is_primary": true,
          "hint": "یک تکه نان سنگک متوسط"
        },
        {
          "key": "palm_carb",
          "label": "کف دست (کربو)",
          "grams": 20,
          "step": 0.5,
          "decimals": 1,
          "is_primary": false,
          "hint": "یک واحد کربوهیدرات در رژیم"
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
    "legacy_slug": "sangak-whole-wheat-bread",
    "image_url": "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=800&q=80",
    "aliases_en": [
      "Whole wheat bread",
      "Sangak bread"
    ],
    "related_slugs": [
      "برنج-سفید-پخته",
      "سیب‌زمینی-آب‌پز",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "نان سنگک کامل یکی از پایه‌های سبد غذایی ایرانی است و در مطالعات تغذیه‌ای به‌عنوان منبع کربوهیدرات پیچیده و فیبر مورد بررسی قرار می‌گیرد.",
    "substitutes": [
      {
        "slug": "برنج-سفید-پخته",
        "ratio": 1.0
      },
      {
        "slug": "سیب‌زمینی-آب‌پز",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "برنج-سفید-پخته",
    "title": "برنج سفید پخته",
    "excerpt": "ارزش غذایی برنج سفید پخته در ۱۰۰ گرم: کالری، کربوهیدرات و شاخص گلیسمی — مرجع علمی تغذیه ورزشی.",
    "category": "کربوهیدرات‌ها",
    "rank_math_title": "برنج سفید پخته | کالری، قاشق سرو و نکات بدنسازی",
    "rank_math_description": "کالری و ماکروهای برنج سفید پخته در هر ۱۰۰ گرم. تفسیر GI و زمان‌بندی مصرف در تغذیه ورزشی.",
    "rank_math_focus_keyword": "برنج سفید پخته",
    "name_app": "برنج سفید پخته",
    "other_names": "برنج سفید, برنج پخته, برنج ایرانی, Cooked White Rice, چلو",
    "food_group": "کربوهیدرات",
    "food_type": "solid",
    "meal_times": "ناهار,شام,بعد تمرین",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "tablespoon",
    "protein": "2.7",
    "calories": "130",
    "carbohydrates": "28",
    "fat": "0.3",
    "saturated_fat": "0.1",
    "fiber": "0.4",
    "sugar": "0.1",
    "cholesterol": "0",
    "sodium": "1",
    "potassium": "35",
    "glycemic_index": "73",
    "allergens": "",
    "short_description": "برنج پخته انرژی سریع برای ریکاوری بعد تمرین فراهم می‌کند. شاخص گلیسمی بالاتر از برنج قهوه‌ای است؛ زمان‌بندی مصرف مهم است.",
    "serving_notes": "مقادیر برای برنج پخته بدون روغن و نمک اضافه. یک قاشق غذاخوری حدود ۱۵ گرم برنج پخته است.",
    "tip_1": "بعد تمرین قدرتی ۱–۲ پیمانه برنج با پروتئین ریکاوری را تسریع می‌کند.",
    "tip_2": "در روزهای استراحت حجم برنج را کمتر از روز تمرین در نظر بگیرید.",
    "tip_3": "برنج را با سبزیجات و سالاد میل کنید تا حجم غذایی و فیبر بیشتر شود.",
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
          "hint": "برنج پخته فشرده"
        },
        {
          "key": "cup",
          "label": "پیمانه / لیوان",
          "grams": 150,
          "step": 0.5,
          "decimals": 1,
          "is_primary": false,
          "hint": "لیوان برنج پخته"
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
    "legacy_slug": "cooked-white-rice",
    "image_url": "https://images.unsplash.com/photo-1586201375761-83865001e31c?w=800&q=80",
    "aliases_en": [
      "Cooked white rice",
      "Steamed rice"
    ],
    "related_slugs": [
      "نان-سنگک-کامل",
      "سیب‌زمینی-آب‌پز",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "برنج پخته ستون انرژی‌زای رژیم ایرانی است؛ در تغذیه ورزشی بیشتر برای تأمین گلیکوژن و ریکاوری بعد تمرین مورد توجه است.",
    "substitutes": [
      {
        "slug": "نان-سنگک-کامل",
        "ratio": 1.0
      },
      {
        "slug": "سیب‌زمینی-آب‌پز",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "سینه-مرغ-گریل-شده",
    "title": "سینه مرغ گریل شده",
    "excerpt": "پروتئین، کالری و پروفایل چربی سینه مرغ گریل در ۱۰۰ گرم — داده علمی برای برنامه غذایی ورزشکاران.",
    "category": "پروتئین‌ها",
    "rank_math_title": "سینه مرغ گریل شده | پروتئین، کالری و واحد سرو",
    "rank_math_description": "مرجع سینه مرغ گریل شده: پروتئین و کالری در ۱۰۰ گرم، کاربرد در حجم و تعریف عضلانی.",
    "rank_math_focus_keyword": "سینه مرغ گریل شده",
    "name_app": "سینه مرغ گریل",
    "other_names": "مرغ گریل, Chicken Breast Grilled, فیله مرغ",
    "food_group": "پروتئین",
    "food_type": "solid",
    "meal_times": "ناهار,شام,بعد تمرین",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "palm_protein",
    "protein": "31",
    "calories": "165",
    "carbohydrates": "0",
    "fat": "3.6",
    "saturated_fat": "1",
    "fiber": "0",
    "sugar": "0",
    "cholesterol": "85",
    "sodium": "74",
    "potassium": "256",
    "glycemic_index": "0",
    "allergens": "",
    "short_description": "سینه مرغ گریل یکی از پایه‌ترین منابع پروتئین در بدنسازی است: چربی کم، پروتئین بالا، آماده‌سازی ساده.",
    "serving_notes": "بدون پوست و بدون روغن اضافه. یک کف دست پروتئین حدود ۸۵ گرم گوشت پخته است.",
    "tip_1": "مرغ را بیش از حد نپزید تا خشک نشود؛ دمای داخلی ۷۴ درجه کافی است.",
    "tip_2": "ادویه و لیمو جایگزین سس‌های پرچرب شود.",
    "tip_3": "هر وعده ۱ تا ۱.۵ کف دست پروتئین برای بیشتر ورزشکاران مناسب است.",
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
    "legacy_slug": "grilled-chicken-breast",
    "image_url": "https://images.unsplash.com/photo-1604503468506-a8da13d4c137?w=800&q=80",
    "aliases_en": [
      "Grilled chicken breast",
      "Chicken breast"
    ],
    "related_slugs": [
      "تخم‌مرغ-آب‌پز",
      "ماهی-قزل‌آلای-گریل",
      "نان-سنگک-کامل"
    ],
    "intro": "سینه مرغ گریل‌شده یکی از منابع کلاسیک پروتئین با چربی کنترل‌شده در ادبیات بدنسازی و تغذیه بالینی ورزشی است.",
    "substitutes": [
      {
        "slug": "تخم‌مرغ-آب‌پز",
        "ratio": 1.0
      },
      {
        "slug": "ماهی-قزل‌آلای-گریل",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "تخم‌مرغ-آب‌پز",
    "title": "تخم‌مرغ آب‌پز",
    "excerpt": "کالری و پروتئین تخم‌مرغ آب‌پز در ۱۰۰ گرم و هر عدد — مرجع علمی تغذیه و بدنسازی.",
    "category": "پروتئین‌ها",
    "rank_math_title": "تخم‌مرغ آب‌پز | کالری، پروتئین و فواید بدنسازی",
    "rank_math_description": "ارزش غذایی تخم‌مرغ آب‌پز: پروتئین، چربی و کلسترول در ۱۰۰ گرم. راهنمای مصرف در تغذیه ورزشی.",
    "rank_math_focus_keyword": "تخم‌مرغ آب‌پز",
    "name_app": "تخم‌مرغ آب‌پز",
    "other_names": "تخم مرغ, Egg Boiled, Hard Boiled Egg",
    "food_group": "پروتئین",
    "food_type": "solid",
    "meal_times": "صبحانه,میان‌وعده صبح,میان‌وعده عصر",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "piece",
    "protein": "13",
    "calories": "155",
    "carbohydrates": "1.1",
    "fat": "11",
    "saturated_fat": "3.3",
    "fiber": "0",
    "sugar": "1.1",
    "cholesterol": "373",
    "sodium": "124",
    "potassium": "126",
    "glycemic_index": "0",
    "allergens": "تخم‌مرغ",
    "short_description": "تخم‌مرغ آب‌پز پروتئین باکیفیت با چربی مفید و سیرکنندگی بالا. یک عدد بزرگ حدود ۵۰ گرم است.",
    "serving_notes": "یک عدد تخم‌مرغ بزرگ ≈ ۵۰ گرم (حدود ۷۸ کالری). زرده کلسترول دارد؛ در رژیم سالم ۱–۳ عدد روزانه معمولاً مجاز است.",
    "tip_1": "برای صبحانه ۲ تا ۴ عدد با نان سنگک ترکیب عالی پروتئین-کربو است.",
    "tip_2": "تخم‌مرغ را ۹–۱۰ دقیقه بجوشانید تا زرده کاملاً پخته و جدا کردن آسان باشد.",
    "tip_3": "اگر کلسترول بالا دارید، با پزشک درباره تعداد زرده مشورت کنید.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "piece",
      "units": [
        {
          "key": "piece",
          "label": "عدد",
          "grams": 50,
          "step": 1,
          "decimals": 0,
          "is_primary": true,
          "hint": "یک عدد تخم‌مرغ بزرگ"
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
    "legacy_slug": "boiled-egg",
    "image_url": "https://images.unsplash.com/photo-1587486913049-658fc9572040?w=800&q=80",
    "aliases_en": [
      "Boiled egg",
      "Hard boiled egg"
    ],
    "related_slugs": [
      "سینه-مرغ-گریل-شده",
      "ماهی-قزل‌آلای-گریل",
      "نان-سنگک-کامل"
    ],
    "intro": "تخم‌مرغ آب‌پز منبع اقتصادی پروتئین با کیفیت بالا و میکرونوترینت‌هایی مانند ویتامین D و B12 است که در رژیم ورزشکاران پرکاربرد است.",
    "substitutes": [
      {
        "slug": "سینه-مرغ-گریل-شده",
        "ratio": 1.0
      },
      {
        "slug": "ماهی-قزل‌آلای-گریل",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "ماست-یونانی-کم‌چرب",
    "title": "ماست یونانی کم‌چرب",
    "excerpt": "پروتئین و کالری ماست یونانی کم‌چرب در ۱۰۰ گرم — مرجع علمی برای صبحانه و میان‌وعده ورزشی.",
    "category": "لبنیات",
    "rank_math_title": "ماست یونانی کم‌چرب | پروتئین، کالری و نکات مصرف",
    "rank_math_description": "ماست یونانی کم‌چرب: ماکروها در ۱۰۰ گرم، پروبیوتیک و کاربرد در ریکاوری و سیری.",
    "rank_math_focus_keyword": "ماست یونانی کم‌چرب",
    "name_app": "ماست یونانی کم‌چرب",
    "other_names": "ماست یونانی, Greek Yogurt, ماست پروتئینی",
    "food_group": "لبنیات",
    "food_type": "solid",
    "meal_times": "صبحانه,میان‌وعده صبح,قبل خواب",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "10",
    "calories": "59",
    "carbohydrates": "3.6",
    "fat": "0.4",
    "saturated_fat": "0.3",
    "fiber": "0",
    "sugar": "3.2",
    "cholesterol": "5",
    "sodium": "36",
    "potassium": "141",
    "glycemic_index": "11",
    "allergens": "لبنیات",
    "short_description": "ماست یونانی کم‌چرب پروتئین بالا و قند کم دارد. برای میان‌وعده شبانه با کازئین کند هضم مناسب است.",
    "serving_notes": "یک پیمانه کوچک (۱۵۰ گرم) حدود ۱۵ گرم پروتئین دارد. نسخه بدون شکر اضافه را انتخاب کنید.",
    "tip_1": "با توت یا دارچین شیرین کنید؛ از شکر سفید پرهیز کنید.",
    "tip_2": "قبل خواب یک پیمانه با کمی بادام برای ریکاوری شبانه عالی است.",
    "tip_3": "برچسب را بخوانید؛ بعضی برندها شکر مخفی دارند.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "cup",
      "units": [
        {
          "key": "cup",
          "label": "پیمانه کوچک",
          "grams": 150,
          "step": 0.5,
          "decimals": 1,
          "is_primary": true,
          "hint": "حدود ۱۵۰ گرم"
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
    "legacy_slug": "greek-yogurt-low-fat",
    "image_url": "https://images.unsplash.com/photo-1488477181946-6428a0291777?w=800&q=80",
    "aliases_en": [
      "Greek yogurt",
      "Low fat yogurt"
    ],
    "related_slugs": [
      "پنیر-سفید-کم‌چرب",
      "ماست-چکیده",
      "نان-سنگک-کامل"
    ],
    "intro": "ماست یونانی کم‌چرب ترکیبی از پروتئین، کلسیم و بافت سیرکننده است و در مطالعات تغذیه ورزشی برای وعده‌های پروتئینی سبک بررسی شده است.",
    "substitutes": [
      {
        "slug": "پنیر-سفید-کم‌چرب",
        "ratio": 1.0
      },
      {
        "slug": "ماست-چکیده",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "سیب‌زمینی-آب‌پز",
    "title": "سیب‌زمینی آب‌پز",
    "excerpt": "کالری، کربوهیدرات و پتاسیم سیب‌زمینی آب‌پز در ۱۰۰ گرم — مرجع علمی تغذیه ورزشی.",
    "category": "کربوهیدرات‌ها",
    "rank_math_title": "سیب‌زمینی آب‌پز | کالری، پتاسیم و واحد سرو",
    "rank_math_description": "جدول تغذیه‌ای سیب‌زمینی آب‌پز: انرژی، GI و پتاسیم. کاربرد قبل و بعد تمرین.",
    "rank_math_focus_keyword": "سیب‌زمینی آب‌پز",
    "name_app": "سیب‌زمینی آب‌پز",
    "other_names": "سیب زمینی, Boiled Potato, سیب‌زمینی پخته",
    "food_group": "کربوهیدرات",
    "food_type": "solid",
    "meal_times": "ناهار,قبل تمرین",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "piece",
    "protein": "1.9",
    "calories": "87",
    "carbohydrates": "20",
    "fat": "0.1",
    "saturated_fat": "0",
    "fiber": "1.8",
    "sugar": "0.9",
    "cholesterol": "0",
    "sodium": "5",
    "potassium": "421",
    "glycemic_index": "78",
    "allergens": "",
    "short_description": "سیب‌زمینی آب‌پز انرژی پایدار و پتاسیم بالا برای انقباض عضلانی فراهم می‌کند. با پوست فیبر بیشتری دارد.",
    "serving_notes": "یک عدد متوسط ≈ ۱۵۰ گرم. بدون کره و روغن اضافه محاسبه شده.",
    "tip_1": "با پوست بپزید؛ فیبر و مواد معدنی حفظ می‌شود.",
    "tip_2": "قبل تمرین ۱–۲ عدد متوسط با مرغ گریل ترکیب خوبی است.",
    "tip_3": "سیب‌زمینی سرخ‌کرده کالری و چربی متفاوت دارد — جدا لاگ کنید.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "piece",
      "units": [
        {
          "key": "piece",
          "label": "عدد متوسط",
          "grams": 150,
          "step": 0.5,
          "decimals": 1,
          "is_primary": true,
          "hint": "سیب‌زمینی متوسط آب‌پز"
        },
        {
          "key": "fist",
          "label": "مشت",
          "grams": 150,
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
    "legacy_slug": "boiled-potato",
    "image_url": "https://images.unsplash.com/photo-1518977676601-b53f82b1b2b8?w=800&q=80",
    "aliases_en": [
      "Boiled potato",
      "Potato"
    ],
    "related_slugs": [
      "نان-سنگک-کامل",
      "برنج-سفید-پخته",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "سیب‌زمینی آب‌پز منبع کربوهیدرات و پتاسیم است و در تغذیه ورزشی برای عملکرد عضلانی و تعادل الکترولیتی اهمیت دارد.",
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
    "slug": "روغن-زیتون",
    "title": "روغن زیتون",
    "excerpt": "کالری و چربی روغن زیتون در ۱۰۰ گرم و هر قاشق — مرجع علمی چربی‌های سالم در تغذیه ورزشی.",
    "category": "چربی‌های سالم",
    "rank_math_title": "روغن زیتون | کالری، قاشق سرو و فواید سلامت",
    "rank_math_description": "روغن زیتون: کالری، اسیدهای چرب و دوز مصرف در رژیم بدنسازی و سلامت عمومی.",
    "rank_math_focus_keyword": "روغن زیتون",
    "name_app": "روغن زیتون",
    "other_names": "Olive Oil, روغن زیتون بکر, EVOO",
    "food_group": "چربی",
    "food_type": "liquid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "tablespoon",
    "protein": "0",
    "calories": "884",
    "carbohydrates": "0",
    "fat": "100",
    "saturated_fat": "14",
    "fiber": "0",
    "sugar": "0",
    "cholesterol": "0",
    "sodium": "2",
    "potassium": "1",
    "glycemic_index": "0",
    "allergens": "",
    "short_description": "روغن زیتون منبع چربی تک‌اشباع و پلی‌فنل است. یک قاشق غذاخوری حدود ۱۴ گرم و ۱۲۴ کالری دارد.",
    "serving_notes": "یک قاشق غذاخوری = ۱۴ گرم. روی سالاد یا سبزیجات بزنید؛ سرخ‌کردن زیاد توصیه نمی‌شود.",
    "tip_1": "۲ تا ۴ قاشق در روز برای بیشتر افراد سالم کافی است.",
    "tip_2": "روغن بکر extra virgin کیفیت آنتی‌اکسیدانی بالاتری دارد.",
    "tip_3": "چربی را در لاگ فراموش نکنید — کالری چربی پرتراکم است.",
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
          "hint": "روغن مایع"
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
          "key": "thumb_fat",
          "label": "انگشت شست (چربی)",
          "grams": 10,
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
    "legacy_slug": "olive-oil",
    "image_url": "https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=800&q=80",
    "aliases_en": [
      "Olive oil",
      "Extra virgin olive oil"
    ],
    "related_slugs": [
      "بادام-خام",
      "گردو-خام",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "روغن زیتون بکر منبع چربی تک‌اشباع و پلی‌فنل‌هاست و در رژیم مدیترانه‌ای و تغذیه ورزشی برای سلامت قلب و هورمون‌ها مطرح است.",
    "substitutes": [
      {
        "slug": "بادام-خام",
        "ratio": 1.0
      },
      {
        "slug": "گردو-خام",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "بادام-خام",
    "title": "بادام خام",
    "excerpt": "کالری، پروتئین و فیبر بادام خام در ۱۰۰ گرم — مرجع علمی میان‌وعده در تغذیه ورزشی.",
    "category": "چربی‌های سالم",
    "rank_math_title": "بادام خام | کالری، پروتئین و واحد سرو",
    "rank_math_description": "ارزش غذایی بادام خام در ۱۰۰ گرم: انرژی، چربی مفید و ویتامین E.",
    "rank_math_focus_keyword": "بادام خام",
    "name_app": "بادام خام",
    "other_names": "بادام, Raw Almonds, آجیل بادام",
    "food_group": "چربی",
    "food_type": "solid",
    "meal_times": "میان‌وعده صبح,میان‌وعده عصر",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "piece",
    "protein": "21",
    "calories": "579",
    "carbohydrates": "22",
    "fat": "50",
    "saturated_fat": "3.8",
    "fiber": "12",
    "sugar": "4.4",
    "cholesterol": "0",
    "sodium": "1",
    "potassium": "733",
    "glycemic_index": "15",
    "allergens": "آجیل (بادام)",
    "short_description": "بادام خام میان‌وعده مقوی با فیبر و ویتامین E. حدود ۲۳ عدد بادام ≈ ۳۰ گرم (یک وعده آجیل).",
    "serving_notes": "یک عدد بادام ≈ ۱.۲ گرم. وعده استاندارد ۲۳–۲۸ عدد.",
    "tip_1": "بدون نمک و بدون بو داده خریداری کنید.",
    "tip_2": "بادام را از پیش وزن کنید؛ خوردن از کیسه باعث پرخوری می‌شود.",
    "tip_3": "با ماست یونانی میان‌وعده متعادل پروتئین-چربی بسازید.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "piece",
      "units": [
        {
          "key": "piece",
          "label": "عدد",
          "grams": 1.2,
          "step": 1,
          "decimals": 0,
          "is_primary": true,
          "hint": "یک دانه بادام"
        },
        {
          "key": "gram",
          "label": "گرم",
          "grams": 1,
          "step": 1,
          "decimals": 0,
          "is_primary": false,
          "hint": "وعده ۲۳ عدد ≈ ۲۸ گرم"
        },
        {
          "key": "palm_protein",
          "label": "کف دست (پروتئین)",
          "grams": 30,
          "step": 1,
          "decimals": 0,
          "is_primary": false,
          "hint": "یک مشت بادام"
        }
      ]
    },
    "legacy_slug": "raw-almonds",
    "image_url": "https://images.unsplash.com/photo-1508747703725-e9c7ec525aa0?w=800&q=80",
    "aliases_en": [
      "Raw almonds",
      "Almonds"
    ],
    "related_slugs": [
      "روغن-زیتون",
      "گردو-خام",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "بادام خام از آجیل‌های پرمصرف در رژیم سالم است؛ ترکیب پروتئین، چربی غیراشباع و فیبر آن در کنترل اشتها و انرژی پایدار نقش دارد.",
    "substitutes": [
      {
        "slug": "روغن-زیتون",
        "ratio": 1.0
      },
      {
        "slug": "گردو-خام",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "ماهی-قزل‌آلای-گریل",
    "title": "ماهی قزل‌آلای گریل",
    "excerpt": "پروتئین، چربی و امگا۳ قزل‌آلای گریل در ۱۰۰ گرم — مرجع علمی تغذیه ورزشی.",
    "category": "پروتئین‌ها",
    "rank_math_title": "ماهی قزل‌آلای گریل | پروتئین، امگا۳ و کالری",
    "rank_math_description": "ماهی قزل‌آلای گریل: ماکروها و امگا۳ در ۱۰۰ گرم. کاربرد در ریکاوری و سلامت قلب.",
    "rank_math_focus_keyword": "ماهی قزل‌آلای گریل",
    "name_app": "قزل‌آلای گریل",
    "other_names": "سالمون, Salmon Grilled, ماهی سالمون",
    "food_group": "پروتئین",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "palm_protein",
    "protein": "22",
    "calories": "206",
    "carbohydrates": "0",
    "fat": "12",
    "saturated_fat": "2.5",
    "fiber": "0",
    "sugar": "0",
    "cholesterol": "63",
    "sodium": "59",
    "potassium": "384",
    "glycemic_index": "0",
    "allergens": "ماهی",
    "short_description": "قزل‌آلا ترکیب عالی پروتئین و اسیدهای چرب امگا۳ برای التهاب کمتر و ریکاوری بهتر است.",
    "serving_notes": "گریل بدون روغن اضافه. یک فیله متوسط ≈ ۱۲۰ گرم.",
    "tip_1": "هفته‌ای ۲–۳ وعده ماهی چرب برای ورزشکاران توصیه می‌شود.",
    "tip_2": "با لیمو و سبزیجات فرنی پز دهید؛ سس مایونز اضافه نکنید.",
    "tip_3": "ماهی تازه یا منجمد با کیفیت یکسان لاگ می‌شود؛ روش پخت را یادداشت کنید.",
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
          "hint": "یک وعده ماهی"
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
    "legacy_slug": "grilled-salmon",
    "image_url": "https://images.unsplash.com/photo-1519708227418-c8fd9a32b2a2?w=800&q=80",
    "aliases_en": [
      "Grilled salmon",
      "Atlantic salmon"
    ],
    "related_slugs": [
      "سینه-مرغ-گریل-شده",
      "تخم‌مرغ-آب‌پز",
      "نان-سنگک-کامل"
    ],
    "intro": "قزل‌آلای گریل‌شده منبع پروتئین و اسیدهای چرب امگا۳ (EPA/DHA) است که در ادبیات التهاب، ریکاوری و سلامت قلب بررسی شده است.",
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
    "slug": "عدس-پخته",
    "title": "عدس پخته",
    "excerpt": "پروتئین، فیبر و کالری عدس پخته در ۱۰۰ گرم — مرجع علمی حبوبات در تغذیه ورزشی.",
    "category": "حبوبات",
    "rank_math_title": "عدس پخته | پروتئین گیاهی، کالری و فیبر",
    "rank_math_description": "عدس پخته: ماکروها، فیبر و GI در ۱۰۰ گرم. پروتئین گیاهی در برنامه بدنسازی.",
    "rank_math_focus_keyword": "عدس پخته",
    "name_app": "عدس پخته",
    "other_names": "عدس, Cooked Lentils, خوراک عدس",
    "food_group": "حبوبات",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "9",
    "calories": "116",
    "carbohydrates": "20",
    "fat": "0.4",
    "saturated_fat": "0.1",
    "fiber": "8",
    "sugar": "1.8",
    "cholesterol": "0",
    "sodium": "2",
    "potassium": "369",
    "glycemic_index": "32",
    "allergens": "",
    "short_description": "عدس پخته پروتئین گیاهی با فیبر بالا و شاخص گلیسمی پایین. جایگزین اقتصادی گوشت در بعضی وعده‌ها.",
    "serving_notes": "یک پیمانه عدس پخته ≈ ۲۰۰ گرم. بدون روغن و نمک زیاد.",
    "tip_1": "عدس را با برنج ترکیب کنید تا پروفایل آمینواسیدی کامل‌تر شود.",
    "tip_2": "برای هضم بهتر، کم‌جوش و با ادویه لذیذتر است.",
    "tip_3": "فیبر بالا آب کافی در روز می‌خواهد.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "cup",
      "units": [
        {
          "key": "cup",
          "label": "پیمانه / لیوان",
          "grams": 200,
          "step": 0.5,
          "decimals": 1,
          "is_primary": true,
          "hint": "عدس پخته"
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
    "legacy_slug": "cooked-lentils",
    "image_url": "https://images.unsplash.com/photo-1544378730-021ea69298f0?w=800&q=80",
    "aliases_en": [
      "Cooked lentils",
      "Lentils"
    ],
    "related_slugs": [
      "لوبیا-قرمز-پخته",
      "نخود-پخته",
      "نان-سنگک-کامل"
    ],
    "intro": "عدس پخته از حبوبات کم‌GI است و ترکیب پروتئین گیاهی و فیبر آن در تغذیه پایدار و رژیم‌های گیاهخواری ورزشی اهمیت دارد.",
    "substitutes": [
      {
        "slug": "لوبیا-قرمز-پخته",
        "ratio": 1.0
      },
      {
        "slug": "نخود-پخته",
        "ratio": 1.0
      }
    ]
  }
]
GYMAI_FOOD_BATCH1
        , true);
        return is_array($cache) ? $cache : array();
    }
}
