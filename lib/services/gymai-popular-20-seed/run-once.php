<?php
/**
 * اجرای یک‌بار batch بدون فعال‌سازی پلاگین در وردپرس.
 *
 * 1) کل پوشه gymai-popular-20-seed را در plugins بگذار (فعال نکن)
 * 2) خط SECRET_KEY را عوض کن
 * 3) باز کن: https://gymaipro.ir/wp-content/plugins/gymai-popular-20-seed/run-once.php?key=SECRET_KEY
 * 4) بعد از موفقیت هر سه فایل run-once.php و verify-install.php را حذف کن
 */
define('GYMAI_POP20_RUN_ONCE_SECRET', 'gymai-pop20-change-me-2026');

$key = isset($_GET['key']) ? (string) $_GET['key'] : '';
if ($key === '' || !hash_equals(GYMAI_POP20_RUN_ONCE_SECRET, $key)) {
    http_response_code(403);
    exit('Forbidden');
}

$wp_load = dirname(__DIR__, 2) . '/wp-load.php';
if (!is_readable($wp_load)) {
    http_response_code(500);
    exit('wp-load.php not found');
}

require_once $wp_load;

if (!is_user_logged_in() || !current_user_can('manage_options')) {
    auth_redirect();
}

define('GYMAI_POP20_PLUGIN_LOADS_MENU', true);
$data = __DIR__ . '/add_exercises_popular_20.php';
if (!is_readable($data)) {
    http_response_code(500);
    exit('add_exercises_popular_20.php missing');
}

require_once $data;

header('Content-Type: text/html; charset=utf-8');
echo '<pre>';

if (!function_exists('gymai_batch_insert_popular_20')) {
    exit('Batch function not loaded — check data file syntax.');
}

$result = gymai_batch_insert_popular_20(false);
echo "Created: {$result['created']}\n";
echo "Updated: {$result['updated']}\n";
echo "Skipped: {$result['skipped']}\n";
if (!empty($result['errors'])) {
    echo "\nDetails:\n";
    foreach ($result['errors'] as $e) {
        echo '- ' . esc_html($e) . "\n";
    }
}
echo "\nDone. Delete run-once.php now.\n</pre>";
