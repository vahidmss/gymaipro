-- هستهٔ متای تمرینی برای تمرین‌های اختصاصی (هم‌تراز کاتالوگ / pop20)
alter table public.custom_exercises
  add column if not exists met numeric(4, 1),
  add column if not exists typical_rpe numeric(3, 1),
  add column if not exists movement_pattern text,
  add column if not exists body_engagement text,
  add column if not exists mechanics_type text,
  add column if not exists force_type text,
  add column if not exists calories_per_1000kg integer;

comment on column public.custom_exercises.met is 'MET — متابولیک معادل تمرین';
comment on column public.custom_exercises.typical_rpe is 'RPE معمول حرکت';
comment on column public.custom_exercises.movement_pattern is 'الگوی حرکت (مثلاً squat, hinge)';
comment on column public.custom_exercises.body_engagement is 'compound / isolation';
comment on column public.custom_exercises.mechanics_type is 'mechanics_type';
comment on column public.custom_exercises.force_type is 'push / pull / static';
comment on column public.custom_exercises.calories_per_1000kg is 'کالری تقریبی به‌ازای ۱۰۰۰ کیلوگرم جابه‌جایی';
