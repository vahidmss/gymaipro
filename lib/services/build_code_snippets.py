# -*- coding: utf-8 -*-
from pathlib import Path

root = Path(__file__).parent

dataset_fn = (root / "_dataset_fn.php").read_text(encoding="utf-8")

seed_tail = r'''
function gymai_run_exercise_meta_seed() {
    $dataset = gymai_exercise_seed_dataset();
    $updated = 0;
    $skipped = 0;
    $errors = [];
    $preserve = array('views_count', 'likes_count', 'video_url');
    foreach ($dataset as $post_id => $data) {
        $post = get_post($post_id);
        if (!$post || $post->post_type !== 'exercises') {
            $errors[] = 'Post ' . $post_id . ' not found';
            $skipped++;
            continue;
        }
        $muscle_targets = array();
        if (isset($data['muscle_targets']) && is_array($data['muscle_targets'])) {
            $muscle_targets = $data['muscle_targets'];
        }
        foreach ($data as $key => $value) {
            if ($key === 'muscle_targets' || in_array($key, $preserve, true)) {
                continue;
            }
            if ($value === null || $value === '') {
                continue;
            }
            update_post_meta($post_id, $key, is_string($value) ? $value : (string) $value);
        }
        if (!empty($muscle_targets)) {
            update_post_meta($post_id, 'muscle_targets_json', wp_json_encode($muscle_targets, JSON_UNESCAPED_UNICODE));
        }
        update_post_meta($post_id, '_gymai_seeded_at', (string) time());
        $updated++;
    }
    return array('updated' => $updated, 'skipped' => $skipped, 'errors' => $errors);
}

add_action('admin_menu', 'gymai_exercise_seed_admin_menu');
function gymai_exercise_seed_admin_menu() {
    add_management_page('GymAI Seed', 'GymAI Seed', 'manage_options', 'gymai-exercise-seed', 'gymai_exercise_seed_admin_page');
}

function gymai_exercise_seed_admin_page() {
    if (!current_user_can('manage_options')) {
        wp_die('No access');
    }
    $result = null;
    if (isset($_POST['gymai_seed_nonce']) && wp_verify_nonce(sanitize_text_field(wp_unslash($_POST['gymai_seed_nonce'])), 'gymai_seed_exercises')) {
        $result = gymai_run_exercise_meta_seed();
    }
    $dataset = gymai_exercise_seed_dataset();
    echo '<div class="wrap"><h1>GymAI Seed — 10 exercises</h1>';
    echo '<p>Count: <strong>' . count($dataset) . '</strong></p>';
    echo '<form method="post">';
    wp_nonce_field('gymai_seed_exercises', 'gymai_seed_nonce');
    echo '<p><button type="submit" class="button button-primary button-hero">Run Seed</button></p></form>';
    if ($result !== null) {
        echo '<div class="notice notice-success"><p>Updated: ' . (int) $result['updated'] . ', Skipped: ' . (int) $result['skipped'] . '</p></div>';
    }
    echo '</div>';
}
'''

snippet_seed = (
    "// GymAI Code Snippet 1 — Seed (NO <?php tag — plugin adds it)\n"
    "// Run: Admin only\n\n"
    + dataset_fn
    + "\n"
    + seed_tail.strip()
    + "\n"
)

metabox_src = (root / "updated_exercise_meta_box.php").read_text(encoding="utf-8")
marker = "add_action('add_meta_boxes', 'gymai_add_exercise_meta_box');"
start = metabox_src.find(marker)
if start < 0:
    raise SystemExit("metabox marker not found")
lines = metabox_src[start:].splitlines()

snippet_metabox = (
    "// GymAI Code Snippet 2 — Metabox (NO <?php tag)\n"
    "// Run: Admin only\n\n"
    + "\n".join(lines).strip()
    + "\n"
)

(root / "CODE_SNIPPET_1_SEED.php").write_text(snippet_seed, encoding="utf-8")
(root / "CODE_SNIPPET_2_METABOX.php").write_text(snippet_metabox, encoding="utf-8")
print("OK seed", len(snippet_seed), "metabox", len(snippet_metabox))
