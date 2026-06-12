# -*- coding: utf-8 -*-
import json

with open(r"d:\gymaipro\v36_data.json", encoding="utf-8") as f:
    data = json.load(f)

issues = []
for item in data["items"]:
    eid = item["id"]
    title = item.get("title", "")
    c = item.get("classification", {})
    main = c.get("main_muscle", "")
    mov = c.get("movement_pattern", "")
    targets = item.get("muscle_targets") or {}
    norm = item.get("_normalization") or []

    # empty movement with compound/full body
    if mov in ("", None) and main not in ("", None):
        if main in ("abs", "full_body") or c.get("body_engagement") == "compound":
            issues.append(f"EMPTY_MOVEMENT: {eid} {title} main={main}")

    # polluted targets: triceps exercise with back_lat in targets
    if main == "triceps" and "back_lat" in targets:
        issues.append(f"POLLUTED_TARGETS: {eid} {title} triceps but has back_lat in targets")

    # leg exercise with back_lat in targets
    if main == "quads" and "back_lat" in targets:
        issues.append(f"POLLUTED_TARGETS: {eid} {title} quads but has back_lat in targets")

    # abs with quads dominant in targets
    if main == "abs" and targets.get("quads", 0) > targets.get("abs", 0):
        issues.append(f"POLLUTED_TARGETS: {eid} {title} abs main but quads higher in targets")

    # final main contradicts last norm entry (misleading only)
    if norm and main == "triceps" and any("back_lat" in n for n in norm):
        pass  # expected stale norm from v3.2

with open(r"d:\gymaipro\v36_quality_scan.txt", "w", encoding="utf-8") as wf:
    wf.write("PAGE 1 QUALITY SCAN\n\n")
    if issues:
        wf.write("\n".join(issues))
    else:
        wf.write("No quality issues found on page 1.")

print("done", len(issues))
