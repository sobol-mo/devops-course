from pathlib import Path
import sys
from fpdf import FPDF

FONT_REGULAR = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
FONT_BOLD    = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FONT_MONO    = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"

FONT_SIZE_TITLE  = 13
FONT_SIZE_NORMAL = 11
LINE_HEIGHT      = 6   # mm per line


def _strip_backticks(text: str) -> str:
    """Remove backtick markers, keeping the enclosed content as plain text."""
    return text.replace('`', '')


def _write_words(pdf: FPDF, text: str, line_height: float, indent_x: float) -> None:
    """Write text word-by-word using cell(), keeping every space as an explicit
    PDF text character.

    Both write() and multi_cell() consume the space that acts as a word-break
    at wrap boundaries, so pdftotext (and MS Forms import) lose that space.
    By writing each word and each space as a separate cell() call we ensure
    every character is explicitly embedded in the PDF text stream.
    """
    pdf.set_x(indent_x)
    words = text.split(' ')
    for i, word in enumerate(words):
        if not word:
            continue
        ww = pdf.get_string_width(word)
        # Wrap to next line if the word doesn't fit
        if ww > pdf.w - pdf.r_margin - pdf.get_x() and pdf.get_x() > indent_x:
            pdf.ln(line_height)
            pdf.set_x(indent_x)
        pdf.cell(ww, line_height, word)
        if i < len(words) - 1:
            sw = pdf.get_string_width(' ')
            pdf.cell(sw, line_height, ' ')
    pdf.ln(line_height)


def build_pdf_from_txt(src_path: Path, out_path: Path) -> None:
    text = src_path.read_text(encoding="utf-8")
    lines = text.splitlines()

    # ── Filter header / metadata lines ──────────────────────────────────────
    filtered: list[str] = []
    title_kept = False
    for line in lines:
        stripped = line.strip()
        if not title_kept:
            if stripped:
                filtered.append(line)
                title_kept = True
            continue
        if not stripped:
            filtered.append("")
            continue
        if stripped.startswith("Для імпорту"):
            continue
        if stripped.startswith("Дата:"):
            continue
        if stripped.startswith("Рекомендація для викладача:"):
            continue
        if set(stripped) == {"="}:
            continue
        if stripped.startswith("Правила форматування:"):
            continue
        if stripped.startswith("-"):
            continue
        filtered.append(line)

    # ── Merge wrapped lines (same logic as the .docx converter) ─────────────
    # Consecutive non-empty lines without a leading tab are joined with a space
    # so that a physically-wrapped sentence stays one logical paragraph.
    merged: list[str] = []
    pending: str | None = None
    for line in filtered:
        if not line.strip():
            if pending is not None:
                merged.append(pending)
                pending = None
            merged.append("")
        elif line.startswith("\t"):
            if pending is not None:
                merged.append(pending)
            pending = line
        else:
            if pending is None:
                pending = line
            else:
                pending = pending.rstrip() + " " + line.lstrip()
    if pending is not None:
        merged.append(pending)

    # ── Build PDF ─────────────────────────────────────────────────────────────
    pdf = FPDF()
    pdf.add_font("regular", style="",  fname=FONT_REGULAR)
    pdf.add_font("regular", style="B", fname=FONT_BOLD)

    pdf.set_auto_page_break(auto=True, margin=15)
    pdf.add_page()
    pdf.set_margins(left=20, top=20, right=20)

    first_line = True
    for line in merged:
        stripped = line.strip()

        if not stripped:
            pdf.ln(LINE_HEIGHT // 2)
            continue

        if first_line:
            # Title line
            pdf.set_font("regular", style="B", size=FONT_SIZE_TITLE)
            pdf.multi_cell(0, LINE_HEIGHT, stripped)
            pdf.ln(2)
            first_line = False
            continue

        pdf.set_font("regular", size=FONT_SIZE_NORMAL)
        if line.startswith("\t"):
            # Answer choice — strip leading tab, indent slightly
            content = _strip_backticks(line.lstrip("\t"))
            _write_words(pdf, content, LINE_HEIGHT, pdf.l_margin + 8)
        else:
            # Question text
            content = _strip_backticks(stripped)
            _write_words(pdf, content, LINE_HEIGHT, pdf.l_margin)

    pdf.output(str(out_path))


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit("Usage: python txt_to_pdf_for_ms_forms.py <input.txt> [output.pdf]")
    src = Path(sys.argv[1])
    out = Path(sys.argv[2]) if len(sys.argv) > 2 else src.with_suffix(".pdf")
    build_pdf_from_txt(src, out)
    print(f"Saved: {out}")
