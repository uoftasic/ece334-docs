#!/usr/bin/env bash
# Build README.pdf from README.md (maintained source for the course guide).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
exec "${SCRIPT_DIR}/build_markdown_pdf.sh" "${REPO_ROOT}/README.md" "${REPO_ROOT}/README.pdf"
