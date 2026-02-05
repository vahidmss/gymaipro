-- اسکریپت SQL برای ایجاد لاگ یک ماهه تمرینات کاربر
-- User ID: 96c529a5-a4e0-42e5-a1e0-ec24064d95df
-- این اسکریپت یک ماه کامل (30 روز) از لاگ تمرینات را با الگوی واقع‌گرایانه ایجاد می‌کند

-- حذف لاگ‌های قبلی این کاربر (اختیاری - در صورت نیاز کامنت کنید)
-- DELETE FROM workout_daily_logs WHERE user_id = '96c529a5-a4e0-42e5-a1e0-ec24064d95df';

-- شروع از 30 روز قبل (می‌توانید تاریخ را تغییر دهید)
-- در این مثال از 2025-11-18 شروع می‌کنیم و تا 2025-12-17 ادامه می‌دهیم

-- ============================================
-- هفته اول (روز 1-7)
-- ============================================

-- روز 1 (2025-11-18) - روز 1: سینه و پشت
INSERT INTO workout_daily_logs (id, user_id, log_date, sessions, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    '96c529a5-a4e0-42e5-a1e0-ec24064d95df',
    '2025-11-18',
    '[
        {
            "id": "2a59a191-ab04-439d-b206-8bf538aa2097",
            "day": "روز 1 - سینه و پشت",
            "notes": "تمرکز بر حرکات سینه و پشت با استفاده از وزنه آزاد و دستگاه.\n\n--- نکات ویژه برای شما ---\n🎯 شدت مدنظر شما: متوسط.\n",
            "exercises": [
                {
                    "id": "fd6dee2a-de1b-4322-b882-5af2c2724d12",
                    "type": "normal",
                    "exercise_id": 3465,
                    "tag": "بنچ پرس هالتر تخت",
                    "exercise_name": "بنچ پرس هالتر تخت",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 10, "weight": 50.0},
                        {"reps": 9, "weight": 55.0},
                        {"reps": 8, "weight": 60.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "8a99161d-12a1-4607-8d1e-13bf3f8f2eac",
                    "type": "normal",
                    "exercise_id": 3473,
                    "tag": "کراس اور سیمکش",
                    "exercise_name": "کراس اور سیمکش",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 12, "weight": 20.0},
                        {"reps": 11, "weight": 22.5},
                        {"reps": 10, "weight": 25.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "4767f6ef-2883-4abf-8242-f084ee415248",
                    "type": "normal",
                    "exercise_id": 3480,
                    "tag": "بارفیکس دست باز",
                    "exercise_name": "بارفیکس دست باز",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 8, "weight": 0.0},
                        {"reps": 6, "weight": 0.0},
                        {"reps": 5, "weight": 0.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "15bda9fc-d396-4d35-afe7-8c8430ebe021",
                    "type": "normal",
                    "exercise_id": 3483,
                    "tag": "لت پول‌دان دست جمع",
                    "exercise_name": "لت پول‌دان دست جمع",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 12, "weight": 40.0},
                        {"reps": 10, "weight": 45.0},
                        {"reps": 9, "weight": 50.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "60fa31c6-8e6d-45f0-961a-e730803fd5eb",
                    "type": "normal",
                    "exercise_id": 3579,
                    "tag": "پلانک",
                    "exercise_name": "پلانک",
                    "style": "setsTime",
                    "sets": [
                        {"seconds": 45},
                        {"seconds": 50},
                        {"seconds": 55}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                }
            ]
        }
    ]'::jsonb,
    '2025-11-18 08:00:00+00',
    '2025-11-18 09:30:00+00'
)
ON CONFLICT (user_id, log_date) DO UPDATE SET sessions = EXCLUDED.sessions, updated_at = EXCLUDED.updated_at;

-- روز 2 (2025-11-19) - استراحت

-- روز 3 (2025-11-20) - روز 2: پا و شکم
INSERT INTO workout_daily_logs (id, user_id, log_date, sessions, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    '96c529a5-a4e0-42e5-a1e0-ec24064d95df',
    '2025-11-20',
    '[
        {
            "id": "4bd5e0e2-9bf8-46e2-9509-56dd5d598bf5",
            "day": "روز 2 - پا و شکم",
            "notes": "تمرکز بر حرکات پا و تقویت عضلات شکم.\n\n--- نکات ویژه برای شما ---\n🎯 شدت مدنظر شما: متوسط.\n",
            "exercises": [
                {
                    "id": "ddb98925-88e6-429b-8144-6d362d9b2aa9",
                    "type": "normal",
                    "exercise_id": 3545,
                    "tag": "اسکوات گابلت",
                    "exercise_name": "اسکوات گابلت",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 12, "weight": 20.0},
                        {"reps": 10, "weight": 22.5},
                        {"reps": 9, "weight": 25.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "08866bc7-0cf8-41dc-afbd-de675b78a8b7",
                    "type": "normal",
                    "exercise_id": 3547,
                    "tag": "لانج دمبل",
                    "exercise_name": "لانج دمبل",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 10, "weight": 12.0},
                        {"reps": 10, "weight": 15.0},
                        {"reps": 8, "weight": 15.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "e1945e8e-9ec9-42f0-be9d-c57d56414018",
                    "type": "normal",
                    "exercise_id": 3553,
                    "tag": "پشت‌پا خوابیده دستگاه",
                    "exercise_name": "پشت‌پا خوابیده دستگاه",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 12, "weight": 30.0},
                        {"reps": 10, "weight": 35.0},
                        {"reps": 9, "weight": 40.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---\n🦾 پشت: از کشیدن وزنه با حرکت کامل استفاده کنید."
                },
                {
                    "id": "7a28955e-b78f-4de4-8145-e757b90f408a",
                    "type": "normal",
                    "exercise_id": 3565,
                    "tag": "ساق پا ایستاده دستگاه",
                    "exercise_name": "ساق پا ایستاده دستگاه",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 15, "weight": 50.0},
                        {"reps": 12, "weight": 55.0},
                        {"reps": 10, "weight": 60.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---\n🦵 پا: زانوها را در راستای انگشتان پا نگه دارید، حرکت را کنترل شده انجام دهید.\n🦵 پا: وزن را روی پاشنه‌ها نگه دارید."
                },
                {
                    "id": "18e714e9-d426-4e04-882d-679d6f107692",
                    "type": "normal",
                    "exercise_id": 3571,
                    "tag": "کرانچ شکم",
                    "exercise_name": "کرانچ شکم",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 15, "weight": 0.0},
                        {"reps": 12, "weight": 0.0},
                        {"reps": 10, "weight": 0.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---\n🔥 شکم: نفس را در حین انقباض نگه دارید، از فشار به گردن پرهیز کنید."
                }
            ]
        }
    ]'::jsonb,
    '2025-11-20 08:00:00+00',
    '2025-11-20 09:45:00+00'
)
ON CONFLICT (user_id, log_date) DO UPDATE SET sessions = EXCLUDED.sessions, updated_at = EXCLUDED.updated_at;

