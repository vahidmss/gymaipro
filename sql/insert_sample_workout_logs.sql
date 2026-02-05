-- Insert sample workout logs for the past 10 days
-- This script creates workout logs based on the provided program
-- Days are alternated: workout days and rest days

-- User ID and Program Info
-- user_id: 0318fc1c-352e-4958-bec5-c0e641a86ddc
-- Program has 3 workout days: Day 1, Day 2, Day 3

-- Day 1 (2025-11-12) - Workout Day 1
INSERT INTO workout_daily_logs (id, user_id, log_date, sessions, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    '0318fc1c-352e-4958-bec5-c0e641a86ddc',
    '2025-11-12',
    '[
        {
            "id": "aa066670-a85b-4ec8-b55c-9fe02176cf1c",
            "day": "روز 1",
            "exercises": [
                {
                    "id": "f12b59e4-4ec9-491e-af9e-37b47135f68c",
                    "tag": "سینه",
                    "sets": [
                        {"reps": 10, "weight": 0.0, "seconds": 60},
                        {"reps": 10, "weight": 0.0, "seconds": 0},
                        {"reps": 10, "weight": 0.0, "seconds": 0}
                    ],
                    "type": "normal",
                    "style": "setsReps",
                    "exercise_id": 3651,
                    "exercise_name": "شنای کرال سینه"
                },
                {
                    "id": "37d3638b-bdac-42c0-b56b-7fce14178a74",
                    "tag": "سینه",
                    "sets": [
                        {"reps": 10, "weight": 45.0, "seconds": 60},
                        {"reps": 10, "weight": 50.0, "seconds": 0},
                        {"reps": 10, "weight": 50.0, "seconds": 0}
                    ],
                    "type": "normal",
                    "style": "setsReps",
                    "exercise_id": 3533,
                    "exercise_name": "پرس سینه دست جمع"
                },
                {
                    "id": "3ddf1bb6-0b6c-4f3a-b36c-297954756964",
                    "tag": "سینه",
                    "sets": [
                        {"reps": 12, "weight": 15.0, "seconds": 60},
                        {"reps": 12, "weight": 20.0, "seconds": 0},
                        {"reps": 12, "weight": 20.0, "seconds": 0}
                    ],
                    "type": "normal",
                    "style": "setsReps",
                    "exercise_id": 3475,
                    "exercise_name": "کراس از پایین به بالا"
                },
                {
                    "id": "bdb85635-f1d8-43ab-af98-84f234100bf3",
                    "tag": "سینه",
                    "sets": [
                        {"reps": 12, "weight": 12.0, "seconds": 60},
                        {"reps": 12, "weight": 15.0, "seconds": 0},
                        {"reps": 12, "weight": 15.0, "seconds": 0}
                    ],
                    "type": "normal",
                    "style": "setsReps",
                    "exercise_id": 3472,
                    "exercise_name": "قفسه دمبل بالاسینه"
                },
                {
                    "id": "038330a6-7b47-45ac-8191-7ea0c42e2e50",
                    "tag": "سینه",
                    "sets": [
                        {"reps": 12, "weight": 40.0, "seconds": 60},
                        {"reps": 12, "weight": 45.0, "seconds": 0},
                        {"reps": 12, "weight": 45.0, "seconds": 0},
                        {"reps": 12, "weight": 45.0, "seconds": 0}
                    ],
                    "type": "normal",
                    "style": "setsReps",
                    "exercise_id": 3537,
                    "exercise_name": "پشت‌بازو سیمکش معکوس"
                }
            ]
        }
    ]'::jsonb,
    '2025-11-12 08:00:00+00',
    '2025-11-12 09:30:00+00'
)
ON CONFLICT (user_id, log_date) DO NOTHING;

-- Day 2 (2025-11-13) - Rest Day (no workout)

