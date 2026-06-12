// GymAI Snippet 0 — ثبت فیلدهای جدید در REST API (بدون <?php)
// محل اجرا: همه جا (Run everywhere) — حتماً قبل از Seed فعال شود

add_action('init', function () {
    $keys = array(
        'target_area',
        'short_description',
        'movement_pattern',
        'body_engagement',
        'estimated_1rm_formula',
        'muscle_targets_json',
        'met',
        'movement_distance_cm',
        'calories_per_1000kg',
        'exercise_difficulty_score',
        'typical_rpe',
    );
    foreach ($keys as $key) {
        register_post_meta('exercises', $key, array(
            'single'            => true,
            'type'              => 'string',
            'show_in_rest'      => true,
            'auth_callback'     => '__return_true',
        ));
    }
}, 20);
