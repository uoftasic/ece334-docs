.PHONY: site serve pdf notebooks

site:
	mkdocs build --strict

serve:
	mkdocs serve

# Render lab notebooks into committed markdown snapshots that the lab pages embed
# (Approach A). The runnable source lives in the sibling ece334-labs checkout.
# Execute the notebooks first inside the lab container (the schematic's
# "Run analysis notebook" button, or `jupyter nbconvert --execute`); this target
# only converts the already-stored outputs, so the docs build needs no EDA tools.
LABS_DIR ?= ../ece334-labs
notebooks:
	@command -v jupyter >/dev/null 2>&1 || { echo "jupyter not found (pip install jupyter)"; exit 1; }
	@for nb in $(LABS_DIR)/lab*/lab*.ipynb; do \
	  [ -f "$$nb" ] || continue; \
	  lab=$$(basename "$$nb" .ipynb); \
	  out="docs/labs/$$lab/notebook"; \
	  mkdir -p "$$out"; \
	  echo "rendering $$nb -> $$out/$$lab.md"; \
	  jupyter nbconvert --to markdown --output "$$lab" --output-dir "$$out" "$$nb"; \
	done

# TODO: PDF generation is deferred. The pandoc/LaTeX tooling lives in pdf-tools/.
# Wire each docs/labs/*/index.md through pdf-tools/build_markdown_pdf.sh once the
# markdown content is finalized and reviewed. Tracked in docs/maintainers/building.md.
pdf:
	@echo "PDF generation is not yet implemented (deferred). See docs/maintainers/building.md."
	@exit 1
