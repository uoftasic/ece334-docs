# ECE334 Lab 4: DFF Characterization and 6T SRAM

*Digital Electronics — SKY130 Open-Source Flow*

**1.8 V** supply; re-derive sizing with **your** Lab 1 $K_P$/$V_t$;
illustrative CR ≈ 2, PR ≈ 1.2 @ L=0.5 µm.

> 📷 *Figure: SRAM read — bit / bit_b during read cycle* — screenshot pending (`images/01-sram-read.png`)

## Preparation

!!! terminal "In the noVNC desktop terminal"
    ```bash
    . /foss/designs/common/.designinit
    cd /foss/designs/lab4_sram
    ```

## L1 / L2 — DFF setup time and $t_{\mathrm{PCQ}}$

After netlisting your DFF into `dff.spice`, sweep the clock `delay` parameter until
Q stops following D. Measure $t_{\mathrm{PCQ}}$ with `.meas`.

### Characterization testbench

Template: `spice/dff_char_tb.spice`

```spice
* Lab 4 L1/L2 -- DFF characterization template
* Include your Lab 3 DFF subckt after xschem netlist:
* .include dff.spice
.lib $PDK_ROOT/sky130A/libs.tech/ngspice/sky130.lib.spice tt
Vdd vdd 0 1.8
Vss vss 0 0
* Sweep delay on clock PULSE -- adjust 4th parameter (delay)
Vclk clk 0 PULSE(0 1.8 0 100p 100p 5n 10n)
Vd data 0 PULSE(0 1.8 1n 100p 100p 3n 20n)
.tran 10p 80n
.control
run
wrdata dff_char.txt v(clk) v(data) v(q)
.meas tran tpcq trig v(clk) val=0.9 rise=1 targ v(q) val=0.9 rise=1
print tpcq
.endc
.end
```

!!! terminal "In the noVNC desktop terminal"
    Sweep clock delay values (e.g. 0, 200, 400, 600, 800, 1000 ps). For each delay, run:

    ```bash
    ngspice -b spice/dff_char_tb.spice
    ```

    Record whether Q follows D. The setup time is the smallest delay at which capture fails.

> 📷 *Figure: Q vs clock delay showing failure boundary* — screenshot pending (`images/02-setup-time.png`)

## L3 — Two DFFs + 4 inverters

$$
f_{\max} = \frac{1}{t_{\mathrm{PCQ}} + t_{\mathrm{logic}} + t_{\mathrm{setup}}}
$$

Raise clock frequency in simulation until capture fails; compare calculated vs simulated $f_{\max}$.

## P1 / P4 + L4–L7 — 6T SRAM

**Illustrative sizing (L=0.5u):** load PMOS 0.5 µm; access N 0.7 µm; driver N 1.5 µm;
periphery 8 µm; $C_{\mathrm{bit}} = 1$ pF.

Stimulus rescaled to 1.8 V per legacy Fig. 3. Convergence: `.ic v(A)=0` in testbench.

**Read time:** `.meas` from WORD edge to $|V(\mathrm{bit}) - V(\mathrm{bit\_b})| = 200$ mV.

**L6/L7:** violate read (shrink driver) or write (shrink access) — plot bit/bit_b and A/A_b.

| Case | Deck |
|------|------|
| Nominal | `spice/sram6t_nominal.spice` |
| Read fail | `spice/sram6t_read_fail.spice` |
| Write fail | `spice/sram6t_write_fail.spice` |

!!! terminal "In the noVNC desktop terminal"
    ```bash
    ngspice -b spice/sram6t_nominal.spice
    ngspice -b spice/sram6t_read_fail.spice
    ngspice -b spice/sram6t_write_fail.spice
    ```

> 📷 *Figure: violated read or write waveforms* — screenshot pending (`images/03-sram-violation.png`)

## P3 — Stick diagram

Hand sketch of the 6T cell (optional: layout in Magic as stretch goal).

## Deliverables

- [ ] Setup time + $t_{\mathrm{PCQ}}$
- [ ] Max clock frequency (calc vs sim)
- [ ] SRAM read time; working cell waveforms
- [ ] Both violated designs documented
