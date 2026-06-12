/**
 * GymAI — افزودن ۲۰ حرکت پرطرفدار
 * برای Code Snippets: این فایل را مستقیم نچسبانید — از CODE_SNIPPET_3_POPULAR_20.php یا پلاگین استفاده کنید.
 */

if (!defined('GYMAI_EXERCISE_POST_TYPE')) {
    define('GYMAI_EXERCISE_POST_TYPE', 'exercises');
}

if (!function_exists('gymai_pop20_exercise_url')) {
    function gymai_pop20_exercise_url($slug) {
        if (!function_exists('home_url')) {
            return '';
        }
        return home_url('/exercises/' . rawurlencode((string) $slug) . '/');
    }
}

if (!function_exists('gymai_pop20_resolve_combos')) {
    function gymai_pop20_resolve_combos(array $def) {
        if (empty($def['combos']) || !is_array($def['combos'])) {
            return $def;
        }
        foreach ($def['combos'] as $i => $combo) {
            if (!empty($combo['slug']) && empty($combo['url'])) {
                $def['combos'][$i]['url'] = gymai_pop20_exercise_url($combo['slug']);
            }
        }
        return $def;
    }
}

/** slugs موجود در دیتابیس — برای جلوگیری از تکرار با ۱۴ حرکت فعلی */
if (!function_exists('gymai_existing_exercise_slugs_blocklist')) {
function gymai_existing_exercise_slugs_blocklist() {
    return [
        'دیپ-پارالل',
        'هایپراکستنشن-فیله-کمر',
        'پلانک-plank',
        'پلانک',
        'پرس-پا-دستگاه',
        'جلوبازو-دمبل-نشسته',
        'زیربغل-سیمکش-دست-باز',
        'ددلیفت-رومانیایی',
        'زیربغل-هالتر-خمیده',
        'پرس-سینه-دستگاه',
        'پشت-پا-دستگاه',
        'پشت-بازو-سیمکش',
        'نشر-جانب-دمبل',
        'اسکات-هالتر',
        'پرس-سرشانه-دستگاه',
    ];
}
}

if (!function_exists('gymai_popular_20_meta_description')) {
function gymai_popular_20_meta_description($title, $tips_count, $mistakes_count, $sets, $reps, $extra = '') {
    $base = sprintf(
        'آموزش ۰ تا ۱۰۰ %s: تکنیک اجرا، %d نکته طلایی، %d اشتباه رایج، برنامه %s ست %s تکرار',
        $title,
        $tips_count,
        $mistakes_count,
        $sets,
        $reps
    );
    if ($extra !== '') {
        $base .= ' — ' . $extra;
    }
    return $base . '.';
}
}

if (!function_exists('gymai_render_popular_exercise_html')) {
function gymai_render_popular_exercise_html(array $ex) {
    $ex = gymai_pop20_resolve_combos($ex);
    $name = $ex['title'];
    $img = $ex['image'];
    $aliases = implode('، ', $ex['aliases']);

    $tips_html = '';
    foreach ($ex['tips'] as $i => $tip) {
        $tips_html .= '<li>' . esc_html($tip) . '</li>';
    }

    $setup_html = $execution_html = $mistakes_rows = $program_rows = $muscles_html = $combo_html = $faq_html = '';

    foreach ($ex['setup'] as $line) {
        $setup_html .= '<li>' . esc_html($line) . '</li>';
    }
    foreach ($ex['execution'] as $line) {
        $execution_html .= '<li>' . esc_html($line) . '</li>';
    }
    foreach ($ex['muscles'] as $line) {
        $muscles_html .= '<li>' . esc_html($line) . '</li>';
    }
    foreach ($ex['mistakes'] as $row) {
        $mistakes_rows .= '<tr><td>' . esc_html($row[0]) . '</td><td>' . esc_html($row[1]) . '</td></tr>';
    }
    foreach ($ex['program'] as $row) {
        $program_rows .= '<tr><td>' . esc_html($row[0]) . '</td><td>' . esc_html($row[1]) . '</td><td>' . esc_html($row[2]) . '</td><td>' . esc_html($row[3]) . '</td></tr>';
    }
    foreach ($ex['combos'] as $combo) {
        if (!empty($combo['url'])) {
            $combo_html .= '<li><strong>' . esc_html($combo['label']) . '</strong> <a href="' . esc_url($combo['url']) . '">' . esc_html($combo['link_text']) . '</a></li>';
        } else {
            $combo_html .= '<li>' . esc_html($combo['label']) . '</li>';
        }
    }
    foreach ($ex['faqs'] as $faq) {
        $faq_html .= '<h3>' . esc_html($faq['q']) . '</h3>' . esc_html($faq['a']);
    }

    $h1 = 'آموزش جامع ' . $name;

    return '<!-- آموزش سئو ' . esc_html($name) . ' - GymAI Pro -->
<h1>' . esc_html($h1) . '</h1>
<p>' . wp_kses_post($ex['intro']) . '</p>
<strong>🔹 نام‌های دیگر:</strong> ' . esc_html($aliases) . '
<figure class="wp-block-image"><img src="' . esc_url($img) . '" alt="' . esc_attr('اجرای صحیح ' . $name) . '" /><figcaption>' . esc_html($ex['caption']) . '</figcaption></figure>
<div class="wp-block-columns"><div class="wp-block-column"><div style="border-radius:10px;background:#f8f9fa;padding:15px;">
<h2>📊 اطلاعات سریع</h2><ul>
<li><strong>عضله اصلی:</strong> ' . esc_html($ex['quick']['main']) . '</li>
<li><strong>عضلات فرعی:</strong> ' . esc_html($ex['quick']['secondary']) . '</li>
<li><strong>سطح:</strong> ' . esc_html($ex['quick']['difficulty']) . '</li>
<li><strong>تجهیزات:</strong> ' . esc_html($ex['quick']['equipment']) . '</li>
<li><strong>نوع:</strong> ' . esc_html($ex['quick']['type']) . '</li>
</ul></div></div><div class="wp-block-column"><div style="border-radius:10px;background:#e8f4f8;padding:15px;">
<h2>💡 ' . count($ex['tips']) . ' نکته طلایی</h2><ol>' . $tips_html . '</ol></div></div></div>
<h2>تکنیک اجرا</h2><h3>آماده‌سازی</h3><ul>' . $setup_html . '</ul>
<h3>اجرای حرکت</h3><ul>' . $execution_html . '</ul>
<p><strong>تنفس:</strong> ' . esc_html($ex['breathing']) . '</p>
<h2>عضلات درگیر</h2><ul>' . $muscles_html . '</ul>
<h2>' . count($ex['mistakes']) . ' اشتباه رایج</h2>
<table class="wp-block-table"><thead><tr><th>اشتباه</th><th>راه‌حل</th></tr></thead><tbody>' . $mistakes_rows . '</tbody></table>
<h2>برنامه پیشنهادی</h2>
<table class="wp-block-table"><thead><tr><th>هدف</th><th>ست</th><th>تکرار</th><th>استراحت</th></tr></thead><tbody>' . $program_rows . '</tbody></table>
<h2>ترکیب با حرکات دیگر</h2><ul>' . $combo_html . '</ul>
<h2>سوالات متداول</h2><div style="border-radius:8px;background:#f0fdf4;padding:10px;">' . $faq_html . '</div>
<h2>جمع‌بندی</h2><p>' . esc_html($ex['summary']) . '</p>
<p>✅ <strong>خلاصه:</strong> ' . esc_html($ex['summary_keys']) . '</p>';
}
}

/**
 * @return array<int, array<string, mixed>>
 */
