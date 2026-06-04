# ECE334 Lab 0: Introduction to XSchem and Magic

*Digital Electronics — SKY130 Open-Source Flow*

!!! abstract
    This lab introduces the course toolchain: **XSchem** for schematic capture and simulation,
    and **Magic** for layout. There are **no marks** for this lab, but completing it
    thoroughly is strongly advised before Lab 1.

## Course conventions

--8<-- "includes/conventions.md"

## Objective

The purpose of this lab is to get you familiar with the software used throughout the course:

- **XSchem** — schematic capture and simulation (replaces SUE)
- **Magic** — full-custom layout (replaces MAX)

By the end you should understand the design methodology used in the course. Cheatsheets for
both tools are in the reference section: [XSchem cheatsheet](../../reference/xschem-cheatsheet.md)
and [Magic cheatsheet](../../reference/magic-cheatsheet.md).

### Key collision warning

If you have used SUE or MAX before, read the collision tables in the cheatsheets **before**
using single-key shortcuts.

- **XSchem:** `d` deselects (SUE: duplicate), `c` copies, `r` draws a rectangle (SUE: rotate).
- **Magic:** `d` deletes (MAX: duplicate), `w` nudges down (MAX: wire). Use **space** for the
  wiring tool in Magic.

## Preparation

### Software setup

The course toolchain runs in the **IIC-OSIC-TOOLS** container (XSchem, Magic, ngspice,
Netgen, SKY130 PDK).

!!! terminal "In the noVNC desktop terminal"
    On your laptop, clone the workbench repo and start the environment:

    ```bash
    cd ece334-labs
    ./scripts/start_vnc.sh
    ```

    Open **http://localhost** in your browser — the EDA desktop for XSchem and Magic
    (password `abc123`). The lab manuals and cheatsheets are on this docs website.

    Inside the EDA desktop terminal:

    ```bash
    . /foss/designs/common/.designinit
    /foss/designs/scripts/smoke_test.sh
    cd /foss/designs/lab0_setup
    ```

    Launch the tools:

    ```bash
    xschem                          # schematic editor
    magic -d X11 -T sky130A          # layout editor, SKY130 tech
    ```

> 📷 *Figure: noVNC desktop with terminal visible after login* — screenshot pending (`images/01-novnc-desktop.png`)

> 📷 *Figure: terminal output of `smoke_test.sh` showing all checks OK* — screenshot pending (`images/02-smoke-test.png`)

Work in `/foss/designs/lab0_setup` (this folder is mounted from your clone and persists
on your host). If something fails, always look at the **terminal** — it prints warnings
and errors that usually point to the cause.

## Lab work

### L1 — XSchem tutorial

XSchem is the schematic environment. You place components and simulate them with **ngspice**.
All later labs compare hand calculations to simulation.

#### Getting started

!!! xschem "In XSchem"
    Start XSchem from the terminal (run `.designinit` first so SKY130 symbols appear in the browser):

    ```bash
    . /foss/designs/common/.designinit
    xschem
    ```

    Press `?` to show the keybinding cheatsheet.

> 📷 *Figure: XSchem main window with blank canvas* — screenshot pending (`images/03-xschem-window.png`)

**Screen layout:** menu bar, toolbar (**Netlist**, **Simulate**, **Waves**), drawing canvas.

#### Placing symbols (no Insert key required)

Most laptop keyboards do **not** have an `Insert` key. XSchem still needs a way to
pick components from its libraries (`devices/`, PDK folders, your own `.sym` files).
Use **any one** of these — they all open the same symbol browser:

!!! xschem "In XSchem"
    **Recommended for Lab 0:** press `Shift-I` (capital I). This opens a
    **persistent** browser: it stays open while you place several symbols in a row.

    **Menu (always works):** **Tools → Insert symbol**
    (some builds label it *Insert Symbol* or *Insert Symbols*).

    **If your keyboard has Insert:** `Insert` opens the browser once per symbol;
    `Shift-Insert` is the same persistent dialog as `Shift-I`.

    **Also:** `Ctrl-i` opens the persistent insert dialog in many XSchem versions.

