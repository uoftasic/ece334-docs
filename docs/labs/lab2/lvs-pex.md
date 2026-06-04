# ECE334 Lab 2 (SKY130) — Layout → DRC → Extraction → LVS → PEX Simulation

This is the expanded Lab 2. The original MAX flow stopped at DRC + LVS ("extraction not available").
In the open flow, Magic does **DRC + extraction + parasitic extraction (PEX)** and Netgen does **LVS**, so
Lab 2 now closes the full loop: a DRC-clean layout that **LVS-matches** its schematic and is **re-simulated
with extracted parasitics**, then compared against the ideal schematic. That pre-vs-post-parasitic
comparison is exactly the skill the old handout *wanted* but the tool couldn't deliver.

**Cell under design:** 2-input NAND. **Process:** `sky130A`, L = 0.5 µm. **Sizing (SKY130):** two series
NMOS at Wn ≈ 2 µm each; two parallel PMOS at Wp ≈ 3 µm each (so worst-case drive ≈ the unit inverter).
Drop the MAX-isms: "L = 2 squares = 0.25 µm" and the fixed contact counts do not apply — SKY130 has its own
design rules and real dimensions.

---

## Stage 0 — project setup
Work under `/foss/designs/lab2_nand/`. Select the PDK and create a local `.magicrc` so Magic loads the
SKY130 tech and the device generators:
```bash
sak-pdk sky130A
cd /foss/designs/lab2_nand
# .magicrc (sources the PDK tech; usually provided by the PDK / IIC helper)
echo "source $PDK_ROOT/sky130A/libs.tech/magic/sky130A.magicrc" > .magicrc
```
Launch Magic with the SKY130 tech:
```bash
magic -d X11 -T sky130A nand2.mag &
```

---

## Stage 1 — draw the layout (GUI)
- Place two `sky130_fd_pr__nfet_01v8` and two `sky130_fd_pr__pfet_01v8` devices. The quickest route is
  Magic's **device generator** (`Devices` menu / `:magic::gencell`) so each transistor comes out as a legal
  parameterized cell — set W and L there.
- Wire with the SKY130 stack: `nwell`, `pwell` taps, `nsdm/psdm`, `poly`, `licon1`, `li1`, `mcon`, `met1`.
- Add **well/substrate taps** (n-well to Vdd, p-substrate to GND) — required for a clean cell and for LVS.
- Label terminals exactly: `A`, `B`, `Y` (out), `VPWR`/`VGND` (or `VDD`/`VSS` — but be consistent with the
  schematic). Use `Edit → Text` (port labels) and mark them as ports.

> Teaching note: SKY130 power-rail conventions in the std-cell world are `VPWR`/`VGND`. For a hand cell,
> any consistent names work as long as the schematic uses the *same* names — Netgen matches by them.

---

## Stage 2 — DRC (must be clean)
Interactive in Magic:
```
drc check
drc why            # box an error area first, then ask why
drc count          # total error count; target 0
```
Iterate until `drc count` is 0. (KLayout's SKY130 DRC deck is available as an independent cross-check if a
rule is confusing: `klayout -b -r $PDK_ROOT/sky130A/libs.tech/klayout/drc/sky130A_mr.drc ...`.)

---

## Stage 3 — extract the layout netlist (for LVS)
In Magic's console (or batch via `magic -dnull -noconsole`):
```tcl
extract all
ext2spice lvs                 ;# LVS-style: no parasitics, clean device netlist
ext2spice -o nand2.lvs.spice
```
This yields a transistor-level netlist of *what you actually drew*.

---

## Stage 4 — the matching schematic + its netlist
Draw the same NAND in **XSchem** (`nand2_sch.sch`) with identical device sizes and identical port names
(`A B Y VPWR VGND`). Export an LVS netlist:
```bash
xschem -n -q -o . nand2_sch.sch      # produces nand2_sch.spice
```
(Or keep a hand-written reference `.spice` — but a schematic is better pedagogy and feeds Stage 6.)

---

## Stage 5 — LVS with Netgen
```bash
netgen -batch lvs \
  "nand2.lvs.spice nand2" \
  "nand2_sch.spice nand2_sch" \
  $PDK_ROOT/sky130A/libs.tech/netgen/sky130A_setup.tcl \
  nand2.lvs.report
```
Open `nand2.lvs.report`. Target:
```
Circuits match uniquely.
```
Common mismatches and fixes: missing well/substrate taps (add taps), port-name mismatch (align names),
a device split into series/parallel fingers (set `nf`/device geometry to match, or let Netgen's series/
parallel reduction handle it), or a forgotten connection (check `drc why`-clean ≠ electrically connected).

---

## Stage 6 — parasitic extraction (PEX) + back-annotated simulation
This is the new capability versus MAX. Extract **with** parasitic caps (and optionally resistance):
```tcl
extract all
ext2spice cthresh 0          ;# keep all parasitic capacitances (0 = no threshold)
# optional resistance extraction:
# extresist
# ext2spice extresist on
# ext2spice rthresh 0
ext2spice -o nand2.pex.spice
```
`nand2.pex.spice` is the same circuit plus the layout's coupling/ground caps (and R if enabled).

**L4 simulation (matches the original stimulus, rescaled):** in a testbench, drive input `B = Vdd = 1.8 V`,
apply a pulse to `A` (height 1.8 V, tr = tf = 200 ps, delay 0, pulse-width 3 ns, period 6 ns), then add a
**0.1 pF** load on `Y`:
```spice
.lib $PDK_ROOT/sky130A/libs.tech/ngspice/sky130.lib.spice tt
.include nand2.pex.spice            ;# swap to nand2.lvs.spice for the "ideal" run
Vdd  VPWR 0 1.8
Vgnd VGND 0 0
VB   B 0 1.8
VA   A 0 PULSE(0 1.8 0 200p 200p 3n 6n)
Xdut A B Y VPWR VGND nand2
CL   Y 0 0.1p
.tran 1p 18n
.meas tran tpHL trig v(A) val=0.9 rise=1 targ v(Y) val=0.9 fall=1
.meas tran tpLH trig v(A) val=0.9 fall=1 targ v(Y) val=0.9 rise=1
.meas tran trise trig v(Y) val=0.18 rise=1 targ v(Y) val=1.62 rise=1
.meas tran tfall trig v(Y) val=1.62 fall=1 targ v(Y) val=0.18 fall=1
.end
```

---

## Deliverables (TA checklist)
- [ ] Magic layout plot of the 2-input NAND (SKY130 layers, taps, labelled ports).
- [ ] `drc count` = 0.
- [ ] Netgen report: **"Circuits match uniquely."**
- [ ] Pre-parasitic (`.lvs.spice`) input/output waveforms.
- [ ] Post-parasitic (`.pex.spice`) input/output waveforms.
- [ ] Same, with the **0.1 pF** load added.
- [ ] Measured **tr, tf, tpHL, tpLH** from the loaded post-PEX run, and a sentence on how parasitics shifted
      them versus the ideal schematic run (the core learning point).

## Optional stretch goals
- Inspect the GDS in **KLayout**; cross-probe schematic↔layout (replaces SUE "k" / MAX cross-probe).
- Turn on **resistance** extraction and quantify how much R (not just C) costs you on the `Y` net.