-- Day 3 (2025-11-14) - Workout Day 2
INSERT INTO workout_daily_logs (id, user_id, log_date, sessions, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    '0318fc1c-352e-4958-bec5-c0e641a86ddc',
    '2025-11-14',
    '[
        {
            "id": "84b1f359-99e7-47cd-b802-d7355a097153",
            "day": "روز 2",
            "exercises": [
                {
                    "id": "27290bc9-cd8d-4329-a59f-1b38655e4eec",
                    "tag": "سینه",
                    "sets": [
                        {"reps": 12, "weight": 0.0, "seconds": 60},
                        {"reps": 12, "weight": 0.0, "seconds": 0},
                        {"reps": 12, "weight": 0.0, "seconds": 0}
                    ],
                    "type": "normal",
                    "style": "setsReps",
                    "exercise_id": 3606,
                    "exercise_name": "پرس سینه هالتر"
                },
                {
                    "id": "e2281b06-7950-4f62-b3cd-94a6947c6b07",
                    "tag": "سینه",
                    "sets": [
                        {"reps": 10, "weight": 50.0, "seconds": 60},
                        {"reps": 10, "weight": 55.0, "seconds": 0},
                        {"reps": 10, "weight": 55.0, "seconds": 0}
                    ],
                    "type": "normal",
                    "style": "setsReps",
                    "exercise_id": 3512,
                    "exercise_name": "پرس سینه دمبل"
                },
                {
                    "id": "1841110c-5470-498e-9d5a-a63b33637a91",
                    "tag": "سینه",
                    "sets": [
                        {"reps": 10, "weight": 20.0, "seconds": 60},
                        {"reps": 10, "weight": 22.5, "seconds": 0},
                        {"reps": 10, "weight": 22.5, "seconds": 0}
                    ],
                    "type": "normal",
                    "style": "setsReps",
                    "exercise_id": 3505,
                    "exercise_name": "قفسه سینه دمبل"
                },
                {
                    "id": "28ee7eaf-7f02-4f5d-896e-416e5652c060",
                    "tag": "سینه",
                    "sets": [
                        {"reps": 10, "weight": 15.0, "seconds": 60},
                        {"reps": 10, "weight": 17.5, "seconds": 0},
                        {"reps": 10, "weight": 17.5, "seconds": 0}
                    ],
                    "type": "normal",
                    "style": "setsReps",
                    "exercise_id": 3503,
                    "exercise_name": "پول اور سیمکش"
                },
                {
                    "id": "5f86b990-d1c3-4c10-a324-aa4887068cf9",
                    "tag": "سینه",
                    "sets": [
                        {"reps": 10, "weight": 12.0, "seconds": 60},
                        {"reps": 10, "weight": 15.0, "seconds": 0},
                        {"reps": 10, "weight": 15.0, "seconds": 0}
                    ],
                    "type": "normal",
                    "style": "setsReps",
                    "exercise_id": 3526,
                    "exercise_name": "کراس اور سیمکش"
                },
                {
                    "id": "680fbadc-ece0-49f1-bddc-7cc2df24eb77",
                    "tag": "سینه",
                    "sets": [
                        {"reps": 10, "weight": 10.0, "seconds": 60},
                        {"reps": 10, "weight": 12.5, "seconds": 0},
                        {"reps": 10, "weight": 12.5, "seconds": 0}
                    ],
                    "type": "normal",
                    "style": "setsReps",
                    "exercise_id": 3522,
                    "exercise_name": "پرس بالا سینه"
                }
            ]
        }
    ]'::jsonb,
    '2025-11-14 08:00:00+00',
    '2025-11-14 09:45:00+00'
)
ON CONFLICT (user_id, log_date) DO NOTHING;

-- Day 4 (2025-11-15) - Rest Day (no workout)

