# ECE334 Lab 1: Basic SPICE Simulations

*Digital Electronics — SKY130 Open-Source Flow*

## Course conventions

--8<-- "includes/conventions.md"

In this lab you learn the **loop you will use all term**: build a circuit in XSchem,
press a button to simulate it, and analyse the result in Python. Tools: **XSchem**
(schematics + launch buttons), **ngspice** (simulator), and a tiny course Python
helper, **`ece334lib`**, that you drive from a Jupyter notebook.

## Your interactive workbench

Each lab folder ships three kinds of files that work together:

| File | What it is |
|------|------------|
| `xschem/*_tb.sch` | **Testbenches** — ready-made schematics with stimulus, load, and **launcher buttons**. You drop your own circuit into the DUT. |
| `lab1.ipynb` | A **Jupyter notebook** that loads the simulation results and measures them with `ece334lib`. |
| `spice/*.spice` | Plain reference decks, if you prefer the command line. |

### The naming contract (important)

The testbench and the notebook find your signals **by net name**. Whenever you build a
circuit, use these names and the analysis "just works":

| Net | Meaning |
|-----|---------|
| `in` | stimulus input |
| `out` | the output you measure |
| `vdd` | 1.8 V supply |
| `vss` | ground (0 V) |

A testbench's **DUT** (device-under-test) is an empty box symbol with exactly these
four pins. You open it and build your circuit inside — the pins are the contract.

### The launcher buttons

Inside every `*_tb.sch` you'll see clickable buttons (the arrow shapes):

- **Netlist & Simulate** — saves, netlists, and runs ngspice. Writes a named `.raw`
  results file (e.g. `rc_tb.raw`).
- **Annotate OP** — overlays DC operating-point node voltages on the schematic.
- **Run analysis notebook** — executes `lab1.ipynb` for you.

### Launching the notebook

!!! terminal "In the noVNC desktop terminal"
    ```bash
    . /foss/designs/common/.designinit
    cd /foss/designs/lab1_spice
    jlab          # starts JupyterLab; open the printed URL, then open lab1.ipynb
    ```

The `jlab` alias and `import ece334lib` are set up by `.designinit` — source it once
per terminal.

??? note "Why script the analysis at all?"
    A SPICE run doesn't hand you "the rise time" — it hands you a **table of numbers**.
    Turning that into a meaningful answer by hand is slow and impossible to reproduce. A
    couple of lines of Python do it in a way that is fast, exact, and **re-runnable**:
    change a transistor width, re-simulate, re-run the cell, and every number updates.
    That is exactly how working chip designers post-process simulations.

---

## P1 — RC step response

Open `xschem/rc_tb.sch`. A 1.8 V step drives `R1` (1 kΩ) into `C1` (1 pF) at node
`out`. The output charges with time constant $\tau = RC$.

### Hand analysis

$$
\begin{aligned}
  \tau &= R\,C = (1\ \mathrm{k}\Omega)(1\ \mathrm{pF}) = 1\ \mathrm{ns} \\
  t_{r}\,(10\text{–}90\%) &= \tau \ln 9 \approx 2.20\ \mathrm{ns}
\end{aligned}
$$

### Simulate & analyse

1. In `rc_tb.sch`, press **Netlist & Simulate**. This writes `rc_tb.raw`.
2. In `lab1.ipynb`, run **§1 RC step response**. It loads the result and measures:

   ```python
   from ece334lib import sim, measure, plot
   rc = sim.run("xschem/rc_tb.raw")
   t_rise, _ = measure.edges_10_90(rc, "out", vdd=1.8)
   plot.transient(rc, ["in", "out"])
   ```

   You should see $\tau \approx 1$ ns and $t_r \approx 2.20$ ns — matching the hand
   analysis exactly.

!!! tip "Make it yours"
    Change `R1` or `C1` in the schematic, re-simulate, and re-run the cell. Confirm
    that $\tau$ tracks $R\cdot C$.

---

## Extract $K_P$ and $V_t$ (diode-connected device)

Before the inverter, extract the device parameters you'll need for its hand estimate.
A diode-connected device (gate tied to drain) is always in saturation when on, so
$I_D = \tfrac12 K_P (W/L)(V_{GS}-V_t)^2$, which makes $\sqrt{I_D}$ **linear** in $V_{GS}$:

- slope $m = \sqrt{\tfrac12 K_P (W/L)} \Rightarrow K_P = 2m^2/(W/L)$
- x-intercept of the fitted line $= V_t$

### Simulate & analyse

1. Open `xschem/diode_tb.sch`. Build a diode-connected NMOS in the DUT (gate+drain → `g`,
   source+body → `s`; size $W=10$, $L=2$ — **unitless**). Press **Netlist & Simulate**;
   it writes `diode_nmos.raw`.
2. Run **§2** of `lab1.ipynb`. `ece334lib` does the fit for you:

   ```python
   diode = sim.run("xschem/diode_nmos.raw")
   res = measure.extract_square_law(diode["g"], diode["id"], wl=10/2, vmin=1.0, vmax=1.7)
   print(res["Vt"], res["KP"])
   ```