-- روز 4 (2025-11-21) - استراحت

-- روز 5 (2025-11-22) - روز 3: سرشانه و بازو
INSERT INTO workout_daily_logs (id, user_id, log_date, sessions, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    '96c529a5-a4e0-42e5-a1e0-ec24064d95df',
    '2025-11-22',
    '[
        {
            "id": "29342931-326f-49df-896d-9c4d649153bc",
            "day": "روز 3 - سرشانه و بازو",
            "notes": "تمرکز بر تقویت عضلات سرشانه و بازو.\n\n--- نکات ویژه برای شما ---\n🎯 شدت مدنظر شما: متوسط.\n",
            "exercises": [
                {
                    "id": "07f46171-50b4-4d44-a3c7-7cf6c8be7875",
                    "type": "normal",
                    "exercise_id": 3500,
                    "tag": "پرس سرشانه دمبل نشسته",
                    "exercise_name": "پرس سرشانه دمبل نشسته",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 10, "weight": 15.0},
                        {"reps": 9, "weight": 17.5},
                        {"reps": 8, "weight": 20.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---\n🏋️ شانه: حرکت را در دامنه کامل انجام دهید."
                },
                {
                    "id": "1d645db4-f44e-4bdf-9790-ead8a21a989f",
                    "type": "normal",
                    "exercise_id": 3502,
                    "tag": "نشر جانب دمبل",
                    "exercise_name": "نشر جانب دمبل",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 12, "weight": 8.0},
                        {"reps": 10, "weight": 10.0},
                        {"reps": 9, "weight": 10.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "f303def2-a537-43a0-855e-5ce0367e1406",
                    "type": "normal",
                    "exercise_id": 3517,
                    "tag": "جلوبازو دمبل تناوبی",
                    "exercise_name": "جلوبازو دمبل تناوبی",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 10, "weight": 12.0},
                        {"reps": 9, "weight": 15.0},
                        {"reps": 8, "weight": 15.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---\n💪 بازو: حرکت را کامل انجام دهید، از تاب دادن بدن پرهیز کنید.\n💪 بازو: آرنج‌ها را نزدیک بدن نگه دارید."
                },
                {
                    "id": "c0d35698-8060-4aab-9f41-805ec26b3d2f",
                    "type": "normal",
                    "exercise_id": 3528,
                    "tag": "پشت‌بازو سیمکش طناب",
                    "exercise_name": "پشت‌بازو سیمکش طناب",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 12, "weight": 25.0},
                        {"reps": 10, "weight": 30.0},
                        {"reps": 9, "weight": 32.5}
                    ],
                    "note": "--- نکات ویژه برای شما ---\n🦾 پشت: از کشیدن وزنه با حرکت کامل استفاده کنید.\n🦾 پشت: فشار را در وسط پشت احساس کنید."
                },
                {
                    "id": "aaab0f1c-3313-4cbf-a41c-3744213d605a",
                    "type": "normal",
                    "exercise_id": 3511,
                    "tag": "فیس پول",
                    "exercise_name": "فیس پول",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 12, "weight": 20.0},
                        {"reps": 10, "weight": 22.5},
                        {"reps": 9, "weight": 25.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                }
            ]
        }
    ]'::jsonb,
    '2025-11-22 08:00:00+00',
    '2025-11-22 09:30:00+00'
)
ON CONFLICT (user_id, log_date) DO UPDATE SET sessions = EXCLUDED.sessions, updated_at = EXCLUDED.updated_at;

-- روز 6 (2025-11-23) - استراحت

-- روز 7 (2025-11-24) - روز 1: سینه و پشت (پیشرفت)
INSERT INTO workout_daily_logs (id, user_id, log_date, sessions, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    '96c529a5-a4e0-42e5-a1e0-ec24064d95df',
    '2025-11-24',
    '[
        {
            "id": "2a59a191-ab04-439d-b206-8bf538aa2097",
            "day": "روز 1 - سینه و پشت",
            "notes": "تمرکز بر حرکات سینه و پشت با استفاده از وزنه آزاد و دستگاه.\n\n--- نکات ویژه برای شما ---\n🎯 شدت مدنظر شما: متوسط.\n",
            "exercises": [
                {
                    "id": "fd6dee2a-de1b-4322-b882-5af2c2724d12",
                    "type": "normal",
                    "exercise_id": 3465,
                    "tag": "بنچ پرس هالتر تخت",
                    "exercise_name": "بنچ پرس هالتر تخت",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 11, "weight": 52.5},
                        {"reps": 10, "weight": 57.5},
                        {"reps": 9, "weight": 62.5}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "8a99161d-12a1-4607-8d1e-13bf3f8f2eac",
                    "type": "normal",
                    "exercise_id": 3473,
                    "tag": "کراس اور سیمکش",
                    "exercise_name": "کراس اور سیمکش",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 13, "weight": 22.5},
                        {"reps": 12, "weight": 25.0},
                        {"reps": 11, "weight": 27.5}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "4767f6ef-2883-4abf-8242-f084ee415248",
                    "type": "normal",
                    "exercise_id": 3480,
                    "tag": "بارفیکس دست باز",
                    "exercise_name": "بارفیکس دست باز",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 9, "weight": 0.0},
                        {"reps": 7, "weight": 0.0},
                        {"reps": 6, "weight": 0.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "15bda9fc-d396-4d35-afe7-8c8430ebe021",
                    "type": "normal",
                    "exercise_id": 3483,
                    "tag": "لت پول‌دان دست جمع",
                    "exercise_name": "لت پول‌دان دست جمع",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 13, "weight": 42.5},
                        {"reps": 11, "weight": 47.5},
                        {"reps": 10, "weight": 52.5}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "60fa31c6-8e6d-45f0-961a-e730803fd5eb",
                    "type": "normal",
                    "exercise_id": 3579,
                    "tag": "پلانک",
                    "exercise_name": "پلانک",
                    "style": "setsTime",
                    "sets": [
                        {"seconds": 50},
                        {"seconds": 55},
                        {"seconds": 60}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                }
            ]
        }
    ]'::jsonb,
    '2025-11-24 08:00:00+00',
    '2025-11-24 09:35:00+00'
)
ON CONFLICT (user_id, log_date) DO UPDATE SET sessions = EXCLUDED.sessions, updated_at = EXCLUDED.updated_at;

