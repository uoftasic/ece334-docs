# ECE334 Lab Overhaul — Part 1: Infrastructure, Lab 0, Lab 1

**Goal:** Ship a working, screenshot-rich Lab 0 and Lab 1 on SKY130 — with the XSchem configuration actually loading, every schematic netlisting, every measurement verified against hand analysis, and a report notebook per lab.

**Architecture:** Two repos joined by three contracts (net names, `.raw` filenames, section numbers). `ece334-docs` holds the manual and figures; `ece334-labs` holds design files and notebooks. Figures are captured from the live tools on the container's X display, never mocked.

**Tech Stack:** XSchem 3.4.8, ngspice, Magic 8.3, SKY130A PDK, Python 3.12 (numpy/pandas/matplotlib), MkDocs Material, Docker (`hpretl/iic-osic-tools:2026.04`).

**Spec:** `ece334-docs/specs/2026-08-18-lab-overhaul-design.md`

**Parts 2 and 3** cover Lab 2 (layout/DRC/LVS/PEX) and Labs 3–4 (AOI21, DFF, SRAM). This part establishes the patterns they reuse.

## Global Constraints

- PDK `sky130A`; devices `sky130_fd_pr__nfet_01v8` / `sky130_fd_pr__pfet_01v8`.
- Supply **1.8 V**. Teaching channel length **L = 0.5 µm**.
- Transistor `W`/`L` are entered as **unitless microns** (`W=1`, `L=0.5`). A `u` suffix lands outside every model bin and ngspice fails with *"could not find a valid modelname"*.
- Net names: `in`, `out`, `vdd`, `vss`. Lab-specific additions must be documented on the lab page.
- Container path for the repo is `/foss/designs`. Always `. /foss/designs/common/.designinit` first.
- Notebooks are committed with **outputs cleared**.
- Reference solutions live in `ece334-labs/instructors/labN/` and are excluded from the student release.
- Prose standard: imperative and unhedged; no reader encouragement; no editorialising; admonitions only for hazards that cost real time.
- Figures: `ece334-docs/docs/labs/labN/images/NN-slug.png`, two-digit ordinal, kebab-case slug.

---

## File Structure

**`ece334-labs` (branch `feat/lab-overhaul`)**

| Path | Responsibility |
|---|---|
| `common/xschemrc` | Layers course library paths over the PDK's xschemrc. **Already fixed.** |
| `common/.designinit` | Environment + installs `~/.xschem/xschemrc` shim. **Already fixed.** |
| `common/ece334lib/measure.py` | Add `pulse_width`, `tau_from_step`. |
| `common/ece334lib/tests/test_measure.py` | Unit tests for the new metrics on synthetic waves. |
| `scripts/capture.sh` | Screenshot helper: launch a tool, size the window, grab a PNG. |
| `scripts/verify_lab.sh` | Netlist + simulate every schematic/deck in a lab; non-zero exit on any failure. |
| `lab0_setup/README.md` | Points at the manual; lists what the student creates. |
| `lab1_spice/xschem/` | `rc_tb.sch`, `dut_diode.{sch,sym}`, `diode_tb.sch`, `dut_inv.{sch,sym}`, `inv_tb.sch`, `dut_pulsegen.{sch,sym}`, `pulsegen_tb.sch` |
| `lab1_spice/spice/` | Terminal-route decks mirroring each testbench. |
| `lab1_spice/lab1.ipynb` | Report notebook, sections P1–P4. |
| `instructors/lab0/xschem/` | Reference inverter, NAND2, pulse generator + symbols (figure source). |
| `instructors/lab1/xschem/` | Completed DUTs (figure source, verification). |
| `instructors/README.md` | States the directory is removed from the student release. |

**`ece334-docs` (branch `docs/lab-overhaul`)**

| Path | Responsibility |
|---|---|
| `docs/includes/conventions.md` | Single source of truth for process/voltage/sizing. |
| `docs/getting-started/index.md` | Retone; keep per-OS depth. |
| `docs/labs/lab0/index.md` | Rewritten manual, legacy skeleton. |
| `docs/labs/lab1/index.md` | Rewritten manual, legacy skeleton. |
| `docs/labs/lab{0,1}/images/*.png` | Captured figures. |
| `docs/reference/xschem-cheatsheet.md` | Absorb useful content from the deleted SUE deep-dive. |
| `docs/reference/magic-cheatsheet.md` | Absorb useful content from the deleted MAX deep-dive. |
| `docs/labs/lab0/sue-to-xschem.md` | **Delete.** |
| `docs/labs/lab0/max-to-magic.md` | **Delete.** |
| `mkdocs.yml` | Drop the two deleted pages from `nav`. |
| `Makefile` | `make verify` target that builds strict and checks every referenced image exists. |

---

## Task 1: Lock in the XSchem configuration fix with a regression test

The fix is already applied (`common/xschemrc`, `common/.designinit`). It is currently unprotected: nothing fails if someone reintroduces `XSCHEMRC` or drops a `:`.

**Files:**
- Create: `ece334-labs/scripts/verify_lab.sh`
- Modify: `ece334-labs/common/.designinit` (already patched — verify only)

**Interfaces:**
- Produces: `scripts/verify_lab.sh <labdir>` — exits 0 only if every `*_tb.sch` in `<labdir>/xschem` netlists with zero `IS MISSING` and every `<labdir>/spice/*.spice` runs with status 0.

- [ ] **Step 1: Write the failing check**

