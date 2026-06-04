# ECE 334 Lab 0 — Porting the SUE Schematic Tutorial to XSchem

**A gap-filling report for re-implementing the Micro Magic SUE content of Lab 0 in the XSchem schematic editor**

---

## 0. How to read this report

ECE 334 Lab 0 introduces two Micro Magic tools: **SUE** (schematic entry + simulation) and **MAX** (full-custom layout). A companion report covers the MAX / layout portion. This report covers **only the SUE / schematic-entry portion** — that is, lab-manual sections 1.3.1 ("L1 – SUE Tutorial") and 1.3.2 ("Sizing Transistors"), together with the underlying *Micro Magic Tools SUE Design Manager Tutorial v4.3* (the PDF) that those sections draw from.

It re-expresses that material so the same outcomes can be achieved in **XSchem**, the open-source hierarchical schematic editor from xschem.sourceforge.io. All XSchem commands, keybindings, and mouse conventions below are taken from the official XSchem documentation (xschem_man.html, commands.html, creating_schematic.html, netlisting.html, simulation.html, creating_symbols.html) and correspond to XSchem release 3.x, which is the current stable branch.

The MAX / layout portion of Lab 0 (section 1.3.3, "L2 – MAX Tutorial", and section 1.3.4) is intentionally out of scope for this document; see the companion MAX-to-Magic report. Section 8 of this report addresses where the SUE/MAX cross-probing workflow (Lab 0 §1.3.1, "Pages 59-end") fits in the XSchem + Magic world.

**Lab 0 lab-manual guidance, carried forward.** The lab manual says to follow the SUE tutorial PDF with several targeted exceptions. This report preserves those same skip/modify instructions, translated into XSchem terms:

- *Page 10 of PDF (installing the tutorial directory):* **skip** — XSchem has no equivalent setup step; your schematic files live wherever you save them.
- *Page 22 (transistor sizing):* after changing a transistor's width to 8/4, **change it back to 2/1** before continuing — same instruction applies in XSchem.
- *Pages 32–34 (Running IRSIM):* **skip** — IRSIM is not available in XSchem; use ngspice (covered in Section 5.3 below).
- *Pages 35–44 (Part 4, higher-level schematics and Verilog):* **follow** the equivalent XSchem procedure in Section 5.4 below.
- *Pages 45–59:* **skip**.
- *Pages 59-end (cross-probing with MAX):* **attempt after completing the layout tutorial**; see Section 8 for the XSchem / Magic equivalent flow.

A note on philosophy: this is not a line-by-line "find and replace" of button labels. SUE and XSchem share the same schematic-capture goals but reach them through different interaction models. The most useful thing this report can do is teach the *model*, then give you the lookup tables. Read Sections 1–3 once; after that, Sections 5–7 are step-by-step reference material.

---

## 1. The single most important warning: keys do not mean the same thing

A student moving from SUE to XSchem who relies on muscle memory will get into trouble immediately, because several of the most-used single-key bindings are bound to **different and conflicting** actions in the two tools. Before anything else, internalize this table.

| Key | Meaning in **SUE** | Meaning in **XSchem** |
|-----|--------------------|-----------------------|
| `d` | **Duplicate** the selection | **Deselect** the object under the mouse pointer |
| `c` | *(unused as a standalone; `Ctrl-c` = copy to clipboard)* | **Copy** selected objects |
| `r` | **Rotate** the selection | **Start rectangle** placement |
| `p` | **Plot** selected net in NST waveform viewer | **Place polygon** |
| `v` | **Zoom to fit** cell | **Constrained vertical move/copy** of objects |
| `s` | **Step time** (IRSIM) | **Run simulation** (asks confirmation) |
| `h` | **Run HSPICE / IRSIM** | **Constrained horizontal move/copy** of objects |
| `k` | **Cross-probe** to MAX layout | **Highlight** selected nets |
| `w` | **Add wire** | **Add wire** ✓ (same!) |
| `e` | **Push into** schematic | **Descend into** schematic ✓ (same!) |
| `Ctrl-e` | **Pop out** of schematic | **Back to parent** schematic ✓ (same!) |
| `q` | *(unused)* | **Edit properties** of selected object |
| `u` | **Undo** | **Undo** ✓ (same!) |
| `t` | **Add text** | **Place text** ✓ (same!) |
| `m` | **Modify** selected object | **Move** selected objects |
| `f` | *(unused)* | **Full zoom** (fit schematic to window) |
| `Escape` | *(varies)* | **Abort current operation**, redraw, unselect |
| `Delete` | *(varies)* | **Delete** selected objects |
| `Ctrl-q` | **Exit SUE** (Ctrl-d in SUE) | **Exit XSchem** |
| `Ctrl-s` | **Save** | **Save** ✓ (same!) |
| `Ctrl-n` | **New schematic** | **Clear schematic** (new) |
| `Ctrl-o` | *(Open, also Ctrl-l in SUE)* | **Open file** |
| `Insert` | *(not used in SUE)* | **Insert symbol from library** |
| `n` | *(unused)* | **Hierarchical netlist** |
| `Shift-N` | **Netlist** in SUE | **Top-level-only netlist** |
| `Space` | **Show hotkeys** in SUE | **Pan** the schematic view |

The three collisions that bite hardest:

