# ECE334 Lab 1: Basic SPICE Simulations

*Digital Electronics — SKY130 Open-Source Flow*

## Course conventions

--8<-- "includes/conventions.md"

Tools: **XSchem** + **ngspice**. Scriptable parts (RC, parameter extraction) run from
the terminal; schematic drawing uses the GUI.

> 📷 *Figure: Lab 1 overview — XSchem inverter schematic or gtkwave Vi/Vo* — screenshot pending (`images/01-lab1-overview.png`)

## Preparation

!!! terminal "In the noVNC desktop terminal"
    ```bash
    . /foss/designs/common/.designinit
    cd /foss/designs/lab1_spice
    ```

## P1 — RC circuit

Topology: pulse `Vi` → R1 (1 kΩ) → `Vo` with R2 (2 kΩ) and C1 (0.7 pF) to ground.
Pulse **1.8 V** high, 3 ns width, 6 ns period, $t_r = t_f = 0.2$ ns.

### Hand analysis

$$
\begin{aligned}
  V_{o,\mathrm{final}} &= 1.8 \times \frac{R_2}{R_1 + R_2} = 1.20\ \mathrm{V} \\
  \tau &= (R_1 \parallel R_2)\, C_1 = 0.467\ \mathrm{ns} \\
  \text{20–80\% rise/fall} &= \tau \ln(4) = 0.647\ \mathrm{ns}
\end{aligned}
$$

### Simulate from the terminal

The committed deck is `spice/rc.spice`:

```spice
* Lab 1 P1 - RC circuit (1.8 V)
Vi n1 0 PULSE(0 1.8 0 0.2n 0.2n 3n 6n)
R1 n1 n2 1k
R2 n2 0 2k
C1 n2 0 0.7p
.tran 1p 15n
.control
run
wrdata rc.txt v(n1) v(n2)
.endc
.end
```

!!! terminal "In the noVNC desktop terminal"
    ```bash
    cd spice
    ngspice -b rc.spice
    ```

    The output file `rc.txt` contains columns: time, `v(n1)`, `v(n2)`.
    Inspect the final value of `Vo` (≈ 1.20 V) and measure 20–80% rise/fall
    (≈ 0.647 ns; expect slightly longer due to 0.2 ns input edges).

> 📷 *Figure: RC waveforms — Vi and Vo vs time, final Vo ≈ 1.2 V* — screenshot pending (`images/02-rc-waveforms.png`)

## Extract $\mu C_\mathrm{ox}$ and $V_t$ (diode-connected)

A diode-connected device (gate tied to drain) is always in saturation when on, so
$I_D = \tfrac{1}{2} K_P (W/L)(V_{GS} - V_t)^2$, which makes $\sqrt{I_D}$ **linear** in
$V_{GS}$:

- slope $m = \sqrt{\tfrac{1}{2} K_P (W/L)} \Rightarrow K_P = 2m^2/(W/L)$
- x-intercept of the line $= V_t$

We use a long/wide device (W = 10 µm, L = 2 µm) so the square law is clean.

### NMOS extraction deck

```spice
* NMOS diode-connected extraction
.lib $PDK_ROOT/sky130A/libs.tech/ngspice/sky130.lib.spice tt
Vg dg 0 dc 0
Xn dg dg 0 0 sky130_fd_pr__nfet_01v8 W=10u L=2u
.dc Vg 0 1.8 0.01
.control
run
let id = -i(Vg)
wrdata nmos_iv.txt id
.endc
.end
```

!!! terminal "In the noVNC desktop terminal"
    ```bash
    cd spice
    ngspice -b nmos_diode.spice
    ```

    Repeat with `spice/pmos_diode.spice` (source/bulk at 1.8 V, sweep gate down) to get
    $|V_{tp}|$ and $K_{Pp}$.

### Fit $\sqrt{I_D}$ vs $V_{GS}$

After running the deck, fit the strong-inversion region ($V_{GS} \in [1.0, 1.7]$ V) in Python
or by hand. Example Python workflow:

```python
import numpy as np
d = np.loadtxt('nmos_iv.txt')
vgs, idd = d[:, 0], d[:, 1]
sid = np.sqrt(np.clip(idd, 0, None))
sel = (vgs > 1.0) & (vgs < 1.7)
m, b = np.polyfit(vgs[sel], sid[sel], 1)
Vt = -b / m
WL = 10 / 2
KP = 2 * m**2 / WL
print(f'Vtn = {Vt:.3f} V')
print(f'KPn = {KP*1e6:.1f} uA/V^2')
```

**Typical result (yours will vary):** $V_{tn} \approx 0.45$ V, $K_{Pn} \approx 70\ \mu A/V^2$.
Record all four numbers for P3 and Lab 3.

> 📷 *Figure: $\sqrt{I_D}$ vs $V_{GS}$ with saturation fit line* — screenshot pending (`images/05-nmos-extraction.png`)

## P2 / L2 — CMOS inverter

Devices: `sky130_fd_pr__nfet_01v8` W=1u L=0.5u; `pfet_01v8` W=3u L=0.5u; $C_L = 0.2$ pF.

!!! xschem "In XSchem"
    1. Draw `inverter_tb.sch`: NMOS and PMOS from SKY130 library, input `Vi`,
       output `Vo`, supply 1.8 V, load 0.2 pF.
    2. **Transfer curve:** add `.dc Vi 0 1.8 0.005` testbench.
    3. **Transient:** 1.8 V input pulse; `.tran 1p 15n`.
    4. Netlist and simulate: `n` then `s`, or headlessly:

       ```bash
       xschem -n -q -o . inverter_tb.sch
       ngspice -b inverter_tb.spice
       ```

Reference deck: `spice/inverter_tb.spice`.

> 📷 *Figure: inverter VTC — Vo vs Vi DC sweep* — screenshot pending (`images/03-inverter-vtc.png`)

> 📷 *Figure: inverter transient — Vi and Vo vs time* — screenshot pending (`images/04-inverter-tran.png`)

## P3 — Equivalent resistance timing

$$
\begin{aligned}
  R_{\mathrm{eq},n} &= \frac{1.8}{K_{Pn} \cdot (W/L)_n \cdot (1.8 - V_{tn})} \\
  R_{\mathrm{eq},p} &= \frac{1.8}{K_{Pp} \cdot (W/L)_p \cdot (1.8 - V_{tp})}
\end{aligned}
$$

Predict 10–90% rise/fall with $\approx 2.2 \cdot R_{\mathrm{eq}} \cdot C_L$; compare to the
L2 transient. Discuss hand vs simulation gap (short-channel effects).

## L3 — Pulse generator

Transistor-level: unit inverters + 2-input NAND (series NMOS W≈2u each, parallel PMOS
W≈3u @ L=0.5u). Measure **low-going** pulse width at 50% with:

```spice
.meas tran tpw trig v(out) val=0.9 fall=1 targ v(out) val=0.9 rise=1
```

> 📷 *Figure: pulse generator output waveform* — screenshot pending (`images/06-pulsegen.png`)

## Deliverables

- [ ] RC: Vi/Vo plot; measured vs 0.647 ns rise/fall
- [ ] Extraction: NMOS + PMOS fits; four parameters ($V_{tn}$, $K_{Pn}$, $|V_{tp}|$, $K_{Pp}$)
- [ ] Inverter: VTC + transient; $V_M$ / noise margins
- [ ] P3: $R_{\mathrm{eq}}$ estimate vs simulation
- [ ] L3: pulsegen schematic + pulse-width measurement
