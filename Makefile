.PHONY: site serve pdf notebooks notebook-check verify prose

site:
	mkdocs build --strict

serve:
	mkdocs serve

# The lab notebook is the student's report; the manual does not embed a rendered
# copy of it. Kept for staff who want a markdown snapshot of a worked notebook.
LABS_DIR ?= ../ece334-labs
notebooks:
	@command -v jupyter >/dev/null 2>&1 || { echo "jupyter not found (pip install jupyter)"; exit 1; }
	@for nb in $(LABS_DIR)/lab*/lab*.ipynb; do \
	  [ -f "$$nb" ] || continue; \
	  lab=$$(basename "$$nb" .ipynb); \
	  out="/tmp/$$lab-rendered"; \
	  mkdir -p "$$out"; \
	  echo "rendering $$nb -> $$out/$$lab.md"; \
	  jupyter nbconvert --to markdown --output "$$lab" --output-dir "$$out" "$$nb"; \
	done

# The notebooks live in the labs repo, but they are part of the deliverable the
# manual points students at, so verify them here too.
notebook-check:
	@if [ -f "$(LABS_DIR)/instructors/check_notebooks.py" ]; then \
	  python3 "$(LABS_DIR)/instructors/check_notebooks.py"; \
	else echo "labs repo not at $(LABS_DIR); skipping notebook check"; fi

# Strict build plus the checks it does not make: that every referenced image
# exists, that the notebooks parse and ship unexecuted, and that the prose has
# not drifted back toward the old register.
verify: site prose notebook-check
	@missing=0; \
	for f in $$(grep -rhoE '!\[[^]]*\]\([^)]+\)' docs --include='*.md' \
	            | sed -E 's/.*\((.*)\)/\1/' | grep -vE '^https?://' | grep -v '<' | sort -u); do \
	  found=$$(find docs -path "*/$$f" | head -1); \
	  if [ -z "$$found" ]; then echo "MISSING IMAGE: $$f"; missing=1; fi; \
	done; \
	if [ $$missing -eq 0 ]; then echo "all referenced images present"; else exit 1; fi

# The lab manuals are written in the register of the course handouts: imperative,
# unhedged, no reassurance aimed at the reader.
prose:
	@if grep -rniE "completely fine|you are in the right place|remarkable|don.t fight|happily|pays off|take it slowly|feel lost|welcome aboard|have fun|we hope|no need to worry|don.t panic|that.s the beauty" docs --include='*.md'; then \
	  echo "prose check FAILED: see matches above"; exit 1; \
	else echo "prose check passed"; fi

# TODO: PDF generation is deferred. The pandoc/LaTeX tooling lives in pdf-tools/.
# Wire each docs/labs/*/index.md through pdf-tools/build_markdown_pdf.sh once the
# markdown content is finalized and reviewed. Tracked in docs/maintainers/building.md.
pdf:
	@echo "PDF generation is not yet implemented (deferred). See docs/maintainers/building.md."
	@exit 1
