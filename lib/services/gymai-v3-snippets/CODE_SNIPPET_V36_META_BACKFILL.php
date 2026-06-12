// ============================================================
// GymAI v3.6 — Meta Backfill (ذخیره در دیتابیس)
// Code Snippets → Run everywhere
// ابزار ادمین: ابزارها → GymAI v3.6 Backfill
// فقط ۶ حرکت batch6 که classification اشتباه داشتند را اصلاح می‌کند.
// بعد از backfill، اپ Flutter (/wp/v2/exercises) هم درست می‌شود.
// ============================================================

if (!defined('ABSPATH')) {
    exit;
}

if (!defined('GYMAI_EXERCISE_POST_TYPE')) {
    define('GYMAI_EXERCISE_POST_TYPE', 'exercises');
}

if (!function_exists('gymai_v36_backfill_dataset')) {
    function gymai_v36_backfill_dataset() {
        return array(
            4011 => array(
                'main_muscle' => 'triceps',
                'secondary_muscle_keys' => array(),
                'movement_pattern' => 'elbow_extension',
                'body_engagement' => 'isolation',
                'mechanics_type' => 'isolation',
                'force_type' => 'push',
                'posture' => 'supine',
                'joint_focus' => 'elbow',
                'target_area' => 'پشت بازو',
                'muscle_targets_json' => array('triceps' => 95, 'forearms' => 25),
            ),
            4013 => array(
                'main_muscle' => 'back_lat',
                'secondary_muscle_keys' => array('biceps', 'shoulder_posterior', 'traps'),
                'movement_pattern' => 'vertical_pull',
                'muscle_targets_json' => array(
                    'back_lat' => 90, 'biceps' => 35,
                    'shoulder_posterior' => 25, 'lower_traps' => 25,
                ),
            ),
            4016 => array(
                'main_muscle' => 'quads',
                'secondary_muscle_keys' => array('glutes', 'hamstrings'),
                'movement_pattern' => 'squat',
                'body_engagement' => 'compound',
                'mechanics_type' => 'compound',
                'force_type' => 'push',
                'posture' => 'standing',
                'joint_focus' => 'knee_hip',
                'target_area' => 'پا',
                'muscle_targets_json' => array(
                    'quads' => 95, 'glutes' => 75, 'hamstrings' => 55,
                    'abs' => 35, 'lower_back' => 30,
                ),
            ),
            4019 => array(
                'main_muscle' => 'abs',
                'secondary_muscle_keys' => array('obliques'),
                'movement_pattern' => 'anti_rotation',
                'body_engagement' => 'isolation',
                'mechanics_type' => 'isolation',
                'force_type' => 'push',
                'posture' => 'standing',
                'joint_focus' => 'core_spine',
                'target_area' => 'Core',
                'muscle_targets_json' => array('abs' => 85, 'obliques' => 70, 'glutes' => 30),
            ),
            4022 => array(
                'main_muscle' => 'quads',
                'secondary_muscle_keys' => array('glutes', 'hamstrings'),
                'movement_pattern' => 'lunge',
                'body_engagement' => 'compound',
                'mechanics_type' => 'compound',
                'force_type' => 'push',
                'posture' => 'standing',
                'joint_focus' => 'knee_hip',
                'target_area' => 'پا',
                'muscle_targets_json' => array('quads' => 85, 'glutes' => 75, 'hamstrings' => 45),
            ),
            4023 => array(
                'main_muscle' => 'quads',
                'secondary_muscle_keys' => array('glutes'),
                'movement_pattern' => 'lunge',
                'body_engagement' => 'compound',
                'mechanics_type' => 'compound',
                'force_type' => 'push',
                'posture' => 'standing',
                'joint_focus' => 'knee_hip',
                'target_area' => 'پا',
                'muscle_targets_json' => array('quads' => 80, 'glutes' => 75),
            ),
        );
    }
}

