#!/usr/bin/env bash
# Build a PDF from a Markdown file (pandoc + table fix + latexmk).
# Usage: build_markdown_pdf.sh SOURCE.md [OUTPUT.pdf]
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 SOURCE.md [OUTPUT.pdf]" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
HEADER="${REPO_ROOT}/common/readme-pdf-header.tex"

SRC="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
if [[ ! -f "${SRC}" ]]; then
  echo "ERROR: ${SRC} not found." >&2
  exit 1
fi

if [[ $# -eq 2 ]]; then
  OUT="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"
else
  OUT="${SRC%.md}.pdf"
fi

JOBNAME="$(basename "${OUT}" .pdf)"
TITLE="$(grep -m1 '^# ' "${SRC}" | sed 's/^# //' || basename "${SRC}" .md)"

if ! command -v pandoc >/dev/null 2>&1; then
  echo "ERROR: pandoc not found. See docs/BUILD_DEPENDENCIES.md for install instructions." >&2
  exit 1
fi

if ! command -v pdflatex >/dev/null 2>&1; then
  echo "ERROR: pdflatex not found. See docs/BUILD_DEPENDENCIES.md for install instructions." >&2
  exit 1
fi

WORKDIR="$(mktemp -d)"
TMP="${WORKDIR}/source.md"
WRAPPED="${WORKDIR}/wrap.tex"
PATCHED="${WORKDIR}/build.tex"
trap 'rm -rf "${WORKDIR}"' EXIT

python3 "${SCRIPT_DIR}/normalize_md_for_pdf.py" "${SRC}" "${TMP}"

echo "=== Building ${OUT} from ${SRC} ==="
pandoc "${TMP}" \
  -t latex \
  -s \
  -o "${WRAPPED}" \
  -f markdown+smart \
  -V documentclass=article \
  -V fontsize=11pt \
  -V geometry:margin=1in \
  --include-in-header="${HEADER}" \
  --highlight-style=tango \
  --metadata "title=${TITLE}"

python3 "${SCRIPT_DIR}/fix_pandoc_tables.py" "${WRAPPED}" "${PATCHED}"

latexmk -pdf -interaction=nonstopmode -file-line-error -f \
  -output-directory="${WORKDIR}" -jobname="${JOBNAME}" "${PATCHED}"

if [[ ! -f "${WORKDIR}/${JOBNAME}.pdf" ]]; then
  echo "ERROR: ${OUT} was not created." >&2
  exit 1
fi

mv -f "${WORKDIR}/${JOBNAME}.pdf" "${OUT}"
echo "  ${OUT}"
