// ============================================================
// GymAI v3.6 — Classification Fix (Output Patch)
// Code Snippets → Run everywhere
// روی /wp-json/gymai/v3/exercises اعمال می‌شود (priority 1200 — بعد از v3.1 و v3.2)
// ریشه باگ: needle «لت» داخل «هالتر» match می‌شد → back_lat اشتباه
// ============================================================

if (!defined('ABSPATH')) {
    exit;
}

if (!function_exists('gymai_v36_label')) {
    function gymai_v36_label($key) {
        $map = array(
            'chest' => 'سینه / کلی',
            'chest_lower' => 'سینه پایینی',
            'back_lat' => 'زیربغل / لات',
            'triceps' => 'پشت‌بازو',
            'biceps' => 'جلوبازو',
            'quads' => 'چهارسر ران',
            'hamstrings' => 'همسترینگ',
            'glutes' => 'باسن / گلوت',
            'abs' => 'شکم / راست شکمی',
            'obliques' => 'مورب شکمی',
            'shoulder_posterior' => 'سرشانه خلفی',
            'traps' => 'ذوزنقه / کول',
            'rhomboids' => 'رومبوئید',
            'forearms' => 'ساعد',
            'lower_back' => 'کمر / ارکتور اسپاین',
            'full_body' => 'کل بدن',
            'calves' => 'ساق پا',
        );
        return isset($map[$key]) ? $map[$key] : $key;
    }
}

if (!function_exists('gymai_v36_movement_label')) {
    function gymai_v36_movement_label($key) {
        $map = array(
            'elbow_extension' => 'باز کردن آرنج / Triceps Extension',
            'squat' => 'اسکوات / Knee Dominant',
            'lunge' => 'لانج / تک‌پا',
            'anti_rotation' => 'ضد چرخش / Anti-Rotation',
            'vertical_pull' => 'کشش عمودی / مثل لت و بارفیکس',
            'horizontal_pull' => 'کشش افقی / مثل قایقی',
            'gait' => 'گام / پیاده‌روی',
            'cardio' => 'هوازی',
        );
        return isset($map[$key]) ? $map[$key] : $key;
    }
}

if (!function_exists('gymai_v36_get')) {
    function gymai_v36_get($item, $key) {
        if (!isset($item['classification'][$key])) {
            return '';
        }
        $v = $item['classification'][$key];
        return is_scalar($v) ? (string) $v : '';
    }
}

if (!function_exists('gymai_v36_set')) {
    function gymai_v36_set(&$item, $key, $value) {
        if (!isset($item['classification']) || !is_array($item['classification'])) {
            $item['classification'] = array();
        }
        $item['classification'][$key] = $value;
        $label_key = $key . '_label';
        if ($key === 'main_muscle') {
            $item['classification'][$label_key] = gymai_v36_label($value);
        } elseif ($key === 'movement_pattern') {
            $item['classification'][$label_key] = gymai_v36_movement_label($value);
        }
    }
}

if (!function_exists('gymai_v36_set_main')) {
    function gymai_v36_set_main(&$item, $key) {
        gymai_v36_set($item, 'main_muscle', $key);
    }
}

if (!function_exists('gymai_v36_set_secondary')) {
    function gymai_v36_set_secondary(&$item, $keys) {
        $keys = array_values(array_unique(array_filter((array) $keys)));
        if (!isset($item['classification']) || !is_array($item['classification'])) {
            $item['classification'] = array();
        }
        $item['classification']['secondary_muscles'] = $keys;
        $item['classification']['secondary_muscle_labels'] = array_map('gymai_v36_label', $keys);
        $item['classification']['secondary_muscle_unknowns'] = array();
    }
}

if (!function_exists('gymai_v36_set_movement')) {
    function gymai_v36_set_movement(&$item, $key) {
        gymai_v36_set($item, 'movement_pattern', $key);
    }
}

if (!function_exists('gymai_v36_set_targets')) {
    function gymai_v36_set_targets(&$item, $targets) {
        $clean = array();
        foreach ((array) $targets as $k => $v) {
            $v = (int) $v;
            if ($k !== '' && $v > 0) {
                $clean[$k] = max(0, min(100, $v));
            }
        }
        arsort($clean, SORT_NUMERIC);
        $item['muscle_targets'] = $clean;
    }
}

