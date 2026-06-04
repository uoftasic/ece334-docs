#!/usr/bin/env python3
"""Write a pdflatex-safe copy of a Markdown file without altering the original."""
from __future__ import annotations

import sys
from pathlib import Path

# Applied only to the temporary build copy — source .md files are never modified.
REPLACEMENTS = {
    "\u2713": "",  # ✓
    "\u2717": "X",  # ✗
    "\u2194": "<->",  # ↔
    "\u2192": "->",  # →
    "\u00b0": " deg",  # °
    "\u00d7": "x",  # ×
    "\u00b5": "u",  # µ (e.g. um, uCox)
    "\u2026": "...",  # …
    "\u26a0\ufe0f": "",  # ⚠️
    "\u26a0": "",  # ⚠
    "\U0001f389": "",  # 🎉
    "\u2705": "",  # ✅
    "\u274c": "",  # ❌
    "\u2013": "-",  # en dash
    "\u2014": "--",  # em dash
    "\u00a7": "Section ",  # §
}


def normalize(text: str) -> str:
    for src, dst in REPLACEMENTS.items():
        text = text.replace(src, dst)
    return text


def main() -> None:
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} INPUT.md OUTPUT.md", file=sys.stderr)
        sys.exit(1)
    src, dst = Path(sys.argv[1]), Path(sys.argv[2])
    dst.write_text(normalize(src.read_text(encoding="utf-8")), encoding="utf-8")


if __name__ == "__main__":
    main()
