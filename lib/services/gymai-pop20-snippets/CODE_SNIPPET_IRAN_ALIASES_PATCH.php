// GymAI — Alias enrichment for existing exercises (Iran gym vernacular)
// Code Snippets: Run everywhere | بدون تگ php
// ابزارها → GymAI Exercises → دکمه «بروزرسانی نام‌های جایگزین»

if (!function_exists('gymai_pop20_iran_alias_patch_map')) {
function gymai_pop20_iran_alias_patch_map() {
    return array(
        'پرس-سینه-شیب-دار' => array('پرس بالاسینه', 'پرس بالا سینه', 'بالاسینه', 'بنچ پرس بالاسینه', 'پرس سینه بالا', 'Incline Bench', 'پرس شیب هالتر'),
        'پرس-سینه-مایل-دمبل' => array('پرس بالاسینه دمبل', 'پرس بالا سینه دمبل', 'بالاسینه دمبل', 'Incline DB Press'),
        'پرس-سینه-دمبل-شیب' => array('پرس بالاسینه دمبل', 'بالاسینه دمبل', 'پرس شیب دمبل'),
        'پرس-سینه-شیب-منفی' => array('پرس زیرسینه', 'پرس پایین سینه', 'Decline Bench', 'زیرسینه هالتر'),
        'پرس-سینه-با-هالتر' => array('بنچ پرس', 'Bench Press', 'پرس سینه هالتر', 'پرس تخت'),
        'پرس-سینه-با-دمبل' => array('پرس دمبل تخت', 'بنچ دمبل', 'Flat DB Press'),
        'زیربغل-سیمکش' => array('لت پولداون', 'لت پول دان', 'لت پول', 'لت پالدان', 'لت سیکمش', 'لت سیکش', 'لت پولداون جلو', 'لت سیکمش جلو', 'لت سیکش جلو', 'لت پول جلو', 'Lat Pulldown', 'پول‌داون', 'زیربغل لت', 'پولدان'),
        'زیربغل-سیم-کش-دست-باز' => array('لت پولداون دست باز', 'لت دست باز', 'Wide Grip Pulldown', 'لت پولدان عریض', 'لت پولداون جلو دست باز'),
        'زیربغل-دست-جمع' => array('لت پولداون دست جمع', 'لت وی بار', 'Close Grip Pulldown', 'پولداون دست جمع'),
        'اکستنشن-پا' => array('جلو پا', 'جلو پا دستگاه', 'لگ اکستنشن', 'Leg Extension', 'اکستنشن چهارسر', 'جلوپا'),
        'پشت-پا-خوابیده' => array('لگ کرل', 'لگ کرل خوابیده', 'Lying Leg Curl', 'همسترینگ کرل', 'پشت پا خوابیده دستگاه'),
        'پشت-پا-نشسته-دستگاه' => array('لگ کرل نشسته', 'Seated Leg Curl'),
        'پشت-پا-دستگاه' => array('لگ کرل', 'Leg Curl'),
        'پاروی-صورت' => array('فیس پول', 'فیس‌پول', 'Face Pull', 'فیس پول طناب', 'فیس پول سیمکش'),
        'هاک-اسکات' => array('هک اسکات', 'اسکات هک', 'Hack Squat', 'هک'),
        'نشر-از-جلو' => array('نشر جلو', 'Front Raise', 'فرانت ریز', 'نشر جلو دمبل', 'نشر جلو هالتر'),
        'نشر-پشت-دمبل' => array('نشر خم', 'نشر خم دمبل', 'ریورس فلای دمبل', 'Bent Over Reverse Fly'),
        'فلای-پک-دستگاه' => array('پک دک', 'پکدک', 'Pec Deck', 'پروانه‌ای', 'فلای دستگاه', 'پک دک سینه'),
        'کراس-سیمکش' => array('کراس اور', 'کراس‌اور', 'Cable Crossover', 'کراس اوور'),
        'فلای-اینکلاین-دمبل' => array('قفسه بالاسینه', 'فلای بالاسینه', 'قفسه شیب', 'Incline Fly'),
        'کول-هالتر' => array('آپرایت رو هالتر', 'Upright Row Barbell', 'کول هالتر', 'Upright Row'),
        'کتله-بل-سوینگ' => array('کتل بل سوینگ', 'کتل‌بل سوینگ', 'Kettlebell Swing', 'سوئینگ کتل بل', 'سوینگ کتل'),
        'بورپی' => array('برپی', 'Burpee'),
        'کوهنورد' => array('مانتین کلایمبر', 'Mountain Climber'),
        'چرخش-روسی' => array('توئیست روسی', 'Russian Twist'),
        'شراگ-دمبل' => array('کول دمبل شراگ', 'Dumbbell Shrug'),
        'لگ-پرس' => array('پرس پا', 'Leg Press', 'لگ پرس دستگاه'),
        'پرس-پا-دستگاه' => array('لگ پرس', 'پرس پا', 'Leg Press'),
    );
}
}

if (!function_exists('gymai_pop20_apply_iran_alias_patch')) {
function gymai_pop20_apply_iran_alias_patch() {
    $ptype = defined('GYMAI_EXERCISE_POST_TYPE') ? GYMAI_EXERCISE_POST_TYPE : 'exercises';
    if (!post_type_exists($ptype)) {
        return array('updated' => 0, 'skipped' => 0, 'created' => 0, 'errors' => array('CPT تمرین پیدا نشد'), 'touched_ids' => array());
    }
    $map = gymai_pop20_iran_alias_patch_map();
    $updated = 0;
    $skipped = 0;
    $errors = array();
    $touched = array();
    foreach ($map as $slug => $extra) {
        $post = get_page_by_path($slug, OBJECT, $ptype);
        if (!$post) {
            $skipped++;
            $errors[] = 'پیدا نشد: ' . $slug;
            continue;
        }
        $current = get_post_meta($post->ID, 'other_names', true);
        if (!is_array($current)) {
            $current = array_filter(array_map('trim', preg_split('/[,\n]+/', (string) $current)));
        }
        $merged = array_values(array_unique(array_filter(array_merge($current, $extra))));
        update_post_meta($post->ID, 'other_names', $merged);
        $touched[] = (int) $post->ID;
        $updated++;
    }
    return array('updated' => $updated, 'skipped' => $skipped, 'created' => 0, 'errors' => $errors, 'touched_ids' => $touched);
}
}
