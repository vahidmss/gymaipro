from pathlib import Path
root = Path(__file__).parent
src = (root / "updated_exercise_meta_box.php").read_text(encoding="utf-8")
marker = "add_action('add_meta_boxes', 'gymai_add_exercise_meta_box');"
start = src.find(marker)
end = src.find("// =============================================\n// REST API")
if start < 0 or end < 0:
    raise SystemExit(f"markers not found start={start} end={end}")
body = src[start:end].rstrip()
out = (
    "// GymAI Code Snippet 2 — Metabox (NO <?php tag)\n"
    "// Run: Admin only\n\n"
    + body
    + "\n"
)
(root / "CODE_SNIPPET_2_METABOX.php").write_text(out, encoding="utf-8")
print("OK", len(out), "lines", out.count(chr(10)))