-- ============================================
-- هفته دوم (روز 8-14)
-- ============================================

-- روز 8 (2025-11-25) - استراحت

-- روز 9 (2025-11-26) - روز 2: پا و شکم (پیشرفت)
INSERT INTO workout_daily_logs (id, user_id, log_date, sessions, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    '96c529a5-a4e0-42e5-a1e0-ec24064d95df',
    '2025-11-26',
    '[
        {
            "id": "4bd5e0e2-9bf8-46e2-9509-56dd5d598bf5",
            "day": "روز 2 - پا و شکم",
            "notes": "تمرکز بر حرکات پا و تقویت عضلات شکم.\n\n--- نکات ویژه برای شما ---\n🎯 شدت مدنظر شما: متوسط.\n",
            "exercises": [
                {
                    "id": "ddb98925-88e6-429b-8144-6d362d9b2aa9",
                    "type": "normal",
                    "exercise_id": 3545,
                    "tag": "اسکوات گابلت",
                    "exercise_name": "اسکوات گابلت",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 13, "weight": 22.5},
                        {"reps": 11, "weight": 25.0},
                        {"reps": 10, "weight": 27.5}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "08866bc7-0cf8-41dc-afbd-de675b78a8b7",
                    "type": "normal",
                    "exercise_id": 3547,
                    "tag": "لانج دمبل",
                    "exercise_name": "لانج دمبل",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 11, "weight": 15.0},
                        {"reps": 10, "weight": 17.5},
                        {"reps": 9, "weight": 17.5}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "e1945e8e-9ec9-42f0-be9d-c57d56414018",
                    "type": "normal",
                    "exercise_id": 3553,
                    "tag": "پشت‌پا خوابیده دستگاه",
                    "exercise_name": "پشت‌پا خوابیده دستگاه",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 13, "weight": 32.5},
                        {"reps": 11, "weight": 37.5},
                        {"reps": 10, "weight": 42.5}
                    ],
                    "note": "--- نکات ویژه برای شما ---\n🦾 پشت: از کشیدن وزنه با حرکت کامل استفاده کنید."
                },
                {
                    "id": "7a28955e-b78f-4de4-8145-e757b90f408a",
                    "type": "normal",
                    "exercise_id": 3565,
                    "tag": "ساق پا ایستاده دستگاه",
                    "exercise_name": "ساق پا ایستاده دستگاه",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 16, "weight": 52.5},
                        {"reps": 13, "weight": 57.5},
                        {"reps": 11, "weight": 62.5}
                    ],
                    "note": "--- نکات ویژه برای شما ---\n🦵 پا: زانوها را در راستای انگشتان پا نگه دارید، حرکت را کنترل شده انجام دهید.\n🦵 پا: وزن را روی پاشنه‌ها نگه دارید."
                },
                {
                    "id": "18e714e9-d426-4e04-882d-679d6f107692",
                    "type": "normal",
                    "exercise_id": 3571,
                    "tag": "کرانچ شکم",
                    "exercise_name": "کرانچ شکم",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 16, "weight": 0.0},
                        {"reps": 13, "weight": 0.0},
                        {"reps": 11, "weight": 0.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---\n🔥 شکم: نفس را در حین انقباض نگه دارید، از فشار به گردن پرهیز کنید."
                }
            ]
        }
    ]'::jsonb,
    '2025-11-26 08:00:00+00',
    '2025-11-26 09:50:00+00'
)
ON CONFLICT (user_id, log_date) DO UPDATE SET sessions = EXCLUDED.sessions, updated_at = EXCLUDED.updated_at;

-- روز 10 (2025-11-27) - استراحت

-- روز 11 (2025-11-28) - روز 3: سرشانه و بازو (پیشرفت)
INSERT INTO workout_daily_logs (id, user_id, log_date, sessions, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    '96c529a5-a4e0-42e5-a1e0-ec24064d95df',
    '2025-11-28',
    '[
        {
            "id": "29342931-326f-49df-896d-9c4d649153bc",
            "day": "روز 3 - سرشانه و بازو",
            "notes": "تمرکز بر تقویت عضلات سرشانه و بازو.\n\n--- نکات ویژه برای شما ---\n🎯 شدت مدنظر شما: متوسط.\n",
            "exercises": [
                {
                    "id": "07f46171-50b4-4d44-a3c7-7cf6c8be7875",
                    "type": "normal",
                    "exercise_id": 3500,
                    "tag": "پرس سرشانه دمبل نشسته",
                    "exercise_name": "پرس سرشانه دمبل نشسته",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 11, "weight": 17.5},
                        {"reps": 10, "weight": 20.0},
                        {"reps": 9, "weight": 22.5}
                    ],
                    "note": "--- نکات ویژه برای شما ---\n🏋️ شانه: حرکت را در دامنه کامل انجام دهید."
                },
                {
                    "id": "1d645db4-f44e-4bdf-9790-ead8a21a989f",
                    "type": "normal",
                    "exercise_id": 3502,
                    "tag": "نشر جانب دمبل",
                    "exercise_name": "نشر جانب دمبل",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 13, "weight": 10.0},
                        {"reps": 11, "weight": 12.5},
                        {"reps": 10, "weight": 12.5}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "f303def2-a537-43a0-855e-5ce0367e1406",
                    "type": "normal",
                    "exercise_id": 3517,
                    "tag": "جلوبازو دمبل تناوبی",
                    "exercise_name": "جلوبازو دمبل تناوبی",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 11, "weight": 15.0},
                        {"reps": 10, "weight": 17.5},
                        {"reps": 9, "weight": 17.5}
                    ],
                    "note": "--- نکات ویژه برای شما ---\n💪 بازو: حرکت را کامل انجام دهید، از تاب دادن بدن پرهیز کنید.\n💪 بازو: آرنج‌ها را نزدیک بدن نگه دارید."
                },
                {
                    "id": "c0d35698-8060-4aab-9f41-805ec26b3d2f",
                    "type": "normal",
                    "exercise_id": 3528,
                    "tag": "پشت‌بازو سیمکش طناب",
                    "exercise_name": "پشت‌بازو سیمکش طناب",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 13, "weight": 27.5},
                        {"reps": 11, "weight": 32.5},
                        {"reps": 10, "weight": 35.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---\n🦾 پشت: از کشیدن وزنه با حرکت کامل استفاده کنید.\n🦾 پشت: فشار را در وسط پشت احساس کنید."
                },
                {
                    "id": "aaab0f1c-3313-4cbf-a41c-3744213d605a",
                    "type": "normal",
                    "exercise_id": 3511,
                    "tag": "فیس پول",
                    "exercise_name": "فیس پول",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 13, "weight": 22.5},
                        {"reps": 11, "weight": 25.0},
                        {"reps": 10, "weight": 27.5}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                }
            ]
        }
    ]'::jsonb,
    '2025-11-28 08:00:00+00',
    '2025-11-28 09:35:00+00'
)
ON CONFLICT (user_id, log_date) DO UPDATE SET sessions = EXCLUDED.sessions, updated_at = EXCLUDED.updated_at;