```bash
cat > ece334-labs/scripts/verify_lab.sh <<'EOF'
#!/usr/bin/env bash
# Netlist and simulate everything in a lab directory. Exit non-zero on any failure.
# Usage (inside the container):  scripts/verify_lab.sh lab1_spice
set -uo pipefail
LAB="${1:?usage: verify_lab.sh <labdir>}"
DESIGNS="${DESIGNS:-/foss/designs}"
LABDIR="${DESIGNS}/${LAB}"
[ -d "$LABDIR" ] || { echo "no such lab: $LABDIR" >&2; exit 2; }

fail=0
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

if [ -d "$LABDIR/xschem" ]; then
  for sch in "$LABDIR"/xschem/*_tb.sch; do
    [ -e "$sch" ] || continue
    name="$(basename "$sch" .sch)"
    out="$work/$name"; mkdir -p "$out"
    if ! timeout 180 xschem -n -s -q -x -o "$out" "$sch" >"$out/log" 2>&1; then
      echo "FAIL netlist(exit): $name"; fail=1; continue
    fi
    deck="$out/$name.spice"
    if [ ! -f "$deck" ]; then
      echo "FAIL netlist(no deck): $name"; fail=1; continue
    fi
    n_missing="$(grep -c 'IS MISSING' "$deck" || true)"
    if [ "$n_missing" -ne 0 ]; then
      echo "FAIL netlist($n_missing missing symbols): $name"
      grep 'IS MISSING' "$deck" | sed 's/^/    /'
      fail=1; continue
    fi
    echo "ok   netlist: $name"
  done
fi

if [ -d "$LABDIR/spice" ]; then
  for deck in "$LABDIR"/spice/*.spice; do
    [ -e "$deck" ] || continue
    name="$(basename "$deck")"
    if timeout 300 ngspice -b "$deck" >"$work/$name.log" 2>&1; then
      echo "ok   simulate: $name"
    else
      echo "FAIL simulate: $name"; tail -15 "$work/$name.log" | sed 's/^/    /'; fail=1
    fi
  done
fi

[ "$fail" -eq 0 ] && echo "PASS $LAB" || echo "FAIL $LAB"
exit "$fail"
EOF
chmod +x ece334-labs/scripts/verify_lab.sh
```

- [ ] **Step 2: Run it against Lab 1 and confirm the DUT resolves**

```bash
docker exec ece334-osic bash -lc '. /foss/designs/common/.designinit >/dev/null 2>&1
/foss/designs/scripts/verify_lab.sh lab1_spice'
```

Expected: `ok   netlist: rc_tb`, `ok   netlist: inv_tb`, `ok   netlist: diode_tb`, and `PASS lab1_spice`. Any `FAIL netlist(... missing symbols)` means the config regressed.

- [ ] **Step 3: Prove the test catches the regression**

Temporarily break it, confirm the script fails, then restore:

```bash
docker exec ece334-osic bash -lc 'mv ~/.xschem/xschemrc /tmp/rc.bak
/foss/designs/scripts/verify_lab.sh lab1_spice; echo "exit=$?"
mv /tmp/rc.bak ~/.xschem/xschemrc'
```

Expected: non-zero exit with `IS MISSING` lines listed.

- [ ] **Step 4: Commit**

```bash
cd ece334-labs
git add common/xschemrc common/.designinit scripts/verify_lab.sh
git commit -m "fix(xschem): load the course xschemrc, repair XSCHEM_LIBRARY_PATH

XSchem never reads an XSCHEMRC environment variable; it sources
\$XSCHEM_SHAREDIR/xschemrc, then ./xschemrc, then ~/.xschem/xschemrc
(src/xinit.c:2732-2790). .designinit exported XSCHEMRC, so the course
configuration was never applied and every local symbol netlisted as
'IS MISSING' -- Lab 1's inverter deck contained no transistors at all.

.designinit now installs a one-line shim at ~/.xschem/xschemrc, and
xschemrc layers course paths over the PDK's own file using colon-separated
appends. scripts/verify_lab.sh fails if this regresses."
```

---

## Task 2: Screenshot capture helper

**Files:**
- Create: `ece334-labs/scripts/capture.sh`

**Interfaces:**
- Produces: `capture.sh --window <regex> --out <path.png> [--size WxH] [--settle N]` — activates the matching X window, optionally resizes it, waits, and writes a PNG. Used by every figure task.

- [ ] **Step 1: Write the helper**

```bash
cat > ece334-labs/scripts/capture.sh <<'EOF'
#!/usr/bin/env bash
# Capture one X window to a PNG. Runs inside the container with DISPLAY set.
#   capture.sh --window '^xschem - inv_tb' --out /tmp/f.png --size 1200x820
set -euo pipefail
WIN=""; OUT=""; SIZE=""; SETTLE=2
while [ $# -gt 0 ]; do
  case "$1" in
    --window) WIN="$2"; shift 2 ;;
    --out)    OUT="$2"; shift 2 ;;
    --size)   SIZE="$2"; shift 2 ;;
    --settle) SETTLE="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done
: "${WIN:?--window required}" "${OUT:?--out required}"
export DISPLAY="${DISPLAY:-:1}"

for _ in $(seq 1 40); do
  id="$(xdotool search --name "$WIN" 2>/dev/null | tail -1 || true)"
  [ -n "$id" ] && break
  sleep 0.5
done
[ -n "${id:-}" ] || { echo "window not found: $WIN" >&2; exit 1; }

if [ -n "$SIZE" ]; then
  xdotool windowsize "$id" "${SIZE%x*}" "${SIZE#*x}"
fi
xdotool windowactivate "$id" || true
xdotool windowraise "$id" || true
sleep "$SETTLE"
mkdir -p "$(dirname "$OUT")"
import -window "$id" "$OUT"
identify "$OUT"
EOF
chmod +x ece334-labs/scripts/capture.sh
```

