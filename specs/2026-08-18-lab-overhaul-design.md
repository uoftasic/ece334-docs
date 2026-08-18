# ECE334 lab overhaul — design

Date: 2026-08-18
Status: approved, in implementation

## Problem

The 2025 rewrite of the ECE334 labs onto SKY130 / XSchem / Magic is incomplete in
four specific ways.

1. **The labs do not run.** Lab 1's inverter testbench netlists with
   `x1 - dut_inv IS MISSING !!!!` and produces a deck containing no transistors.
   Root cause: `common/.designinit` exports `XSCHEMRC`, which XSchem never reads.
   XSchem sources `$XSCHEM_SHAREDIR/xschemrc`, then `./xschemrc`, then
   `~/.xschem/xschemrc` (`src/xinit.c:2732-2790`). The course config was therefore
   never loaded, and `common/xschemrc` additionally built
   `XSCHEM_LIBRARY_PATH` with `append` calls that omitted the `:` separator,
   concatenating every path into one unusable string.
2. **No screenshots.** 21 `screenshot pending` placeholders across four lab pages;
   all five `images/` directories contain only `.gitkeep`.
3. **The prose reads as generated text.** Cheerleading, editorialising, and
   admonition density far above the reference handouts.
4. **Labs 2-4 and Lab 0 have no design files.** Labs 2, 3 and 4 ship SPICE decks
   only — no XSchem schematics, no DUT symbols, no notebooks. Lab 0 ships nothing
   but a README. Only Lab 1 has schematics, and only Lab 1 has a notebook.

## Scope

All five labs (0-4), both repositories, to full depth: prose rewrite, real
screenshots, missing design files, per-lab notebooks, and verification.

Out of scope: changing the PDK, the supply voltage, or the teaching channel
length; grading policy; any change to the container image.

## Decisions

| # | Decision | Rationale |
|---|---|---|
| D1 | Docs site is the manual; the notebook is the lab report | Professors want one artifact holding the student's work. Manual stays in Markdown where screenshots and diffs are manageable. |
| D2 | Mirror the legacy section skeleton: Objective / Preparation (P*n*) / Lab Work (L*n*) / Expected Results / Extra Notes / FAQ | Staff can diff old against new one-to-one; the "demonstrate to your TA" checklists carry over unchanged. |
| D3 | Magic stays the layout tool | Only Magic gives `extract` + `ext2spice cthresh 0`, so only Magic supports Lab 2's pre- versus post-PEX comparison. KLayout's SKY130 support is DRC and LVS only. Magic is also the closest analogue to the legacy MAX. |
| D4 | Lab 2's reference NAND2 layout is instructor-only; students receive it as figures | Matches the legacy handout, which prints the finished layout as Figure 2 but expects the student to redraw it. |
| D5 | The pulse generator returns, split by depth | It was cut for being too advanced. The fix is sequencing, not deletion — see "Pulse generator on-ramp" below. |
| D6 | Delete the two migration deep-dives; fold their mechanics into the cheatsheets and Lab 0 | Incoming students have never used SUE or MAX, so "here is the SUE equivalent" is noise. |

## Pulse generator on-ramp

The concern behind D5 is real: students take the lab concurrently with the
lectures and have not yet covered gate delay when Lab 0 and Lab 1 run. The
prerequisite is an introductory nonlinear-circuits course.

That is sufficient, provided the concept is introduced through RC charging rather
than through digital-logic theory. The chain already exists inside Lab 1:

1. **P1** measures an RC step response and its time constant. Pure circuit
   theory; no new concepts.
2. **P2** extracts $K_P$ and $V_t$ from a diode-connected device, then models a
   conducting transistor as $R_{eq}$. Again first-year device physics.
3. The inverter's delay is then *the same RC charge* from P1, with $R_{eq}$ in
   place of the resistor and the load capacitance in place of $C_1$. No gate-delay
   lecture is required to reach this.
4. A pulse generator is a NAND fed by a signal and a delayed inversion of it. Its
   output width is the chain delay from step 3. The only new idea is a two-row
   truth table.

Split by depth:

- **Lab 0 (ungraded, tool familiarity): observational.** Build the inverter and
  NAND symbols, wire them into a pulse generator, observe that a narrow pulse
  appears. No timing analysis, no prediction.
- **Lab 1 (graded): quantitative.** Rebuild at transistor level, predict the
  pulse width from the measured $R_{eq}$ and $C_L$, confirm against simulation,
  then size the circuit for a 1.5 ns pulse.

If the Lab 0 section cannot be written without leaning on unlectured material, it
is cut back to "build the hierarchy" and the pulse observation moves to Lab 1.