if (!function_exists('gymai_popular_20_exercise_definitions')) {
function gymai_popular_20_exercise_definitions() {
    $base_img = 'https://gymaipro.ir/wp-content/uploads/2026/06/';

    $defs = [];

    $add = function (array $row) use (&$defs, $base_img) {
        if (empty($row['image'])) {
            $key = !empty($row['image_key']) ? $row['image_key'] : ('exercise-' . (count($defs) + 1));
            $row['image'] = $base_img . $key . '.jpg';
        }
        $defs[] = $row;
    };

    $add([
        'slug' => 'پرس-سینه-با-دمبل',
        'title' => 'پرس سینه با دمبل',
        'aliases' => ['Dumbbell Bench Press', 'DB Chest Press', 'Flat Dumbbell Press', 'پرس دمبل تخت'],
        'intro' => '<strong>پرس سینه با دمبل</strong> یک حرکت فشار افقی مرکب برای رشد سینه است. دامنه حرکت بیشتر از هالتر و تمرین جداگانه هر طرف از مزایای اصلی آن است.',
        'caption' => 'پرس سینه با دمبل — کتف جمع و کنترل دامنه',
        'quick' => ['main' => 'سینه میانی و بالایی', 'secondary' => 'پشت بازو، سرشانه قدامی', 'difficulty' => 'متوسط', 'equipment' => 'دمبل، نیمکت تخت', 'type' => 'قدرتی / حجمی'],
        'tips' => ['کتف‌ها جمع و پایین.', 'آرنج حدود ۴۵–۶۰ درجه.', 'در بالا انقباض سینه؛ آرنج قفل نشود.'],
        'setup' => ['روی نیمکت تخت، پا روی زمین.', 'دمبل کنار سینه.', 'کتف جمع، شکم سفت.'],
        'execution' => ['با دم پایین آوردن کنترل‌شده.', 'تا کنار سینه.', 'با بازدم فشار به بالا.', 'دمبل‌ها نزدیک در بالا.'],
        'breathing' => 'دم در پایین — بازدم در بالا.',
        'muscles' => ['اصلی: سینه بزرگ (میانی/بالایی)', 'کمکی: تریسپس، دلتوئید قدامی', 'تثبیت: Core و ساعد'],
        'mistakes' => [['آرنج بیش از حد باز', 'زاویه ۴۵–۶۰°'], ['تاب دادن دمبل', 'کاهش وزنه'], ['کتف شل', 'جمع کردن قبل از هر تکرار']],
        'program' => [['حجم', '۳–۴', '۸–۱۲', '۶۰–۹۰ث'], ['قدرت', '۴–۵', '۳–۶', '۹۰–۱۵۰ث'], ['استقامت', '۲–۳', '۱۲–۲۰', '۴۵–۶۰ث']],
        'combos' => [['label' => 'سوپرسِت: ', 'link_text' => 'پرس سینه دستگاه', 'slug' => 'پرس-سینه-دستگاه']],
        'faqs' => [['q' => 'دمبل بهتر است یا هالتر؟', 'a' => 'هر دو مفیدند؛ دمبل برای دامنه و تعادل، هالتر برای بار سنگین‌تر.']],
        'summary' => 'پرس سینه با دمبل ستون تمرین سینه برای حجم و تعادل عضلانی است.',
        'summary_keys' => 'کتف جمع | دامنه کنترل‌شده | انقباض در بالا',
        'meta' => [
            'main_muscle' => 'chest', 'secondary_muscle_keys' => ['triceps', 'shoulder_anterior'],
            'difficulty' => 'intermediate', 'equipment_keys' => ['dumbbell', 'bench'],
            'exercise_type' => 'strength', 'movement_pattern' => 'horizontal_push', 'body_engagement' => 'compound',
            'mechanics_type' => 'compound', 'force_type' => 'push', 'plane_of_motion' => 'sagittal', 'laterality' => 'bilateral',
            'posture' => 'lying_supine', 'grip_type' => 'neutral', 'resistance_profile' => 'free_weight', 'joint_focus' => 'shoulder_elbow',
            'muscle_targets' => ['chest_middle' => 90, 'chest' => 80, 'chest_upper' => 50, 'triceps' => 45, 'shoulder_anterior' => 40],
            'met' => 6, 'movement_distance_cm' => 40, 'calories_per_1000kg' => 40, 'exercise_difficulty_score' => 4, 'typical_rpe' => 7,
            'estimated_1rm_formula' => 'brzycki', 'programming_goal' => 'hypertrophy', 'recommended_sets' => '3-4',
            'rep_range_strength' => '3-6', 'rep_range_hypertrophy' => '8-12', 'rep_range_endurance' => '12-20', 'rest_seconds' => 90, 'tempo' => '2-1-2',
            'short_description' => 'پرس سینه با دمبل حرکت مرکب فشار افقی برای سینه، پشت بازو و سرشانه قدامی با دامنه حرکت بیشتر از هالتر.',
            'target_area' => 'سینه میانی و بالایی',
        ],
        'rank_extra' => 'مناسب هایپرتروفی و اصلاح عدم تقارن.',
    ]);

    $add([
        'slug' => 'پرس-سینه-با-هالتر',
        'title' => 'پرس سینه با هالتر',
        'aliases' => ['Barbell Bench Press', 'Bench Press', 'Flat Bench Press', 'بنچ پرس'],
        'intro' => '<strong>پرس سینه با هالتر</strong> (بنچ پرس) یکی از اصلی‌ترین حرکات بدنسازی برای قدرت و حجم سینه است و در پاورلیفتینگ نیز جزو حرکات پایه محسوب می‌شود.',
        'caption' => 'پرس سینه با هالتر روی نیمکت تخت',
        'quick' => ['main' => 'سینه', 'secondary' => 'پشت بازو، سرشانه قدامی', 'difficulty' => 'متوسط', 'equipment' => 'هالتر، نیمکت، رک', 'type' => 'قدرتی / حجمی'],
        'tips' => ['پا محکم روی زمین.', 'میله روی خط نیپل یا کمی پایین‌تر.', 'اسپاتر برای بار سنگین.'],
        'setup' => ['درازکش روی نیمکت، چشمان زیر میله.', 'گرفتن میله عرض شانه یا کمی بازتر.', 'کتف جمع، قوس طبیعی کمر.'],
        'execution' => ['با دم میله به سینه.', 'لمس سبک یا نزدیک سینه.', 'با بازدم فشار به بالا.', 'آرنج نرم در بالا.'],
        'breathing' => 'دم پایین — بازدم بالا؛ قبل از تکرار سنگین نفس حبس کوتاه مجاز است.',
        'muscles' => ['اصلی: سینه بزرگ', 'کمکی: تریسپس، دلتوئید قدامی', 'تثبیت: پا، Core، کتف'],
        'mistakes' => [['پا روی نیمکت', 'پا روی زمین'], ['میله روی گردن', 'خط سینه/نیپل'], ['بouncing روی سینه', 'کنترل تمپو']],
        'program' => [['حجم', '۳–۵', '۶–۱۲', '۹۰ث'], ['قدرت', '۴–۶', '۱–۵', '۱۸۰–۳۰۰ث'], ['استقامت', '۳', '۱۲–۱۵', '۶۰ث']],
        'combos' => [['label' => 'بعد از بنچ: ', 'link_text' => 'فلای دمبل', 'slug' => 'فلای-دمبل']],
        'faqs' => [['q' => 'عرض گرفتن میله؟', 'a' => 'معمولاً کمی بازتر از شانه؛ گریپ باریک‌تر پشت بازو بیشتر درگیر می‌کند.']],
        'summary' => 'بنچ پرس برای قدرت مطلق بالاتنه و حجم سینه بی‌نظیر است.',
        'summary_keys' => 'کتف پایین | خط میله صحیح | اسپات امن',
        'meta' => [
            'main_muscle' => 'chest', 'secondary_muscle_keys' => ['triceps', 'shoulder_anterior'],
            'difficulty' => 'intermediate', 'equipment_keys' => ['barbell', 'bench'],
            'exercise_type' => 'strength', 'movement_pattern' => 'horizontal_push', 'body_engagement' => 'compound',
            'mechanics_type' => 'compound', 'force_type' => 'push', 'plane_of_motion' => 'sagittal', 'laterality' => 'bilateral',
            'posture' => 'lying_supine', 'grip_type' => 'pronated', 'resistance_profile' => 'free_weight', 'joint_focus' => 'shoulder_elbow',
            'muscle_targets' => ['chest_middle' => 95, 'chest' => 90, 'triceps' => 50, 'shoulder_anterior' => 45, 'chest_lower' => 40],
            'met' => 6, 'movement_distance_cm' => 45, 'calories_per_1000kg' => 45, 'exercise_difficulty_score' => 5, 'typical_rpe' => 8,
            'estimated_1rm_formula' => 'brzycki', 'programming_goal' => 'strength', 'recommended_sets' => '3-5',
            'rep_range_strength' => '3-6', 'rep_range_hypertrophy' => '6-12', 'rep_range_endurance' => '12-15', 'rest_seconds' => 120, 'tempo' => '2-1-2',
            'short_description' => 'پرس سینه با هالتر (بنچ پرس) حرکت پایه برای قدرت و حجم سینه، پشت بازو و سرشانه قدامی.',
            'target_area' => 'سینه',
        ],
        'rank_extra' => 'حرکت پایه پاورلیفتینگ و بدنسازی.',
    ]);

    $add([
        'slug' => 'پرس-سرشانه-با-هالتر',
        'title' => 'پرس سرشانه با هالتر',
        'aliases' => ['Overhead Press', 'Military Press', 'OHP', 'Barbell Shoulder Press', 'پرس نظامی'],
        'intro' => '<strong>پرس سرشانه با هالتر</strong> بهترین حرکت compound برای قدرت و حجم سرشانه و پشت بازو است؛ ایستاده یا نشسته قابل اجراست.',
        'caption' => 'پرس سرشانه با هالتر — Core سفت و میله عمودی',
        'quick' => ['main' => 'سرشانه (قدامی/میانی)', 'secondary' => 'پشت بازو، ذوزنقه', 'difficulty' => 'متوسط', 'equipment' => 'هالتر', 'type' => 'قدرتی'],
        'tips' => ['کمر و Core سفت.', 'سر میله زیر چانه، سپس بالای سر.', 'چانه عقب در مسیر میله.'],
        'setup' => ['هالتر روی کلاویکل یا جلو سرشانه.', 'گرفتن کمی بازتر از شانه.', 'پا عرض لگن، زانو نرم.'],
        'execution' => ['با بازدم فشار عمودی.', 'سر کمی عقب برای عبور میله.', 'بالای سر، میله روی خط گوش.', 'با دم پایین کنترل‌شده.'],
        'breathing' => 'بازدم در فشار — دم در پایین.',
        'muscles' => ['اصلی: دلتوئید قدامی و میانی', 'کمکی: تریسپس، تراپس بالایی', 'تثبیت: Core و باسن'],
        'mistakes' => [['قوس بیش از حد کمر', 'سفت کردن Core'], ['پرس جلو بدن', 'مسیر عمودی'], ['قفل سخت آرنج', 'آرنج نرم']],
        'program' => [['حجم', '۳–۴', '۶–۱۰', '۹۰–۱۲۰ث'], ['قدرت', '۴–۵', '۳–۵', '۱۵۰–۱۸۰ث'], ['استقامت', '۳', '۱۰–۱۵', '۶۰ث']],
        'combos' => [['label' => 'بعد از OHP: ', 'link_text' => 'نشر جانب دمبل', 'slug' => 'نشر-جانب-دمبل']],
        'faqs' => [['q' => 'ایستاده یا نشسته؟', 'a' => 'ایستاده Core بیشتر؛ نشسته تمرکز روی سرشانه با ثبات بیشتر.']],
        'summary' => 'پرس سرشانه با هالتر ستون تمرین سرشانه برای قدرت واقعی.',
        'summary_keys' => 'Core سفت | مسیر عمودی | دامنه کامل',
        'meta' => [
            'main_muscle' => 'shoulder_anterior', 'secondary_muscle_keys' => ['shoulder_lateral', 'triceps', 'traps_upper'],
            'difficulty' => 'intermediate', 'equipment_keys' => ['barbell'],
            'exercise_type' => 'strength', 'movement_pattern' => 'vertical_push', 'body_engagement' => 'compound',
            'mechanics_type' => 'compound', 'force_type' => 'push', 'plane_of_motion' => 'sagittal', 'laterality' => 'bilateral',
            'posture' => 'standing', 'grip_type' => 'pronated', 'resistance_profile' => 'free_weight', 'joint_focus' => 'shoulder_elbow',
            'muscle_targets' => ['shoulder_anterior' => 90, 'shoulder_lateral' => 75, 'triceps' => 50, 'traps_upper' => 35, 'abs' => 25],
            'met' => 5.5, 'movement_distance_cm' => 50, 'calories_per_1000kg' => 48, 'exercise_difficulty_score' => 6, 'typical_rpe' => 8,
            'estimated_1rm_formula' => 'brzycki', 'programming_goal' => 'strength', 'recommended_sets' => '3-5',
            'rep_range_strength' => '3-6', 'rep_range_hypertrophy' => '6-10', 'rep_range_endurance' => '10-15', 'rest_seconds' => 120, 'tempo' => '2-0-2',
            'short_description' => 'پرس سرشانه با هالتر حرکت مرکب فشار عمودی برای سرشانه، پشت بازو و Core.',
            'target_area' => 'سرشانه',
        ],
        'rank_extra' => 'قدرت واقعی سرشانه و بالاتنه.',
    ]);

    $add([
        'slug' => 'بارفیکس',
        'title' => 'بارفیکس',
        'aliases' => ['Pull-Up', 'Chin-Up', 'Wide Grip Pull-Up', 'بارفیکس دست باز', 'کشش عمودی'],
        'intro' => '<strong>بارفیکس</strong> یک حرکت کشش عمودی با وزن بدن برای ساخت پشت پهن، قدرت گرفتن و جلوبازو است.',
        'caption' => 'بارفیکس — کتف پایین و چانه بالای میله',
        'quick' => ['main' => 'زیربغل (لات)', 'secondary' => 'جلوبازو، ذوزنقه، پشت بازو', 'difficulty' => 'متوسط', 'equipment' => 'میله بارفیکس', 'type' => 'قدرتی / حجمی'],
        'tips' => ['کتف را پایین و جمع کنید.', 'شروع از آویزان فعال.', 'بدون تاب بدن.'],
        'setup' => ['گرفتن میله کمی بازتر از شانه.', 'آویزان با شانه فعال.', 'Core سفت.'],
        'execution' => ['کشش با آرنج به پایین.', 'چانه بالای میله یا سینه نزدیک.', 'بازگشت آهسته تا آویزان کامل.'],
        'breathing' => 'بازدم در بالا — دم در پایین.',
        'muscles' => ['اصلی: لاتسیموس dorsi', 'کمکی: بiceps، رomboids، ترaps', 'تثبیت: Core و ساعد'],
        'mistakes' => [['تاب خوردن', 'کنترل تمپو'], ['شانه به گوش', 'کتف پایین'], ['نیمه دامنه', 'آویزان کامل']],
        'program' => [['حجم', '۳–۴', '۶–۱۲', '۹۰ث'], ['قدرت', '۴–۵', '۳–۶', '۱۲۰–۱۸۰ث'], ['استقامت', '۳', 'تا ناتوانی', '۶۰ث']],
        'combos' => [['label' => 'بعد از بارفیکس: ', 'link_text' => 'زیربغل سیمکش', 'slug' => 'زیربغل-سیمکش-دست-باز']],
        'faqs' => [['q' => 'بارفیکس سخت است؛ چه کنم؟', 'a' => 'کش کمکی، بارفیکس منفی یا دستگاه گرavity تا قدرت کافی.']],
        'summary' => 'بارفیکس یکی از بهترین حرکات وزن بدن برای پشت است.',
        'summary_keys' => 'کتف فعال | بدون تاب | دامنه کامل',
        'meta' => [
            'main_muscle' => 'back_lat', 'secondary_muscle_keys' => ['biceps', 'traps', 'shoulder_posterior'],
            'difficulty' => 'intermediate', 'equipment_keys' => ['pullup_bar'],
            'exercise_type' => 'strength', 'movement_pattern' => 'vertical_pull', 'body_engagement' => 'compound',
            'mechanics_type' => 'compound', 'force_type' => 'pull', 'plane_of_motion' => 'sagittal', 'laterality' => 'bilateral',
            'posture' => 'hanging', 'grip_type' => 'pronated', 'resistance_profile' => 'bodyweight', 'joint_focus' => 'shoulder_elbow',
            'muscle_targets' => ['back_lat' => 95, 'biceps' => 45, 'traps_upper' => 40, 'shoulder_posterior' => 30, 'forearms' => 35],
            'met' => 5, 'movement_distance_cm' => 55, 'calories_per_1000kg' => 50, 'exercise_difficulty_score' => 6, 'typical_rpe' => 8,
            'estimated_1rm_formula' => '', 'programming_goal' => 'hypertrophy', 'recommended_sets' => '3-5',
            'rep_range_strength' => '3-6', 'rep_range_hypertrophy' => '6-12', 'rep_range_endurance' => '10-20', 'rest_seconds' => 120, 'tempo' => '2-1-2',
            'short_description' => 'بارفیکس حرکت کشش عمودی با وزن بدن برای زیربغل، جلوبازو و پشت.',
            'target_area' => 'زیربغل و پشت',
        ],
        'rank_extra' => 'ساخت پشت پهن با وزن بدن.',
    ]);

    $add([
        'slug' => 'شنا-سوئدی',
        'title' => 'شنا سوئدی',
        'aliases' => ['Push-Up', 'Press-Up', 'شنا', 'شنا روی زمین'],
        'intro' => '<strong>شنا سوئدی</strong> حرکت فشار افقی با وزن بدن برای سینه، پشت بازو و Core؛ در هر جایی قابل اجراست.',
        'caption' => 'شنا سوئدی با خط بدن صاف',
        'quick' => ['main' => 'سینه', 'secondary' => 'پشت بازو، سرشانه، Core', 'difficulty' => 'مبتدی', 'equipment' => 'بدون تجهیزات', 'type' => 'قدرتی / استقامتی'],
        'tips' => ['خط بدن از سر تا پاشنه.', 'کتف جمع.', 'آرنج ۴۵ درجه نسبت به بدن.'],
        'setup' => ['دست‌ها کمی بازتر از شانه.', 'انگشتان جلو.', 'Core و باسن سفت.'],
        'execution' => ['با دم پایین تا سینه نزدیک زمین.', 'با بازدم بالا.', 'بدون افتادگی کمر.'],
        'breathing' => 'دم پایین — بازدم بالا.',
        'muscles' => ['اصلی: سینه', 'کمکی: تریسپس، دلتوئید قدامی', 'تثبیت: شکم و باسن'],
        'mistakes' => [['کمر افتاده', 'سفت کردن Core'], ['آرنج باز ۹۰°', 'زاویه ۴۵°'], ['سر آویزان', 'گردن خنثی']],
        'program' => [['حجم', '۳–۴', '۸–۲۰', '۴۵–۶۰ث'], ['استقامت', '۳–۵', '۱۵–۳۰', '۳۰–۴۵ث'], ['قدرت', '۴', '۵–۱۰', '۶۰–۹۰ث']],
        'combos' => [['label' => 'سوپرسِت: ', 'link_text' => 'دیپ پارالل', 'slug' => 'دیپ-پارالل']],
        'faqs' => [['q' => 'چند بار در هفته؟', 'a' => '۲–۴ بار بسته به شدت؛ برای مبتدی هر روز سبک هم ممکن است.']],
        'summary' => 'شنا پایه‌ای‌ترین حرکت فشار برای سینه بدون تجهیزات.',
        'summary_keys' => 'خط بدن صاف | Core سفت | دامنه کامل',
        'meta' => [
            'main_muscle' => 'chest', 'secondary_muscle_keys' => ['triceps', 'shoulder_anterior', 'abs'],
            'difficulty' => 'beginner', 'equipment_keys' => ['bodyweight'],
            'exercise_type' => 'strength', 'movement_pattern' => 'horizontal_push', 'body_engagement' => 'compound',
            'mechanics_type' => 'compound', 'force_type' => 'push', 'plane_of_motion' => 'sagittal', 'laterality' => 'bilateral',
            'posture' => 'lying_prone', 'grip_type' => 'neutral', 'resistance_profile' => 'bodyweight', 'joint_focus' => 'shoulder_elbow',
            'muscle_targets' => ['chest_middle' => 85, 'chest' => 80, 'triceps' => 50, 'shoulder_anterior' => 40, 'abs' => 35],
            'met' => 4, 'movement_distance_cm' => 35, 'calories_per_1000kg' => 35, 'exercise_difficulty_score' => 3, 'typical_rpe' => 6,
            'estimated_1rm_formula' => '', 'programming_goal' => 'endurance', 'recommended_sets' => '3-4',
            'rep_range_strength' => '6-10', 'rep_range_hypertrophy' => '8-15', 'rep_range_endurance' => '15-30', 'rest_seconds' => 60, 'tempo' => '2-1-2',
            'short_description' => 'شنا سوئدی حرکت فشار افقی با وزن بدن برای سینه، پشت بازو و Core.',
            'target_area' => 'سینه',
        ],
        'rank_extra' => 'تمرین سینه در خانه بدون وسیله.',
    ]);

    $add([
        'slug' => 'ددلیفت',
        'title' => 'ددلیفت',
        'aliases' => ['Deadlift', 'Conventional Deadlift', 'Barbell Deadlift', 'ددلیفت کلاسیک'],
        'intro' => '<strong>ددلیفت</strong> حرکت هیپ‌هینج با هالتر برای قدرت کل بدن؛ همسترینگ، باسن، کمر و Core به‌شدت درگیر می‌شوند.',
        'caption' => 'ددلیفت — کمر خنثی و میله نزدیک پا',
        'quick' => ['main' => 'همسترینگ و باسن', 'secondary' => 'کمر، ساعد، چهارسر', 'difficulty' => 'پیشرفته', 'equipment' => 'هالتر', 'type' => 'قدرتی'],
        'tips' => ['میله روی پا نزدیک ساق.', 'کمر خنثی؛ قفسه بالا.', 'فشار از زمین با پا، نه کمر.'],
        'setup' => ['پا عرض لگن، میله روی میانی پا.', 'گرفتن mixed یا دوبل اورهند.', 'کتف روی میله، Core سفت.'],
        'execution' => ['باسن عقب، زانو خم.', 'کشش میله کنار پا.', 'ایستادن کامل با باسن جلو.', 'پایین با کنترل همان مسیر.'],
        'breathing' => 'نفس حبس قبل از کشش — بازدم در بالا یا بعد از عبور زانو.',
        'muscles' => ['اصلی: همسترینگ، گلوت', 'کمکی: erector spinae، تراپس', 'تثبیت: Core، ساعد'],
        'mistakes' => [['گرد شدن کمر', 'کتف جمع، میله نزدیک'], ['میله دور از پا', 'کشش عمودی نزدیک ساق'], ['کشش با کمر', 'فشار پا به زمین']],
        'program' => [['قدرت', '۳–۵', '۱–۵', '۳–۵ دقیقه'], ['حجم', '۳–۴', '۵–۸', '۱۸۰–۲۴۰ث'], ['تکنیک', '۳', '۵', '۱۲۰ث']],
        'combos' => [['label' => 'روز پا: بعد از ', 'link_text' => 'اسکات هالتر', 'slug' => 'اسکات-هالتر']],
        'faqs' => [['q' => 'RDL با ددلیفت فرق؟', 'a' => 'ددلیفت از زمین با زانوی بیشتر؛ RDL از ایستاده با زانوی ثابت‌تر و تمرکز همسترینگ.']],
        'summary' => 'ددلیفت پادشاه حرکات قدرتی برای کل زنجیره خلفی.',
        'summary_keys' => 'کمر خنثی | میله نزدیک | فشار پا',
        'meta' => [
            'main_muscle' => 'hamstrings', 'secondary_muscle_keys' => ['glutes', 'lower_back', 'forearms', 'quads'],
            'difficulty' => 'advanced', 'equipment_keys' => ['barbell'],
            'exercise_type' => 'strength', 'movement_pattern' => 'hinge', 'body_engagement' => 'compound',
            'mechanics_type' => 'compound', 'force_type' => 'pull', 'plane_of_motion' => 'sagittal', 'laterality' => 'bilateral',
            'posture' => 'standing', 'grip_type' => 'mixed', 'resistance_profile' => 'free_weight', 'joint_focus' => 'hip',
            'muscle_targets' => ['hamstrings' => 90, 'glutes' => 85, 'lower_back' => 70, 'forearms' => 45, 'quads' => 40, 'traps_upper' => 35],
            'met' => 6.5, 'movement_distance_cm' => 65, 'calories_per_1000kg' => 60, 'exercise_difficulty_score' => 8, 'typical_rpe' => 8.5,
            'estimated_1rm_formula' => 'brzycki', 'programming_goal' => 'strength', 'recommended_sets' => '3-5',
            'rep_range_strength' => '1-5', 'rep_range_hypertrophy' => '5-8', 'rep_range_endurance' => '8-12', 'rest_seconds' => 180, 'tempo' => '2-0-1',
            'short_description' => 'ددلیفت حرکت هیپ‌هینج با هالتر برای قدرت همسترینگ، باسن، کمر و کل زنجیره خلفی.',
            'target_area' => 'پشت پا و باسن',
        ],
        'rank_extra' => 'قدرت کل بدن و زنجیره خلفی.',
    ]);

    $add([
        'slug' => 'فلای-دمبل',
        'title' => 'فلای دمبل',
        'aliases' => ['Dumbbell Fly', 'Chest Fly', 'DB Fly', 'قفسه دمبل', 'فلای سینه'],
        'intro' => '<strong>فلای دمبل</strong> حرکت ایزوله کششی برای سینه با دامنه افقی؛ مکمل عالی بعد از پرس‌ها.',
        'caption' => 'فلای دمبل — آرنج ثابت و کشش سینه',
        'quick' => ['main' => 'سینه', 'secondary' => 'سرشانه قدامی', 'difficulty' => 'متوسط', 'equipment' => 'دمبل، نیمکت', 'type' => 'حجمی'],
        'tips' => ['آرنج زاویه ثابت (~۱۵–۲۰° خم).', 'پایین تا کشش ملایم.', 'بالا مثل بستن درب.'],
        'setup' => ['درازکش روی نیمکت تخت.', 'دمبل بالای سینه، کف دست رو به هم.', 'کتف جمع.'],
        'execution' => ['با دم باز کردن دست‌ها کنار.', 'تا احساس کشش سینه.', 'با بازدم جمع کردن دمبل بالا.', 'انقباض ۱ ثانیه.'],
        'breathing' => 'دم باز — بازدم جمع.',
        'muscles' => ['اصلی: سینه (میانی)', 'کمکی: دلتوئید قدامی', 'تثبیت: Core'],
        'mistakes' => [['خم و باز کردن آرنج', 'آرنج ثابت'], ['وزنه سنگین', 'کاهش بار برای فرم'], ['پایین بیش از حد', 'دامنه تا کشش امن']],
        'program' => [['حجم', '۳–۴', '۱۰–۱۵', '۶۰ث'], ['فینشر', '۲–۳', '۱۲–۲۰', '۴۵ث'], ['پمپ', '۲', '۱۵–۲۰', '۳۰ث']],
        'combos' => [['label' => 'بعد از ', 'link_text' => 'پرس سینه با هالتر', 'slug' => 'پرس-سینه-با-هالتر']],
        'faqs' => [['q' => 'فلای یا کراس سیمکش؟', 'a' => 'هر دو عالی؛ فلای دمبل آزاد، کراس تنش ثابت کابل.']],
        'summary' => 'فلای دمبل برای کشش و فرم‌دهی سینه ضروری است.',
        'summary_keys' => 'آرنج ثابت | کشش کنترل‌شده | انقباض',
        'meta' => [
            'main_muscle' => 'chest', 'secondary_muscle_keys' => ['shoulder_anterior'],
            'difficulty' => 'intermediate', 'equipment_keys' => ['dumbbell', 'bench'],
            'exercise_type' => 'hypertrophy', 'movement_pattern' => 'chest_fly', 'body_engagement' => 'isolation',
            'mechanics_type' => 'isolation', 'force_type' => 'push', 'plane_of_motion' => 'transverse', 'laterality' => 'bilateral',
            'posture' => 'lying_supine', 'grip_type' => 'neutral', 'resistance_profile' => 'free_weight', 'joint_focus' => 'shoulder',
            'muscle_targets' => ['chest_middle' => 95, 'chest' => 85, 'chest_upper' => 45, 'shoulder_anterior' => 30],
            'met' => 4, 'movement_distance_cm' => 50, 'calories_per_1000kg' => 35, 'exercise_difficulty_score' => 4, 'typical_rpe' => 7,
            'estimated_1rm_formula' => '', 'programming_goal' => 'hypertrophy', 'recommended_sets' => '3-4',
            'rep_range_strength' => '8-10', 'rep_range_hypertrophy' => '10-15', 'rep_range_endurance' => '15-20', 'rest_seconds' => 60, 'tempo' => '3-1-2',
            'short_description' => 'فلای دمبل حرکت ایزوله برای کشش و هایپرتروفی سینه با دامنه افقی.',
            'target_area' => 'سینه',
        ],
        'rank_extra' => 'فرم‌دهی و کشش سینه.',
    ]);

    $add([
        'slug' => 'کراس-سیمکش',
        'title' => 'کراس سیمکش',
        'aliases' => ['Cable Crossover', 'Cable Fly', 'کراس اور', 'فلای سیمکش'],
        'intro' => '<strong>کراس سیمکش</strong> فلای با کابل برای تنش مداوم روی سینه؛ از بالا، وسط یا پایین قابل تنظیم است.',
        'caption' => 'کراس سیمکش — قوس حرکت و انقباض سینه',
        'quick' => ['main' => 'سینه', 'secondary' => 'سرشانه قدامی', 'difficulty' => 'مبتدی', 'equipment' => 'سیم‌کش', 'type' => 'حجمی'],
        'tips' => ['قدم کوچک جلو.', 'آرنج کمی خم ثابت.', 'کتف پایین.'],
        'setup' => ['تنظیم پولی (معمولاً بالا برای پایین سینه).', 'گرفتن دستگیره‌ها.', 'تنه کمی مایل.'],
        'execution' => ['باز کردن دست‌ها کنار.', 'قوس به جلو و پایین (یا بالا).', 'انقباض سینه جلو.', 'بازگشت کنترل‌شده.'],
        'breathing' => 'بازدم در جلو — دم در باز.',
        'muscles' => ['اصلی: سینه', 'کمکی: دلتوئید قدامی', 'تثبیت: Core'],
        'mistakes' => [['فشار با شانه', 'تمرکز سینه'], ['کمر قوس زیاد', 'ثبات تنه'], ['وزنه زیاد', 'تمپو کنترل']],
        'program' => [['حجم', '۳–۴', '۱۲–۱۵', '۴۵–۶۰ث'], ['فینشر', '۲', '۱۵–۲۰', '۳۰ث'], ['پمپ', '۳', '۱۵', '۳۰ث']],
        'combos' => [['label' => 'با ', 'link_text' => 'پرس سینه دستگاه', 'slug' => 'پرس-سینه-دستگاه']],
        'faqs' => [['q' => 'ارتفاع پولی؟', 'a' => 'بالا→پایین سینه؛ پایین→بالا سینه؛ وسط→میانی.']],
        'summary' => 'کراس سیمکش برای پمپ و فرم سینه بی‌نظیر است.',
        'summary_keys' => 'تنش مداوم | قوس کنترل | انقباض',
        'meta' => [
            'main_muscle' => 'chest', 'secondary_muscle_keys' => ['shoulder_anterior'],
            'difficulty' => 'beginner', 'equipment_keys' => ['cable'],
            'exercise_type' => 'hypertrophy', 'movement_pattern' => 'chest_fly', 'body_engagement' => 'isolation',
            'mechanics_type' => 'isolation', 'force_type' => 'push', 'plane_of_motion' => 'transverse', 'laterality' => 'bilateral',
            'posture' => 'standing', 'grip_type' => 'neutral', 'resistance_profile' => 'cable_constant', 'joint_focus' => 'shoulder',
            'muscle_targets' => ['chest_middle' => 90, 'chest_lower' => 55, 'chest_upper' => 50, 'shoulder_anterior' => 25],
            'met' => 4, 'movement_distance_cm' => 45, 'calories_per_1000kg' => 38, 'exercise_difficulty_score' => 3, 'typical_rpe' => 7,
            'estimated_1rm_formula' => '', 'programming_goal' => 'hypertrophy', 'recommended_sets' => '3-4',
            'rep_range_strength' => '8-12', 'rep_range_hypertrophy' => '12-15', 'rep_range_endurance' => '15-20', 'rest_seconds' => 60, 'tempo' => '2-1-2',
            'short_description' => 'کراس سیمکش فلای کابلی با تنش مداوم برای هایپرتروفی و فرم سینه.',
            'target_area' => 'سینه',
        ],
        'rank_extra' => 'پمپ و فرم سینه با کابل.',
    ]);

    $add([
        'slug' => 'پرس-سینه-شیب-دار',
        'title' => 'پرس سینه شیب دار',
        'aliases' => ['Incline Bench Press', 'Incline Barbell Press', 'Incline Dumbbell Press', 'پرس بالاسینه'],
        'intro' => '<strong>پرس سینه شیب دار</strong> (بالاسینه) برای تأکید روی fibers بالایی سینه و سرشانه قدامی است؛ معمولاً ۱۵–۳۰ درجه.',
        'caption' => 'پرس سینه شیب دار — زاویه ملایم نیمکت',
        'quick' => ['main' => 'سینه بالایی', 'secondary' => 'سرشانه قدامی، پشت بازو', 'difficulty' => 'متوسط', 'equipment' => 'هالتر یا دمبل، نیمکت شیب‌دار', 'type' => 'قدرتی / حجمی'],
        'tips' => ['زاویه ۱۵–۳۰° کافی است.', 'میله/دمبل به بالای سینه.', 'کتف جمع.'],
        'setup' => ['نیمکت ۱۵–۳۰ درجه.', 'پا ثابت.', 'گرفتن وزنه خط بالای سینه.'],
        'execution' => ['پایین کنترل‌شده به خط بالای سینه.', 'بازدم فشار بالا.', 'آرنج نرم.'],
        'breathing' => 'دم پایین — بازدم بالا.',
        'muscles' => ['اصلی: سینه بالایی (clavicular)', 'کمکی: دلتوئید قدامی، تریسپس', 'تثبیت: Core'],
        'mistakes' => [['زاویه ۴۵°+', 'شیب ملایم ۱۵–۳۰°'], ['میله روی گردن', 'خط بالای سینه'], ['کتف شل', 'جمع قبل از تکرار']],
        'program' => [['حجم', '۳–۴', '۸–۱۲', '۹۰ث'], ['قدرت', '۴', '۴–۸', '۱۲۰ث'], ['استقامت', '۳', '۱۲–۱۵', '۶۰ث']],
        'combos' => [['label' => 'بعد از ', 'link_text' => 'پرس سینه با هالتر', 'slug' => 'پرس-سینه-با-هالتر']],
        'faqs' => [['q' => 'هالتر یا دمبل؟', 'a' => 'هالتر برای بار بیشتر؛ دمبل برای دامنه و تعادل.']],
        'summary' => 'پرس شیب‌دار کلید سینه‌ی «پر» و بالاتنه قوی.',
        'summary_keys' => 'شیب ۱۵–۳۰° | خط بالای سینه | کتف جمع',
        'meta' => [
            'main_muscle' => 'chest_upper', 'secondary_muscle_keys' => ['shoulder_anterior', 'triceps'],
            'difficulty' => 'intermediate', 'equipment_keys' => ['barbell', 'incline_bench'],
            'exercise_type' => 'strength', 'movement_pattern' => 'horizontal_push', 'body_engagement' => 'compound',
            'mechanics_type' => 'compound', 'force_type' => 'push', 'plane_of_motion' => 'sagittal', 'laterality' => 'bilateral',
            'posture' => 'incline', 'grip_type' => 'pronated', 'resistance_profile' => 'free_weight', 'joint_focus' => 'shoulder_elbow',
            'muscle_targets' => ['chest_upper' => 95, 'chest_middle' => 70, 'shoulder_anterior' => 50, 'triceps' => 45],
            'met' => 6, 'movement_distance_cm' => 42, 'calories_per_1000kg' => 44, 'exercise_difficulty_score' => 5, 'typical_rpe' => 7.5,
            'estimated_1rm_formula' => 'brzycki', 'programming_goal' => 'hypertrophy', 'recommended_sets' => '3-4',
            'rep_range_strength' => '4-8', 'rep_range_hypertrophy' => '8-12', 'rep_range_endurance' => '12-15', 'rest_seconds' => 90, 'tempo' => '2-1-2',
            'short_description' => 'پرس سینه شیب دار برای بالاسینه، سرشانه قدامی و پشت بازو با نیمکت ۱۵–۳۰ درجه.',
            'target_area' => 'سینه بالایی',
        ],
        'rank_extra' => 'برجسته‌سازی بالاسینه.',
    ]);

    $add([
        'slug' => 'جلو-بازو-هالتر',
        'title' => 'جلو بازو هالتر',
        'aliases' => ['Barbell Curl', 'BB Curl', 'Standing Barbell Curl', 'کرل هالتر'],
        'intro' => '<strong>جلو بازو هالتر</strong> حرکت پایه برای ضخامت و قدرت جلوبازو با بار مشترک.',
        'caption' => 'جلو بازو هالتر ایستاده',
        'quick' => ['main' => 'جلوبازو', 'secondary' => 'براکیالیس، ساعد', 'difficulty' => 'مبتدی', 'equipment' => 'هالتر', 'type' => 'حجمی'],
        'tips' => ['آرنج کنار بدن.', 'بدون تاب بدن.', 'پایین کامل بدون قفل.'],
        'setup' => ['ایستاده، هالتر underhand.', 'آرنج ثابت کنار تنه.', 'Core سفت.'],
        'execution' => ['خم کردن آرنج تا جلو بازو منقبض.', 'پایین آهسته.', 'تکرار بدون تاب.'],
        'breathing' => 'بازدم بالا — دم پایین.',
        'muscles' => ['اصلی: biceps brachii', 'کمکی: brachialis، forearms', 'تثبیت: Core'],
        'mistakes' => [['تاب بدن', 'کاهش وزنه'], ['آرنج جلو', 'ثابت کنار بدن'], ['نیمه دامنه', 'پایین و بالا کامل']],
        'program' => [['حجم', '۳–۴', '۸–۱۲', '۶۰ث'], ['استقامت', '۳', '۱۲–۱۵', '۴۵ث'], ['قدرت', '۳', '۶–۸', '۹۰ث']],
        'combos' => [['label' => 'با ', 'link_text' => 'جلو بازو دمبل', 'slug' => 'جلو-بازو-دمبل']],
        'faqs' => [['q' => 'میله EZ بهتر است؟', 'a' => 'EZ مچ راحت‌تر؛ هالتر مستقیم بار بیشتر روی biceps.']],
        'summary' => 'کرل هالتر کلاسیک‌ترین حرکت جلوبازو.',
        'summary_keys' => 'آرنج ثابت | بدون تاب | دامنه کامل',
        'meta' => [
            'main_muscle' => 'biceps', 'secondary_muscle_keys' => ['brachialis', 'forearms'],
            'difficulty' => 'beginner', 'equipment_keys' => ['barbell'],
            'exercise_type' => 'hypertrophy', 'movement_pattern' => 'elbow_flexion', 'body_engagement' => 'isolation',
            'mechanics_type' => 'isolation', 'force_type' => 'pull', 'plane_of_motion' => 'sagittal', 'laterality' => 'bilateral',
            'posture' => 'standing', 'grip_type' => 'supinated', 'resistance_profile' => 'free_weight', 'joint_focus' => 'elbow',
            'muscle_targets' => ['biceps' => 95, 'brachialis' => 50, 'forearms' => 40],
            'met' => 3.5, 'movement_distance_cm' => 45, 'calories_per_1000kg' => 35, 'exercise_difficulty_score' => 3, 'typical_rpe' => 7,
            'estimated_1rm_formula' => 'brzycki', 'programming_goal' => 'hypertrophy', 'recommended_sets' => '3-4',
            'rep_range_strength' => '6-8', 'rep_range_hypertrophy' => '8-12', 'rep_range_endurance' => '12-15', 'rest_seconds' => 60, 'tempo' => '2-1-2',
            'short_description' => 'جلو بازو هالتر حرکت پایه ایزوله برای هایپرتروفی جلوبازو و ساعد.',
            'target_area' => 'جلوبازو',
        ],
        'rank_extra' => 'ضخامت جلوبازو با هالتر.',
    ]);

    $add([
        'slug' => 'جلو-بازو-دمبل',
        'title' => 'جلو بازو دمبل',
        'aliases' => ['Dumbbell Curl', 'Standing Dumbbell Curl', 'Alternating DB Curl', 'کرل دمبل'],
        'intro' => '<strong>جلو بازو دمبل</strong> (ایستاده) برای تمرین جداگانه هر دست و دامنه طبیعی‌تر مچ نسبت به نسخه نشسته.',
        'caption' => 'جلو بازو دمبل ایستاده',
        'quick' => ['main' => 'جلوبازو', 'secondary' => 'براکیالیس، ساعد', 'difficulty' => 'مبتدی', 'equipment' => 'دمبل', 'type' => 'حجمی'],
        'tips' => ['آرنج ثابت.', 'چرخش neutral به supinated اختیاری.', 'کنترل پایین.'],
        'setup' => ['دمبل کنار بدن.', 'ایستاده متعادل.', 'شانه پایین.'],
        'execution' => ['خم آرنج تا انقباض.', 'پایین آهسته.', 'تناوبی یا همزمان.'],
        'breathing' => 'بازدم بالا — دم پایین.',
        'muscles' => ['اصلی: biceps', 'کمکی: brachialis', 'تثبیت: Core'],
        'mistakes' => [['تاب بدن', 'وزنه سبک‌تر'], ['آرنج جلو', 'کنار تنه'], ['کوتاه کردن دامنه', 'پایین کامل']],
        'program' => [['حجم', '۳–۴', '۱۰–۱۵', '۴۵–۶۰ث'], ['استقامت', '۳', '۱۵–۲۰', '۳۰ث'], ['قدرت', '۳', '۶–۱۰', '۷۵ث']],
        'combos' => [['label' => 'سوپرسِت: ', 'link_text' => 'جلو بازو هالتر', 'slug' => 'جلو-بازو-هالتر']],
        'faqs' => [['q' => 'فرق با نشسته؟', 'a' => 'نشسته تاب کمتر؛ ایستاده Core بیشتر و طبیعی‌تر.']],
        'summary' => 'کرل دمبل برای Arms متعادل و فرم خوب.',
        'summary_keys' => 'آرنج ثابت | تمپو کنترل | هر دست جدا',
        'meta' => [
            'main_muscle' => 'biceps', 'secondary_muscle_keys' => ['brachialis', 'forearms'],
            'difficulty' => 'beginner', 'equipment_keys' => ['dumbbell'],
            'exercise_type' => 'hypertrophy', 'movement_pattern' => 'elbow_flexion', 'body_engagement' => 'isolation',
            'mechanics_type' => 'isolation', 'force_type' => 'pull', 'plane_of_motion' => 'sagittal', 'laterality' => 'alternating',
            'posture' => 'standing', 'grip_type' => 'supinated', 'resistance_profile' => 'free_weight', 'joint_focus' => 'elbow',
            'muscle_targets' => ['biceps' => 95, 'brachialis' => 45, 'forearms' => 35],
            'met' => 3.5, 'movement_distance_cm' => 45, 'calories_per_1000kg' => 35, 'exercise_difficulty_score' => 2, 'typical_rpe' => 7,
            'estimated_1rm_formula' => 'brzycki', 'programming_goal' => 'hypertrophy', 'recommended_sets' => '3-4',
            'rep_range_strength' => '6-10', 'rep_range_hypertrophy' => '10-15', 'rep_range_endurance' => '15-20', 'rest_seconds' => 60, 'tempo' => '2-1-2',
            'short_description' => 'جلو بازو دمبل ایستاده برای هایپرتروفی جلوبازو با دامنه طبیعی هر دست.',
            'target_area' => 'جلوبازو',
        ],
        'rank_extra' => 'فرم و حجم جلوبازو با دمبل.',
    ]);

    $add([
        'slug' => 'کرانچ',
        'title' => 'کرانچ',
        'aliases' => ['Crunch', 'Abdominal Crunch', 'دراز و نشست نیمه', 'شکم کرانچ'],
        'intro' => '<strong>کرانچ</strong> حرکت فلکشن ستون فقرات برای شکم راست؛ مناسب مبتدی تا متوسط.',
        'caption' => 'کرانچ — بالا آوردن شانه نه کل تنه',
        'quick' => ['main' => 'شکم راست', 'secondary' => 'مورب (کم)', 'difficulty' => 'مبتدی', 'equipment' => 'بدون تجهیزات', 'type' => 'حجمی'],
        'tips' => ['فقط شانه از زمین.', 'چانه به سینه نه به پا.', 'شکم منقبض در بالا.'],
        'setup' => ['پشت روی زمین، زانو خم.', 'دست پشت سر یا روی سینه.', 'کمر به زمین.'],
        'execution' => ['منقبض شکم، شانه بالا.', 'مکث کوتاه.', 'پایین بدون افتادن کامل.'],
        'breathing' => 'بازدم بالا — دم پایین.',
        'muscles' => ['اصلی: rectus abdominis', 'کمکی: hip flexors (کم)', 'تثبیت: Core'],
        'mistakes' => [['کشش گردن', 'دست فقط لمس سبک'], ['دراز نشست کامل', 'دامنه کوتاه کرانچ'], ['نفس حبس طولانی', 'تنفس منظم']],
        'program' => [['حجم', '۳–۴', '۱۵–۲۵', '۳۰–۴۵ث'], ['استقامت', '۳', '۲۵–۴۰', '۳۰ث'], ['سنگین', '۳', '۱۰–۱۵ با وزنه', '۴۵ث']],
        'combos' => [['label' => 'با ', 'link_text' => 'پلانک', 'slug' => 'پلانک-plank']],
        'faqs' => [['q' => 'کرانچ یا دراز نشست؟', 'a' => 'کرانچ فشار کمتر کمر؛ دراز نشست hip flexor بیشتر.']],
        'summary' => 'کرانچ پایه تمرین شکم برای مبتدی.',
        'summary_keys' => 'شانه بالا | شکم منقبض | بدون کشش گردن',
        'meta' => [
            'main_muscle' => 'abs', 'secondary_muscle_keys' => ['obliques'],
            'difficulty' => 'beginner', 'equipment_keys' => ['bodyweight'],
            'exercise_type' => 'hypertrophy', 'movement_pattern' => 'spinal_flexion', 'body_engagement' => 'isolation',
            'mechanics_type' => 'isolation', 'force_type' => 'pull', 'plane_of_motion' => 'sagittal', 'laterality' => 'bilateral',
            'posture' => 'lying_supine', 'grip_type' => 'none', 'resistance_profile' => 'bodyweight', 'joint_focus' => 'core_spine',
            'muscle_targets' => ['abs' => 90, 'obliques' => 25, 'hip_flexors' => 20],
            'met' => 3, 'movement_distance_cm' => 25, 'calories_per_1000kg' => 25, 'exercise_difficulty_score' => 2, 'typical_rpe' => 6,
            'estimated_1rm_formula' => '', 'programming_goal' => 'hypertrophy', 'recommended_sets' => '3-4',
            'rep_range_strength' => '', 'rep_range_hypertrophy' => '15-25', 'rep_range_endurance' => '20-40', 'rest_seconds' => 45, 'tempo' => '2-1-2',
            'short_description' => 'کرانچ حرکت فلکشن برای شکم راست با دامنه کنترل‌شده و فشار کمتر کمر.',
            'target_area' => 'شکم',
        ],
        'rank_extra' => 'تمرین پایه شکم برای همه سطوح.',
    ]);

    $add([
        'slug' => 'لانج',
        'title' => 'لانج',
        'aliases' => ['Lunge', 'Walking Lunge', 'Forward Lunge', 'حرکت قدم بلند'],
        'intro' => '<strong>لانج</strong> حرکت تک‌پا برای چهارسر، باسن و تعادل؛ با وزن بدن یا دمبل قابل پیشرفت.',
        'caption' => 'لانج — زانو جلو روی مچ پا',
        'quick' => ['main' => 'چهارسر', 'secondary' => 'باسن، همسترینگ', 'difficulty' => 'مبتدی', 'equipment' => 'بدون تجهیزات (یا دمبل)', 'type' => 'قدرتی / حجمی'],
        'tips' => ['زانو جلو روی مچ، نه جلوتر.', 'تنه عمودی.', 'قدم کافی برای کشش.'],
        'setup' => ['ایستاده، Core سفت.', 'قدم بلند جلو.', 'پاشنه عقب بالا.'],
        'execution' => ['پایین تا زانو عقب نزدیک زمین.', 'فشار پا جلو برای بالا.', 'تناوب پاها.'],
        'breathing' => 'دم پایین — بازدم بالا.',
        'muscles' => ['اصلی: quadriceps', 'کمکی: glutes، hamstrings', 'تثبیت: Core'],
        'mistakes' => [['زانو جلو زیاد', 'قدم بلندتر'], ['تنه جلو', 'قامت عمودی'], ['قدم کوتاه', 'کشش کافی']],
        'program' => [['حجم', '۳', '۱۰–۱۲ هر پا', '۶۰ث'], ['استقامت', '۳', '۱۵–۲۰', '۴۵ث'], ['قدرت', '۳–۴', '۶–۸', '۹۰ث']],
        'combos' => [['label' => 'روز پا: ', 'link_text' => 'اسکات هالتر', 'slug' => 'اسکات-هالتر']],
        'faqs' => [['q' => 'جلو یا عقب؟', 'a' => 'جلو رایج‌تر؛ عقب فشار کمتر روی زانو جلو.']],
        'summary' => 'لانج برای پا، باسن و تعادل ضروری است.',
        'summary_keys' => 'زانو روی مچ | تنه عمودی | دامنه کامل',
        'meta' => [
            'main_muscle' => 'quads', 'secondary_muscle_keys' => ['glutes', 'hamstrings'],
            'difficulty' => 'beginner', 'equipment_keys' => ['bodyweight'],
            'exercise_type' => 'strength', 'movement_pattern' => 'lunge', 'body_engagement' => 'compound',
            'mechanics_type' => 'compound', 'force_type' => 'push', 'plane_of_motion' => 'sagittal', 'laterality' => 'unilateral',
            'posture' => 'standing', 'grip_type' => 'none', 'resistance_profile' => 'bodyweight', 'joint_focus' => 'knee_hip',
            'muscle_targets' => ['quads' => 90, 'glutes' => 75, 'hamstrings' => 45, 'abs' => 25],
            'met' => 4.5, 'movement_distance_cm' => 50, 'calories_per_1000kg' => 42, 'exercise_difficulty_score' => 4, 'typical_rpe' => 7,
            'estimated_1rm_formula' => '', 'programming_goal' => 'hypertrophy', 'recommended_sets' => '3-4',
            'rep_range_strength' => '6-10', 'rep_range_hypertrophy' => '10-12', 'rep_range_endurance' => '12-20', 'rest_seconds' => 60, 'tempo' => '2-1-2',
            'short_description' => 'لانج حرکت تک‌پا برای چهارسر، باسن، همسترینگ و تعادل.',
            'target_area' => 'پا و باسن',
        ],
        'rank_extra' => 'تمرین تک‌پا برای پا و باسن.',
    ]);

    $add([
        'slug' => 'پشت-بازو-پشت-سر',
        'title' => 'پشت بازو پشت سر',
        'aliases' => ['Skull Crusher', 'Lying Triceps Extension', 'French Press', 'EZ Bar Skull Crusher', 'پشت بازو خوابیده'],
        'intro' => '<strong>پشت بازو پشت سر</strong> (اسکال کرشر) حرکت ایزوله برای سه‌سر بازو در حالت خوابیده.',
        'caption' => 'پشت بازو پشت سر — آرنج ثابت',
        'quick' => ['main' => 'پشت بازو', 'secondary' => 'ساعد', 'difficulty' => 'متوسط', 'equipment' => 'هالتر یا EZ، نیمکت', 'type' => 'حجمی'],
        'tips' => ['آرنج ثابت رو به سقف.', 'پایین تا پیشانی/کنار سر.', 'بازگشت با انقباض.'],
        'setup' => ['درازکش، هالتر بالای سینه.', 'آرنج جمع رو به بالا.', 'گرفتن بار.'],
        'execution' => ['خم آرنج پایین کنترل.', 'تا نزدیک پیشانی.', 'بازگشت تا آرنج تقریباً صاف.'],
        'breathing' => 'دم پایین — بازدم بالا.',
        'muscles' => ['اصلی: triceps (long head)', 'کمکی: forearms', 'تثبیت: Core'],
        'mistakes' => [['آرنج باز', 'ثابت رو به بالا'], ['کوبیدن پیشانی', 'تمپو آهسته'], ['کمر قوس', 'پا روی زمین']],
        'program' => [['حجم', '۳–۴', '۸–۱۲', '۶۰–۹۰ث'], ['استقامت', '۳', '۱۲–۱۵', '۴۵ث'], ['قدرت', '۳', '۶–۸', '۹۰ث']],
        'combos' => [['label' => 'با ', 'link_text' => 'پشت بازو سیمکش', 'slug' => 'پشت-بازو-سیمکش']],
        'faqs' => [['q' => 'EZ یا هالتر مستقیم؟', 'a' => 'EZ مچ راحت‌تر؛ هر دو مؤثرند.']],
        'summary' => 'اسکال کرشر کلاسیک برای سه‌سر.',
        'summary_keys' => 'آرنج ثابت | تمپو کنترل | دامنه کامل',
        'meta' => [
            'main_muscle' => 'triceps', 'secondary_muscle_keys' => ['forearms'],
            'difficulty' => 'intermediate', 'equipment_keys' => ['barbell', 'bench'],
            'exercise_type' => 'hypertrophy', 'movement_pattern' => 'elbow_extension', 'body_engagement' => 'isolation',
            'mechanics_type' => 'isolation', 'force_type' => 'push', 'plane_of_motion' => 'sagittal', 'laterality' => 'bilateral',
            'posture' => 'lying_supine', 'grip_type' => 'pronated', 'resistance_profile' => 'free_weight', 'joint_focus' => 'elbow',
            'muscle_targets' => ['triceps' => 95, 'forearms' => 30],
            'met' => 4, 'movement_distance_cm' => 40, 'calories_per_1000kg' => 38, 'exercise_difficulty_score' => 4, 'typical_rpe' => 7.5,
            'estimated_1rm_formula' => 'brzycki', 'programming_goal' => 'hypertrophy', 'recommended_sets' => '3-4',
            'rep_range_strength' => '6-8', 'rep_range_hypertrophy' => '8-12', 'rep_range_endurance' => '12-15', 'rest_seconds' => 75, 'tempo' => '2-1-2',
            'short_description' => 'پشت بازو پشت سر (اسکال کرشر) حرکت ایزوله برای سه‌سر بازو.',
            'target_area' => 'پشت بازو',
        ],
        'rank_extra' => 'حجم سه‌سر بازو.',
    ]);

    $add([
        'slug' => 'کول-هالتر',
        'title' => 'کول هالتر',
        'aliases' => ['Barbell Shrug', 'Shrug', 'Shrugs', 'شراگ هالتر', 'شراگ'],
        'intro' => '<strong>کول هالتر</strong> (شراگ) برای ذوزنقه بالایی و گردن/کتف قوی؛ حرکت کوتاه ولی مؤثر.',
        'caption' => 'کول هالتر — بالا بردن شانه مستقیم',
        'quick' => ['main' => 'ذوزنقه بالایی', 'secondary' => 'گردن (تثبیت)', 'difficulty' => 'مبتدی', 'equipment' => 'هالتر', 'type' => 'حجمی'],
        'tips' => ['فقط شانه بالا — نه چرخش.', 'مکث ۱ ثانیه بالا.', 'آرنج صاف.'],
        'setup' => ['هالتر جلو بدن یا پشت.', 'دست بازتر از لگن.', 'ایستاده صاف.'],
        'execution' => ['بالا بردن شانه به گوش.', 'مکث.', 'پایین آهسته.'],
        'breathing' => 'بازدم بالا — دم پایین.',
        'muscles' => ['اصلی: upper trapezius', 'کمکی: levator scapulae', 'تثبیت: Core'],
        'mistakes' => [['چرخش شانه', 'حرکت خطی بالا'], ['تاب سر', 'گردن خنثی'], ['وزنه بیش از حد', 'دامنه کامل']],
        'program' => [['حجم', '۳–۴', '۱۲–۱۵', '۴۵–۶۰ث'], ['قدرت', '۳', '۸–۱۰', '۹۰ث'], ['استقامت', '۳', '۱۵–۲۰', '۳۰ث']],
        'combos' => [['label' => 'بعد از ', 'link_text' => 'زیربغل هالتر', 'slug' => 'زیربغل-هالتر-خمیده']],
        'faqs' => [['q' => 'هالتر جلو یا پشت؟', 'a' => 'جلو رایج‌تر؛ پشت گرفتن متفاوت است.']],
        'summary' => 'شراگ برای ذوزنقه و ظاهر پشت بالاتنه.',
        'summary_keys' => 'حرکت خطی | مکث بالا | بدون چرخش',
        'meta' => [
            'main_muscle' => 'traps_upper', 'secondary_muscle_keys' => ['traps_middle'],
            'difficulty' => 'beginner', 'equipment_keys' => ['barbell'],
            'exercise_type' => 'hypertrophy', 'movement_pattern' => 'scapular_elevation', 'body_engagement' => 'isolation',
            'mechanics_type' => 'isolation', 'force_type' => 'pull', 'plane_of_motion' => 'frontal', 'laterality' => 'bilateral',
            'posture' => 'standing', 'grip_type' => 'pronated', 'resistance_profile' => 'free_weight', 'joint_focus' => 'shoulder',
            'muscle_targets' => ['traps_upper' => 95, 'traps_middle' => 70, 'traps_lower' => 30],
            'met' => 3.5, 'movement_distance_cm' => 15, 'calories_per_1000kg' => 30, 'exercise_difficulty_score' => 2, 'typical_rpe' => 6.5,
            'estimated_1rm_formula' => 'brzycki', 'programming_goal' => 'hypertrophy', 'recommended_sets' => '3-4',
            'rep_range_strength' => '6-10', 'rep_range_hypertrophy' => '12-15', 'rep_range_endurance' => '15-20', 'rest_seconds' => 60, 'tempo' => '2-1-2',
            'short_description' => 'کول هالتر (شراگ) برای ذوزنقه بالایی و تقویت کتف.',
            'target_area' => 'ذوزنقه',
        ],
        'rank_extra' => 'ذوزنقه بالایی و کتف.',
    ]);

    $add([
        'slug' => 'پشت-بازو-دمبل',
        'title' => 'پشت بازو دمبل',
        'aliases' => ['Dumbbell Triceps Extension', 'Overhead Triceps Extension', 'Single Arm Triceps Extension', 'اکستنشن پشت بازو'],
        'intro' => '<strong>پشت بازو دمبل</strong> (بالای سر) برای کشش long head سه‌سر؛ نشسته یا ایستاده.',
        'caption' => 'پشت بازو دمبل — آرنج رو به بالا',
        'quick' => ['main' => 'پشت بازو', 'secondary' => 'ساعد', 'difficulty' => 'مبتدی', 'equipment' => 'دمبل', 'type' => 'حجمی'],
        'tips' => ['آرنج ثابت کنار سر.', 'پایین پشت سر.', 'کمر خنثی.'],
        'setup' => ['دمبل دو دست یا تک.', 'آرنج رو به بالا.', 'نشسته یا ایستاده.'],
        'execution' => ['خم آرنج پایین.', 'کشش سه‌سر.', 'بازگشت تا صاف.'],
        'breathing' => 'دم پایین — بازدم بالا.',
        'muscles' => ['اصلی: triceps long head', 'کمکی: forearms', 'تثبیت: Core'],
        'mistakes' => [['آرنج باز', 'ثابت'], ['قوس کمر', 'Core سفت'], ['دامنه کوتاه', 'پایین کامل']],
        'program' => [['حجم', '۳–۴', '۱۰–۱۵', '۴۵–۶۰ث'], ['استقامت', '۳', '۱۵–۲۰', '۳۰ث'], ['تک دست', '۳', '۱۰–۱۲', '۴۵ث']],
        'combos' => [['label' => 'با ', 'link_text' => 'پشت بازو سیمکش', 'slug' => 'پشت-بازو-سیمکش']],
        'faqs' => [['q' => 'بالای سر یا لickback؟', 'a' => 'بالای سر long head بیشتر؛ kickback برای peak contraction.']],
        'summary' => 'اکستنشن دمبل برای arms کامل.',
        'summary_keys' => 'آرنج ثابت | کشش long head | تمپو',
        'meta' => [
            'main_muscle' => 'triceps', 'secondary_muscle_keys' => ['forearms'],
            'difficulty' => 'beginner', 'equipment_keys' => ['dumbbell'],
            'exercise_type' => 'hypertrophy', 'movement_pattern' => 'elbow_extension', 'body_engagement' => 'isolation',
            'mechanics_type' => 'isolation', 'force_type' => 'push', 'plane_of_motion' => 'sagittal', 'laterality' => 'bilateral',
            'posture' => 'seated', 'grip_type' => 'neutral', 'resistance_profile' => 'free_weight', 'joint_focus' => 'elbow',
            'muscle_targets' => ['triceps' => 95, 'forearms' => 25],
            'met' => 3.5, 'movement_distance_cm' => 45, 'calories_per_1000kg' => 35, 'exercise_difficulty_score' => 3, 'typical_rpe' => 7,
            'estimated_1rm_formula' => '', 'programming_goal' => 'hypertrophy', 'recommended_sets' => '3-4',
            'rep_range_strength' => '6-10', 'rep_range_hypertrophy' => '10-15', 'rep_range_endurance' => '15-20', 'rest_seconds' => 60, 'tempo' => '2-1-2',
            'short_description' => 'پشت بازو دمبل (بالای سر) برای هایپرتروفی سه‌سر بازو.',
            'target_area' => 'پشت بازو',
        ],
        'rank_extra' => 'long head سه‌سر بازو.',
    ]);

    $add([
        'slug' => 'پای-آویزان',
        'title' => 'پای آویزان',
        'aliases' => ['Hanging Leg Raise', 'Hanging Knee Raise', 'Leg Raise', 'بالا آوردن پا آویزان'],
        'intro' => '<strong>پای آویزان</strong> حرکت پیشرفته Core با آویزان از بارفیکس؛ شکم و فلکسور لگن را هدف می‌گیرد.',
        'caption' => 'پای آویزان — بدون تاب',
        'quick' => ['main' => 'شکم', 'secondary' => 'فلکسور لگن', 'difficulty' => 'متوسط', 'equipment' => 'میله بارفیکس', 'type' => 'قدرتی Core'],
        'tips' => ['بدون تاب.', 'لگن کمی جلو برای شکم.', 'پایین کنترل‌شده.'],
        'setup' => ['آویزان فعال از بارفیکس.', 'کتف پایین.', 'پا کنار هم.'],
        'execution' => ['بالا بردن پا تا موازی زمین یا بالاتر.', 'مکث کوتاه.', 'پایین آهسته.'],
        'breathing' => 'بازدم بالا — دم پایین.',
        'muscles' => ['اصلی: rectus abdominis', 'کمکی: hip flexors', 'تثبیت: forearms، lats'],
        'mistakes' => [['تاب', 'کنترل تمپو'], ['فقط زانو بدون شکم', 'لگن posterior tilt'], ['گردن فشار', 'شانه ریلکس']],
        'program' => [['حجم', '۳–۴', '۸–۱۵', '۶۰ث'], ['استقامت', '۳', '۱۲–۲۰', '۴۵ث'], ['زانو (آسان‌تر)', '۳', '۱۵–۲۰', '۳۰ث']],
        'combos' => [['label' => 'بعد از ', 'link_text' => 'بارفیکس', 'slug' => 'بارفیکس']],
        'faqs' => [['q' => 'پا صاف یا زانو؟', 'a' => 'زانو برای مبتدی؛ پا صاف سخت‌تر و شکم بیشتر.']],
        'summary' => 'پای آویزان برای شکم قوی و Core پیشرفته.',
        'summary_keys' => 'بدون تاب | کنترل پایین | کتف فعال',
        'meta' => [
            'main_muscle' => 'abs', 'secondary_muscle_keys' => ['hip_flexors', 'forearms'],
            'difficulty' => 'intermediate', 'equipment_keys' => ['pullup_bar'],
            'exercise_type' => 'strength', 'movement_pattern' => 'spinal_flexion', 'body_engagement' => 'core_dominant',
            'mechanics_type' => 'compound', 'force_type' => 'pull', 'plane_of_motion' => 'sagittal', 'laterality' => 'bilateral',
            'posture' => 'hanging', 'grip_type' => 'pronated', 'resistance_profile' => 'bodyweight', 'joint_focus' => 'core_spine',
            'muscle_targets' => ['abs' => 90, 'hip_flexors' => 55, 'forearms' => 35, 'back_lat' => 25],
            'met' => 4, 'movement_distance_cm' => 40, 'calories_per_1000kg' => 35, 'exercise_difficulty_score' => 5, 'typical_rpe' => 7.5,
            'estimated_1rm_formula' => '', 'programming_goal' => 'hypertrophy', 'recommended_sets' => '3-4',
            'rep_range_strength' => '6-10', 'rep_range_hypertrophy' => '10-15', 'rep_range_endurance' => '12-20', 'rest_seconds' => 60, 'tempo' => '2-1-2',
            'short_description' => 'پای آویزان حرکت Core برای شکم و فلکسور لگن با آویزان از بارفیکس.',
            'target_area' => 'شکم',
        ],
        'rank_extra' => 'Core پیشرفته و شکم.',
    ]);

    $add([
        'slug' => 'کتله-بل-سوینگ',
        'title' => 'کتله بل سوینگ',
        'aliases' => ['Kettlebell Swing', 'KB Swing', 'Russian Swing', 'سوینگ کتلبل'],
        'intro' => '<strong>کتله بل سوینگ</strong> حرکت هیپ‌هینج انفجاری برای باسن، همسترینگ، Core و استقامت.',
        'caption' => 'کتله بل سوینگ — قدرت از باسن',
        'quick' => ['main' => 'باسن', 'secondary' => 'همسترینگ، Core، کمر', 'difficulty' => 'متوسط', 'equipment' => 'کتل‌بل', 'type' => 'پاور / هوازی'],
        'tips' => ['قدرت از باسن نه دست.', 'کتل تا ارتفاع سینه (Russian).', 'کمر خنثی.'],
        'setup' => ['پا عرض شانه.', 'کتل جلو، خم با باسن عقب.', 'دو دست روی دسته.'],
        'execution' => ['باسن عقب، کتل بین پا.', 'انفجار باسن جلو — کتل تا سینه.', 'کنترل پایین.', 'ریتم ثابت.'],
        'breathing' => 'بازدم در بالا — دم در backswing.',
        'muscles' => ['اصلی: glutes، hamstrings', 'کمکی: erector، shoulders', 'تثبیت: Core'],
        'mistakes' => [['کشش با دست', 'هیپ هینج'], ['کمر گرد', 'قفسه بالا'], ['کتل خیلی بالا', 'تا سینه کافی']],
        'program' => [['پاور', '۵', '۱۵–۲۰', '۶۰ث'], ['HIIT', '۸', '۲۰ ثانیه', '۴۰ث'], ['استقامت', '۳', '۲۵–۳۰', '۴۵ث']],
        'combos' => [['label' => 'با ', 'link_text' => 'ددلیفت رومانیایی', 'slug' => 'ددلیفت-رومانیایی']],
        'faqs' => [['q' => 'American vs Russian؟', 'a' => 'Russian تا سینه امن‌تر؛ American overhead سخت‌تر.']],
        'summary' => 'سوینگ برای باسن، چربی‌سوزی و پاور.',
        'summary_keys' => 'هیپ هینج | بازدم بالا | کمر خنثی',
        'meta' => [
            'main_muscle' => 'glutes', 'secondary_muscle_keys' => ['hamstrings', 'lower_back', 'abs'],
            'difficulty' => 'intermediate', 'equipment_keys' => ['kettlebell'],
            'exercise_type' => 'power', 'movement_pattern' => 'hinge', 'body_engagement' => 'compound',
            'mechanics_type' => 'compound', 'force_type' => 'dynamic', 'plane_of_motion' => 'sagittal', 'laterality' => 'bilateral',
            'posture' => 'standing', 'grip_type' => 'neutral', 'resistance_profile' => 'free_weight', 'joint_focus' => 'hip',
            'muscle_targets' => ['glutes' => 90, 'hamstrings' => 80, 'lower_back' => 45, 'abs' => 40, 'shoulder_anterior' => 25],
            'met' => 9, 'movement_distance_cm' => 55, 'calories_per_1000kg' => 55, 'exercise_difficulty_score' => 5, 'typical_rpe' => 7,
            'estimated_1rm_formula' => '', 'programming_goal' => 'power', 'recommended_sets' => '3-5',
            'rep_range_strength' => '5-10', 'rep_range_hypertrophy' => '10-15', 'rep_range_endurance' => '15-25', 'rest_seconds' => 60, 'tempo' => 'dynamic',
            'short_description' => 'کتله بل سوینگ حرکت هیپ‌هینج انفجاری برای باسن، همسترینگ و Core.',
            'target_area' => 'باسن و پشت پا',
        ],
        'rank_extra' => 'پاور باسن و چربی‌سوزی.',
    ]);

    $add([
        'slug' => 'رویینگ-سیمکش',
        'title' => 'رویینگ سیمکش',
        'aliases' => ['Seated Cable Row', 'Cable Row', 'Low Row', 'قایقی سیمکش', 'Row'],
        'intro' => '<strong>رویینگ سیمکش</strong> کشش افقی نشسته برای ضخامت پشت، رomboid و لats.',
        'caption' => 'رویینگ سیمکش — کتف جمع در عقب',
        'quick' => ['main' => 'پشت (میانی)', 'secondary' => 'زیربغل، جلوبازو', 'difficulty' => 'مبتدی', 'equipment' => 'سیم‌کش', 'type' => 'قدرتی / حجمی'],
        'tips' => ['کتف جمع در عقب.', 'آرنج کنار بدن.', 'بدون تاب.'],
        'setup' => ['نشسته، پا روی پدال.', 'کمر خنثی.', 'گرفتن V یا دست صاف.'],
        'execution' => ['کشش به شکم/پایین سینه.', 'مکث عقب.', 'بازگشت آهسته.'],
        'breathing' => 'بازدم کشش — دم باز.',
        'muscles' => ['اصلی: mid traps، rhomboids، lats', 'کمکی: biceps', 'تثبیت: Core'],
        'mistakes' => [['کشش با بدن', 'ثابت تنه'], ['گردن جلو', 'خنثی'], ['نیمه دامنه', 'کشش کامل']],
        'program' => [['حجم', '۳–۴', '۸–۱۲', '۶۰–۹۰ث'], ['قدرت', '۴', '۶–۸', '۱۲۰ث'], ['استقامت', '۳', '۱۲–۱۵', '۴۵ث']],
        'combos' => [['label' => 'با ', 'link_text' => 'بارفیکس', 'slug' => 'بارفیکس']],
        'faqs' => [['q' => 'V یا wide؟', 'a' => 'V ضخامت میانی؛ wide لats بیشتر.']],
        'summary' => 'رویینگ برای پشت ضخیم و posture بهتر.',
        'summary_keys' => 'کتف جمع | تنه ثابت | مکث عقب',
        'meta' => [
            'main_muscle' => 'back_lat', 'secondary_muscle_keys' => ['rhomboids', 'traps_middle', 'biceps'],
            'difficulty' => 'beginner', 'equipment_keys' => ['cable'],
            'exercise_type' => 'strength', 'movement_pattern' => 'horizontal_pull', 'body_engagement' => 'compound',
            'mechanics_type' => 'compound', 'force_type' => 'pull', 'plane_of_motion' => 'transverse', 'laterality' => 'bilateral',
            'posture' => 'seated', 'grip_type' => 'neutral', 'resistance_profile' => 'cable_constant', 'joint_focus' => 'shoulder_elbow',
            'muscle_targets' => ['back_lat' => 85, 'rhomboids' => 75, 'traps_middle' => 70, 'biceps' => 40],
            'met' => 5, 'movement_distance_cm' => 50, 'calories_per_1000kg' => 45, 'exercise_difficulty_score' => 3, 'typical_rpe' => 7,
            'estimated_1rm_formula' => 'brzycki', 'programming_goal' => 'hypertrophy', 'recommended_sets' => '3-5',
            'rep_range_strength' => '4-8', 'rep_range_hypertrophy' => '8-12', 'rep_range_endurance' => '12-15', 'rest_seconds' => 90, 'tempo' => '2-1-2',
            'short_description' => 'رویینگ سیمکش کشش افقی برای ضخامت پشت، رomboid و زیربغل.',
            'target_area' => 'پشت',
        ],
        'rank_extra' => 'ضخامت پشت و وضعیت بدن.',
    ]);

    $add([
        'slug' => 'شنا-الماسی',
        'title' => 'شنا الماسی',
        'aliases' => ['Diamond Push-Up', 'Triangle Push-Up', 'Close Grip Push-Up', 'شنا دست جمع'],
        'intro' => '<strong>شنا الماسی</strong> شنا با دست جمع برای تأکید بر پشت بازو و درونی سینه.',
        'caption' => 'شنا الماسی — دست‌ها الماس',
        'quick' => ['main' => 'پشت بازو', 'secondary' => 'سینه داخلی، Core', 'difficulty' => 'متوسط', 'equipment' => 'بدون تجهیزات', 'type' => 'قدرتی'],
        'tips' => ['انگشتان الماس زیر سینه.', 'آرنج نزدیک بدن.', 'Core سفت.'],
        'setup' => ['شنا، دست الماس.', 'خط بدن صاف.', 'پا مناسب سطح.'],
        'execution' => ['پایین تا سینه نزدیک دست.', 'بازدم بالا.', 'کنترل تمپو.'],
        'breathing' => 'دم پایین — بازدم بالا.',
        'muscles' => ['اصلی: triceps', 'کمکی: chest inner، anterior deltoid', 'تثبیت: Core'],
        'mistakes' => [['کمر افتاده', 'Core'], ['آرنج باز', 'نزدیک بدن'], ['دست جلو صورت', 'زیر سینه']],
        'program' => [['حجم', '۳–۴', '۸–۱۵', '۴۵–۶۰ث'], ['استقامت', '۳', '۱۵–۲۵', '۳۰ث'], ['قدرت', '۴', '۵–۱۰', '۶۰ث']],
        'combos' => [['label' => 'با ', 'link_text' => 'پشت بازو سیمکش', 'slug' => 'پشت-بازو-سیمکش']],
        'faqs' => [['q' => 'سخت است؟', 'a' => 'روی زانو یا دست روی سکو شروع کنید.']],
        'summary' => 'شنا الماسی برای triceps بدون وسیله.',
        'summary_keys' => 'دست الماس | آرنج نزدیک | Core سفت',
        'meta' => [
            'main_muscle' => 'triceps', 'secondary_muscle_keys' => ['chest', 'shoulder_anterior', 'abs'],
            'difficulty' => 'intermediate', 'equipment_keys' => ['bodyweight'],
            'exercise_type' => 'strength', 'movement_pattern' => 'horizontal_push', 'body_engagement' => 'compound',
            'mechanics_type' => 'compound', 'force_type' => 'push', 'plane_of_motion' => 'sagittal', 'laterality' => 'bilateral',
            'posture' => 'lying_prone', 'grip_type' => 'narrow', 'resistance_profile' => 'bodyweight', 'joint_focus' => 'elbow',
            'muscle_targets' => ['triceps' => 90, 'chest_middle' => 55, 'shoulder_anterior' => 35, 'abs' => 30],
            'met' => 4.5, 'movement_distance_cm' => 30, 'calories_per_1000kg' => 38, 'exercise_difficulty_score' => 5, 'typical_rpe' => 7.5,
            'estimated_1rm_formula' => '', 'programming_goal' => 'hypertrophy', 'recommended_sets' => '3-4',
            'rep_range_strength' => '5-8', 'rep_range_hypertrophy' => '8-15', 'rep_range_endurance' => '15-25', 'rest_seconds' => 60, 'tempo' => '2-1-2',
            'short_description' => 'شنا الماسی شنا دست جمع برای پشت بازو و سینه داخلی با وزن بدن.',
            'target_area' => 'پشت بازو',
        ],
        'rank_extra' => 'پشت بازو با وزن بدن.',
    ]);

    return $defs;
}
}