-- روز 12 (2025-11-29) - استراحت

-- روز 13 (2025-11-30) - روز 1: سینه و پشت (پیشرفت بیشتر)
INSERT INTO workout_daily_logs (id, user_id, log_date, sessions, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    '96c529a5-a4e0-42e5-a1e0-ec24064d95df',
    '2025-11-30',
    '[
        {
            "id": "2a59a191-ab04-439d-b206-8bf538aa2097",
            "day": "روز 1 - سینه و پشت",
            "notes": "تمرکز بر حرکات سینه و پشت با استفاده از وزنه آزاد و دستگاه.\n\n--- نکات ویژه برای شما ---\n🎯 شدت مدنظر شما: متوسط.\n",
            "exercises": [
                {
                    "id": "fd6dee2a-de1b-4322-b882-5af2c2724d12",
                    "type": "normal",
                    "exercise_id": 3465,
                    "tag": "بنچ پرس هالتر تخت",
                    "exercise_name": "بنچ پرس هالتر تخت",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 12, "weight": 55.0},
                        {"reps": 11, "weight": 60.0},
                        {"reps": 10, "weight": 65.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "8a99161d-12a1-4607-8d1e-13bf3f8f2eac",
                    "type": "normal",
                    "exercise_id": 3473,
                    "tag": "کراس اور سیمکش",
                    "exercise_name": "کراس اور سیمکش",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 14, "weight": 25.0},
                        {"reps": 13, "weight": 27.5},
                        {"reps": 12, "weight": 30.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "4767f6ef-2883-4abf-8242-f084ee415248",
                    "type": "normal",
                    "exercise_id": 3480,
                    "tag": "بارفیکس دست باز",
                    "exercise_name": "بارفیکس دست باز",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 10, "weight": 0.0},
                        {"reps": 8, "weight": 0.0},
                        {"reps": 7, "weight": 0.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "15bda9fc-d396-4d35-afe7-8c8430ebe021",
                    "type": "normal",
                    "exercise_id": 3483,
                    "tag": "لت پول‌دان دست جمع",
                    "exercise_name": "لت پول‌دان دست جمع",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 14, "weight": 45.0},
                        {"reps": 12, "weight": 50.0},
                        {"reps": 11, "weight": 55.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "60fa31c6-8e6d-45f0-961a-e730803fd5eb",
                    "type": "normal",
                    "exercise_id": 3579,
                    "tag": "پلانک",
                    "exercise_name": "پلانک",
                    "style": "setsTime",
                    "sets": [
                        {"seconds": 55},
                        {"seconds": 60},
                        {"seconds": 65}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                }
            ]
        }
    ]'::jsonb,
    '2025-11-30 08:00:00+00',
    '2025-11-30 09:40:00+00'
)
ON CONFLICT (user_id, log_date) DO UPDATE SET sessions = EXCLUDED.sessions, updated_at = EXCLUDED.updated_at;

-- روز 14 (2025-12-01) - استراحت

-- ============================================
-- هفته سوم (روز 15-21)
-- ============================================

-- روز 15 (2025-12-02) - روز 2: پا و شکم (پیشرفت)
INSERT INTO workout_daily_logs (id, user_id, log_date, sessions, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    '96c529a5-a4e0-42e5-a1e0-ec24064d95df',
    '2025-12-02',
    '[
        {
            "id": "4bd5e0e2-9bf8-46e2-9509-56dd5d598bf5",
            "day": "روز 2 - پا و شکم",
            "notes": "تمرکز بر حرکات پا و تقویت عضلات شکم.\n\n--- نکات ویژه برای شما ---\n🎯 شدت مدنظر شما: متوسط.\n",
            "exercises": [
                {
                    "id": "ddb98925-88e6-429b-8144-6d362d9b2aa9",
                    "type": "normal",
                    "exercise_id": 3545,
                    "tag": "اسکوات گابلت",
                    "exercise_name": "اسکوات گابلت",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 14, "weight": 25.0},
                        {"reps": 12, "weight": 27.5},
                        {"reps": 11, "weight": 30.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "08866bc7-0cf8-41dc-afbd-de675b78a8b7",
                    "type": "normal",
                    "exercise_id": 3547,
                    "tag": "لانج دمبل",
                    "exercise_name": "لانج دمبل",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 12, "weight": 17.5},
                        {"reps": 11, "weight": 20.0},
                        {"reps": 10, "weight": 20.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "e1945e8e-9ec9-42f0-be9d-c57d56414018",
                    "type": "normal",
                    "exercise_id": 3553,
                    "tag": "پشت‌پا خوابیده دستگاه",
                    "exercise_name": "پشت‌پا خوابیده دستگاه",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 14, "weight": 35.0},
                        {"reps": 12, "weight": 40.0},
                        {"reps": 11, "weight": 45.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---\n🦾 پشت: از کشیدن وزنه با حرکت کامل استفاده کنید."
                },
                {
                    "id": "7a28955e-b78f-4de4-8145-e757b90f408a",
                    "type": "normal",
                    "exercise_id": 3565,
                    "tag": "ساق پا ایستاده دستگاه",
                    "exercise_name": "ساق پا ایستاده دستگاه",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 17, "weight": 55.0},
                        {"reps": 14, "weight": 60.0},
                        {"reps": 12, "weight": 65.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---\n🦵 پا: زانوها را در راستای انگشتان پا نگه دارید، حرکت را کنترل شده انجام دهید.\n🦵 پا: وزن را روی پاشنه‌ها نگه دارید."
                },
                {
                    "id": "18e714e9-d426-4e04-882d-679d6f107692",
                    "type": "normal",
                    "exercise_id": 3571,
                    "tag": "کرانچ شکم",
                    "exercise_name": "کرانچ شکم",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 17, "weight": 0.0},
                        {"reps": 14, "weight": 0.0},
                        {"reps": 12, "weight": 0.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---\n🔥 شکم: نفس را در حین انقباض نگه دارید، از فشار به گردن پرهیز کنید."
                }
            ]
        }
    ]'::jsonb,
    '2025-12-02 08:00:00+00',
    '2025-12-02 09:55:00+00'
)
ON CONFLICT (user_id, log_date) DO UPDATE SET sessions = EXCLUDED.sessions, updated_at = EXCLUDED.updated_at;

