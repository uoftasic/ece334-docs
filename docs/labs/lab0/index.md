# ECE334 Lab 0: Introduction to XSchem and Magic

*Digital Electronics — SKY130 Open-Source Flow*

!!! abstract
    This lab introduces the course toolchain: **XSchem** for schematic capture and simulation,
    and **Magic** for layout. There are **no marks** for this lab, but completing it
    thoroughly is strongly advised before Lab 1. Take it slowly — its whole purpose is to
    make you comfortable before any marks are involved.

## Course conventions

--8<-- "includes/conventions.md"

## Objective

The purpose of this lab is to get comfortable with the two tools you will use all term:

- **XSchem** — schematic capture and simulation (drives ngspice)
- **Magic** — full-custom layout

By the end you will have:

1. drawn and simulated your **own CMOS inverter** built from individual transistors;
2. turned it into a reusable **symbol** (a "cell") and built a **2-input NAND** the same way;
3. compared your hand-built inverter against a **real production standard cell** from the
   SKY130 library; and
4. painted your first transistor in Magic.

Cheatsheets for both tools live in the reference section:
[XSchem cheatsheet](../../reference/xschem-cheatsheet.md) and
[Magic cheatsheet](../../reference/magic-cheatsheet.md). Keep them open in a browser tab.

!!! note "You are using a *real* process — that's the remarkable part"
    Everything you simulate in this course runs against **SKY130**, a genuine 130 nm CMOS
    process from SkyWater Technology, released as an open-source **process design kit (PDK)**.
    The transistor models you place (`sky130_fd_pr__nfet_01v8`, …) are the *same* device
    models a company would use to tape out real silicon, and the standard cells you compare
    against (Section L1.8) are the *same* cells used in actual open-source chips. You are not
    working with toy models — you are working around an industrial PDK, on your own laptop, for
    free. That used to require a workstation in a locked lab and a five-figure software licence.

!!! tip "If you've used another schematic or layout editor before"
    XSchem and Magic use single-key shortcuts, and a few of them differ from tools like
    LTspice, SUE, or MAX (for example, in XSchem `c` copies and `d` *deselects*; in Magic
    `d` *deletes*). You don't need to memorise anything now — the
    [cheatsheets](../../reference/xschem-cheatsheet.md) list the collisions, and this lab
    points them out as they come up. Most students have never seen these tools, and that is
    exactly who this lab is written for.

## Preparation

### Software setup

The course toolchain runs in the **IIC-OSIC-TOOLS** container (XSchem, Magic, ngspice,
Netgen, SKY130 PDK). If you have not set up the environment yet, do the
[Getting started](../../getting-started/index.md) guide first.

!!! terminal "In the noVNC desktop terminal"
    Open **http://localhost** in your browser — the EDA desktop (password `abc123`).
    Inside the EDA desktop terminal:

    ```bash
    . /foss/designs/common/.designinit     # loads course settings + SKY130 technology
    /foss/designs/scripts/smoke_test.sh     # quick health check of all the tools
    cd /foss/designs/lab0_setup             # work here
    ```

    Launch the tools:

    ```bash
    xschem                          # schematic editor
    magic -d X11 -T sky130A          # layout editor, SKY130 tech
    ```

> 📷 *Figure: noVNC desktop with terminal visible after login* — screenshot pending (`images/01-novnc-desktop.png`)

> 📷 *Figure: terminal output of `smoke_test.sh` showing all checks OK* — screenshot pending (`images/02-smoke-test.png`)

Work in `/foss/designs/lab0_setup` (this folder is mounted from your clone and persists
on your host). **If something fails, always look at the terminal** — it prints the warnings
and errors that usually point straight at the cause. Treat it as your log file.

## L1 — XSchem: your first schematics

XSchem is where you *draw* a circuit and then hand it to **ngspice** to simulate. Throughout
the course you will predict a circuit's behaviour by hand and then check it here. This
section walks you, gently and in full, from a blank canvas to a working inverter.

### L1.1 — Starting XSchem and finding your way around

