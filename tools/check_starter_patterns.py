# -*- coding: utf-8 -*-
"""Simulate BeginnerStarterProgramService v2 pattern matching on v36 catalog."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ids_file = ROOT / "v36_all_ids.txt"
names = []
muscles = []
for line in ids_file.read_text(encoding="utf-8").splitlines():
    parts = line.split("\t")
    if len(parts) >= 3:
        names.append(parts[1].strip())
        muscles.append(parts[2].strip())

DEFAULT_EX = ["هالتر", "barbell", "دیپ", "بارفیکس", "ددلیفت", "بورپی"]

SESSIONS = [
    ("A", [
        (["لگ پرس", "پرس پا", "leg press"], [], ["quads"]),
        (["پرس سینه اسمیت", "پرس سینه دستگاه", "پرس سینه"], [], ["chest"]),
        (["زیربغل", "لت", "pulldown"], ["نشسته", "افقی"], ["back_lat"]),
        (["پالوف", "pallof"], [], ["abs"]),
        (["ددباگ", "dead bug"], [], ["abs"]),
    ]),
    ("B", [
        (["اسکات", "squat"], ["پرش", "هاک"], ["quads"]),
        (["فلای پک", "pec deck", "پک دک", "فلای دستگاه"], [], ["chest"]),
        (["زیربغل نشسته", "زیربغل", "رویینگ", "rowing"], [], ["back_lat"]),
        (["پشت بازو", "خرچنگ", "tricep"], ["معکوس", "هالتر"], ["triceps"]),
        (["کرانچ", "crunch"], ["دوچرخه", "رول"], ["abs"]),
    ]),
    ("C", [
        (["لانج", "lunge"], ["هالتر", "راه"], ["quads"]),
        (["شنا", "push-up", "push up"], ["دیپ", "شیب منفی"], ["chest"]),
        (["زیربغل", "لت", "رویینگ", "pulldown"], [], ["back_lat"]),
        (["جلو بازو", "جلوبازو", "biceps", "curl"], ["هالتر", "چکشی"], ["biceps"]),
        (["وال سیت", "wall sit", "پلانک", "plank"], [], ["quads"]),
    ]),
]


def blob(name: str, muscle: str) -> str:
    return (name + " " + muscle).lower().replace("\u200c", "")


def match(name, muscle, patterns, extra_ex, pref_muscles):
    b = blob(name, muscle)
    ex = DEFAULT_EX + extra_ex
    if any(x in b for x in ex):
        return False
    if any(p.lower() in b for p in patterns):
        return True
    if pref_muscles and muscle.lower() in [m.lower() for m in pref_muscles]:
        return True
    return False


def pick(patterns, extra_ex, pref_muscles, used):
    candidates = []
    for n, m in zip(names, muscles):
        if not match(n, m, patterns, extra_ex, pref_muscles):
            continue
        score = 0
        if n in used:
            score -= 18
        candidates.append((score, n))
    if not candidates:
        return None
    candidates.sort(reverse=True)
    best = candidates[0][1]
    used.add(best)
    return best


used = set()
print(f"Catalog: {len(names)} exercises\n")
ok = True
for sid, specs in SESSIONS:
    print(f"=== Session {sid} ===")
    for patterns, extra_ex, pref in specs:
        r = pick(patterns, extra_ex, pref, used)
        status = "OK" if r else "MISS"
        if not r:
            ok = False
        print(f"  {status}: {patterns[0]} -> {r or '(none)'}")
    print()

print("ALL OK" if ok else "GAPS REMAIN")
