| Setting | Value |
|---------|-------|
| Process (PDK) | `sky130A` |
| Supply voltage | **1.8 V** |
| Teaching channel length | **L = 0.5 µm** |
| NMOS / PMOS devices | `sky130_fd_pr__nfet_01v8` / `sky130_fd_pr__pfet_01v8` |
| Unit inverter | Wn = 1, Wp = 3 |
| NAND2 | Wn = 2 (series pair), Wp = 3 (parallel pair) |
| Extraction device (Lab 1 P2) | W = 10, L = 2 |

Widths and lengths are entered as **unitless microns**: `W=1`, `L=0.5`. A `u`
suffix means metres, lands outside every model bin, and makes ngspice report
*"could not find a valid modelname"*.
