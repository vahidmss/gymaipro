-- Create progress_analyses table
-- این جدول برای ذخیره نتایج تحلیل‌های پیشرفت هوش مصنوعی استفاده می‌شود

CREATE TABLE IF NOT EXISTS public.progress_analyses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    analysis_result TEXT NOT NULL,
    period_days INTEGER NOT NULL,
    analysis_date TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_progress_analyses_user_id ON public.progress_analyses(user_id);
CREATE INDEX IF NOT EXISTS idx_progress_analyses_user_period ON public.progress_analyses(user_id, period_days);
CREATE INDEX IF NOT EXISTS idx_progress_analyses_analysis_date ON public.progress_analyses(analysis_date DESC);
CREATE INDEX IF NOT EXISTS idx_progress_analyses_user_date ON public.progress_analyses(user_id, analysis_date DESC);

-- Enable RLS
ALTER TABLE public.progress_analyses ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid errors on re-run)
DROP POLICY IF EXISTS "Users can view their own progress analyses" ON public.progress_analyses;
DROP POLICY IF EXISTS "Users can insert their own progress analyses" ON public.progress_analyses;
DROP POLICY IF EXISTS "Users can update their own progress analyses" ON public.progress_analyses;
DROP POLICY IF EXISTS "Users can delete their own progress analyses" ON public.progress_analyses;

-- Create RLS policies
CREATE POLICY "Users can view their own progress analyses" ON public.progress_analyses
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own progress analyses" ON public.progress_analyses
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own progress analyses" ON public.progress_analyses
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own progress analyses" ON public.progress_analyses
    FOR DELETE USING (auth.uid() = user_id);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_progress_analyses_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
DROP TRIGGER IF EXISTS update_progress_analyses_updated_at ON public.progress_analyses;
CREATE TRIGGER update_progress_analyses_updated_at
    BEFORE UPDATE ON public.progress_analyses
    FOR EACH ROW
    EXECUTE FUNCTION update_progress_analyses_updated_at();

-- توضیحات:
-- این جدول نتایج تحلیل‌های پیشرفت هوش مصنوعی را ذخیره می‌کند
-- هر تحلیل شامل:
--   - analysis_result: متن کامل تحلیل تولید شده توسط AI
--   - period_days: دوره زمانی تحلیل (7، 30، 90 روز)
--   - analysis_date: تاریخ انجام تحلیل
-- 
-- مزایای ذخیره در دیتابیس:
--   - حفظ داده‌ها حتی بعد از پاک کردن اپلیکیشن
--   - دسترسی از چند دستگاه
--   - تاریخچه کامل تحلیل‌ها
--   - همگام‌سازی بین دستگاه‌ها
