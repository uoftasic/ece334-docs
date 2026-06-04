# ECE334 — Digital Electronics

Welcome to the laboratory component of ECE334. Over the term you will move from the equations
and timing diagrams of the lecture hall into the hands-on craft of designing, simulating, and
laying out real CMOS circuits — building and characterizing inverters, logic gates, a flip-flop,
and a 6T SRAM cell on the open-source **SKY130** process.

## Start here

➡️ **[Setting up your lab environment](getting-started/index.md)** — install Docker, download the
workbench, and launch the EDA desktop in your browser. New to the tools or the command line? This
guide assumes no prior experience.

## The toolchain

| Tool | What it does for you |
|------|----------------------|
| **XSchem** | Draw schematics and launch simulations |
| **ngspice** | The SPICE simulator that computes how your circuit behaves |
| **Magic** | Draw the physical layout (the actual mask geometry) |
| **Netgen** | Check that your layout matches your schematic (LVS) |

You install just **one** program — Docker — which provides a ready-made container with every tool,
the SKY130 technology, and all settings inside it.

## The labs

| Lab | What you will explore |
|-----|------------------------|
| **[Lab 0 — XSchem & Magic intro](labs/lab0/index.md)** | Get comfortable with the tools, gently and without marks |
| **[Lab 1 — Basic SPICE](labs/lab1/index.md)** | RC circuit, device-parameter extraction, the CMOS inverter, a pulse generator |
| **[Lab 2 — NAND layout, LVS, PEX](labs/lab2/index.md)** | Layout → DRC → LVS → post-layout simulation with parasitics |
| **[Lab 3 — Digital circuits](labs/lab3/index.md)** | Timing of complex gates and a transmission-gate D flip-flop |
| **[Lab 4 — DFF & 6T SRAM](labs/lab4/index.md)** | Characterize the flip-flop and design a 6T SRAM cell |

Keep the [XSchem](reference/xschem-cheatsheet.md) and [Magic](reference/magic-cheatsheet.md)
cheatsheets open in a tab while you work.