1. In SUE `d` *duplicates*, but in XSchem `d` *deselects* — copy in XSchem is `c`.
2. In SUE `r` *rotates*, but in XSchem `r` *begins a rectangle*. Rotation in XSchem is `Shift-R` (or `alt-r` to rotate around an anchor point).
3. In SUE `p` *plots a waveform*, but in XSchem `p` *begins polygon placement*. Net highlighting in XSchem is `k`; waveform viewing requires launching gtkwave separately.

When in doubt, use the **menu**: every action is accessible via `Edit`, `View`, `Simulation`, etc., and the menu labels are unambiguous regardless of muscle memory.

---

## 2. The two tools' models, side by side

### SUE's model (what Lab 0 assumes)

- **Library List Boxes** run down the right side of the window. You find a component (e.g. `inverter` in the `mspice` library), click on its name in the list, drag the cursor into the canvas, and click again to drop it.
- **Generators:** some components (like `nand2`) are *generators* — parameterized cells that structurally regenerate their schematic when you change `ninputs`. This is a SUE-specific concept.
- **Push/Pop hierarchy:** `e` descends into a subcell; `Ctrl-e` returns. The schematic and icon are two *views* of the same cell, toggled with `c` (Swap Views).
- **Simulation is tightly integrated:** SUE calls HSPICE or IRSIM directly with a single hotkey (`h`), then drives the NST waveform viewer. The schematic, netlist, and simulator are all coordinated from one window.
- **Cross-probing:** SUE communicates with MAX over an inter-process socket. Selecting a net in SUE and pressing `k` highlights the same net in the MAX layout window, and vice versa.

### XSchem's model (what you will actually use)

- **Symbol browser (Insert key):** pressing `Insert` opens a hierarchical file-browser dialog. You navigate to the desired library directory (e.g. `devices/`), select a symbol file (`.sym`), and place it. No permanent side panel — the browser is invoked on demand.
- **Select then act:** XSchem's fundamental principle is *select first, then act*. Left-click to select a single object; `Shift`+left-click to add to the selection; drag a box to area-select. Then press `m` to move, `c` to copy, `Delete` to delete, `q` to edit properties, etc.
- **No generator concept:** XSchem does not have parametric generators in the SUE sense. Parameterized components work by editing the `w=`, `l=`, `ninputs=` etc. attributes in the properties dialog (`q` key). If you need a 3-input NAND, you either build it from transistors or use a library that provides it.
- **Hierarchy via schematic/symbol pairs:** a schematic (`.sch`) and its symbol (`.sym`) are separate files. You create a symbol automatically by pressing `a` in the schematic view; XSchem generates a symbol file from the schematic's port list. Pressing `e` on a placed instance descends to the schematic; `Ctrl-e` returns.
- **Simulation is externally driven:** XSchem generates a netlist (`n` key → SPICE format by default) and then launches the configured simulator (ngspice, Icarus Verilog, etc.) in an xterm. Waveforms open in **gtkwave** (or GAW). This is less tightly integrated than SUE+HSPICE but more flexible.
- **Net highlighting** replaces cross-probing: select a wire and press `k` to highlight that electrical net throughout the schematic. Press `Shift-K` to clear all highlights.

### The library concept

SUE organizes components into UNIX directories that appear as named Library List Boxes (`mspice`, `devices`, etc.). XSchem uses the same concept — libraries are directories of `.sym` files — but you navigate them through the Insert dialog rather than a persistent panel. The default XSchem library includes a `devices/` directory with general-purpose components: `ipin.sym`, `opin.sym`, `iopin.sym`, `lab_pin.sym` (net label), `vdd.sym`, `gnd.sym`, `vsource.sym`, `isource.sym`, `res.sym`, `cap.sym`, `nmos4.sym`, `pmos4.sym`, and `title.sym`.

The lab's PDK-specific components (transistors with process-calibrated parameters) may be in an additional library directory; confirm the path with course staff.

---

## 3. Software setup and starting up (Lab 0 §1.2.1 → XSchem)

Lab 0 has you append a `source /cad2/ece451/SOURCEME` block to `.cshrc` and then launch with `sue`. The XSchem equivalent depends on how XSchem and the PDK are installed on the eecg machines; confirm the exact path with course staff, but the shape of the setup is:

**Shell configuration** (append to `~/.cshrc` and re-login, similar to the existing block):
```csh
# ECE334 XSchem setup
setenv XSCHEM_LIBRARY_PATH /path/to/pdk/symbols:/path/to/course/library
```

**Launching XSchem:**
```
xschem                         # open blank schematic
xschem myschematic.sch         # open an existing file directly
xschem -T <techname> myfile.sch  # specify a technology file
```

**Where errors appear:** exactly as Lab 0 advises for SUE — *watch the terminal*. The xterm from which you launched XSchem (and any xterm XSchem opens for simulation) prints all warnings, netlist errors, and simulator messages. Treat it as your log file.

**Getting help:**
- `?` key in the drawing area: show/hide a keybinding cheatsheet overlay.
- `/` key: show a fullscreen image of keybindings.
- `Help` menu → keybindings reference.

