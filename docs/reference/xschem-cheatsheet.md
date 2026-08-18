# XSchem quick reference

Official manual:
<https://xschem.sourceforge.io/stefan/xschem_man/xschem_man.html>

Press `?` inside XSchem for the built-in keybinding overlay.

## Launch

```bash
. /foss/designs/common/.designinit   # once per terminal
xschem                               # empty canvas
xschem mycell.sch                    # open a schematic
xschem mycell.sym                    # open a symbol
```

`.designinit` writes `~/.xschem/xschemrc`, which is where XSchem actually looks
for configuration. There is no `XSCHEMRC` environment variable — setting one has
no effect.

## View

| Action | Key |
|--------|-----|
| Zoom to fit | `f` |
| Zoom in / out | `Shift-Z` / `Ctrl-Z`, or scroll |
| Pan | hold `Space` and drag, or middle-drag |
| Swap schematic ↔ symbol view | `c` |
| Push into a symbol's schematic | `e` |
| Pop back out | `Ctrl-E` |

## Place and edit

| Action | Key |
|--------|-----|
| Insert symbol (persistent browser) | `Shift-I` |
| Insert symbol (menu, always works) | **Tools → Insert symbol** |
| Draw a wire | `w` |
| Select | click; `Shift`-click to add |
| Select all | `Ctrl-A` |
| Move selection | `m` |
| Copy selection | `c` |
| Delete selection | `Delete` |
| Edit properties of selection | `q` |
| Rotate / flip | `r` / `x` |
| Undo / redo | `u` / `Shift-U` |
| Abort the current mode | `Ctrl-C` |
| Save | `Ctrl-S` |

Most laptops have no `Insert` key. Use `Shift-I` or the menu.

## Connectivity

A port or wire end shows its state:

| Symbol | Meaning |
|--------|---------|
| hollow square | unconnected |
| nothing | one connection |
| solid square | two or more connections |

Wires that merely cross do **not** connect. They connect only where one wire's
endpoint lands on the other, or on a port.

You can also connect by name: place a `lab_pin` carrying the same label on two
nets and they become one net. The course cells use this for gate and supply
connections, which keeps the drawing readable.

## Naming nets

Ports and globals are the only things you must name; XSchem invents `net_1`,
`net_2` … for the rest.

| Icon | Use |
|------|-----|
| `devices/ipin.sym` | input port |
| `devices/opin.sym` | output port |
| `devices/iopin.sym` | bidirectional port, e.g. supplies |
| `devices/lab_pin.sym` | name a net without making it a port |

The order in which `ipin`/`opin`/`iopin` appear in a schematic sets the port
order of the generated `.subckt`, and it must match the order of the `B` lines
in the matching `.sym`. Mismatch wires the wrong nets silently.

## Transistors

Place `sky130_fd_pr/nfet_01v8.sym` or `pfet_01v8.sym` and set only `W` and `L`.

```
W=1  L=0.5
```

Unitless microns. A `u` suffix means metres, misses every model bin, and gives
*"could not find a valid modelname"*.

The symbol computes `ad`, `as`, `pd`, `ps`, `nrd`, `nrs` — the source and drain
diffusion geometry — from `W` and `nf`. Those junction capacitances are part of
the delay, which is why a hand-written deck that omits them runs fast.

Pin order on both device symbols is **D G S B**.

## Simulate

| Action | How |
|--------|-----|
| Netlist | `Shift-N` |
| Netlist and run | `h`, or the **Netlist & Simulate** button |
| Plot a net | select the wire, press `p` |
| Annotate operating point | the **Annotate OP** button |

Netlists and results land in `/foss/designs/.xschem/simulations`. In a notebook,
`sim.raw("name.raw")` resolves against that directory.

## Batch use

```bash
xschem -n -s -q -x -o OUTDIR file.sch     # netlist only, no GUI
xschem --command "TCL" file.sch           # run a Tcl command at startup
```

XSchem's exit status is **not** a reliable success signal in batch: a schematic
carrying a multi-command `.control` block exits 10 while writing a perfectly
good netlist. Check the generated deck instead, and grep it for `IS MISSING`.

## Symbol libraries

`XSCHEM_LIBRARY_PATH` is one flat namespace searched in order, and the first
match wins. The course adds, in order: `common`, `common/xschem`, then each
`labN/xschem`. Cells shared between labs therefore live in `common/xschem` — a
name reused by two labs would resolve to whichever sorts first.

A symbol's schematic is looked up **beside the symbol** before the library path
is consulted.

## Common failures

| Symptom | Cause |
|---------|-------|
| `IS MISSING !!!!` in the netlist, no devices | XSchem cannot find the symbol. Re-run `.designinit`. |
| `could not find a valid modelname` | A `u` suffix on `W` or `L`. |
| `write: no writable vector found` | The nets named in `.control` do not exist — usually an empty DUT. |
| Ports wired to the wrong nets | `.sym` pin order does not match the schematic's `ipin`/`opin`/`iopin` order. |
