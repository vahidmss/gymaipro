import json
import re
from pathlib import Path

wrong_names = [
    "پرس سینه با هالتر",
    "پرس سینه با دمبل",
    "پرس سرشانه با هالتر",
    "جلو بازو هالتر",
    "هیپ تراست",
    "پل باسن",
]

root = Path(r"d:\gymaipro\lib\services\gymai-pop20-snippets")
hits = []
for f in sorted(root.glob("pop20-batch*.php")):
    text = f.read_text(encoding="utf-8", errors="ignore")
    for name in wrong_names:
        if name not in text:
            continue
        idx = text.find(name)
        window = text[max(0, idx - 800) : idx + 900]
        m = re.search(r"'main_muscle'\s*=>\s*'([^']+)'", window)
        hits.append(f"{f.name} | {name} | {m.group(1) if m else '?'}")

# Also scan v36_data for same titles
v36 = Path(r"d:\gymaipro\v36_data.json")
v36_hits = []
if v36.exists():
    data = json.loads(v36.read_text(encoding="utf-8"))
    items = data if isinstance(data, list) else data.get("items", data.get("exercises", []))
    if isinstance(data, dict) and not items:
        # maybe keyed
        for k, v in data.items():
            if isinstance(v, dict) and "classification" in v:
                items = list(data.values()) if False else []
                break
    # try recursive search for name + main_muscle
    def walk(obj, path=""):
        if isinstance(obj, dict):
            name = obj.get("name_app") or obj.get("title") or obj.get("name")
            clas = obj.get("classification")
            if isinstance(name, str) and isinstance(clas, dict):
                for wn in wrong_names:
                    if wn in name or name in wn:
                        v36_hits.append(
                            f"v36 | {name} | {clas.get('main_muscle')} | id={obj.get('id')}"
                        )
            for v in obj.values():
                walk(v)
        elif isinstance(obj, list):
            for v in obj:
                walk(v)

    walk(data)

out = Path(r"d:\gymaipro\.cursor\agent-tools\wp_batch_muscle_check.txt")
out.write_text(
    "POP20 BATCH SOURCE:\n"
    + "\n".join(hits)
    + "\n\nV36 API DUMP:\n"
    + "\n".join(v36_hits[:80]),
    encoding="utf-8",
)
print(f"batch_hits={len(hits)} v36_hits={len(v36_hits)} -> {out}")
