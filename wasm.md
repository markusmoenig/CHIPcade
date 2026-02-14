# WASM Quickstart

CHIPcade uses the same packaged 64 KB runtime image (`program.bin`) for browser builds.

## Start

From the repository root:

```sh
cargo run -- build test
CHIPCADE_BUNDLE=test/build/program.bin cargo run-wasm --package CHIPcade --bin CHIPcade
```

Open the local URL printed by `cargo run-wasm`.

## Notes

- `CHIPCADE_BUNDLE` selects which built project image is embedded for the WASM run.
- If omitted, the build fallback is crate-root `build/program.bin`.
- For build-only (no dev server):

```sh
CHIPCADE_BUNDLE=test/build/program.bin cargo run-wasm --package CHIPcade --bin CHIPcade --build-only
```
