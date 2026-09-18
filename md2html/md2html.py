#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
md2doc.py — 미라클웍스(주) 표준 문서 변환기
마크다운(.md) → 인쇄 최적화 HTML(A4) 변환

작성: 2026-09-07 / v1.0
용도: 대화형 작업 산출물을 사람용(HTML) / 이관용(MD) 이중 포맷으로 유지
의존성: pip install markdown

사용법
  python3 md2doc.py input.md
  python3 md2doc.py input.md -o report.html
  python3 md2doc.py input.md --theme navy      # navy|slate|forest|mono
  python3 md2doc.py *.md --batch

버전 관리: 출력 파일이 이미 있으면 _v2, _v3 ... 로 신규 생성 (--force 시 덮어씀)
"""

import argparse
import os
import re
import sys

try:
    import markdown
except ImportError:
    sys.exit("[오류] markdown 패키지가 필요합니다:  pip install markdown")

THEMES = {
    "navy":   ("#0f3d6e", "#f3f6fa", "#f7f9fc", "#0b2f56"),
    "slate":  ("#334155", "#f1f5f9", "#f8fafc", "#1e293b"),
    "forest": ("#14532d", "#f0f7f2", "#f7fbf8", "#0f3d22"),
    "mono":   ("#1f1f1f", "#f4f4f4", "#fafafa", "#000000"),
}

CSS_TEMPLATE = """
@page {{ size: A4; margin: 18mm 15mm; }}
* {{ box-sizing: border-box; }}
body {{
  font-family: "Pretendard","Noto Sans KR","Malgun Gothic","Apple SD Gothic Neo",sans-serif;
  font-size: 10.5pt; line-height: 1.68; color: #1a1a1a;
  max-width: 900px; margin: 0 auto; padding: 40px 32px 80px;
  background: #fff; word-break: keep-all;
}}
h1 {{ font-size: 20pt; font-weight: 800; letter-spacing: -0.4px; line-height: 1.35;
     border-bottom: 3px solid {main}; padding-bottom: 14px; margin: 0 0 26px; color: {main}; }}
h2 {{ font-size: 14.5pt; font-weight: 750; margin: 34px 0 12px; padding: 8px 0 8px 12px;
     border-left: 5px solid {main}; background: {soft}; color: {main}; page-break-after: avoid; }}
