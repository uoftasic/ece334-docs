# ECE334 Lab 3: Digital Circuit Simulations

*Digital Electronics — SKY130 Open-Source Flow*

**1.8 V** supply; unit inverter **Wn=1u Wp=3u L=0.5u**; use your Lab 1 extracted
$K_P$ and $V_t$ values.

> 📷 *Figure: four-panel DFF waveforms — CL, SETQ, DATA, Q* — screenshot pending (`images/01-dff-panels.png`)

## Preparation

!!! terminal "In the noVNC desktop terminal"
    ```bash
    . /foss/designs/common/.designinit
    cd /foss/designs/lab3_digital
    ```

## P1 / L1 — Unit inverter ($C_L = 0.3$ pF)

### Hand estimate (equivalent resistance model)

Using **your** Lab 1 extracted parameters, compute:

$$
\begin{aligned}
  R_{\mathrm{eq},n} &= \frac{V_{DD}}{K_{Pn} \cdot (W/L)_n \cdot (V_{DD} - V_{tn})} \\
  R_{\mathrm{eq},p} &= \frac{V_{DD}}{K_{Pp} \cdot (W/L)_p \cdot (V_{DD} - V_{tp})} \\
  t_{\mathrm{fall}} &\approx 2.2 \cdot R_{\mathrm{eq},n} \cdot C_L \\
  t_{\mathrm{rise}} &\approx 2.2 \cdot R_{\mathrm{eq},p} \cdot C_L
\end{aligned}
$$

With $(W/L)_n = 2$, $(W/L)_p = 6$, $C_L = 0.3$ pF, and example values
$V_{tn}=0.45$ V, $V_{tp}=0.50$ V, $K_{Pn}=70\ \mu A/V^2$, $K_{Pp}=23\ \mu A/V^2$:

```python
VDD = 1.8
Vtn, Vtp = 0.45, 0.50   # replace with your extraction
KPn, KPp = 70e-6, 23e-6
WLn, WLp = 2, 6
CL = 0.3e-12
Req_n = VDD / (KPn * WLn * (VDD - Vtn))
Req_p = VDD / (KPp * WLp * (VDD - Vtp))
t_fall = 2.2 * Req_n * CL * 1e9
t_rise = 2.2 * Req_p * CL * 1e9
print(f'Req_n={Req_n/1e3:.1f} kOhm  t_fall~{t_fall:.2f} ns')
print(f'Req_p={Req_p/1e3:.1f} kOhm  t_rise~{t_rise:.2f} ns')
```

### Simulate the unit inverter

Reference deck: `spice/unit_inv_tb.spice`

```spice
* Lab 3 P1 -- unit inverter, CL = 0.3 pF
.lib $PDK_ROOT/sky130A/libs.tech/ngspice/sky130.lib.spice tt
Vdd vdd 0 1.8
Vgnd vss 0 0
Vi vi 0 PULSE(0 1.8 0 0.2n 0.2n 3n 6n)
Xn vo vi vss vss sky130_fd_pr__nfet_01v8 W=1u L=0.5u
Xp vo vi vdd vdd sky130_fd_pr__pfet_01v8 W=3u L=0.5u
Cload vo vss 0.3p
.tran 1p 20n
.control
run
wrdata unit_inv.txt v(vi) v(vo)
.endc
.end
```

!!! terminal "In the noVNC desktop terminal"
    ```bash
    cd spice
    ngspice -b unit_inv_tb.spice
    ```

    Compare analytic $t_{\mathrm{rise}}$, $t_{\mathrm{fall}}$ to the simulated 10–90% edges.

> 📷 *Figure: unit inverter transient — Vo vs time* — screenshot pending (`images/02-unit-inv.png`)

## P2 / L2 — Complex gate $Y = \neg(A + B \cdot C)$

AOI21 structure. Size for **1.5 pF** load (×5 scale from 0.3 pF unit):

- $N_A = 5$ µm, $N_B = N_C = 10$ µm, $P_A = P_B = P_C = 30$ µm @ L=0.5 µm

Worst/best case input patterns per handout. Compare analytic vs simulated $t_r$/$t_f$.

!!! xschem "In XSchem"
    Draw the AOI21 gate in XSchem, netlist, and simulate with `.tran`.

> 📷 *Figure: AOI21 schematic in XSchem* — screenshot pending (`images/03-aoi21-sch.png`)

## P3 / L3 — Transmission-gate D flip-flop

Rebuild the DFF in XSchem. Switches/clock inv: **Wn=3u, Wp=9u**. NOR PMOS ≈ 2× clock-inv
PMOS width.

!!! xschem "In XSchem"
    Use `.tran 10p 250n` with PULSE timings for CL, SETQ, RESETQ, DATA unchanged from the
    legacy handout. Produce four plots: CL / $\overline{\text{CL}}$; SETQ / RESETQ; DATA;
    Q / $\overline{Q}$.

## Deliverables

- [ ] P1: analytic vs sim rise/fall table
- [ ] P2: AOI21 schematic; worst-case $t_r$/$t_f$ vs hand estimate
- [ ] L3: DFF functional waveforms (4 panels)
