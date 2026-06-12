import json
from pathlib import Path

data = json.load(open(Path(__file__).parent / "exercises_bulk_meta.json", encoding="utf-8"))
ex = data["exercises"]

lines = [
    "function gymai_exercise_seed_dataset() {",
    "    static $cache = null;",
    "    if ($cache !== null) {",
    "        return $cache;",
    "    }",
    "    $cache = [",
]
for sid, row in ex.items():
    lines.append(f"        {int(sid)} => [")
    for k, v in row.items():
        if k == "muscle_targets":
            parts = [f"'{mk}' => {int(mv)}" for mk, mv in v.items()]
            lines.append("            'muscle_targets' => [" + ", ".join(parts) + "],")
        elif isinstance(v, str):
            esc = v.replace("\\", "\\\\").replace("'", "\\'")
            lines.append(f"            '{k}' => '{esc}',")
    lines.append("        ],")
lines.append("    ];")
lines.append("    return $cache;")
lines.append("}")

Path(__file__).parent.joinpath("_dataset_fn.php").write_text("\n".join(lines), encoding="utf-8")
print("ok", len(lines))