if (!function_exists('gymai_apply_popular_exercise_meta')) {
function gymai_apply_popular_exercise_meta($post_id, array $def, $content) {
    $m = $def['meta'];
    $title = $def['title'];
    $image = $def['image'];

    $meta = [
        'name_app' => $title,
        'other_names' => $def['aliases'],
        'short_description' => $m['short_description'],
        'detailed_description' => '',
        'seo_content' => $m['short_description'],
        'main_muscle' => $m['main_muscle'],
        'secondary_muscle_keys' => $m['secondary_muscle_keys'],
        'target_area' => $m['target_area'],
        'difficulty' => $m['difficulty'],
        'equipment_keys' => $m['equipment_keys'],
        'exercise_type' => $m['exercise_type'],
        'movement_pattern' => $m['movement_pattern'],
        'body_engagement' => $m['body_engagement'],
        'mechanics_type' => $m['mechanics_type'],
        'force_type' => $m['force_type'],
        'plane_of_motion' => $m['plane_of_motion'],
        'laterality' => $m['laterality'],
        'posture' => $m['posture'],
        'grip_type' => $m['grip_type'] ?? '',
        'resistance_profile' => $m['resistance_profile'],
        'joint_focus' => $m['joint_focus'],
        'muscle_targets_json' => wp_json_encode($m['muscle_targets'], JSON_UNESCAPED_UNICODE),
        'met' => (string) $m['met'],
        'movement_distance_cm' => (string) $m['movement_distance_cm'],
        'calories_per_1000kg' => (string) $m['calories_per_1000kg'],
        'exercise_difficulty_score' => (string) $m['exercise_difficulty_score'],
        'typical_rpe' => (string) $m['typical_rpe'],
        'estimated_1rm_formula' => $m['estimated_1rm_formula'] ?? '',
        'programming_goal' => $m['programming_goal'],
        'recommended_sets' => $m['recommended_sets'],
        'rep_range_strength' => $m['rep_range_strength'],
        'rep_range_hypertrophy' => $m['rep_range_hypertrophy'],
        'rep_range_endurance' => $m['rep_range_endurance'],
        'rest_seconds' => (string) $m['rest_seconds'],
        'tempo' => $m['tempo'],
        'setup' => implode("\n", $def['setup']),
        'execution' => implode("\n", $def['execution']),
        'breathing' => $def['breathing'],
        'common_mistakes' => implode("\n", array_map(function ($row) {
            return $row[0];
        }, $def['mistakes'])),
        'contraindications' => implode("\n", $def['contraindications'] ?? ['درد حاد مفصل مرتبط', 'آسیب فعال — با پزشک مشورت کنید']),
        'tip_1' => $def['tips'][0] ?? '',
        'tip_2' => $def['tips'][1] ?? '',
        'tip_3' => $def['tips'][2] ?? '',
        'video_url' => '',
        'image_url' => $image,
        'thumbnail_url' => $image,
        'views_count' => '0',
        'likes_count' => '0',
    ];

    foreach ($meta as $key => $value) {
        update_post_meta($post_id, $key, $value);
    }
    update_post_meta($post_id, '_gymai_v2_meta_saved', (string) time());

    $sets = $m['recommended_sets'];
    $reps = $m['rep_range_hypertrophy'] ?: '۸–۱۲';
    $desc = gymai_popular_20_meta_description(
        $title,
        count($def['tips']),
        count($def['mistakes']),
        $sets,
        $reps,
        $def['rank_extra'] ?? ''
    );

    $seo_title = $title . ' | آموزش ۰ تا ۱۰۰ + برنامه تمرینی | GymAI Pro';
    $canonical = gymai_pop20_exercise_url($def['slug']);

    $rank = [
        'rank_math_title' => $seo_title,
        'rank_math_description' => $desc,
        'rank_math_focus_keyword' => $title,
        'rank_math_canonical_url' => $canonical,
        'rank_math_facebook_title' => $seo_title,
        'rank_math_facebook_description' => $desc,
        'rank_math_facebook_image' => $image,
        'rank_math_twitter_title' => $seo_title,
        'rank_math_twitter_description' => $desc,
        'rank_math_twitter_image' => $image,
        'rank_math_robots' => ['index'],
        'rank_math_rich_snippet' => 'article',
    ];
    foreach ($rank as $key => $value) {
        update_post_meta($post_id, $key, $value);
    }
}
}

