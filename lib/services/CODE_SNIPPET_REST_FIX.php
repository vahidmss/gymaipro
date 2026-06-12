// این را جایگزین کل snippet #65 کنید یا اول آن بچسبانید — بدون <?php
// محل اجرا: حتماً «همه جا» (نه فقط مدیریت)

$gymai_rest_meta_keys = array(
    'short_description', 'detailed_description', 'learn', 'seo_content',
    'movement_pattern', 'body_engagement', 'estimated_1rm_formula', 'muscle_targets_json',
    'met', 'movement_distance_cm', 'calories_per_1000kg',
    'exercise_difficulty_score', 'typical_rpe',
    'image_url', 'thumbnail_url', 'video_url',
    'mechanics_type', 'force_type', 'plane_of_motion', 'laterality', 'posture',
    'grip_type', 'resistance_profile', 'joint_focus',
    'programming_goal', 'recommended_sets', 'rep_range_strength',
    'rep_range_hypertrophy', 'rep_range_endurance', 'rest_seconds', 'tempo',
    'setup', 'execution', 'breathing', 'common_mistakes', 'contraindications',
);

add_action('init', function () use ($gymai_rest_meta_keys) {
    foreach ($gymai_rest_meta_keys as $key) {
        register_post_meta('exercises', $key, array(
            'single' => true, 'type' => 'string',
            'show_in_rest' => true, 'auth_callback' => '__return_true',
        ));
    }
}, 5);

// اگر register_post_meta روی سرور جواب نداد، این فیلدها را مستقیم در meta برمی‌گرداند
add_filter('rest_prepare_exercises', function ($response, $post, $request) use ($gymai_rest_meta_keys) {
    if (!is_object($response) || !method_exists($response, 'get_data')) {
        return $response;
    }
    $data = $response->get_data();
    if (!isset($data['meta']) || !is_array($data['meta'])) {
        $data['meta'] = array();
    }
    foreach ($gymai_rest_meta_keys as $key) {
        $data['meta'][$key] = (string) get_post_meta($post->ID, $key, true);
    }
    $response->set_data($data);
    return $response;
}, 20, 3);
