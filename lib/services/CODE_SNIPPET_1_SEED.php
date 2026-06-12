// GymAI — REST + Seed (نسخه امن — بدون <?php)
// محل اجرا: همه جا (Run everywhere) — الزامی برای دیدن فیلدها در API
// Seed: ابزارها → GymAI Seed → Run Seed Now

if (!function_exists('gymai_register_exercise_rest_meta_safe')) {
    function gymai_register_exercise_rest_meta_safe() {
        if (!function_exists('get_registered_meta_keys')) {
            return;
        }
        $registered = get_registered_meta_keys('post', 'exercises');
        if (!is_array($registered)) {
            $registered = array();
        }
        $keys = array(
            'target_area', 'short_description', 'movement_pattern', 'body_engagement',
            'estimated_1rm_formula', 'muscle_targets_json', 'met', 'movement_distance_cm',
            'calories_per_1000kg', 'exercise_difficulty_score', 'typical_rpe',
        );
        foreach ($keys as $key) {
            if (isset($registered[$key])) {
                continue;
            }
            register_post_meta('exercises', $key, array(
                'single'            => true,
                'type'              => 'string',
                'show_in_rest'      => true,
                'auth_callback'     => '__return_true',
            ));
        }
    }
    add_action('init', 'gymai_register_exercise_rest_meta_safe', 99);
}

