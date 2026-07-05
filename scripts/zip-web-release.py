#!/usr/bin/env python3
"""Create a Linux-friendly zip from build/web (forward slashes only)."""
from __future__ import annotations

import sys
import zipfile
from pathlib import Path


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    source = root / "build" / "web"
    output = root / "gymaipro-web-release.zip"

    if not source.is_dir():
        print(f"Missing {source} — run scripts/build-web.ps1 first.", file=sys.stderr)
        return 1

    if output.exists():
        output.unlink()

    count = 0
    with zipfile.ZipFile(
        output,
        mode="w",
        compression=zipfile.ZIP_DEFLATED,
        compresslevel=9,
    ) as zf:
        for path in sorted(source.rglob("*")):
            if not path.is_file():
                continue
            arcname = path.relative_to(source).as_posix()
            zf.write(path, arcname)
            count += 1

    size_mb = output.stat().st_size / (1024 * 1024)
    print(f"Created {output} ({count} files, {size_mb:.2f} MB)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
