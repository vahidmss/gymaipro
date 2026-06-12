# -*- coding: utf-8 -*-
"""Generate pop20-batch7.php … pop20-batch11.php"""
import os
from batch7_11_specs import ALL_BATCHES
from generate_batch5_6 import spec_to_ex, emit_exercise

BASE = os.path.dirname(os.path.abspath(__file__))


def write_batch(batch_num, specs, func_name):
    header = f"""// GymAI Popular — BATCH {batch_num} (20 حرکت — حرکات {100 + (batch_num - 7) * 20 + 1} تا {100 + (batch_num - 6) * 20})
// Code Snippets: Run everywhere | بدون تگ php

if (!function_exists('{func_name}')) {{
function {func_name}() {{
    $base_img = 'https://gymaipro.ir/wp-content/uploads/2026/07/';
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
        body.append(emit_exercise(batch_num, i, spec_to_ex(row)))
    footer = """
    return $defs;
}
}
"""
    path = os.path.join(BASE, f"pop20-batch{batch_num}.php")
    with open(path, "w", encoding="utf-8") as f:
        f.write(header + "\n".join(body) + footer)
    print(f"Wrote {path} ({len(specs)} exercises)")


def validate_specs():
    from list_slugs import BLOCKLIST
    import re
    taken = set(BLOCKLIST)
    for f in os.listdir(BASE):
        if f.startswith("pop20-batch") and f.endswith(".php"):
            t = open(os.path.join(BASE, f), encoding="utf-8").read()
            for m in re.finditer(r"'slug' => '([^']+)'", t):
                taken.add(m.group(1))
    dup = []
    new_slugs = []
    for bn, specs in ALL_BATCHES.items():
        if len(specs) != 20:
            raise SystemExit(f"Batch {bn} has {len(specs)} exercises, expected 20")
        for row in specs:
            slug = row[0]
            if slug in taken:
                dup.append((bn, slug))
            if slug in new_slugs:
                dup.append((bn, slug + " (duplicate in new)"))
            new_slugs.append(slug)
            taken.add(slug)
    if dup:
        raise SystemExit("Duplicate slugs: " + ", ".join(f"{b}:{s}" for b, s in dup))
    print(f"Validation OK: {len(new_slugs)} new exercises")


if __name__ == "__main__":
    validate_specs()
    for bn, specs in ALL_BATCHES.items():
        write_batch(bn, specs, f"gymai_pop20_batch{bn}_definitions")