/**
 * @return array{created: int, skipped: int, updated: int, errors: string[]}
 */
if (!function_exists('gymai_batch_insert_popular_20')) {
function gymai_batch_insert_popular_20($update_existing = false) {
    $blocklist = array_flip(gymai_existing_exercise_slugs_blocklist());
    $created = $skipped = $updated = 0;
    $errors = [];

    foreach (gymai_popular_20_exercise_definitions() as $def) {
        $slug = $def['slug'];
        if (isset($blocklist[$slug])) {
            $skipped++;
            $errors[] = "رد (لیست موجود): $slug";
            continue;
        }

        $existing = get_page_by_path($slug, OBJECT, GYMAI_EXERCISE_POST_TYPE);
        $content = gymai_render_popular_exercise_html($def);

        if ($existing instanceof WP_Post) {
            if (!$update_existing) {
                $skipped++;
                continue;
            }
            wp_update_post([
                'ID' => $existing->ID,
                'post_title' => $def['title'],
                'post_content' => $content,
            ]);
            gymai_apply_popular_exercise_meta($existing->ID, $def, $content);
            $updated++;
            continue;
        }

        $post_id = wp_insert_post([
            'post_title' => $def['title'],
            'post_name' => $slug,
            'post_type' => GYMAI_EXERCISE_POST_TYPE,
            'post_status' => 'publish',
            'post_content' => $content,
        ], true);

        if (is_wp_error($post_id)) {
            $errors[] = $def['title'] . ': ' . $post_id->get_error_message();
            continue;
        }

        gymai_apply_popular_exercise_meta((int) $post_id, $def, $content);
        $created++;
    }

    return compact('created', 'skipped', 'updated', 'errors');
}
}

