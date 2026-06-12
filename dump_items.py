# -*- coding: utf-8 -*-
import json

with open(r"d:\gymaipro\v36_data.json", encoding="utf-8") as f:
    data = json.load(f)

for eid in [4021, 4010, 4012, 4014, 4015, 4017, 4018, 4020, 4024]:
    item = next((x for x in data["items"] if x["id"] == eid), None)
    if not item:
        continue
    c = item["classification"]
    out = {
        "id": eid,
        "title": item["title"],
        "main": c.get("main_muscle"),
        "movement": c.get("movement_pattern"),
        "targets": item.get("muscle_targets"),
        "secondary": c.get("secondary_muscles"),
        "equipment": c.get("equipment"),
        "norm": item.get("_normalization"),
        "notes": item.get("v3_6_patch_notes"),
    }
    with open(rf"d:\gymaipro\item_{eid}.json", "w", encoding="utf-8") as wf:
        json.dump(out, wf, ensure_ascii=False, indent=2)

# Full page list
with open(r"d:\gymaipro\v36_all_ids.txt", "w", encoding="utf-8") as wf:
    for item in data["items"]:
        c = item["classification"]
        wf.write(f"{item['id']}\t{item['title']}\t{c.get('main_muscle')}\t{c.get('movement_pattern')}\n")