if (!function_exists('gymai_exercise_seed_dataset')) {
    function gymai_exercise_seed_dataset() {
        static $cache = null;
        if ($cache !== null) {
            return $cache;
        }
        $cache = array(
            3831 => array(
                'name_app' => 'پرس سرشانه دستگاه',
                'other_names' => 'دستگاه پرس بالای سر نشسته, Machine Overhead Press, Seated Machine Shoulder Press',
                'main_muscle' => 'سرشانه',
                'secondary_muscles' => 'پشت‌بازو، ذوزنقه فوقانی',
                'difficulty' => 'مبتدی',
                'equipment' => 'ماشین',
                'exercise_type' => 'قدرتی',
                'target_area' => 'سرشانه',
                'short_description' => 'روی دستگاه بنشینید، کمر و پشت سر را به تکیه‌گاه بچسبانید. دستگیره‌ها را در ارتفاع شانه بگیرید. با بازدم دست‌ها را به بالا فشار دهید تا آرنج‌ها تقریباً صاف شوند (کامل قفل نکنید). با دم و کنترل ۲–۳ ثانیه برگردید. شانه را به گوش نکشید.',
                'tip_1' => 'کمر را کاملاً به پشتی دستگاه بچسبانید و در کل حرکت جدا نکنید',
                'tip_2' => 'دست‌ها را به بالا فشار دهید؛ آرنج را کامل قفل نکنید',
                'tip_3' => 'در نقطه بالا شانه را به سمت گوش بالا نبرید (شراگ نکنید)',
                'movement_pattern' => 'فشار عمودی',
                'body_engagement' => 'چند مفصلی',
                'met' => '5',
                'movement_distance_cm' => '50',
                'calories_per_1000kg' => '48',
                'exercise_difficulty_score' => '5',
                'estimated_1rm_formula' => 'برزیکی',
                'typical_rpe' => '7',
                'muscle_targets' => array('shoulder_anterior' => 85, 'shoulder_lateral' => 90, 'shoulder_posterior' => 30, 'triceps' => 40, 'back_trap' => 35, 'abs' => 20),
            ),
            3832 => array(
                'name_app' => 'پرس سینه دستگاه',
                'other_names' => 'Machine Chest Press, Seated Chest Press',
                'main_muscle' => 'سینه',
                'secondary_muscles' => 'سرشانه قدامی، پشت‌بازو',
                'difficulty' => 'مبتدی',
                'equipment' => 'ماشین',
                'exercise_type' => 'قدرتی',
                'target_area' => 'سینه',
                'short_description' => 'روی دستگاه بنشینید، کمر و تیغه‌های شانه را به پشتی بچسبانید. شانه‌ها را پایین و عقب ببرید. با بازدم دستگیره‌ها را به جلو فشار دهید؛ آرنج را کامل قفل نکنید. یک ثانیه مکث و انقباض سینه. با دم آهسته برگردید.',
                'tip_1' => 'شانه‌ها را به سمت پایین و عقب ببرید (قفسه سینه باز شود)',
                'tip_2' => 'در نقطه بالا آرنج را کامل قفل نکنید',
                'tip_3' => 'تیغه‌های شانه را در تمام حرکت به پشتی بچسبانید',
                'movement_pattern' => 'فشار افقی',
                'body_engagement' => 'چند مفصلی',
                'met' => '5.5',
                'movement_distance_cm' => '45',
                'calories_per_1000kg' => '52',
                'exercise_difficulty_score' => '5',
                'estimated_1rm_formula' => 'برزیکی',
                'typical_rpe' => '7.5',
                'muscle_targets' => array('chest_upper' => 60, 'chest_middle' => 90, 'chest_lower' => 50, 'shoulder_anterior' => 40, 'triceps' => 35, 'abs' => 15),
            ),
            3842 => array(
                'name_app' => 'پشت پا دستگاه',
                'other_names' => 'Lying Leg Curl, Seated Leg Curl',
                'main_muscle' => 'همسترینگ',
                'secondary_muscles' => 'ساق پا (دوقلو)',
                'difficulty' => 'مبتدی',
                'equipment' => 'ماشین',
                'exercise_type' => 'قدرتی',
                'target_area' => 'همسترینگ',
                'short_description' => 'روی دستگاه دمر دراز بکشید، زانو روی لبه پد، پاشنه به غلتک. کمر را به پشتی بچسبانید. با بازدم پد را به باسن بکشید، ۱ ثانیه مکث. با دم ۲–۳ ثانیه برگردید.',
                'tip_1' => 'کمر را کاملاً به پشتی دستگاه بچسبانید و لگن را تثبیت کنید',
                'tip_2' => 'در نقطه بالا مکث کنید و انقباض همسترینگ را حس کنید',
                'tip_3' => 'فاز منفی را آهسته (۲–۳ ثانیه) انجام دهید',
                'movement_pattern' => 'لگد',
                'body_engagement' => 'تک مفصلی',
                'met' => '4.5',
                'movement_distance_cm' => '35',
                'calories_per_1000kg' => '42',
                'exercise_difficulty_score' => '4',
                'estimated_1rm_formula' => 'برزیکی',
                'typical_rpe' => '7',
                'muscle_targets' => array('hamstrings' => 95, 'glutes' => 15, 'calf' => 25, 'abs' => 10),
            ),
            3844 => array(
                'name_app' => 'زیربغل سیم‌کش',
                'other_names' => 'Lat Pulldown Wide Grip',
                'main_muscle' => 'پشت',
                'secondary_muscles' => 'دلتوئید خلفی، ذوزنقه، دوسر بازو',
                'difficulty' => 'مبتدی',
                'equipment' => 'کابل',
                'exercise_type' => 'قدرتی',
                'target_area' => 'پشت',
                'short_description' => 'روی دستگاه بنشینید، میله را با دست باز بگیرید. با بازدم آرنج‌ها را پایین بکشید تا میله بالای سینه برسد. با دم آهسته برگردید.',
                'tip_1' => 'میله را با دست باز (عرضه) بگیرید',
                'tip_2' => 'با آرنج بکشید، نه با بازو',
                'tip_3' => 'در نقطه پایین سینه را به جلو بدهید و منقبض کنید',
                'movement_pattern' => 'کشش عمودی',
                'body_engagement' => 'چند مفصلی',
                'met' => '5',
                'movement_distance_cm' => '50',
                'calories_per_1000kg' => '45',
                'exercise_difficulty_score' => '3',
                'estimated_1rm_formula' => 'برزیکی',
                'typical_rpe' => '7.5',
                'muscle_targets' => array('back_lat' => 95, 'back_trap' => 70, 'shoulder_posterior' => 35, 'biceps' => 25, 'triceps' => 15),
            ),
            3847 => array(
                'name_app' => 'اسکات هالتر',
                'other_names' => 'Barbell Squat, Squat',
                'main_muscle' => 'پا',
                'secondary_muscles' => 'همسترینگ، باسن، سرینی',
                'difficulty' => 'متوسط',
                'equipment' => 'هالتر',
                'exercise_type' => 'قدرتی',
                'target_area' => 'پا',
                'short_description' => 'هالتر روی شانه، پاها به عرض شانه، کمر صاف. با کنترل باسن را عقب بدهید تا ران‌ها با زمین موازی شوند. با بازدم به بالا برگردید.',
                'tip_1' => 'کمر را صاف نگه دارید و سینه را باز کنید',
                'tip_2' => 'زانوها را همجهت با انگشتان پا حرکت دهید',
                'tip_3' => 'در پایین‌ترین نقطه ران‌ها با زمین موازی شوند',
                'movement_pattern' => 'اسکوات',
                'body_engagement' => 'چند مفصلی',
                'met' => '6',
                'movement_distance_cm' => '60',
                'calories_per_1000kg' => '55',
                'exercise_difficulty_score' => '7',
                'estimated_1rm_formula' => 'برزیکی',
                'typical_rpe' => '8',
                'muscle_targets' => array('quads' => 95, 'hamstrings' => 70, 'glutes' => 80, 'abs' => 40, 'lower_back' => 35),
            ),
            3849 => array(
                'name_app' => 'جلوبازو دمبل نشسته',
                'other_names' => 'Seated Dumbbell Curl',
                'main_muscle' => 'جلوبازو',
                'secondary_muscles' => 'ساعد',
                'difficulty' => 'مبتدی',
                'equipment' => 'دمبل',
                'exercise_type' => 'حجمی',
                'target_area' => 'جلوبازو',
                'short_description' => 'روی نیمکت بنشینید. با بازدم به شانه بکشید؛ در اوج مچ را به بیرون بچرخانید. با دم آهسته پایین بیاورید.',
                'tip_1' => 'پشت را به نیمکت بچسبانید',
                'tip_2' => 'در اوج مچ را به بیرون بچرخانید',
                'tip_3' => 'فاز منفی را آهسته انجام دهید',
                'movement_pattern' => 'کشش عمودی',
                'body_engagement' => 'تک مفصلی',
                'met' => '3.5',
                'movement_distance_cm' => '45',
                'calories_per_1000kg' => '37',
                'exercise_difficulty_score' => '3',
                'estimated_1rm_formula' => 'برزیکی',
                'typical_rpe' => '7',
                'muscle_targets' => array('biceps' => 95, 'forearms' => 40),
            ),
            3851 => array(
                'name_app' => 'نشر جانب دمبل',
                'other_names' => 'Dumbbell Lateral Raise',
                'main_muscle' => 'سرشانه',
                'secondary_muscles' => 'ذوزنقه فوقانی',
                'difficulty' => 'مبتدی',
                'equipment' => 'دمبل',
                'exercise_type' => 'حجمی',
                'target_area' => 'سرشانه',
                'short_description' => 'صاف بایستید. با بازدم دمبل‌ها را تا همسطح شانه بالا ببرید. با دم آهسته پایین.',
                'tip_1' => 'مچ را صاف نگه دارید',
                'tip_2' => 'آرنج را کمی خمیده نگه دارید',
                'tip_3' => 'وزنه را تا همسطح شانه بالا ببرید',
                'movement_pattern' => 'فشار عمودی',
                'body_engagement' => 'تک مفصلی',
                'met' => '4',
                'movement_distance_cm' => '50',
                'calories_per_1000kg' => '40',
                'exercise_difficulty_score' => '3',
                'estimated_1rm_formula' => 'برزیکی',
                'typical_rpe' => '7',
                'muscle_targets' => array('shoulder_lateral' => 90, 'shoulder_anterior' => 30, 'back_trap' => 20, 'forearms' => 15),
            ),
            3853 => array(
                'name_app' => 'پشت بازو سیم‌کش',
                'other_names' => 'Triceps Pushdown',
                'main_muscle' => 'پشت‌بازو',
                'secondary_muscles' => 'ساعد',
                'difficulty' => 'مبتدی',
                'equipment' => 'کابل',
                'exercise_type' => 'قدرتی',
                'target_area' => 'پشت‌بازو',
                'short_description' => 'روبروی سیم‌کش، آرنج به بدن. با بازدم میله را پایین فشار دهید. با دم آهسته برگردید.',
                'tip_1' => 'آرنج را ثابت و چسبیده به بدن نگه دارید',
                'tip_2' => 'در نقطه پایین مکث کنید',
                'tip_3' => 'فاز منفی را آهسته انجام دهید',
                'movement_pattern' => 'فشار عمودی',
                'body_engagement' => 'تک مفصلی',
                'met' => '4',
                'movement_distance_cm' => '40',
                'calories_per_1000kg' => '38',
                'exercise_difficulty_score' => '2',
                'estimated_1rm_formula' => 'برزیکی',
                'typical_rpe' => '7',
                'muscle_targets' => array('triceps' => 95, 'forearms' => 25),
            ),
            3855 => array(
                'name_app' => 'زیربغل هالتر خمیده',
                'other_names' => 'Barbell Bent Over Row',
                'main_muscle' => 'پشت',
                'secondary_muscles' => 'دلتوئید خلفی، ذوزنقه، دوسر بازو',
                'difficulty' => 'مبتدی',
                'equipment' => 'هالتر',
                'exercise_type' => 'قدرتی',
                'target_area' => 'پشت',
                'short_description' => 'هالتر با دست باز، بالاتنه ۴۵ درجه، کمر صاف. با بازدم هالتر را به پایین شکم بکشید. با دم آهسته برگردید.',
                'tip_1' => 'کمر را صاف نگه دارید',
                'tip_2' => 'هالتر را به پایین شکم بکشید',
                'tip_3' => 'در اوج تیغه‌های شانه را به هم فشار دهید',
                'movement_pattern' => 'کشش افقی',
                'body_engagement' => 'چند مفصلی',
                'met' => '5.5',
                'movement_distance_cm' => '55',
                'calories_per_1000kg' => '50',
                'exercise_difficulty_score' => '5',
                'estimated_1rm_formula' => 'برزیکی',
                'typical_rpe' => '8',
                'muscle_targets' => array('back_lat' => 95, 'back_trap' => 75, 'shoulder_posterior' => 65, 'biceps' => 50, 'forearms' => 40, 'lower_back' => 40),
            ),
            3857 => array(
                'name_app' => 'ددلیفت رومانیایی',
                'other_names' => 'RDL, Romanian Deadlift',
                'main_muscle' => 'همسترینگ',
                'secondary_muscles' => 'باسن، کمر، چهارسر ران',
                'difficulty' => 'متوسط',
                'equipment' => 'هالتر',
                'exercise_type' => 'قدرتی',
                'target_area' => 'همسترینگ',
                'short_description' => 'صاف بایستید، هالتر جلوی ران، کمر صاف. با دم باسن عقب و هالتر پایین تا کشش همسترینگ. با بازدم باسن جلو. هرگز کمر قوز نکنید.',
                'tip_1' => 'کمر را کاملاً صاف نگه دارید',
                'tip_2' => 'فاز منفی را آرام انجام دهید',
                'tip_3' => 'زانوها را کمی خمیده نگه دارید',
                'movement_pattern' => 'لگد',
                'body_engagement' => 'چند مفصلی',
                'met' => '6',
                'movement_distance_cm' => '60',
                'calories_per_1000kg' => '55',
                'exercise_difficulty_score' => '7',
                'estimated_1rm_formula' => 'برزیکی',
                'typical_rpe' => '8',
                'muscle_targets' => array('hamstrings' => 95, 'glutes' => 85, 'quads' => 30, 'lower_back' => 40, 'forearms' => 35),
            ),
        );
        return $cache;
    }
}

