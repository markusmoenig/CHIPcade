# CHIPcade

This repo vendors a fork of the 6502 assembler from https://github.com/bgourlie/asm6502 (version 0.1.2, MIT) under `src/asm6502` and uses it as the crate `chipcade_asm` so the project ships as a single package. We patched the parser (`src/asm6502/src/parser/mod.rs`) so implied instructions no longer consume the trailing newline; you can now write `CLC` on its own line without requiring an extra blank line before the next instruction. The original MIT license is preserved in `src/asm6502/LICENSE`.
