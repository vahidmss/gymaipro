#!/usr/bin/env python3
"""Audit 10 exercise posts: live API meta vs exercises_bulk_meta.json"""
import json
import urllib.request
from pathlib import Path

IDS = [3831, 3832, 3842, 3844, 3847, 3849, 3851, 3853, 3855, 3857]
ROOT = Path(__file__).resolve().parent
EXPECTED = json.loads((ROOT / "exercises_bulk_meta.json").read_text(encoding="utf-8"))[
    "exercises"
]

ADV_KEYS = [
    "short_description",
    "movement_pattern",
    "body_engagement",
    "met",
    "muscle_targets_json",
    "typical_rpe",
    "movement_distance_cm",
    "calories_per_1000kg",
    "exercise_difficulty_score",
    "estimated_1rm_formula",
    "target_area",
]

COMPARE = [
    "name_app",
    "main_muscle",
    "difficulty",
    "equipment",
    "exercise_type",
    "target_area",
    "met",
    "movement_pattern",
    "body_engagement",
    "typical_rpe",
    "movement_distance_cm",
    "calories_per_1000kg",
    "exercise_difficulty_score",
    "estimated_1rm_formula",
]


def norm(v):
    if v is None:
        return ""
    if isinstance(v, list):
        return ", ".join(str(x) for x in v)
    return str(v).strip()


def fetch(post_id: int) -> dict:
    url = f"https://gymaipro.ir/wp-json/wp/v2/exercises/{post_id}"
    req = urllib.request.Request(url, headers={"User-Agent": "GymAI-Audit/1.0"})
    with urllib.request.urlopen(req, timeout=45) as resp:
        return json.load(resp)


def compare_muscle(api_json: str, expected_mt: dict | None) -> list[str]:
    if not expected_mt:
        return []
    try:
        got = json.loads(api_json or "{}")
    except json.JSONDecodeError:
        return ["muscle_targets_json: invalid JSON"]
    issues = []
    for k, v in expected_mt.items():
        if got.get(k) != v:
            issues.append(f"muscle {k}: api={got.get(k)!r} expected={v!r}")
    return issues


def main():
    rows = []
    for pid in IDS:
        data = fetch(pid)
        meta = data.get("meta") or {}
        exp = EXPECTED.get(str(pid), {})
        title = (data.get("title") or {}).get("rendered", "?")

        missing_adv = [k for k in ADV_KEYS if not norm(meta.get(k))]
        mismatches = []
        for field in COMPARE:
            ev = norm(exp.get(field, ""))
            av = norm(meta.get(field, ""))
            if ev and av != ev:
                mismatches.append(f"{field}: API «{av}» ≠ expected «{ev}»")

        mismatches.extend(compare_muscle(meta.get("muscle_targets_json"), exp.get("muscle_targets")))

        if not missing_adv and not mismatches:
            status = "complete"
        elif missing_adv:
            status = "missing_advanced"
        else:
            status = "wrong_values"

        rows.append(
            {
                "id": pid,
                "title": title,
                "status": status,
                "missing_adv": missing_adv,
                "mismatches": mismatches,
                "api": {k: meta.get(k) for k in ADV_KEYS + COMPARE if k in meta},
            }
        )

    out_path = ROOT / "audit_10_report.json"
    out_path.write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding="utf-8")

    complete = sum(1 for r in rows if r["status"] == "complete")
    print(f"Complete: {complete}/10\n")
    for r in rows:
        icon = {"complete": "OK", "missing_advanced": "!!", "wrong_values": "~"}[r["status"]]
        print(f"[{icon}] {r['id']} {r['title']}")
        if r["missing_adv"]:
            print(f"    missing: {', '.join(r['missing_adv'])}")
        for m in r["mismatches"][:6]:
            print(f"    - {m}")
    print(f"\nFull report: {out_path}")


if __name__ == "__main__":
    main()
