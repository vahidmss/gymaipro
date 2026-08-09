-- پاک‌سازی امتیاز/رتبه جعلی مربی GymAI (اگر از seed قدیمی ۴.۹ با ۰ نظر مانده)
UPDATE profiles
SET
  rating = 0,
  review_count = 0,
  experience_years = 0,
  ranking = NULL,
  updated_at = NOW()
WHERE id = '00000000-0000-0000-0000-000000000001'
   OR username IN ('gymai_trainer', 'gymai', 'gym_ai');
