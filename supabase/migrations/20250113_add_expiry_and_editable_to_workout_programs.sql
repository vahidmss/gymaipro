-- افزودن ستون‌های expiry_date و editable_until به جدول workout_programs

-- افزودن ستون expiry_date (33 روز از تاریخ ساخت)
ALTER TABLE public.workout_programs
ADD COLUMN IF NOT EXISTS expiry_date TIMESTAMPTZ;

-- افزودن ستون editable_until (3 روز از تاریخ ساخت - تا این تاریخ مربی می‌تواند ادیت کند)
ALTER TABLE public.workout_programs
ADD COLUMN IF NOT EXISTS editable_until TIMESTAMPTZ;

-- ایجاد ایندکس برای بهبود عملکرد جستجو
CREATE INDEX IF NOT EXISTS idx_workout_programs_expiry_date ON public.workout_programs(expiry_date);
CREATE INDEX IF NOT EXISTS idx_workout_programs_editable_until ON public.workout_programs(editable_until);