-- روز 16 (2025-12-03) - استراحت

-- روز 17 (2025-12-04) - روز 3: سرشانه و بازو (پیشرفت)
INSERT INTO workout_daily_logs (id, user_id, log_date, sessions, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    '96c529a5-a4e0-42e5-a1e0-ec24064d95df',
    '2025-12-04',
    '[
        {
            "id": "29342931-326f-49df-896d-9c4d649153bc",
            "day": "روز 3 - سرشانه و بازو",
            "notes": "تمرکز بر تقویت عضلات سرشانه و بازو.\n\n--- نکات ویژه برای شما ---\n🎯 شدت مدنظر شما: متوسط.\n",
            "exercises": [
                {
                    "id": "07f46171-50b4-4d44-a3c7-7cf6c8be7875",
                    "type": "normal",
                    "exercise_id": 3500,
                    "tag": "پرس سرشانه دمبل نشسته",
                    "exercise_name": "پرس سرشانه دمبل نشسته",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 12, "weight": 20.0},
                        {"reps": 11, "weight": 22.5},
                        {"reps": 10, "weight": 25.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---\n🏋️ شانه: حرکت را در دامنه کامل انجام دهید."
                },
                {
                    "id": "1d645db4-f44e-4bdf-9790-ead8a21a989f",
                    "type": "normal",
                    "exercise_id": 3502,
                    "tag": "نشر جانب دمبل",
                    "exercise_name": "نشر جانب دمبل",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 14, "weight": 12.5},
                        {"reps": 12, "weight": 15.0},
                        {"reps": 11, "weight": 15.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "f303def2-a537-43a0-855e-5ce0367e1406",
                    "type": "normal",
                    "exercise_id": 3517,
                    "tag": "جلوبازو دمبل تناوبی",
                    "exercise_name": "جلوبازو دمبل تناوبی",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 12, "weight": 17.5},
                        {"reps": 11, "weight": 20.0},
                        {"reps": 10, "weight": 20.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---\n💪 بازو: حرکت را کامل انجام دهید، از تاب دادن بدن پرهیز کنید.\n💪 بازو: آرنج‌ها را نزدیک بدن نگه دارید."
                },
                {
                    "id": "c0d35698-8060-4aab-9f41-805ec26b3d2f",
                    "type": "normal",
                    "exercise_id": 3528,
                    "tag": "پشت‌بازو سیمکش طناب",
                    "exercise_name": "پشت‌بازو سیمکش طناب",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 14, "weight": 30.0},
                        {"reps": 12, "weight": 35.0},
                        {"reps": 11, "weight": 37.5}
                    ],
                    "note": "--- نکات ویژه برای شما ---\n🦾 پشت: از کشیدن وزنه با حرکت کامل استفاده کنید.\n🦾 پشت: فشار را در وسط پشت احساس کنید."
                },
                {
                    "id": "aaab0f1c-3313-4cbf-a41c-3744213d605a",
                    "type": "normal",
                    "exercise_id": 3511,
                    "tag": "فیس پول",
                    "exercise_name": "فیس پول",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 14, "weight": 25.0},
                        {"reps": 12, "weight": 27.5},
                        {"reps": 11, "weight": 30.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                }
            ]
        }
    ]'::jsonb,
    '2025-12-04 08:00:00+00',
    '2025-12-04 09:40:00+00'
)
ON CONFLICT (user_id, log_date) DO UPDATE SET sessions = EXCLUDED.sessions, updated_at = EXCLUDED.updated_at;

-- روز 18 (2025-12-05) - استراحت

-- روز 19 (2025-12-06) - روز 1: سینه و پشت (پیشرفت)
INSERT INTO workout_daily_logs (id, user_id, log_date, sessions, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    '96c529a5-a4e0-42e5-a1e0-ec24064d95df',
    '2025-12-06',
    '[
        {
            "id": "2a59a191-ab04-439d-b206-8bf538aa2097",
            "day": "روز 1 - سینه و پشت",
            "notes": "تمرکز بر حرکات سینه و پشت با استفاده از وزنه آزاد و دستگاه.\n\n--- نکات ویژه برای شما ---\n🎯 شدت مدنظر شما: متوسط.\n",
            "exercises": [
                {
                    "id": "fd6dee2a-de1b-4322-b882-5af2c2724d12",
                    "type": "normal",
                    "exercise_id": 3465,
                    "tag": "بنچ پرس هالتر تخت",
                    "exercise_name": "بنچ پرس هالتر تخت",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 13, "weight": 57.5},
                        {"reps": 12, "weight": 62.5},
                        {"reps": 11, "weight": 67.5}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "8a99161d-12a1-4607-8d1e-13bf3f8f2eac",
                    "type": "normal",
                    "exercise_id": 3473,
                    "tag": "کراس اور سیمکش",
                    "exercise_name": "کراس اور سیمکش",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 15, "weight": 27.5},
                        {"reps": 14, "weight": 30.0},
                        {"reps": 13, "weight": 32.5}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "4767f6ef-2883-4abf-8242-f084ee415248",
                    "type": "normal",
                    "exercise_id": 3480,
                    "tag": "بارفیکس دست باز",
                    "exercise_name": "بارفیکس دست باز",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 11, "weight": 0.0},
                        {"reps": 9, "weight": 0.0},
                        {"reps": 8, "weight": 0.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "15bda9fc-d396-4d35-afe7-8c8430ebe021",
                    "type": "normal",
                    "exercise_id": 3483,
                    "tag": "لت پول‌دان دست جمع",
                    "exercise_name": "لت پول‌دان دست جمع",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 15, "weight": 47.5},
                        {"reps": 13, "weight": 52.5},
                        {"reps": 12, "weight": 57.5}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "60fa31c6-8e6d-45f0-961a-e730803fd5eb",
                    "type": "normal",
                    "exercise_id": 3579,
                    "tag": "پلانک",
                    "exercise_name": "پلانک",
                    "style": "setsTime",
                    "sets": [
                        {"seconds": 60},
                        {"seconds": 65},
                        {"seconds": 70}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                }
            ]
        }
    ]'::jsonb,
    '2025-12-06 08:00:00+00',
    '2025-12-06 09:45:00+00'
)
ON CONFLICT (user_id, log_date) DO UPDATE SET sessions = EXCLUDED.sessions, updated_at = EXCLUDED.updated_at;

-- روز 20 (2025-12-07) - استراحت

