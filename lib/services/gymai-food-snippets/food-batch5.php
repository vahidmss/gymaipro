// GymAI Foods — BATCH 5 (خوراکی 41–50)
// Code Snippets: Run everywhere | بدون تگ php
// یا کپی در: wp-content/gymai-seed/food-batch5.php

if (!function_exists('gymai_food_batch5_definitions')) {
    function gymai_food_batch5_definitions() {
        static $cache = null;
        if ($cache !== null) {
            return $cache;
        }
        $cache = json_decode(<<<'GYMAI_FOOD_BATCH5'
[
  {
    "slug": "موز",
    "title": "موز",
    "excerpt": "مرجع علمی موز: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "میوه‌ها",
    "rank_math_title": "موز | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای موز در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "موز",
    "name_app": "موز",
    "other_names": "موز, Banana",
    "food_group": "میوه",
    "food_type": "solid",
    "meal_times": "صبحانه,قبل تمرین,بعد تمرین",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "piece",
    "protein": "1.1",
    "calories": "89",
    "carbohydrates": "23",
    "fat": "0.3",
    "saturated_fat": "0.1",
    "fiber": "2.6",
    "sugar": "2.8",
    "cholesterol": "0",
    "sodium": "1",
    "potassium": "358",
    "glycemic_index": "51",
    "allergens": "",
    "short_description": "موز پتاسیم و کربوهیدرات سریع دارد؛ قبل و بعد تمرین کلاسیک است.",
    "serving_notes": "ارزش‌ها برای موز در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "رسیده GI بالاتر؛ کمی سبز برای GI پایین‌تر.",
    "tip_2": "با کره بادام یا شیر.",
    "tip_3": "یک عدد متوسط ~۱۲۰ گرم.",
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
    "legacy_slug": "banana",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1498837167922-ddd27525b352?w=800&q=80",
    "aliases_en": [
      "Banana",
      "Ripe banana"
    ],
    "related_slugs": [
      "سیب",
      "پرتقال",
      "ماست-یونانی-کم‌چرب"
    ],
    "intro": "موز در تغذیه ورزشی برای جلوگیری از گرفتگی عضلانی مطرح است.",
    "substitutes": [
      {
        "slug": "سیب",
        "ratio": 1.0
      },
      {
        "slug": "پرتقال",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "سیب",
    "title": "سیب",
    "excerpt": "مرجع علمی سیب: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "میوه‌ها",
    "rank_math_title": "سیب | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای سیب در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "سیب",
    "name_app": "سیب",
    "other_names": "سیب, Apple",
    "food_group": "میوه",
    "food_type": "solid",
    "meal_times": "میان‌وعده,صبحانه",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "piece",
    "protein": "0.3",
    "calories": "52",
    "carbohydrates": "14",
    "fat": "0.2",
    "saturated_fat": "0.1",
    "fiber": "2.4",
    "sugar": "1.7",
    "cholesterol": "0",
    "sodium": "1",
    "potassium": "107",
    "glycemic_index": "36",
    "allergens": "",
    "short_description": "سیب فیبر pectin و GI پایین؛ میان‌وعده سیری‌بخش.",
    "serving_notes": "ارزش‌ها برای سیب در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "با پوست فیبر بیشتر.",
    "tip_2": "با کره بادام پروتئین اضافه.",
    "tip_3": "یک عدد متوسط.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "piece",
      "units": [
        {
          "key": "piece",
          "label": "عدد متوسط",
          "grams": 180,
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
    "legacy_slug": "apple",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80",
    "aliases_en": [
      "Apple",
      "Fresh apple"
    ],
    "related_slugs": [
      "موز",
      "پرتقال",
      "ماست-یونانی-کم‌چرب"
    ],
    "intro": "سیب در مطالعات satiety و قند خون مثبت است.",
    "substitutes": [
      {
        "slug": "موز",
        "ratio": 1.0
      },
      {
        "slug": "پرتقال",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "پرتقال",
    "title": "پرتقال",
    "excerpt": "مرجع علمی پرتقال: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "میوه‌ها",
    "rank_math_title": "پرتقال | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای پرتقال در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "پرتقال",
    "name_app": "پرتقال",
    "other_names": "پرتقال, Orange",
    "food_group": "میوه",
    "food_type": "solid",
    "meal_times": "میان‌وعده,صبحانه",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "piece",
    "protein": "0.9",
    "calories": "47",
    "carbohydrates": "12",
    "fat": "0.1",
    "saturated_fat": "0.0",
    "fiber": "2.4",
    "sugar": "1.4",
    "cholesterol": "0",
    "sodium": "0",
    "potassium": "181",
    "glycemic_index": "43",
    "allergens": "",
    "short_description": "پرتقال ویتامین C و کربوهیدرات طبیعی؛ ریکاوری آنتی‌اکسیدant.",
    "serving_notes": "ارزش‌ها برای پرتقال در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "تازه بهتر از آب صنعتی.",
    "tip_2": "با پروتئین میان‌وعده.",
    "tip_3": "یک عدد متوسط.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "piece",
      "units": [
        {
          "key": "piece",
          "label": "عدد متوسط",
          "grams": 130,
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
    "legacy_slug": "orange",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80",
    "aliases_en": [
      "Orange",
      "Fresh orange"
    ],
    "related_slugs": [
      "موز",
      "سیب",
      "ماست-یونانی-کم‌چرب"
    ],
    "intro": "ویتامین C در ریکاوری ورزشی نقش دارد.",
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
    "slug": "انگور",
    "title": "انگور",
    "excerpt": "مرجع علمی انگور: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "میوه‌ها",
    "rank_math_title": "انگور | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای انگور در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "انگور",
    "name_app": "انگور",
    "other_names": "انگور, Grapes",
    "food_group": "میوه",
    "food_type": "solid",
    "meal_times": "میان‌وعده",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "piece",
    "protein": "0.7",
    "calories": "69",
    "carbohydrates": "18",
    "fat": "0.2",
    "saturated_fat": "0.1",
    "fiber": "0.9",
    "sugar": "2.2",
    "cholesterol": "0",
    "sodium": "2",
    "potassium": "191",
    "glycemic_index": "59",
    "allergens": "",
    "short_description": "انگور قند طبیعی و resveratrol دارد؛ وعده کوچک برای کالری.",
    "serving_notes": "ارزش‌ها برای انگور در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "یک خوشه کوچک میان‌وعده.",
    "tip_2": "با پنیر تعادل.",
    "tip_3": "فریز شده dessert سالم.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "piece",
      "units": [
        {
          "key": "piece",
          "label": "خوشه کوچک",
          "grams": 150,
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
    "legacy_slug": "grapes",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800&q=80",
    "aliases_en": [
      "Grapes",
      "Fresh grapes"
    ],
    "related_slugs": [
      "موز",
      "سیب",
      "ماست-یونانی-کم‌چرب"
    ],
    "intro": "انگور انرژی سریع قبل تمرین سبک.",
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
    "slug": "خرما",
    "title": "خرما",
    "excerpt": "مرجع علمی خرما: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "میوه‌ها",
    "rank_math_title": "خرما | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای خرما در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "خرما",
    "name_app": "خرما",
    "other_names": "خرما, Dates",
    "food_group": "میوه",
    "food_type": "solid",
    "meal_times": "میان‌وعده,قبل تمرین",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "piece",
    "protein": "2.5",
    "calories": "282",
    "carbohydrates": "75",
    "fat": "0.4",
    "saturated_fat": "0.1",
    "fiber": "8",
    "sugar": "9.0",
    "cholesterol": "0",
    "sodium": "1",
    "potassium": "656",
    "glycemic_index": "42",
    "allergens": "",
    "short_description": "خرما قند طبیعی و پتاسیم بالا؛ انرژی فشرده قبل تمرین.",
    "serving_notes": "ارزش‌ها برای خرما در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "۱–۲ عدد کافی است.",
    "tip_2": "با مغزها تعادل چربی.",
    "tip_3": "در شیرینی طبیعی.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "piece",
      "units": [
        {
          "key": "piece",
          "label": "یک عدد",
          "grams": 15,
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
    "legacy_slug": "dates",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80",
    "aliases_en": [
      "Dates",
      "Medjool dates"
    ],
    "related_slugs": [
      "موز",
      "سیب",
      "ماست-یونانی-کم‌چرب"
    ],
    "intro": "خرما منبع انرژی سنتی در ورزش.",
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
    "slug": "انار",
    "title": "انار",
    "excerpt": "مرجع علمی انار: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "میوه‌ها",
    "rank_math_title": "انار | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای انار در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "انار",
    "name_app": "انار",
    "other_names": "انار, Pomegranate",
    "food_group": "میوه",
    "food_type": "solid",
    "meal_times": "میان‌وعده,دسر",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "piece",
    "protein": "1.7",
    "calories": "83",
    "carbohydrates": "19",
    "fat": "1.2",
    "saturated_fat": "0.4",
    "fiber": "4",
    "sugar": "2.3",
    "cholesterol": "0",
    "sodium": "3",
    "potassium": "236",
    "glycemic_index": "35",
    "allergens": "",
    "short_description": "انار آنتی‌اکسیدant polyphenols دارد؛ GI نسبتاً پایین.",
    "serving_notes": "ارزش‌ها برای انار در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "دانه تازه بهتر از آب.",
    "tip_2": "روی ماست.",
    "tip_3": "فصل پاییز.",
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
    "legacy_slug": "pomegranate",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1482049016688-a7bd8fa7e6a1?w=800&q=80",
    "aliases_en": [
      "Pomegranate",
      "Pomegranate seeds"
    ],
    "related_slugs": [
      "موز",
      "سیب",
      "ماست-یونانی-کم‌چرب"
    ],
    "intro": "انار در مطالعات التهاب مورد توجه است.",
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
    "slug": "کیوی",
    "title": "کیوی",
    "excerpt": "مرجع علمی کیوی: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "میوه‌ها",
    "rank_math_title": "کیوی | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای کیوی در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "کیوی",
    "name_app": "کیوی",
    "other_names": "کیوی, Kiwi",
    "food_group": "میوه",
    "food_type": "solid",
    "meal_times": "میان‌وعده,صبحانه",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "piece",
    "protein": "1.1",
    "calories": "61",
    "carbohydrates": "15",
    "fat": "0.5",
    "saturated_fat": "0.2",
    "fiber": "3",
    "sugar": "1.8",
    "cholesterol": "0",
    "sodium": "3",
    "potassium": "312",
    "glycemic_index": "50",
    "allergens": "",
    "short_description": "کیوی ویتامین C بسیار بالا و فیبر دارد.",
    "serving_notes": "ارزش‌ها برای کیوی در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "با پوست فیبر بیشتر (اگر تمیز).",
    "tip_2": "در اسموتی.",
    "tip_3": "دو عدد کوچک.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "piece",
      "units": [
        {
          "key": "piece",
          "label": "یک عدد",
          "grams": 75,
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
    "legacy_slug": "kiwi",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800&q=80",
    "aliases_en": [
      "Kiwi",
      "Kiwifruit"
    ],
    "related_slugs": [
      "موز",
      "سیب",
      "ماست-یونانی-کم‌چرب"
    ],
    "intro": "ویتامین C برای collagen و ریکاوری.",
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
    "slug": "هلو",
    "title": "هلو",
    "excerpt": "مرجع علمی هلو: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "میوه‌ها",
    "rank_math_title": "هلو | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای هلو در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "هلو",
    "name_app": "هلو",
    "other_names": "هلو, Peach",
    "food_group": "میوه",
    "food_type": "solid",
    "meal_times": "میان‌وعده",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "piece",
    "protein": "0.9",
    "calories": "39",
    "carbohydrates": "10",
    "fat": "0.3",
    "saturated_fat": "0.1",
    "fiber": "1.5",
    "sugar": "1.2",
    "cholesterol": "0",
    "sodium": "0",
    "potassium": "190",
    "glycemic_index": "42",
    "allergens": "",
    "short_description": "هلو کم‌کالری و ویتامین A؛ میان‌وعده تابستانی.",
    "serving_notes": "ارزش‌ها برای هلو در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "تازه یا منجمد.",
    "tip_2": "با ماست.",
    "tip_3": "یک عدد متوسط.",
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
    "legacy_slug": "peach",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1511690743698-d9d85f2fbf38?w=800&q=80",
    "aliases_en": [
      "Peach",
      "Fresh peach"
    ],
    "related_slugs": [
      "موز",
      "سیب",
      "ماست-یونانی-کم‌چرب"
    ],
    "intro": "میوه فصل تنوع آنتی‌اکسیدant.",
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
    "slug": "توت‌فرنگی",
    "title": "توت‌فرنگی",
    "excerpt": "مرجع علمی توت‌فرنگی: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "میوه‌ها",
    "rank_math_title": "توت‌فرنگی | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای توت‌فرنگی در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "توت‌فرنگی",
    "name_app": "توت‌فرنگی",
    "other_names": "توت‌فرنگی, Strawberries",
    "food_group": "میوه",
    "food_type": "solid",
    "meal_times": "میان‌وعده,صبحانه",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "0.7",
    "calories": "32",
    "carbohydrates": "8",
    "fat": "0.3",
    "saturated_fat": "0.1",
    "fiber": "2",
    "sugar": "1.0",
    "cholesterol": "0",
    "sodium": "1",
    "potassium": "153",
    "glycemic_index": "40",
    "allergens": "",
    "short_description": "توت‌فرنگی کم‌کالری و ویتامین C؛ GI پایین.",
    "serving_notes": "ارزش‌ها برای توت‌فرنگی در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "روی جو دوسر.",
    "tip_2": "منجمد در اسموتی.",
    "tip_3": "یک پیمانه.",
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
    "legacy_slug": "strawberries",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1473093295045-ddd4c915dc20?w=800&q=80",
    "aliases_en": [
      "Strawberries",
      "Fresh strawberries"
    ],
    "related_slugs": [
      "موز",
      "سیب",
      "ماست-یونانی-کم‌چرب"
    ],
    "intro": "berries در رژیم آنتی‌اکسیدant محبوب‌اند.",
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
    "slug": "هندوانه",
    "title": "هندوانه",
    "excerpt": "مرجع علمی هندوانه: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "میوه‌ها",
    "rank_math_title": "هندوانه | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای هندوانه در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "هندوانه",
    "name_app": "هندوانه",
    "other_names": "هندوانه, Watermelon",
    "food_group": "میوه",
    "food_type": "solid",
    "meal_times": "میان‌وعده,بعد تمرین",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "piece",
    "protein": "0.6",
    "calories": "30",
    "carbohydrates": "8",
    "fat": "0.2",
    "saturated_fat": "0.1",
    "fiber": "0.4",
    "sugar": "1.0",
    "cholesterol": "0",
    "sodium": "1",
    "potassium": "112",
    "glycemic_index": "72",
    "allergens": "",
    "short_description": "هندوانه آب و l-citrulline دارد؛ hydration بعد تمرین.",
    "serving_notes": "ارزش‌ها برای هندوانه در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "GI بالا اما بار glycemic پایین.",
    "tip_2": "بعد تمرین تابستان.",
    "tip_3": "یک برش متوسط.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "piece",
      "units": [
        {
          "key": "piece",
          "label": "برش متوسط",
          "grams": 250,
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
    "legacy_slug": "watermelon",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1455619452474-d2be8b1e70cb?w=800&q=80",
    "aliases_en": [
      "Watermelon",
      "Fresh watermelon"
    ],
    "related_slugs": [
      "موز",
      "سیب",
      "ماست-یونانی-کم‌چرب"
    ],
    "intro": "هندوانه برای hydration طبیعی است.",
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
GYMAI_FOOD_BATCH5
        , true);
        return is_array($cache) ? $cache : array();
    }
}
