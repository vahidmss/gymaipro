-- جدول weight_records
CREATE TABLE IF NOT EXISTS public.weight_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL,
    weight DECIMAL(5, 2) NOT NULL CHECK (weight > 0 AND weight < 500), -- وزن به کیلوگرم
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    notes TEXT,  -- یادداشت های اضافی
    CONSTRAINT fk_profile
      FOREIGN KEY(profile_id) 
      REFERENCES public.profiles(id)
      ON DELETE CASCADE
);

-- شاخص‌ها
CREATE INDEX IF NOT EXISTS weight_records_profile_id_idx ON public.weight_records (profile_id);
CREATE INDEX IF NOT EXISTS weight_records_recorded_at_idx ON public.weight_records (recorded_at);

-- سیاست‌های امنیتی (RLS)
ALTER TABLE public.weight_records ENABLE ROW LEVEL SECURITY;

-- حذف سیاست‌های موجود در صورت وجود
DROP POLICY IF EXISTS "Users can view their own weight records" ON public.weight_records;
DROP POLICY IF EXISTS "Users can insert their own weight records" ON public.weight_records;
DROP POLICY IF EXISTS "Users can update their own weight records" ON public.weight_records;
DROP POLICY IF EXISTS "Users can delete their own weight records" ON public.weight_records;

-- سیاست دسترسی عمومی برای مشاهده رکوردهای وزن
CREATE POLICY "Users can view their own weight records"
  ON public.weight_records
  FOR SELECT
  USING (auth.uid() = profile_id);

-- سیاست دسترسی عمومی برای درج رکوردهای وزن
CREATE POLICY "Users can insert their own weight records"
  ON public.weight_records
  FOR INSERT
  WITH CHECK (auth.uid() = profile_id);

-- سیاست دسترسی عمومی برای بروزرسانی رکوردهای وزن
CREATE POLICY "Users can update their own weight records"
  ON public.weight_records
  FOR UPDATE
  USING (auth.uid() = profile_id);

-- سیاست دسترسی عمومی برای حذف رکوردهای وزن
CREATE POLICY "Users can delete their own weight records"
  ON public.weight_records
  FOR DELETE
  USING (auth.uid() = profile_id); 