-- روز 21 (2025-12-08) - روز 2: پا و شکم (پیشرفت)
INSERT INTO workout_daily_logs (id, user_id, log_date, sessions, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    '96c529a5-a4e0-42e5-a1e0-ec24064d95df',
    '2025-12-08',
    '[
        {
            "id": "4bd5e0e2-9bf8-46e2-9509-56dd5d598bf5",
            "day": "روز 2 - پا و شکم",
            "notes": "تمرکز بر حرکات پا و تقویت عضلات شکم.\n\n--- نکات ویژه برای شما ---\n🎯 شدت مدنظر شما: متوسط.\n",
            "exercises": [
                {
                    "id": "ddb98925-88e6-429b-8144-6d362d9b2aa9",
                    "type": "normal",
                    "exercise_id": 3545,
                    "tag": "اسکوات گابلت",
                    "exercise_name": "اسکوات گابلت",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 15, "weight": 27.5},
                        {"reps": 13, "weight": 30.0},
                        {"reps": 12, "weight": 32.5}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "08866bc7-0cf8-41dc-afbd-de675b78a8b7",
                    "type": "normal",
                    "exercise_id": 3547,
                    "tag": "لانج دمبل",
                    "exercise_name": "لانج دمبل",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 13, "weight": 20.0},
                        {"reps": 12, "weight": 22.5},
                        {"reps": 11, "weight": 22.5}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "e1945e8e-9ec9-42f0-be9d-c57d56414018",
                    "type": "normal",
                    "exercise_id": 3553,
                    "tag": "پشت‌پا خوابیده دستگاه",
                    "exercise_name": "پشت‌پا خوابیده دستگاه",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 15, "weight": 37.5},
                        {"reps": 13, "weight": 42.5},
                        {"reps": 12, "weight": 47.5}
                    ],
                    "note": "--- نکات ویژه برای شما ---\n🦾 پشت: از کشیدن وزنه با حرکت کامل استفاده کنید."
                },
                {
                    "id": "7a28955e-b78f-4de4-8145-e757b90f408a",
                    "type": "normal",
                    "exercise_id": 3565,
                    "tag": "ساق پا ایستاده دستگاه",
                    "exercise_name": "ساق پا ایستاده دستگاه",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 18, "weight": 57.5},
                        {"reps": 15, "weight": 62.5},
                        {"reps": 13, "weight": 67.5}
                    ],
                    "note": "--- نکات ویژه برای شما ---\n🦵 پا: زانوها را در راستای انگشتان پا نگه دارید، حرکت را کنترل شده انجام دهید.\n🦵 پا: وزن را روی پاشنه‌ها نگه دارید."
                },
                {
                    "id": "18e714e9-d426-4e04-882d-679d6f107692",
                    "type": "normal",
                    "exercise_id": 3571,
                    "tag": "کرانچ شکم",
                    "exercise_name": "کرانچ شکم",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 18, "weight": 0.0},
                        {"reps": 15, "weight": 0.0},
                        {"reps": 13, "weight": 0.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---\n🔥 شکم: نفس را در حین انقباض نگه دارید، از فشار به گردن پرهیز کنید."
                }
            ]
        }
    ]'::jsonb,
    '2025-12-08 08:00:00+00',
    '2025-12-08 10:00:00+00'
)
ON CONFLICT (user_id, log_date) DO UPDATE SET sessions = EXCLUDED.sessions, updated_at = EXCLUDED.updated_at;

-- ============================================
-- هفته چهارم (روز 22-30)
-- ============================================

-- روز 22 (2025-12-09) - استراحت

-- روز 23 (2025-12-10) - روز 3: سرشانه و بازو (پیشرفت) - این یکی از نمونه‌های شماست
INSERT INTO workout_daily_logs (id, user_id, log_date, sessions, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    '96c529a5-a4e0-42e5-a1e0-ec24064d95df',
    '2025-12-10',
    '[
        {
            "id": "29342931-326f-49df-896d-9c4d649153bc",
            "day": "روز 3 - سرشانه و بازو",
            "notes": "تمرکز بر تقویت عضلات سرشانه و بازو.\n\n--- نکات ویژه برای شما ---\n🎯 شدت مدنظر شما: متوسط.\n",
            "exercises": [
                {
                    "id": "07f46171-50b4-4d44-a3c7-7cf6c8be7875",
                    "type": "normal",
                    "exercise_id": 3500,
                    "tag": "پرس سرشانه دمبل نشسته",
                    "exercise_name": "پرس سرشانه دمبل نشسته",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 13, "weight": 22.5},
                        {"reps": 12, "weight": 25.0},
                        {"reps": 11, "weight": 27.5}
                    ],
                    "note": "--- نکات ویژه برای شما ---\n🏋️ شانه: حرکت را در دامنه کامل انجام دهید."
                },
                {
                    "id": "1d645db4-f44e-4bdf-9790-ead8a21a989f",
                    "type": "normal",
                    "exercise_id": 3502,
                    "tag": "نشر جانب دمبل",
                    "exercise_name": "نشر جانب دمبل",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 15, "weight": 15.0},
                        {"reps": 13, "weight": 17.5},
                        {"reps": 12, "weight": 17.5}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "f303def2-a537-43a0-855e-5ce0367e1406",
                    "type": "normal",
                    "exercise_id": 3517,
                    "tag": "جلوبازو دمبل تناوبی",
                    "exercise_name": "جلوبازو دمبل تناوبی",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 13, "weight": 20.0},
                        {"reps": 12, "weight": 22.5},
                        {"reps": 11, "weight": 22.5}
                    ],
                    "note": "--- نکات ویژه برای شما ---\n💪 بازو: حرکت را کامل انجام دهید، از تاب دادن بدن پرهیز کنید.\n💪 بازو: آرنج‌ها را نزدیک بدن نگه دارید."
                },
                {
                    "id": "c0d35698-8060-4aab-9f41-805ec26b3d2f",
                    "type": "normal",
                    "exercise_id": 3528,
                    "tag": "پشت‌بازو سیمکش طناب",
                    "exercise_name": "پشت‌بازو سیمکش طناب",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 15, "weight": 32.5},
                        {"reps": 13, "weight": 37.5},
                        {"reps": 12, "weight": 40.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---\n🦾 پشت: از کشیدن وزنه با حرکت کامل استفاده کنید.\n🦾 پشت: فشار را در وسط پشت احساس کنید."
                },
                {
                    "id": "aaab0f1c-3313-4cbf-a41c-3744213d605a",
                    "type": "normal",
                    "exercise_id": 3511,
                    "tag": "فیس پول",
                    "exercise_name": "فیس پول",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 15, "weight": 27.5},
                        {"reps": 13, "weight": 30.0},
                        {"reps": 12, "weight": 32.5}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                }
            ]
        }
    ]'::jsonb,
    '2025-12-10 08:00:00+00',
    '2025-12-10 09:45:00+00'
)
ON CONFLICT (user_id, log_date) DO UPDATE SET sessions = EXCLUDED.sessions, updated_at = EXCLUDED.updated_at;

