#!/usr/bin/env python3
"""Post-process pandoc LaTeX to fix table column overflow.

Pandoc wraps table cells in minipages sized with \\columnwidth, but inside
longtable that width is the full page — cells spill into neighbouring columns.
This script strips those minipages and uses fixed p{...} column specs.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path


def _strip_minipages(tex: str) -> str:
    tex = re.sub(
        r"\\begin\{minipage\}\[[bt]\]\{[^}]+\}\\raggedright\s*",
        "",
        tex,
    )
    tex = re.sub(r"\\end\{minipage\}", "", tex)
    tex = tex.replace(r"\strut", "")
    return tex


def _fix_longtables(tex: str) -> str:
    col2 = (
        r"\begin{longtable}{@{}"
        r">{\raggedright\arraybackslash}p{0.26\textwidth}"
        r">{\raggedright\arraybackslash}p{0.69\textwidth}@{}}"
    )
    col3 = (
        r"\begin{longtable}{@{}"
        r">{\raggedright\arraybackslash}p{0.18\textwidth}"
        r">{\raggedright\arraybackslash}p{0.34\textwidth}"
        r">{\raggedright\arraybackslash}p{0.42\textwidth}@{}}"
    )
    tex = tex.replace(r"\begin{longtable}[]{@{}ll@{}}", col2)
    tex = tex.replace(r"\begin{longtable}[]{@{}lll@{}}", col3)
    return tex


def fix_pandoc_tables(tex: str) -> str:
    tex = _strip_minipages(tex)
    tex = _fix_longtables(tex)
    return tex


def main() -> None:
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} INPUT.tex OUTPUT.tex", file=sys.stderr)
        sys.exit(1)
    src, dst = Path(sys.argv[1]), Path(sys.argv[2])
    dst.write_text(fix_pandoc_tables(src.read_text(encoding="utf-8")), encoding="utf-8")


if __name__ == "__main__":
    main()