**After the browser opens:**

1. Navigate folders (e.g. `devices/`) and select a `*.sym` file.
2. Click **OK**. The symbol follows the cursor.
3. **Left-click** on the canvas to place; click again for more copies of the same symbol.
4. Press `Esc` when you are done placing that symbol.

Press `?` anytime for the full keybinding overlay.

| Action | XSchem |
|--------|--------|
| Insert symbol | `Shift-I`, **Tools → Insert symbol**, or `Insert` |
| Zoom in | `Shift-Z` or scroll up |
| Zoom out | `Ctrl-z` or scroll down |
| Fit window | `f` |
| Pan | `Space` or middle-drag |

#### Build the pulsegen circuit

!!! xschem "In XSchem"
    Source the course environment (loads the SKY130 symbol library into XSchem), then open the schematic:

    ```bash
    . /foss/designs/common/.designinit
    xschem pulsegen.sch
    ```

**Which transistor symbols?**
XSchem ships with generic `devices/nmos4.sym` and `devices/pmos4.sym` (simple
placeholders, not tied to SKY130 models). **For Lab 0 and every marked lab in this course,
use the SKY130 PDK devices instead** so netlisting matches the `.lib` line in your
testbench and ngspice finds real BSIM models.

- **Use (required):** `sky130_fd_pr__nfet_01v8` and `sky130_fd_pr__pfet_01v8` from the PDK
  library (`$PDK_ROOT/sky130A/libs.tech/xschem`, added to the symbol browser after
  `.designinit`).
- **Do not use for this lab:** `nmos4` / `pmos4` from `devices/` — simulation with SKY130
  will fail or be meaningless.

In the symbol browser (`Shift-I`), open the **SKY130** library folder (not only
`devices/`), pick the `nfet_01v8` and `pfet_01v8` symbols, and place them
as you would any other component. After placing, press `q` and set widths/lengths with a
**`u`** suffix (course default for teaching: `w=1u`, `l=0.5u` on NMOS;
mirror Lab 1 inverter sizing on PMOS if you like, e.g. `w=3u`, `l=0.5u`).

Place remaining components from `devices/` using the symbol browser:

| Component | XSchem symbol |
|-----------|---------------|
| Pulse source | `devices/vsource.sym` — edit with `q`: `value=PULSE(0 1.8 0 100p 100p 5n 10n)` |
| Ground | `devices/gnd.sym` |
| VDD | `devices/vdd.sym` |
| Inverter (each) | `sky130_fd_pr__pfet_01v8` + `sky130_fd_pr__nfet_01v8` (PMOS above, NMOS below; wire as usual) |
| 2-input NAND | 2× PFET in parallel, 2× NFET in series (same SKY130 symbols) |

**Select, then act:** left-click to select; `m` move, `c` copy, `q` properties,
`Delete` remove. **Wire:** press `w`, click to start and bend, click on pin to finish.

Build: (1) pulse source on the left; (2) three inverters in a row; (3) 2-input NAND from
four transistors tapping the chain. Save with `Ctrl-s`.

> 📷 *Figure: partial pulsegen schematic with source and inverters wired* — screenshot pending (`images/05-pulsegen-wiring.png`)

#### Simulate with ngspice

!!! xschem "In XSchem"
    Add analysis via the symbol browser (`Shift-I`) → `devices/code_shown.sym`, then edit
    with `q`:

    ```spice
    .tran 100p 50n
    .save all
    .lib $PDK_ROOT/sky130A/libs.tech/ngspice/sky130.lib.spice tt
    ```

    Then:

    1. **Netlist:** `n` (or toolbar **Netlist**)
    2. **Simulate:** `s` (or **Simulate**)
    3. **Waveforms:** **Waves → gtkwave**

