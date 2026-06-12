<?php
/**
 * GymAI Pro — پر کردن خودکار متا + هیت‌مپ ۱۰ حرکت
 *
 * نصب:
 *   1) این فایل + updated_exercise_meta_box.php را در functions.php تم include کنید
 *      یا به‌صورت پلاگین کوچک در wp-content/plugins/gymai-exercise-seed/
 *   2) پیشخوان → ابزارها → GymAI Seed Exercises
 *   3) دکمه «اجرای Seed» — views_count / likes_count دست نخورده می‌مانند
 *
 * داده‌ها از lib/services/exercises_bulk_meta.json (همین ریپو)
 */

if (!defined('ABSPATH')) {
    exit;
}

/** @return array<int, array<string, mixed>> */
function gymai_exercise_seed_dataset() {
    static $cache = null;
    if ($cache !== null) {
        return $cache;
    }

    $json_path = dirname(__FILE__) . '/exercises_bulk_meta.json';
    if (!is_readable($json_path)) {
        return [];
    }

    $raw = file_get_contents($json_path);
    $decoded = json_decode($raw, true);
    if (!is_array($decoded) || !isset($decoded['exercises']) || !is_array($decoded['exercises'])) {
        return [];
    }

    $out = [];
    foreach ($decoded['exercises'] as $id => $row) {
        $out[(int) $id] = $row;
    }
    $cache = $out;
    return $out;
}

/**
 * @return array{updated: int, skipped: int, errors: string[]}
 */
function gymai_run_exercise_meta_seed() {
    $dataset = gymai_exercise_seed_dataset();
    $updated = 0;
    $skipped = 0;
    $errors = [];

    $preserve = ['views_count', 'likes_count', 'video_url'];

    foreach ($dataset as $post_id => $data) {
        $post = get_post($post_id);
        if (!$post || $post->post_type !== 'exercises') {
            $errors[] = "پست $post_id یافت نشد یا CPT exercises نیست";
            $skipped++;
            continue;
        }

        $muscle_targets = [];
        if (isset($data['muscle_targets']) && is_array($data['muscle_targets'])) {
            $muscle_targets = $data['muscle_targets'];
        }

        foreach ($data as $key => $value) {
            if ($key === 'muscle_targets') {
                continue;
            }
            if (in_array($key, $preserve, true)) {
                continue;
            }
            if ($value === null || $value === '') {
                continue;
            }
            update_post_meta($post_id, $key, is_string($value) ? $value : (string) $value);
        }

        if (!empty($muscle_targets)) {
            update_post_meta(
                $post_id,
                'muscle_targets_json',
                wp_json_encode($muscle_targets, JSON_UNESCAPED_UNICODE)
            );
        }

        update_post_meta($post_id, '_gymai_seeded_at', (string) time());
        $updated++;
    }

    return [
        'updated' => $updated,
        'skipped' => $skipped,
        'errors' => $errors,
    ];
}

add_action('admin_menu', 'gymai_exercise_seed_admin_menu');
function gymai_exercise_seed_admin_menu() {
    add_management_page(
        'GymAI Seed Exercises',
        'GymAI Seed Exercises',
        'manage_options',
        'gymai-exercise-seed',
        'gymai_exercise_seed_admin_page'
    );
}

function gymai_exercise_seed_admin_page() {
    if (!current_user_can('manage_options')) {
        wp_die('دسترسی ندارید');
    }

    $result = null;
    if (
        isset($_POST['gymai_seed_nonce']) &&
        wp_verify_nonce(sanitize_text_field(wp_unslash($_POST['gymai_seed_nonce'])), 'gymai_seed_exercises')
    ) {
        $result = gymai_run_exercise_meta_seed();
    }

    $dataset = gymai_exercise_seed_dataset();
    $json_ok = !empty($dataset);
    ?>
    <div class="wrap">
        <h1>GymAI — پر کردن متا و هیت‌مپ (۱۰ حرکت)</h1>
        <?php if (!$json_ok) : ?>
            <div class="notice notice-error"><p>
                فایل <code>exercises_bulk_meta.json</code> کنار این PHP پیدا نشد.
                هر دو فایل را در همان پوشه پلاگین/تم بگذارید.
            </p></div>
        <?php else : ?>
            <p>تعداد حرکت در dataset: <strong><?php echo count($dataset); ?></strong></p>
            <form method="post">
                <?php wp_nonce_field('gymai_seed_exercises', 'gymai_seed_nonce'); ?>
                <p>
                    <button type="submit" class="button button-primary button-hero">
                        اجرای Seed (همه فیلدها + muscle_targets_json)
                    </button>
                </p>
                <p class="description">
                    views_count، likes_count و video_url تغییر نمی‌کنند.
                </p>
            </form>
        <?php endif; ?>

        <?php if ($result !== null) : ?>
            <div class="notice notice-success">
                <p>به‌روزرسانی: <?php echo (int) $result['updated']; ?> —
                    رد شده: <?php echo (int) $result['skipped']; ?></p>
                <?php if (!empty($result['errors'])) : ?>
                    <ul>
                        <?php foreach ($result['errors'] as $err) : ?>
                            <li><?php echo esc_html($err); ?></li>
                        <?php endforeach; ?>
                    </ul>
                <?php endif; ?>
            </div>
        <?php endif; ?>

        <h2>پیش‌نمایش هیت‌مپ</h2>
        <table class="widefat striped">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>نام</th>
                    <th>عضلات (top)</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($dataset as $id => $row) : ?>
                    <?php
                    $mt = isset($row['muscle_targets']) && is_array($row['muscle_targets'])
                        ? $row['muscle_targets']
                        : [];
                    arsort($mt);
                    $top = array_slice($mt, 0, 4, true);
                    $parts = [];
                    foreach ($top as $k => $v) {
                        $parts[] = $k . ':' . $v;
                    }
                    ?>
                    <tr>
                        <td><?php echo (int) $id; ?></td>
                        <td><?php echo esc_html($row['name_app'] ?? ''); ?></td>
                        <td><code><?php echo esc_html(implode(', ', $parts)); ?></code></td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php
}

// REST برای ادمین لاگین‌شده (اختیاری — از Postman با کوکی ادمین)
add_action('rest_api_init', function () {
    register_rest_route('gymai/v1', '/seed-exercises-meta', [
        'methods' => 'POST',
        'permission_callback' => static function () {
            return current_user_can('manage_options');
        },
        'callback' => static function () {
            $r = gymai_run_exercise_meta_seed();
            return new WP_REST_Response($r, 200);
        },
    ]);
});