- [ ] **Step 2: Verify it captures XSchem**

```bash
docker exec -e DISPLAY=:1 ece334-osic bash -lc '. /foss/designs/common/.designinit >/dev/null 2>&1
cd /foss/designs/lab1_spice && (nohup xschem xschem/rc_tb.sch >/dev/null 2>&1 &)
/foss/designs/scripts/capture.sh --window "^xschem - rc_tb" --out /tmp/cap.png --size 1200x820'
```

Expected: `identify` prints `1200x8xx`. Copy it out with `docker cp` and view it to confirm the schematic is legible.

- [ ] **Step 3: Commit**

```bash
cd ece334-labs && git add scripts/capture.sh
git commit -m "build: add capture.sh for reproducible tool screenshots"
```

---

## Task 3: Extend `ece334lib` with the metrics Labs 0–1 need

The library has `edges_10_90`, `prop_delay`, `noise_margins`, `extract_square_law`. Lab 1 P1 needs a time constant from a step, and P4 needs a pulse width.

**Files:**
- Modify: `ece334-labs/common/ece334lib/measure.py`
- Modify: `ece334-labs/common/ece334lib/tests/test_measure.py`

**Interfaces:**
- Consumes: `ece334lib.waves.Wave` with `.x` (time) and `__getitem__(name) -> ndarray`.
- Produces:
  - `measure.tau_from_step(wave, name, v_final=None) -> float` — time from the step to the 63.2 % point of `v_final` (defaults to the final sample).
  - `measure.pulse_width(wave, name, vdd, polarity="low") -> float` — 50 %-to-50 % width. `polarity="low"` measures a low-going pulse (falling edge to the next rising edge); `"high"` measures a high-going pulse.

- [ ] **Step 1: Write the failing tests**

```python
# append to ece334-labs/common/ece334lib/tests/test_measure.py
import numpy as np
from ece334lib import measure
from ece334lib.waves import Wave

def _wave(t, **sigs):
    return Wave(x=t, signals={k: np.asarray(v, float) for k, v in sigs.items()})

def test_tau_from_step_recovers_rc_time_constant():
    tau = 1e-9
    t = np.linspace(0, 10e-9, 20001)
    v = 1.2 * (1.0 - np.exp(-t / tau))
    got = measure.tau_from_step(_wave(t, out=v), "out")
    assert abs(got - tau) / tau < 0.02

def test_pulse_width_low_going():
    # 1.8 V rail; low pulse from 4 ns to 5.5 ns -> 1.5 ns wide
    t = np.linspace(0, 10e-9, 100001)
    v = np.where((t >= 4e-9) & (t < 5.5e-9), 0.0, 1.8)
    got = measure.pulse_width(_wave(t, out=v), "out", vdd=1.8, polarity="low")
    assert abs(got - 1.5e-9) < 20e-12

def test_pulse_width_high_going():
    t = np.linspace(0, 10e-9, 100001)
    v = np.where((t >= 2e-9) & (t < 2.8e-9), 1.8, 0.0)
    got = measure.pulse_width(_wave(t, out=v), "out", vdd=1.8, polarity="high")
    assert abs(got - 0.8e-9) < 20e-12
```

- [ ] **Step 2: Run and confirm failure**

```bash
docker exec ece334-osic bash -lc 'cd /foss/designs/common && python3 -m pytest ece334lib/tests/test_measure.py -q 2>&1 | tail -20'
```

Expected: `AttributeError: module 'ece334lib.measure' has no attribute 'tau_from_step'`.

- [ ] **Step 3: Implement**

```python
# append to ece334-labs/common/ece334lib/measure.py
def _crossing(t, v, level, rising):
    """First time v crosses `level`, linearly interpolated. None if it never does."""
    if rising:
        idx = np.nonzero((v[:-1] < level) & (v[1:] >= level))[0]
    else:
        idx = np.nonzero((v[:-1] > level) & (v[1:] <= level))[0]
    if idx.size == 0:
        return None
    i = int(idx[0])
    dv = v[i + 1] - v[i]
    frac = 0.0 if dv == 0 else (level - v[i]) / dv
    return float(t[i] + frac * (t[i + 1] - t[i]))

def tau_from_step(wave, name, v_final=None):
    """RC time constant of a step response: the 63.2 % crossing time.

    Assumes the step starts at t = 0 and the signal is monotonic toward
    ``v_final`` (the last sample if not given).
    """
    t = np.asarray(wave.x, float)
    v = np.asarray(wave[name], float)
    if v_final is None:
        v_final = float(v[-1])
    target = 0.632 * v_final
    tau = _crossing(t, v, target, rising=v_final >= v[0])
    if tau is None:
        raise ValueError(f"{name!r} never reaches 63.2% of {v_final:g} V")
    return tau

def pulse_width(wave, name, vdd, polarity="low"):
    """50%-to-50% width of the first pulse on ``name``.

    ``polarity="low"``  measures a low-going pulse: falling 50 % crossing to the
    next rising 50 % crossing (this is what the pulse generator produces, since
    its output stage is a NAND).
    ``polarity="high"`` measures a high-going pulse.
    """
    if polarity not in ("low", "high"):
        raise ValueError("polarity must be 'low' or 'high'")
    t = np.asarray(wave.x, float)
    v = np.asarray(wave[name], float)
    mid = 0.5 * vdd
    first_rising = polarity == "high"

    t0 = _crossing(t, v, mid, rising=first_rising)
    if t0 is None:
        raise ValueError(f"no {'rising' if first_rising else 'falling'} 50% "
                         f"crossing on {name!r}")
    after = t > t0
    t1 = _crossing(t[after], v[after], mid, rising=not first_rising)
    if t1 is None:
        raise ValueError(f"{name!r} has an opening edge but never returns")
    return t1 - t0
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
docker exec ece334-osic bash -lc 'cd /foss/designs/common && python3 -m pytest ece334lib -q 2>&1 | tail -5'
```

