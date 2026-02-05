-- ============================================================
-- داده تستی ثابت برای صفحه رتبه‌بندی (همه لیگ‌ها قابل مشاهده)
-- ============================================================
-- این اسکریپت از همین الان کاربران موجود در profiles را می‌گیرد
-- و به آن‌ها امتیاز و لیگ ثابت می‌دهد تا بتوانید صفحه را مرتب تست کنید.
-- در Supabase Dashboard > SQL Editor اجرا کنید.
-- ============================================================

-- ۱) حذف رتبه‌های قبلی (اختیاری - برای شروع تمیز)
-- DELETE FROM public.user_rankings;

-- ۲) درج/به‌روزرسانی رتبه با امتیاز و لیگ ثابت برای چند کاربر اول
WITH profiles_sample AS (
  SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn
  FROM public.profiles
  WHERE role = 'athlete'
  LIMIT 20
),
scores AS (
  SELECT id, rn,
    CASE rn
      WHEN 1 THEN 18000   -- الماس
      WHEN 2 THEN 16000   -- الماس
      WHEN 3 THEN 12000   -- پلاتین
      WHEN 4 THEN 9000    -- پلاتین
      WHEN 5 THEN 7500    -- پلاتین
      WHEN 6 THEN 5500    -- طلا
      WHEN 7 THEN 4500    -- طلا
      WHEN 8 THEN 3500    -- طلا
      WHEN 9 THEN 2500    -- نقره
      WHEN 10 THEN 1500   -- نقره
      WHEN 11 THEN 1200   -- نقره
      WHEN 12 THEN 800    -- برنز
      WHEN 13 THEN 500    -- برنز
      WHEN 14 THEN 300    -- برنز
      ELSE 200 + (rn * 100)
    END AS total_score,
    CASE
      WHEN rn IN (1, 2) THEN 'diamond'
      WHEN rn IN (3, 4, 5) THEN 'platinum'
      WHEN rn IN (6, 7, 8) THEN 'gold'
      WHEN rn IN (9, 10, 11) THEN 'silver'
      ELSE 'bronze'
    END AS current_league
  FROM profiles_sample
)
INSERT INTO public.user_rankings (
  user_id,
  total_score,
  current_league,
  league_points,
  league_changed_at,
  rank_updated_at
)
SELECT
  s.id,
  s.total_score,
  s.current_league,
  GREATEST(0, s.total_score - CASE s.current_league
    WHEN 'bronze'   THEN 0
    WHEN 'silver'   THEN 1001
    WHEN 'gold'     THEN 3001
    WHEN 'platinum' THEN 7001
    WHEN 'diamond'  THEN 15001
    ELSE 0
  END),
  NOW(),
  NOW()
FROM scores s
ON CONFLICT (user_id) DO UPDATE SET
  total_score = EXCLUDED.total_score,
  current_league = EXCLUDED.current_league,
  league_points = EXCLUDED.league_points,
  league_changed_at = EXCLUDED.league_changed_at,
  rank_updated_at = EXCLUDED.rank_updated_at;

-- ۳) به‌روزرسانی رتب سراسری (global_rank)
WITH ranked AS (
  SELECT user_id, ROW_NUMBER() OVER (ORDER BY total_score DESC) AS r
  FROM public.user_rankings
)
UPDATE public.user_rankings ur
SET global_rank = ranked.r
FROM ranked
WHERE ur.user_id = ranked.user_id;

-- ۴) به‌روزرسانی رتب در هر لیگ (league_rank)
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

-- ۵) نمایش خلاصه برای اطمینان
SELECT current_league, COUNT(*) AS count, MIN(total_score) AS min_score, MAX(total_score) AS max_score
FROM public.user_rankings
GROUP BY current_league
ORDER BY MIN(total_score);