### What the helper is doing (your scripting on-ramp)

`extract_square_law` is just five lines of NumPy — read them once and the analysis
stops being mysterious. Each line uses one core idea:

```python
import numpy as np
d = np.loadtxt("nmos_iv.txt")           # (1) load a table ngspice wrote (terminal route)
vgs, idd = d[:, 0], d[:, 1]             # (2) pick the VGS and ID columns with [:, k]
sid = np.sqrt(np.clip(idd, 0, None))    # (3) math applies to the whole column at once
sel = (vgs > 1.0) & (vgs < 1.7)         # (4) a boolean mask keeps strong-inversion rows
m, b = np.polyfit(vgs[sel], sid[sel], 1)  # (5) best-fit line -> slope m, intercept b
Vt = -b / m                             # x-intercept is Vt
KP = 2 * m**2 / (10 / 2)                # slope -> KP  (extraction device W/L = 10/2)
print(f"Vtn = {Vt:.3f} V    KPn = {KP*1e6:.1f} uA/V^2")
```

!!! tip "Prefer the terminal?"
    The committed deck `spice/nmos_diode.spice` does the same sweep:
    `ngspice -b nmos_diode.spice` writes `nmos_iv.txt`, which the snippet above loads.

Repeat with `pmos_diode.spice` for $|V_{tp}|$ and $K_{Pp}$. **Record all four numbers** —
you'll plug them into the inverter timing estimate below. *(Typical on SKY130:
$V_{tn}\approx0.46$ V, $K_{Pn}\approx170\ \mu A/V^2$; yours will vary with the fit window.)*

---

## P2 — CMOS inverter

Now build a real circuit into the testbench DUT.

!!! xschem "In XSchem"
    1. Open `xschem/inv_tb.sch`. Note the stimulus (`Vin` pulse on `in`), the load
       (`Cload` on `out`), the supply (`Vdd`), and the **DUT** box.
    2. **Double-click the DUT** to open `dut_inv.sch`. Build a CMOS inverter inside it:
        - PMOS `pfet_01v8`: source → `vdd`, drain → `out`, gate → `in`, body → `vdd`
        - NMOS `nfet_01v8`: source → `vss`, drain → `out`, gate → `in`, body → `vss`
        - Sizes: $W_n = 1$, $W_p = 3$, $L = 0.5$ — see the unit warning below.
       Keep the four pin names (`in`, `out`, `vdd`, `vss`) unchanged.

    !!! warning "Enter W and L as unitless microns — no `u`"
        The SKY130 device models are **binned on plain micron numbers**. Type
        `W=1` and `L=0.5`, *not* `W=1u`/`L=0.5u`. A value with a `u` suffix
        (i.e. metres) falls outside every bin and ngspice fails with
        *"could not find a valid modelname"*. This is the single most common
        first-simulation error — when you see it, check your `u`s.
    3. Back in `inv_tb.sch`, press **Netlist & Simulate**. It writes both
       `inv_tb_vtc.raw` (DC sweep) and `inv_tb_tran.raw` (transient).

### Transfer curve & noise margins

Run **§2** of `lab1.ipynb`:

```python
vtc = sim.run("xschem/inv_tb_vtc.raw")
nm  = measure.noise_margins(vtc, "in", "out")   # VM, VIL, VIH, VOL, VOH, NMH, NML
plot.vtc(vtc, "in", "out")
```

Report the switching threshold $V_M$ and the noise margins $NM_H$, $NM_L$.

### Transient timing vs hand estimate

Run **§3**. It measures propagation delay and edge rates, and compares them with the
equivalent-resistance estimate built from **your extracted** $K_P$, $V_t$:

$$
R_{\mathrm{eq}} = \frac{V_{DD}}{K_P (W/L)(V_{DD}-V_t)}, \qquad
t_{r,f} \approx 2.2\, R_{\mathrm{eq}}\, C_L
$$

Edit the `KPn, KPp, Vtn, Vtp` values in the cell to your numbers, then compare the
simulated and hand-estimated $t_r$, $t_f$. Discuss the gap (short-channel effects).

---

## The notebook, rendered

This is the executed `lab1.ipynb` for reference — your own run replaces these numbers
with your circuit's results.

--8<-- "labs/lab1/notebook/lab1.md"

---

## Deliverables

- [ ] **RC:** $V_{in}/V_{out}$ plot; measured $\tau$ and $t_r$ vs hand analysis
- [ ] **Extraction:** NMOS + PMOS fits; four parameters ($V_{tn}$, $K_{Pn}$, $|V_{tp}|$, $K_{Pp}$)
- [ ] **Inverter VTC:** $V_M$ and noise margins $NM_H$, $NM_L$
- [ ] **Inverter transient:** simulated vs hand-estimated $t_r$, $t_f$, $t_{pd}$