-- روز 24 (2025-12-11) - استراحت

-- روز 25 (2025-12-12) - روز 1: سینه و پشت (پیشرفت)
INSERT INTO workout_daily_logs (id, user_id, log_date, sessions, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    '96c529a5-a4e0-42e5-a1e0-ec24064d95df',
    '2025-12-12',
    '[
        {
            "id": "2a59a191-ab04-439d-b206-8bf538aa2097",
            "day": "روز 1 - سینه و پشت",
            "notes": "تمرکز بر حرکات سینه و پشت با استفاده از وزنه آزاد و دستگاه.\n\n--- نکات ویژه برای شما ---\n🎯 شدت مدنظر شما: متوسط.\n",
            "exercises": [
                {
                    "id": "fd6dee2a-de1b-4322-b882-5af2c2724d12",
                    "type": "normal",
                    "exercise_id": 3465,
                    "tag": "بنچ پرس هالتر تخت",
                    "exercise_name": "بنچ پرس هالتر تخت",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 14, "weight": 60.0},
                        {"reps": 13, "weight": 65.0},
                        {"reps": 12, "weight": 70.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "8a99161d-12a1-4607-8d1e-13bf3f8f2eac",
                    "type": "normal",
                    "exercise_id": 3473,
                    "tag": "کراس اور سیمکش",
                    "exercise_name": "کراس اور سیمکش",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 16, "weight": 30.0},
                        {"reps": 15, "weight": 32.5},
                        {"reps": 14, "weight": 35.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "4767f6ef-2883-4abf-8242-f084ee415248",
                    "type": "normal",
                    "exercise_id": 3480,
                    "tag": "بارفیکس دست باز",
                    "exercise_name": "بارفیکس دست باز",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 12, "weight": 0.0},
                        {"reps": 10, "weight": 0.0},
                        {"reps": 9, "weight": 0.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "15bda9fc-d396-4d35-afe7-8c8430ebe021",
                    "type": "normal",
                    "exercise_id": 3483,
                    "tag": "لت پول‌دان دست جمع",
                    "exercise_name": "لت پول‌دان دست جمع",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 16, "weight": 50.0},
                        {"reps": 14, "weight": 55.0},
                        {"reps": 13, "weight": 60.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "60fa31c6-8e6d-45f0-961a-e730803fd5eb",
                    "type": "normal",
                    "exercise_id": 3579,
                    "tag": "پلانک",
                    "exercise_name": "پلانک",
                    "style": "setsTime",
                    "sets": [
                        {"seconds": 65},
                        {"seconds": 70},
                        {"seconds": 75}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                }
            ]
        }
    ]'::jsonb,
    '2025-12-12 08:00:00+00',
    '2025-12-12 09:50:00+00'
)
ON CONFLICT (user_id, log_date) DO UPDATE SET sessions = EXCLUDED.sessions, updated_at = EXCLUDED.updated_at;

-- روز 26 (2025-12-13) - استراحت

-- روز 27 (2025-12-14) - روز 2: پا و شکم (پیشرفت)
INSERT INTO workout_daily_logs (id, user_id, log_date, sessions, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    '96c529a5-a4e0-42e5-a1e0-ec24064d95df',
    '2025-12-14',
    '[
        {
            "id": "4bd5e0e2-9bf8-46e2-9509-56dd5d598bf5",
            "day": "روز 2 - پا و شکم",
            "notes": "تمرکز بر حرکات پا و تقویت عضلات شکم.\n\n--- نکات ویژه برای شما ---\n🎯 شدت مدنظر شما: متوسط.\n",
            "exercises": [
                {
                    "id": "ddb98925-88e6-429b-8144-6d362d9b2aa9",
                    "type": "normal",
                    "exercise_id": 3545,
                    "tag": "اسکوات گابلت",
                    "exercise_name": "اسکوات گابلت",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 16, "weight": 30.0},
                        {"reps": 14, "weight": 32.5},
                        {"reps": 13, "weight": 35.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "08866bc7-0cf8-41dc-afbd-de675b78a8b7",
                    "type": "normal",
                    "exercise_id": 3547,
                    "tag": "لانج دمبل",
                    "exercise_name": "لانج دمبل",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 14, "weight": 22.5},
                        {"reps": 13, "weight": 25.0},
                        {"reps": 12, "weight": 25.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "e1945e8e-9ec9-42f0-be9d-c57d56414018",
                    "type": "normal",
                    "exercise_id": 3553,
                    "tag": "پشت‌پا خوابیده دستگاه",
                    "exercise_name": "پشت‌پا خوابیده دستگاه",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 16, "weight": 40.0},
                        {"reps": 14, "weight": 45.0},
                        {"reps": 13, "weight": 50.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---\n🦾 پشت: از کشیدن وزنه با حرکت کامل استفاده کنید."
                },
                {
                    "id": "7a28955e-b78f-4de4-8145-e757b90f408a",
                    "type": "normal",
                    "exercise_id": 3565,
                    "tag": "ساق پا ایستاده دستگاه",
                    "exercise_name": "ساق پا ایستاده دستگاه",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 19, "weight": 60.0},
                        {"reps": 16, "weight": 65.0},
                        {"reps": 14, "weight": 70.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---\n🦵 پا: زانوها را در راستای انگشتان پا نگه دارید، حرکت را کنترل شده انجام دهید.\n🦵 پا: وزن را روی پاشنه‌ها نگه دارید."
                },
                {
                    "id": "18e714e9-d426-4e04-882d-679d6f107692",
                    "type": "normal",
                    "exercise_id": 3571,
                    "tag": "کرانچ شکم",
                    "exercise_name": "کرانچ شکم",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 19, "weight": 0.0},
                        {"reps": 16, "weight": 0.0},
                        {"reps": 14, "weight": 0.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---\n🔥 شکم: نفس را در حین انقباض نگه دارید، از فشار به گردن پرهیز کنید."
                }
            ]
        }
    ]'::jsonb,
    '2025-12-14 08:00:00+00',
    '2025-12-14 10:05:00+00'
)
ON CONFLICT (user_id, log_date) DO UPDATE SET sessions = EXCLUDED.sessions, updated_at = EXCLUDED.updated_at;

-- روز 28 (2025-12-15) - استراحت

