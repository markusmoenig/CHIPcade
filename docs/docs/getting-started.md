# Getting Started

## Install Rust

CHIPcade is distributed through Cargo, so install Rust first:

- https://www.rust-lang.org/tools/install

## Install

```sh
cargo install chipcade
```

## Create a Project

Default scaffold (C):

```sh
chipcade new my_game
```

ASM scaffold:

```sh
chipcade new my_game --lang asm
```

## Build and Run

```sh
cd my_game
chipcade build
chipcade run
```

## Debug (REPL + Preview)

```sh
chipcade repl
```

Terminal-only REPL:

```sh
chipcade repl --no-preview
```

Inside the REPL, typical flow is:

```text
debug        start/reset debug session
step [n]     execute n instructions
run [n]      run continuously (or up to n steps)
pause        pause active run
regs         show CPU registers
line         show current C/source line + ASM context
mem <a> [n]  dump memory at address a
labels [p]   list labels (optional prefix filter p)
stop         stop current debug session
help         show all commands
```

Example session:

```text
CHIPcade> debug
CHIPcade> step 20
CHIPcade> mem SPRITE_RAM 16
CHIPcade> run
CHIPcade> pause
CHIPcade> regs
```

## WASM

From your project folder:

```sh
cd my_game
cargo install cargo-run-wasm
chipcade wasm
```
