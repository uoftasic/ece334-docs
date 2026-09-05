# Magic quick reference

Official tutorials: <http://opencircuitdesign.com/magic/tutorials/>

## Launch

```bash
. /foss/designs/common/.designinit
cd /foss/designs/lab2_layout
echo "source \$PDK_ROOT/sky130A/libs.tech/magic/sky130A.magicrc" > .magicrc
magic -d X11 -T sky130A mycell.mag &
```

Use the **X11** driver. The OpenGL and Cairo drivers can fail with a pixmap
allocation error inside the container.

Magic opens two windows: the **layout** window, and **tkcon**, a Tcl console
where you type commands. Anything below written as a command goes in tkcon.

## The box

Magic has no free-floating cursor selection. Almost every operation acts on
**the box**, a rectangle you position first.

| Action | How |
|--------|-----|
| Place the box | left-click one corner, right-click the other |
| Set it exactly | `box <llx> <lly> <urx> <ury>` |
| Read it back | `box values` |
| Use microns | `box 0um 0um 2um 1um` |

## Painting

| Action | How |
|--------|-----|
| Paint a layer into the box | middle-click the layer, or `paint <layer>` |
| Erase a layer from the box | `erase <layer>` |
| Erase everything in the box | `erase` |
| Undo / redo | `u` / `Shift-U` |

Common SKY130 layers: `ndiffusion`, `pdiffusion`, `poly`, `nwell`, `ndcontact`,
`pdcontact`, `polycontact`, `m1`, `m2`, `via1`.

Magic infers devices from overlap. Paint `poly` across `ndiffusion` and the
overlap becomes an `nmos`; you never place a transistor as an object.

## View

| Action | Key / command |
|--------|---------------|
| Zoom to fit | `v` |
| Zoom in / out | `z` / `Shift-Z` |
| Pan | arrow keys |
| Expand subcells | `x` (`Shift-X` to collapse) |
| Show what is under the box | `what` |

An unexpanded subcell draws as an empty rectangle with its name. If a layout
looks blank, expand it.

## Selecting and moving

| Action | How |
|--------|-----|
| Select what is under the box | `s` |
| Select an entire cell | `S` |
| Select a whole connected net | `select net` |
| Move the selection | `m` plus a direction, or arrow keys |
| Copy | `c` |
| Delete | `d` |

## Labels

```
label VDD          # label the box on the current layer
label GND!         # a trailing ! makes the name global
```

Label every port. LVS matches by name: an unlabelled or misspelled port is the
usual reason Netgen reports a mismatch on an otherwise correct layout.

## DRC

DRC runs continuously. White dots mark violations, and the toolbar shows a live
count.

| Command | Meaning |
|---------|---------|
| `drc check` | re-run over the whole cell |
| `drc count` | how many violations |
| `drc why` | explain the violations under the box |
| `drc catchup` | finish any pending background checking |

Target zero before extracting. `drc why` names the rule, which is faster than
guessing at spacing.

## Extraction, LVS, PEX

```
extract all                 # build the .ext files
ext2spice lvs               # device-level netlist, no parasitics
ext2spice -o cell.lvs.spice

extract all                 # for PEX, extract again
ext2spice cthresh 0         # keep every coupling capacitance
ext2spice -o cell.pex.spice
```

`cthresh 0` is what makes the difference between the pre- and post-PEX
netlists: without it, capacitances below the threshold are discarded.

Compare against a schematic with Netgen:

```bash
# Prefer the course wrapper -- it handles the netgen quirk below for you:
/foss/designs/scripts/run_lvs.sh cell.lvs.spice xschem/cell_lvs.sch

# Raw netgen, if you want it. Strip XSchem's commented top-level block first:
awk '/^[*][*][.]subckt/{s=1;next} /^[*][*][.]ends/{s=0;next} !s' \
    cell_sch.spice > cell_sch.netgen.spice
netgen -batch lvs "cell.lvs.spice cell" "cell_sch.netgen.spice cell" \
       $PDK_ROOT/sky130A/libs.tech/netgen/sky130A_setup.tcl
```

A clean run reports **Circuits match uniquely.**

## Batch use

```bash
magic -dnull -noconsole -T sky130A <<'EOF'
load mycell
drc check
puts "errors: [drc list count total]"
quit -noprompt
EOF
```

Magic reads commands on stdin in GUI mode too, which is the reliable way to
script it:

```bash
( echo "view"; echo "drc check"; sleep 200 ) | magic -d X11 -T sky130A mycell.mag &
```

## Devices from the PDK

```
magic::gencell sky130::sky130_fd_pr__nfet_01v8 myfet w 1 l 0.5
```

This drops a parameterised device **as a subcell**, so it appears as a named
rectangle until you expand it with `x`. For Lab 0 and Lab 2 you paint the
layers yourself instead.

## Common failures

| Symptom | Cause |
|---------|-------|
| Layout looks empty, one named rectangle | An unexpanded subcell. Press `x`. |
| `Failed to load technology` | No `.magicrc` in the working directory. |
| Netgen reports a mismatch on correct-looking layout | Missing or misspelled port labels. |
| Nothing happens when you paint | The box is empty or off-screen. `box values` to check. |