-- روز 29 (2025-12-16) - روز 3: سرشانه و بازو (پیشرفت)
INSERT INTO workout_daily_logs (id, user_id, log_date, sessions, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    '96c529a5-a4e0-42e5-a1e0-ec24064d95df',
    '2025-12-16',
    '[
        {
            "id": "29342931-326f-49df-896d-9c4d649153bc",
            "day": "روز 3 - سرشانه و بازو",
            "notes": "تمرکز بر تقویت عضلات سرشانه و بازو.\n\n--- نکات ویژه برای شما ---\n🎯 شدت مدنظر شما: متوسط.\n",
            "exercises": [
                {
                    "id": "07f46171-50b4-4d44-a3c7-7cf6c8be7875",
                    "type": "normal",
                    "exercise_id": 3500,
                    "tag": "پرس سرشانه دمبل نشسته",
                    "exercise_name": "پرس سرشانه دمبل نشسته",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 14, "weight": 25.0},
                        {"reps": 13, "weight": 27.5},
                        {"reps": 12, "weight": 30.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---\n🏋️ شانه: حرکت را در دامنه کامل انجام دهید."
                },
                {
                    "id": "1d645db4-f44e-4bdf-9790-ead8a21a989f",
                    "type": "normal",
                    "exercise_id": 3502,
                    "tag": "نشر جانب دمبل",
                    "exercise_name": "نشر جانب دمبل",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 16, "weight": 17.5},
                        {"reps": 14, "weight": 20.0},
                        {"reps": 13, "weight": 20.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "f303def2-a537-43a0-855e-5ce0367e1406",
                    "type": "normal",
                    "exercise_id": 3517,
                    "tag": "جلوبازو دمبل تناوبی",
                    "exercise_name": "جلوبازو دمبل تناوبی",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 14, "weight": 22.5},
                        {"reps": 13, "weight": 25.0},
                        {"reps": 12, "weight": 25.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---\n💪 بازو: حرکت را کامل انجام دهید، از تاب دادن بدن پرهیز کنید.\n💪 بازو: آرنج‌ها را نزدیک بدن نگه دارید."
                },
                {
                    "id": "c0d35698-8060-4aab-9f41-805ec26b3d2f",
                    "type": "normal",
                    "exercise_id": 3528,
                    "tag": "پشت‌بازو سیمکش طناب",
                    "exercise_name": "پشت‌بازو سیمکش طناب",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 16, "weight": 35.0},
                        {"reps": 14, "weight": 40.0},
                        {"reps": 13, "weight": 42.5}
                    ],
                    "note": "--- نکات ویژه برای شما ---\n🦾 پشت: از کشیدن وزنه با حرکت کامل استفاده کنید.\n🦾 پشت: فشار را در وسط پشت احساس کنید."
                },
                {
                    "id": "aaab0f1c-3313-4cbf-a41c-3744213d605a",
                    "type": "normal",
                    "exercise_id": 3511,
                    "tag": "فیس پول",
                    "exercise_name": "فیس پول",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 16, "weight": 30.0},
                        {"reps": 14, "weight": 32.5},
                        {"reps": 13, "weight": 35.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                }
            ]
        }
    ]'::jsonb,
    '2025-12-16 08:00:00+00',
    '2025-12-16 09:50:00+00'
)
ON CONFLICT (user_id, log_date) DO UPDATE SET sessions = EXCLUDED.sessions, updated_at = EXCLUDED.updated_at;

-- روز 30 (2025-12-17) - روز 1: سینه و پشت (پیشرفت نهایی)
INSERT INTO workout_daily_logs (id, user_id, log_date, sessions, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    '96c529a5-a4e0-42e5-a1e0-ec24064d95df',
    '2025-12-17',
    '[
        {
            "id": "2a59a191-ab04-439d-b206-8bf538aa2097",
            "day": "روز 1 - سینه و پشت",
            "notes": "تمرکز بر حرکات سینه و پشت با استفاده از وزنه آزاد و دستگاه.\n\n--- نکات ویژه برای شما ---\n🎯 شدت مدنظر شما: متوسط.\n",
            "exercises": [
                {
                    "id": "fd6dee2a-de1b-4322-b882-5af2c2724d12",
                    "type": "normal",
                    "exercise_id": 3465,
                    "tag": "بنچ پرس هالتر تخت",
                    "exercise_name": "بنچ پرس هالتر تخت",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 15, "weight": 62.5},
                        {"reps": 14, "weight": 67.5},
                        {"reps": 13, "weight": 72.5}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "8a99161d-12a1-4607-8d1e-13bf3f8f2eac",
                    "type": "normal",
                    "exercise_id": 3473,
                    "tag": "کراس اور سیمکش",
                    "exercise_name": "کراس اور سیمکش",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 17, "weight": 32.5},
                        {"reps": 16, "weight": 35.0},
                        {"reps": 15, "weight": 37.5}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "4767f6ef-2883-4abf-8242-f084ee415248",
                    "type": "normal",
                    "exercise_id": 3480,
                    "tag": "بارفیکس دست باز",
                    "exercise_name": "بارفیکس دست باز",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 13, "weight": 0.0},
                        {"reps": 11, "weight": 0.0},
                        {"reps": 10, "weight": 0.0}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "15bda9fc-d396-4d35-afe7-8c8430ebe021",
                    "type": "normal",
                    "exercise_id": 3483,
                    "tag": "لت پول‌دان دست جمع",
                    "exercise_name": "لت پول‌دان دست جمع",
                    "style": "setsReps",
                    "sets": [
                        {"reps": 17, "weight": 52.5},
                        {"reps": 15, "weight": 57.5},
                        {"reps": 14, "weight": 62.5}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                },
                {
                    "id": "60fa31c6-8e6d-45f0-961a-e730803fd5eb",
                    "type": "normal",
                    "exercise_id": 3579,
                    "tag": "پلانک",
                    "exercise_name": "پلانک",
                    "style": "setsTime",
                    "sets": [
                        {"seconds": 70},
                        {"seconds": 75},
                        {"seconds": 80}
                    ],
                    "note": "--- نکات ویژه برای شما ---"
                }
            ]
        }
    ]'::jsonb,
    '2025-12-17 08:00:00+00',
    '2025-12-17 10:00:00+00'
)
ON CONFLICT (user_id, log_date) DO UPDATE SET sessions = EXCLUDED.sessions, updated_at = EXCLUDED.updated_at;

-- ============================================
-- خلاصه:
-- این اسکریپت یک ماه کامل (30 روز) از لاگ تمرینات را ایجاد می‌کند
-- الگوی تمرین: 3-4 جلسه در هفته با روزهای استراحت بین تمرینات
-- پیشرفت تدریجی: افزایش تدریجی وزن و تکرار در طول ماه
-- تعداد کل جلسات تمرین: 13 جلسه در 30 روز
-- ============================================
