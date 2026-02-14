# Language Guide

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

```asm6502
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

```asm6502
    JSR CFunc
```

## End-to-End C Example

This is a realistic `src/main.c` that initializes one sprite, reads input from IO, moves the sprite, and flashes colors on collision.

```c
#include "include/chipcade.h"

unsigned char player_x;
unsigned char player_y;
unsigned char enemy_x;
unsigned char enemy_y;
unsigned char flash_ticks;

void ResetRound() {
    player_x = 0x20;
    player_y = 0x70;
    enemy_x = 0xA0;
    enemy_y = 0x70;
    flash_ticks = 0;
}

void DrawSprites() {
    sprite[0].x = player_x;
    sprite[0].y = player_y;
    sprite[0].tile = SPR_CHIPCADE;
    sprite[0].flags = 0x10;   // enable + 8x8
    sprite[0].c0 = 12;
    sprite[0].c1 = 7;
    sprite[0].c2 = 15;

    sprite[1].x = enemy_x;
    sprite[1].y = enemy_y;
    sprite[1].tile = SPR_CHIPCADE;
    sprite[1].flags = 0x10;
    sprite[1].c0 = 3;
    sprite[1].c1 = 10;
    sprite[1].c2 = 1;
}

void UpdatePlayer() {
    if (mem[IO_LEFT] != 0) {
        if (player_x > 0x08) {
            player_x--;
        }
    }
    if (mem[IO_RIGHT] != 0) {
        if (player_x < 0xF0) {
            player_x++;
        }
    }
    if (mem[IO_UP] != 0) {
        if (player_y > 0x08) {
            player_y--;
        }
    }
    if (mem[IO_DOWN] != 0) {
        if (player_y < 0xB0) {
            player_y++;
        }
    }
}

void UpdateEnemy() {
    if (enemy_x < player_x) {
        enemy_x++;
    } else {
        if (enemy_x > player_x) {
            enemy_x--;
        }
    }
    if (enemy_y < player_y) {
        enemy_y++;
    } else {
        if (enemy_y > player_y) {
            enemy_y--;
        }
    }
}

void CheckCollision() {
    unsigned char dx;
    unsigned char dy;

    if (player_x > enemy_x) {
        dx = player_x - enemy_x;
    } else {
        dx = enemy_x - player_x;
    }

    if (player_y > enemy_y) {
        dy = player_y - enemy_y;
    } else {
        dy = enemy_y - player_y;
    }

    if (dx < 8) {
        if (dy < 8) {
            flash_ticks = 20;
            ResetRound();
        }
    }
}

void Init() {
    ResetRound();
    DrawSprites();
}

void Update() {
    UpdatePlayer();
    UpdateEnemy();
    CheckCollision();

    if (flash_ticks != 0) {
        flash_ticks--;
        mem[PALETTE_RAM + 3] = 0xFF;
        mem[PALETTE_RAM + 4] = 0x00;
        mem[PALETTE_RAM + 5] = 0x00;
    }

    DrawSprites();
}
```

## End-to-End ASM Example

Same idea in ASM, split across files. This demonstrates shared symbols from `chipcade.inc` and calling helper routines from another ASM module.

`src/main.asm`

```asm6502
    .include "include/chipcade.inc"
    .include "utils.asm"

; Zero-page state (manual addresses)
.const PLAYER_X $40
.const PLAYER_Y $41
.const ENEMY_X  $42
.const ENEMY_Y  $43

Init:
    JSR ResetRound
    JSR DrawSprites
    BRK

Update:
    JSR ReadInputAndMovePlayer
    JSR MoveEnemyTowardPlayer
    JSR DrawSprites
    BRK

ReadInputAndMovePlayer:
    LDA IO_LEFT
    BEQ check_right
    LDA PLAYER_X
    CMP #$08
    BCC check_right
    DEC PLAYER_X
check_right:
    LDA IO_RIGHT
    BEQ check_up
    LDA PLAYER_X
    CMP #$F0
    BCS check_up
    INC PLAYER_X
check_up:
    LDA IO_UP
    BEQ check_down
    LDA PLAYER_Y
    CMP #$08
    BCC check_down
    DEC PLAYER_Y
check_down:
    LDA IO_DOWN
    BEQ done
    LDA PLAYER_Y
    CMP #$B0
    BCS done
    INC PLAYER_Y
done:
    RTS

DrawSprites:
    ; sprite 0 = player
    LDA PLAYER_X
    STA SPRITE_RAM + 0
    LDA PLAYER_Y
    STA SPRITE_RAM + 1
    LDA #SPR_CHIPCADE
    STA SPRITE_RAM + 2
    LDA #$10
    STA SPRITE_RAM + 3
    LDA #12
    STA SPRITE_RAM + 4
    LDA #7
    STA SPRITE_RAM + 5
    LDA #15
    STA SPRITE_RAM + 6

    ; sprite 1 = enemy
    LDA ENEMY_X
    STA SPRITE_RAM + 8
    LDA ENEMY_Y
    STA SPRITE_RAM + 9
    LDA #SPR_CHIPCADE
    STA SPRITE_RAM + 10
    LDA #$10
    STA SPRITE_RAM + 11
    LDA #3
    STA SPRITE_RAM + 12
    LDA #10
    STA SPRITE_RAM + 13
    LDA #1
    STA SPRITE_RAM + 14
    RTS
```

`src/utils.asm`

```asm6502
    .include "include/chipcade.inc"

ResetRound:
    LDA #$20
    STA PLAYER_X
    LDA #$70
    STA PLAYER_Y
    LDA #$A0
    STA ENEMY_X
    LDA #$70
    STA ENEMY_Y
    RTS

MoveEnemyTowardPlayer:
    LDA ENEMY_X
    CMP PLAYER_X
    BEQ x_done
    BCC x_inc
    DEC ENEMY_X
    JMP x_done
x_inc:
    INC ENEMY_X
x_done:
    LDA ENEMY_Y
    CMP PLAYER_Y
    BEQ y_done
    BCC y_inc
    DEC ENEMY_Y
    JMP y_done
y_inc:
    INC ENEMY_Y
y_done:
    RTS
```

## C + ASM Interop Example

You can freely call across language boundaries:

`src/game.c`

```c
void AsmFlashPalette();

void TriggerFx() {
    AsmFlashPalette();
}
```

`src/fx.asm`

```asm6502
    .include "include/chipcade.inc"
    .global AsmFlashPalette

AsmFlashPalette:
    LDA #$FF
    STA PALETTE_RAM + 3
    LDA #$FF
    STA PALETTE_RAM + 4
    LDA #$FF
    STA PALETTE_RAM + 5
    RTS
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
- ASM directives are intentionally minimal: use `.include` and `.const`; CA65-style directives like `.segment`, `.res`, `.global`, `.import` are not supported.

## Current Limitations

Not implemented yet:

- Function parameters
- Non-`void` return values
- General arrays/structs/pointers (except `sprite[n].field` sugar)
- Global initializers
- `switch`
- `break` / `continue`
- Full C preprocessor/macro expansion
