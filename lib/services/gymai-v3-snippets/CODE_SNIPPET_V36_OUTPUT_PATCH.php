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

        gymai_v36_fix_false_lat($item, $text, $debug);
        gymai_v36_fix_pallof($item, $text, $debug);
        gymai_v36_fix_lunge_pattern($item, $text, $debug);
        gymai_v36_clean_targets($item, $debug);

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
                'message' => 'v3.6 classification fix active. Test: /wp-json/gymai/v3/exercises?per_page=5&debug=1',
            );
        },
        'permission_callback' => '__return_true',
    ));
}, 20);
