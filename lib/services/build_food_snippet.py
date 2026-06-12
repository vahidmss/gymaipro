"""Rebuild CODE_SNIPPET_FOOD_METABOX.php with valid PHP brace structure."""
import re
from pathlib import Path

src = Path(__file__).with_name('updated_food_meta_box.php')
dst = Path(__file__).with_name('CODE_SNIPPET_FOOD_METABOX.php')

raw = src.read_text(encoding='utf-8')
raw = re.sub(r'^<\?php\s*\n', '', raw)
raw = re.sub(r"if \(!defined\('ABSPATH'\)\) \{\s*\n\s*exit;\s*\n\}\s*\n", '', raw)
raw = re.sub(r'/\*\*[\s\S]*?\*/\s*', '', raw, count=1)
raw = re.sub(
    r"// =+\s*\n// REST API[\s\S]*$",
    '',
    raw,
    flags=re.MULTILINE,
)


def extract_block(content: str, start_pattern: str) -> str:
    m = re.search(start_pattern, content)
    if not m:
        raise SystemExit(f'Pattern not found: {start_pattern}')
    brace_start = content.find('{', m.start())
    depth = 0
    for i in range(brace_start, len(content)):
        ch = content[i]
        if ch == '{':
            depth += 1
        elif ch == '}':
            depth -= 1
            if depth == 0:
                return content[m.start(): i + 1]
    raise SystemExit(f'Unclosed block: {start_pattern}')


helpers = [
    extract_block(raw, r'function gymai_food_unit_catalog\('),
    extract_block(raw, r'function gymai_food_group_options\('),
    extract_block(raw, r'function gymai_food_type_options\('),
    extract_block(raw, r'function gymai_food_meal_time_options\('),
]
metabox_add = extract_block(raw, r"add_action\('add_meta_boxes', 'gymai_add_food_meta_box'\);")
callback = extract_block(raw, r'function gymai_food_meta_box_callback\(')
save_block = extract_block(raw, r"add_action\('save_post_foods', 'gymai_save_food_meta_box'")

header = """// ============================================================
// GymAI — متاباکس خوراکی + REST meta
// بدون <?php — افزونه Code Snippets — Run everywhere
// پست‌تایپ را با JetEngine بساز: اسلاگ = foods
// Snippet CPT (CODE_SNIPPET_FOOD_CPT) را فعال نکن!
// ============================================================

$gymai_food_rest_meta_keys = array(
    'name_app', 'other_names', 'food_group', 'food_type', 'meal_times',
    'short_description', 'serving_notes', 'nutrition_basis', 'serving_size_grams',
    'default_serving_unit', 'serving_units_json', 'substitutes_json',
    'allergens', 'glycemic_index', 'sample_image_forapp',
    'tip_1', 'tip_2', 'tip_3',
    'protein', 'calories', 'carbohydrates', 'fat', 'saturated_fat',
    'fiber', 'sugar', 'cholesterol', 'sodium', 'potassium',
    'views_count', 'likes_count',
);
add_action('init', function () use ($gymai_food_rest_meta_keys) {
    if (!post_type_exists('foods')) {
        return;
    }
    foreach ($gymai_food_rest_meta_keys as $key) {
        register_post_meta('foods', $key, array(
            'single' => true, 'type' => 'string',
            'show_in_rest' => true, 'auth_callback' => '__return_true',
        ));
    }
}, 20);
add_filter('rest_prepare_foods', function ($response, $post, $request) use ($gymai_food_rest_meta_keys) {
    if (!is_object($response) || !method_exists($response, 'get_data')) {
        return $response;
    }
    $data = $response->get_data();
    if (!isset($data['meta']) || !is_array($data['meta'])) {
        $data['meta'] = array();
    }
    foreach ($gymai_food_rest_meta_keys as $key) {
        $data['meta'][$key] = (string) get_post_meta($post->ID, $key, true);
    }
    $response->set_data($data);
    return $response;
}, 20, 3);

"""


def wrap(fn_name: str, inner: str, hook_prefix: str = '') -> str:
    lines = [f"if (!function_exists('{fn_name}')) {{"]
    if hook_prefix:
        lines.append(f"    {hook_prefix}")
    for line in inner.splitlines():
        if line.strip():
            lines.append('    ' + line)
        else:
            lines.append('')
    lines.append('}')
    return '\n'.join(lines)


parts = [header]
helper_names = [
    'gymai_food_unit_catalog',
    'gymai_food_group_options',
    'gymai_food_type_options',
    'gymai_food_meal_time_options',
]
for name, block in zip(helper_names, helpers):
    fn_only = re.sub(r'^function ', 'function ', block)
    parts.append(wrap(name, fn_only))

parts.append(wrap(
    'gymai_add_food_meta_box',
    re.sub(r"add_action\('add_meta_boxes', 'gymai_add_food_meta_box'\);\s*", '', metabox_add),
    "add_action('add_meta_boxes', 'gymai_add_food_meta_box');",
))
parts.append(wrap('gymai_food_meta_box_callback', callback))
parts.append(wrap(
    'gymai_save_food_meta_box',
    re.sub(
        r"add_action\('save_post_foods', 'gymai_save_food_meta_box', 10, 3\);\s*",
        '',
        save_block,
    ),
    "add_action('save_post_foods', 'gymai_save_food_meta_box', 10, 3);",
))

dst.write_text('\n'.join(parts).strip() + '\n', encoding='utf-8')
print('OK:', dst, dst.stat().st_size, 'bytes')
