# CHIPcade

![Screenshot](images/screenshot.png)

CHIPcade is a terminal-driven 6502 fantasy console for building games and demos.

## What You Get

- 6502 VM with deterministic execution
- 256x192 4bpp bitmap display
- 16-color global palette (runtime editable)
- up to 64 hardware-style sprites
- single packaged 64 KB runtime image
- plain-text source in one place: `src/`
- C and ASM support in the same project
- REPL debugger (step, regs, memory, labels)
- built-in live preview window while debugging
- CLI-first workflow: scaffold, build, run, debug, package

Everything is memory-mapped: write bytes, control the machine.

## Quick Start

```sh
chipcade new my_game
chipcade build my_game
chipcade run my_game
```

## Language Options

Default scaffold is C:

```sh
chipcade new my_game
```

ASM scaffold:

```sh
chipcade new my_game --lang asm
```

You can keep both `.c` and `.asm` files in `src/`.

## Debugging

REPL + live preview (default):

```sh
chipcade repl my_game
```

Terminal-only REPL:

```sh
chipcade repl my_game --no-preview
```

## WASM

```sh
cargo run -- build my_game
CHIPCADE_BUNDLE=my_game/build/program.bin cargo run-wasm --package CHIPcade --bin CHIPcade
```