if (!function_exists('gymai_v36_item_text')) {
    function gymai_v36_item_text($item) {
        $parts = array();
        foreach (array('id', 'title', 'name_app', 'slug_decoded', 'slug') as $key) {
            if (!empty($item[$key]) && is_scalar($item[$key])) {
                $parts[] = (string) $item[$key];
            }
        }
        if (!empty($item['aliases']) && is_array($item['aliases'])) {
            $parts[] = implode(' ', $item['aliases']);
        }
        if (!empty($item['description']['short']) && is_scalar($item['description']['short'])) {
            $parts[] = (string) $item['description']['short'];
        }
        if (!empty($item['classification']['target_area'])) {
            $parts[] = (string) $item['classification']['target_area'];
        }
        return mb_strtolower(implode(' ', $parts), 'UTF-8');
    }
}

if (!function_exists('gymai_v36_contains_any')) {
    function gymai_v36_contains_any($text, $needles) {
        foreach ((array) $needles as $needle) {
            $needle = mb_strtolower(trim((string) $needle), 'UTF-8');
            if ($needle !== '' && mb_strpos($text, $needle, 0, 'UTF-8') !== false) {
                return true;
            }
        }
        return false;
    }
}

if (!function_exists('gymai_v36_note')) {
    function gymai_v36_note(&$item, $msg, $debug) {
        if (!$debug) {
            return;
        }
        if (!isset($item['v3_6_patch_notes']) || !is_array($item['v3_6_patch_notes'])) {
            $item['v3_6_patch_notes'] = array();
        }
        $item['v3_6_patch_notes'][] = $msg;
    }
}

if (!function_exists('gymai_v36_id_overrides')) {
    function gymai_v36_id_overrides() {
        return array(
            // فشار پشت بازو هالتر — Skull Crusher
            4011 => array(
                'main_muscle' => 'triceps',
                'secondary_muscles' => array(),
                'movement_pattern' => 'elbow_extension',
                'body_engagement' => 'isolation',
                'mechanics_type' => 'isolation',
                'force_type' => 'push',
                'posture' => 'supine',
                'joint_focus' => 'elbow',
                'muscle_targets' => array('triceps' => 95, 'forearms' => 25),
            ),
            // اسکات با مکث
            4016 => array(
                'main_muscle' => 'quads',
                'secondary_muscles' => array('glutes', 'hamstrings'),
                'movement_pattern' => 'squat',
                'body_engagement' => 'compound',
                'mechanics_type' => 'compound',
                'force_type' => 'push',
                'posture' => 'standing',
                'joint_focus' => 'knee_hip',
                'muscle_targets' => array(
                    'quads' => 95, 'glutes' => 75, 'hamstrings' => 55,
                    'abs' => 35, 'lower_back' => 30,
                ),
            ),
            // پالوف پرس
            4019 => array(
                'main_muscle' => 'abs',
                'secondary_muscles' => array('obliques'),
                'movement_pattern' => 'anti_rotation',
                'body_engagement' => 'isolation',
                'mechanics_type' => 'isolation',
                'force_type' => 'push',
                'posture' => 'standing',
                'joint_focus' => 'core_spine',
                'muscle_targets' => array('abs' => 85, 'obliques' => 70, 'glutes' => 30),
            ),
            // لانج با هالتر
            4022 => array(
                'main_muscle' => 'quads',
                'secondary_muscles' => array('glutes', 'hamstrings'),
                'movement_pattern' => 'lunge',
                'body_engagement' => 'compound',
                'mechanics_type' => 'compound',
                'force_type' => 'push',
                'posture' => 'standing',
                'joint_focus' => 'knee_hip',
                'muscle_targets' => array('quads' => 85, 'glutes' => 75, 'hamstrings' => 45),
            ),
            // لانج عقب — movement_pattern خالی بود
            4023 => array(
                'main_muscle' => 'quads',
                'secondary_muscles' => array('glutes'),
                'movement_pattern' => 'lunge',
                'body_engagement' => 'compound',
                'mechanics_type' => 'compound',
                'force_type' => 'push',
                'posture' => 'standing',
                'joint_focus' => 'knee_hip',
                'muscle_targets' => array('quads' => 80, 'glutes' => 75),
            ),
            // زیربغل تک بازو — secondary غنی‌تر
            4013 => array(
                'main_muscle' => 'back_lat',
                'secondary_muscles' => array('biceps', 'shoulder_posterior', 'traps'),
                'movement_pattern' => 'vertical_pull',
                'muscle_targets' => array(
                    'back_lat' => 90, 'biceps' => 35,
                    'shoulder_posterior' => 25, 'lower_traps' => 25,
                ),
            ),
        );
    }
}

