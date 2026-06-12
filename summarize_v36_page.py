# -*- coding: utf-8 -*-
import json

with open(r"d:\gymaipro\v36_data.json", encoding="utf-8") as f:
    data = json.load(f)

lines = []
for item in data["items"]:
    c = item.get("classification", {})
    lines.append(
        f"{item['id']}\t{item.get('title','')[:40]}\t{c.get('main_muscle')}\t{c.get('movement_pattern')}\t{list(item.get('muscle_targets',{}).keys())}"
    )

with open(r"d:\gymaipro\v36_page1_summary.txt", "w", encoding="utf-8") as wf:
    wf.write("\n".join(lines))