Expected: all tests pass, including the pre-existing ones.

- [ ] **Step 5: Commit**

```bash
cd ece334-labs
git add common/ece334lib/measure.py common/ece334lib/tests/test_measure.py
git commit -m "feat(ece334lib): add tau_from_step and pulse_width

Lab 1 P1 reports an RC time constant and P4 reports a pulse width; both
now come from tested helpers rather than ad hoc notebook code."
```

---

## Task 4: Lab 1 P1 — retarget the RC testbench to the legacy divider

The current `rc_tb.sch` is a single 1 kΩ / 1 pF series RC. The legacy handout uses a divider: `R1 = 1 kΩ` from the source to node 1, `R2 = 2 kΩ` to ground, `C1 = 0.7 pF` across `R2`. Restoring it preserves the legacy hand analysis and gives a more interesting result (the final value is not the rail).

**Hand analysis to document:**

- $V_{out}(\infty) = 1.8 \cdot \frac{2\,\mathrm{k}}{3\,\mathrm{k}} = 1.200\ \mathrm{V}$
- $\tau = (R_1 \parallel R_2)\,C_1 = 666.7\,\Omega \cdot 0.7\ \mathrm{pF} = 466.7\ \mathrm{ps}$
- $t_{0\to70\%} = \tau\ln\frac{1}{0.3} = 1.204\,\tau = 561.9\ \mathrm{ps}$ (the legacy definition)
- $t_{10\to90\%} = \tau\ln 9 = 2.197\,\tau = 1025.4\ \mathrm{ps}$ (industry definition)

**Files:**
- Modify: `ece334-labs/lab1_spice/xschem/rc_tb.sch`
- Modify: `ece334-labs/lab1_spice/spice/rc.spice`

**Interfaces:**
- Produces: `rc_tb.raw` (ascii) with `v(in)` and `v(out)`; stimulus `PULSE(0 1.8 0 0.2n 0.2n 3n 6n)`.

- [ ] **Step 1: Write the reference deck first (it is the oracle for the schematic)**

```spice
* ECE334 Lab 1 P1 -- RC divider step response
* Vout(inf) = 1.8 * R2/(R1+R2) = 1.2 V ; tau = (R1||R2)*C1 = 466.7 ps
Vin  in  0 PULSE(0 1.8 0 0.2n 0.2n 3n 6n)
R1   in  out 1k
R2   out 0   2k
C1   out 0   0.7p
.tran 1p 15n
.control
run
set filetype=ascii
write rc.raw v(in) v(out)
meas tran t70 trig v(out) val=0 rise=1 targ v(out) val=0.84 rise=1
meas tran trise trig v(out) val=0.12 rise=1 targ v(out) val=1.08 rise=1
.endc
.end
```

- [ ] **Step 2: Run it and check against hand analysis**

```bash
docker exec ece334-osic bash -lc 'cd /foss/designs/lab1_spice/spice && ngspice -b rc.spice 2>&1 | grep -E "t70|trise|Error"'
```

Expected: `trise ≈ 1.03e-09` (hand: 1025 ps) and a final value of 1.2 V. Record the actual numbers — they go in the manual next to the hand analysis.

- [ ] **Step 3: Update the schematic to match**

Edit `rc_tb.sch` so the resistor divider and 0.7 pF cap match the deck, and the embedded `.control` block writes `rc_tb.raw`. Keep the three launcher buttons and the `in`/`out` net labels.

- [ ] **Step 4: Verify the schematic route agrees with the deck route**

```bash
docker exec ece334-osic bash -lc '. /foss/designs/common/.designinit >/dev/null 2>&1
/foss/designs/scripts/verify_lab.sh lab1_spice'
```

Expected: `ok netlist: rc_tb` and `PASS`.

- [ ] **Step 5: Commit**

```bash
cd ece334-labs
git add lab1_spice/xschem/rc_tb.sch lab1_spice/spice/rc.spice
git commit -m "feat(lab1): restore the legacy RC divider for P1

R1=1k, R2=2k, C1=0.7pF at 1.8 V. The final value is 1.2 V rather than the
rail, so tau = (R1||R2)*C1 and the hand analysis is worth doing."
```

---

## Task 5: Lab 1 P4 — pulse generator testbench and DUT

Three inverters in series feed one input of a NAND2; the undelayed signal feeds the other. Output is a low-going pulse whose width is the inverter-chain delay.

**Files:**
- Create: `ece334-labs/lab1_spice/xschem/dut_pulsegen.sym`
- Create: `ece334-labs/lab1_spice/xschem/dut_pulsegen.sch`
- Create: `ece334-labs/lab1_spice/xschem/pulsegen_tb.sch`
- Create: `ece334-labs/lab1_spice/spice/pulsegen.spice`
- Create: `ece334-labs/instructors/lab1/xschem/dut_pulsegen_solution.sch`

**Interfaces:**
- Consumes: net names `in`, `out`, `vdd`, `vss`.
- Produces: `pulsegen_tb.raw` with `v(in)`, `v(out)`, and the chain node `v(n3)`.

- [ ] **Step 1: Write the transistor-level reference deck**