if (!function_exists('gymai_v36_apply_override')) {
    function gymai_v36_apply_override(&$item, $override, $debug) {
        if (isset($override['main_muscle'])) {
            gymai_v36_set_main($item, $override['main_muscle']);
        }
        if (isset($override['secondary_muscles'])) {
            gymai_v36_set_secondary($item, $override['secondary_muscles']);
        }
        if (isset($override['movement_pattern'])) {
            gymai_v36_set_movement($item, $override['movement_pattern']);
        }
        foreach (array('body_engagement', 'mechanics_type', 'force_type', 'posture', 'joint_focus') as $key) {
            if (isset($override[$key])) {
                gymai_v36_set($item, $key, $override[$key]);
            }
        }
        if (isset($override['muscle_targets']) && is_array($override['muscle_targets'])) {
            gymai_v36_set_targets($item, $override['muscle_targets']);
        }
        gymai_v36_note($item, 'Applied v3.6 ID override.', $debug);
    }
}

if (!function_exists('gymai_v36_fix_false_lat')) {
    /**
     * اگر main=back_lat ولی movement/title نشان می‌دهد حرکت پشت‌بازو یا پاست — اصلاح کن.
     */
    function gymai_v36_fix_false_lat(&$item, $text, $debug) {
        $main = gymai_v36_get($item, 'main_muscle');
        $movement = gymai_v36_get($item, 'movement_pattern');

        if ($main !== 'back_lat') {
            return;
        }

        // پشت بازو
        if ($movement === 'elbow_extension'
            || gymai_v36_contains_any($text, array('پشت بازو', 'پشت‌بازو', 'triceps', 'skull crusher', 'french press'))
        ) {
            gymai_v36_set_main($item, 'triceps');
            gymai_v36_set_secondary($item, array());
            gymai_v36_set_movement($item, 'elbow_extension');
            gymai_v36_set_targets($item, array('triceps' => 95, 'forearms' => 25));
            gymai_v36_note($item, 'Fixed false back_lat → triceps (elbow extension / title).', $debug);
            return;
        }

        // پا — اسکات / لانج
        if (in_array($movement, array('squat', 'lunge'), true)
            || gymai_v36_contains_any($text, array('اسکات', 'اسکوات', 'squat', 'لانج', 'lunge', 'pause squat'))
        ) {
            gymai_v36_set_main($item, 'quads');
            if ($movement === '') {
                gymai_v36_set_movement($item, gymai_v36_contains_any($text, array('لانج', 'lunge')) ? 'lunge' : 'squat');
            }
            gymai_v36_set_targets($item, array(
                'quads' => 90, 'glutes' => 75, 'hamstrings' => 50,
            ));
            gymai_v36_note($item, 'Fixed false back_lat → quads (leg movement).', $debug);
            return;
        }

        // هیپ تراست / پل باسن
        if (gymai_v36_contains_any($text, array('هیپ تراست', 'هیپ‌تراست', 'پل باسن', 'hip thrust', 'glute bridge'))) {
            gymai_v36_set_main($item, 'glutes');
            gymai_v36_set_secondary($item, array('hamstrings'));
            gymai_v36_set_targets($item, array('glutes' => 95, 'hamstrings' => 45));
            gymai_v36_note($item, 'Fixed false back_lat → glutes (hip thrust).', $debug);
            return;
        }

        // جلو بازو
        if (gymai_v36_contains_any($text, array('جلو بازو', 'جلوبازو', 'bicep'))
            && !gymai_v36_contains_any($text, array('پشت بازو', 'پشت‌بازو', 'leg curl'))
        ) {
            gymai_v36_set_main($item, 'biceps');
            gymai_v36_set_secondary($item, array('forearms'));
            gymai_v36_set_targets($item, array('biceps' => 95, 'forearms' => 30));
            gymai_v36_note($item, 'Fixed false back_lat → biceps (curl).', $debug);
            return;
        }

        // ساق
        if (gymai_v36_contains_any($text, array('ساق', 'calf'))) {
            gymai_v36_set_main($item, 'calves');
            gymai_v36_set_secondary($item, array());
            gymai_v36_set_targets($item, array('calves' => 95));
            gymai_v36_note($item, 'Fixed false back_lat → calves.', $debug);
            return;
        }

        // Core — پالوف
        if (gymai_v36_contains_any($text, array('پالوف', 'pallof', 'ضد چرخش'))
            || gymai_v36_get($item, 'target_area') === 'Core'
        ) {
            gymai_v36_set_main($item, 'abs');
            gymai_v36_set_secondary($item, array('obliques'));
            gymai_v36_set_movement($item, 'anti_rotation');
            gymai_v36_set_targets($item, array('abs' => 85, 'obliques' => 70));
            gymai_v36_note($item, 'Fixed false back_lat/quads → abs (Pallof/core).', $debug);
        }
    }
}

