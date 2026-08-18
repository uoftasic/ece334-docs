# Lab 4 — Flip-flop characterization and the 6T SRAM cell

*ECE334 — Digital Electronics — SKY130 open-source flow*

## Objective

Characterise the flip-flop you built in Lab 3, use its numbers to predict the
maximum clock frequency of a real path, and then design a 6T SRAM cell against
two competing stability constraints — and break each one deliberately to see
what failure looks like.

## References

Textbook section 12.2.1, *Memory cell read/write operation*.

## Course conventions

--8<-- "includes/conventions.md"

| Device | Width |
|---|---|
| Cell load PMOS, $P_1$ $P_2$ | 0.5 |
| Cell access NMOS, $N_2$ $N_4$ | 0.7 |
| Cell driver NMOS, $N_1$ $N_3$ | 2.0 |
| Periphery: precharge and write drivers | 8 |

Bit-line capacitance is 1 pF on each side. Ignore the body effect in hand
analysis.

---

## Preparation

### P1 — Size the SRAM cell

The 6T cell is two cross-coupled inverters ($P_1$/$N_1$ and $P_2$/$N_3$) plus
two access transistors ($N_2$, $N_4$) joining the internal nodes to the bit
lines. It has to satisfy two constraints that pull in opposite directions.

**Read stability.** During a read, both bit lines are precharged high and the
word line turns on both access devices. The access device connected to the low
internal node forms a divider with that node's driver, and the low node rises.
It must stay below 0.3 V or the cell can flip while merely being read:

$$W_{N1} \geq 2.7\,W_{N2}$$

**Write stability.** During a write, the driver holds one bit line at 0 and the
access device must overpower the load PMOS holding that internal node high:

$$W_{N2} \geq 1.2\,W_{P1}$$

Read time is not critical, so make the smallest devices minimum sized to keep
the cell area down. Determine all six widths. Show that your choice satisfies
both inequalities.

The reference build uses $W_{P} = 0.5$, $W_{access} = 0.7$, $W_{driver} = 2.0$:

$$2.0 \geq 2.7 \times 0.7 = 1.89 \quad\checkmark
\qquad
0.7 \geq 1.2 \times 0.5 = 0.60 \quad\checkmark$$

### P2 — Which device would you change?

1. If the **read** stability condition were violated, which transistor(s) would
   you resize, and in which direction?
2. If the **write** stability condition were violated, which transistor(s)?

Answer before L6 and L7, where you break each one on purpose.

### P3 — Stick diagram

Draw a coloured stick diagram of the 6T cell. A neat sketch is enough; exact
design-rule dimensions are not required.

### P4 — Set up the simulation

Build the circuit with its precharge devices and write drivers, driven by the
waveforms in L5. Unit inverters are fine for the precharge and data paths.

---

## Lab Work

### L1 — Setup time

Setup time is the smallest gap between the data edge and the clock edge for
which the flip-flop still captures. Measure it by sweeping that gap:

```bash
. /foss/designs/common/.designinit
cd /foss/designs/lab4_sram
for d in 2000 1000 500 300 240 220 200; do
  sed "s/^.param DSKEW=.*/.param DSKEW=${d}p/" spice/dff_char.spice > /tmp/s.spice
  printf "%6s ps  " "$d"
  ngspice -b /tmp/s.spice 2>&1 | grep '^qfinal'
done
```

![Setup time sweep](images/01-setup-time.png)
*Capture succeeds down to 240 ps and fails at 220 ps.*

| Data edge before clock | Q after the edge | Captured |
|---|---|---|
| 300 ps | 1.800 V | yes |
| 240 ps | 1.800 V | yes |
| 220 ps | 0.000 V | **no** |

$t_{setup} \approx 230$ ps for the reference flip-flop. Report the two values
that bracket your own, not a single number you cannot defend.

### L2 — Clock-to-Q delay

On a cycle that does capture, measure from the clock's 50 % point to Q's:

```
meas tran tpcq TRIG v(cl) VAL=0.9 RISE=1 TARG v(q) VAL=0.9 RISE=1
```

Reference: $t_{PCQ} = 1.134$ ns.

### L3 — Two flip-flops and four inverters

Build the path: `DFF1 → inv → inv → inv → inv → DFF2`, both flip-flops on the
same clock, inverters sized as the Lab 3 unit inverter.

```bash
ngspice -b spice/dff_chain.spice
```

The reference build measures $t_{logic}$ = 621 ps rising, 641 ps falling. The
maximum clock frequency follows from the max-delay constraint:

$$f_{max} = \frac{1}{t_{PCQ} + t_{logic} + t_{setup}}
= \frac{1}{1.134 + 0.621 + 0.230\ \mathrm{ns}} = 504\ \mathrm{MHz}$$

Then find it experimentally: reduce `TCLK` until DFF2 stops tracking DFF1, and
compare against your calculation. Expect the simulated limit to be close to but
not exactly the calculated one, and say which of the three terms you trust
least.

### L4 — Build the SRAM cell

Build the cell and its periphery with your P1 sizes.

!!! warning "The cell has two stable states, so tell the simulator which one"
    Without an initial condition the DC solution is arbitrary, and a write has
    nothing to overwrite. Add
    ```
    ^.IC V(A) = 0V
    ```
    to the schematic (press `t`, click, type it, press Enter), or `.ic v(a)=0`
    to the deck. Extend the simulation to 50 ns.

### L5 — Write, then read

Drive it with the handout's waveforms: precharge high 1–9 ns, word and write
high 10–19 ns to write a 1, precharge again 20–29 ns, then word high from 29 ns
for the read. Hold `data` at $V_{DD}$.

```bash
ngspice -b spice/sram6t.spice
```

![Working SRAM cell](images/02-sram-nominal.png)
*Write: `bit_b` is pulled to 0 and A flips to 1.8 V. Read: `bit_b` discharges
through the cell while A_b rises only to 144 mV.*

Report:

- **Read time** — from the word line rising to 200 mV of separation between the
  bit lines. Reference: **1.45 ns**.
- **Read disturb** — how far the low internal node rises during the read.
  Reference: **144 mV**, against the 300 mV limit.

### L6 — Break read stability

Shrink the driver NMOS from 2.0 to 0.6, so $W_{N1} = 0.6$ is well below
$2.7 W_{N2} = 1.89$.

```bash
ngspice -b spice/sram6t_read_fail.spice
```

![Read stability violated](images/03-sram-read-fail.png)
*The low internal node is dragged to 351 mV during the read, past the 300 mV
limit. The access device now wins the divider against the weakened driver.*

Plot the bit lines and both internal nodes, and describe the change relative to
L5. Compare against your P2 answer.

### L7 — Break write stability

Grow the load PMOS to 6.0 and shrink the access NMOS to 0.36.

```bash
ngspice -b spice/sram6t_write_fail.spice
```

![Write stability violated](images/04-sram-write-fail.png)
*The write never takes: A stays at 0.075 V where the working cell reaches
1.8 V.*

!!! note "One violated ratio is not always enough"
    Shrinking the access device alone, or growing the load alone, still writes
    successfully even though the inequality is violated. A PMOS is roughly three
    times weaker than an NMOS of the same width, so the stated ratio carries
    real margin. Both devices have to move before the write actually fails.
    That margin is worth a sentence in your report.

---

## Expected results

- [ ] **L1** — setup time, with the bracketing values that establish it
- [ ] **L2** — $t_{PCQ}$
- [ ] **L3** — $t_{logic}$; calculated $f_{max}$; the simulated frequency at
      which capture fails; a comparison
- [ ] **L5** — working cell: bit-line and internal-node waveforms, read time,
      read disturb
- [ ] **L6** — read stability violated: waveforms, and what changed
- [ ] **L7** — write stability violated: waveforms, and what changed

## Extra notes

- Setup time is measured from the 50 % point of the data transition to the 50 %
  point of the clock transition.
- Sweep the clock delay finely near the boundary. The transition from capture to
  failure is abrupt, and a coarse sweep will step over it.
- The read is non-destructive only if the read-stability condition holds. That
  is the whole point of L6.
- Read time is measured to 200 mV of bit-line separation, not to a full swing —
  a sense amplifier resolves the difference long before the bit line discharges.

## FAQ

**The simulation will not converge, or A and A_b sit at the same voltage.**
No initial condition. Add `^.IC V(A) = 0V`.

**Q never changes in the characterization deck.**
Check that SETQ and RESETQ are tied low. Either one stuck high overrides the
data path entirely.

**My setup time is negative, or absurdly large.**
The measurement is picking the wrong clock edge. The deck places exactly one
data transition before exactly one rising edge; if you change the periods, check
which edge `.meas` is triggering on.

**The write-fail case still writes.**
You have violated the ratio but not by enough. See the note in L7 — move both
the load and the access device.

**Read time comes out negative.**
`.meas` found the bit-line separation from the *write* phase, where the driver
pulls a bit line down for an unrelated reason. Match the second rising crossing,
not the first.