```spice
* ECE334 Lab 1 P4 -- transistor-level pulse generator
* 3 inverters (in -> n1 -> n2 -> n3) + NAND2(in, n3) -> out
.lib $PDK_ROOT/sky130A/libs.tech/ngspice/sky130.lib.spice tt
.param WN=1 WP=3 LL=0.5
Vdd vdd 0 1.8
Vin in 0 PULSE(0 1.8 1n 0.2n 0.2n 10n 20n)

* inverter chain
XN1 n1 in  0   0   sky130_fd_pr__nfet_01v8 W='WN' L='LL'
XP1 n1 in  vdd vdd sky130_fd_pr__pfet_01v8 W='WP' L='LL'
XN2 n2 n1  0   0   sky130_fd_pr__nfet_01v8 W='WN' L='LL'
XP2 n2 n1  vdd vdd sky130_fd_pr__pfet_01v8 W='WP' L='LL'
XN3 n3 n2  0   0   sky130_fd_pr__nfet_01v8 W='WN' L='LL'
XP3 n3 n2  vdd vdd sky130_fd_pr__pfet_01v8 W='WP' L='LL'

* NAND2: series NMOS, parallel PMOS
XNA mid in  0   0   sky130_fd_pr__nfet_01v8 W='2*WN' L='LL'
XNB out n3  mid 0   sky130_fd_pr__nfet_01v8 W='2*WN' L='LL'
XPA out in  vdd vdd sky130_fd_pr__pfet_01v8 W='WP' L='LL'
XPB out n3  vdd vdd sky130_fd_pr__pfet_01v8 W='WP' L='LL'

.tran 1p 25n
.control
run
set filetype=ascii
write pulsegen.raw v(in) v(n3) v(out)
meas tran pw trig v(out) val=0.9 fall=1 targ v(out) val=0.9 rise=1
.endc
.end
```

- [ ] **Step 2: Run it and record the pulse width**

```bash
docker exec ece334-osic bash -lc '. /foss/designs/common/.designinit >/dev/null 2>&1
cd /foss/designs/lab1_spice/spice && ngspice -b pulsegen.spice 2>&1 | grep -E "^pw|Error|error"'
```

Expected: a `pw` in the few-hundred-picosecond range. **Record the value** — the manual quotes it, and the 1.5 ns design task is defined relative to it.

- [ ] **Step 3: Determine what reaches 1.5 ns and document the mechanism**

The unloaded chain is far faster than 1.5 ns, so the design task needs a stated lever. Sweep a load capacitance on each chain node:

```bash
docker exec ece334-osic bash -lc '. /foss/designs/common/.designinit >/dev/null 2>&1
cd /tmp && for c in 0 50f 100f 200f 400f; do
  sed "s|^\.tran|C1 n1 0 $c\nC2 n2 0 $c\nC3 n3 0 $c\n.tran|" \
      /foss/designs/lab1_spice/spice/pulsegen.spice > pg_$c.spice
  printf "CL=%-5s " "$c"; ngspice -b pg_$c.spice 2>&1 | grep -E "^pw" || echo "(no pw)"
done'
```

Pick the value that lands nearest 1.5 ns; that becomes the worked answer the manual withholds and the notebook asks for.

- [ ] **Step 4: Create the DUT symbol**

```
v {xschem version=3.4.8 file_version=1.2}
G {type=subcircuit
format="@name @pinlist @symname"
template="name=x1"
}
V {}
S {}
E {}
L 4 -60 -50 60 -50 {}
L 4 60 -50 60 50 {}
L 4 60 50 -60 50 {}
L 4 -60 50 -60 -50 {}
L 4 -70 0 -60 0 {}
L 4 60 0 70 0 {}
L 4 0 -60 0 -50 {}
L 4 0 50 0 60 {}
B 5 -72.5 -2.5 -67.5 2.5 {name=in dir=in}
B 5 67.5 -2.5 72.5 2.5 {name=out dir=out}
B 5 -2.5 -62.5 2.5 -57.5 {name=vdd dir=inout}
B 5 -2.5 57.5 2.5 62.5 {name=vss dir=inout}
T {@name} -58 -65 0 0 0.3 0.3 {}
T {PULSEGEN} -44 -8 0 0 0.4 0.4 {}
T {in} -56 -10 0 0 0.25 0.25 {}
T {out} 30 -10 0 0 0.25 0.25 {}
T {vdd} 4 -58 0 0 0.2 0.2 {}
T {vss} 4 50 0 0 0.2 0.2 {}
```

Pin order in the `B` lines must match the `ipin`/`opin`/`iopin` order in the schematic, or the netlist wires the wrong nets.

- [ ] **Step 5: Create the empty student DUT schematic and the instructor solution**

`dut_pulsegen.sch` carries the four pins plus a text block stating the topology to build and the required net names. `instructors/lab1/xschem/dut_pulsegen_solution.sch` is the completed version, used for figures and verification.

- [ ] **Step 6: Verify the solution netlists and simulates**

```bash
docker exec ece334-osic bash -lc '. /foss/designs/common/.designinit >/dev/null 2>&1
cp /foss/designs/instructors/lab1/xschem/dut_pulsegen_solution.sch \
   /tmp/dut_pulsegen.sch
/foss/designs/scripts/verify_lab.sh lab1_spice'
```

Expected: `ok netlist: pulsegen_tb`, zero missing symbols, and a simulated pulse width matching Step 2 within 5 %.

- [ ] **Step 7: Commit**

