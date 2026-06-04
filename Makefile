.PHONY: site serve pdf

site:
	mkdocs build --strict

serve:
	mkdocs serve

# TODO: PDF generation is deferred. The pandoc/LaTeX tooling lives in pdf-tools/.
# Wire each docs/labs/*/index.md through pdf-tools/build_markdown_pdf.sh once the
# markdown content is finalized and reviewed. Tracked in docs/maintainers/building.md.
pdf:
	@echo "PDF generation is not yet implemented (deferred). See docs/maintainers/building.md."
	@exit 1