## Repository contract

The two repos are coupled by three things only.

1. **Net names** — `in`, `out`, `vdd`, `vss` for single-input circuits; documented
   per-lab additions otherwise (`a`, `b`, `y`, `clk`, `d`, `q`, `bit`, `bit_b`,
   `word`).
2. **Result filenames** — each testbench writes a named `.raw`; the notebook reads
   that exact name.
3. **Section numbers** — manual `P1`/`L1` map to notebook headings `P1`/`L1`.

Nothing else. A lab page must be readable without the notebook, and a notebook
must run without the lab page open.

## Per-lab structure

Each lab is four artifacts.

| Artifact | Location |
|---|---|
| Manual page | `ece334-docs/docs/labs/labN/index.md` |
| Figures | `ece334-docs/docs/labs/labN/images/NN-slug.png` |
| Design files | `ece334-labs/labN_*/xschem/`, `.../magic/`, `.../spice/` |
| Report notebook | `ece334-labs/labN_*/labN.ipynb` |

Notebook cell taxonomy, in this order per section:

1. Markdown heading matching the manual's section number.
2. **Hand analysis** — a code cell with the symbolic result and named constants
   the student edits with their own extracted values.
3. **Measurement** — `ece334lib` calls that load the `.raw` and print metrics.
4. **Answer block** — a markdown cell the student writes their comparison and
   discussion into. This is what gets graded.

## Content map

Legacy content is preserved and retargeted from 2.5 V / 0.25 µm to 1.8 V /
$L = 0.5\,\mu$m. Device W/L *ratios* are preserved; absolute widths are recomputed
and then confirmed by simulation and, for Lab 2, by DRC and LVS.

| Lab | Sections |
|---|---|
| 0 | Tool tour; transistor-level inverter; symbol creation; NAND2; pulse generator (observational); standard-cell comparison; first Magic transistor |
| 1 | P1 RC divider step response; P2 $K_P$/$V_t$ extraction; P3 inverter VTC, noise margins, transient versus hand estimate; P4 transistor-level pulse generator, loaded, and the 1.5 ns design task |
| 2 | NAND2 layout; DRC to zero errors; extraction; XSchem reference schematic; Netgen LVS; PEX; pre- versus post-PEX timing |
| 3 | Unit inverter at $C_L = 0.3$ pF; AOI21 $Y = \overline{A + BC}$ sizing for 1.5 pF, worst and best case; transmission-gate DFF functional verification |
| 4 | DFF setup time; $t_{PCQ}$; two DFFs plus four inverters and $f_{max}$; 6T SRAM sizing, read time, and deliberate read-stability and write-stability violations |

## Prose standard

Imperative, declarative, unhedged. Concretely:

- No encouragement or reassurance directed at the reader.
- No editorial claims about the tools or the field.
- Admonitions reserved for hazards that cost real time. The `W=1u` unit trap
  qualifies; "press Home if lost" does not.
- Every number either derived in the text or cited to a measurement.
- Figures carry captions stating what the reader should see, not what to feel.

Getting Started keeps its per-OS depth. Its problem is tone, not coverage.

## Verification

A lab is not done until, in the container:

1. Every schematic netlists headlessly with zero `IS MISSING`.
2. Every deck simulates with exit status 0 and produces its named output.
3. Measured values match the documented hand analysis within a stated tolerance,
   and both numbers appear in the manual.
4. Lab 2 additionally reaches `drc count` = 0 and Netgen "Circuits match
   uniquely."
5. `pytest ece334lib` passes.
6. `mkdocs build --strict` passes with no broken links or missing images.

Screenshots are captured from the live tools on the container's X display via
`xdotool` and `import`, never mocked. Waveform figures are produced by matplotlib
through `ece334lib` so they are legible and reproducible.

## Risks

| Risk | Handling |
|---|---|
| DFF (~20 devices) and 6T SRAM plus periphery are large schematics to author and must converge | Author programmatically as `.sch` text, verify by netlist and simulation. If convergence needs per-case `.ic`, document it in the lab. |
| Lab 2 sizing at $L = 0.5\,\mu$m may not be DRC-clean at the legacy ratios | Ratios are the requirement; absolute widths are free. Adjust widths until DRC and LVS pass, then record the final numbers in `conventions.md`. |
| Notebook outputs bloat the repo | Notebooks are committed with outputs cleared. The docs embed a rendered snapshot instead. |
| Screenshots drift as tools update | Filenames are stable and numbered; capture is scripted so figures can be regenerated. |