```bash
cd ece334-labs
git add lab1_spice/xschem/dut_pulsegen.sym lab1_spice/xschem/dut_pulsegen.sch \
        lab1_spice/xschem/pulsegen_tb.sch lab1_spice/spice/pulsegen.spice \
        instructors/lab1/xschem/dut_pulsegen_solution.sch
git commit -m "feat(lab1): add the transistor-level pulse generator for P4

Restores the legacy pulse-generator thread. Width is the inverter-chain
delay, which P1 (RC step) and P2 (Req extraction) have already set up, so
no gate-delay lecture is assumed."
```

---

## Task 6: Lab 0 reference designs and figure capture

Lab 0 is a guided build from a blank canvas, so the student repo ships almost nothing. The instructor copies exist to generate figures and to prove the walkthrough produces something that works.

**Files:**
- Create: `ece334-labs/instructors/lab0/xschem/inv.{sch,sym}`, `nand2.{sch,sym}`, `pulsegen.sch`, `pulsegen_tb.sch`
- Create: `ece334-labs/instructors/README.md`
- Modify: `ece334-labs/lab0_setup/README.md`

- [ ] **Step 1: Build the reference inverter, symbol, NAND2 and pulse generator**

Author each as `.sch`/`.sym` text following the Task 5 symbol pattern. Sizes: inverter `Wn=1 Wp=3 L=0.5`; NAND2 `Wn=2 Wp=3 L=0.5` (series NMOS doubled).

- [ ] **Step 2: Verify the hierarchy netlists and the pulse appears**

```bash
docker exec ece334-osic bash -lc '. /foss/designs/common/.designinit >/dev/null 2>&1
/foss/designs/scripts/verify_lab.sh instructors/lab0'
```

Expected: `PASS`, and the simulated `out` shows one low-going pulse per input edge.

- [ ] **Step 3: Write `instructors/README.md`**

State plainly: this directory holds reference solutions for figure generation and verification, and it is deleted on the student release branch.

- [ ] **Step 4: Commit**

```bash
cd ece334-labs
git add instructors lab0_setup/README.md
git commit -m "feat(lab0): reference inverter/NAND2/pulsegen for figures and verification"
```

---

## Task 7: Capture the Lab 0 and Lab 1 figures

**Files:**
- Create: `ece334-docs/docs/labs/lab0/images/*.png` (target 18–24)
- Create: `ece334-docs/docs/labs/lab1/images/*.png` (target 12–16)
- Create: `ece334-labs/scripts/make_figures.sh`

- [ ] **Step 1: Write the figure manifest as a script**

`make_figures.sh` drives `capture.sh` once per figure so the whole set can be regenerated after a tool upgrade. Each entry names the tool, the file to open, any keystrokes to send, the window regex, and the output path.

Lab 0 figures, in manual order:

| # | Slug | Content |
|---|---|---|
| 01 | novnc-desktop | Browser at `localhost`, desktop after login |
| 02 | smoke-test | Terminal output of `smoke_test.sh` |
| 03 | xschem-window | Blank XSchem canvas |
| 04 | symbol-browser | `Shift-I` browser open at `sky130_fd_pr` |
| 05 | nfet-placed | One NMOS placed, properties visible |
| 06 | edit-properties | Property dialog with `W=1 L=0.5` |
| 07 | inverter-wired | Completed inverter with pins |
| 08 | inverter-symbol | Generated `inv.sym` in symbol view |
| 09 | nand2-schematic | NAND2 transistor schematic |
| 10 | pulsegen-hierarchy | Pulse generator built from symbols |
| 11 | pulsegen-waves | Output pulse in the waveform viewer |
| 12 | stdcell-compare | SKY130 library cell beside the hand-built one |
| 13 | magic-window | Magic with the SKY130 palette |
| 14 | magic-first-fet | One painted transistor, DRC clean |

Lab 1 figures:

| # | Slug | Content |
|---|---|---|
| 01 | rc-testbench | `rc_tb.sch` with launcher buttons |
| 02 | rc-waves | matplotlib `v(in)`/`v(out)` with τ marked |
| 03 | diode-dut | Diode-connected NMOS in the DUT |
| 04 | sqrt-id-fit | matplotlib √I_D fit with V_t intercept |
| 05 | inv-dut | Completed inverter DUT |
| 06 | inv-vtc | VTC with V_M and noise margins marked |
| 07 | inv-transient | Transient with 10–90 % edges marked |
| 08 | pulsegen-tb | `pulsegen_tb.sch` |
| 09 | pulsegen-waves | `in`, `n3`, `out` with the width marked |
| 10 | jupyterlab | `lab1.ipynb` open in JupyterLab |

- [ ] **Step 2: Generate the waveform figures from `ece334lib`**

Waveform figures are matplotlib, not screen grabs — legible and reproducible. Write `instructors/figures/make_waveform_figs.py` that loads each `.raw` and saves the annotated PNG at 150 dpi.

- [ ] **Step 3: Run the manifest and review every image**

```bash
docker exec -e DISPLAY=:1 ece334-osic bash -lc '. /foss/designs/common/.designinit >/dev/null 2>&1
/foss/designs/scripts/make_figures.sh'
```

Then copy them into the docs repo and **look at each one**. Reject any figure that is cropped, shows a stale filename, has an unreadable font, or contains a dialog left open by accident.

- [ ] **Step 4: Commit**

```bash
cd ece334-docs && git add docs/labs/lab0/images docs/labs/lab1/images
git commit -m "docs: capture Lab 0 and Lab 1 figures from the live tools"
cd ../ece334-labs && git add scripts/make_figures.sh instructors/figures
git commit -m "build: scripted figure generation for Labs 0-1"
```

---

## Task 8: Rewrite the Lab 1 manual page

