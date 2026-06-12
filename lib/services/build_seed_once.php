<?php
// Run on dev machine to build gymai-seed-once.php — not for WordPress upload
$snippet = file_get_contents(__DIR__ . '/CODE_SNIPPET_1_SEED.php');
$header = <<<'HDR'
<?php
/**
 * GymAI — اجرای یک‌بار Seed (بعد از اجرا این فایل را حذف کنید)
 * آپلود در: public_html/gymai-seed-once.php (کنار wp-load.php)
 * باز کنید: https://gymaipro.ir/gymai-seed-once.php
 * (باید با حساب ادمین لاگین باشید)
 */
require_once __DIR__ . '/wp-load.php';

if (!is_user_logged_in() || !current_user_can('manage_options')) {
    wp_die('<h1>GymAI Seed</h1><p>اول در وردپرس <a href="' . esc_url(wp_login_url($_SERVER['REQUEST_URI'])) . '">لاگین ادمین</a> کنید، بعد این صفحه را رفرش کنید.</p>');
}

HDR;

$footer = <<<'FTR'

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
echo '<p><a href="https://gymaipro.ir/wp-json/wp/v2/exercises/3857" target="_blank">Check API 3857</a></p>';
echo '<p style="color:red"><strong>این فایل را الان حذف کنید (gymai-seed-once.php)</strong></p>';

FTR;

file_put_contents(__DIR__ . '/gymai-seed-once.php', $header . "\n" . $snippet . "\n" . $footer);
