-- جدول weight_records
CREATE TABLE IF NOT EXISTS public.weight_records (
    id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
    profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    weight numeric(5,2) NOT NULL,
    recorded_at timestamptz DEFAULT now() NOT NULL,
    created_at timestamptz DEFAULT now() NOT NULL
);

-- شاخص‌ها
CREATE INDEX IF NOT EXISTS weight_records_profile_id_idx ON public.weight_records (profile_id);
CREATE INDEX IF NOT EXISTS weight_records_recorded_at_idx ON public.weight_records (recorded_at);

-- سیاست‌های امنیتی (RLS)
ALTER TABLE public.weight_records ENABLE ROW LEVEL SECURITY;

-- سیاست دسترسی عمومی برای مشاهده رکوردهای وزن
CREATE POLICY "Users can view their own weight records"
  ON public.weight_records
  FOR SELECT
  USING (auth.uid() = profile_id);

-- سیاست دسترسی برای درج رکوردهای وزن جدید
CREATE POLICY "Users can insert their own weight records"
  ON public.weight_records
  FOR INSERT
  WITH CHECK (auth.uid() = profile_id);

-- سیاست دسترسی برای به‌روزرسانی رکوردهای وزن
CREATE POLICY "Users can update their own weight records"
  ON public.weight_records
  FOR UPDATE
  USING (auth.uid() = profile_id);

-- سیاست دسترسی برای حذف رکوردهای وزن
CREATE POLICY "Users can delete their own weight records"
  ON public.weight_records
  FOR DELETE
  USING (auth.uid() = profile_id); 