!!! xschem "In XSchem"
    Start XSchem from the terminal (run `.designinit` first so the SKY130 symbols appear):

    ```bash
    . /foss/designs/common/.designinit
    xschem
    ```

    Press `?` at any time to show the keybinding cheatsheet overlay.

> 📷 *Figure: XSchem main window with blank canvas* — screenshot pending (`images/03-xschem-window.png`)

The window has three parts: the **menu bar** along the top, a **toolbar** with
**Netlist / Simulate / Waves** buttons, and the large **drawing canvas** in the middle.
Messages and errors print at the bottom and in the terminal you launched from.

| Action | Key |
|--------|-----|
| Zoom in / out | `Shift-Z` / `Ctrl-z`, or scroll wheel |
| Fit everything to the window | `f` |
| Pan | hold `Space`, or middle-drag |
| Help overlay | `?` |

Spend a minute zooming and panning around the empty canvas before you place anything.

### L1.2 — The symbol browser (and the Home button that saves you)

XSchem does not keep a parts palette on screen. Instead, every time you want a component you
open the **symbol browser**, navigate to a `.sym` file, and place it.

!!! xschem "Opening the symbol browser"
    **Recommended:** press `Shift-I` (capital I). This opens a **persistent** browser — it
    stays open so you can place several parts in a row.

    **Always works:** **Tools → Insert symbol** from the menu.

    Most laptops have **no `Insert` key**, so prefer `Shift-I` or the menu.

!!! tip "Lost in the folders? Press Home."
    The browser drops you into a tree of folders (`devices/`, the SKY130 PDK folders, your
    own files). It is easy to wander into a subdirectory and lose track of where you are. If
    that happens, click the **Home** button in the browser to jump back to the top level, then
    search again from there. You are never more than one click from a clean start — don't
    fight the tree.

**After the browser opens:**

1. Navigate to the folder you want and select a `*.sym` file.
2. Click **OK** (or double-click). The symbol now follows your cursor.
3. **Left-click** on the canvas to drop it; click again to drop another copy of the same part.
4. Press `Esc` when you are done placing that symbol.

### L1.3 — Selecting things: *select first, then act*

XSchem's golden rule is **select, then act**. Almost every edit is "click the thing, then
press a key."

| Action | How |
|--------|-----|
| Select one object | left-click it (it changes colour) |
| Add to the selection | `Shift`-left-click |
| Select a region | drag a box with the left button |
| Select everything | `Ctrl-a` |
| Clear the selection | left-click empty space, or `Esc` |

Once something is selected:

| Action | Key | Note |
|--------|-----|------|
| Move | `m` → move mouse → left-click to drop | |
| Copy | `c` → move mouse → left-click to drop | **not `d`** — `d` *deselects* |
| Rotate / flip | `Shift-R` / `Shift-F` / `Shift-V` | works while moving too |
| Edit properties | `q` | opens the properties dialog |
| Delete | `Delete` | `Esc` only *aborts*, it does not delete |

### L1.4 — The wire tool (read this carefully — it is not like LTspice)

Wiring in XSchem trips up almost everyone the first time, because it does **not** work like
the schematic editors you may have seen. There is no "wire tool button" you click and then
draw with. Instead:

!!! xschem "Drawing a wire"
    1. **Move your cursor onto the pin or wire you want to start from.** (Position matters —
       the wire begins from wherever the cursor is when you press the key.)
    2. **Press `w`.** This *starts* a wire at that point — a rubber-band line now follows your
       cursor.
    3. **Move to the other end** and **left-click** to finish the wire. Click again *before*
       finishing to add a bend (corner).
    4. Press `Esc` to abort a wire you started by mistake.

    Compare this to LTspice, where you pick a wire tool first and then click a start and an
    end. In XSchem the order is reversed: **hover first, press `w`, then click to end.** Once
    it clicks (pun intended) it becomes second nature.

**Did it actually connect?** Unconnected pins show as small **red squares**. When a wire
truly lands on a pin, that red square disappears. Where three or more wires meet, XSchem
draws a small **junction dot**. If a red square stubbornly remains, you missed the pin —
undo (`u`) and try again, zooming in (`Shift-Z`) for precision.