if (!function_exists('gymai_v36_fix_pallof')) {
    function gymai_v36_fix_pallof(&$item, $text, $debug) {
        if (!gymai_v36_contains_any($text, array('پالوف', 'pallof'))) {
            return;
        }
        $main = gymai_v36_get($item, 'main_muscle');
        if ($main === 'abs') {
            return;
        }
        gymai_v36_set_main($item, 'abs');
        gymai_v36_set_secondary($item, array('obliques'));
        gymai_v36_set_movement($item, 'anti_rotation');
        gymai_v36_set($item, 'body_engagement', 'isolation');
        gymai_v36_set($item, 'mechanics_type', 'isolation');
        gymai_v36_set($item, 'joint_focus', 'core_spine');
        gymai_v36_set_targets($item, array('abs' => 85, 'obliques' => 70, 'glutes' => 30));
        gymai_v36_note($item, 'Pallof press normalized to abs / anti_rotation.', $debug);
    }
}

if (!function_exists('gymai_v36_fix_lunge_pattern')) {
    function gymai_v36_fix_lunge_pattern(&$item, $text, $debug) {
        if (gymai_v36_get($item, 'movement_pattern') !== '') {
            return;
        }
        if (!gymai_v36_contains_any($text, array('لانج', 'lunge'))) {
            return;
        }
        gymai_v36_set_movement($item, 'lunge');
        gymai_v36_set($item, 'joint_focus', 'knee_hip');
        gymai_v36_note($item, 'Filled missing movement_pattern → lunge.', $debug);
    }
}

if (!function_exists('gymai_v36_clean_targets')) {
    function gymai_v36_clean_targets(&$item, $debug) {
        $main = gymai_v36_get($item, 'main_muscle');
        $movement = gymai_v36_get($item, 'movement_pattern');
        $targets = isset($item['muscle_targets']) && is_array($item['muscle_targets'])
            ? $item['muscle_targets'] : array();

        if (empty($targets)) {
            return;
        }

        $pull_muscles = array('back_lat', 'biceps', 'shoulder_posterior', 'lower_traps', 'rhomboids', 'middle_traps');
        $leg_muscles = array('quads', 'glutes', 'hamstrings', 'calves', 'adductors');

        $remove = array();
        if ($main === 'triceps' || $movement === 'elbow_extension') {
            $remove = $pull_muscles;
        } elseif (in_array($main, array('quads', 'glutes', 'hamstrings'), true)
            || in_array($movement, array('squat', 'lunge', 'knee_dominant_press'), true)
        ) {
            $remove = array('back_lat', 'biceps', 'shoulder_posterior', 'lower_traps');
        } elseif ($main === 'abs' || $movement === 'anti_rotation') {
            $remove = array('quads', 'back_lat');
        }

        $changed = false;
        foreach ($remove as $key) {
            if (isset($targets[$key])) {
                unset($targets[$key]);
                $changed = true;
            }
        }

        if ($changed) {
            gymai_v36_set_targets($item, $targets);
            gymai_v36_note($item, 'Cleaned polluted muscle_targets for main=' . $main . '.', $debug);
        }
    }
}

