# CHIPcade

![Screenshot](images/screenshot.png)

**CHIPcade — 6502 Fantasy Console**  
*Inspired by the C64 era. Built for fun, not quirks.*

CHIPcade is a **fantasy console** built around a clean, approachable 6502-based virtual machine.  
It captures the feel of early home computers without inheriting their historical baggage.

CHIPcade is about **making games and demos**, not fighting hardware edge cases.

---

## What is CHIPcade?

CHIPcade is a deliberately simple virtual machine with:

- A **6502 CPU** at a fixed, predictable speed
- A **256×192 bitmap display**
- A **fixed-size 16-color global palette** (user-editable)
- **Up to 64 hardware-style sprites** (8×8 or 16×16, 3 colors + transparency)
- A **simple, documented memory map**
- A **deterministic 64 KB system image**

Everything is memory-mapped.  
There are no APIs, no draw calls, no hidden state.

If you can write to memory, you can control the machine.

---

## What CHIPcade is

- A **fantasy console**, not an emulator
- A **6502-based programming environment**
- A platform for **small games, demos, and experiments**
- **Hardware-minded**, but intentionally simplified
- **Deterministic and reproducible**
- **Tooling-first**, with a modern editor and CLI
- **Cross-platform** by design

---

## What CHIPcade is not

- Not a Commodore 64 emulator
- Not cycle-exact or raster-accurate
- No badlines, VIC-II quirks, or undocumented behavior
- No reliance on timing hacks
- No attempt at full historical compatibility

If you want exact C64 behavior, excellent tools already exist.  
CHIPcade deliberately takes a different path.

---

## Graphics & palette

CHIPcade uses a **single global palette of 16 colors**.

- The palette size is fixed
- The palette contents are fully editable
- Colors are stored in memory and can be changed at runtime

This allows palette animation, fades, and color cycling while keeping assets consistent and simple.

---

## How programs run

A CHIPcade program is a **single 64 KB binary image** containing:

- Zero page
- Stack
- RAM
- VRAM
- Palette
- Sprite RAM
- I/O registers
- ROM (code + assets)

When the machine starts:

- `Init` runs once
- `Update` runs once per frame
- Everything else is just memory changing over time

---

## Tooling

CHIPcade projects are managed through a **command-line tool** that handles file creation, building, and running projects.  
Source files are plain text and can be edited in **any editor**, or opened in the **integrated editor** with a visual debugger, memory inspectors, and frame-by-frame execution.  
The workflow stays simple: edit files, build a 64 KB image, run it — locally, in the editor, or in the browser via WASM.

--- 

## Status

CHIPcade is under active development.

---

### In one sentence

> **CHIPcade is the joy of 8-bit development, without the pain of real hardware quirks.**