### L1.5 — Build your first cell: a CMOS inverter

You will build the inverter from **two individual transistors**. This is the heart of the
lab: there is no "drop an inverter" button, so you construct one the way it is really
made — and in doing so you see exactly what is inside it. (Later you will turn it into a
single symbol so you *don't* have to redraw it every time.)

!!! note "Which transistor symbols — and why it matters"
    XSchem ships generic `devices/nmos4.sym` and `devices/pmos4.sym`. **Do not use those for
    this course** — they are placeholders with no real models behind them. Use the **SKY130
    PDK devices** instead, so that simulation uses the same BSIM models a chip designer would:

    - **NMOS:** `sky130_fd_pr__nfet_01v8`
    - **PMOS:** `sky130_fd_pr__pfet_01v8`

    After `.designinit`, these appear in the symbol browser under the SKY130 PDK library
    folder (`$PDK_ROOT/sky130A/libs.tech/xschem`).

!!! xschem "Step by step"
    Open a fresh schematic named for the cell:

    ```bash
    xschem inverter.sch
    ```

    1. **Place the PMOS** (`sky130_fd_pr__pfet_01v8`) near the top and the **NMOS**
       (`sky130_fd_pr__nfet_01v8`) below it (`Shift-I` → SKY130 library → place).
    2. **Set the sizes.** Select each transistor, press `q`, and set the width/length with a
       **`u`** (micrometre) suffix on *both*:
        - NMOS: `W=1u`, `L=0.5u`
        - PMOS: `W=3u`, `L=0.5u`

       (These are the course's [unit-inverter](#course-conventions) sizes — the
       PMOS is wider to make up for holes being slower than electrons.)
    3. **Place power and ground:** `devices/vdd.sym` above the PMOS, `devices/gnd.sym` below
       the NMOS.
    4. **Wire it up** (`w` — remember: hover, press `w`, click to end):
        - PMOS source → **VDD**; NMOS source → **GND**.
        - PMOS drain → NMOS drain → this shared node is the **output**.
        - PMOS gate → NMOS gate → tied together as the **input**.
    5. **Add the input and output ports** so the cell has named terminals: place
       `devices/ipin.sym` on the input and `devices/opin.sym` on the output. Select each,
       press `q`, and set `lab=A` (input) and `lab=Y` (output).
    6. **Save:** `Ctrl-s`.

> 📷 *Figure: completed inverter schematic with A, Y, VDD, GND labelled* — screenshot pending (`images/04-inverter-schematic.png`)

### L1.6 — Simulate the inverter (the voltage transfer curve)

A single inverter is the perfect first simulation: sweep the input from 0 V to 1.8 V and
watch the output flip. This curve — the **voltage transfer characteristic (VTC)** — is one
you will analyse properly in Lab 1.

!!! xschem "Add the analysis and a stimulus"
    1. Place a `devices/vsource.sym` on the input port `A`. Select it, press `q`, and give it
       a name like `Vi` and `value=0` (the DC sweep below will override the value).
    2. Place a `devices/code_shown.sym` anywhere on the sheet, press `q`, and set its text to:

       ```spice
       .lib $PDK_ROOT/sky130A/libs.tech/ngspice/sky130.lib.spice tt
       .dc Vi 0 1.8 0.005
       .save all
       ```

       The `.lib … tt` line loads the SKY130 models at the **typical-typical** process corner.
    3. **Netlist:** press `n` (or the toolbar **Netlist** button).
    4. **Simulate:** press `s` (or **Simulate**). Watch the terminal for errors.
    5. **View the result:** click **Waves**, then plot `Y` against the swept input.

You should see `Y` start near 1.8 V, drop steeply through a switching threshold around the
middle of the supply, and settle near 0 V. **That steep middle region is the gain of the
inverter** — the whole reason CMOS logic works.

> 📷 *Figure: inverter VTC — Vo vs Vi sweep* — screenshot pending (`images/05-inverter-vtc.png`)

!!! note "What just happened is non-trivial"
    You drew two transistors and a real PDK simulated them as physical devices, complete with
    short-channel effects and parasitics, in under a second. Keep that in mind whenever a
    simulation surprises you: it is usually telling you something true about the device.

### L1.7 — Make it a *symbol*: where cells come from

Here is the idea that makes everything above worth it. Right now your inverter is a
schematic full of transistors. You do **not** want to redraw those transistors every time you
need an inverter. So you create a **symbol** — a single box with an `A` input and a `Y`
output — that *stands in* for the whole schematic.

Understanding **where and how symbols are created** is a core skill, so do this deliberately:

!!! xschem "Create the symbol"
    1. With `inverter.sch` open and **nothing selected** (`Esc`), press **`a`** (or
       **Symbol → Make symbol from schematic**).
    2. XSchem reads the port list (`A`, `Y`) you defined with the `ipin`/`opin` symbols and
       **auto-generates** `inverter.sym` — a rectangle with those two pins — saved next to
       your `.sch`.
    3. That is the whole mechanism: **a cell is a `.sch` (the contents) paired with a `.sym`
       (the box other schematics see).** Your ports *become* the symbol's pins.

**See the pairing for yourself.** Open a new schematic (`xschem test_inverter.sch`), place
your `inverter.sym` with `Shift-I`, and notice you now have a clean inverter box. Then, with
that instance selected, press **`e`** to *descend* into it — you are now looking at the
transistor schematic underneath. Press `Ctrl-e` to come back up.

!!! note "This descend-into-the-cell ability matters in the next section"
    You can descend into **your own** cells because you have their schematic. Hold that
    thought — when we compare against a *PDK* standard cell, you'll find you **can't** descend
    into it, and that contrast is the whole point.

### L1.8 — Build a second cell: the 2-input NAND

Repeat the workflow to cement it, this time for a gate with structure worth seeing: a
**2-input NAND**. The pull-down is **two NMOS in series**; the pull-up is **two PMOS in
parallel**.

!!! xschem "Build `nand2.sch`"
    ```bash
    xschem nand2.sch
    ```

    1. **Pull-down (series NMOS):** place two `sky130_fd_pr__nfet_01v8`. Stack them so the
       drain of the lower connects to the source of the upper; the bottom source goes to
       **GND**, the top drain is the **output `Y`**. Sizes: `W=2u`, `L=0.5u` each (series
       devices are widened so two stacked transistors still pull down strongly).
    2. **Pull-up (parallel PMOS):** place two `sky130_fd_pr__pfet_01v8`. Tie both sources to
       **VDD** and both drains to the **output `Y`**. Sizes: `W=3u`, `L=0.5u` each.
    3. **Inputs:** gate of NMOS-1 + PMOS-1 = input `A`; gate of NMOS-2 + PMOS-2 = input `B`.
    4. **Ports:** `ipin` for `A` and `B`, `opin` for `Y` (`q` → set `lab=`). Add `vdd`/`gnd`.
    5. **Save** (`Ctrl-s`), then **make the symbol** with `a` → `nand2.sym`.

> 📷 *Figure: 2-input NAND schematic, series NMOS + parallel PMOS* — screenshot pending (`images/06-nand2-schematic.png`)

You now have **two of your own cells**, `inverter.sym` and `nand2.sym`. Keep these files —
**you will reuse them in later labs** instead of redrawing transistors. This little
collection is your personal cell library; building it yourself is how you come to understand
what a "standard cell" actually *is*.

### L1.9 — Compare your inverter to a *real* standard cell

A chip is not built from cells you draw by hand — it is assembled from a **standard-cell
library** that the foundry characterises and ships. SKY130 includes one called
**`sky130_fd_sc_hd`** (`fd_sc_hd` = "high-density standard cells"). Its inverter is
**`sky130_fd_sc_hd__inv_1`**. Let's see how your hand-built inverter compares to it.

!!! note "You can't descend into a PDK standard cell — and that's expected"
    Unlike *your* `inverter.sym`, a PDK standard cell does **not** come with a schematic you
    can open in XSchem. It ships as a **SPICE subcircuit** (a `.subckt … .ends` block) plus a
    GDS layout — a sealed black box, characterised once by the foundry and reused everywhere.
    So there is nothing to "descend into." To *use* one, you **include its SPICE file** and
    **instantiate it as a subcircuit** (an `x`-prefixed device), wiring its pins. That is a
    genuinely important real-world skill: most of a real design is built from black-box cells
    you trust but never open.

!!! warning "The sizing is deliberately different"
    `inv_1` is **not** sized like your `W=1u/3u` teaching inverter — the foundry chose its own
    transistor widths for its density and drive targets. So expect the switching threshold and
    sharpness to differ. **That difference is the lesson**, not a mistake: sizing changes
    behaviour, and you'll quantify exactly how in Lab 1.

Run this comparison from the terminal — it mirrors the inverter VTC you just simulated, but
on the foundry cell:

!!! terminal "In the noVNC desktop terminal"
    ```bash
    cd /foss/designs/lab0_setup
    . /foss/designs/common/.designinit
    ```

    Create `hd_inv.spice`:

    ```spice
    * Lab 0 - VTC of a real SKY130 standard cell, sky130_fd_sc_hd__inv_1
    .lib $PDK_ROOT/sky130A/libs.tech/ngspice/sky130.lib.spice tt
    .include $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/spice/sky130_fd_sc_hd.spice

    * Pin order of the subckt is: A VGND VNB VPB VPWR Y
    * (open the .spice above and read the ".subckt sky130_fd_sc_hd__inv_1 ..." line to confirm)
    Xinv A 0 0 VDD VDD Y sky130_fd_sc_hd__inv_1
    VDD  VDD 0 1.8
    Vin  A   0 0
    .dc Vin 0 1.8 0.005
    .control
    run
    wrdata hd_inv_vtc.txt v(Y)
    .endc
    .end
    ```

    Run it:

    ```bash
    ngspice -b hd_inv.spice
    ```

    `hd_inv_vtc.txt` holds two columns: the swept input voltage and the cell's output `Y`.

!!! tip "Confirm the pin order yourself"
    Pin order is something you *read off the cell*, never guess. Open the standard-cell SPICE
    file and find the line beginning `.subckt sky130_fd_sc_hd__inv_1` — the names after it,
    in order, are exactly how you must wire the `Xinv` line. `A` is the input, `Y` the output,
    `VPWR`/`VGND` the supplies, and `VPB`/`VNB` the body (well) connections, tied to power and
    ground respectively.

**What to look for.** Plot the foundry cell's VTC next to your own inverter's VTC. Where does
each one switch? Which has the sharper transition? You are looking at the difference between
*your* sizing choices and a *foundry's* sizing choices — the first of many "hand design vs.
the real thing" comparisons this course is built around.

> 📷 *Figure: VTC of your inverter overlaid with the sky130_fd_sc_hd__inv_1 VTC* — screenshot pending (`images/07-vtc-compare.png`)

## L2 — Magic: your first layout

Magic is the **layout** editor: instead of symbols and wires, you paint the actual mask
geometry — diffusion, polysilicon, metal — that becomes silicon. In Lab 2 you will lay out a
full gate; here you just get a feel for the canvas and paint a single transistor.

!!! terminal "In the noVNC desktop terminal"
    ```bash
    cd /foss/designs/lab0_setup
    magic -d X11 -T sky130A
    # in Magic:  :load scratch
    ```

Magic is built around a **box** (a rectangle you position) and a **cursor**. Almost every
command acts on "the box" or "the current selection."

| Action | How |
|--------|-----|
| Set the box | **left-click** = lower-left corner, **right-click** = upper-right corner |
| Read the box size/position | `b` (or `:box`) — prints to the console |
| Paint a layer into the box | middle-click over a layer's colour, or `:paint <layer>` |
| Erase one layer under the cursor | `Ctrl-D`, or `:erase <layer>` |
| Move the selection | select with `s`, then drag with the **middle mouse button** |
| Undo / redo | `u` / `U` |
| Zoom to fit / zoom to box | `v` / `z` |

> 📷 *Figure: Magic window with a box drawn on the grid* — screenshot pending (`images/09-magic-box.png`)

!!! tip "A few keys differ from MAX (only relevant if you used it)"
    In Magic, `w`/`e`/`r`/`q` **nudge** the selection (down/up/right/left), `d` **deletes**,
    and the **wiring tool is reached with the space bar**, not `w`. If you never used MAX,
    ignore this — just learn the keys above.

### L2.1 — Paint a transistor

A transistor in Magic is not a part you place — it is simply **poly painted across
diffusion**. Where the two overlap, Magic automatically recognises a transistor channel.

!!! magic "In Magic"
    1. Set a box (left-click lower-left, right-click upper-right) over a small area.
    2. Paint **n-diffusion**: `:paint ndiff` (or middle-click the ndiff colour).
    3. Set a box for a thin vertical strip crossing the diffusion, and paint **poly**:
       `:paint poly`.
    4. **Watch the overlap** — the crossing region becomes an `ntransistor` automatically.
       The diffusion on either side is the source and drain; the poly is the gate.

    For a PMOS you would first paint an `nwell`, then `pdiff`, then `poly` across it.

> 📷 *Figure: poly painted across ndiff, the channel highlighted* — screenshot pending (`images/10-magic-transistor.png`)

### L2.2 — Show and hide layers

Layouts get busy. Magic lets you hide layers to inspect just what you care about.

!!! magic "In Magic"
    ```text
    :see no poly
    :see no ndiff
    :see metal1
    ```

    Restore everything with `:see allSame` (or `:see` of each layer). `:see no errors` hides
    the white **DRC dots** that flag design-rule violations in real time.

> 📷 *Figure: layout with only metal1 visible* — screenshot pending (`images/12-magic-layers-hide.png`)

!!! note "Want the full layout walkthrough?"
    A complete, friendly tour of Magic — painting, selection, contacts, hierarchy, and
    design-rule checking — lives in the
    [Lab 0 deep dive: MAX → Magic](max-to-magic.md). You don't need it for Lab 0, but it's a
    good reference once you reach Lab 2.

## Smoke test — verify ngspice from the terminal

This optional check confirms ngspice and the PDK work before Lab 1. You write a minimal RC
deck, run it headlessly, and inspect the output — a gentle preview of how Lab 1 works.

!!! terminal "In the noVNC desktop terminal"
    ```bash
    cd /foss/designs/lab0_setup
    . /foss/designs/common/.designinit
    ```

    Create the SPICE deck (`/tmp/smoke_rc.spice`):

    ```spice
    * Minimal RC -- no PDK needed
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

    The output file `/tmp/smoke_rc.txt` has time and voltage columns. The final value of
    `v(n2)` should be about **1.20 V** (= 1.8 V × 2 kΩ / (1 kΩ + 2 kΩ)).

> 📷 *Figure: expected RC response — Vi and Vo vs time, final Vo ≈ 1.2 V* — screenshot pending (`images/13-smoke-rc-plot.png`)

## Deliverables

- [ ] Container launches; smoke test passes
- [ ] `inverter.sch` built from SKY130 transistors, with `A`/`Y` ports, and simulated (VTC)
- [ ] `inverter.sym` created with `a`; descended into and back (`e` / `Ctrl-e`)
- [ ] `nand2.sch` (series NMOS, parallel PMOS) built and turned into `nand2.sym`
- [ ] VTC of your inverter compared against `sky130_fd_sc_hd__inv_1`; difference noted
- [ ] Magic scratch cell: box drawn, poly painted across diffusion, layers hidden/shown
- [ ] Cheatsheets bookmarked for Labs 1–4

!!! note "Going deeper (optional)"
    Two companion **deep-dive** documents map the old Micro Magic SUE/MAX flow onto XSchem and
    Magic in exhaustive detail: [SUE → XSchem](sue-to-xschem.md) and
    [MAX → Magic](max-to-magic.md). They are reference material for the curious or for anyone
    who used the legacy tools — you do **not** need them to complete Lab 0.