if (!function_exists('gymai_v36_backfill_save_post')) {
    function gymai_v36_backfill_save_post($post_id, $fields) {
        if (get_post_type($post_id) !== GYMAI_EXERCISE_POST_TYPE) {
            return array('ok' => false, 'error' => 'wrong post type');
        }

        foreach ($fields as $key => $value) {
            if ($key === 'secondary_muscle_keys' || $key === 'muscle_targets_json') {
                update_post_meta($post_id, $key, $value);
                continue;
            }
            update_post_meta($post_id, $key, $value);
        }

        return array('ok' => true, 'post_id' => $post_id);
    }
}

if (!function_exists('gymai_v36_run_backfill')) {
    function gymai_v36_run_backfill() {
        $dataset = gymai_v36_backfill_dataset();
        $results = array('updated' => array(), 'skipped' => array(), 'errors' => array());

        foreach ($dataset as $post_id => $fields) {
            $post = get_post($post_id);
            if (!$post) {
                $results['errors'][] = array('id' => $post_id, 'error' => 'post not found');
                continue;
            }
            $save = gymai_v36_backfill_save_post($post_id, $fields);
            if (!empty($save['ok'])) {
                $results['updated'][] = array(
                    'id' => $post_id,
                    'title' => get_the_title($post_id),
                    'main_muscle' => $fields['main_muscle'],
                );
            } else {
                $results['errors'][] = array('id' => $post_id, 'error' => $save['error']);
            }
        }

        return $results;
    }
}

add_action('admin_menu', function () {
    add_management_page(
        'GymAI v3.6 Backfill',
        'GymAI v3.6 Backfill',
        'manage_options',
        'gymai-v36-backfill',
        'gymai_v36_backfill_admin_page'
    );
});

if (!function_exists('gymai_v36_backfill_admin_page')) {
    function gymai_v36_backfill_admin_page() {
        if (!current_user_can('manage_options')) {
            wp_die('Unauthorized');
        }

        $result = null;
        if (isset($_POST['gymai_v36_backfill_run'])
            && check_admin_referer('gymai_v36_backfill', 'gymai_v36_backfill_nonce')
        ) {
            $result = gymai_v36_run_backfill();
        }

        $dataset = gymai_v36_backfill_dataset();
        ?>
        <div class="wrap">
            <h1>GymAI v3.6 — Meta Backfill</h1>
            <p>۶ حرکت batch6 با classification اشتباه (باگ «لت» داخل «هالتر») را در <strong>دیتابیس</strong> اصلاح می‌کند.</p>
            <p>بعد از backfill، هم <code>/wp-json/gymai/v3/exercises</code> و هم <code>/wp-json/wp/v2/exercises</code> (اپ Flutter) درست می‌شوند.</p>

            <table class="widefat striped" style="max-width:900px">
                <thead>
                    <tr><th>ID</th><th>main_muscle</th><th>movement_pattern</th></tr>
                </thead>
                <tbody>
                <?php foreach ($dataset as $id => $f) : ?>
                    <tr>
                        <td><?php echo (int) $id; ?></td>
                        <td><code><?php echo esc_html($f['main_muscle']); ?></code></td>
                        <td><code><?php echo esc_html($f['movement_pattern']); ?></code></td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>

            <form method="post" style="margin-top:20px">
                <?php wp_nonce_field('gymai_v36_backfill', 'gymai_v36_backfill_nonce'); ?>
                <p>
                    <button type="submit" name="gymai_v36_backfill_run" class="button button-primary"
                        onclick="return confirm('۶ پست اصلاح شوند؟');">
                        اجرای Backfill v3.6
                    </button>
                </p>
            </form>

            <?php if (is_array($result)) : ?>
                <h2>نتیجه</h2>
                <pre style="background:#f6f7f7;padding:12px;max-width:900px;overflow:auto"><?php
                    echo esc_html(wp_json_encode($result, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT));
                ?></pre>
            <?php endif; ?>

            <h2>ترتیب deploy</h2>
            <ol>
                <li>اسنیپت <strong>v3.6 Output Patch</strong> را فعال کن</li>
                <li><code>/wp-json/gymai/v3.6/ping</code> → باید <code>ok: true</code> بدهد</li>
                <li><code>/wp-json/gymai/v3/exercises?debug=1</code> → IDهای 4011، 4016، 4019، 4022 را چک کن</li>
                <li>این Backfill را بزن (برای اپ Flutter)</li>
            </ol>
        </div>
        <?php
    }
}
