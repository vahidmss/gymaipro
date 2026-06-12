// GymAI Foods — BATCH 14 (خوراکی 131–140)
// Code Snippets: Run everywhere | بدون تگ php
// یا کپی در: wp-content/gymai-seed/food-batch14.php

if (!function_exists('gymai_food_batch14_definitions')) {
    function gymai_food_batch14_definitions() {
        static $cache = null;
        if ($cache !== null) {
            return $cache;
        }
        $cache = json_decode(<<<'GYMAI_FOOD_BATCH14'
[
  {
    "slug": "پودر-کراتین-مونوهیدرات",
    "title": "پودر کراتین مونوهیدرات",
    "excerpt": "مرجع علمی پودر کراتین مونوهیدرات: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "مکمل‌ها",
    "rank_math_title": "پودر کراتین مونوهیدرات | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای پودر کراتین مونوهیدرات در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "پودر کراتین مونوهیدرات",
    "name_app": "پودر کراتین مونوهیدرات",
    "other_names": "کراتین, Creatine",
    "food_group": "مکمل",
    "food_type": "solid",
    "meal_times": "هر زمان",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "scoop",
    "protein": "0",
    "calories": "0",
    "carbohydrates": "0",
    "fat": "0.0",
    "saturated_fat": "0.0",
    "fiber": "0",
    "sugar": "0",
    "cholesterol": "0",
    "sodium": "0",
    "potassium": "0",
    "glycemic_index": "0",
    "allergens": "",
    "short_description": "کراتین برای قدرت و حجم عضلانی؛ ۳–۵ گرم روزانه.",
    "serving_notes": "ارزش‌ها برای پودر کراتین مونوهیدرات در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "با آب یا شیک پروتئین.",
    "tip_2": "روزانه ثابت مهم‌تر از زمان‌بندی است.",
    "tip_3": "آب کافی بنوشید.",
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
    "legacy_slug": "creatine-monohydrate",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1498837167922-ddd27525b352?w=800&q=80",
    "aliases_en": [
      "Creatine monohydrate",
      "Creatine"
    ],
    "related_slugs": [
      "پودر-وی-پروتئین",
      "پروتئین-بار",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "کراتین پرتحقیق‌ترین مکمل قدرتی است.",
    "substitutes": [
      {
        "slug": "پودر-وی-پروتئین",
        "ratio": 1.0
      },
      {
        "slug": "پروتئین-بار",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "گینر-پودری",
    "title": "گینر پودری",
    "excerpt": "مرجع علمی گینر پودری: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "مکمل‌ها",
    "rank_math_title": "گینر پودری | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای گینر پودری در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "گینر پودری",
    "name_app": "گینر پودری",
    "other_names": "گینر, Mass gainer",
    "food_group": "مکمل",
    "food_type": "solid",
    "meal_times": "بعد تمرین,میان‌وعده",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "scoop",
    "protein": "15",
    "calories": "380",
    "carbohydrates": "60",
    "fat": "5.0",
    "saturated_fat": "1.8",
    "fiber": "2",
    "sugar": "7.2",
    "cholesterol": "0",
    "sodium": "200",
    "potassium": "300",
    "glycemic_index": "0",
    "allergens": "لبنیات, گلوتن",
    "short_description": "گینر کالری و کربو بالا برای سخت‌افزاری‌ها.",
    "serving_notes": "ارزش‌ها برای گینر پودری در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "فقط در مازاد کالری.",
    "tip_2": "جایگزین وعده کامل نشود.",
    "tip_3": "بعد تمرین یا بین وعده.",
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
    "legacy_slug": "mass-gainer",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80",
    "aliases_en": [
      "Mass gainer",
      "Weight gainer"
    ],
    "related_slugs": [
      "پودر-وی-پروتئین",
      "پروتئین-بار",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "گینر برای افزایش وزن سریع طراحی شده است.",
    "substitutes": [
      {
        "slug": "پودر-وی-پروتئین",
        "ratio": 1.0
      },
      {
        "slug": "پروتئین-بار",
        "ratio": 1.0
      }
    ]
  },
  {
    "slug": "لوبیا-سبز-پخته",
    "title": "لوبیا سبز پخته",
    "excerpt": "مرجع علمی لوبیا سبز پخته: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "سبزیجات",
    "rank_math_title": "لوبیا سبز پخته | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای لوبیا سبز پخته در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "لوبیا سبز پخته",
    "name_app": "لوبیا سبز پخته",
    "other_names": "لوبیا سبز, Green beans",
    "food_group": "سبزیجات",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "1.9",
    "calories": "35",
    "carbohydrates": "7",
    "fat": "0.2",
    "saturated_fat": "0.1",
    "fiber": "3.4",
    "sugar": "0.8",
    "cholesterol": "0",
    "sodium": "6",
    "potassium": "209",
    "glycemic_index": "15",
    "allergens": "",
    "short_description": "لوبیا سبز فیبر و حجم غذایی کم‌کالری.",
    "serving_notes": "ارزش‌ها برای لوبیا سبز پخته در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "بخارپز یا آب‌پز.",
    "tip_2": "کنار پروتئین اصلی.",
    "tip_3": "یک پیمانه ۱۰۰ گرم.",
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
    "legacy_slug": "green-beans-cooked",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80",
    "aliases_en": [
      "Green beans cooked",
      "String beans"
    ],
    "related_slugs": [
      "خیار",
      "گوجه‌فرنگی",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "سبزیجات کم‌کالری سبد رژیم را پر می‌کنند.",
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
    "slug": "نخود-فرنگی",
    "title": "نخود فرنگی",
    "excerpt": "مرجع علمی نخود فرنگی: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "سبزیجات",
    "rank_math_title": "نخود فرنگی | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای نخود فرنگی در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "نخود فرنگی",
    "name_app": "نخود فرنگی",
    "other_names": "نخود فرنگی, Peas",
    "food_group": "سبزیجات",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "5.4",
    "calories": "81",
    "carbohydrates": "14",
    "fat": "0.4",
    "saturated_fat": "0.1",
    "fiber": "5.7",
    "sugar": "1.7",
    "cholesterol": "0",
    "sodium": "5",
    "potassium": "244",
    "glycemic_index": "22",
    "allergens": "",
    "short_description": "نخود فرنگی پروتئین گیاهی و فیبر.",
    "serving_notes": "ارزش‌ها برای نخود فرنگی در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "منجمد یا تازه.",
    "tip_2": "با برنج یا ماکارونی.",
    "tip_3": "یک پیمانه ۱۰۰ گرم.",
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
    "legacy_slug": "green-peas",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800&q=80",
    "aliases_en": [
      "Green peas",
      "Peas"
    ],
    "related_slugs": [
      "خیار",
      "گوجه‌فرنگی",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "نخود فرنگی سبزی-پروتئین دوگانه است.",
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
    "slug": "کدو-حلوایی-پخته",
    "title": "کدو حلوایی پخته",
    "excerpt": "مرجع علمی کدو حلوایی پخته: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "کربوهیدرات‌ها",
    "rank_math_title": "کدو حلوایی پخته | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای کدو حلوایی پخته در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "کدو حلوایی پخته",
    "name_app": "کدو حلوایی پخته",
    "other_names": "کدو حلوایی, Pumpkin",
    "food_group": "کربوهیدرات",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "1",
    "calories": "45",
    "carbohydrates": "12",
    "fat": "0.1",
    "saturated_fat": "0.0",
    "fiber": "2",
    "sugar": "1.4",
    "cholesterol": "0",
    "sodium": "4",
    "potassium": "230",
    "glycemic_index": "75",
    "allergens": "",
    "short_description": "کدو حلوایی کربو و بتاکاروتن؛ غذای پاییزی.",
    "serving_notes": "ارزش‌ها برای کدو حلوایی پخته در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "پخته یا تنوری.",
    "tip_2": "با مرغ یا گوشت.",
    "tip_3": "یک پیمانه ۱۵۰ گرم.",
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
    "legacy_slug": "pumpkin-cooked",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80",
    "aliases_en": [
      "Pumpkin cooked",
      "Squash"
    ],
    "related_slugs": [
      "نان-سنگک-کامل",
      "برنج-سفید-پخته",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "کدو حلوایی کربوهیدرات سبک است.",
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
    "slug": "کلم-سفید-خام",
    "title": "کلم سفید خام",
    "excerpt": "مرجع علمی کلم سفید خام: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "سبزیجات",
    "rank_math_title": "کلم سفید خام | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای کلم سفید خام در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "کلم سفید خام",
    "name_app": "کلم سفید خام",
    "other_names": "کلم, Cabbage",
    "food_group": "سبزیجات",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "cup",
    "protein": "1.3",
    "calories": "25",
    "carbohydrates": "6",
    "fat": "0.1",
    "saturated_fat": "0.0",
    "fiber": "2.5",
    "sugar": "0.7",
    "cholesterol": "0",
    "sodium": "18",
    "potassium": "170",
    "glycemic_index": "10",
    "allergens": "",
    "short_description": "کلم سفید حجم غذایی و فیبر بسیار کم‌کالری.",
    "serving_notes": "ارزش‌ها برای کلم سفید خام در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "سالاد یا خورشت.",
    "tip_2": "با لیمو و نمک کم.",
    "tip_3": "برای سیری در کات.",
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
    "legacy_slug": "white-cabbage",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1482049016688-a7bd8fa7e6a1?w=800&q=80",
    "aliases_en": [
      "White cabbage",
      "Cabbage raw"
    ],
    "related_slugs": [
      "خیار",
      "گوجه‌فرنگی",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "کلم در رژیم کاهش وزن پرحجم است.",
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
    "slug": "کباب-تابه‌ای-مرغ",
    "title": "کباب تابه‌ای مرغ",
    "excerpt": "مرجع علمی کباب تابه‌ای مرغ: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "پروتئین‌ها",
    "rank_math_title": "کباب تابه‌ای مرغ | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای کباب تابه‌ای مرغ در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "کباب تابه‌ای مرغ",
    "name_app": "کباب تابه‌ای مرغ",
    "other_names": "کباب تابه‌ای, Pan kebab",
    "food_group": "پروتئین",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "palm_protein",
    "protein": "27",
    "calories": "175",
    "carbohydrates": "1",
    "fat": "6.0",
    "saturated_fat": "2.1",
    "fiber": "0",
    "sugar": "0.1",
    "cholesterol": "15",
    "sodium": "420",
    "potassium": "260",
    "glycemic_index": "0",
    "allergens": "",
    "short_description": "کباب تابه‌ای مرغ سریع؛ بدون برنج، با سالاد.",
    "serving_notes": "ارزش‌ها برای کباب تابه‌ای مرغ در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "روغن کم در تابه.",
    "tip_2": "۱۲۰–۱۵۰ گرم در وعده.",
    "tip_3": "با برنج جدا ترکیب کنید.",
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
    "legacy_slug": "pan-chicken-kebab",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800&q=80",
    "aliases_en": [
      "Pan chicken kebab",
      "Chicken patty"
    ],
    "related_slugs": [
      "سینه-مرغ-گریل-شده",
      "تخم‌مرغ-آب‌پز",
      "نان-سنگک-کامل"
    ],
    "intro": "کباب تابه‌ای غذای سریع خانگی است.",
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
    "slug": "کتف-مرغ-گریل",
    "title": "کتف مرغ گریل",
    "excerpt": "مرجع علمی کتف مرغ گریل: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "پروتئین‌ها",
    "rank_math_title": "کتف مرغ گریل | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای کتف مرغ گریل در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "کتف مرغ گریل",
    "name_app": "کتف مرغ گریل",
    "other_names": "کتف مرغ, Chicken wing",
    "food_group": "پروتئین",
    "food_type": "solid",
    "meal_times": "ناهار,شام",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "palm_protein",
    "protein": "22",
    "calories": "203",
    "carbohydrates": "0",
    "fat": "12.0",
    "saturated_fat": "4.2",
    "fiber": "0",
    "sugar": "0",
    "cholesterol": "15",
    "sodium": "75",
    "potassium": "210",
    "glycemic_index": "0",
    "allergens": "",
    "short_description": "کتف مرغ پروتئین با چربی بیشتر؛ در حجم معتدل.",
    "serving_notes": "ارزش‌ها برای کتف مرغ گریل در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "بدون سس پرچرب.",
    "tip_2": "۲–۳ کتف در وعده.",
    "tip_3": "پوست جدا شود.",
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
    "legacy_slug": "grilled-chicken-wing",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1511690743698-d9d85f2fbf38?w=800&q=80",
    "aliases_en": [
      "Grilled chicken wing",
      "Chicken wings"
    ],
    "related_slugs": [
      "سینه-مرغ-گریل-شده",
      "تخم‌مرغ-آب‌پز",
      "نان-سنگک-کامل"
    ],
    "intro": "کتف مرغ برای تنوع در رژیم حجم است.",
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
    "slug": "بادام-هندی-خام",
    "title": "بادام هندی خام",
    "excerpt": "مرجع علمی بادام هندی خام: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "چربی‌ها",
    "rank_math_title": "بادام هندی خام | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای بادام هندی خام در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "بادام هندی خام",
    "name_app": "بادام هندی خام",
    "other_names": "بادام هندی, Cashew",
    "food_group": "چربی",
    "food_type": "solid",
    "meal_times": "میان‌وعده",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "gram",
    "protein": "18",
    "calories": "553",
    "carbohydrates": "30",
    "fat": "44.0",
    "saturated_fat": "15.4",
    "fiber": "3.3",
    "sugar": "3.6",
    "cholesterol": "0",
    "sodium": "12",
    "potassium": "660",
    "glycemic_index": "25",
    "allergens": "آجیل",
    "short_description": "بادام هندی چربی و پروتئین؛ وعده ۲۵–۳۰ گرم.",
    "serving_notes": "ارزش‌ها برای بادام هندی خام در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "خام بدون نمک.",
    "tip_2": "در کات مقدار دقیق.",
    "tip_3": "با میوه خشک.",
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
    "legacy_slug": "cashew-raw",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1473093295045-ddd4c915dc20?w=800&q=80",
    "aliases_en": [
      "Cashew raw",
      "Cashews"
    ],
    "related_slugs": [
      "روغن-زیتون",
      "بادام-خام",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "آجیل منبع چربی سالم در میان‌وعده است.",
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
    "slug": "پودر-BCAA",
    "title": "پودر BCAA",
    "excerpt": "مرجع علمی پودر BCAA: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.",
    "category": "مکمل‌ها",
    "rank_math_title": "پودر BCAA | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم",
    "rank_math_description": "جدول تغذیه‌ای پودر BCAA در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.",
    "rank_math_focus_keyword": "پودر BCAA",
    "name_app": "پودر BCAA",
    "other_names": "BCAA, Amino acids",
    "food_group": "مکمل",
    "food_type": "solid",
    "meal_times": "حین تمرین,بعد تمرین",
    "nutrition_basis": "per_100g",
    "serving_size_grams": "100",
    "default_serving_unit": "scoop",
    "protein": "0",
    "calories": "0",
    "carbohydrates": "0",
    "fat": "0.0",
    "saturated_fat": "0.0",
    "fiber": "0",
    "sugar": "0",
    "cholesterol": "0",
    "sodium": "50",
    "potassium": "0",
    "glycemic_index": "0",
    "allergens": "",
    "short_description": "BCAA آمینواسید شاخه‌دار؛ حین تمرین یا بین وعده.",
    "serving_notes": "ارزش‌ها برای پودر BCAA در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.",
    "tip_1": "۵–۱۰ گرم با آب.",
    "tip_2": "جایگزین پروتئین کامل نیست.",
    "tip_3": "در کسری کالری اختیاری است.",
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
    "legacy_slug": "bcaa-powder",
    "migrate_slugs": [],
    "image_url": "https://images.unsplash.com/photo-1455619452474-d2be8b1e70cb?w=800&q=80",
    "aliases_en": [
      "BCAA powder",
      "Branched chain amino acids"
    ],
    "related_slugs": [
      "پودر-وی-پروتئین",
      "پروتئین-بار",
      "سینه-مرغ-گریل-شده"
    ],
    "intro": "BCAA در تمرینات طولانی کاربرد دارد.",
    "substitutes": [
      {
        "slug": "پودر-وی-پروتئین",
        "ratio": 1.0
      },
      {
        "slug": "پروتئین-بار",
        "ratio": 1.0
      }
    ]
  }
]
GYMAI_FOOD_BATCH14
        , true);
        return is_array($cache) ? $cache : array();
    }
}
