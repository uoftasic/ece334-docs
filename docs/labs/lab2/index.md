# ECE334 Lab 2: NAND Layout, DRC, Extraction, LVS, and PEX

*Digital Electronics — SKY130 Open-Source Flow*

Full layout → simulation loop. **Cell:** 2-input NAND; **L = 0.5 µm**; NMOS series
Wn ≈ 2 µm each; PMOS parallel Wp ≈ 3 µm each.

See also the expanded guide: [Lab 2 in depth — Layout/LVS/PEX](lvs-pex.md).

> 📷 *Figure: Magic layout plot with labelled ports A, B, Y* — screenshot pending (`images/01-nand-layout.png`)

## Stage 0 — Project setup

!!! terminal "In the noVNC desktop terminal"
    ```bash
    . /foss/designs/common/.designinit
    cd /foss/designs/lab2_layout
    sak-pdk sky130A
    echo "source \$PDK_ROOT/sky130A/libs.tech/magic/sky130A.magicrc" > .magicrc
    magic -d X11 -T sky130A nand2.mag &
    ```

## Stage 1 — Draw layout (GUI)

!!! magic "In Magic"
    Use Magic device generators or paint SKY130 layers: `nwell`, `diff`, `poly`,
    `licon1`, `li1`, `mcon`, `met1`. Add **well/substrate taps**.
    Label ports: `A`, `B`, `Y`, `VPWR`, `VGND` (match schematic).

## Stage 2 — DRC

!!! magic "In Magic"
    ```bash
    drc check
    drc why
    drc count
    ```

    Target: **0 errors**.

> 📷 *Figure: DRC clean — `drc count = 0`* — screenshot pending (`images/02-drc-clean.png`)

## Stage 3 — Extract (LVS netlist)

!!! magic "In Magic"
    ```bash
    extract all
    ext2spice lvs
    ext2spice -o nand2.lvs.spice
    ```

## Stage 4 — XSchem schematic

!!! xschem "In XSchem"
    Draw `nand2_sch.sch` with matching sizes and port names. Netlist headlessly:

    ```bash
    xschem -n -q -o . nand2_sch.sch
    ```

## Stage 5 — LVS (Netgen)

!!! terminal "In the noVNC desktop terminal"
    ```bash
    ./scripts/run_lvs.sh
    ```

    Expect: **Circuits match uniquely.**

> 📷 *Figure: Netgen report showing match* — screenshot pending (`images/03-lvs-match.png`)

## Stage 6 — PEX + simulation

!!! magic "In Magic"
    ```bash
    extract all
    ext2spice cthresh 0
    ext2spice -o nand2.pex.spice
    ```

After Magic extraction produces `nand2.pex.spice`, run the testbench and plot waveforms.

### PEX testbench

```spice
* Lab 2 L4 -- NAND2 simulation (swap include for ideal vs PEX)
.lib $PDK_ROOT/sky130A/libs.tech/ngspice/sky130.lib.spice tt
.include nand2.pex.spice
* .include nand2.lvs.spice
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
.control
run
wrdata nand2_pex_wave.txt v(A) v(Y)
.endc
.end
```

!!! terminal "In the noVNC desktop terminal"
    ```bash
    cd /foss/designs/lab2_layout
    ngspice -b spice/nand2_pex_tb.spice
    ```

    Compare pre-PEX (ideal `.include nand2.lvs.spice`) vs post-PEX waveforms.

> 📷 *Figure: pre- vs post-PEX waveforms with 0.1 pF load* — screenshot pending (`images/04-pex-waveforms.png`)

## Deliverables

- [ ] Layout plot; DRC clean
- [ ] Netgen **match**
- [ ] Waveforms: pre- and post-PEX; with 0.1 pF load
- [ ] $t_r$, $t_f$, $t_{pHL}$, $t_{pLH}$ + brief parasitic discussion
