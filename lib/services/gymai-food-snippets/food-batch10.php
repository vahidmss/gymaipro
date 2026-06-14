// GymAI Foods — BATCH 10 (خوراکی 91–100)
// Code Snippets: Run everywhere | بدون تگ php
// یا کپی در: wp-content/gymai-seed/food-batch10.php

if (!function_exists('gymai_food_batch10_definitions')) {
    function gymai_food_batch10_definitions() {
        static $cache = null;
        if ($cache !== null) {
            return $cache;
        }
        $cache = json_decode(<<<'GYMAI_FOOD_BATCH10'
[
  {
    "slug": "زرده-تخم‌مرغ-پخته",
    "title": "زرده تخم‌مرغ پخته",
    "excerpt": "مرجع علمی زرده تخم‌مرغ پخته: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "پروتئین‌ها",
    "rank_math_title": "زرده تخم‌مرغ پخته | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای زرده تخم‌مرغ پخته در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "زرده تخم‌مرغ پخته",
    "name_app": "زرده تخم‌مرغ پخته",
    "other_names": "زرده, Egg yolk",
    "food_group": "پروتئین",
    "food_type": "solid",
    "meal_times": "صبحانه,ناهار",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "piece",
    "protein": "16",
    "calories": "322",
    "carbohydrates": "3.6",
    "fat": "27.0",
    "saturated_fat": "9.4",
    "fiber": "0",
    "sugar": "0.4",
    "cholesterol": "15",
    "sodium": "48",
    "potassium": "109",
    "glycemic_index": "0",
    "allergens": "تخم‌مرغ",
    "short_description": "زرده تخم‌مرغ چربی، ویتامین‌های محلول در چربی و کلسترول دارد؛ با سفیده تعادل بدهید.",
    "serving_notes": "ارزش‌ها برای زرده تخم‌مرغ پخته در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "۱–۲ زرده با چند سفیده برای اکثر افراد.",
    "tip_2": "در سس و سالاد مقدار کم.",
    "tip_3": "کلسترول رژیم را در کل روز ببینید.",
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
          "hint": "یک عدد بزرگ"
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
    "legacy_slug": "egg-yolk-boiled",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1498837167922-ddd27525b352?w=800&q=80",
    "aliases_en": [
      "Egg yolk boiled",
      "Boiled yolk"
    ],
    "related_slugs": [
      "سینه-مرغ-گریل-شده",
      "تخم‌مرغ-آب‌پز",
      "نان-سنگک-کامل"
    ],
    "intro": "زرده منبع lutein و کولین در تغذیه ورزشی است.",
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
    "slug": "تن-ماهی-کنسروی-در-آب",
    "title": "تن ماهی کنسروی در آب",
    "excerpt": "مرجع علمی تن ماهی کنسروی در آب: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "پروتئین‌ها",
    "rank_math_title": "تن ماهی کنسروی در آب | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای تن ماهی کنسروی در آب در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "تن ماهی کنسروی در آب",
    "name_app": "تن ماهی کنسروی در آب",
    "other_names": "تن ماهی, Tuna",
    "food_group": "پروتئین",
    "food_type": "solid",
    "meal_times": "ناهار,شام,میان‌وعده",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "palm_protein",
    "protein": "26",
    "calories": "116",
    "carbohydrates": "0",
    "fat": "0.8",
    "saturated_fat": "0.3",
    "fiber": "0",
    "sugar": "0",
    "cholesterol": "15",
    "sodium": "320",
    "potassium": "250",
    "glycemic_index": "0",
    "allergens": "ماهی",
    "short_description": "تن ماهی کنسروی در آب؛ پروتئین سریع و پرکاربرد در برنامه‌های مربیان.",
    "serving_notes": "ارزش‌ها برای تن ماهی کنسروی در آب در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "یک قوطی کوچک حدود ۱۲۰–۱۵۰ گرم ماهی drained.",
    "tip_2": "با نان یا برنج و سالاد ترکیب کنید.",
    "tip_3": "نسخه در آب کم‌چرب‌تر از روغن است.",
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
    "legacy_slug": "tilapia-cooked",
    "migrate_slugs": [
      "ماهی-تیلاپیا-پخته"
    ],
    "image_url": "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80",
    "aliases_en": [
      "Canned tuna in water",
      "Tuna can"
    ],
    "related_slugs": [
      "سینه-مرغ-گریل-شده",
      "تخم‌مرغ-آب‌پز",
      "نان-سنگک-کامل"
    ],
    "intro": "تن ماهی یکی از سریع‌ترین منابع پروتئین در برنامه غذایی ورزشی است.",
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
    "slug": "پودر-کازئین",
    "title": "پودر کازئین",
    "excerpt": "مرجع علمی پودر کازئین: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "پروتئین‌ها",
    "rank_math_title": "پودر کازئین | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای پودر کازئین در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "پودر کازئین",
    "name_app": "پودر کازئین",
    "other_names": "کازئین, Casein protein",
    "food_group": "پروتئین",
    "food_type": "solid",
    "meal_times": "قبل خواب,میان‌وعده",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "scoop",
    "protein": "75",
    "calories": "370",
    "carbohydrates": "6",
    "fat": "3.0",
    "saturated_fat": "1.0",
    "fiber": "0",
    "sugar": "0.7",
    "cholesterol": "15",
    "sodium": "180",
    "potassium": "280",
    "glycemic_index": "0",
    "allergens": "لبنیات",
    "short_description": "کازئین جذب آهسته دارد؛ برای شب یا فاصله طولانی بین وعده‌ها مناسب است.",
    "serving_notes": "ارزش‌ها برای پودر کازئین در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "۳۰ گرم با آب یا شیر.",
    "tip_2": "مکمل جایگزین غذا نیست.",
    "tip_3": "بعد وی برای MPS شبانه.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "scoop",
      "units": [
        {
          "key": "scoop",
          "label": "اسکوپ",
          "grams": 30,
          "step": 0.5,
          "decimals": 1,
          "is_primary": true,
          "hint": "حدود ۳۰ گرم پودر"
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
    "legacy_slug": "casein-protein-powder",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80",
    "aliases_en": [
      "Casein protein powder",
      "Casein"
    ],
    "related_slugs": [
      "سینه-مرغ-گریل-شده",
      "تخم‌مرغ-آب‌پز",
      "نان-سنگک-کامل"
    ],
    "intro": "کازئین در مطالعات overnight protein synthesis بررسی شده.",
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
    "slug": "مغز-تخمه-کدو",
    "title": "مغز تخمه کدو",
    "excerpt": "مرجع علمی مغز تخمه کدو: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "چربی‌های سالم",
    "rank_math_title": "مغز تخمه کدو | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای مغز تخمه کدو در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "مغز تخمه کدو",
    "name_app": "مغز تخمه کدو",
    "other_names": "تخمه کدو, Pumpkin seeds",
    "food_group": "چربی",
    "food_type": "solid",
    "meal_times": "میان‌وعده,صبحانه",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "gram",
    "protein": "30",
    "calories": "559",
    "carbohydrates": "11",
    "fat": "49.0",
    "saturated_fat": "17.1",
    "fiber": "6",
    "sugar": "1.3",
    "cholesterol": "0",
    "sodium": "7",
    "potassium": "809",
    "glycemic_index": "25",
    "allergens": "",
    "short_description": "تخمه کدو پروتئین، منیزium و روی دارد؛ میان‌وعده مغذی.",
    "serving_notes": "ارزش‌ها برای مغز تخمه کدو در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "وعده ۲۵–۳۰ گرم.",
    "tip_2": "روی سالاد یا ماست.",
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
    "legacy_slug": "pumpkin-seeds",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800&q=80",
    "aliases_en": [
      "Pumpkin seeds",
      "Pepitas"
    ],
    "related_slugs": [
      "روغن-زیتون",
      "بادام-خام",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "روی برای testosterone و immunity مطرح است.",
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
    "slug": "انجیر-خشک",
    "title": "انجیر خشک",
    "excerpt": "مرجع علمی انجیر خشک: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "میوه‌ها",
    "rank_math_title": "انجیر خشک | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای انجیر خشک در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "انجیر خشک",
    "name_app": "انجیر خشک",
    "other_names": "انجیر خشک, Dried figs",
    "food_group": "میوه",
    "food_type": "solid",
    "meal_times": "میان‌وعده,قبل تمرین",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "piece",
    "protein": "3.3",
    "calories": "249",
    "carbohydrates": "64",
    "fat": "0.9",
    "saturated_fat": "0.3",
    "fiber": "9.8",
    "sugar": "7.7",
    "cholesterol": "0",
    "sodium": "10",
    "potassium": "680",
    "glycemic_index": "61",
    "allergens": "",
    "short_description": "انجیر خشک فیبر و قند طبیعی فشرده؛ انرژی قبل تمرین با حجم کم.",
    "serving_notes": "ارزش‌ها برای انجیر خشک در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "۲–۳ عدد کافی است.",
    "tip_2": "با مغزها.",
    "tip_3": "آب کافی بنوشید.",
    "substitutes_json": [],
    "serving_units": {
      "default_unit": "piece",
      "units": [
        {
          "key": "piece",
          "label": "یک عدد",
          "grams": 10,
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
    "legacy_slug": "dried-figs",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80",
    "aliases_en": [
      "Dried figs",
      "Dry figs"
    ],
    "related_slugs": [
      "موز",
      "سیب",
      "ماست-یونانی-کم‌چرب"
    ],
    "intro": "انجیر منبع کلسیum گیاهی است.",
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
    "slug": "زیتون-سیاه",
    "title": "زیتون سیاه",
    "excerpt": "مرجع علمی زیتون سیاه: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "چربی‌های سالم",
    "rank_math_title": "زیتون سیاه | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای زیتون سیاه در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "زیتون سیاه",
    "name_app": "زیتون سیاه",
    "other_names": "زیتون, Olives",
    "food_group": "چربی",
    "food_type": "solid",
    "meal_times": "ناهار,شام,میان‌وعده",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "0.8",
    "calories": "115",
    "carbohydrates": "6",
    "fat": "11.0",
    "saturated_fat": "3.8",
    "fiber": "3.2",
    "sugar": "0.7",
    "cholesterol": "0",
    "sodium": "735",
    "potassium": "8",
    "glycemic_index": "15",
    "allergens": "",
    "short_description": "زیتون چربی MUFA و آنتی‌اکسیدant دارد؛ سدیم بالا.",
    "serving_notes": "ارزش‌ها برای زیتون سیاه در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "۵–۸ عدد.",
    "tip_2": "در سالاد.",
    "tip_3": "سدیم روز را کنترل کنید.",
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
    "legacy_slug": "black-olives",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1482049016688-a7bd8fa7e6a1?w=800&q=80",
    "aliases_en": [
      "Black olives",
      "Olives"
    ],
    "related_slugs": [
      "روغن-زیتون",
      "بادام-خام",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "زیتون در رژیم مدیترانه‌ای.",
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
    "slug": "سبزی-خوردن",
    "title": "سبزی خوردن",
    "excerpt": "مرجع علمی سبزی خوردن: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "سبزیجات",
    "rank_math_title": "سبزی خوردن | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای سبزی خوردن در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "سبزی خوردن",
    "name_app": "سبزی خوردن",
    "other_names": "سبزی, Fresh herbs",
    "food_group": "سبزیجات",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "2.5",
    "calories": "32",
    "carbohydrates": "5",
    "fat": "0.5",
    "saturated_fat": "0.2",
    "fiber": "2.8",
    "sugar": "0.6",
    "cholesterol": "0",
    "sodium": "45",
    "potassium": "320",
    "glycemic_index": "15",
    "allergens": "",
    "short_description": "سبزی خوردن تره، شوید، ریحان؛ ویتامین و آنتی‌اکسیدant با کالری ناچیز.",
    "serving_notes": "ارزش‌ها برای سبزی خوردن در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "با نان و پنیر.",
    "tip_2": "تازه.",
    "tip_3": "کنار کباب.",
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
    "legacy_slug": "fresh-herbs-plate",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800&q=80",
    "aliases_en": [
      "Fresh herbs plate",
      "Sabzi khordan"
    ],
    "related_slugs": [
      "خیار",
      "گوجه‌فرنگی",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "سبزیجات خام polyphenols.",
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
    "slug": "قارچ-پخته",
    "title": "قارچ پخته",
    "excerpt": "مرجع علمی قارچ پخته: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "سبزیجات",
    "rank_math_title": "قارچ پخته | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای قارچ پخته در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "قارچ پخته",
    "name_app": "قارچ پخته",
    "other_names": "قارچ, Mushrooms",
    "food_group": "سبزیجات",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "3.6",
    "calories": "28",
    "carbohydrates": "3.3",
    "fat": "0.4",
    "saturated_fat": "0.1",
    "fiber": "1",
    "sugar": "0.4",
    "cholesterol": "0",
    "sodium": "6",
    "potassium": "318",
    "glycemic_index": "15",
    "allergens": "",
    "short_description": "قارچ پروتئین گیاهی و ویتامین D (با نور UV) دارد.",
    "serving_notes": "ارزش‌ها برای قارچ پخته در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "تفت با سیر.",
    "tip_2": "در خوراک لوبیا.",
    "tip_3": "کم‌کالری.",
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
    "legacy_slug": "mushrooms-cooked",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1511690743698-d9d85f2fbf38?w=800&q=80",
    "aliases_en": [
      "Mushrooms cooked",
      "Button mushrooms"
    ],
    "related_slugs": [
      "خیار",
      "گوجه‌فرنگی",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "قارچ umami برای طعم غذا.",
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
    "slug": "کلم-بروکسل-پخته",
    "title": "کلم بروکسل پخته",
    "excerpt": "مرجع علمی کلم بروکسل پخته: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "سبزیجات",
    "rank_math_title": "کلم بروکسل پخته | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای کلم بروکسل پخته در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "کلم بروکسل پخته",
    "name_app": "کلم بروکسل پخته",
    "other_names": "کلم بروکسل, Brussels sprouts",
    "food_group": "سبزیجات",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "2.6",
    "calories": "36",
    "carbohydrates": "7",
    "fat": "0.5",
    "saturated_fat": "0.2",
    "fiber": "2.6",
    "sugar": "0.8",
    "cholesterol": "0",
    "sodium": "22",
    "potassium": "317",
    "glycemic_index": "15",
    "allergens": "",
    "short_description": "کلم بروکسل جزو سبزیجات چلیپایی و سرشار از فیبر است.",
    "serving_notes": "ارزش‌ها برای کلم بروکسل پخته در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "بخارپز یا فر.",
    "tip_2": "نیم پیمانه.",
    "tip_3": "با سینه مرغ.",
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
    "legacy_slug": "brussels-sprouts-cooked",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1473093295045-ddd4c915dc20?w=800&q=80",
    "aliases_en": [
      "Brussels sprouts cooked",
      "Brussels sprouts"
    ],
    "related_slugs": [
      "خیار",
      "گوجه‌فرنگی",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "سبزیجات چلیپایی در رژیم ضدالتهاب مطرح‌اند.",
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
    "slug": "ماست-پروبیوتیک-ساده",
    "title": "ماست پروبیوتیک ساده",
    "excerpt": "مرجع علمی ماست پروبیوتیک ساده: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "لبنیات",
    "rank_math_title": "ماست پروبیوتیک ساده | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای ماست پروبیوتیک ساده در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "ماست پروبیوتیک ساده",
    "name_app": "ماست پروبیوتیک ساده",
    "other_names": "ماست ساده, Plain yogurt",
    "food_group": "لبنیات",
    "food_type": "solid",
    "meal_times": "صبحانه,میان‌وعده",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "3.5",
    "calories": "61",
    "carbohydrates": "4.7",
    "fat": "3.3",
    "saturated_fat": "1.2",
    "fiber": "0",
    "sugar": "0.6",
    "cholesterol": "15",
    "sodium": "46",
    "potassium": "155",
    "glycemic_index": "35",
    "allergens": "لبنیات",
    "short_description": "ماست پروbiotic پروتئین و باکteria مفید؛ پایه صبحانه ایرانی.",
    "serving_notes": "ارزش‌ها برای ماست پروبیوتیک ساده در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "بدون شکر.",
    "tip_2": "با عسل کم.",
    "tip_3": "با میوه.",
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
    "legacy_slug": "plain-probiotic-yogurt",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1455619452474-d2be8b1e70cb?w=800&q=80",
    "aliases_en": [
      "Plain probiotic yogurt",
      "Yogurt"
    ],
    "related_slugs": [
      "ماست-یونانی-کم‌چرب",
      "پنیر-سفید-کم‌چرب",
      "نان-سنگک-کامل"
    ],
    "intro": "probiotic برای gut health.",
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
  }
]
GYMAI_FOOD_BATCH10
        , true);
        return is_array($cache) ? $cache : array();
    }
}
