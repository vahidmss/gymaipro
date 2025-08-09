-- ایجاد جدول ثبت وزن هفتگی
CREATE TABLE IF NOT EXISTS public.weekly_weight_records (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    weight DECIMAL(5,2) NOT NULL CHECK (weight > 0 AND weight < 1000),
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    week_number INTEGER NOT NULL,
    year INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ایجاد ایندکس برای جستجوی سریع
CREATE INDEX IF NOT EXISTS idx_weekly_weight_user_id ON public.weekly_weight_records(user_id);
CREATE INDEX IF NOT EXISTS idx_weekly_weight_recorded_at ON public.weekly_weight_records(recorded_at);
CREATE INDEX IF NOT EXISTS idx_weekly_weight_week_year ON public.weekly_weight_records(week_number, year);

-- ایجاد RLS (Row Level Security)
ALTER TABLE public.weekly_weight_records ENABLE ROW LEVEL SECURITY;

-- سیاست‌های امنیتی
CREATE POLICY "Users can view their own weekly weight records" ON public.weekly_weight_records
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own weekly weight records" ON public.weekly_weight_records
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own weekly weight records" ON public.weekly_weight_records
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own weekly weight records" ON public.weekly_weight_records
    FOR DELETE USING (auth.uid() = user_id);

-- تابع برای به‌روزرسانی خودکار updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- تریگر برای به‌روزرسانی خودکار updated_at
CREATE TRIGGER update_weekly_weight_records_updated_at 
    BEFORE UPDATE ON public.weekly_weight_records 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column(); 