-- =============================================================================
-- اصلاح main_muscle غلط در ai_exercises (بر اساس نام حرکت)
-- مشکل رایج: پرس سینه / پرس سرشانه به‌اشتباه triceps؛ جلوبازو به‌اشتباه back_lat
-- اجرا در Supabase SQL Editor
-- =============================================================================

BEGIN;

UPDATE public.ai_exercises
SET
  main_muscle = CASE
    -- سینه
    WHEN name ~* '(پرس سینه|بالا سینه|بالاسینه|بنچ|Bench Press)' THEN 'chest'
    WHEN name ~* '(قفسه سینه|کراس.?اور|Crossover|فلای سینه|پک دک|Pec Deck)' THEN 'chest'
    WHEN name ~* '(شنا سوئدی|شنای سوئدی|Push.?Up)' THEN 'chest'
    WHEN name ~* '(پول.?اور|Pullover)' THEN 'chest'

    -- سرشانه
    WHEN name ~* '(پرس سرشانه|آرنولد|Overhead Press|Military Press)' THEN 'shoulder_anterior'
    WHEN name ~* '(نشر جانب|نشر از جانب|Lateral Raise)' THEN 'shoulder_lateral'
    WHEN name ~* '(نشر پشت|فیس.?پول|Face Pull|Rear Delt)' THEN 'shoulder_posterior'
    WHEN name ~* '(شراگ|کول هالتر|کول دمبل|Shrug)' THEN 'traps'

    -- بازو (قبل از «پشت» عمومی)
    WHEN name ~* '(جلو بازو|جلوبازو|Bicep|Curl)'
      AND name !~* '(پشت بازو|پشت‌بازو|Leg Curl|همستر)' THEN 'biceps'
    WHEN name ~* '(پشت بازو|پشت‌بازو|Triceps|کرشر|اسکال|Skull)' THEN 'triceps'
    WHEN name ~* '(دیپ|Dip)' AND name !~* '(سینه|Hip)' THEN 'triceps'

    -- پایین‌تنه
    WHEN name ~* '(هیپ.?تراست|پل باسن|Hip Thrust|Glute Bridge)' THEN 'glutes'
    WHEN name ~* '(پرس ساق|ساق پا|ساق ایستاده|ساق نشسته|ساق دونکی|Calf)' THEN 'calves'
    WHEN name ~* '(رومانیایی|پشت پا|همسترینگ|Nordic|Leg Curl)' THEN 'hamstrings'
    WHEN name ~* '(اسکوات|اسکات|پرس پا|جلو پا|لانج|لانگز|هک اسکوات|Squat|Lunge|Leg Press|Leg Extension)' THEN 'quads'

    -- پشت
    WHEN name ~* '(زیربغل|بارفیکس|لت.?پول|پول.?دان|رویینگ|قایقی|تی.?بار|Pulldown|Pull.?Up|Chin.?Up)'
      AND name !~* '(روئینگ|Rowing|بایک|Bike)' THEN 'back_lat'
    WHEN name ~* '(ددلیفت|Deadlift)' AND name !~* 'رومانیایی' THEN 'lower_back'
    WHEN name ~* 'Row' AND name !~* '(روئینگ|Rowing|بایک|Bike)' THEN 'back_lat'

    -- میان‌تنه / فول‌بادی
    WHEN name ~* '(چرخش روسی|ابلیک|Oblique|پهلو)' THEN 'obliques'
    WHEN name ~* '(کرانچ|پلانک|زیرشکم|Crunch|Plank|Leg Raise)' THEN 'abs'
    WHEN name ~* '(بورپی|برپی|فارمر|کلین|اسنچ|جرک|Burpee)' THEN 'full_body'

    ELSE main_muscle
  END,
  synced_at = now()
WHERE name ~* '(پرس سینه|بالا سینه|قفسه|کراس|شنا سوئدی|پول.?اور|پرس سرشانه|آرنولد|نشر|شراگ|کول |جلو بازو|جلوبازو|پشت بازو|دیپ|هیپ.?تراست|پل باسن|ساق|رومانیایی|پشت پا|همستر|اسکوات|اسکات|پرس پا|جلو پا|لانج|زیربغل|بارفیکس|لت|رویینگ|قایقی|ددلیفت|کرانچ|پلانک|چرخش روسی|بورپی|برپی|فارمر|کلین)';

-- نمونهٔ کنترل (اختیاری — در صورت نیاز uncomment)
-- SELECT id, name, main_muscle FROM public.ai_exercises
-- WHERE name ~* 'پرس سینه|پرس سرشانه|جلو بازو|هیپ تراست|پل باسن'
-- ORDER BY name;

COMMIT;