if (!function_exists('gymai_v36_classify_by_title')) {
    /**
     * قوانین همسو با sql/fix_ai_exercises_main_muscle.sql و AiExerciseMuscleNormalizer.
     * هدف: جلوگیری از نوشتن دوبارهٔ main/heatmap غلط به Supabase هنگام sync اپ.
     * عمداً needle lone «لت» استفاده نمی‌شود (داخل «هالتر»/«اسالت» match می‌شد).
     *
     * @return array|null override یا null اگر مطمئن نیستیم
     */
    function gymai_v36_classify_by_title($text) {
        $text = mb_strtolower((string) $text, 'UTF-8');
        if ($text === '') {
            return null;
        }

        $has = function ($needles) use ($text) {
            return gymai_v36_contains_any($text, $needles);
        };
        $has_not = function ($needles) use ($text) {
            return !gymai_v36_contains_any($text, $needles);
        };

        // --- سینه ---
        if ($has(array('پرس سینه', 'بالا سینه', 'بالاسینه', 'بنچ', 'bench press', 'قفسه', 'کراس اور', 'کراس‌اور', 'فلای', 'پک دک', 'pec deck', 'سوندر', 'گیوتین', 'اسپوتو'))) {
            if ($has(array('دست جمع', 'close grip')) && $has_not(array('فلای', 'کراس'))) {
                return array(
                    'main_muscle' => 'triceps',
                    'secondary_muscles' => array('chest', 'shoulder_anterior'),
                    'muscle_targets' => array('triceps' => 90, 'chest' => 70, 'shoulder_anterior' => 35),
                );
            }
            return array(
                'main_muscle' => 'chest',
                'secondary_muscles' => array('triceps', 'shoulder_anterior'),
                'muscle_targets' => array('chest' => 90, 'triceps' => 45, 'shoulder_anterior' => 40),
            );
        }
        if ($has(array('شنا سوئدی', 'شنای سوئدی', 'push-up', 'push up', 'pushup')) && $has_not(array('حلقه', 'ring row'))) {
            $main = $has(array('الماسی', 'diamond')) ? 'triceps' : 'chest';
            return array(
                'main_muscle' => $main,
                'secondary_muscles' => $main === 'triceps' ? array('chest', 'shoulder_anterior') : array('triceps', 'shoulder_anterior'),
                'muscle_targets' => $main === 'triceps'
                    ? array('triceps' => 90, 'chest' => 55, 'shoulder_anterior' => 40)
                    : array('chest' => 85, 'triceps' => 55, 'shoulder_anterior' => 40),
            );
        }
        if ($has(array('پول اور', 'پول‌اور', 'pullover'))) {
            return array(
                'main_muscle' => 'chest',
                'secondary_muscles' => array('back_lat', 'triceps'),
                'muscle_targets' => array('chest' => 75, 'back_lat' => 60, 'triceps' => 35),
            );
        }

        // --- سرشانه / کول ---
        if ($has(array('پرس سرشانه', 'آرنولد', 'overhead press', 'military press', 'میلیتری', 'ohp', 'پوش پرس', 'هنداستند'))) {
            return array(
                'main_muscle' => 'shoulder_anterior',
                'secondary_muscles' => array('triceps', 'shoulder_lateral'),
                'muscle_targets' => array('shoulder_anterior' => 90, 'triceps' => 45, 'shoulder_lateral' => 40),
            );
        }
        if ($has(array('نشر جانب', 'lateral raise'))) {
            return array(
                'main_muscle' => 'shoulder_lateral',
                'secondary_muscles' => array(),
                'muscle_targets' => array('shoulder_lateral' => 95),
            );
        }
        if ($has(array('نشر پشت', 'فیس پول', 'فیس‌پول', 'face pull', 'rear delt', 'فلای معکوس', 'ریورس فلای', 'ریورس پک', 'پاروی صورت'))) {
            return array(
                'main_muscle' => 'shoulder_posterior',
                'secondary_muscles' => array('rhomboids', 'traps'),
                'muscle_targets' => array('shoulder_posterior' => 92, 'rhomboids' => 50, 'traps' => 40),
            );
        }
        if ($has(array('شراگ', 'کول هالتر', 'کول دمبل', 'shrug', 'یوک واک'))) {
            return array(
                'main_muscle' => 'traps',
                'secondary_muscles' => array('forearms'),
                'muscle_targets' => array('traps' => 95, 'forearms' => 40),
            );
        }
        if ($has(array('نشر از جلو', 'نشر جلو', 'front raise'))) {
            return array(
                'main_muscle' => 'shoulder_anterior',
                'secondary_muscles' => array(),
                'muscle_targets' => array('shoulder_anterior' => 95),
            );
        }

        // --- بازو (قبل از پشت عمومی) ---
        if ($has(array('جلو بازو', 'جلوبازو', 'bicep', 'پریچر', 'اسپایدر', 'تمرکزی', 'دراگ کرل', 'زوتمن', 'اسکات کرل'))
            && $has_not(array('پشت بازو', 'پشت‌بازو', 'leg curl', 'همستر', 'پشت پا'))
        ) {
            return array(
                'main_muscle' => 'biceps',
                'secondary_muscles' => array('forearms'),
                'muscle_targets' => array('biceps' => 95, 'forearms' => 30),
            );
        }
        // کرل عمومی — فقط اگر curl بدون leg
        if ($has(array('curl')) && $has_not(array('leg curl', 'hamstring', 'پشت پا', 'پشت بازو'))) {
            return array(
                'main_muscle' => 'biceps',
                'secondary_muscles' => array('forearms'),
                'muscle_targets' => array('biceps' => 95, 'forearms' => 30),
            );
        }
        if ($has(array('پشت بازو', 'پشت‌بازو', 'triceps', 'اسکال', 'skull', 'فرنچ', 'french press', 'پوش‌داون', 'پوشداون', 'pushdown'))) {
            return array(
                'main_muscle' => 'triceps',
                'secondary_muscles' => array(),
                'muscle_targets' => array('triceps' => 95, 'forearms' => 25),
            );
        }
        if ($has(array('دیپ', 'dip')) && $has_not(array('هیپ', 'hip'))) {
            return array(
                'main_muscle' => 'triceps',
                'secondary_muscles' => array('chest', 'shoulder_anterior'),
                'muscle_targets' => array('triceps' => 85, 'chest' => 55, 'shoulder_anterior' => 40),
            );
        }

        // --- پایین‌تنه ---
        if ($has(array('هیپ تراست', 'هیپ‌تراست', 'پل باسن', 'گلات', 'گلوت بریج', 'hip thrust', 'glute bridge', 'کلام شل', 'فایر هایدرنت', 'خارج ران', 'ابداکشن'))) {
            return array(
                'main_muscle' => 'glutes',
                'secondary_muscles' => array('hamstrings'),
                'muscle_targets' => array('glutes' => 95, 'hamstrings' => 45),
            );
        }
        if ($has(array('داخل ران', 'اداکشن', 'اداکتر', 'کوپنهاگن', 'adductor'))) {
            return array(
                'main_muscle' => 'adductors',
                'secondary_muscles' => array('glutes'),
                'muscle_targets' => array('adductors' => 95, 'glutes' => 30),
            );
        }
        if ($has(array('پرس ساق', 'ساق پا', 'ساق ایستاده', 'ساق نشسته', 'ساق دونکی', 'کاف', 'تیبیالیس', 'calf'))) {
            return array(
                'main_muscle' => 'calves',
                'secondary_muscles' => array(),
                'muscle_targets' => array('calves' => 95),
            );
        }
        if ($has(array('رومانیایی', 'پشت پا', 'همسترینگ', 'nordic', 'leg curl', 'لگ کرل', 'جی اچ دی', 'ghr'))) {
            return array(
                'main_muscle' => 'hamstrings',
                'secondary_muscles' => array('glutes', 'calves'),
                'muscle_targets' => array('hamstrings' => 95, 'glutes' => 40, 'calves' => 25),
            );
        }
        if ($has(array('اسکات', 'اسکوات', 'پرس پا', 'لگ پرس', 'جلو پا', 'اکستنشن پا', 'لانج', 'هک اسکات', 'هاک اسکات', 'squat', 'lunge', 'leg press', 'leg extension', 'استپ آپ', 'وال سیت'))) {
            return array(
                'main_muscle' => 'quads',
                'secondary_muscles' => array('glutes', 'hamstrings'),
                'muscle_targets' => array('quads' => 90, 'glutes' => 70, 'hamstrings' => 45),
            );
        }

        // --- پشت (بدون lone «لت») ---
        if ($has(array(
            'زیربغل', 'بارفیکس', 'لت پول', 'لت‌پول', 'لت پولداون', 'پولدان', 'پول‌دان',
            'رویینگ', 'قایقی', 'تی بار', 'تی‌بار', 'مدوز', 'سیل رو', 'pulldown', 'pull-up', 'pull up', 'chin up', 'chin-up',
        )) && $has_not(array('روئینگ', 'rowing', 'بایک', 'bike', 'اسالت'))) {
            return array(
                'main_muscle' => 'back_lat',
                'secondary_muscles' => array('biceps', 'rhomboids'),
                'muscle_targets' => array('back_lat' => 90, 'biceps' => 45, 'rhomboids' => 40),
            );
        }
        if ($has(array('ددلیفت', 'deadlift', 'تراپ بار')) && $has_not(array('رومانیایی'))) {
            return array(
                'main_muscle' => 'lower_back',
                'secondary_muscles' => array('glutes', 'hamstrings', 'traps'),
                'muscle_targets' => array('lower_back' => 80, 'glutes' => 75, 'hamstrings' => 70, 'traps' => 55),
            );
        }
        // Ring row / inverted — عنوان فارسی اشتباه «شنا حلقه»
        if ($has(array('ring row', 'رویینگ حلقه', 'شنا حلقه', 'inverted row'))) {
            return array(
                'main_muscle' => 'back_lat',
                'secondary_muscles' => array('biceps', 'rhomboids'),
                'muscle_targets' => array('back_lat' => 82, 'biceps' => 48, 'rhomboids' => 40),
            );
        }

        // --- Core ---
        if ($has(array('پالوف', 'pallof'))) {
            return array(
                'main_muscle' => 'abs',
                'secondary_muscles' => array('obliques'),
                'movement_pattern' => 'anti_rotation',
                'muscle_targets' => array('abs' => 85, 'obliques' => 70),
            );
        }
        if ($has(array('چرخش روسی', 'توئیست', 'oblique', 'پهلو', 'ساید کرانچ', 'خم جانبی'))) {
            return array(
                'main_muscle' => 'obliques',
                'secondary_muscles' => array('abs'),
                'muscle_targets' => array('obliques' => 90, 'abs' => 55),
            );
        }
        if ($has(array('کرانچ', 'پلانک', 'دراز و نشست', 'اب ویل', 'چرخ شکم', 'وی آپ', 'هالو', 'ددباگ', 'لگ ریز', 'پای آویزان', 'crunch', 'plank'))) {
            return array(
                'main_muscle' => 'abs',
                'secondary_muscles' => array(),
                'muscle_targets' => array('abs' => 90),
            );
        }

        // --- فول‌بادی / کاردیو ---
        // «دوچرخه» تنها نه — با کرانچ دوچرخه قاطی نشود. این بلاک بعد از Core است.
        if ($has(array(
            'بورپی', 'برپی', 'فارمر', 'کلین', 'اسنچ', 'جرک', 'تراستر', 'وال بال',
            'اسالت', 'روئینگ ارگ', 'اسکی ارگ', 'اسلد', 'طناب نبرد', 'burpee',
            'تردمیل', 'treadmill', 'الپتیکال', 'elliptical', 'کراس ترینر', 'cross trainer',
            'دوچرخه ثابت', 'دوچرخه ایستاده', 'دوچرخه خوابیده',
            'stationary bike', 'exercise bike', 'upright bike',
        ))) {
            $is_walk = $has(array('پیاده', 'walk')) && $has_not(array('دویدن', 'run', 'jog'));
            return array(
                'main_muscle' => 'full_body',
                'secondary_muscles' => array('quads', 'hamstrings', 'glutes', 'calves'),
                'movement_pattern' => $is_walk ? 'gait' : 'cardio',
                'muscle_targets' => array('quads' => 50, 'glutes' => 45, 'hamstrings' => 40, 'calf' => 40, 'abs' => 30),
            );
        }

        return null;
    }
}

