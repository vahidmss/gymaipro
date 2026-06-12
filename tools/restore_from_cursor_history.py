#!/usr/bin/env python3
"""Restore gymaipro files from Cursor/VS Code Local History."""
from __future__ import annotations

import hashlib
import json
import os
import shutil
import subprocess
import sys
import urllib.parse
from datetime import datetime
from pathlib import Path

HIST_ROOT = Path(os.environ.get("CURSOR_HISTORY", r"C:\Users\vahid\AppData\Roaming\Cursor\User\History"))
PROJECT = Path(r"d:\gymaipro")
BACKUP = PROJECT / f"_recovery_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8", errors="surrogateescape")).hexdigest()


def git_head_text(rel: str) -> str | None:
    try:
        out = subprocess.check_output(
            ["git", "show", f"HEAD:{rel.replace(os.sep, '/')}"],
            cwd=PROJECT,
            stderr=subprocess.DEVNULL,
        )
        return out.decode("utf-8", errors="replace")
    except subprocess.CalledProcessError:
        return None


def collect_history() -> dict[str, tuple[int, Path, str]]:
    """Map project-relative path -> (timestamp, snapshot_path, source)."""
    found: dict[str, tuple[int, Path, str]] = {}
    for entries_path in HIST_ROOT.glob("*/entries.json"):
        try:
            data = json.loads(entries_path.read_text(encoding="utf-8"))
        except Exception:
            continue
        resource = data.get("resource", "")
        if "gymaipro" not in resource.lower():
            continue
        raw = urllib.parse.unquote(resource.replace("file:///", "").replace("file://", ""))
        if raw.startswith("/") and len(raw) > 2 and raw[2] == ":":
            raw = raw[1:]
        abs_path = Path(raw.replace("/", os.sep))
        try:
            rel = abs_path.relative_to(PROJECT).as_posix()
        except ValueError:
            continue
        entries = data.get("entries") or []
        if not entries:
            continue
        latest = max(entries, key=lambda e: e.get("timestamp", 0))
        snap = entries_path.parent / latest["id"]
        if not snap.is_file():
            continue
        ts = int(latest.get("timestamp", 0))
        src = str(latest.get("source") or "")
        prev = found.get(rel)
        if prev is None or ts > prev[0]:
            found[rel] = (ts, snap, src)
    return found


def main() -> int:
    history = collect_history()
    print(f"History entries for project: {len(history)}")

    restored = 0
    skipped_same = 0
    skipped_newer_disk = 0
    created = 0
    log_lines: list[str] = []

    for rel, (ts, snap, src) in sorted(history.items()):
        target = PROJECT / rel.replace("/", os.sep)
        snap_text = snap.read_text(encoding="utf-8", errors="replace")
        snap_hash = sha256_text(snap_text)

        if target.is_file():
            cur_text = target.read_text(encoding="utf-8", errors="replace")
            cur_hash = sha256_text(cur_text)
            if cur_hash == snap_hash:
                skipped_same += 1
                continue
            disk_mtime_ms = int(target.stat().st_mtime * 1000)
            head_text = git_head_text(rel)
            head_hash = sha256_text(head_text) if head_text is not None else None
            reverted_to_git = head_hash is not None and cur_hash == head_hash
            disk_newer = disk_mtime_ms > ts + 5_000  # 5s slack
            if disk_newer and not reverted_to_git:
                skipped_newer_disk += 1
                log_lines.append(f"SKIP newer disk: {rel}")
                continue
            # backup current before overwrite
            backup_target = BACKUP / rel.replace("/", os.sep)
            backup_target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(target, backup_target)
        else:
            created += 1

        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(snap_text, encoding="utf-8", newline="\n")
        when = datetime.fromtimestamp(ts / 1000).strftime("%Y-%m-%d %H:%M")
        restored += 1
        log_lines.append(f"RESTORE [{when}] {rel} <= {snap.name} ({src})")

    report = BACKUP / "_restore_report.txt"
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text("\n".join(log_lines), encoding="utf-8")

    print(f"Backup dir: {BACKUP}")
    print(f"Restored: {restored}")
    print(f"Created missing: {created}")
    print(f"Skipped (already same): {skipped_same}")
    print(f"Skipped (newer on disk): {skipped_newer_disk}")
    print(f"Report: {report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
