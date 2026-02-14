# CHIPcade C Language + ASM Interop

This document describes the currently implemented C subset and how it interoperates with 6502 assembly in CHIPcade.

## Build Model

- If at least one `.c` file exists under `src/` (recursive), CHIPcade transpiles all of them to 6502 assembly and assembles them.
- If `src/main.asm` also exists, it is assembled together with the transpiled C output.
- If no C sources exist, the build uses only the ASM path.

### C File Discovery

- Sources are discovered recursively under `src/`.
- Compilation order is deterministic: `src/main.c` first (if present), then remaining files by path.

## Types

Only 8-bit integer types are user-visible:

- `unsigned char`
- `signed char`

No user-visible 16-bit integer type is supported.

## Declarations

### Global

- Supported: `unsigned char name;`, `signed char name;`
- Not supported: global initializers (`unsigned char x = 1;`)

### Local (function scope)

- Supported:
  - `unsigned char name;`
  - `signed char name;`
  - with initializer: `unsigned char i = 0;`

Locals are allocated from zero page by the transpiler.

## Functions

### Definitions

- Only zero-argument `void` functions are supported.
- Function opening brace must be on the same line.

Example:

```c
void Update() {
    // ...
}
```

### Prototypes

- Supported: `void Foo();`

## Statements

Supported statement forms:

- Assignment: `x = expr;`
- Memory write: `[addr_expr] = expr;`
- Memory read: `x = [addr_expr];`
- Memory write: `mem[addr_expr] = expr;`
- Memory read: `x = mem[addr_expr];`
- Memory write: `data[addr_expr] = expr;`
- Memory read: `x = data[addr_expr];`
- Sprite byte write/read: `sprite_data[i] = expr;`, `x = sprite_data[i];`
- Sprite field write/read: `sprite[n].field = expr;`, `x = sprite[n].field;`
- Increment/decrement: `x++;`, `x--;`
- Call: `Foo();`
- Return: `return;`
- `if (...) { ... }`
- `if (...) { ... } else { ... }`
- `while (...) { ... }`
- `for (init; cond; step) { ... }`

## Expressions

Supported expression grammar is intentionally small:

- Terms: 8-bit literal, variable, constant
- Operators:
  - arithmetic: `+`, `-`
  - bitwise: `&`, `|`, `^`, `~`
  - shifts: `<<`, `>>`
- Parentheses are supported in expressions.
- 8-bit semantics (results are byte-sized in generated code).

No `*`, `/`, logical operators (`&&`, `||`, `!`) yet.

## Conditions

Supported comparison operators:

- `==`, `!=`, `<`, `<=`, `>`, `>=`

A condition is a single comparison (`term op term`).
A condition compares two expressions (`expr op expr`).
Compound boolean expressions (`&&`, `||`, `!`) are not supported yet.

## Memory Access (`[...]`, `mem[]`, `data[]`, `sprite_data[]`)

All of these read/write one byte:

- `[addr_expr]`
- `mem[addr_expr]`
- `data[addr_expr]`
- `sprite_data[i]` (maps to `SPRITE_RAM + i`)

Supported address forms:

- `[BASE]`
- `[BASE + OFFSET]`

Where:

- `BASE` is a 16-bit constant or literal (for example `VRAM`, `SPRITE_RAM`, `0x2000`, `$2000`)
- `OFFSET` is an 8-bit term (literal/constant/variable)

`mem[]` and `data[]` are aliases (both are pseudo memory views for editor/highlighter compatibility).

## Sprite Structured Access (`sprite[]`)

CHIPcade also provides a sprite-oriented syntax sugar:

- `sprite[n].x`
- `sprite[n].y`
- `sprite[n].tile`
- `sprite[n].flags`
- `sprite[n].c0` / `sprite[n].color0`
- `sprite[n].c1` / `sprite[n].color1`
- `sprite[n].c2` / `sprite[n].color2`
- `sprite[n].reserved`

Semantics:

- `n` is sprite index `0..63`
- each sprite entry is 8 bytes in sprite RAM
- field offsets:
  - `x` = `+0`
  - `y` = `+1`
  - `tile` = `+2`
  - `flags` = `+3`
  - `c0` = `+4`
  - `c1` = `+5`
  - `c2` = `+6`
  - `reserved` = `+7`

`c0/c1/c2` are palette indices into the global palette (3 sprite colors + transparency).

## Constants and Headers

CHIPcade auto-generates both:

- `src/include/chipcade.inc` (ASM view)
- `src/include/chipcade.h` (C view)

Both are generated from the same symbol source (system constants + sprite constants), so values stay in sync.

## C / ASM Interop

Interop is label-based and works both directions when both sources are built together.

### C calling ASM

If ASM defines a label as a callable routine:

```asm
AsmHook:
    RTS
```

C can call it:

```c
AsmHook();
```

### ASM calling C

If C defines:

```c
void CFunc() {
    // ...
}
```

ASM can call:

```asm
    JSR CFunc
```

## Special `Init` / `Update` Behavior

- `Init` and `Update` are treated as frame entry routines by CHIPcade.
- Transpiled C emits `BRK` at function end (or on `return;`) for `Init`/`Update`.
- Other C functions emit `RTS`.

## Syntax Constraints (Current)

- Control-flow opening brace must be on the same line:
  - `if (...) {`
  - `while (...) {`
  - `for (...) {`
- `else` must be `else {` (or `else{`) on its own line after the closing `}` of the `if` block.
- C preprocessor directives are not implemented; `#include` lines are ignored by the transpiler.

## Current Limitations

Not implemented yet:

- Function parameters
- Non-`void` return values
- General arrays/structs/pointers (except `sprite[n].field` sugar)
- Global initializers
- `switch`
- `break` / `continue`
- Full C preprocessor/macro expansion