if (!function_exists('gymai_v36_normalize_main_key')) {
    function gymai_v36_normalize_main_key($main) {
        $map = array(
            'chest_upper' => 'chest',
            'chest_middle' => 'chest',
            'chest_lower' => 'chest',
            'shoulders' => 'shoulder_anterior',
            'lats' => 'back_lat',
            'calf' => 'calves',
            'back_trap' => 'traps',
            'traps_upper' => 'traps',
            'traps_middle' => 'traps',
        );
        $main = (string) $main;
        return isset($map[$main]) ? $map[$main] : $main;
    }
}

if (!function_exists('gymai_v36_fix_item')) {
    function gymai_v36_fix_item($item, $debug = false) {
        if (!is_array($item)) {
            return $item;
        }

        $id = isset($item['id']) ? (int) $item['id'] : 0;
        $text = gymai_v36_item_text($item);
        $overrides = gymai_v36_id_overrides();

        if ($id > 0 && isset($overrides[$id])) {
            gymai_v36_apply_override($item, $overrides[$id], $debug);
            return $item;
        }

        // نرمال‌سازی کلیدهای فرعی مثل chest_upper → chest
        $main_now = gymai_v36_get($item, 'main_muscle');
        $main_norm = gymai_v36_normalize_main_key($main_now);
        if ($main_norm !== '' && $main_norm !== $main_now) {
            gymai_v36_set_main($item, $main_norm);
            gymai_v36_note($item, 'Normalized main_muscle ' . $main_now . ' → ' . $main_norm, $debug);
        }

        // طبقه‌بندی قطعی بر اساس عنوان (همسو با SQL فیکس سوپابیس)
        $by_title = gymai_v36_classify_by_title($text);
        if (is_array($by_title) && !empty($by_title['main_muscle'])) {
            $inferred = $by_title['main_muscle'];
            $current = gymai_v36_normalize_main_key(gymai_v36_get($item, 'main_muscle'));
            $poisoned = in_array($current, array('back_lat', 'triceps', 'full_body', 'quads', ''), true)
                && $inferred !== $current;
            // همیشه اگر عنوان سینه/جلوبازو/هیپ‌تراست… با main فعلی تضاد دارد، اصلاح کن
            $hard_families = array('chest', 'biceps', 'triceps', 'glutes', 'calves', 'hamstrings', 'shoulder_anterior', 'shoulder_lateral', 'shoulder_posterior', 'traps', 'abs', 'obliques', 'quads', 'adductors', 'lower_back');
            if ($current === '' || $poisoned || ($inferred !== $current && in_array($inferred, $hard_families, true))) {
                // استثنا: اگر هر دو منطقی‌اند (مثلاً دیپ chest vs triceps) فقط وقتی current مسموم است عوض کن
                $ambiguous_ok = (
                    ($inferred === 'triceps' && $current === 'chest' && gymai_v36_contains_any($text, array('دیپ', 'dip', 'دست جمع')))
                    || ($inferred === 'chest' && $current === 'triceps' && gymai_v36_contains_any($text, array('دیپ', 'dip', 'دست جمع')))
                    || ($inferred === 'glutes' && $current === 'quads' && gymai_v36_contains_any($text, array('لانج', 'استپ')))
                    || ($inferred === 'quads' && $current === 'glutes' && gymai_v36_contains_any($text, array('لانج', 'استپ', 'لگ پرس پا بالا')))
                );
                if (!$ambiguous_ok || $current === '' || $poisoned) {
                    gymai_v36_apply_override($item, $by_title, $debug);
                    gymai_v36_note($item, 'Title classification: ' . $current . ' → ' . $inferred, $debug);
                }
            }
        }

        gymai_v36_fix_false_lat($item, $text, $debug);
        gymai_v36_fix_pallof($item, $text, $debug);
        gymai_v36_fix_lunge_pattern($item, $text, $debug);
        gymai_v36_clean_targets($item, $debug);

        // تضمین: main در heatmap هست
        $main = gymai_v36_normalize_main_key(gymai_v36_get($item, 'main_muscle'));
        $targets = isset($item['muscle_targets']) && is_array($item['muscle_targets']) ? $item['muscle_targets'] : array();
        if ($main !== '' && $main !== 'full_body' && empty($targets[$main])) {
            $targets[$main] = 90;
            gymai_v36_set_targets($item, $targets);
            gymai_v36_note($item, 'Ensured main_muscle present in muscle_targets.', $debug);
        }

        return $item;
    }
}