**Quitting:** `Ctrl-q` (XSchem prompts to save unsaved changes, equivalent to SUE's warning about modified cells).

**Creating a new schematic:**
```
xschem pulsegen.sch     # XSchem asks whether to create the file if it doesn't exist
```
or, from inside a running XSchem, `Ctrl-n` clears the current canvas (be careful — SUE's `Ctrl-n` opens a name dialog; XSchem's clears immediately after confirmation).

---

## 4. Notes on transistor sizing in XSchem (Lab 0 §1.3.2)

Lab 0 §1.3.2 gives sizing rules specific to the Micromagic tool:

> - Use `lp_min` (PMOS) and `ln_min` (NMOS) for transistor lengths.
> - Length values must be preceded by `u` (micrometers) if you enter a number.
> - Width values do NOT need `u` (the tool assumes micrometers automatically).

In XSchem, transistor properties are edited through the **property dialog** (`q` key with the instance selected). The behavior is identical in intent, with these differences:

- XSchem property values follow standard SPICE syntax. Write lengths as `l=0.18u` or `l=lp_min` (if your PDK defines `lp_min` as a SPICE parameter). Write widths as `w=2u` or `w=2` if the model's scale factor handles it.
- **There is no implicit unit assumption** in XSchem's property strings. Both `w=` and `l=` should carry explicit units (`u`, `n`, `m`) unless the PDK documentation says otherwise. This is the opposite of the SUE convention for widths — **always add `u`** to both parameters to be safe.
- The `m=` multiplier (number of fingers / instances) follows standard SPICE: `m=1` for a single device.
- Use `lp_min` and `ln_min` only if your PDK's SPICE model files define them as `.param` variables. If they are not defined, use the numerical minimum length from the design rules (e.g. `l=0.18u` for a typical 180 nm process).

---

## 5. Step-by-step translation of Lab 0 §1.3.1 ("L1 – SUE Tutorial")

The following five sub-sections mirror the five Parts of the SUE tutorial PDF, reproducing the same circuit-building sequence in XSchem. Each sub-section is written to be self-contained; you do not need the SUE PDF open alongside this document. The lab manual skip/modify instructions from §1.3.1 are respected throughout.

---

### 5.1 Part 1 — Getting started with XSchem (SUE tutorial pages 1–6)

**Launching and the screen layout.** Start XSchem from the terminal:
```
xschem
```
The XSchem window opens with:
- A **menu bar** at the top: `File Edit Options Simulation Tools Help`.
- A **toolbar** on the right side with buttons: `Netlist`, `Simulate`, `Waves`.
- The **drawing canvas** occupying the main area.
- Status / message information at the bottom of the window.

There are no Library List Boxes in XSchem. Component browsing is entirely via the `Insert` key dialog. This is the biggest visual difference from SUE.

**Menus and hotkeys.** XSchem uses single-key bindings without requiring the cursor to hover over a specific region. Pressing `?` at any time shows the complete keybinding cheatsheet. Pressing `/` shows it fullscreen. Unlike SUE's Space-bar-activated hotkey list, XSchem's cheatsheet is always available.

**The snap factor.** XSchem snaps objects to a grid. You can halve the snap threshold with `g` and double it with `G`. Use `g` when you need to place objects more precisely; reset with `G` when done. This replaces SUE's zoom-in-to-place behavior.

**Zoom controls** (replacing SUE's `z`/`Shift-z`/`v`):

| Action | SUE | XSchem |
|--------|-----|--------|
| Zoom in | `z` | `Shift-Z` or scroll wheel up |
| Zoom out | `Shift-z` | `Ctrl-z` or scroll wheel down |
| Zoom to fit | `v` | `f` |
| Zoom box (drag an area) | drag in canvas | `z` (then drag with right mouse button) |
| Pan | *(scroll bars)* | `Space` (pan toggle) or middle-drag |

**Try it.** Before drawing anything, practice the zoom controls. Zoom in with `Shift-Z`, zoom out with `Ctrl-z`, and return to a full view with `f`. Note that `v` in XSchem does *not* fit the view — it begins a constrained vertical move.

---

### 5.2 Part 2 — Drawing a schematic: the pulsegen circuit (SUE tutorial pages 7–19)

The goal is to build the pulsegen circuit from the SUE tutorial: a pulse source feeding three inverters in series, with a nand2 gate tapping two points to generate a glitch pulse. The SUE tutorial builds this from transistor-level components in the `mspice` library; the XSchem equivalent uses individual NMOS/PMOS transistor symbols from the `devices/` library. The resulting SPICE netlist is identical in structure.

#### 5.2.1 Creating a new schematic file

```
xschem pulsegen.sch
```
XSchem will ask to confirm creating a new file. Once open, press `Ctrl-Shift-S` or use `File → Save As` to confirm the file name.

In SUE, a new schematic is created with `Ctrl-n` and named in a dialog. In XSchem, the name is specified on the command line or in `File → Save As`. The title bar will show the filename and modification state — an asterisk `*` indicates unsaved changes, directly analogous to SUE's `M` (modified) indicator in the Schematic List Box.

#### 5.2.2 Placing components

In SUE you click a name in the Library List Box and drag to the canvas. **In XSchem:**

1. Press `Insert` (or `Shift-I` for the persistent dialog). A file-browser dialog opens.
2. Navigate to `devices/` and select `nmos4.sym` for an NMOS transistor. Click **OK**.
3. The symbol attaches to your cursor. Move the mouse to the desired position and **left-click** to place it. XSchem remains in placement mode — click again to place another copy. Press `Escape` to exit placement mode.

To place common components:

| SUE component | XSchem equivalent | Symbol path |
|---------------|-------------------|-------------|
| `inverter` (mspice) | PMOS + NMOS pair | `devices/pmos4.sym` + `devices/nmos4.sym` |
| `nand2` (mspice) | 2× PMOS (parallel) + 2× NMOS (series) | same building blocks |
| `pulse` (mspice) | Voltage source with PULSE waveform | `devices/vsource.sym` |
| `global` (devices) | Ground symbol | `devices/gnd.sym` |
| `input` (devices) | Input port | `devices/ipin.sym` |
| `output` (devices) | Output port | `devices/opin.sym` |
| `vddp` supply | VDD symbol | `devices/vdd.sym` |

> **Note:** the Micromagic mspice library provides pre-built, transistor-level inverters and gates as single icons. XSchem does not include equivalent pre-built icons in its default `devices/` library. You will build the inverter and nand2 from individual transistors. This is exactly what the mspice library itself contains internally — you are just making the hierarchy visible. If the course provides a lab-specific library with pre-built gate symbols, place them from that library instead.

#### 5.2.3 Selecting objects

XSchem's fundamental interaction: **select, then act.**

- **Left-click** near an object selects it (it turns a highlighted color). Left-clicking on an empty area clears the selection.
- **`Shift`+left-click** adds to the selection without clearing previous selections.
- **Drag** with left button pressed to area-select (drag a box around multiple objects).
- `Ctrl-a` selects everything on the canvas.
- `Alt-left-click` deselects a specific object.
- `Escape` clears the selection and aborts any active mode.

Object states in XSchem (replacing SUE's black/white/blue/yellow color scheme):
- **Default:** the component is drawn in its normal color.
- **Selected:** the component is drawn in the selection highlight color (typically yellow or a brighter variant, depending on the color scheme).
- **Highlighted net:** pressing `k` on a selected wire highlights the entire electrical net in a distinct color (pink by default). `Shift-K` clears all highlights.

#### 5.2.4 Editing component properties

In SUE you double-click a component to get its Edit Properties popup. **In XSchem:**

1. Left-click the component to select it.
2. Press `q` — the **Edit Properties** dialog opens, showing all attributes (name, model, w, l, m, etc.).
3. Edit the desired fields, then press `Enter` or click **OK** (or `Ctrl-Enter` to confirm).

To replicate the SUE tutorial's transistor resizing (page 22 of the SUE PDF — the third inverter's right-most transistors):
- Select the PMOS of the third inverter, press `q`, change `w=2u` to `w=8u`. Click OK.
- Select the NMOS of the third inverter, press `q`, change `w=1u` to `w=4u`. Click OK.
- **Then change them back to `w=2u` and `w=1u`** before continuing, as the lab manual instructs.

For the `vsource` (replacing the SUE `pulse` icon), press `q` and set the value to a PULSE specification:
```
value=PULSE(0 1.8 0 100p 100p 5n 10n)
```
This specifies: low=0 V, high=1.8 V, delay=0, rise=100 ps, fall=100 ps, pulse width=5 ns, period=10 ns. Adjust to match the parameters the SUE tutorial sets for the `pulse` icon.

For the ground (`devices/gnd.sym`), the default net name `GND` is already correct. For VDD (`devices/vdd.sym`), the default `VDD` is appropriate; edit with `q` if you need a different name.

#### 5.2.5 Rotating, flipping, and duplicating

| Action | SUE | XSchem |
|--------|-----|--------|
| Rotate 90° | `r` | Select, then `Shift-R` (or `alt-r` to rotate around anchor) |
| Flip horizontal | `x` | Select, then `Shift-F` |
| Flip vertical | *(no direct key)* | Select, then `Shift-V` |
| Duplicate / copy | `d` | Select, then `c` — **not `d`** |
| Move | Button-2 drag | Select, then `m` + mouse movement + left-click to place |
| Undo | `u` | `u` (identical) |

When **moving** (`m`): after pressing `m`, the selected object attaches to the cursor. During movement, press `Shift-R` to rotate or `Shift-F`/`Shift-V` to flip before placing. Left-click to drop the object.

When **copying** (`c`): identical to move, but the original remains in place and the copy is attached to the cursor.

**Deleting:** select the object(s) and press `Delete`. There is no `Escape`-to-delete — `Escape` *aborts* the current mode but does not delete.

#### 5.2.6 Wiring and connectivity

In SUE: `w` hotkey → click to start → click to add segments → Button-2 to end. **In XSchem `w` is identical in concept:**

1. Press `w` to enter wire placement mode.
2. **Left-click** to start the wire at a point.
3. Move the mouse — a rubber wire follows. Press `Space` to toggle between Horizontal-then-Vertical, Vertical-then-Horizontal, and diagonal routing.
4. **Left-click** again to place an anchor (add a bend), and continue.
5. **Left-click on a pin or another wire endpoint** to connect and end the wire.
6. Press `Escape` to abort the current wire segment (replaces SUE's `Ctrl-c` to abort).
7. Press `Shift-W` to snap-start: the wire automatically snaps its starting point to the nearest unconnected pin or wire endpoint.

**Connectivity indicators** (replacing SUE's hollow-square / solid-square / nothing convention):
- XSchem draws a **small green dot** (junction dot) at a T or cross intersection where three or more wires meet, exactly equivalent to SUE's solder dot.
- There is no explicit "open" marker in XSchem; unconnected pins on components show as small red squares. If a pin's red square disappears when you zoom in on it, the wire is connected. If it persists, you have missed the connection — undo and try again.

**Moving components connected to wires:** in SUE, wires stay connected when you move an icon. In XSchem, use `Ctrl-m` (move with wire stretching) instead of plain `m`, or use a **stretch operation** (`Ctrl-drag` to define the stretch region, then `m` to move) to drag a block of the schematic while keeping connections intact.

**Net naming** (replacing SUE's name_net_s icon): in XSchem, place a `devices/lab_pin.sym` on any wire and edit its `lab=` attribute (with `q`) to assign a name. The `lab_pin` symbol is XSchem's direct replacement for SUE's `name_net_s` icon.

**Saving:** `Ctrl-s` — identical to SUE.

#### 5.2.7 Building the pulsegen circuit step by step

Use the following sequence (corresponding to the SUE tutorial's Part 2 walk-through):

1. Place a `devices/vsource.sym` on the left side of the canvas. Edit it (`q`) to set a PULSE waveform. This replaces the SUE `pulse` icon.
2. Place a `devices/gnd.sym` below the negative terminal of the source, and another `devices/gnd.sym` below each NMOS transistor source in the inverters. Edit with `q` if the net name needs changing. This replaces the SUE `global` icon named `gnd`.
3. Build the first inverter: place one `devices/pmos4.sym` and one `devices/nmos4.sym`. Wire the PMOS drain to the NMOS drain (output), PMOS source to VDD, NMOS source to GND, and both gates together (input).
4. Place `devices/vdd.sym` on the PMOS source. This replaces the SUE `vddp` generator.
5. **Copy** (`c`) the inverter pair twice more to get three inverters total. Move (`m`) them into a row.
6. Build the nand2 gate from two PMOS (parallel) and two NMOS (series) transistors, connecting them correctly.
7. Wire the inverter chain and nand2 gate to match the target schematic.
8. Save: `Ctrl-s`.

---

### 5.3 Part 3 — Simulating the pulsegen circuit (SUE tutorial pages 21–26)

The SUE tutorial runs the schematic in HSPICE (single key `h`) and then in IRSIM (after switching simulation mode). **Lab 0 skips IRSIM (pages 32–34).** In XSchem, both are replaced by **ngspice** as the simulation backend.

#### 5.3.1 Adding SPICE analysis statements

Unlike SUE, which embeds analysis parameters in the `pulse` icon and a built-in `.tran` command, XSchem requires you to place the analysis statement explicitly in the schematic. Place a `devices/code_shown.sym` (or `devices/netlist.sym`) component and edit its property (`q`) to contain:

```spice
.tran 100p 50n
.save all
```

This instructs ngspice to run a transient simulation for 50 ns with 100 ps time steps and save all node voltages.

You also need to include the SPICE model files for the transistors. Place a `devices/netlist.sym` and add a `.include` line pointing to the PDK model file, for example:
```spice
.include "/path/to/models/tt.spice"
```
Confirm the model file path with course staff.

#### 5.3.2 Generating the netlist

Press `n` (or click the **Netlist** button in the toolbar). XSchem generates a SPICE netlist file named `pulsegen.spice` (or `pulsegen.sch.spice`, depending on configuration) in the simulation directory (default: `~/.xschem/simulations/`). The **Options → Show netlist window** setting (or `Shift-A`) opens a panel that shows the generated netlist inline — use this to verify the netlist before simulating.

This replaces SUE's `Shift-N` (SPICE Netlist) hotkey.

#### 5.3.3 Running the simulation

Press `s` or click the **Simulate** button. XSchem launches ngspice in an xterm window. This replaces SUE's `h` hotkey for HSPICE.

Watch the terminal for errors — ngspice will print warnings and, if the model files are found and the circuit is valid, will complete the transient run silently.

#### 5.3.4 Viewing waveforms

Click the **Waves** button in the toolbar, or configure a waveform viewer in `Simulation → Configure Simulators and Tools`. XSchem can launch **gtkwave** automatically. This replaces SUE's NST waveform viewer.

In gtkwave:
- Drag signal names from the left panel to the waveform area to display them.
- This is conceptually equivalent to SUE's "select wire, press `p` to plot net."

**Net highlighting within the schematic** (analogous to SUE's waveform probe): select any wire in XSchem and press `k` to highlight that entire electrical net in the schematic. This tells you visually which wires belong to the same node. To plot that net's waveform, note its net name (shown in the status bar when selected) and locate it in gtkwave.

#### 5.3.5 Net naming (replacing SUE's automatic net naming)

In SUE, unnamed nets get automatic names like `net_#`. XSchem behaves similarly — unnamed internal nodes get auto-generated names in the SPICE netlist. To give a net a meaningful name (equivalent to SUE's `name_net_s` icon or I/O port approach):

- Place `devices/lab_pin.sym` on the wire. Press `q` and set the `lab=` attribute to the desired name (e.g. `lab=out_nand`).
- After netlisting, that net will appear under that name in gtkwave.

Port pins (`ipin`, `opin`) also name their attached nets, exactly as in SUE.

---

### 5.4 Part 4 — Hierarchical schematics and symbols (SUE tutorial pages 27–44)

The SUE tutorial (Part 4) has you add I/O ports to the pulsegen schematic, create an icon for it, instantiate that icon into a test schematic (`test_pg`), and run Verilog simulation. The XSchem equivalent covers the same concepts through its schematic/symbol pair mechanism.

**Lab 0 says to follow pages 35–44.** This maps to the following XSchem workflow:

#### 5.4.1 Adding ports (I/O pins) to the schematic

In SUE, you place `input`, `output`, or `inout` icons from the `devices` library. **In XSchem:**

1. Press `Insert` and select `devices/ipin.sym` for an input port. Place it at the input of the pulsegen (where the source connects to the first inverter). Press `q` and set `lab=in`.
2. Place `devices/opin.sym` for the output of the nand2. Press `q` and set `lab=out0_H`.
3. Place a second `devices/opin.sym` for the output of the third inverter. Press `q` and set `lab=out1_H`.

To name multiple ports with a common prefix+suffix (the SUE tutorial's "Name Objects" shortcut for bulk naming): in XSchem there is no bulk-rename dialog. Select each port individually and edit its `lab=` with `q`. For two output ports it takes only two steps.

Save the schematic: `Ctrl-s`.

#### 5.4.2 Creating a symbol for the pulsegen schematic

In SUE, you select "Make Other View" from the View menu (hotkey `Shift-c`). **In XSchem:**

1. With the pulsegen schematic open, make sure no objects are selected (press `Escape`).
2. Press `a` — XSchem reads the port list and generates a symbol automatically. A dialog asks for confirmation; click **OK**.
3. XSchem saves the symbol as `pulsegen.sym` in the same directory as `pulsegen.sch`.
4. The symbol will appear as a simple rectangular box with ports attached (analogous to SUE's auto-generated icon). You can open and edit `pulsegen.sym` (use `File → Open`) to customize its appearance — draw lines, arcs, and text just as in the SUE icon editor.

To switch between schematic and symbol views (SUE's `c` / Swap Views hotkey): open each file separately with `File → Open`. XSchem does not have a single toggle key between views; instead, from a placed instance in a parent schematic, press `i` to descend to the symbol or `e` to descend to the schematic.

**Editing the symbol's graphical appearance:**

In the symbol editor (after opening `pulsegen.sym`):
- Press `l` to draw a line; left-click for each vertex; left-click the starting point or double-click to finish.
- Press `r` to draw a rectangle; drag with left button.
- Press `t` to add text; click to place, type the text, press `Enter`.
- The port pins (small red squares at the ends of the stubs) should not be moved without also moving their labels — select both together before moving.

Adding a text property that displays a parameter value (SUE's `I'm $my_name` feature):

In XSchem, add a text element `@name` or `@<attribute>` in the symbol file — XSchem substitutes attribute values at placement time. For example, if you add the text `@name` to the symbol body, each placed instance will display its instance name.

#### 5.4.3 Building the test schematic (`test_pg`)

In SUE, you create a new schematic, drop the pulsegen icon, drop a clock icon, and wire them. **In XSchem:**

1. Open a new schematic: `File → New` (or from the command line: `xschem test_pg.sch`).
2. Press `Insert` and navigate to your working directory; select `pulsegen.sym`. Place it.
3. Place a vsource or a second schematic-defined `clock` symbol if one is available.
4. Wire the components together (`w` key, same as before).
5. Add `devices/ipin.sym`, `devices/opin.sym`, or `devices/lab_pin.sym` as needed for net labels.
6. Save: `Ctrl-s`.

#### 5.4.4 Descending into and returning from hierarchy

| Action | SUE | XSchem |
|--------|-----|--------|
| Push into instance's schematic | `e` (select first) | Select instance, press `e` |
| Push into instance's symbol | *(Swap Views: `c`)* | Select instance, press `i` |
| Pop back up | `Ctrl-e` | `Ctrl-e` (identical) |
| Display hierarchical netlist | Display Design Hierarchy (Sim menu) | Press `n` — XSchem netlists the full hierarchy automatically |

XSchem performs **hierarchical netlisting by default** — pressing `n` walks the entire hierarchy and generates a flat SPICE file with `.subckt` sections for each unique schematic. There is no explicit "Display Design Hierarchy" control in XSchem; the netlisting depth is always full hierarchy unless a symbol has a `format` attribute that makes it a leaf (terminal) element.

#### 5.4.5 Verilog simulation

The SUE tutorial changes simulation mode to Verilog (`Change Simulation Mode`) and runs a Verilog netlist. **In XSchem:**

1. Switch netlist mode: `Options → Verilog` radio button (or press `Ctrl-Shift-V` to cycle modes).
2. Press `n` to generate the Verilog netlist (`pulsegen.v` in the simulation directory).
3. Configure the Verilog simulator: `Simulation → Configure Simulators and Tools`. Set the Verilog line to invoke **Icarus Verilog** (`iverilog`), which is the open-source equivalent of the commercial Verilog tools the SUE tutorial assumes.
4. Press `s` or the **Simulate** button.
5. View results in **gtkwave**: click **Waves**.

Behavioral Verilog models (SUE's Verilog property line in icons, the `.vb` file mechanism): in XSchem, a symbol's `verilog_format` attribute defines how it is netlisted in Verilog mode — this is the direct equivalent of SUE's `-type fixed -name verilog -text {...}` property line in an icon. Edit the symbol file's global property string with `q` (with nothing selected) to add or modify `verilog_format`.

---

### 5.5 Part 5 — Cross-probing with MAX → XSchem + Magic integration (SUE tutorial pages 51–54)

**Lab 0 says:** attempt cross-probing with MAX after completing the layout tutorial (L2). Copy `FA.max` and `FA.sue` into your working directory.

XSchem has no native cross-probing link to Magic equivalent to the SUE/MAX inter-process communication. The SUE/MAX cross-probe (`k` hotkey) worked by: (1) running LVS via Gemini to match schematic nets to layout nets, (2) communicating selected net names between the two processes. This is a sophisticated, tightly-coupled feature unique to the Micromagic toolset.

**The XSchem + Magic equivalent flow is a sequential extract/LVS loop:**

1. **Complete the layout in Magic** (from the companion L2 tutorial).
2. **Extract the layout** from Magic's console:
   ```
   :extract all
   :ext2spice
   ```
   This produces a `.spice` file from the layout's geometry.
3. **Run LVS** using the `netgen` tool, comparing the extracted layout netlist against the XSchem-generated schematic netlist:
   ```
   netgen -batch lvs "pulsegen.spice pulsegen" "pulsegen_layout.spice pulsegen"
   ```
   `netgen` reports mismatches — unmatched devices, mismatched connectivity — which is what the SUE/MAX cross-probe was checking interactively.
4. **Simulate the extracted netlist** in ngspice if post-layout simulation with parasitics is desired.

This is more work than pressing `k` in SUE, but it is rigorous: it guarantees that the schematic and layout are electrically equivalent (LVS) rather than just visually correlated. The interactive net-highlight experience is replaced by LVS reports.

**Net highlighting within XSchem** (the partial equivalent): selecting a wire and pressing `k` highlights the entire electrical net across the schematic. `Shift-K` clears. `Ctrl-k` unhighlights only the selected net. This gives you visual net tracing within the schematic, but does not communicate to Magic.

---

## 6. A worked example: the pulsegen circuit in XSchem

This section condenses the full pulsegen build into a checklist, analogous to the MAX-to-Magic report's NAND2 worked example. Run these steps in sequence on a fresh canvas.

1. **Open a new schematic:** `xschem pulsegen.sch`. Confirm creation.
2. **Place a vsource:** `Insert` → `devices/vsource.sym`. Place on the left. Press `q` → set `value=PULSE(0 1.8 0 100p 100p 5n 10n)`. Set `name=V1`.
3. **Place GND under the vsource negative terminal:** `Insert` → `devices/gnd.sym`.
4. **Place VDD above each PMOS source:** `Insert` → `devices/vdd.sym`. Three copies needed (one per inverter).
5. **Build inverter 1:** place one `pmos4` and one `nmos4`. Wire drain-to-drain (output), source of pmos to VDD, source of nmos to GND, gate of each connected. Press `Ctrl-s`.
6. **Copy (`c`) inverter 1** twice; place inverters 2 and 3 to the right using `m`. Wire the output of inverter 1 to the input of inverter 2, and so on.
7. **Edit inverter 3's transistor widths:** select PMOS → `q` → `w=8u`. Select NMOS → `q` → `w=4u`. Then **change back** to `w=2u` and `w=1u`.
8. **Build the nand2 gate:** 2× `pmos4` in parallel (shared drain, individual gates), 2× `nmos4` in series (drain of upper to source of lower, individual gates). Wire gates: input from vsource positive terminal, and from after inverter 2's output.
9. **Add a netlist analysis block:** `Insert` → `devices/code_shown.sym` → `q` → add `.tran 100p 50n` and `.save all`. Add a `.include` for PDK models.
10. **Add port labels:** place `devices/ipin.sym` at the vsource gate input. Place `devices/opin.sym` at the nand2 output and the inverter 3 output. Edit `lab=` attributes with `q`.
11. **Generate netlist:** press `n`. Open **Options → Show netlist win** to verify.
12. **Simulate:** press `s`. Watch the xterm for errors.
13. **View waveforms:** click **Waves** → gtkwave opens. Drag `in`, `out0_H`, `out1_H` into the waveform display.
14. **Create a symbol:** press `a` → confirm. XSchem saves `pulsegen.sym`.
15. **Build test_pg:** open `xschem test_pg.sch`. Insert `pulsegen.sym`. Wire, add source / ports. Save. Simulate.

---

## 7. Master command / keybinding reference (SUE → XSchem)

Long-form descriptions are used where a macro would collide (Section 1). Where SUE used the mouse heavily (dragging icons from list boxes, Button-2 to end wires), the XSchem equivalent is noted with the mouse action.

| Task | SUE keybind / action | XSchem keybind / action |
|------|----------------------|------------------------|
| Launch tool | `sue` | `xschem [file.sch]` |
| Quit | `Ctrl-d` | `Ctrl-q` |
| Help / hotkey list | `Space` | `?` or `/` |
| New schematic | `Ctrl-n` (name dialog) | `Ctrl-n` (clears canvas; name was set at launch) |
| Open file | `Ctrl-l` | `Ctrl-o` |
| Save | `Ctrl-s` | `Ctrl-s` ✓ |
| Save As | `File → Save As` | `Ctrl-Shift-S` |
| Place component | click name in Library List Box | `Insert` → navigate → OK |
| Rotate 90° | `r` | `Shift-R` (or `alt-r` for anchor rotation) |
| Flip X | `x` | `Shift-F` |
| Flip Y | `y` | `Shift-V` |
| Duplicate / copy | `d` | `c` — **not `d`** |
| Move | Button-2 hold+drag | Select → `m` → mouse → left-click |
| Move with wire stretch | *(not explicit; wires auto-follow)* | `Ctrl-m` |
| Delete | Delete key / select+del | `Delete` key |
| Undo | `u` | `u` ✓ |
| Redo | *(Shift-u)* | `Shift-U` |
| Edit properties | double-click | Select → `q` |
| Add wire | `w` | `w` ✓ |
| Snap-start wire | *(automatic)* | `W` (Shift-W) |
| End wire / terminate | Button-2 click | Left-click on target pin or wire endpoint |
| Abort wire | `Ctrl-c` | `Escape` |
| Toggle wire routing mode | Space | Space |
| Add text / label | `t` | `t` |
| Net label (name_net_s) | `name_net_s` icon from devices | `Insert` → `devices/lab_pin.sym` → `q` → set `lab=` |
| Add input port | `input` icon | `Insert` → `devices/ipin.sym` |
| Add output port | `output` icon | `Insert` → `devices/opin.sym` |
| Global VDD | `vddp` icon | `Insert` → `devices/vdd.sym` |
| Global GND | `global` icon, name=gnd | `Insert` → `devices/gnd.sym` |
| Select object | left-click | left-click |
| Add to selection | Shift+left-click | `Shift`+left-click |
| Select by area | drag Button-1 | drag left-button |
| Deselect all | click blank | left-click blank area or `Escape` |
| Select all | *(no hotkey)* | `Ctrl-a` |
| Zoom in | `z` | `Shift-Z` or scroll up |
| Zoom out | `Shift-z` | `Ctrl-z` or scroll down |
| Zoom to fit | `v` | `f` |
| Zoom box | `z`+drag | `z` (then right-drag) |
| Pan | scroll bars | `Space` or middle-drag |
| Push into schematic | `e` | `e` ✓ |
| Push into symbol | `c` (Swap Views) | Select instance → `i` |
| Pop out | `Ctrl-e` | `Ctrl-e` ✓ |
| Make symbol (Make Other View) | `Shift-c` | `a` (auto-generates from port list) |
| SPICE netlist | `Shift-N` | `n` |
| Run HSPICE / simulator | `h` | `s` or **Simulate** button |
| View waveforms | NST viewer (auto-launched) | **Waves** button → gtkwave |
| Highlight / probe net | select + `p` (plot) | select wire + `k` (highlight) |
| Clear net highlights | *(re-plot without wire selected)* | `Shift-K` |
| Cross-probe to layout | `k` | *(no equivalent; use LVS — Section 5.5)* |
| Display schematic hierarchy | `Sim → Display Design Hierarchy` | `n` (always full-hierarchy) |
| Switch simulation mode | `Sim → Change Simulation Mode` | `Options → SPICE/Verilog/VHDL` radio buttons or `Ctrl-Shift-V` |
| Show/hide netlist window | *(separate NST window)* | `Options → Show netlist win` or `Shift-A` |

---

## 8. Where XSchem has no SUE equivalent — gaps and recommendations

Four aspects of the Lab 0 SUE material do not translate cleanly into XSchem. Being explicit about them prevents wasted time.

**1. The Library List Box / persistent component browser.** SUE keeps all library icons in visible, scrollable list boxes at all times, making discovery fast. XSchem's `Insert` dialog must be navigated each time. *Recommendation:* learn the paths to the most-used symbols (`devices/nmos4.sym`, `devices/pmos4.sym`, `devices/vsource.sym`, etc.) and use `Shift-I` for the persistent dialog, which stays open between placements.

**2. Generators (parameterized cells that regenerate their schematic).** SUE's `nand2` is a generator — changing `ninputs` from 2 to 3 rewrites the underlying transistor schematic. XSchem has no generator mechanism in base form. *Recommendation:* build multi-input gates from individual transistors, or use a library that provides pre-built gate symbols. For the pulsegen tutorial specifically, a 2-input NAND from 4 transistors is straightforward and is actually better practice for understanding the circuit.

**3. IRSIM interactive simulation.** The lab already skips IRSIM (pages 32–34), so this gap was pre-existing. For completeness: IRSIM is a switch-level simulator not available in XSchem. Use ngspice for analog-accurate SPICE simulation, or Icarus Verilog for fast logic-level simulation. There is no XSchem equivalent of IRSIM's interactive step-by-step logic-level probing, though ngspice's interactive mode (`ngspice -i`) provides similar time-step-by-time-step control at the SPICE level.

**4. Live SUE/MAX cross-probing.** As explained in Section 5.5, the interactive net-highlight cross-probe between schematic and layout has no native equivalent in the XSchem + Magic world. The flow becomes an extract/LVS loop: layout → `:extract all` + `:ext2spice` in Magic → `netgen` for LVS → review mismatch report. This is more rigorous than the interactive highlight but requires an explicit LVS step each time the layout changes.

---

## Appendix: sources

All XSchem behavior above is drawn from the official documentation at `xschem.sourceforge.io/stefan/xschem_man/xschem_man.html` (accessed May 2026), specifically:

- *XSCHEM Editor Commands* (`commands.html`) — all keybindings and mouse actions, select/move/copy/stretch, wire placement, constrained moves, polygon editing.
- *Creating a Circuit Schematic* (`creating_schematic.html`) — component placement, wiring, power symbols, property editing, automatic symbol generation (`a` key), hierarchy (`e`/`Ctrl-e`), netlisting.
- *Creating Symbols* (`creating_symbols.html`) — schematic/symbol pair model, pin direction, `format`/`template` attributes, cloning.
- *Netlisting* (`netlisting.html`) — SPICE/Verilog/VHDL modes, leaf vs. subcircuit components, `format` and `verilog_format` attributes, netlist directory.
- *Simulation* (`simulation.html`) — ngspice and Icarus Verilog configuration, `Simulate` and `Waves` buttons, gtkwave integration, xschemrc/simrc configuration.
- *Run XSCHEM* (`run_xschem.html`) — command-line options, new/open/save file workflow.

The SUE behavior referenced is from the *Micro Magic Tools SUE Design Manager Tutorial v4.3* and ECE 334 Lab 0 (Revision 2025), sections 1.3.1–1.3.2.