if (!function_exists('gymai_popular_20_admin_page')) {
function gymai_popular_20_admin_page() {
    if (!current_user_can('manage_options')) {
        wp_die('دسترسی کافی ندارید.');
    }

    $result = null;
    if (isset($_POST['gymai_pop20_nonce']) && wp_verify_nonce(sanitize_text_field(wp_unslash($_POST['gymai_pop20_nonce'])), 'gymai_pop20')) {
        $update = !empty($_POST['update_existing']);
        $result = gymai_batch_insert_popular_20($update);
    }

    $count = count(gymai_popular_20_exercise_definitions());
    ?>
    <div class="wrap">
        <h1>🏋️ افزودن <?php echo (int) $count; ?> حرکت پرطرفدار</h1>
        <p>عنوان پست = <strong>اسم عمومی حرکت</strong> (مثلاً «پرس سینه با دمبل»). نام‌های تخصصی در aliases. توضیح متا شامل <strong>آموزش ۰ تا ۱۰۰</strong> و اعداد برنامه.</p>
        <p>حرکات موجود در لیست ۱۴تایی شما skip می‌شوند. slug تکراری بدون تیک «بروزرسانی» رد می‌شود.</p>

        <?php if (is_array($result)) : ?>
            <div class="notice notice-success"><p>
                ایجاد: <?php echo (int) $result['created']; ?> |
                بروزرسانی: <?php echo (int) $result['updated']; ?> |
                رد شده: <?php echo (int) $result['skipped']; ?>
            </p></div>
            <?php if (!empty($result['errors'])) : ?>
                <details><summary>جزئیات</summary><ul><?php foreach ($result['errors'] as $e) : ?><li><?php echo esc_html($e); ?></li><?php endforeach; ?></ul></details>
            <?php endif; ?>
        <?php endif; ?>

        <form method="post" style="margin-top:16px;">
            <?php wp_nonce_field('gymai_pop20', 'gymai_pop20_nonce'); ?>
            <p><label><input type="checkbox" name="update_existing" value="1" /> بروزرسانی پست‌های موجود با همین slug</label></p>
            <?php submit_button('اجرای batch — افزودن ۲۰ حرکت', 'primary', 'submit', false); ?>
        </form>

        <h2>لیست حرکات</h2>
        <ol><?php foreach (gymai_popular_20_exercise_definitions() as $d) : ?>
            <li><strong><?php echo esc_html($d['title']); ?></strong> — <code><?php echo esc_html($d['slug']); ?></code></li>
        <?php endforeach; ?></ol>
    </div>
    <?php
}
}

