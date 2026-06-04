# XSchem quick reference (ECE334)

Official manual: <https://xschem.sourceforge.io/stefan/xschem_man/xschem_man.html>

## Critical collisions (if you used SUE before)

| Key | SUE | XSchem |
|-----|-----|--------|
| `d` | duplicate | **deselect** |
| `c` | (Ctrl-c copy) | **copy** |
| `r` | rotate | **rectangle** |
| `p` | plot waveform | **polygon** |
| `v` | zoom fit | vertical move |
| `h` | run HSPICE | horizontal move |
| `k` | cross-probe MAX | **highlight net** |

## Launch

```bash
xschem                    # new
xschem mycell.sch         # open
```

Help: `?` or `/` — keybinding overlay.

## Place & edit

| Action | Key / menu |
|--------|------------|
| Insert symbol | **`Shift-I`** (persistent browser; best on laptops without Insert) |
| Insert symbol | **Tools → Insert symbol** (menu; always works) |
| Insert symbol | `Insert` (one-shot); `Shift-Insert` or `Ctrl-i` = persistent dialog (version-dependent) |

Laptops often have no **Insert** key — use **`Shift-I`** or the menu, not Insert alone.
| Select | left-click; add `Shift`-click |
| Select all | `Ctrl-a` |
| Move | `m` → click to place |
| Copy | `c` (not `d`) |
| Delete | `Delete` |
| Properties | `q` |
| Rotate | `Shift-R` |
| Flip H / V | `Shift-F` / `Shift-V` |
| Wire | `w`; snap-start `Shift-W`; end on pin; `Esc` abort |
| Net label | `lab_pin.sym` → `q` → `lab=name` |
| Text | `t` |
| Undo / redo | `u` / `Shift-U` |

## Zoom & pan

| Action | Key |
|--------|-----|
| Zoom in / out | `Shift-Z` / `Ctrl-z` or scroll |
| Fit | `f` |
| Zoom box | `z` + right-drag |
| Pan | `Space` or middle-drag |
| Finer grid | `g` / coarser `G` |

## Hierarchy

| Action | Key |
|--------|-----|
| Descend schematic | select instance → `e` |
| Back to parent | `Ctrl-e` |
| Make symbol from ports | `a` |
| Descend symbol view | `i` |

## Simulation (ngspice)

| Action | Key / UI |
|--------|----------|
| Netlist | `n` |
| Simulate | `s` or toolbar **Simulate** |
| Waveforms | toolbar **Waves** → gtkwave |
| Highlight net | select wire → `k`; clear `Shift-K` |

Put `.tran`, `.dc`, `.lib` / `.include` in `code_shown.sym` or `netlist.sym` on the schematic.

## SKY130 sizing (ECE334)

**Transistors:** use `sky130_fd_pr__nfet_01v8` and `sky130_fd_pr__pfet_01v8` from the PDK library (`$PDK_ROOT/sky130A/libs.tech/xschem`, loaded after `.designinit`). Do **not** use generic `devices/nmos4.sym` / `pmos4.sym` for course simulations.

Edit instance with `q`: `w=1u`, `l=0.5u` — **always use `u` suffix** for both W and L.

**Passive / supplies:** `vsource`, `gnd`, `vdd`, `code_shown`, ports, etc. still come from `devices/`.
