from pathlib import Path
p = Path(__file__).parent / "updated_exercise_meta_box.php"
text = p.read_text(encoding="utf-8")
s = text.find("// =============================================")
b = text[s:].splitlines()
Path(__file__).parent.joinpath("_dbg_lines.txt").write_text(
    "\n".join(f"{i}:{x!r}" for i, x in enumerate(b[:20])),
    encoding="utf-8",
)
