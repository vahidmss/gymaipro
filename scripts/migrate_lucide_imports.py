#!/usr/bin/env python3
"""Replace lucide_icons imports without touching file encoding."""
from __future__ import annotations

from pathlib import Path

OLD = "package:lucide_icons/lucide_icons.dart"
NEW = "package:lucide_icons_flutter/lucide_icons.dart"
ROOT = Path(__file__).resolve().parents[1] / "lib"


def read_text(path: Path) -> str:
    raw = path.read_bytes()
    for encoding in ("utf-8-sig", "utf-8", "cp1256", "latin-1"):
        try:
            return raw.decode(encoding)
        except UnicodeDecodeError:
            continue
    return raw.decode("utf-8", errors="replace")


def main() -> None:
    changed = 0
    for path in ROOT.rglob("*.dart"):
        text = read_text(path)
        if OLD not in text:
            continue
        path.write_text(text.replace(OLD, NEW), encoding="utf-8", newline="\n")
        changed += 1
    print(f"Updated {changed} files")


if __name__ == "__main__":
    main()
