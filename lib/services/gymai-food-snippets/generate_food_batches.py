#!/usr/bin/env python3
"""Generate food-batchN.php and CODE_SNIPPET_FOOD_BATCHN.php from foods_bulk_meta.json."""
import json
from pathlib import Path

ROOT = Path(__file__).parent
JSON_PATH = ROOT.parent / 'foods_bulk_meta.json'
BATCH_SIZE = 10

data = json.loads(JSON_PATH.read_text(encoding='utf-8'))
foods = data.get('foods') or []

for idx in range(0, len(foods), BATCH_SIZE):
    batch_num = idx // BATCH_SIZE + 1
    chunk = foods[idx : idx + BATCH_SIZE]
    start = idx + 1
    end = idx + len(chunk)
    tag = f'GYMAI_FOOD_BATCH{batch_num}'
    payload = json.dumps(chunk, ensure_ascii=False, indent=2)

    content = f"""// GymAI Foods — BATCH {batch_num} (خوراکی {start}–{end})
// Code Snippets: Run everywhere | بدون تگ php
// یا کپی در: wp-content/gymai-seed/food-batch{batch_num}.php

if (!function_exists('gymai_food_batch{batch_num}_definitions')) {{
    function gymai_food_batch{batch_num}_definitions() {{
        static $cache = null;
        if ($cache !== null) {{
            return $cache;
        }}
        $cache = json_decode(<<<'{tag}'
{payload}
{tag}
        , true);
        return is_array($cache) ? $cache : array();
    }}
}}
"""

    for name in (f'food-batch{batch_num}.php', f'CODE_SNIPPET_FOOD_BATCH{batch_num}.php'):
        (ROOT / name).write_text(content, encoding='utf-8')
    print(f'batch{batch_num}: {len(chunk)} foods ({start}-{end})')
