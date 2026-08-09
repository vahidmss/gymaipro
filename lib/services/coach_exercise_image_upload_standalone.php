<?php
/**
 * upload-exercise-image.php
 * Deploy to: private_html/upload-exercise-image.php
 * Saves to: custom_exercises/{username}/images/
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Authorization, Content-Type, X-User-Id, X-Auth-Token');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(array(
        'success' => false,
        'error' => 'method_not_allowed',
        'message' => 'Only POST allowed',
    ));
    exit;
}

$auth_header = '';
if (isset($_SERVER['HTTP_AUTHORIZATION'])) {
    $auth_header = $_SERVER['HTTP_AUTHORIZATION'];
} elseif (isset($_SERVER['HTTP_X_AUTH_TOKEN'])) {
    $auth_header = $_SERVER['HTTP_X_AUTH_TOKEN'];
}

$jwt_token = null;
if (preg_match('/Bearer\s+(.+)/i', $auth_header, $matches)) {
    $jwt_token = trim($matches[1]);
}
if (empty($jwt_token) && !empty($_POST['auth_token'])) {
    $jwt_token = trim((string) $_POST['auth_token']);
}
if (empty($jwt_token)) {
    http_response_code(401);
    echo json_encode(array(
        'success' => false,
        'error' => 'unauthorized',
        'message' => 'Authorization token is missing',
    ));
    exit;
}

$upload_config_file = __DIR__ . '/upload_config.php';
$supabase_url = 'https://api.gymaipro.ir';
$supabase_anon_key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE';
$supabase_host = 'api.gymaipro.ir';
if (file_exists($upload_config_file)) {
    $cfg = require $upload_config_file;
    if (is_array($cfg)) {
        if (!empty($cfg['supabase_url'])) {
            $supabase_url = rtrim((string) $cfg['supabase_url'], '/');
        }
        if (!empty($cfg['supabase_anon_key'])) {
            $supabase_anon_key = $cfg['supabase_anon_key'];
        }
        if (!empty($cfg['supabase_host'])) {
            $supabase_host = $cfg['supabase_host'];
        }
    }
}

// اگر هنوز http روی IP باشد و سرور 301 بدهد، به https دامنه سوییچ کن
if (stripos($supabase_url, 'http://') === 0) {
    $supabase_url = 'https://' . $supabase_host;
}

/**
 * @return array{0:string|false,1:int}
 */
function gymai_supabase_get($url, $headers) {
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($ch, CURLOPT_TIMEOUT, 15);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
    curl_setopt($ch, CURLOPT_MAXREDIRS, 3);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);
    $body = curl_exec($ch);
    $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    return array($body, $code);
}

$auth_headers = array(
    'Authorization: Bearer ' . $jwt_token,
    'apikey: ' . $supabase_anon_key,
    'Host: ' . $supabase_host,
    'Accept: application/json',
);

list($user_response, $http_code) = gymai_supabase_get(
    $supabase_url . '/auth/v1/user',
    $auth_headers
);

if ($http_code !== 200) {
    http_response_code(401);
    echo json_encode(array(
        'success' => false,
        'error' => 'unauthorized',
        'message' => 'Invalid or expired token',
        'debug_http' => $http_code,
        'debug_url' => $supabase_url . '/auth/v1/user',
    ));
    exit;
}

$user_data = json_decode($user_response, true);
$user_id = isset($user_data['id']) ? $user_data['id'] : null;
if (empty($user_id)) {
    http_response_code(401);
    echo json_encode(array(
        'success' => false,
        'error' => 'unauthorized',
        'message' => 'User ID not found in token',
    ));
    exit;
}

$rest_headers = array(
    'Authorization: Bearer ' . $jwt_token,
    'apikey: ' . $supabase_anon_key,
    'Host: ' . $supabase_host,
    'Content-Type: application/json',
    'Accept: application/json',
);

list($profile_response, $profile_http_code) = gymai_supabase_get(
    $supabase_url . '/rest/v1/profiles?id=eq.' . rawurlencode($user_id) . '&select=role,username',
    $rest_headers
);
$profile_data = null;
if ($profile_http_code === 200) {
    $profile_data = json_decode($profile_response, true);
}

