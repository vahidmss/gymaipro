-- جدول رتبه‌بندی کاربران
CREATE TABLE IF NOT EXISTS public.user_rankings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- امتیاز کلی
  total_score INTEGER NOT NULL DEFAULT 0,
  
  -- رتبه کلی
  global_rank INTEGER,
  
  -- رتبه در لیگ
  league_rank INTEGER,
  
  -- لیگ فعلی
  current_league VARCHAR(20) NOT NULL DEFAULT 'bronze',
  -- مقادیر: bronze, silver, gold, platinum, diamond
  
  -- امتیاز لیگ (برای ارتقا/سقوط)
  league_points INTEGER NOT NULL DEFAULT 0,
  
  -- تاریخ ارتقا/سقوط آخرین لیگ
  league_changed_at TIMESTAMP WITH TIME ZONE,
  
  -- رتبه در لیگ قبلی (برای نمایش پیشرفت)
  previous_league VARCHAR(20),
  
  -- تاریخ آخرین به‌روزرسانی رتبه
  rank_updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- تاریخ ایجاد
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- ایندکس منحصر به فرد برای هر کاربر
  UNIQUE(user_id)
);

-- ایندکس‌ها
CREATE INDEX IF NOT EXISTS idx_user_rankings_total_score 
  ON public.user_rankings(total_score DESC);
  
CREATE INDEX IF NOT EXISTS idx_user_rankings_league 
  ON public.user_rankings(current_league, league_points DESC);
  
CREATE INDEX IF NOT EXISTS idx_user_rankings_global_rank 
  ON public.user_rankings(global_rank) 
  WHERE global_rank IS NOT NULL;

-- Enable RLS
ALTER TABLE public.user_rankings ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- کاربران می‌توانند رتبه خود را ببینند
CREATE POLICY "Users can view their own ranking" 
  ON public.user_rankings
  FOR SELECT USING (auth.uid() = user_id);

-- Leaderboard عمومی برای همه قابل مشاهده است
CREATE POLICY "Anyone can view leaderboard" 
  ON public.user_rankings
  FOR SELECT USING (true);

-- فقط سیستم می‌تواند رتبه‌ها را به‌روزرسانی کند (از طریق service role)
-- کاربران نمی‌توانند رتبه خود را دستی تغییر دهند

-- Function برای به‌روزرسانی خودکار rank_updated_at
CREATE OR REPLACE FUNCTION update_user_rankings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.rank_updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger برای به‌روزرسانی خودکار
CREATE TRIGGER update_user_rankings_updated_at
  BEFORE UPDATE ON public.user_rankings
  FOR EACH ROW
  EXECUTE FUNCTION update_user_rankings_updated_at();
