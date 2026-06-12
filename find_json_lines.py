# -*- coding: utf-8 -*-
import json

path = r"C:\Users\vahid\.cursor\projects\d-gymaipro\agent-transcripts\d9c3fce9-c260-4840-ade6-d7d51693eae1\d9c3fce9-c260-4840-ade6-d7d51693eae1.jsonl"

with open(path, encoding="utf-8") as f:
    for i, line in enumerate(f, 1):
        if '"role":"user"' not in line:
            continue
        if "4011" not in line:
            continue
        outer = json.loads(line)
        text = outer["message"]["content"][0]["text"]
        print(i, "len", len(text), "v36", "v3.6" in text, "version", "version" in text[:500])
