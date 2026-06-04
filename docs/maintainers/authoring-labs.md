# Authoring an interactive lab

The recipe Lab 1 establishes. Every lab is built from the same four parts, so once
you've read this you can bring up Labs 2–4 by analogy.

## The four parts

1. **A testbench harness** (`ece334-labs/labN/xschem/<thing>_tb.sch`)
   - Stimulus source(s), load, and supply, wired to nets named `in`, `out`, `vdd`,
     `vss`.
   - A **DUT placeholder**: a subcircuit symbol whose pins are exactly those nets.
     Students build their circuit in the schematic behind it. See
     `lab1_spice/xschem/dut_inv.sym` / `dut_inv.sch`.
   - **Launcher buttons** (`devices/launcher.sym`):
     - `Netlist & Simulate` → `tclcommand="xschem save; xschem netlist; xschem simulate"`
     - `Annotate OP` → `tclcommand="set show_hidden_texts 1; xschem annotate_op"`
     - `Run analysis notebook` → execs `jupyter nbconvert --execute` on the lab notebook
   - An embedded **SPICE control block** (`devices/code_shown.sym`) that, after the
     analysis, does `set filetype=ascii` and `write <name>.raw v(in) v(out)`. The
     `.raw` filename is the contract the notebook reads.

   !!! warning "Subcircuit symbol gotcha"
       Put `type=subcircuit` / `format` / `template` in the **`G {}`** block and do
       **not** leave an empty `K {}` block after it — an empty `K {}` clears the type
       and the instance silently netlists to nothing. List the symbol's pins (the
       `B` lines) in the same order as the `ipin`/`opin`/`iopin` order in the DUT
       schematic.

2. **A Python notebook** (`ece334-labs/labN/labN.ipynb`)
   - Short prose cells interleaved with `ece334lib` calls. Load results with
     `sim.run("xschem/<name>.raw")`, measure with `measure.*`, plot with `plot.*`.
   - Keep the notebook **clean** (cleared outputs) in git — it's the student's start.

3. **The shared helper** (`ece334-labs/common/ece334lib/`)
   - `waves` (load `.raw`/`wrdata`), `measure` (metrics), `sim` (run/sweep), `plot`.
   - Add new metrics here, not in notebooks. Lab 4, for example, adds `setup_hold`
     and `butterfly` to `measure.py`. Write a unit test in
     `common/ece334lib/tests/` with a synthetic waveform of known answer.

4. **The lab page** (`ece334-docs/docs/labs/labN/index.md`)
   - States the naming contract, walks the build → button → notebook loop, and embeds
     the rendered notebook with `--8<-- "labs/labN/notebook/labN.md"`.

## Publishing the rendered notebook (Approach A)

The runnable notebook lives in `ece334-labs`; the docs embed a committed snapshot.

```bash
# 1. in the lab container, execute the notebook so it carries real outputs
jupyter nbconvert --to notebook --execute --inplace labN/labN.ipynb
# 2. in the docs repo, render the stored outputs to markdown + images
cd ece334-docs && make notebooks      # LABS_DIR defaults to ../ece334-labs
# 3. commit docs/labs/labN/notebook/ and verify
make site                              # mkdocs build --strict
```

If cross-repo rendering ever becomes a chore, fall back to **Approach C**: link to the
runnable notebook and commit a couple of static reference figures instead.

## Validating before you ship

- `cd ece334-labs/common && python3 -m pytest ece334lib` — helper unit tests pass.
- Netlist the harness headlessly: `xschem -n -s -q -x -o /tmp labN/xschem/<thing>_tb.sch`
  and confirm the DUT instance and `.subckt` appear.
- `cd ece334-docs && make site` — docs build clean.

!!! danger "Container prerequisite: SKY130 ngspice models"
    Transistor simulations need the PDK's compiled OSDI model libraries
    (`$PDK_ROOT/sky130A/libs.tech/ngspice/osdi/*.osdi`). If they're missing, ngspice
    reports *"could not find a valid modelname"* and **no** transistor circuit will
    simulate (model-free benches like the RC still work). Provision the models in the
    container image before relying on the inverter/transistor labs.