add_filter('rest_post_dispatch', function ($response, $server, $request) {
    if (!is_object($request) || !method_exists($request, 'get_route')) {
        return $response;
    }

    $route = (string) $request->get_route();
    if (strpos($route, '/gymai/v3/exercises') !== 0) {
        return $response;
    }

    if (is_wp_error($response) || !is_object($response) || !method_exists($response, 'get_data')) {
        return $response;
    }

    $data = $response->get_data();
    $debug = (bool) $request->get_param('debug');

    if (isset($data['items']) && is_array($data['items'])) {
        foreach ($data['items'] as $i => $item) {
            $data['items'][$i] = gymai_v36_fix_item($item, $debug);
        }
        $data['version'] = 'gymai/v3.6-patched';
        if ($debug) {
            $data['patch'] = array(
                'name' => 'GymAI v3.6 Classification Fix',
                'priority' => 1200,
                'note' => 'Fixes false back_lat from هالتر/لت substring + batch6 IDs.',
            );
        }
        $response->set_data($data);
        return $response;
    }

    if (isset($data['id'])) {
        $data = gymai_v36_fix_item($data, $debug);
        $data['version'] = 'gymai/v3.6-patched';
        if ($debug) {
            $data['patch'] = array(
                'name' => 'GymAI v3.6 Classification Fix',
                'priority' => 1200,
                'note' => 'Fixes false back_lat from هالتر/لت substring + batch6 IDs.',
            );
        }
        $response->set_data($data);
        return $response;
    }

    return $response;
}, 1200, 3);

add_action('rest_api_init', function () {
    register_rest_route('gymai/v3.6', '/ping', array(
        'methods' => 'GET',
        'callback' => function () {
            return array(
                'ok' => true,
                'version' => 'gymai/v3.6-patched',
                'message' => 'v3.6 classification fix active (title rules + ID overrides). Test: /wp-json/gymai/v3/exercises?per_page=5&debug=1',
            );
        },
        'permission_callback' => '__return_true',
    ));
}, 20);
