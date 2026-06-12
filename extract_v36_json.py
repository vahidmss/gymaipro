# -*- coding: utf-8 -*-
import json
import re

path = r"C:\Users\vahid\.cursor\projects\d-gymaipro\agent-transcripts\d9c3fce9-c260-4840-ade6-d7d51693eae1\d9c3fce9-c260-4840-ade6-d7d51693eae1.jsonl"
raw_out = r"d:\gymaipro\v36_raw_extract.txt"
json_out = r"d:\gymaipro\v36_data.json"

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
        with open(raw_out, "w", encoding="utf-8") as wf:
            wf.write(text)
        idx = text.find('{"version"')
        if idx < 0:
            idx = text.find("{")
        if idx < 0:
            raise SystemExit("No JSON found, text len=" + str(len(text)))
        data, end = json.JSONDecoder().raw_decode(text, idx)
        with open(json_out, "w", encoding="utf-8") as wf:
            json.dump(data, wf, ensure_ascii=False, indent=2)
        print("extracted", len(data.get("items", [])), "items, version", data.get("version"))
        break
    else:
        raise SystemExit("line not found")
