# Setting up your lab environment

## What this page does

Sets up the software you need for every lab in this course. You install one
program — Docker — and it brings the rest with it.

You do steps 1 and 2 once. After that, starting the lab environment is one
command.

No prior experience with circuit design software or the command line is
assumed. Lab 0 introduces the tools themselves and carries no marks.

### A note on the tools we use

The toolchain is open source and runs on Windows, macOS (Intel or Apple Silicon), and Linux. You will use four tools against the **SKY130** open process design kit.

| Tool | What it does for you |
|------|----------------------|
| **XSchem** | Draw schematics and launch simulations |
| **ngspice** | The SPICE simulator that computes how your circuit behaves |
| **Magic** | Draw the physical layout (the actual mask geometry) |
| **Netgen** | Check that your layout matches your schematic (LVS) |

Here is the key idea that makes setup painless: **you do not install these four tools individually.** Instead you install *one* program — **Docker** — which downloads a single pre-built "container" that already has every tool, the SKY130 technology, and all the settings inside it. Think of the container as a complete, ready-made workbench that appears on your screen. You launch it, and everything is simply *there*.

---

## Setting up — a step-by-step guide for every operating system

There are four steps, and you only do Steps 1–2 **once**:

1. **Install Docker Desktop** (the program that runs the workbench).
2. **Download the course files** (the `ece334-labs` workbench repository).
3. **Start the environment** (one command or one double-click).
4. **Open it in your browser** and run a quick check.

Find your operating system below and follow it top to bottom. If a step does not behave as described, ask course staff.

> Throughout this guide, text shown `like this` is something you type or click. Lines beginning with `#` are explanatory notes, not something you type.

---

### Step 1 — Install Docker Desktop

Docker is the single piece of software you install yourself. It is free for educational use.

=== "Windows"

    1. Docker on Windows needs a Microsoft component called **WSL 2**. The easiest way to get it: open the **Start menu**, type `PowerShell`, right-click **Windows PowerShell**, and choose **Run as administrator**. In the blue window, type this and press Enter:
       ```powershell
       wsl --install
       ```
       When it finishes, **restart your computer**. (If you already have WSL, this does nothing harmful.)
    2. Download **Docker Desktop for Windows** from <https://www.docker.com/products/docker-desktop/> and run the installer, accepting the default options (keep "Use WSL 2" checked).
    3. After installing, launch **Docker Desktop** from the Start menu. Wait until the little whale icon near your clock stops animating — that means Docker is **running**. Docker Desktop must be running whenever you do lab work.

=== "macOS"

    1. Go to <https://www.docker.com/products/docker-desktop/> and download Docker Desktop. **Choose the right version for your Mac:**
        - If your Mac is from **2020 or later**, it is almost certainly **Apple Silicon** (M1/M2/M3…). Pick the **Apple Silicon** download.
        - Older Macs use **Intel**. Pick the **Intel chip** download.
        - *Not sure?* Click the Apple menu → **About This Mac**. If it says "Chip: Apple M…", you have Apple Silicon; if it says "Processor: Intel…", you have Intel.
    2. Open the downloaded `.dmg` file and drag **Docker** into your **Applications** folder.
    3. Launch **Docker** from Applications. Approve any permission prompt. Wait until the whale icon in the top menu bar is steady — Docker is now running. Keep it running during lab work.

=== "Linux"

    1. Install **Docker Engine** using your distribution's instructions: <https://docs.docker.com/engine/install/>.
    2. So you can run Docker without `sudo`, add yourself to the `docker` group, then log out and back in:
       ```bash
       sudo usermod -aG docker $USER
       ```
    3. Confirm it works:
       ```bash
       docker run hello-world
       ```

> **How much disk space?** The toolchain downloads about **4 GB** the first time, and you'll want roughly **20 GB free** overall. The first launch will take a while depending on your internet speed — this is normal, and it only happens once.

---

### Step 2 — Download the course files

You need a copy of the **`ece334-labs`** workbench repository on your computer. There are two ways; **pick whichever sounds easier to you.**

#### Option A — Download a ZIP (simplest, no extra software)

1. On the `ece334-labs` repository web page, click the green **Code** button, then **Download ZIP**.
2. **Unzip it** to a place you'll remember — your **Desktop** or **Documents** folder is perfect.
    - *Windows:* right-click the downloaded `.zip` → **Extract All…**
    - *macOS:* double-click the `.zip`.
    - *Linux:* right-click → **Extract**, or `unzip` in a terminal.
3. You'll now have a folder (for example, `ece334-labs`). Remember where it is — you'll point to it in Step 3.

#### Option B — Use Git (handy if you already have it, or want easy updates)