if (!function_exists('gymai_run_exercise_meta_seed')) {
    function gymai_run_exercise_meta_seed() {
        $dataset = gymai_exercise_seed_dataset();
        $updated = 0;
        $skipped = 0;
        $errors = array();
        $preserve = array('views_count', 'likes_count', 'video_url');
        foreach ($dataset as $post_id => $data) {
            $post = get_post($post_id);
            if (!$post || $post->post_type !== 'exercises') {
                $errors[] = 'Post ' . $post_id . ' not found';
                $skipped++;
                continue;
            }
            $muscle_targets = array();
            if (isset($data['muscle_targets']) && is_array($data['muscle_targets'])) {
                $muscle_targets = $data['muscle_targets'];
            }
            foreach ($data as $key => $value) {
                if ($key === 'muscle_targets' || in_array($key, $preserve, true)) {
                    continue;
                }
                if ($value === null || $value === '') {
                    continue;
                }
                update_post_meta($post_id, $key, is_string($value) ? $value : (string) $value);
            }
            if (!empty($muscle_targets)) {
                $json_flags = defined('JSON_UNESCAPED_UNICODE') ? JSON_UNESCAPED_UNICODE : 0;
                update_post_meta($post_id, 'muscle_targets_json', wp_json_encode($muscle_targets, $json_flags));
            }
            update_post_meta($post_id, '_gymai_seeded_at', (string) time());
            $updated++;
        }
        return array('updated' => $updated, 'skipped' => $skipped, 'errors' => $errors);
    }
}

