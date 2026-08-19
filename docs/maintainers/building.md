# Building the docs

This page is for course staff maintaining the documentation site. Students do **not** need any
of this — they read the published site.

## The website (active)

The site is built with [MkDocs](https://www.mkdocs.org/) + the
[Material](https://squidfunk.github.io/mkdocs-material/) theme. Markdown under `docs/` is the
**single source of truth**.

```bash
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt

make serve     # live preview at http://127.0.0.1:8000
make site      # strict production build into site/
```

`make site` runs `mkdocs build --strict`, which fails on broken links, missing pages, or missing
media — keep it green. On push to `main`, the
[`deploy-docs.yml`](https://github.com/uoftasic/ece334-docs/actions) workflow builds and publishes
to GitHub Pages.

### Authoring conventions

- **Lab manuals** live at `docs/labs/lab{0..4}/index.md`. The shared course-conventions table is a
  snippet included with `--8<-- "includes/conventions.md"`.
- **Custom admonitions** `terminal`, `xschem`, and `magic` are styled in
  `docs/stylesheets/extra.css` (mirroring the original LaTeX colour boxes). Use them as
  `!!! terminal "In the noVNC desktop terminal"`, etc.
- **Math** uses `pymdownx.arithmatex` (generic mode + MathJax). Inline `$...$`, display `$$...$$`.
- **Figures** live in each lab's `images/` directory, named `NN-slug.png`. They are
  generated, not collected by hand:
    - Tool screenshots come from `ece334-labs/scripts/make_figures.sh`, which drives
      XSchem and Magic on the container's X display.
    - Waveform figures come from `ece334-labs/instructors/figures/make_waveform_figs.py`,
      which plots real simulation output with matplotlib so the axes and the measured
      value are legible and reproducible.
  Both need the reference solutions in `ece334-labs/instructors/`. Run
  `scripts/install_capture_deps.sh` once per container first.
- **Checks:** `make verify` runs the strict build, confirms every referenced image
  exists, and fails if the prose drifts back toward the pre-2026 register.

## PDF generation (TODO — deferred)

PDFs (for Canvas distribution) are **not yet wired up**. The pandoc → LaTeX tooling has been
carried over into `pdf-tools/` so it can be enabled later without re-migration:

| File | Role |
|------|------|
| `pdf-tools/build_markdown_pdf.sh` | Convert one markdown file to PDF (pandoc → `pdflatex`) |
| `pdf-tools/build_readme.sh` | Build the top-level guide PDF |
| `pdf-tools/normalize_md_for_pdf.py` | Normalize Unicode in a temp copy before pandoc |
| `pdf-tools/fix_pandoc_tables.py` | Post-process pandoc table widths |
| `pdf-tools/ece334.sty` | Shared LaTeX style |
| `pdf-tools/readme-pdf-header.tex` | LaTeX header for the markdown → PDF path |

The intended flow is `pdf-tools/build_markdown_pdf.sh docs/labs/labN/index.md` per manual, wired
into the `make pdf` target and attached as release assets. It is intentionally left inactive until
the markdown content is finalized and reviewed.

### Dependencies (when activating PDFs)

Install on a Linux/macOS machine or CI runner:

```bash
# Ubuntu / Debian / WSL2
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  texlive-latex-base texlive-latex-recommended texlive-latex-extra \
  texlive-fonts-recommended texlive-fonts-extra latexmk pandoc
```

```bash
# macOS (Homebrew)
brew install --cask mactex-no-gui
brew install pandoc
```

`pdflatex` is provided by the TeX Live packages; pandoc invokes it as `--pdf-engine=pdflatex`.
Verify with `latexmk --version`, `pandoc --version`, `pdflatex --version`.