If you have Git installed (Windows users can get it from <https://git-scm.com/download/win>, which also gives you a terminal called **Git Bash**):

```bash
git clone <ece334-labs-repo-url>
cd ece334-labs
```

Don't worry if Option B looks unfamiliar — Option A works exactly as well for this course.

---

### Step 3 — Start the environment

Make sure **Docker Desktop is running** first (the steady whale icon). Then follow your operating system.

=== "Windows"

    1. Open the course folder you unzipped in **File Explorer**.
    2. Go into the `scripts` folder.
    3. **Double-click `start_vnc.bat`.** A black window will open and begin downloading the toolchain the first time (this can take several minutes — please be patient and leave it open).

       *If double-clicking is blocked or closes instantly,* open **PowerShell**, then type `cd ` (with a space), drag the course folder onto the window so its path fills in, press Enter, and run:
       ```powershell
       .\scripts\start_vnc.bat
       ```

    > Windows note: the files ending in `.sh` are for macOS and Linux and will **not** work on Windows. Always use **`start_vnc.bat`** on Windows.

=== "macOS"

    1. Open the **Terminal** app (press `Cmd-Space`, type `Terminal`, press Enter).
    2. Type `cd ` (with a space), then **drag the course folder from Finder onto the Terminal window** — its location fills in automatically. Press Enter.
    3. Start the environment:
       ```bash
       ./scripts/start_vnc.sh
       ```
       The first run downloads the toolchain and may take several minutes. If macOS says the script is not executable, run `chmod +x scripts/*.sh` once and try again.

=== "Linux"

    1. Open a terminal in the course folder.
    2. Run:
       ```bash
       ./scripts/start_vnc.sh
       ```

When the command finishes, it will print the browser address for the **EDA desktop** (noVNC).

If the default port is already in use on your machine, set `HOST_PORT` before starting (for example `HOST_PORT=8081 ./scripts/start_vnc.sh` on Mac/Linux).

The EDA desktop opens at a **1280×800** resolution by default (scaled to your browser window). To change it, set `VNC_RESOLUTION` before starting (for example `VNC_RESOLUTION=1920x1080 ./scripts/start_vnc.sh` on Mac/Linux).

---

### Step 4 — Open your workbench and check that it works

The **EDA desktop** runs on your own computer — nothing is uploaded to the cloud.

| What | URL | When you need it |
|------|-----|------------------|
| **EDA desktop** (XSchem, Magic) | **http://localhost** | Drawing schematics and layout inside a Linux desktop in your browser |

The lab manuals and reference cheatsheets are **here on this website** — keep them open in a separate browser tab while you work.

1. Open the **EDA desktop** at **http://localhost**. You'll be asked for a password. The default is:

   `abc123`

2. A complete Linux desktop appears **inside your browser tab**. This is your workbench, and from here on **everyone uses the exact same environment**, no matter what laptop they started from. 🎉

   **Copy/paste:** click the **clipboard** icon in the noVNC sidebar (left edge of the desktop view), paste your text there, then click **Send**; or use **Ctrl+Shift+V** to paste from your computer into the VM.

3. Inside that desktop, open its **terminal** (there's a terminal icon on the desktop or taskbar). Type these three lines, pressing Enter after each:

   ```bash
   . /foss/designs/common/.designinit     # loads the course settings + SKY130 technology
   /foss/designs/scripts/smoke_test.sh     # a quick health check of all the tools
   cd /foss/designs/lab0_setup             # step into Lab 0 to begin
   ```

The middle line — the **smoke test** — is your friend. Any time something feels off later, run it again: it confirms that XSchem, Magic, ngspice, and the SKY130 technology are all present, and tells you plainly if anything is missing.

> **Will I lose my work when I close the browser or shut down?** No. Everything you create is saved inside the course folder *on your own computer* (it appears as `/foss/designs` inside the desktop). Your designs persist between sessions. You can stop and restart the environment as often as you like.

---

## Other ways to run it (optional)

The browser method above (called **noVNC**) is recommended for everyone and needs no extra setup. These alternatives give you the *same* tools and files, in case you prefer them:

| Mode | How to start it | Good for |
|------|-----------------|----------|
| **noVNC (recommended)** | `start_vnc.bat` (Windows) or `./scripts/start_vnc.sh` (Mac/Linux) | Everyone — EDA desktop at `http://localhost` |
| **VS Code devcontainer** | Open the folder in VS Code → *Reopen in Container* | Students who already use VS Code |
| **GitHub Codespaces** | Open the repo in Codespaces (runs in the cloud) | Anyone who cannot install Docker at all |
| **Local X11** *(advanced)* | `./scripts/start_x.sh` | Linux users wanting native windows |

If you do not have a reliable laptop of your own, the course can host this environment for you so you only need a browser — ask course staff. **No student should ever be blocked by hardware**; if you are, please tell us.

---

## How the labs are organized

Work through the labs in order. **Lab 0 comes first and is required** (though ungraded) — it is where you get comfortable with the tools before any marks are involved.

| Lab | Manual | What you will explore |
|-----|--------|------------------------|
| **0** | [Lab 0](../labs/lab0/index.md) | Setting up the environment and learning XSchem & Magic, gently and without marks |
| **1** | [Lab 1](../labs/lab1/index.md) | Basic SPICE: an RC circuit, extracting device parameters yourself, the CMOS inverter, and a pulse generator |
| **2** | [Lab 2](../labs/lab2/index.md) | Drawing a NAND gate layout, checking design rules, verifying it against your schematic, and simulating with real parasitics |
| **3** | [Lab 3](../labs/lab3/index.md) | Timing of complex logic gates and a transmission-gate D flip-flop |
| **4** | [Lab 4](../labs/lab4/index.md) | Characterizing the flip-flop and designing a 6T SRAM cell |

The matching starter files for each lab (SPICE decks, helper scripts) live in the corresponding folder of the **`ece334-labs`** workbench repository, mounted at `/foss/designs/<lab>` inside the container.

Keep the two **tool cheatsheets** open in a browser tab while you work:

- [XSchem cheatsheet](../reference/xschem-cheatsheet.md)
- [Magic cheatsheet](../reference/magic-cheatsheet.md)

---

## Conventions used throughout the course

So that your hand calculations and your simulations speak the same language, every lab uses the same settings. Keep these nearby:

| Setting | Value | Why it matters |
|---------|-------|----------------|
| Process (PDK) | `sky130A` | The technology all your devices come from |
| Supply voltage | **1.8 V** | Used for every rail, pulse height, and sweep |
| Teaching channel length | **L = 0.5 µm** | Keeps the simple square-law hand model reasonably accurate |
| NMOS / PMOS devices | `sky130_fd_pr__nfet_01v8` / `pfet_01v8` | These are subcircuits — use the **`x`** prefix if you ever hand-write a netlist |
| Unit inverter (Lab 3 reference) | Wn = 1 µm, Wp = 3 µm at L = 0.5 µm | The baseline against which gates are sized |

One idea threads through the whole course: rather than handing you device constants, **you will measure µCox and the threshold voltage yourself in Lab 1** (from a simple diode-connected transistor) and then use *your own* numbers in the hand calculations for Labs 1 and 3. Measuring the parameters you reason with is a small but genuinely professional skill — and it makes the comparison between theory and simulation far more meaningful.

---

## When something goes wrong (and it will — that's normal)

A few habits save time:

- **Read the terminal.** XSchem, Magic, and ngspice print their warnings and errors there. The messages are usually descriptive enough to point you at the cause — treat the terminal as your log file.
- **Re-run the smoke test** (`/foss/designs/scripts/smoke_test.sh`) after any change; it separates "is the tool set up correctly?" from "is my circuit correct?".
- **Is Docker Desktop running?** On Windows and macOS, the most common "nothing happens" cause is that the whale icon isn't active yet. Start Docker Desktop, wait for it to settle, then try again.
- **Windows: `$'\r': command not found` when sourcing `.designinit`?** Git for Windows often checks files out with CRLF line endings (`core.autocrlf=true` is the default). The Linux container needs LF. After you **restart** the environment with `start_vnc.bat`, the startup script auto-fixes this. If you already have the container running, run once in the EDA terminal: `sed -i 's/\\r$//' /foss/designs/common/.designinit && . /foss/designs/common/.designinit`. To fix Git on your machine for future clones: `git config --global core.autocrlf false`, then in the repo run `git add --renormalize .` and `git checkout -- .` (or clone again).
- **Desktop too large or tiny in the browser?** Restart with a different resolution, e.g. `VNC_RESOLUTION=1366x768 ./scripts/start_vnc.sh`. The session also scales to fit the browser tab automatically.
- **Copy/paste not working?** Use the clipboard panel in the noVNC sidebar (not only Ctrl+C inside the VM). Restart the environment if needed — startup enables clipboard sync automatically.
- **Magic crashes with `BadAlloc` / `X_CreatePixmap`?** Use the course command `magic -d X11 -T sky130A` (or the `magic130` alias after sourcing `.designinit`). Do not use `-d XR` in the browser desktop unless you know your container has enough shared memory.
- **No Insert key in XSchem?** Use **`Shift-I`** or **Tools → Insert symbol** to open the component browser (see Lab 0).
- **Ask early.** Tool problems, as opposed to circuit-design questions, are usually quick for course staff to resolve.

---

## Reference

- [Lab 2 in depth](../labs/lab2/lvs-pex.md) — the layout → DRC → LVS → PEX flow
- [XSchem cheatsheet](../reference/xschem-cheatsheet.md) and [Magic cheatsheet](../reference/magic-cheatsheet.md)

Teaching assistants and IT staff setting up the environment should refer to the **`ece334-instructor`** repository, and to [Building the docs](../maintainers/building.md) for the documentation toolchain.

**Reproducibility note:** the Docker image tag is pinned in `.devcontainer/devcontainer.json` and `scripts/start_*.sh` (`DOCKER_TAG`, default `2026.04` — confirm before the term), and the PDK build is recorded in `pdk/volare.lock` after the pilot run. This ensures every student works in an identical, unchanging environment all term. The default browser password (`abc123`) can be changed by setting `VNC_PW` before launching.

---

Once the smoke test passes, start [Lab 0](../labs/lab0/index.md).
