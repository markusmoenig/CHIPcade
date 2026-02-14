# WASM Quickstart

CHIPcade uses the same packaged 64 KB runtime image (`program.bin`) for browser builds.

## Start

From your project directory:

```sh
cargo install cargo-run-wasm
chipcade wasm
```

Open the local URL printed by `cargo run-wasm`.

## Notes

- `chipcade wasm` builds the project first, then launches `cargo run-wasm`.
- For build-only (no dev server):

```sh
chipcade wasm --build-only
```
