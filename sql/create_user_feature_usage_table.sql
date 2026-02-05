-- Create user_feature_usage table
-- این جدول برای ذخیره استفاده کاربران از فیچرهای مختلف (تحلیل پیشرفت، چت AI و ...) استفاده می‌شود

CREATE TABLE IF NOT EXISTS public.user_feature_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    feature_name VARCHAR(50) NOT NULL, -- 'progress_analysis', 'ai_chat', etc.
    usage_type VARCHAR(20) NOT NULL, -- 'total' (کل) یا 'daily' (روزانه)
    usage_count INTEGER NOT NULL DEFAULT 0,
    last_reset_date DATE, -- برای daily usage - تاریخ آخرین ریست
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- هر کاربر فقط یک رکورد برای هر feature و usage_type می‌تواند داشته باشد
    UNIQUE(user_id, feature_name, usage_type)
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_user_feature_usage_user_id ON public.user_feature_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_user_feature_usage_feature ON public.user_feature_usage(feature_name);
CREATE INDEX IF NOT EXISTS idx_user_feature_usage_user_feature ON public.user_feature_usage(user_id, feature_name);
CREATE INDEX IF NOT EXISTS idx_user_feature_usage_last_reset ON public.user_feature_usage(last_reset_date);

-- Enable RLS
ALTER TABLE public.user_feature_usage ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid errors on re-run)
DROP POLICY IF EXISTS "Users can view their own feature usage" ON public.user_feature_usage;
DROP POLICY IF EXISTS "Users can insert their own feature usage" ON public.user_feature_usage;
DROP POLICY IF EXISTS "Users can update their own feature usage" ON public.user_feature_usage;
DROP POLICY IF EXISTS "Users can delete their own feature usage" ON public.user_feature_usage;

-- Create RLS policies
CREATE POLICY "Users can view their own feature usage" ON public.user_feature_usage
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own feature usage" ON public.user_feature_usage
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own feature usage" ON public.user_feature_usage
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own feature usage" ON public.user_feature_usage
    FOR DELETE USING (auth.uid() = user_id);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_user_feature_usage_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
DROP TRIGGER IF EXISTS update_user_feature_usage_updated_at ON public.user_feature_usage;
CREATE TRIGGER update_user_feature_usage_updated_at
    BEFORE UPDATE ON public.user_feature_usage
    FOR EACH ROW
    EXECUTE FUNCTION update_user_feature_usage_updated_at();

-- توضیحات:
-- این جدول استفاده کاربران از فیچرهای مختلف را ذخیره می‌کند
-- 
-- feature_name: نام فیچر
--   - 'progress_analysis': تحلیل پیشرفت (لیمیت کل: 3 بار)
--   - 'ai_chat': چت با هوش مصنوعی (لیمیت روزانه: 10 پیام)
--
-- usage_type: نوع استفاده
--   - 'total': استفاده کل (برای progress_analysis)
--   - 'daily': استفاده روزانه (برای ai_chat)
--
-- مزایای ذخیره در دیتابیس:
--   - حفظ داده‌ها حتی بعد از پاک کردن اپلیکیشن
--   - همگام‌سازی بین چند دستگاه
--   - امکان مدیریت از سمت سرور
--   - جلوگیری از تقلب (ریست دستی)
