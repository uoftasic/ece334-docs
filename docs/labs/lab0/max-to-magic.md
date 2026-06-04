# ECE 334 Lab 0 — Porting the MAX Layout Tutorial to Magic VLSI

**A gap-filling report for re-implementing the Micro Magic MAX content of Lab 0 in the Magic VLSI layout editor**

---

## 0. How to read this report

ECE 334 Lab 0 introduces two Micro Magic tools: **SUE** (schematic entry + simulation) and **MAX** (full-custom layout). This report covers **only the MAX / layout portion** of Lab 0 — that is, lab-manual sections 1.3.3 ("L2 – MAX Tutorial") and 1.3.4 ("Configuring Layers in Max"), together with the underlying *Micro Magic Tools MAX Layout System Tutorial* (the second PDF) that those sections draw from and that Lab 2 expands on.

It re-expresses that material so the same outcomes can be achieved in **Magic**, the open-source layout editor from opencircuitdesign.com. All Magic commands, macros, and mouse conventions below are taken from the standard Magic tutorial set (Tutorials #1, #2, #3, #4, and #6) linked from the Magic documentation page; they correspond to Magic 7/8 and are stable across current 8.x releases.

The SUE schematic-capture portion of Lab 0 (sections 1.2 and 1.3.1) is intentionally out of scope: Magic is a layout editor and has no schematic-entry counterpart to SUE. Section 9 explains what replaces the SUE/MAX cross-probing flow.

A note on philosophy: this is not a line-by-line "find and replace" of one tool's buttons with another's. MAX and Magic share the same goals (draw a transistor-level layout, check it against design rules, build hierarchy) but reach them through genuinely different interaction models. The most useful thing this report can do is teach the *model*, then give you the lookup tables. Read sections 2–3 once; after that, sections 6–8 are reference material.

---

## 1. The single most important warning: keys do not mean the same thing

A student moving from MAX to Magic who relies on muscle memory will get into trouble fast, because several of the most-used single-key macros are bound to **different and conflicting** actions in the two tools. Before anything else, internalize this table.

| Key | Meaning in **MAX** | Meaning in **Magic** |
|-----|--------------------|----------------------|
| `p` | Paint the layer under the cursor | *(not a default paint macro; painting is done with the middle mouse button or `:paint`)* |
| `a` | Edit/stretch a rectangle **edge** | **Select by area** (`:select area`) |
| `w` | Enter **wire** mode | **Move** selection **down** one unit |
| `e` | **Push into / edit** a cell | **Move** selection **up** one unit |
| `r` | **Rotate** the selection | **Move** selection **right** one unit |
| `q` | *(unused)* | **Move** selection **left** one unit |
| `d` | **Duplicate** the selection | **Delete** the selection (`:delete`) |
| `s` | Select net (`Select Net`) | **Select** chunk → region → net (repeat to grow) |
| `u` | Undo | Undo |
| `v` | Zoom to fit edit cell | **View** (fit cell to window) |
| `t` | Add **text** | **Move** ("translate") the selection (`:move`) |

The two that bite hardest: in MAX `d` *duplicates*, but in Magic `d` *deletes* — and in Magic *copy* is `c`. And MAX's `w` (wire) is Magic's `w` (nudge down). When in doubt, type the long command (`:copy`, `:delete`, `:wire`) instead of the macro; long commands are identical regardless of tool state.

---

## 2. The two tools' models, side by side

### MAX's model (what Lab 0 assumes)
- A **Smart Palette** down the left edge; you hover over a layer and press `p` to paint it into the current box.
- **Gcells**: parametric *cell generators*. The `fet` gcell pops up a form where you type a width, number of fingers, and contact options, and it emits correctly-formed transistor geometry. Vias are gcells too.
- Layers can be set **Visible / Lock / Hide** individually from the palette.
- **Continuous DRC** draws little white dots where rules are violated, in real time.

### Magic's model (what you'll actually use)
- A **box** and a **cursor**. The box is a rectangle you position with the mouse; almost every command acts on "the box" and/or "the selection."
- **Abstract layers ("logs"):** you do *not* draw mask layers like wells, implants, or via cuts. You draw the *conducting* layers (poly, ndiff, metal1, …) and let Magic synthesize the mask layers when it writes CIF/GDS. A transistor is just **poly painted on top of diffusion** — the overlap automatically *becomes* the transistor layer. There is **no parametric FET generator** in base Magic; you size a transistor by how big you draw it.
- **Three command styles**, all available at once:
  1. **Mouse buttons**, whose meaning depends on the active *tool* (box tool vs. wiring tool vs. netlist tool).
  2. **Macros** — single keystrokes (e.g. `s`, `a`, `c`).
  3. **Long commands** — type `:` then a command name, e.g. `:paint metal1`. Macros are just shorthand that expand into long commands. Command names can be abbreviated as long as they're unambiguous (`:he` = `:help`).
- **Continuous DRC**, also drawn as **little white dots** in real time — conceptually identical to MAX, which makes this one of the easiest things to carry over.

### The box and cursor (Magic Tutorial #1)
This replaces MAX's "draw a box by dragging Button-1."
- **Left mouse button** places the box's **lower-left** corner at the cursor.
- **Right mouse button** places the box's **upper-right** corner at the cursor.
- Hold a button down and click the *other* button to grab the box by a different corner (lets you reshape from any side).
- To make a zero-area "point" box (needed for placing point labels), set the lower-left with the left button, then click the right button at the same spot.

So "draw a box" in Lab 0 step 2 becomes: *left-click bottom-left, right-click top-right.*

---

## 3. Software setup and starting up (Lab 0 §1.2.1 → Magic)

Lab 0 has you append a `source` block to `.cshrc` and then launch with `sue` / `max`. The Magic analog depends on how Magic and the process design kit (PDK / technology file) are installed on the eecg machines, so confirm the exact path with the course staff, but the shape of it is:

- **Launch Magic** on a blank cell:
  ```
  magic
  ```
- **Launch editing a named cell** (`tut1` is a built-in library cell, great for practice):
  ```
  magic tut1
  ```
- **Force a technology file** (the equivalent of MAX's `max -tech mmi18`):
  ```
  magic -T <techname>
  ```
  Confirm the course's technology name (e.g. an SCMOS-style or a specific PDK tech). Whereas MAX used `mmi18` (a generic 0.18 µm CMOS), Magic ships with scalable-CMOS rules and most courses point it at a specific PDK.
- **Force a display driver** if Magic guesses wrong: `magic -d X11 tut1` (classic X11; reliable in the course noVNC container). On a native GPU workstation you can try `magic -d OGL` or `magic -d XR` (Cairo) for faster redraw. This is the analog of debugging MAX's display under X.

**Where errors appear:** exactly as Lab 0 advises for MAX — *watch the terminal*. The console window from which you launched Magic (or the Tcl command line in the Magic console) prints all warnings, DRC explanations, and command output. Treat it as your log file.

**Getting help (replaces MAX's Help-menu manual):**
- `:help` — one line per command (space for more, `q` to stop).
- `:help <subject>` — every command whose description contains *subject*.
- The authoritative reference is the `magic(1)` man page (also on the documentation site).

**Quitting:** `:quit` (Magic offers to save modified cells first), or the macro for it; answer `y`/`n`/`abort` as prompted.

---

## 4. Direct translation of Lab 0 §1.3.3 ("L2 – MAX Tutorial")

Lab 0's eight-step MAX warm-up, rewritten step-for-step for Magic. Run these in a scratch cell (`magic scratch` or just `magic`, then `:save scratch` later).

| Lab 0 step (MAX) | Do this in Magic |
|---|---|
| **1. Start MAX** (`max`) | `magic` (optionally `magic -T <tech>`). |
| **2. Draw a box.** | Left-click for the lower-left corner, right-click for the upper-right corner. Type `b` (`:box`) to print its exact size/position. Type `g` to show the grid and confirm the box snaps to grid points. |
| **3. Resize / move it with the middle mouse button.** | The box itself isn't "painted" yet, so move/reshape it with the **left/right buttons and corner grabs** (Section 2). Once you've *painted* material (step 4), you select it (`s`) and move it with the **middle mouse button** held down — that part carries over directly. |
| **4. Paint it as Poly** (hover poly, press `p`). | Position the box over the area, then **either** move the cursor over a red/poly splotch and **click the middle mouse button**, **or** just type `:paint poly`. (Magic has no `p`-to-paint macro; middle-click and `:paint` are the two paint mechanisms.) |
| **5. Move it, and stretch it both ways** (Edit edge / `a`). | Select it with `s`. Nudge it with `q`/`w`/`e`/`r` (left/down/up/right one unit). **Stretch** it with `:stretch` (macro `T`) or the one-unit stretch macros `Q`/`W`/`E`/`R`. ⚠️ Do **not** press `a` expecting MAX's edge-edit — in Magic `a` means *select area*. For edge-style editing Magic's preferred tools are `:stretch` and `:plow` (plowing, Section 6.10). |
| **6. Undo** (`u`). | `u` (`:undo`) — identical. Redo is `U` (`:redo`). Magic keeps ~10 levels of undo. |
| **7. Draw a metal1 wire** (`w`, left-click to bend, middle to end). | Switch to the **wiring tool**: press **space** (`:tool`). Pick the wire material/width by **left-clicking** existing metal1, or set it with `:wire type metal1 <width>`. **Right-click** to add each wire leg (each click = one Manhattan segment; this is how you "bend"). **Middle-click** drops a **contact** / changes layer. To finish, switch back with **space** or just stop right-clicking. ⚠️ Don't press `w` for "wire" — in Magic `w` nudges the selection down. The wiring tool is reached via **space**. |
| **8. Experiment.** | Same spirit. Try `:layers` to list every layer name in your technology, paint a few, and watch the white DRC dots appear/disappear. |

---

## 5. Direct translation of Lab 0 §1.3.4 ("Configuring Layers in Max")

MAX's palette lets each layer be **Visible**, **Lock**, or **Hide**. Magic controls the same ideas through the `:see` command and the edit-cell concept, but the mapping is not one-to-one, so here it is honestly:

| MAX layer state | Closest Magic equivalent | Notes / caveats |
|---|---|---|
| **Visible** (shown and editable) | Default state. `:see <layer>` turns a hidden layer back on. | All visible mask layers are editable *in the edit cell*. |
| **Hide** (invisible, to declutter) | `:see no <layer>` hides a layer; `:see <layer>` re-shows it. `:see no errors` / `:see errors` hides/shows DRC dots specifically. | This is the cleanest, most direct match — exactly the "hide other layers to inspect routing" use case from Lab 0. |
| **Lock** (visible but not modifiable) | **No exact per-layer lock.** The closest concept is the **edit cell**: only paint in the *edit cell* is modifiable; everything in non-edit subcells is visible but locked. You can also dim/undim with `:see allSame` / `:see no allSame`. | If you specifically need "see this layer but never accidentally edit it," Magic's model is to isolate it in a subcell or simply hide it while you work, then re-show it. Flag this as a genuine model difference rather than pretending a lock toggle exists. |

Practical recipe for the Lab 0 routing-inspection example ("hide everything but metal1 to see how routing went"):
```
:see no allSame        (optional: normalize brightness first)
:see no poly
:see no ndiff
:see no metal2
... (hide each layer you don't care about)
```
then `:see <layer>` to bring them back.

---

## 6. Full workflow mapping: the Micro Magic MAX Tutorial → Magic

This section walks the *Micro Magic MAX Layout System Tutorial* (the second PDF) section-by-section so the whole layout flow Lab 0 references can be reproduced in Magic. Each heading mirrors a heading in that tutorial.

### 6.1 MAX screen layout & getting help
MAX's window has a Smart Palette, cell-list boxes, a navigation window, mouse-coordinate and box-size readouts, and a DRC status box. Magic's window shows the layout, a caption with the **root cell** and **edit cell** names, and prints coordinates/box size to the console on demand (`:box`). Magic's online help is `:help` / `:help <subject>`; MAX's "About MAX / technology" check (`max -tech mmi18`) corresponds to launching with `magic -T <tech>` and confirming the caption/console reports the right technology.

### 6.2 Using gcells (creating FETs) → painting transistors
This is the **biggest conceptual change** in the whole port.

In MAX you select the `fet` gcell, type a width (e.g. 2.0 µm), set *fingers* and *contacts* in a form, click **Done**, and place a correctly-formed transistor. In Magic there is no FET form. Instead:

1. Paint the **diffusion** for the source/drain region: position the box, `:paint ndiff` (n-type) or `:paint pdiff` (p-type). For PMOS in a typical CMOS tech, the pdiff must sit inside an **nwell** — paint `:paint nwell` under it (or use the well-aware contact/transistor layers your tech defines; check `:layers`).
2. Paint **poly** across the diffusion: `:paint poly`. **The overlap automatically becomes `ntransistor` (or `ptransistor`).** Try it — paint poly on ndiff and watch the channel layer appear, exactly as Magic Tutorial #2 describes.
3. The transistor's **width** = the dimension of the channel perpendicular to current flow; its **length** = the poly dimension along current flow. You set them by *how large you paint*, not by typing into a form. Use `b`/`:box` to read off dimensions and the grid (`g`) to size precisely.
4. **Contacts** to source/drain are their own layers: `:paint ndcontact` (ndiff↔metal1), `:paint pdcontact` (pdiff↔metal1). Poly-to-metal1 is `:paint pcontact`; metal1-to-metal2 is `:paint m2contact`. (Names are technology-dependent — `:layers` is the source of truth.)

MAX's *fingers* and *merged/stacked devices* (its "2 gates × 2 µm" device) become, in Magic, simply painting multiple poly stripes over a shared diffusion, or — for repeated identical structures — painting one finger and replicating it with `:array` (Section 6.9). MAX's *vias as gcells* become Magic's contact layers, which the wiring tool can also drop automatically (Section 6.11).

### 6.3 Zooming
| MAX | Magic |
|---|---|
| `v` — zoom to fit edit cell | `v` (`:view`) — fit cell to window |
| `z` — zoom-box mode, drag a region | `z` (`:findbox zoom`) — zoom so the box fills the screen; or `B` (`:findbox`) to recenter on the box without rescaling |
| `Shift-z` — zoom out ×2 | `Z` (`:zoom 2`) zooms out ×2; `:zoom .5` zooms in ×2 |
| `j` — zoom in ×2 at cursor | use `:zoom .5` or the zoom box (`z`) |
| Navigation window | the box + `z`/`B`/`v` serve the same navigation purpose |

### 6.4 Selecting and moving layout
MAX selects by dragging Button-1 or clicking; Magic's selection is richer (Tutorial #2):
- `s` (`:select`) over paint selects a **chunk**; press `s` again *without moving* to grow to **region**, again to **net** (everything electrically connected). This single behavior also covers MAX's "Select Net" (`s`) — see 6.16.
- `a` (`:select area`) selects everything under the box. `S`/`A` *add* to the selection. `C` clears the selection. `:select area metal1` limits to a layer.
- **Move:** `t` (`:move`) drops the selection so the box's lower-left lands at the cursor — or hold the **middle mouse button** and drag (this matches MAX's Button-2 drag directly). One-unit nudges: `q w e r`. Precise: `:move up 10`.

### 6.5 Duplicating
MAX duplicates with `d`. **In Magic, copy is `c` (`:copy`); `d` deletes.** `:copy` leaves a copy at the original spot and moves the box+selection to the cursor — same idea as MAX's offset duplicate. This is the single most dangerous key collision in the port; see Section 1.

### 6.6 Stretching gcells → :stretch and plowing
MAX stretches a gcell fet by grabbing an edge (Shift-e / Button-2 drag). Magic offers two mechanisms:
- `:stretch` (macro `T`, and one-unit `Q W E R`): moves selected paint and *erases what's in its path* while *dragging connected material along behind it*. Good for shifting a wire or device edge.
- **Plowing** (`:plow <dir> [layers]`, Section 6.10): the more powerful "stretch the whole region while preserving design rules" operation — closest in spirit to MAX's idea that stretching a device keeps everything legal. Magic actively prevents DRC violations as it plows.

### 6.7 Aligning objects
MAX has an explicit **Align Objects** command (Control-a) that snaps selected objects to a shared edge using the box. Magic has no single "align" command; you align by:
- selecting the object and nudging with `q/w/e/r` or `:move <dir> <n>` to a known coordinate (read coordinates with `:box`), or
- using the grid (`g`/`G`) plus `:box` to place edges on common grid lines, or
- using `:plow` to push edges into alignment while preserving rules.
This is a workflow gap worth noting: budget a little more manual positioning than MAX's one-click align.

### 6.8 Continuous DRC
Nearly a direct carry-over — both tools show **white dots** in real time.

| MAX action | Magic equivalent |
|---|---|
| White dots appear/clear as you move geometry | Identical: Magic rechecks every paint/erase/move and shows white error paint until fixed |
| **Explain DRC under Box** (`Shift-y`) | `:drc why` (macro `y`) — put the box around the dots first |
| **DRC Results → Next Error** (step through) | `:drc find [nth]` — select a cell, then repeat (use the `.` macro to repeat the last long command) to step through errors |
| DRC error-count readout | `:drc count` — counts error areas in every cell under the box |
| (re-check imported layout) | `:drc check` — force a full recheck under the box (needed only for layout not created in Magic, or after changing rules) |
| (silence the checker) | `:drc off` / `:drc on` / `:drc catchup`; `:see no errors` hides dots without disabling checking |

Magic's checker is hierarchical: a cell must be legal alone, *and* a cell plus all descendants must be legal, *and* each array must be legal by itself. Errors from subcell interactions appear in the **parent** cell.

### 6.9 The Box and Box Mode
MAX's "Box Mode" (`b`) lets you size/place the box without selecting under it; "Box Dimensions" (`Shift-b`) types in exact origin+size. In Magic the box is *always* present and is positioned with the **left/right mouse buttons** (Section 2). To read or set it exactly:
- `b` / `:box` prints size and position.
- `:box` with arguments sets position/width/height (see the man page for the argument forms) — the analog of MAX's "origin+size" form where you typed width 4.0, height 2.0.
- Unlike MAX, dragging in Magic's box tool does **not** auto-select what's underneath; selection is a separate `s`/`a` action. (Convenient — no "don't drag a box around the whole chip" hazard.)

### 6.10 Plowing (Magic's superpower with no MAX equivalent)
Magic adds **plowing**, which MAX lacks. `:plow <direction> [layers]` treats one side of the box as a bulldozer and shoves all geometry ahead of it to the far side, *automatically maintaining design rules, connectivity, and device sizes*. Use it to compact a cell (plow a big box across it) or open space (drag a small plow). `:plow selection` moves a selection while keeping it legal. Tune with `:plow jogs`/`:plow nojogs`/`:plow straighten` and constrain with `:plow boundary`. This is the tool to reach for whenever Lab 0's MAX text says "stretch" or "move things to make room."

### 6.11 The Palette → Magic display/layer control
MAX's Smart Palette (toggle visibility, selectability, painting, colors per layer) maps onto Magic commands rather than a panel:
- **What layers exist:** `:layers`.
- **Paint / erase a layer:** `:paint <layers>` / `:erase <layers>` (comma-separated), or middle-click.
- **Visibility:** `:see <layer>` / `:see no <layer>`.
- **What's under here / what is this:** `:what` reports the layers/labels of the selection; the **Probe** equivalent is selecting repeatedly (`s` cycles through overlapping material) — see 6.17.
- **Colors/stipples:** controlled by the technology's display-style (`.dstyle`) and colormap (`.cmap`) files, not interactively per session.

### 6.12 Painting the power rails
MAX paints two 2 µm metal1 rectangles, then later changes them to metal2. In Magic:
1. Position the box where the Vdd rail goes; set it to the exact size (e.g. read with `:box`, adjust with `:box` arguments or by snapping to grid).
2. `:paint metal1` (or middle-click over blue). 
3. **Duplicate** the rail with `c` (`:copy`) and move the copy down for the GND rail (hold **Shift** while moving to keep it aligned — same as MAX's Shift-while-duplicating trick).
4. To **change a rail from metal1 to metal2** later (MAX's "boss changed the rails to M2" exercise): select the rail, then either erase metal1 and paint metal2, or — closest to MAX's "Change Layer" — there is no single change-layer button, so the idiom is `:erase metal1` then `:paint metal2` over the same box, or select + `:delete` + repaint. Connect rails to the cell with the wiring tool (6.11/6.13), starting the wire from existing metal so the width matches.

### 6.13 Wiring mode and changing layers (contacts)
This expands Lab 0 step 7. With the **wiring tool** active (press **space**):
- **Left-click** existing material to adopt its layer + width as the current wire.
- **Right-click** to lay each leg (Manhattan only; click to bend).
- **Middle-click** to drop a **contact** and *switch to the contacted layer* — this is exactly MAX's "type `d` in wire mode to drop a poly→M1 contact and move up a layer." Repeat middle-clicks to climb through metal layers.
- Force a leg's direction with `:wire horizontal` / `:wire vertical`.
- Set material with no sample present: `:wire type <layer> <width>`.
- For **bundles** of parallel wires: `:fill <dir> [layers]` sweeps existing paint across the box; `:corner <dir1> <dir2> [layers]` makes L-shaped turns; `:array 1 N` replicates a hand-placed contact across a bundle.

### 6.14 Editing a placed wire
MAX edits placed wires with Move/Stretch/Fill. Magic: select the leg (`s`) and `:stretch`/nudge (`Q W E R`), or `:fill <dir>` to extend it, or `:plow` to shove it while staying legal. Re-drawing a leg is often faster than editing — same advice the MAX tutorial gives.

### 6.15 Erasing layers
| MAX | Magic |
|---|---|
| Erase everything in box (right-click empty space) | Box over area, cursor over empty space, **middle-click**; or `:erase` (all layers under box) |
| **Selectively** erase one layer (Ctrl-Button-3 over a layer) | `^D` (control-D) erases *only the layer(s) under the cursor* from the box area; or `:erase <layer>` |
| Delete selected object | `d` (`:delete`) deletes the whole selection (paint, labels, cells) |

`^D` is the precise analog of MAX's "erase just this layer, leave the poly alone" exercise.

### 6.16 Text → labels and the Vdd!/GND! convention
MAX adds Text to nets (e.g. mark VDD/GND as *global*, In1/In2/Out as *local*, with a direction like n/e). Magic uses **labels**:
- Select the paint (`s`) or make a point box on it, then `:label <text> [position] [layer]`. Position is `north`, `e`, `ne`, `center`, etc. — the same idea as MAX's n/s/e/w text orientation.
- **Global nets** end in `!`: use **`Vdd!`** and **`GND!`** *exactly* (capitalization matters — GND! is all caps, Vdd! is not). Any `name!` is treated as globally connected everywhere, which is precisely MAX's "marked as global" behavior.
- **Local node names** have no suffix and are unique within the cell — the analog of MAX's local In1/In2/Out labels.
- For nets that leave the cell and will be auto-routed, label the *edge* of the wire with a line label, not a point (Tutorial #2, §7).

### 6.17 Selecting nets and "Probe"
MAX's `s` selects a whole net and prints its label(s) in the message area; multiple `s` cycle nets; the **Probe** (Shift-Button-1) lists everything under a point. Magic:
- `s` over paint → chunk → region → **net** (third press) selects the full electrically-connected net and, if labeled, prints the net name to the console. This *is* MAX's Select-Net, folded into the same key.
- Press `s` repeatedly to cycle through overlapping material/cells — the Probe-style "show me each thing under the cursor."
- `:what` reports layer/label info on the selection.

### 6.18 Bigger designs and hierarchy (Part 3) — instancing, arraying, edit-in-place
This is where MAX's push/pop/edit-in-place and cell-list instancing map onto Magic's edit-cell model (Tutorial #4):

| MAX concept | Magic equivalent |
|---|---|
| Drop an instance from the Cell List (Shift-Button-1) | `:getcell <name>` places an instance of `name.mag` at the box's lower-left; or select-save and re-place |
| **Array Cell…** (e.g. 4×1) / text `:array 4 1` | `:array xsize ysize` (or `:array xlo xhi ylo yhi`) — box width/height sets the element spacing. Works on cells *and* on paint/labels. |
| Select a cell (`f` / Select Cell) | `f` (`:select cell`) over the cell; press `f` again to cycle through nested instances under the cursor |
| **Show/Hide Internals** (`i` / `h`) | `^X` toggles **expand** on the selected instance; `x` (`:expand` under box) / `X` (`:unexpand`) for area-based expand/unexpand. Expanded = internals shown; unexpanded = just the bounding box + names |
| **Push into Cell / Edit** (`e`), **Pop** (`Ctrl-e`) | Switch the **edit cell**: select an instance and type `:edit` to descend into it (its paint brightens; everything else dims). This is Magic's "push/edit-in-place." There's no literal "pop" key — select the parent (or `:load <root>`, or select the root cell and `:edit`) to climb back. Edits to a cell definition appear in **all** its instances, exactly like MAX's edit-in-place affecting every NAND2 instance. |
| Dim non-edit cells toggle | `:see allSame` (show everything bright) / `:see no allSame` (dim non-edit) |
| **Save Multiple → Save Edit Cell and Descendents** | `:writeall` walks every modified cell and asks what to do (`write`/`autowrite`/`skip`/`flush`/`abort`); `:save [name]` writes the current edit cell. `:flush [cell]` discards edits and reloads from disk. |

Magic's **root cell vs. edit cell** distinction is the key mental model: the root is the top of the hierarchy in the window; the edit cell is the one definition you're currently allowed to modify. The window caption shows both. Identify instances with `:identify <newid>`; reference nodes hierarchically as `id1/id2/node`.

---

## 7. Worked example: the 2-input NAND, MAX → Magic

The MAX tutorial's spine is building a 2-input NAND (`foo` → `Nand` → `INV` → `row`). Here is the equivalent Magic procedure, condensed. (Layer names assume a generic CMOS/SCMOS-style tech; verify with `:layers`.)

1. **New cell:** `magic nand2` (or `magic`, then `:save nand2` later). Turn on the grid: `g`.
2. **NMOS pair (series, for NAND):** paint a vertical strip of `ndiff`, then paint two horizontal `poly` stripes across it. Each poly/ndiff overlap becomes an `ntransistor`. The shared diffusion between the two poly stripes is the internal series node.
   ```
   (box over diffusion region) :paint ndiff
   (box over first gate)       :paint poly
   (box over second gate)      :paint poly
   ```
3. **PMOS pair (parallel):** in an `nwell` region above, paint `pdiff` and two `poly` gates the same way; the pdiff/poly overlaps become `ptransistor`. Put both PMOS drains on the shared output diffusion.
   ```
   (box)                       :paint nwell
   (box over pdiff region)     :paint pdiff
   (gates)                     :paint poly
   ```
4. **Contacts:** drop `ndcontact`/`pdcontact` where diffusion meets metal1, and `pcontact` where the poly gates meet metal1 inputs. Easiest via the wiring tool's middle-click, or `:paint <contact>`.
5. **Power rails:** paint two `metal1` rails (Vdd top, GND bottom). Box to ~2 units tall, `:paint metal1`, then `c` to duplicate the second rail (Shift-drag to keep aligned).
6. **Wire it up:** press **space** for the wiring tool; left-click metal1 to adopt it; right-click legs to connect PMOS sources to Vdd, the bottom NMOS source to GND, the shared NMOS/PMOS drains to the output; middle-click to drop contacts where you change layers.
7. **Label the nets:** select each net and add labels:
   ```
   (select top rail)   :label Vdd! e
   (select bottom rail) :label GND! e
   (select input poly)  :label In1 n
   (select input poly)  :label In2 n
   (select output)      :label Out n
   ```
8. **Check & save:** white dots = DRC errors; box them and `:drc why`, fix, then `:drc count` to confirm zero. `:save nand2`.
9. **Build the row (hierarchy):** `magic row` (or new cell), `:getcell nand2`, then `:array 4 1` to make four abutting NAND2s; `:getcell inv` and place it to the right. Use `:edit` to descend into a cell and bring outputs to the bottom (the change propagates to all four instances). `:writeall` → save edit cell and descendants. `:quit`.

This reproduces the MAX tutorial's outcome (a NAND cell, an inverter, and a row) using only painted geometry, contacts, the wiring tool, labels, hierarchy, and continuous DRC.

---

## 8. Master command / keybinding reference (MAX → Magic)

Long commands are preferred when a macro would collide (Section 1). "Macro" = single keystroke.

| Task | MAX | Magic long command | Magic macro |
|---|---|---|---|
| Start tool | `max` | `magic` / `magic -T <tech>` | — |
| Quit | Ctrl-d / Exit | `:quit` | — |
| Help | Help menu | `:help [subject]` | — |
| Show/hide grid | — | `:grid` | `g` / `G` |
| Read box size/position | box-size readout | `:box` | `b` |
| Paint a layer | hover + `p` | `:paint <layers>` | middle-click |
| Erase all under box | right-click empty | `:erase` | middle-click on empty |
| Erase one layer only | Ctrl-Button-3 | `:erase <layer>` | `^D` |
| List layers | palette | `:layers` | — |
| Identify selection | Probe | `:what` | — |
| Undo / Redo | `u` / Shift-u | `:undo` / `:redo` | `u` / `U` |
| Select chunk/region/net | `s` | `:select` (repeat) | `s` (repeat) |
| Select by area | drag Button-1 | `:select area [layer]` | `a` |
| Add to selection | Shift-Button-1 | `:select more …` | `S` / `A` |
| Clear selection | — | `:select clear` | `C` |
| Select a cell | `f` | `:select cell` | `f` |
| Move selection | Button-2 drag | `:move [dir n]` | `t`; nudge `q w e r`; or middle-drag |
| Copy / duplicate | `d` | `:copy` | `c` |
| Delete selection | Delete | `:delete` | `d` |
| Stretch | edge / Shift-e | `:stretch [dir n]` | `T`; one-unit `Q W E R` |
| Rotate | `r` | `:clockwise [deg]` | — |
| Flip | — | `:upsidedown` / `:sideways` | — |
| Plow (no MAX equiv.) | — | `:plow <dir> [layers]` | — |
| Fill / corner bundles | Fill | `:fill <dir>` / `:corner <d1> <d2>` | — |
| Wiring tool on/off | `w` | `:tool` | **space** |
| Set wire material | left-click sample | `:wire type <layer> <w>` | left-click (in wire tool) |
| Add wire leg | left-click | (right-click in wire tool) | right-click |
| Drop contact / change layer | `d` in wire mode | (middle-click in wire tool) | middle-click |
| Add text / label | `t` | `:label <text> [pos] [layer]` | — |
| Global power nets | mark "global" | `:label Vdd!` / `:label GND!` | — |
| Zoom to fit cell | `v` | `:view` | `v` |
| Zoom to box | `z` | `:findbox zoom` | `z` |
| Zoom out ×2 | Shift-z | `:zoom 2` | `Z` |
| Recenter on box | nav window | `:findbox` | `B` |
| Instance a cell | Shift-Button-1 | `:getcell <name>` | — |
| Make/modify array | Array Cell | `:array x y` / `:array xlo xhi ylo yhi` | — |
| Expand / unexpand subcell | Show/Hide Internals (`i`/`h`) | `:expand` / `:unexpand` | `^X` (toggle), `x` / `X` |
| Switch edit cell (push) | `e` / Push into Cell | `:edit` | — |
| Pop up a level | Ctrl-e | (select parent / `:load <root>`) | — |
| Dim non-edit cells | toggle | `:see [no] allSame` | — |
| Continuous DRC dots | white dots | (always on) | — |
| Explain DRC error | Shift-y | `:drc why` | `y` |
| Step through DRC errors | DRC Results | `:drc find [nth]` | (`.` repeats) |
| Count DRC errors | error box | `:drc count` | — |
| Full re-check | — | `:drc check` | — |
| Hide/show DRC dots | — | `:see [no] errors` | — |
| Save current cell | Ctrl-s | `:save [name]` | — |
| Save all modified | Save Multiple | `:writeall` | — |
| Discard edits / reload | — | `:flush [cell]` | — |
| Load a cell | Cell List click | `:load <name>` | — |
| Set search path | — | `:path` / `:addpath <dir>` | — |

---

## 9. Where Magic has no MAX equivalent — gaps and recommendations

Three parts of the Lab 0 MAX material do not translate cleanly. Being explicit about them prevents wasted time:

1. **Parametric FET gcells (the `fet` form with width/fingers/contacts).** No equivalent in base Magic — transistors are painted, and width is set by the geometry you draw (Section 6.2). *Recommendation:* teach transistor painting directly; if the course wants parametric devices, that's a Tcl-scripted generator (Magic's Tcl interface, Magic Tcl Tutorials #1–#5) rather than a built-in form.

2. **Align Objects (one-click edge alignment).** No single command. *Recommendation:* align via grid snapping + `:move`/`q w e r` to known coordinates, or `:plow`. Plowing also subsumes much of MAX's "stretch and keep it legal" behavior and has no MAX counterpart, so it's worth introducing early.

3. **MAX-LS cross-probing with SUE (auto-layout from schematic, fly-lines, highlight-matching-net between schematic and layout).** This depends on SUE, Micro Magic's schematic tool, and has **no native Magic counterpart** — Magic is layout-only and does not pair with a schematic editor for live cross-probing or schematic-driven layout generation. *Recommendation / closest flow:*
   - Build the layout by hand (Sections 6–7).
   - **Extract** the circuit from the layout: `:extract all`, producing `.ext` files.
   - Convert with **`ext2spice`** (or `ext2sim`) to a SPICE/sim netlist.
   - **Verify against the intended schematic** using **LVS** (e.g. the `netgen` tool) — this is the rigorous replacement for "do the schematic and layout match?", which is what SUE/MAX cross-probing was checking informally.
   - **Simulate** the extracted netlist with **IRSIM** (Magic Tutorial #11) or a SPICE simulator — the analog of running the SUE simulation, now driven from the layout.
   - For interconnect, Magic's **netlist tool** (press space to cycle to it; square cursor) plus `:route` (Tutorial #7) gives netlist-driven routing — not a schematic cross-probe, but the same intent of "wire it up to match a netlist."

   In short: MAX-LS's *interactive* schematic↔layout link becomes, in the Magic world, an *extract → netlist → LVS/simulate* loop. If the course requires the live cross-probe experience specifically, that capability lives with the schematic tool, not with Magic.

---

## Appendix: sources

All Magic behavior above is drawn from the official documentation at `opencircuitdesign.com/magic/magic_docs.html` (last updated October 2025), specifically:

- *Magic Tutorial #1: Getting Started* — box/cursor model, command styles, starting up, help, quit.
- *Magic Tutorial #2: Basic Painting and Selection* — paint/erase, `^D`, undo/redo, selection (`s`/`a`/`S`/`A`/`C`), move/copy/delete/stretch/flip, labels and the `Vdd!`/`GND!` convention, layers, files (`:save`/`:writeall`/`:load`), view/zoom/grid, abstract "log" layers.
- *Magic Tutorial #3: Advanced Painting (Wiring and Plowing)* — the tool concept (space toggles tools), the wiring tool (left/right/middle buttons), `:wire`, `:fill`, `:corner`, `:array`, and plowing (`:plow`, `:straighten`).
- *Magic Tutorial #4: Cell Hierarchies* — expand/unexpand (`^X`/`x`/`X`), `:getcell`, `:array`, edit cell vs. root cell, `:edit`, `:identify`, `:flush`, `:see allSame`, search paths.
- *Magic Tutorial #6: Design-Rule Checking* — continuous DRC, white error paint, `:drc why`/`find`/`count`/`check`/`off`/`on`/`catchup`, `:see [no] errors`.

The MAX behavior referenced is from the *Micro Magic Tools MAX Layout System Tutorial v4.2* and ECE 334 Lab 0 (Revision 2025), sections 1.3.3–1.3.4.
