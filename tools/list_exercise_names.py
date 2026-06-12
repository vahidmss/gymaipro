#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""چاپ نام همهٔ حرکات از جدول ai_exercises.

اجرا:
  python tools/list_exercise_names.py
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]


def load_env() -> tuple[str, str]:
    env = dict(os.environ)
    dotenv = ROOT / ".env"
    if dotenv.is_file():
        for line in dotenv.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, _, v = line.partition("=")
            env[k.strip()] = v.strip().strip('"').strip("'")
    url = env.get("SUPABASE_URL", "").strip()
    key = env.get("SUPABASE_ANON_KEY", "").strip()
    return url, key


def main() -> int:
    url, key = load_env()
    if not url or not key:
        print("SUPABASE_URL و SUPABASE_ANON_KEY را در .env بگذار.", file=sys.stderr)
        return 1

    api = (
        f"{url.rstrip('/')}/rest/v1/ai_exercises"
        "?select=id,name&order=name.asc&limit=2000"
    )
    req = Request(
        api,
        headers={
            "apikey": key,
            "Authorization": f"Bearer {key}",
        },
    )
    with urlopen(req, timeout=60) as resp:
        rows = json.loads(resp.read().decode("utf-8"))

    print(f"--- ai_exercises ({len(rows)} مورد) ---\n")
    for i, row in enumerate(rows, 1):
        eid = row.get("id", "?")
        name = (row.get("name") or "").strip()
        print(f"{i:3}. [{eid}] {name}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
