<?php
/**
 * اسکریپت تست اتصال هاست dl.gymaipro.ir به Supabase
 * این فایل را روی dl.gymaipro.ir با نام test-supabase.php آپلود کن و در مرورگر باز کن.
 * بعد از تست حذفش کن (امنیتی).
 */
header('Content-Type: application/json; charset=utf-8');

$upload_config_file = __DIR__ . '/upload_config.php';
$default_url = 'http://87.248.156.175';
$default_key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE';
$default_host = 'api.gymaipro.ir';
if (file_exists($upload_config_file)) {
    $cfg = require $upload_config_file;
    $supabase_url = $cfg['supabase_url'] ?? $default_url;
    $supabase_anon_key = $cfg['supabase_anon_key'] ?? $default_key;
    $supabase_host = $cfg['supabase_host'] ?? $default_host;
} else {
    $supabase_url = $default_url;
    $supabase_anon_key = $default_key;
    $supabase_host = $default_host;
}

$test_url = $supabase_url . '/auth/v1/health';
$ch = curl_init($test_url);
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
        'apikey: ' . $supabase_anon_key,
        'Host: ' . $supabase_host,
    ],
    CURLOPT_TIMEOUT => 10,
    CURLOPT_CONNECTTIMEOUT => 5,
]);

$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curl_errno = curl_errno($ch);
$curl_error = curl_error($ch);
curl_close($ch);

$result = [
    'supabase_url' => $supabase_url,
    'test_url' => $test_url,
    'http_code' => $http_code,
    'curl_errno' => $curl_errno,
    'curl_error' => $curl_error ?: null,
    'response_preview' => $response ? substr($response, 0, 200) : null,
    'success' => ($http_code === 200 && $curl_errno === 0),
];

echo json_encode($result, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