**Files:**
- Modify: `ece334-docs/docs/labs/lab1/index.md`
- Modify: `ece334-docs/docs/includes/conventions.md`

Structure, in this order: **Objective** → **References** → **Preparation** (P1–P4 hand analysis, done before the session) → **Lab Work** (L1–L4, one per preparation item) → **Expected Results** → **Extra Notes** → **FAQ**.

- [ ] **Step 1: Rewrite `conventions.md` to cover every number the labs cite**

Add the pulse-generator sizing and the RC divider values so no lab page invents its own numbers.

- [ ] **Step 2: Write the page**

Requirements:
- Every figure from Task 7 referenced exactly once, with a caption saying what to look for.
- Each hand-analysis result stated as a number, with the simulated value beside it and the tolerance named.
- The `W=1u` trap gets one `!!! warning`. No other admonitions unless a hazard costs real time.
- No sentence directed at the reader's feelings.
- `--8<-- "includes/conventions.md"` for the settings table.

- [ ] **Step 3: Check the prose against the standard**

```bash
cd ece334-docs
grep -nE "completely fine|you are in the right place|remarkable|don't fight|happily|pays off|Take it slowly|feel lost" docs/labs/lab1/index.md docs/getting-started/index.md
```

Expected: no matches.

```bash
awk 'BEGIN{n=0} /^!!!|^\?\?\?/{n++} END{print "admonitions:", n}' docs/labs/lab1/index.md
wc -l docs/labs/lab1/index.md
```

Expected: fewer than one admonition per 60 lines.

- [ ] **Step 4: Build strict**

```bash
cd ece334-docs && mkdocs build --strict 2>&1 | tail -20
```

Expected: no warnings about missing images or broken links.

- [ ] **Step 5: Commit**

```bash
cd ece334-docs && git add docs/labs/lab1/index.md docs/includes/conventions.md
git commit -m "docs(lab1): rewrite on the legacy P/L skeleton with real figures"
```

---

## Task 9: Rewrite the Lab 0 manual page and retire the migration deep-dives

**Files:**
- Modify: `ece334-docs/docs/labs/lab0/index.md`
- Modify: `ece334-docs/docs/reference/xschem-cheatsheet.md`
- Modify: `ece334-docs/docs/reference/magic-cheatsheet.md`
- Delete: `ece334-docs/docs/labs/lab0/sue-to-xschem.md`
- Delete: `ece334-docs/docs/labs/lab0/max-to-magic.md`
- Modify: `ece334-docs/mkdocs.yml`

- [ ] **Step 1: Salvage before deleting**

Read both deep-dives and move anything a student who never used SUE or MAX still needs — keystrokes, gotchas, netlisting mechanics — into the cheatsheets. Drop every "in SUE you would…" framing.

- [ ] **Step 2: Rewrite the Lab 0 page**

Same skeleton as Lab 1. The pulse-generator section is **observational**: build the hierarchy, simulate, note that the pulse is narrow and that its width comes from the inverter chain. State explicitly that Lab 1 does the timing analysis. No delay arithmetic here.

- [ ] **Step 3: Delete the deep-dives and update `nav`**

```bash
cd ece334-docs
git rm docs/labs/lab0/sue-to-xschem.md docs/labs/lab0/max-to-magic.md
# then remove both entries from mkdocs.yml nav
```

- [ ] **Step 4: Build strict and confirm no dangling links**

```bash
cd ece334-docs && mkdocs build --strict 2>&1 | tail -20
grep -rn "sue-to-xschem\|max-to-magic" docs/ mkdocs.yml
```

Expected: strict build clean; grep finds nothing.

- [ ] **Step 5: Commit**

```bash
cd ece334-docs
git add -A docs mkdocs.yml
git commit -m "docs(lab0): rewrite on the legacy skeleton; retire the SUE/MAX deep-dives

Students have never used SUE or MAX, so migration framing was noise. The
mechanics worth keeping moved into the XSchem and Magic cheatsheets."
```

---

## Task 10: Lab 1 report notebook

**Files:**
- Modify: `ece334-labs/lab1_spice/lab1.ipynb`

Sections P1–P4 matching the manual. Per section: heading, hand-analysis cell with named constants, measurement cell, and a markdown answer block for the student.

- [ ] **Step 1: Restructure the notebook**

P4 is new. Its measurement cell:

```python
pg = sim.run(f"{XS}/pulsegen_tb.raw")
pw = measure.pulse_width(pg, "out", vdd=VDD, polarity="low")
print(f"pulse width (50%-50%) = {pw*1e12:.0f} ps")
plot.transient(pg, ["in", "n3", "out"])
plt.title("Pulse generator: input, delayed chain node, output")
plt.show()
```

Its hand-analysis cell computes the predicted width from the student's own $R_{eq}$ and the chain's load capacitance, so P2's extracted numbers feed P4.

- [ ] **Step 2: Execute end to end in the container**

```bash
docker exec ece334-osic bash -lc '. /foss/designs/common/.designinit >/dev/null 2>&1
cd /foss/designs/lab1_spice
jupyter nbconvert --to notebook --execute --inplace --ExecutePreprocessor.timeout=600 lab1.ipynb 2>&1 | tail -5'
```

Expected: exit 0, no cell raises. This is the check that the whole lab actually works.

- [ ] **Step 3: Confirm the measured numbers match the manual**

Read the executed outputs and compare each against the manual's stated hand analysis and tolerance. Any mismatch means the manual, not the notebook, is wrong — fix the manual.

- [ ] **Step 4: Clear outputs and commit**