if (!function_exists('gymai_exercise_seed_admin_menu')) {
    function gymai_exercise_seed_admin_menu() {
        add_management_page(
            'GymAI Seed',
            'GymAI Seed',
            'manage_options',
            'gymai-exercise-seed',
            'gymai_exercise_seed_admin_page'
        );
    }
    add_action('admin_menu', 'gymai_exercise_seed_admin_menu');
}

if (!function_exists('gymai_exercise_seed_admin_page')) {
    function gymai_exercise_seed_admin_page() {
        if (!current_user_can('manage_options')) {
            wp_die('No access');
        }
        $result = null;
        if (isset($_POST['gymai_seed_nonce']) && wp_verify_nonce(sanitize_text_field(wp_unslash($_POST['gymai_seed_nonce'])), 'gymai_seed_exercises')) {
            $result = gymai_run_exercise_meta_seed();
        }
        $dataset = gymai_exercise_seed_dataset();
        echo '<div class="wrap"><h1>GymAI Seed</h1>';
        echo '<p>Count: <strong>' . esc_html((string) count($dataset)) . '</strong></p>';
        echo '<form method="post">';
        wp_nonce_field('gymai_seed_exercises', 'gymai_seed_nonce');
        submit_button('Run Seed Now', 'primary', 'submit', true);
        echo '</form>';
        if (is_array($result)) {
            $cls = ((int) $result['updated'] > 0) ? 'notice-success' : 'notice-warning';
            echo '<div class="notice ' . esc_attr($cls) . '"><p><strong>Updated:</strong> ' . (int) $result['updated'];
            echo ' — <strong>Skipped:</strong> ' . (int) $result['skipped'] . '</p>';
            if (!empty($result['errors'])) {
                echo '<ul>';
                foreach ($result['errors'] as $err) {
                    echo '<li>' . esc_html($err) . '</li>';
                }
                echo '</ul>';
            }
            echo '</div>';
        }
        echo '<p>بعد از Seed، API را رفرش کن. اگر Updated=0 بود، فایل <code>gymai-seed-once.php</code> را از ریشه سایت اجرا کن.</p>';
        echo '</div>';
    }
}
