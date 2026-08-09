<?php
/**
 * upload-chat-media.php
 * Private chat attachments → chat/{conversation_id}/{images|voice|files}/
 *
 * Deploy to: private_html/upload-chat-media.php
 * Requires: upload_config.php, upload_paths.php
 *
 * POST multipart:
 *   field: media
 *   media_kind: image|voice|file
 *   conversation_id: uuid
 *   auth via Authorization / X-Auth-Token / auth_token
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
if (stripos($supabase_url, 'http://') === 0) {
    $supabase_url = 'https://' . $supabase_host;
}

$ch = curl_init($supabase_url . '/auth/v1/user');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, array(
    'Authorization: Bearer ' . $jwt_token,
    'apikey: ' . $supabase_anon_key,
    'Host: ' . $supabase_host,
    'Accept: application/json',
));
curl_setopt($ch, CURLOPT_TIMEOUT, 15);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
$user_response = curl_exec($ch);
$http_code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($http_code !== 200) {
    http_response_code(401);
    echo json_encode(array(
        'success' => false,
        'error' => 'unauthorized',
        'message' => 'Invalid or expired token',
        'debug_http' => $http_code,
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

// Any authenticated user may upload chat media
$username = $user_id;
$ch = curl_init($supabase_url . '/rest/v1/profiles?id=eq.' . rawurlencode($user_id) . '&select=username');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, array(
    'Authorization: Bearer ' . $jwt_token,
    'apikey: ' . $supabase_anon_key,
    'Host: ' . $supabase_host,
    'Accept: application/json',
));
curl_setopt($ch, CURLOPT_TIMEOUT, 10);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
$profile_response = curl_exec($ch);
$profile_http = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);
if ($profile_http === 200) {
    $rows = json_decode($profile_response, true);
    if (!empty($rows[0]['username'])) {
        $username = $rows[0]['username'];
    }
}

if (empty($_FILES['media'])) {
    http_response_code(400);
    echo json_encode(array(
        'success' => false,
        'error' => 'missing_file',
        'message' => 'media file is required',
    ));
    exit;
}

$file = $_FILES['media'];
if ($file['error'] !== UPLOAD_ERR_OK) {
    http_response_code(400);
    echo json_encode(array(
        'success' => false,
        'error' => 'upload_error',
        'message' => 'File upload error code: ' . $file['error'],
    ));
    exit;
}

$media_kind = isset($_POST['media_kind']) ? strtolower(trim((string) $_POST['media_kind'])) : '';
$conversation_id = isset($_POST['conversation_id']) ? trim((string) $_POST['conversation_id']) : '';
if ($media_kind === '') {
    $media_kind = 'file';
}
if (!in_array($media_kind, array('image', 'voice', 'file'), true)) {
    http_response_code(400);
    echo json_encode(array(
        'success' => false,
        'error' => 'invalid_kind',
        'message' => 'media_kind must be image, voice, or file',
    ));
    exit;
}

$ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
$allowed = array();
if ($media_kind === 'image') {
    $allowed = array('jpg', 'jpeg', 'png', 'webp', 'gif');
} elseif ($media_kind === 'voice') {
    $allowed = array('m4a', 'mp3', 'wav', 'ogg', 'aac', 'mp4');
} else {
    $allowed = array(
        'pdf', 'doc', 'docx', 'txt', 'zip', 'rar',
        'jpg', 'jpeg', 'png', 'webp',
        'm4a', 'mp3', 'wav',
        'mp4', 'mov',
    );
}
if ($ext === '' || !in_array($ext, $allowed, true)) {
    http_response_code(400);
    echo json_encode(array(
        'success' => false,
        'error' => 'invalid_file_type',
        'message' => 'File type not allowed for ' . $media_kind,
    ));
    exit;
}

require_once __DIR__ . '/upload_paths.php';
$target = gymai_resolve_media_target(
    __DIR__,
    $media_kind,
    'private_chat',
    $username,
    $user_id,
    $conversation_id
);

if ($file['size'] > (int) $target['max_bytes']) {
    http_response_code(400);
    echo json_encode(array(
        'success' => false,
        'error' => 'file_too_large',
        'message' => 'File size exceeds maximum allowed',
        'max_bytes' => $target['max_bytes'],
    ));
    exit;
}

$folder = $target['absolute'];
if (!is_dir($folder)) {
    if (!mkdir($folder, 0755, true)) {
        http_response_code(500);
        echo json_encode(array(
            'success' => false,
            'error' => 'directory_error',
            'message' => 'Failed to create chat media directory',
        ));
        exit;
    }
}

$timestamp = time();
$random_string = bin2hex(openssl_random_pseudo_bytes(4));
$file_name = $target['prefix'] . '_' . $timestamp . '_' . $random_string . '.' . $ext;
$file_path = $folder . '/' . $file_name;

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

$url = $target['url_base'] . '/' . $file_name;

http_response_code(200);
echo json_encode(array(
    'success' => true,
    'url' => $url,
    'media_url' => $url,
    'image_url' => $url,
    'audio_url' => $url,
    'file_name' => $file_name,
    'file_size' => $file['size'],
    'media_kind' => $media_kind,
    'relative_path' => $target['relative'] . '/' . $file_name,
    'uploader_id' => $user_id,
    'uploaded_at' => date('Y-m-d H:i:s'),
));
