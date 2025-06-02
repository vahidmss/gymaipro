-- توجه: این اسکریپت برای تست کردن ساختار JSONB در workout_program_logs است
-- و می‌تواند در محیط توسعه برای بررسی عملکرد صحیح استفاده شود.

-- تست درج یک برنامه تمرینی کامل با ساختار JSONB
INSERT INTO workout_program_logs (user_id, program_name, sessions)
VALUES 
(
  auth.uid(), -- شناسه کاربر فعلی
  'برنامه تست',
  '[
    {
      "id": "session-123",
      "day": "شنبه",
      "exercises": [
        {
          "id": "exercise-1",
          "type": "normal",
          "exercise_id": 1,
          "exercise_name": "پرس سینه",
          "tag": "سینه",
          "style": "normal",
          "sets": [
            {"reps": 12, "weight": 60},
            {"reps": 10, "weight": 70},
            {"reps": 8, "weight": 80}
          ]
        },
        {
          "id": "exercise-2",
          "type": "superset",
          "tag": "سینه و جلو بازو",
          "style": "superset",
          "exercises": [
            {
              "exercise_id": 2,
              "exercise_name": "جلو بازو هالتر",
              "sets": [
                {"reps": 12, "weight": 25},
                {"reps": 10, "weight": 30}
              ]
            },
            {
              "exercise_id": 3,
              "exercise_name": "قفسه سینه دمبل",
              "sets": [
                {"reps": 12, "weight": 20},
                {"reps": 10, "weight": 22.5}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "session-456",
      "day": "دوشنبه",
      "exercises": [
        {
          "id": "exercise-3",
          "type": "normal",
          "exercise_id": 4,
          "exercise_name": "اسکات پا",
          "tag": "پا",
          "style": "normal",
          "sets": [
            {"reps": 15, "weight": 80},
            {"reps": 12, "weight": 100},
            {"reps": 10, "weight": 120}
          ]
        }
      ]
    }
  ]'::jsonb
);

-- بازیابی و نمایش برنامه تمرینی درج شده
SELECT * FROM workout_program_logs WHERE program_name = 'برنامه تست' AND user_id = auth.uid();

-- استخراج روزهای تمرینی و تعداد تمرین‌ها با استفاده از تابع
SELECT s.day, s.exercise_count
FROM workout_program_logs,
     LATERAL get_program_sessions(sessions) s
WHERE program_name = 'برنامه تست' AND user_id = auth.uid();

-- پاکسازی داده‌های تست (در محیط توسعه)
DELETE FROM workout_program_logs WHERE program_name = 'برنامه تست' AND user_id = auth.uid(); 