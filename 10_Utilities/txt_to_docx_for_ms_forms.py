from pathlib import Path
import sys
import zipfile
from xml.sax.saxutils import escape


def build_docx_from_txt(src_path: Path, out_path: Path) -> None:
    text = src_path.read_text(encoding="utf-8")
    lines = text.splitlines()

    filtered = []
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

    # Merge consecutive non-empty lines into one paragraph with a space between them.
    # This handles cases where a long answer or question text is split across
    # multiple physical lines in the source .txt file.  Without this step, each
    # physical line becomes its own <w:p> and MS Forms joins them without spaces.
    #
    # Rules:
    #   - Empty line  → flush pending paragraph, emit empty separator.
    #   - Tab-prefixed line (answer choice) → flush pending, start fresh pending.
    #   - Any other non-empty line → append to current pending with a space.
    merged: list[str] = []
    pending: str | None = None
    for line in filtered:
        if not line.strip():
            if pending is not None:
                merged.append(pending)
                pending = None
            merged.append('')
        elif line.startswith('\t'):
            if pending is not None:
                merged.append(pending)
            pending = line
        else:
            if pending is None:
                pending = line
            else:
                pending = pending.rstrip() + ' ' + line.lstrip()
    if pending is not None:
        merged.append(pending)

    paragraphs = []
    for line in merged:
        if not line.strip():
            paragraphs.append('<w:p/>')
            continue
        parts = line.split('\t')
        runs = []
        for i, part in enumerate(parts):
            if i > 0:
                runs.append('<w:r><w:tab/></w:r>')
            if part:
                # preserve spaces aggressively by splitting spaces into separate runs
                buf = []
                for ch in part:
                    if ch == ' ':
                        if buf:
                            runs.append(f'<w:r><w:t xml:space="preserve">{escape("".join(buf))}</w:t></w:r>')
                            buf = []
                        runs.append('<w:r><w:t xml:space="preserve"> </w:t></w:r>')
                    else:
                        buf.append(ch)
                if buf:
                    runs.append(f'<w:r><w:t xml:space="preserve">{escape("".join(buf))}</w:t></w:r>')
        paragraphs.append(f"<w:p>{''.join(runs)}</w:p>")

    document_xml = f"""<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>
<w:document xmlns:wpc=\"http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas\" xmlns:mc=\"http://schemas.openxmlformats.org/markup-compatibility/2006\" xmlns:o=\"urn:schemas-microsoft-com:office:office\" xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\" xmlns:m=\"http://schemas.openxmlformats.org/officeDocument/2006/math\" xmlns:v=\"urn:schemas-microsoft-com:vml\" xmlns:wp14=\"http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing\" xmlns:wp=\"http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing\" xmlns:w10=\"urn:schemas-microsoft-com:office:word\" xmlns:w=\"http://schemas.openxmlformats.org/wordprocessingml/2006/main\" xmlns:w14=\"http://schemas.microsoft.com/office/word/2010/wordml\" xmlns:wpg=\"http://schemas.microsoft.com/office/word/2010/wordprocessingGroup\" xmlns:wpi=\"http://schemas.microsoft.com/office/word/2010/wordprocessingInk\" xmlns:wne=\"http://schemas.microsoft.com/office/word/2006/wordml\" xmlns:wps=\"http://schemas.microsoft.com/office/word/2010/wordprocessingShape\" mc:Ignorable=\"w14 wp14\">
  <w:body>
    {''.join(paragraphs)}
    <w:sectPr>
      <w:pgSz w:w=\"12240\" w:h=\"15840\"/>
      <w:pgMar w:top=\"1440\" w:right=\"1440\" w:bottom=\"1440\" w:left=\"1440\" w:header=\"708\" w:footer=\"708\" w:gutter=\"0\"/>
      <w:cols w:space=\"708\"/>
      <w:docGrid w:linePitch=\"360\"/>
    </w:sectPr>
  </w:body>
</w:document>"""

    content_types = """<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>
<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">
  <Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/>
  <Default Extension=\"xml\" ContentType=\"application/xml\"/>
  <Override PartName=\"/word/document.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml\"/>
  <Override PartName=\"/docProps/core.xml\" ContentType=\"application/vnd.openxmlformats-package.core-properties+xml\"/>
  <Override PartName=\"/docProps/app.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.extended-properties+xml\"/>
</Types>"""

    rels = """<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>
<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">
  <Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\" Target=\"word/document.xml\"/>
  <Relationship Id=\"rId2\" Type=\"http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties\" Target=\"docProps/core.xml\"/>
  <Relationship Id=\"rId3\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties\" Target=\"docProps/app.xml\"/>
</Relationships>"""

    word_rels = """<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>
<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\"/>"""

    core = f"""<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>
<cp:coreProperties xmlns:cp=\"http://schemas.openxmlformats.org/package/2006/metadata/core-properties\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:dcmitype=\"http://purl.org/dc/dcmitype/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">
  <dc:title>{escape(src_path.stem)}</dc:title>
  <dc:creator>Kilo Code</dc:creator>
</cp:coreProperties>"""

    app = """<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>
<Properties xmlns=\"http://schemas.openxmlformats.org/officeDocument/2006/extended-properties\" xmlns:vt=\"http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes\">
  <Application>Microsoft Office Word</Application>
</Properties>"""

    with zipfile.ZipFile(out_path, 'w', compression=zipfile.ZIP_DEFLATED) as zf:
        zf.writestr('[Content_Types].xml', content_types)
        zf.writestr('_rels/.rels', rels)
        zf.writestr('word/document.xml', document_xml)
        zf.writestr('word/_rels/document.xml.rels', word_rels)
        zf.writestr('docProps/core.xml', core)
        zf.writestr('docProps/app.xml', app)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        raise SystemExit('Usage: python txt_to_docx_for_ms_forms.py <input.txt> [output.docx]')
    src = Path(sys.argv[1])
    out = Path(sys.argv[2]) if len(sys.argv) > 2 else src.with_suffix('.docx')
    build_docx_from_txt(src, out)