-- Day 5 (2025-11-16) - Workout Day 3
INSERT INTO workout_daily_logs (id, user_id, log_date, sessions, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    '0318fc1c-352e-4958-bec5-c0e641a86ddc',
    '2025-11-16',
    '[
        {
            "id": "ef720c2d-0aba-41a8-a0b4-8ad83b577853",
            "day": "روز 3",
            "exercises": [
                {
                    "id": "24f47764-de74-43dd-b4d6-b1c12c745b78",
                    "tag": "سینه",
                    "sets": [
                        {"reps": 10, "weight": 0.0, "seconds": 60},
                        {"reps": 10, "weight": 0.0, "seconds": 0},
                        {"reps": 10, "weight": 0.0, "seconds": 0}
                    ],
                    "type": "normal",
                    "style": "setsReps",
                    "exercise_id": 3544,
                    "exercise_name": "پرس سینه دستگاه"
                },
                {
                    "id": "ba6de3f6-5a60-4404-b4d3-55d026ded750",
                    "tag": "سینه",
                    "sets": [
                        {"reps": 10, "weight": 55.0, "seconds": 60},
                        {"reps": 10, "weight": 60.0, "seconds": 0},
                        {"reps": 10, "weight": 60.0, "seconds": 0},
                        {"reps": 10, "weight": 60.0, "seconds": 0}
                    ],
                    "type": "normal",
                    "style": "setsReps",
                    "exercise_id": 3554,
                    "exercise_name": "پرس سینه هالتر شیب دار"
                },
                {
                    "id": "a9133389-c908-499f-b3a1-70f040fbeaba",
                    "tag": "سینه",
                    "sets": [
                        {"reps": 10, "weight": 25.0, "seconds": 60},
                        {"reps": 10, "weight": 27.5, "seconds": 0},
                        {"reps": 10, "weight": 27.5, "seconds": 0}
                    ],
                    "type": "normal",
                    "style": "setsReps",
                    "exercise_id": 3552,
                    "exercise_name": "قفسه سینه دمبل شیب دار"
                },
                {
                    "id": "c2298e01-9141-47c3-8707-96615335c88e",
                    "tag": "سینه",
                    "sets": [
                        {"reps": 10, "weight": 20.0, "seconds": 60},
                        {"reps": 10, "weight": 22.5, "seconds": 0},
                        {"reps": 10, "weight": 22.5, "seconds": 0},
                        {"reps": 10, "weight": 22.5, "seconds": 0}
                    ],
                    "type": "normal",
                    "style": "setsReps",
                    "exercise_id": 3569,
                    "exercise_name": "پرس بالا سینه دمبل"
                }
            ]
        }
    ]'::jsonb,
    '2025-11-16 08:00:00+00',
    '2025-11-16 09:30:00+00'
)
ON CONFLICT (user_id, log_date) DO NOTHING;

-- Day 6 (2025-11-17) - Rest Day (no workout)

-- Day 7 (2025-11-18) - Workout Day 1 (repeat)
INSERT INTO workout_daily_logs (id, user_id, log_date, sessions, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    '0318fc1c-352e-4958-bec5-c0e641a86ddc',
    '2025-11-18',
    '[
        {
            "id": "aa066670-a85b-4ec8-b55c-9fe02176cf1c",
            "day": "روز 1",
            "exercises": [
                {
                    "id": "f12b59e4-4ec9-491e-af9e-37b47135f68c",
                    "tag": "سینه",
                    "sets": [
                        {"reps": 10, "weight": 0.0, "seconds": 60},
                        {"reps": 10, "weight": 0.0, "seconds": 0},
                        {"reps": 10, "weight": 0.0, "seconds": 0}
                    ],
                    "type": "normal",
                    "style": "setsReps",
                    "exercise_id": 3651,
                    "exercise_name": "شنای کرال سینه"
                },
                {
                    "id": "37d3638b-bdac-42c0-b56b-7fce14178a74",
                    "tag": "سینه",
                    "sets": [
                        {"reps": 10, "weight": 50.0, "seconds": 60},
                        {"reps": 10, "weight": 52.5, "seconds": 0},
                        {"reps": 10, "weight": 52.5, "seconds": 0}
                    ],
                    "type": "normal",
                    "style": "setsReps",
                    "exercise_id": 3533,
                    "exercise_name": "پرس سینه دست جمع"
                },
                {
                    "id": "3ddf1bb6-0b6c-4f3a-b36c-297954756964",
                    "tag": "سینه",
                    "sets": [
                        {"reps": 12, "weight": 20.0, "seconds": 60},
                        {"reps": 12, "weight": 22.5, "seconds": 0},
                        {"reps": 12, "weight": 22.5, "seconds": 0}
                    ],
                    "type": "normal",
                    "style": "setsReps",
                    "exercise_id": 3475,
                    "exercise_name": "کراس از پایین به بالا"
                },
                {
                    "id": "bdb85635-f1d8-43ab-af98-84f234100bf3",
                    "tag": "سینه",
                    "sets": [
                        {"reps": 12, "weight": 15.0, "seconds": 60},
                        {"reps": 12, "weight": 17.5, "seconds": 0},
                        {"reps": 12, "weight": 17.5, "seconds": 0}
                    ],
                    "type": "normal",
                    "style": "setsReps",
                    "exercise_id": 3472,
                    "exercise_name": "قفسه دمبل بالاسینه"
                },
                {
                    "id": "038330a6-7b47-45ac-8191-7ea0c42e2e50",
                    "tag": "سینه",
                    "sets": [
                        {"reps": 12, "weight": 45.0, "seconds": 60},
                        {"reps": 12, "weight": 47.5, "seconds": 0},
                        {"reps": 12, "weight": 47.5, "seconds": 0},
                        {"reps": 12, "weight": 47.5, "seconds": 0}
                    ],
                    "type": "normal",
                    "style": "setsReps",
                    "exercise_id": 3537,
                    "exercise_name": "پشت‌بازو سیمکش معکوس"
                }
            ]
        }
    ]'::jsonb,
    '2025-11-18 08:00:00+00',
    '2025-11-18 09:30:00+00'
)
ON CONFLICT (user_id, log_date) DO NOTHING;