```bash
docker exec ece334-osic bash -lc 'cd /foss/designs/lab1_spice
jupyter nbconvert --ClearOutputPreprocessor.enabled=True --to notebook --inplace lab1.ipynb'
cd ece334-labs && git add lab1_spice/lab1.ipynb
git commit -m "feat(lab1): notebook as the lab report, sections P1-P4

Adds the P4 pulse-generator section and an answer block per section.
Committed with outputs cleared; verified by executing end to end."
```

---

## Task 11: Retone Getting Started and add a docs verification target

**Files:**
- Modify: `ece334-docs/docs/getting-started/index.md`
- Modify: `ece334-docs/Makefile`
- Modify: `ece334-labs/README.md`

- [ ] **Step 1: Retone Getting Started**

Keep every per-OS step and the container explanation. Remove the welcome essay, the reassurance, and the claims about the field. Replace `XSCHEMRC` guidance if any exists with the `~/.xschem/xschemrc` shim now installed by `.designinit`.

- [ ] **Step 2: Add `make verify`**

```makefile
verify: ## strict build + confirm every referenced image exists
	mkdocs build --strict
	@missing=0; \
	for f in $$(grep -rhoE '\!\[[^]]*\]\(([^)]+)\)' docs --include='*.md' \
	            | sed -E 's/.*\((.*)\)/\1/' | grep -vE '^https?://' | sort -u); do \
	  case $$f in /*) p="docs$$f";; *) p="$$(find docs -name "$$(basename $$f)" | head -1)";; esac; \
	  if [ -z "$$p" ] || [ ! -f "$$p" ]; then echo "MISSING IMAGE: $$f"; missing=1; fi; \
	done; \
	[ $$missing -eq 0 ] && echo "all referenced images present"
```

- [ ] **Step 3: Run it**

```bash
cd ece334-docs && make verify
```

Expected: strict build clean, `all referenced images present`.

- [ ] **Step 4: Update the labs README**

Point at the manual, list the labs, and document `scripts/verify_lab.sh` and `scripts/capture.sh`.

- [ ] **Step 5: Commit**

```bash
cd ece334-docs && git add docs/getting-started/index.md Makefile
git commit -m "docs: retone Getting Started; add make verify for images and links"
cd ../ece334-labs && git add README.md
git commit -m "docs: README covers the verification and capture scripts"
```

---

## Task 12: Full-stack verification gate for Part 1

**Files:** none created; this is the gate before Part 2.

- [ ] **Step 1: Clean-container run**

Recreate the container from the published image, mount the repo, and run the whole chain. This catches anything that depended on packages installed by hand.

```bash
docker rm -f ece334-verify 2>/dev/null || true
docker run -d --name ece334-verify --shm-size=1g --security-opt seccomp=unconfined \
  -e VNC_PW=abc123 -v "$PWD/ece334-labs:/foss/designs" hpretl/iic-osic-tools:2026.04
sleep 20
docker exec ece334-verify bash -lc '. /foss/designs/common/.designinit
/foss/designs/scripts/smoke_test.sh
/foss/designs/scripts/verify_lab.sh lab1_spice
cd /foss/designs/common && python3 -m pytest ece334lib -q'
```

Expected: smoke test OK, `PASS lab1_spice`, pytest green.

- [ ] **Step 2: Notebook executes on the clean container**

```bash
docker exec ece334-verify bash -lc '. /foss/designs/common/.designinit >/dev/null 2>&1
cd /foss/designs/lab1_spice && jupyter nbconvert --to notebook --execute \
  --output /tmp/lab1_check.ipynb --ExecutePreprocessor.timeout=900 lab1.ipynb' \
  && echo "notebook OK"
```

- [ ] **Step 3: Docs gate**

```bash
cd ece334-docs && make verify && grep -c "screenshot pending" -r docs/ || echo "no pending placeholders"
```

Expected: `make verify` clean, zero `screenshot pending` in Lab 0 and Lab 1.

- [ ] **Step 4: Record results and open Part 2**

Write the measured numbers (τ, $t_r$, $V_t$, $K_P$, $V_M$, noise margins, $t_{pd}$, pulse width) into the spec as an appendix so Parts 2–3 can cite them, and commit.

```bash
cd ece334-docs && git add specs && git commit -m "specs: record verified Lab 0-1 measurements"
```

---

## Self-Review

**Spec coverage.** Defect 1 (broken config) → Task 1. Defect 2 (no screenshots) → Tasks 2, 7. Defect 3 (prose) → Tasks 8, 9, 11. Defect 4 (missing files) → Tasks 5, 6 for Labs 0–1; Labs 2–4 are Parts 2–3. D1 notebook-as-report → Task 10. D2 legacy skeleton → Tasks 8, 9. D3 Magic → Part 2. D4 instructor-only → Task 6. D5 pulse generator → Tasks 5, 6, 9 (observational in Lab 0, quantitative in Lab 1). D6 delete deep-dives → Task 9. Verification bar → Task 12.

**Gap found and closed.** The verification bar requires `pytest ece334lib` and a strict docs build; neither had an owning task until Task 12 Steps 1 and 3. The image-existence check had no owner until Task 11 Step 2.

**Open risk carried into execution.** Task 5 Step 3 does not yet know which load capacitance yields 1.5 ns; the sweep determines it. If no reasonable capacitance gets there, the lever changes to inverter count or device width and the manual states whichever it is.

**Type consistency.** `tau_from_step(wave, name, v_final=None)` and `pulse_width(wave, name, vdd, polarity)` are used with exactly these signatures in Tasks 3 and 10. `verify_lab.sh <labdir>` and `capture.sh --window/--out/--size/--settle` are used consistently in Tasks 1, 2, 6, 7, 12.