if (empty($profile_data) || !isset($profile_data[0]['role'])) {
    list($profile_response, $profile_http_code) = gymai_supabase_get(
        $supabase_url . '/rest/v1/profiles?auth_user_id=eq.' . rawurlencode($user_id) . '&select=role,username',
        $rest_headers
    );
    if ($profile_http_code === 200) {
        $profile_data = json_decode($profile_response, true);
    }
}

if (empty($profile_data) || !isset($profile_data[0]['role'])) {
    http_response_code(403);
    echo json_encode(array(
        'success' => false,
        'error' => 'forbidden',
        'message' => 'User profile not found',
        'debug_http' => $profile_http_code,
    ));
    exit;
}

$user_role = $profile_data[0]['role'];
$username = isset($profile_data[0]['username']) ? $profile_data[0]['username'] : $user_id;
if ($user_role !== 'admin' && $user_role !== 'trainer') {
    http_response_code(403);
    echo json_encode(array(
        'success' => false,
        'error' => 'forbidden',
        'message' => 'Only admins and trainers can upload',
    ));
    exit;
}

$file = null;
if (!empty($_FILES['image'])) {
    $file = $_FILES['image'];
} elseif (!empty($_FILES['cover'])) {
    $file = $_FILES['cover'];
}
if ($file === null) {
    http_response_code(400);
    echo json_encode(array(
        'success' => false,
        'error' => 'missing_file',
        'message' => 'Image file is required (field: image or cover)',
    ));
    exit;
}
if ($file['error'] !== UPLOAD_ERR_OK) {
    http_response_code(400);
    echo json_encode(array(
        'success' => false,
        'error' => 'upload_error',
        'message' => 'File upload error code: ' . $file['error'],
    ));
    exit;
}

$allowed = array('jpg', 'jpeg', 'png', 'webp');
$file_extension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
if (!in_array($file_extension, $allowed, true)) {
    http_response_code(400);
    echo json_encode(array(
        'success' => false,
        'error' => 'invalid_file_type',
        'message' => 'Only JPG/PNG/WEBP allowed',
    ));
    exit;
}

if ($file['size'] > (10 * 1024 * 1024)) {
    http_response_code(400);
    echo json_encode(array(
        'success' => false,
        'error' => 'file_too_large',
        'message' => 'Max size is 10MB',
    ));
    exit;
}

$safe_username = preg_replace('/[^a-zA-Z0-9_-]/', '_', (string) $username);
if ($safe_username === '' || $safe_username === '_') {
    $safe_username = preg_replace('/[^a-zA-Z0-9_-]/', '_', (string) $user_id);
}

$trainer_folder = __DIR__ . '/custom_exercises/' . $safe_username . '/images';
if (!is_dir($trainer_folder)) {
    if (!mkdir($trainer_folder, 0755, true)) {
        http_response_code(500);
        echo json_encode(array(
            'success' => false,
            'error' => 'directory_error',
            'message' => 'Failed to create directory: custom_exercises/' . $safe_username . '/images',
        ));
        exit;
    }
}

$timestamp = time();
$random_string = bin2hex(openssl_random_pseudo_bytes(4));
$file_name = 'exercise_img_' . $timestamp . '_' . $random_string . '.' . $file_extension;
$file_path = $trainer_folder . '/' . $file_name;

if (!move_uploaded_file($file['tmp_name'], $file_path)) {
    http_response_code(500);
    echo json_encode(array(
        'success' => false,
        'error' => 'move_error',
        'message' => 'Failed to move uploaded file',
    ));
    exit;
}
@chmod($file_path, 0644);

$image_url = 'https://dl.gymaipro.ir/custom_exercises/' . $safe_username . '/images/' . $file_name;

http_response_code(200);
echo json_encode(array(
    'success' => true,
    'image_url' => $image_url,
    'cover_url' => $image_url,
    'url' => $image_url,
    'file_name' => $file_name,
    'file_size' => $file['size'],
    'trainer_id' => $user_id,
    'trainer_username' => $safe_username,
    'uploaded_at' => date('Y-m-d H:i:s'),
));