h3 {{ font-size: 12pt; font-weight: 700; margin: 24px 0 8px; color: {accent}; page-break-after: avoid; }}
h4 {{ font-size: 11pt; font-weight: 700; margin: 18px 0 6px; color: #333; }}
p  {{ margin: 8px 0; }}
ul, ol {{ margin: 8px 0; padding-left: 22px; }}
li {{ margin: 4px 0; }}
table {{ border-collapse: collapse; width: 100%; margin: 14px 0 20px;
        font-size: 9.3pt; page-break-inside: avoid; }}
th {{ background: {main}; color: #fff; font-weight: 650; text-align: left;
     padding: 8px 9px; border: 1px solid {main}; vertical-align: middle; }}
td {{ padding: 7px 9px; border: 1px solid #ccd6e0; vertical-align: top; line-height: 1.5; }}
tbody tr:nth-child(even) td {{ background: {stripe}; }}
code {{ background: #eef1f5; padding: 1px 5px; border-radius: 3px;
       font-family: "D2Coding","Consolas",monospace; font-size: 9pt; }}
pre {{ background: #f6f8fa; border: 1px solid #dfe3e8; border-radius: 6px;
      padding: 12px 14px; overflow-x: auto; font-size: 9pt; page-break-inside: avoid; }}
pre code {{ background: none; padding: 0; }}
strong {{ font-weight: 750; color: {accent}; }}
em {{ color: #555; }}
hr {{ border: 0; border-top: 1px solid #d8dee6; margin: 30px 0; }}
blockquote {{ border-left: 4px solid #cbd5e0; margin: 12px 0; padding: 6px 14px;
             color: #444; background: #fafbfc; }}
a {{ color: {accent}; }}
.meta {{ background: {soft}; border: 1px solid #d3dde8; border-radius: 6px;
        padding: 14px 18px; margin: 0 0 26px; font-size: 9.6pt; }}
.meta ul {{ margin: 0; padding-left: 18px; }}
@media print {{
  body {{ padding: 0; max-width: none; font-size: 9.6pt; }}
  h2 {{ background: {soft} !important; -webkit-print-color-adjust: exact; print-color-adjust: exact; }}
  th {{ background: {main} !important; color: #fff !important;
       -webkit-print-color-adjust: exact; print-color-adjust: exact; }}
  tbody tr:nth-child(even) td {{ background: {stripe} !important;
       -webkit-print-color-adjust: exact; print-color-adjust: exact; }}
  a {{ color: inherit; text-decoration: none; }}
}}
"""

META_KEYS = ("작성시각", "작성목적", "작성자", "버전", "의뢰인", "문서번호")


def promote_meta_block(html: str) -> str:
    """문서 선두의 메타 불릿 블록을 .meta 박스로 승격."""
    m = re.search(r"<ul>\s*<li><strong>(%s)</strong>" % "|".join(META_KEYS), html)
    if not m:
        return html
    start = m.start()
    end = html.find("</ul>", start)
    if end == -1:
        return html
    end += len("</ul>")
    return html[:start] + '<div class="meta">' + html[start:end] + "</div>" + html[end:]


def next_available(path: str) -> str:
    """기존 파일 보존: 존재하면 _v2, _v3 ... 미사용 경로 반환."""
    if not os.path.exists(path):
        return path
    root, ext = os.path.splitext(path)
    n = 2
    while os.path.exists(f"{root}_v{n}{ext}"):
        n += 1
    return f"{root}_v{n}{ext}"


def convert(src_path, out_path=None, theme="navy", title=None, force=False):
    with open(src_path, encoding="utf-8") as f:
        src = f.read()

    body = markdown.markdown(
        src,
        extensions=["tables", "toc", "attr_list", "sane_lists", "fenced_code", "nl2br"],
    )
    body = promote_meta_block(body)

    if not title:
        h1 = re.search(r"^#\s+(.+)$", src, re.M)
        title = h1.group(1).strip() if h1 else os.path.splitext(os.path.basename(src_path))[0]

    main, soft, stripe, accent = THEMES.get(theme, THEMES["navy"])
    css = CSS_TEMPLATE.format(main=main, soft=soft, stripe=stripe, accent=accent)

    html = (
        '<!DOCTYPE html>\n<html lang="ko"><head><meta charset="utf-8">\n'
        '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
        f"<title>{title}</title>\n<style>{css}</style></head><body>\n{body}\n</body></html>"
    )

    if not out_path:
        out_path = os.path.splitext(src_path)[0] + ".html"
    if not force:
        out_path = next_available(out_path)

    with open(out_path, "w", encoding="utf-8") as f:
        f.write(html)

    print(f"[OK] {src_path} -> {out_path}  ({len(html):,}B, 표 {body.count('<table>')}개, theme={theme})")
    return out_path


def main():
    ap = argparse.ArgumentParser(description="마크다운 → 인쇄용 HTML 변환기")
    ap.add_argument("inputs", nargs="+", help="입력 .md 파일")
    ap.add_argument("-o", "--output", help="출력 경로 (단일 입력 전용)")
    ap.add_argument("--theme", default="navy", choices=list(THEMES))
    ap.add_argument("--title", help="문서 제목 (미지정 시 첫 H1 자동 추출)")
    ap.add_argument("--force", action="store_true", help="덮어쓰기 허용")
    ap.add_argument("--batch", action="store_true", help="일괄 변환")
    a = ap.parse_args()

    if len(a.inputs) > 1 and a.output:
        sys.exit("[오류] 복수 입력에는 -o 를 쓸 수 없습니다. --batch 를 사용하세요.")

    for p in a.inputs:
        if not os.path.exists(p):
            print(f"[건너뜀] 파일 없음: {p}")
            continue
        convert(p, a.output, a.theme, a.title, a.force)


if __name__ == "__main__":
    main()
