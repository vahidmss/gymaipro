# -*- coding: utf-8 -*-
"""Generate pop20-batch12.php … pop20-batch16.php and alias patch snippet."""
import os
import re
from batch12_16_specs import ALL_BATCHES, EXISTING_ALIAS_PATCH
from generate_batch5_6 import php_str, emit_exercise, spec_to_ex

BASE = os.path.dirname(os.path.abspath(__file__))


def enrich_ex(row):
    extra = []
    if len(row) == 19:
        extra = list(row[18])
        row = row[:18]
    ex = spec_to_ex(row)
    aliases = list(ex['aliases'])
    for a in extra:
        if a not in aliases:
            aliases.append(a)
    # Always keep common vernacular if title suggests it
    slug = ex['slug']
    if slug in EXISTING_ALIAS_PATCH:
        for a in EXISTING_ALIAS_PATCH[slug]:
            if a not in aliases:
                aliases.append(a)
    ex['aliases'] = aliases
    return ex


def write_batch(batch_num, specs, func_name):
    start = 200 + (batch_num - 12) * 20 + 1
    end = start + 19
    header = f"""// GymAI Popular — BATCH {batch_num} (20 حرکت — حرکات {start} تا {end})
// Code Snippets: Run everywhere | بدون تگ php

if (!function_exists('{func_name}')) {{
function {func_name}() {{
    $base_img = 'https://gymaipro.ir/wp-content/uploads/2026/08/';
    $defs = [];
    $add = function (array $row) use (&$defs, $base_img) {{
        if (empty($row['image'])) {{
            $key = !empty($row['image_key']) ? $row['image_key'] : ('exercise-batch{batch_num}-' . str_pad((string) (count($defs) + 1), 2, '0', STR_PAD_LEFT));
            $row['image'] = $base_img . $key . '.jpg';
        }}
        $defs[] = $row;
    }};

"""
    body = []
    for i, row in enumerate(specs, 1):
        body.append(emit_exercise(batch_num, i, enrich_ex(row)))
    footer = """
    return $defs;
}
}
"""
    path = os.path.join(BASE, f"pop20-batch{batch_num}.php")
    with open(path, "w", encoding="utf-8") as f:
        f.write(header + "\n".join(body) + footer)
    print(f"Wrote {path} ({len(specs)} exercises)")


def write_alias_patch():
    lines = [
        "// GymAI — Alias enrichment for existing exercises (Iran gym vernacular)",
        "// Code Snippets: Run everywhere | بدون تگ php",
        "// ابزارها → GymAI Exercises → دکمه «بروزرسانی نام‌های جایگزین»",
        "",
        "if (!function_exists('gymai_pop20_iran_alias_patch_map')) {",
        "function gymai_pop20_iran_alias_patch_map() {",
        "    return array(",
    ]
    for slug, aliases in EXISTING_ALIAS_PATCH.items():
        al = ", ".join(php_str(a) for a in aliases)
        lines.append(f"        {php_str(slug)} => array({al}),")
    lines += [
        "    );",
        "}",
        "}",
        "",
        "if (!function_exists('gymai_pop20_apply_iran_alias_patch')) {",
        "function gymai_pop20_apply_iran_alias_patch() {",
        "    if (!post_type_exists('exercises') && !post_type_exists('exercise')) {",
        "        return array('updated' => 0, 'skipped' => 0, 'errors' => array('CPT تمرین پیدا نشد'));",
        "    }",
        "    $ptype = post_type_exists('exercises') ? 'exercises' : 'exercise';",
        "    $map = gymai_pop20_iran_alias_patch_map();",
        "    $updated = 0;",
        "    $skipped = 0;",
        "    $errors = array();",
        "    foreach ($map as $slug => $extra) {",
        "        $post = get_page_by_path($slug, OBJECT, $ptype);",
        "        if (!$post) {",
        "            $skipped++;",
        "            $errors[] = 'پیدا نشد: ' . $slug;",
        "            continue;",
        "        }",
        "        $current = get_post_meta($post->ID, 'other_names', true);",
        "        if (!is_array($current)) {",
        "            $current = array_filter(array_map('trim', preg_split('/[,\\n]+/', (string) $current)));",
        "        }",
        "        $merged = array_values(array_unique(array_filter(array_merge($current, $extra))));",
        "        update_post_meta($post->ID, 'other_names', $merged);",
        "        $updated++;",
        "    }",
        "    return array('updated' => $updated, 'skipped' => $skipped, 'errors' => $errors, 'created' => 0, 'touched_ids' => array());",
        "}",
        "}",
        "",
    ]
    path = os.path.join(BASE, "CODE_SNIPPET_IRAN_ALIASES_PATCH.php")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f"Wrote {path}")


def validate():
    taken = set()
    for f in os.listdir(BASE):
        if f.startswith("pop20-batch") and f.endswith(".php") and not f.startswith("pop20-batch1"):
            pass
    for f in os.listdir(BASE):
        if re.match(r"pop20-batch\d+\.php$", f):
            t = open(os.path.join(BASE, f), encoding="utf-8").read()
            for m in re.finditer(r"'slug' => '([^']+)'", t):
                taken.add(m.group(1))
    # Don't include batches we're about to overwrite (12-16)
    for bn in range(12, 17):
        path = os.path.join(BASE, f"pop20-batch{bn}.php")
        if os.path.exists(path):
            t = open(path, encoding="utf-8").read()
            for m in re.finditer(r"'slug' => '([^']+)'", t):
                taken.discard(m.group(1))

    new_slugs = []
    for bn, specs in ALL_BATCHES.items():
        if len(specs) != 20:
            raise SystemExit(f"Batch {bn} has {len(specs)}, expected 20")
        for row in specs:
            slug = row[0]
            if slug in taken:
                raise SystemExit(f"Duplicate with existing: {slug}")
            if slug in new_slugs:
                raise SystemExit(f"Duplicate in new: {slug}")
            new_slugs.append(slug)
            taken.add(slug)
    print(f"Validation OK: {len(new_slugs)} new exercises")


if __name__ == "__main__":
    validate()
    for bn, specs in ALL_BATCHES.items():
        write_batch(bn, specs, f"gymai_pop20_batch{bn}_definitions")
    write_alias_patch()
