# Magic quick reference (ECE334)

Official tutorials: <http://opencircuitdesign.com/magic/tutorials.html>

## Critical collisions (if you used MAX before)

| Key | MAX | Magic |
|-----|-----|-------|
| `p` | paint layer | (use middle-click or `:paint`) |
| `a` | edit edge | **select area** |
| `w` | wire mode | **nudge down** |
| `d` | duplicate | **delete** |
| `c` | — | **copy** |
| `t` | text | **move** |

When unsure, type the long command: `:copy`, `:delete`, `:wire`.

## Launch

```bash
magic -d X11 -T sky130A mycell.mag
```

The course standardizes on the **X11** display driver because it is reliable in the noVNC Docker desktop. On a native Linux workstation with a GPU you may prefer `magic -d OGL` or `magic -d XR` (Cairo) for faster redraw on very large layouts; those drivers can fail in the browser desktop with `BadAlloc` on `X_CreatePixmap`.

Help: `:help` / `:help <topic>`. Quit: `:quit`.

## Box (always visible)

- **Left click** — lower-left corner
- **Right click** — upper-right corner
- `b` / `:box` — read or set size

## Paint & erase

| Action | Command |
|--------|---------|
| Paint | middle-click on layer, or `:paint <layer>` |
| Erase all in box | middle-click empty, or `:erase` |
| Erase one layer | `^D` or `:erase <layer>` |
| List layers | `:layers` |

**Transistor:** paint `ndiff`/`pdiff`, then `poly` across it — overlap becomes `ntransistor`/`ptransistor`. PMOS needs `nwell` under `pdiff`.

**Contacts:** `ndcontact`, `pdcontact`, `pcontact`, `m2contact` (verify with `:layers`).

## Select & move

| Action | Macro |
|--------|-------|
| Select chunk → region → net | `s` (repeat) |
| Select area | `a` |
| Add to selection | `S` / `A` |
| Clear | `C` |
| Move | `t` or middle-drag; nudge `q w e r` |
| Copy | `c` |
| Delete | `d` |
| Stretch | `T` or `Q W E R` |
| Plow | `:plow <dir>` |

## Wiring tool

Press **space** (`:tool`) to cycle tools → wiring tool.

- **Left-click** sample — adopt layer/width
- **Right-click** — add leg (bend)
- **Middle-click** — contact / change layer
- `:wire type metal1 <width>`

## Labels & power

```
:label Vdd! e
:label GND! e
:label In1 n
```

Global nets use trailing `!`.

## DRC

| Action | Command |
|--------|---------|
| Explain errors in box | `y` / `:drc why` |
| Count errors | `:drc count` |
| Step errors | `:drc find` (`.` repeats) |
| Full recheck | `:drc check` |
| Hide dots | `:see no errors` |

White dots = violations (same idea as MAX).

## Layers visibility

```
:see no poly
:see metal1
:see no allSame    # dim non-edit cells
```

No exact per-layer **lock** — use edit-cell isolation or hide layers while editing.

## Hierarchy

| Action | Command |
|--------|---------|
| Place instance | `:getcell <name>` |
| Array | `:array 4 1` |
| Edit subcell | select instance → `:edit` |
| Expand view | `^X` toggle |
| Save all | `:writeall` |

## Extract (Lab 2+)

```
extract all
ext2spice lvs
ext2spice -o cell.lvs.spice
```

PEX: `ext2spice cthresh 0` then `ext2spice -o cell.pex.spice`
