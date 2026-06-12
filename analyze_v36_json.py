# -*- coding: utf-8 -*-
import json
import re

path = r"C:\Users\vahid\.cursor\projects\d-gymaipro\agent-transcripts\d9c3fce9-c260-4840-ade6-d7d51693eae1\d9c3fce9-c260-4840-ade6-d7d51693eae1.jsonl"
out = r"d:\gymaipro\v36_analysis.txt"

EXPECTED = {
    4011: {"main": "triceps", "movement": "elbow_extension", "title": "فشار پشت بازو هالتر"},
    4013: {"main": "back_lat", "movement": "vertical_pull", "title": "زیربغل تک بازو"},
    4016: {"main": "quads", "movement": "squat", "title": "اسکات"},
    4019: {"main": "abs", "movement": "anti_rotation", "title": "پالوف"},
    4022: {"main": "quads", "movement": "lunge", "title": "لانج با هالتر"},
    4023: {"main": "quads", "movement": "lunge", "title": "لانج عقب"},
}

# Heuristic sanity rules for batch6 page
RULES = [
    (lambda t, c: "هالتر" in t and "پشت بازو" in t, "triceps", "elbow_extension"),
    (lambda t, c: "پالوف" in t or "pallof" in t.lower(), "abs", "anti_rotation"),
    (lambda t, c: "لانج" in t or "lunge" in t.lower(), "quads", "lunge"),
    (lambda t, c: "اسکات" in t or "اسکوات" in t or "squat" in t.lower(), "quads", "squat"),
    (lambda t, c: "زیربغل" in t or "lat pulldown" in t.lower(), "back_lat", "vertical_pull"),
]

with open(path, encoding="utf-8") as f:
    for line in f:
        if '"role":"user"' not in line or "v3.6-patched" not in line:
            continue
        outer = json.loads(line)
        text = outer["message"]["content"][0]["text"]
        if text.startswith("<user_query>"):
            text = text[len("<user_query>"):].lstrip()
        if text.endswith("</user_query>"):
            text = text[: -len("</user_query>")].rstrip()
        idx = text.find('{"version"')
        if idx < 0:
            idx = text.find("{")
        data, _ = json.JSONDecoder().raw_decode(text, idx)
        break
    else:
        raise SystemExit("v3.6 JSON not found")

lines = []
lines.append(f"version: {data.get('version')}")
lines.append(f"total: {data.get('total')} items on page: {len(data.get('items', []))}\n")

# Check expected IDs
lines.append("=== TARGET ID CHECKS ===")
all_ok = True
for eid, exp in EXPECTED.items():
    item = next((x for x in data["items"] if x["id"] == eid), None)
    if not item:
        lines.append(f"ID {eid}: NOT ON THIS PAGE")
        continue
    c = item.get("classification", {})
    main = c.get("main_muscle")
    mov = c.get("movement_pattern")
    ok_main = main == exp["main"]
    ok_mov = mov == exp["movement"]
    status = "OK" if ok_main and ok_mov else "FAIL"
    if status != "OK":
        all_ok = False
    lines.append(
        f"ID {eid} {item.get('title','')[:30]}: main={main} ({'OK' if ok_main else 'FAIL'}) "
        f"movement={mov} ({'OK' if ok_mov else 'FAIL'}) targets={item.get('muscle_targets')} "
        f"notes={item.get('v3_6_patch_notes')} norm={item.get('_normalization')}"
    )

# Scan all page items for suspicious classifications
lines.append("\n=== PAGE SCAN (heuristic) ===")
issues = []
for item in data["items"]:
    eid = item["id"]
    title = item.get("title", "")
    c = item.get("classification", {})
    main = c.get("main_muscle", "")
    mov = c.get("movement_pattern", "")
    text = title + " " + " ".join(item.get("aliases", []))
    for rule_fn, exp_main, exp_mov in RULES:
        if rule_fn(text, c):
            if main != exp_main or (exp_mov and mov != exp_mov):
                issues.append(f"ID {eid} {title}: got main={main} mov={mov}, expected main={exp_main} mov={exp_mov}")
            break

if issues:
    all_ok = False
    lines.extend(issues)
else:
    lines.append("No heuristic mismatches on page 1.")

# False lat check: هالتر in title but back_lat
lines.append("\n=== FALSE LAT CHECK (هالتر + back_lat) ===")
false_lat = []
for item in data["items"]:
    t = item.get("title", "")
    main = item.get("classification", {}).get("main_muscle")
    if "هالتر" in t and main == "back_lat" and "زیربغل" not in t and "لت" not in t.replace("هالتر", ""):
        false_lat.append(f"ID {item['id']} {t}: still back_lat")
if false_lat:
    all_ok = False
    lines.extend(false_lat)
else:
    lines.append("None found on page 1.")

lines.append(f"\nOVERALL PAGE1: {'PASS' if all_ok else 'ISSUES REMAIN'}")

with open(out, "w", encoding="utf-8") as wf:
    wf.write("\n".join(lines))
print("\n".join(lines))