> 📷 *Figure: ngspice simulation or gtkwave with pulsegen signals* — screenshot pending (`images/07-xschem-simulate.png`)

#### Hierarchy: symbol and test_pg

1. Add ports (`Shift-I`): `devices/ipin.sym` at input, `devices/opin.sym` at outputs; set names with `q`.
2. **Make symbol:** press `a` → creates `pulsegen.sym`.
3. New schematic: `xschem test_pg.sch`; use `Shift-I` to place `pulsegen.sym`, wire, save.
4. **Descend:** select instance → `e`; **back:** `Ctrl-e`.

### L2 — Magic tutorial

!!! terminal "In the noVNC desktop terminal"
    ```bash
    cd /foss/designs/lab0_setup
    magic -d X11 -T sky130A
    # in Magic:  :load scratch
    ```

| Step | Old MAX | Magic |
|------|---------|-------|
| Start | `max` | `magic -d X11 -T sky130A` |
| Draw box | left/right click | left-click = lower-left, right-click = upper-right |
| Paint poly | `p` over layer | middle-click on poly layer, or `:paint poly` |
| Wire | `w` | **space** (wiring tool); right-click each leg |
| Undo | `u` | `u` (redo `U`) |

> 📷 *Figure: Magic window with box drawn on grid* — screenshot pending (`images/09-magic-box.png`)

> 📷 *Figure: painted poly on diffusion showing channel* — screenshot pending (`images/10-magic-transistor.png`)

> 📷 *Figure: metal1 wire with wiring tool active* — screenshot pending (`images/11-magic-wire.png`)

**Transistor in Magic:** paint `ndiff`, paint `poly` across it → overlap becomes
`ntransistor`. PMOS: `nwell` then `pdiff` then `poly`.

### Configuring layers

!!! magic "In Magic"
    Hide non-routing layers to inspect metal1 only:

    ```bash
    :see no poly
    :see no ndiff
    :see no nwell
    :see metal1
    ```

    Restore with `:see all`.

> 📷 *Figure: layout with only metal1 visible* — screenshot pending (`images/12-magic-layers-hide.png`)

## Smoke test — verify ngspice from the terminal

This optional check confirms that ngspice and the PDK work before Lab 1. Write a minimal RC
deck, run it headlessly, and inspect the output data file.

!!! terminal "In the noVNC desktop terminal"
    ```bash
    cd /foss/designs/lab0_setup
    . /foss/designs/common/.designinit
    ```

    Create the SPICE deck (`/tmp/smoke_rc.spice`):

    ```spice
    * Minimal RC -- no PDK
    Vi n1 0 PULSE(0 1.8 0 0.2n 0.2n 3n 6n)
    R1 n1 n2 1k
    R2 n2 0 2k
    C1 n2 0 0.7p
    .tran 1p 15n
    .control
    run
    wrdata /tmp/smoke_rc.txt v(n1) v(n2)
    .endc
    .end
    ```

    Run ngspice in batch mode:

    ```bash
    ngspice -b /tmp/smoke_rc.spice
    ```

    The output file `/tmp/smoke_rc.txt` contains time and voltage columns. The final value
    of `Vo` should be approximately **1.20 V** (1.8 V × 2 kΩ / (1 kΩ + 2 kΩ)).

> 📷 *Figure: expected RC response — Vi and Vo vs time, final Vo ≈ 1.2 V* — screenshot pending (`images/13-smoke-rc-plot.png`)

## Deliverables

- [ ] Container launches; smoke test passes
- [ ] `pulsegen.sch` saved with source, three inverters, NAND; simulated once
- [ ] `pulsegen.sym` and `test_pg.sch` created (hierarchy)
- [ ] Magic scratch cell: box, painted poly, metal1 wire, undo tried
- [ ] Layer hide/show exercise on Magic layout
- [ ] Cheatsheets bookmarked for Labs 1–4
