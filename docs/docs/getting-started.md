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
chipcade build my_game
chipcade run my_game
```

## Debug (REPL + Preview)

```sh
chipcade repl my_game
```

Terminal-only REPL:

```sh
chipcade repl my_game --no-preview
```

## WASM

From repository root:

```sh
cargo run -- build my_game
CHIPCADE_BUNDLE=my_game/build/program.bin cargo run-wasm --package CHIPcade --bin CHIPcade
```
