"""Apply Cursor Chat RTL patch (Persian/Arabic/Hebrew) to local Cursor install."""
from __future__ import annotations

import json
import re
import shutil
from pathlib import Path

APP_ROOT = Path(r"C:\Users\vahid\AppData\Local\Programs\cursor\resources\app")
CONTENT_TS = Path(
    r"C:\Users\vahid\.cursor\extensions\yechielby.cursor-chat-rtl-0.1.6\src\content.ts"
)
WORKBENCH_DIR = APP_ROOT / "out" / "vs" / "workbench"
PRODUCT_JSON = APP_ROOT / "product.json"
HTML_PATH = (
    APP_ROOT / "out" / "vs" / "code" / "electron-sandbox" / "workbench" / "workbench.html"
)
CHECKSUM_KEY = "vs/code/electron-sandbox/workbench/workbench.html"
CSS_FILENAME = "cursor-chat-rtl.css"
JS_FILENAME = "cursor-chat-rtl.js"
MARKER = "cursor-chat-rtl.css"


def extract_ts_const(name: str, source: str) -> str:
    match = re.search(rf"export const {name} = `(.*?)`;", source, re.DOTALL)
    if not match:
        raise RuntimeError(f"Could not extract {name} from content.ts")
    return match.group(1)


def default_rtl_on(js: str) -> str:
    """Enable RTL by default on first launch."""
    return js.replace(
        "if (localStorage.getItem(STORAGE_KEY) === 'true') {",
        "if (localStorage.getItem(STORAGE_KEY) !== 'false') {",
    ).replace(
        "localStorage.setItem(STORAGE_KEY, isActive ? 'true' : 'false');",
        "localStorage.setItem(STORAGE_KEY, isActive ? 'true' : 'false');\n"
        "            if (!isActive) { document.body.classList.remove(BODY_CLASS); }",
    )


def inject_html(html: str) -> str:
    if MARKER in html:
        return html

    css_link = (
        "\n\t<!-- Cursor Chat RTL Support -->\n"
        f'\t<link rel="stylesheet" href="../../../workbench/{CSS_FILENAME}">'
    )
    css_pattern = re.compile(r"<link[^>]*workbench\.desktop\.main\.css[^>]*>")
    css_match = css_pattern.search(html)
    if css_match:
        insert_pos = css_match.end()
        html = html[:insert_pos] + css_link + html[insert_pos:]
    else:
        html = html.replace("</head>", css_link + "\n\t</head>")

    script_tag = (
        "\t<!-- Cursor Chat RTL Support -->\n"
        f'\t<script src="../../../workbench/{JS_FILENAME}"></script>\n'
    )
    html_close = html.rfind("</html>")
    if html_close == -1:
        raise RuntimeError("workbench.html has no </html>")
    return html[:html_close] + script_tag + html[html_close:]


def remove_checksum(product_path: Path) -> None:
    backup = product_path.with_suffix(".json.bak")
    data = json.loads(product_path.read_text(encoding="utf-8"))
    checksums = data.get("checksums") or {}
    if CHECKSUM_KEY not in checksums:
        return
    if not backup.exists():
        shutil.copy2(product_path, backup)
    del checksums[CHECKSUM_KEY]
    data["checksums"] = checksums
    product_path.write_text(json.dumps(data, indent="\t") + "\n", encoding="utf-8")


def main() -> None:
    if not CONTENT_TS.exists():
        raise SystemExit(f"Missing extension source: {CONTENT_TS}")
    if not HTML_PATH.exists():
        raise SystemExit(f"Missing workbench.html: {HTML_PATH}")

    source = CONTENT_TS.read_text(encoding="utf-8")
    css = extract_ts_const("RTL_CSS", source)
    js = default_rtl_on(extract_ts_const("RTL_JS", source))

    WORKBENCH_DIR.mkdir(parents=True, exist_ok=True)
    (WORKBENCH_DIR / CSS_FILENAME).write_text(css, encoding="utf-8")
    (WORKBENCH_DIR / JS_FILENAME).write_text(js, encoding="utf-8")

    html = HTML_PATH.read_text(encoding="utf-8")
    if MARKER not in html:
        backup = Path(str(HTML_PATH) + ".bak")
        if not backup.exists():
            shutil.copy2(HTML_PATH, backup)
        HTML_PATH.write_text(inject_html(html), encoding="utf-8")

    remove_checksum(PRODUCT_JSON)
    print("Cursor Chat RTL installed successfully.")
    print("Please fully quit Cursor (File -> Exit) and reopen it.")


if __name__ == "__main__":
    main()