-- Day 8 (2025-11-19) - Rest Day (no workout)

-- Day 9 (2025-11-20) - Workout Day 2 (repeat)
INSERT INTO workout_daily_logs (id, user_id, log_date, sessions, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    '0318fc1c-352e-4958-bec5-c0e641a86ddc',
    '2025-11-20',
    '[
        {
            "id": "84b1f359-99e7-47cd-b802-d7355a097153",
            "day": "روز 2",
            "exercises": [
                {
                    "id": "27290bc9-cd8d-4329-a59f-1b38655e4eec",
                    "tag": "سینه",
                    "sets": [
                        {"reps": 12, "weight": 0.0, "seconds": 60},
                        {"reps": 12, "weight": 0.0, "seconds": 0},
                        {"reps": 12, "weight": 0.0, "seconds": 0}
                    ],
                    "type": "normal",
                    "style": "setsReps",
                    "exercise_id": 3606,
                    "exercise_name": "پرس سینه هالتر"
                },
                {
                    "id": "e2281b06-7950-4f62-b3cd-94a6947c6b07",
                    "tag": "سینه",
                    "sets": [
                        {"reps": 10, "weight": 55.0, "seconds": 60},
                        {"reps": 10, "weight": 57.5, "seconds": 0},
                        {"reps": 10, "weight": 57.5, "seconds": 0}
                    ],
                    "type": "normal",
                    "style": "setsReps",
                    "exercise_id": 3512,
                    "exercise_name": "پرس سینه دمبل"
                },
                {
                    "id": "1841110c-5470-498e-9d5a-a63b33637a91",
                    "tag": "سینه",
                    "sets": [
                        {"reps": 10, "weight": 22.5, "seconds": 60},
                        {"reps": 10, "weight": 25.0, "seconds": 0},
                        {"reps": 10, "weight": 25.0, "seconds": 0}
                    ],
                    "type": "normal",
                    "style": "setsReps",
                    "exercise_id": 3505,
                    "exercise_name": "قفسه سینه دمبل"
                },
                {
                    "id": "28ee7eaf-7f02-4f5d-896e-416e5652c060",
                    "tag": "سینه",
                    "sets": [
                        {"reps": 10, "weight": 17.5, "seconds": 60},
                        {"reps": 10, "weight": 20.0, "seconds": 0},
                        {"reps": 10, "weight": 20.0, "seconds": 0}
                    ],
                    "type": "normal",
                    "style": "setsReps",
                    "exercise_id": 3503,
                    "exercise_name": "پول اور سیمکش"
                },
                {
                    "id": "5f86b990-d1c3-4c10-a324-aa4887068cf9",
                    "tag": "سینه",
                    "sets": [
                        {"reps": 10, "weight": 15.0, "seconds": 60},
                        {"reps": 10, "weight": 17.5, "seconds": 0},
                        {"reps": 10, "weight": 17.5, "seconds": 0}
                    ],
                    "type": "normal",
                    "style": "setsReps",
                    "exercise_id": 3526,
                    "exercise_name": "کراس اور سیمکش"
                },
                {
                    "id": "680fbadc-ece0-49f1-bddc-7cc2df24eb77",
                    "tag": "سینه",
                    "sets": [
                        {"reps": 10, "weight": 12.5, "seconds": 60},
                        {"reps": 10, "weight": 15.0, "seconds": 0},
                        {"reps": 10, "weight": 15.0, "seconds": 0}
                    ],
                    "type": "normal",
                    "style": "setsReps",
                    "exercise_id": 3522,
                    "exercise_name": "پرس بالا سینه"
                }
            ]
        }
    ]'::jsonb,
    '2025-11-20 08:00:00+00',
    '2025-11-20 09:45:00+00'
)
ON CONFLICT (user_id, log_date) DO NOTHING;

-- Day 10 (2025-11-21) - Rest Day (no workout)

