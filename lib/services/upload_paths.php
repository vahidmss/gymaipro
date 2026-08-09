<?php
/**
 * Shared media folder taxonomy for dl.gymaipro.ir
 *
 * Deploy next to upload-*.php as: upload_paths.php
 *
 * Final tree (new uploads):
 *
 *   coaches_music/{username}/                 academy tracks (legacy name, keep URLs stable)
 *   coaches_music_covers/{username}/          academy covers
 *   coaches_video/{username}/                 default coach videos
 *
 *   channel/{username}/images/
 *   channel/{username}/videos/
 *   channel/{username}/audio/
 *
 *   custom_exercises/{username}/images/
 *   custom_exercises/{username}/videos/
 *
 *   announcements/images/YYYY/MM/
 *   announcements/videos/YYYY/MM/
 *
 *   chat/{conversation_id}/images/
 *   chat/{conversation_id}/voice/
 *   chat/{conversation_id}/files/
 */

if (!function_exists('gymai_safe_segment')) {
    function gymai_safe_segment($value, $fallback = 'unknown')
    {
        $s = preg_replace('/[^a-zA-Z0-9_-]/', '_', (string) $value);
        $s = trim((string) $s, '_');
        if ($s === '' || $s === '_') {
            return $fallback;
        }
        return $s;
    }
}

if (!function_exists('gymai_resolve_media_target')) {
    /**
     * @param string $root_dir Absolute public root (__DIR__ of upload scripts)
     * @param string $kind     image|audio|video|voice|file
     * @param string $context  upload_context from client
     * @param string $username
     * @param string $user_id
     * @param string $conversation_id Required for private_chat
     * @return array{relative:string,absolute:string,url_base:string,prefix:string,max_bytes:int}
     */
    function gymai_resolve_media_target(
        $root_dir,
        $kind,
        $context,
        $username,
        $user_id,
        $conversation_id = ''
    ) {
        $safe_user = gymai_safe_segment($username, gymai_safe_segment($user_id, 'user'));
        $ctx = trim((string) $context);
        $kind = strtolower(trim((string) $kind));
        $base_url = 'https://dl.gymaipro.ir';
        $year = date('Y');
        $month = date('m');

        // Defaults by kind (academy / generic)
        $relative = '';
        $prefix = $kind;
        $max_bytes = 5 * 1024 * 1024;

        if ($ctx === 'private_chat' || $ctx === 'chat') {
            $conv = gymai_safe_segment($conversation_id, '');
            if ($conv === '' || $conv === 'unknown') {
                // Fall back to per-user inbox so files are never lost in a flat dump
                $conv = 'user_' . $safe_user;
            }
            if ($kind === 'image') {
                $relative = 'chat/' . $conv . '/images';
                $prefix = 'chat_img';
                $max_bytes = 8 * 1024 * 1024;
            } elseif ($kind === 'voice' || $kind === 'audio') {
                $relative = 'chat/' . $conv . '/voice';
                $prefix = 'chat_voice';
                $max_bytes = 8 * 1024 * 1024;
            } else {
                $relative = 'chat/' . $conv . '/files';
                $prefix = 'chat_file';
                $max_bytes = 20 * 1024 * 1024;
            }
        } elseif ($ctx === 'trainer_channel' || $ctx === 'channel') {
            if ($kind === 'image') {
                $relative = 'channel/' . $safe_user . '/images';
                $prefix = 'channel_img';
                $max_bytes = 8 * 1024 * 1024;
            } elseif ($kind === 'video') {
                $relative = 'channel/' . $safe_user . '/videos';
                $prefix = 'channel_video';
                $max_bytes = 100 * 1024 * 1024;
            } else {
                $relative = 'channel/' . $safe_user . '/audio';
                $prefix = 'channel_audio';
                $max_bytes = 50 * 1024 * 1024;
            }
        } elseif ($ctx === 'custom_exercise') {
            if ($kind === 'image') {
                $relative = 'custom_exercises/' . $safe_user . '/images';
                $prefix = 'exercise_img';
                $max_bytes = 10 * 1024 * 1024;
            } else {
                $relative = 'custom_exercises/' . $safe_user . '/videos';
                $prefix = 'exercise_video';
                $max_bytes = 100 * 1024 * 1024;
            }
        } elseif ($ctx === 'announcements') {
            if ($kind === 'image') {
                $relative = 'announcements/images/' . $year . '/' . $month;
                $prefix = 'announcement_image';
                $max_bytes = 8 * 1024 * 1024;
            } else {
                $relative = 'announcements/videos/' . $year . '/' . $month;
                $prefix = 'announcement_video';
                $max_bytes = 100 * 1024 * 1024;
            }
        } else {
            // Academy / default coach library (legacy folder names = stable old URLs)
            if ($kind === 'image') {
                $relative = 'coaches_music_covers/' . $safe_user;
                $prefix = 'cover';
                $max_bytes = 5 * 1024 * 1024;
            } elseif ($kind === 'video') {
                $relative = 'coaches_video/' . $safe_user;
                $prefix = 'video';
                $max_bytes = 100 * 1024 * 1024;
            } else {
                $relative = 'coaches_music/' . $safe_user;
                $prefix = 'music';
                $max_bytes = 50 * 1024 * 1024;
            }
        }

        $absolute = rtrim($root_dir, '/\\') . '/' . $relative;
        return array(
            'relative' => $relative,
            'absolute' => $absolute,
            'url_base' => $base_url . '/' . $relative,
            'prefix' => $prefix,
            'max_bytes' => $max_bytes,
            'safe_username' => $safe_user,
        );
    }
}
