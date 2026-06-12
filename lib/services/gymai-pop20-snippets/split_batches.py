# -*- coding: utf-8 -*-
import os

src = os.path.join(os.path.dirname(__file__), '..', 'gymai-exercise-seed', 'add_exercises_popular_20.php')
out_dir = os.path.dirname(__file__)

with open(src, encoding='utf-8') as f:
    lines = f.readlines()

b1 = lines[160:499]
b2 = lines[500:839]

header1 = """// GymAI Popular 20 — BATCH 1 (10 حرکت اول)
// Code Snippets: Run everywhere | بدون تگ php

if (!function_exists('gymai_pop20_batch1_definitions')) {
function gymai_pop20_batch1_definitions() {
    $base_img = 'https://gymaipro.ir/wp-content/uploads/2026/06/';
    $defs = [];
    $add = function (array $row) use (&$defs, $base_img) {
        if (empty($row['image'])) {
            $key = !empty($row['image_key']) ? $row['image_key'] : ('exercise-' . (count($defs) + 1));
            $row['image'] = $base_img . $key . '.jpg';
        }
        $defs[] = $row;
    };

"""

header2 = """// GymAI Popular 20 — BATCH 2 (10 حرکت دوم)
// Code Snippets: Run everywhere | بدون تگ php

if (!function_exists('gymai_pop20_batch2_definitions')) {
function gymai_pop20_batch2_definitions() {
    $base_img = 'https://gymaipro.ir/wp-content/uploads/2026/06/';
    $defs = [];
    $add = function (array $row) use (&$defs, $base_img) {
        if (empty($row['image'])) {
            $key = !empty($row['image_key']) ? $row['image_key'] : ('exercise-' . (count($defs) + 11));
            $row['image'] = $base_img . $key . '.jpg';
        }
        $defs[] = $row;
    };

"""

footer = """
    return $defs;
}
}

"""

for name, header, body in [('CODE_SNIPPET_POP20_BATCH1.php', header1, b1),
                            ('CODE_SNIPPET_POP20_BATCH2.php', header2, b2)]:
    path = os.path.join(out_dir, name)
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(header)
        f.writelines(body)
        f.write(footer)
    print(name, 'lines:', header.count('\n') + len(body) + footer.count('\n'))
