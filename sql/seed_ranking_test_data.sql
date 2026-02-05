-- ============================================================
-- داده‌های تستی برای صفحه رتبه‌بندی (Leaderboard)
-- ============================================================
-- نحوه استفاده: این فایل را در Supabase Dashboard > SQL Editor اجرا کنید.
-- توجه: اگر RLS فقط به کاربران لاگین‌شده اجازه INSERT ندهد، با Service Role اجرا کنید.
-- ============================================================

-- ۱) حذف رتبه‌های قبلی (اختیاری - برای شروع تمیز)
-- اگر می‌خواهید فقط داده تست اضافه شود، این بخش را کامنت کنید.
-- DELETE FROM public.user_rankings;

-- ۲) درج رتبه‌بندی تستی برای کاربران موجود در profiles
-- از بین همه پروفایل‌ها (با role athlete یا هر نقش) تعدادی را انتخاب و به آن‌ها امتیاز/لیگ می‌دهیم

INSERT INTO public.user_rankings (
  user_id,
  total_score,
  current_league,
  league_points,
  league_changed_at,
  rank_updated_at
)
SELECT
  p.id,
  -- امتیاز تصادفی بین ۰ تا ۱۶۰۰۰ برای پوشش همه لیگ‌ها
  (random() * 16000)::int,
  CASE
    WHEN random() < 0.25 THEN 'bronze'
    WHEN random() < 0.50 THEN 'silver'
    WHEN random() < 0.70 THEN 'gold'
    WHEN random() < 0.85 THEN 'platinum'
    ELSE 'diamond'
  END,
  (random() * 2000)::int,
  NOW(),
  NOW()
FROM public.profiles p
WHERE p.role = 'athlete'
  AND NOT EXISTS (SELECT 1 FROM public.user_rankings ur WHERE ur.user_id = p.id)
ORDER BY random()
LIMIT 30
ON CONFLICT (user_id) DO UPDATE SET
  total_score = (random() * 16000)::int,
  current_league = CASE
    WHEN random() < 0.25 THEN 'bronze'
    WHEN random() < 0.50 THEN 'silver'
    WHEN random() < 0.70 THEN 'gold'
    WHEN random() < 0.85 THEN 'platinum'
    ELSE 'diamond'
  END,
  league_points = (random() * 2000)::int,
  rank_updated_at = NOW();

-- ۳) به‌روزرسانی league_points بر اساس total_score و حداقل امتیاز هر لیگ
UPDATE public.user_rankings ur
SET league_points = GREATEST(0, ur.total_score - CASE ur.current_league
  WHEN 'bronze'   THEN 0
  WHEN 'silver'   THEN 1001
  WHEN 'gold'     THEN 3001
  WHEN 'platinum' THEN 7001
  WHEN 'diamond'  THEN 15001
  ELSE 0
END);

-- ۴) ست کردن رتبه سراسری (global_rank)
WITH ranked AS (
  SELECT user_id, ROW_NUMBER() OVER (ORDER BY total_score DESC) AS r
  FROM public.user_rankings
)
UPDATE public.user_rankings ur
SET global_rank = ranked.r
FROM ranked
WHERE ur.user_id = ranked.user_id;

-- ۵) ست کردن رتبه در هر لیگ (league_rank)
WITH bronze_ranked AS (
  SELECT user_id, ROW_NUMBER() OVER (ORDER BY league_points DESC) AS r
  FROM public.user_rankings WHERE current_league = 'bronze'
),
silver_ranked AS (
  SELECT user_id, ROW_NUMBER() OVER (ORDER BY league_points DESC) AS r
  FROM public.user_rankings WHERE current_league = 'silver'
),
gold_ranked AS (
  SELECT user_id, ROW_NUMBER() OVER (ORDER BY league_points DESC) AS r
  FROM public.user_rankings WHERE current_league = 'gold'
),
platinum_ranked AS (
  SELECT user_id, ROW_NUMBER() OVER (ORDER BY league_points DESC) AS r
  FROM public.user_rankings WHERE current_league = 'platinum'
),
diamond_ranked AS (
  SELECT user_id, ROW_NUMBER() OVER (ORDER BY league_points DESC) AS r
  FROM public.user_rankings WHERE current_league = 'diamond'
)
UPDATE public.user_rankings ur
SET league_rank = COALESCE(
  (SELECT r FROM bronze_ranked br WHERE br.user_id = ur.user_id),
  (SELECT r FROM silver_ranked sr WHERE sr.user_id = ur.user_id),
  (SELECT r FROM gold_ranked gr WHERE gr.user_id = ur.user_id),
  (SELECT r FROM platinum_ranked pr WHERE pr.user_id = ur.user_id),
  (SELECT r FROM diamond_ranked dr WHERE dr.user_id = ur.user_id)
);

-- ۶) اگر هیچ پروفایلی نداشتید، می‌توانید با یک user_id واقعی تست کنید (یکی از auth.users را بگذارید)
-- مثال (این خط را با user_id واقعی از جدول profiles جایگزین کنید):
/*
INSERT INTO public.user_rankings (user_id, total_score, current_league, league_points)
VALUES
  ('USER_UUID_1', 500, 'bronze', 500),
  ('USER_UUID_2', 2000, 'silver', 999),
  ('USER_UUID_3', 5000, 'gold', 1999),
  ('USER_UUID_4', 10000, 'platinum', 2999),
  ('USER_UUID_5', 18000, 'diamond', 2999)
ON CONFLICT (user_id) DO UPDATE SET
  total_score = EXCLUDED.total_score,
  current_league = EXCLUDED.current_league,
  league_points = EXCLUDED.league_points;
*/

-- بررسی نتیجه
SELECT current_league, COUNT(*), MIN(total_score), MAX(total_score)
FROM public.user_rankings
GROUP BY current_league
ORDER BY MIN(total_score);
