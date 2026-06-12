from pathlib import Path
root = Path(__file__).parent
snippet = (root / "CODE_SNIPPET_1_SEED.php").read_text(encoding="utf-8")
header = """<?php
/**
 * GymAI — اجرای یک‌بار Seed (بعد از اجرا این فایل را حذف کنید)
 * آپلود: public_html/gymai-seed-once.php (کنار wp-load.php)
 * URL: https://gymaipro.ir/gymai-seed-once.php
 */
require_once __DIR__ . '/wp-load.php';

if (!is_user_logged_in() || !current_user_can('manage_options')) {
    wp_die('<h1>GymAI Seed</h1><p>اول با ادمین لاگین کنید، بعد این URL را باز کنید.</p>');
}

"""
footer = """
gymai_register_exercise_rest_meta_safe();
$result = gymai_run_exercise_meta_seed();
header('Content-Type: text/html; charset=utf-8');
echo '<h1>GymAI Seed Result</h1>';
echo '<p>Updated: <strong>' . (int) $result['updated'] . '</strong></p>';
echo '<p>Skipped: <strong>' . (int) $result['skipped'] . '</strong></p>';
if (!empty($result['errors'])) {
    echo '<ul>';
    foreach ($result['errors'] as $e) {
        echo '<li>' . esc_html($e) . '</li>';
    }
    echo '</ul>';
}
echo '<p><a href="https://gymaipro.ir/wp-json/wp/v2/exercises/3857">Check API 3857</a></p>';
echo '<p style="color:red"><strong>حذف کنید: gymai-seed-once.php</strong></p>';
"""
(root / "gymai-seed-once.php").write_text(header + snippet + footer, encoding="utf-8")
print("written", (root / "gymai-seed-once.php").stat().st_size)
