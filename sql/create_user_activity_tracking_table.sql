-- جدول ردیابی فعالیت‌های خودکار کاربران برای سیستم رتبه‌بندی
-- این جدول فعالیت‌های واقعی کاربر را ردیابی می‌کند که قابل دستکاری نیستند

CREATE TABLE IF NOT EXISTS public.user_activity_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  activity_date DATE NOT NULL DEFAULT CURRENT_DATE,
  
  -- ردیابی خواندن مقالات (به دقیقه)
  article_reading_minutes INTEGER NOT NULL DEFAULT 0,
  
  -- ردیابی گوش دادن به موزیک (به دقیقه)
  music_listening_minutes INTEGER NOT NULL DEFAULT 0,
  
  -- ردیابی تماشای ویدیو (به دقیقه)
  video_watching_minutes INTEGER NOT NULL DEFAULT 0,
  
  -- ثبت تمرین (تعداد تمرینات ثبت شده در روز)
  workout_logs_count INTEGER NOT NULL DEFAULT 0,
  
  -- ثبت رژیم (تعداد وعده‌های ثبت شده در روز)
  meal_logs_count INTEGER NOT NULL DEFAULT 0,
  
  -- کالری‌شماری (تعداد روزهایی که کالری شماری شده)
  calorie_counting_days INTEGER NOT NULL DEFAULT 0,
  
  -- تاریخ ایجاد و به‌روزرسانی
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- هر کاربر فقط یک رکورد در روز دارد
  UNIQUE(user_id, activity_date)
);

-- ایندکس‌ها برای بهبود عملکرد
CREATE INDEX IF NOT EXISTS idx_user_activity_tracking_user_date 
  ON public.user_activity_tracking(user_id, activity_date DESC);

CREATE INDEX IF NOT EXISTS idx_user_activity_tracking_date 
  ON public.user_activity_tracking(activity_date DESC);

-- Enable RLS
ALTER TABLE public.user_activity_tracking ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own activity tracking" 
  ON public.user_activity_tracking
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own activity tracking" 
  ON public.user_activity_tracking
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own activity tracking" 
  ON public.user_activity_tracking
  FOR UPDATE USING (auth.uid() = user_id);

-- Function برای به‌روزرسانی خودکار updated_at
CREATE OR REPLACE FUNCTION update_user_activity_tracking_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger برای به‌روزرسانی خودکار
CREATE TRIGGER update_user_activity_tracking_updated_at
  BEFORE UPDATE ON public.user_activity_tracking
  FOR EACH ROW
  EXECUTE FUNCTION update_user_activity_tracking_updated_at();
