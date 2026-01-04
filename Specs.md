**Chipcade Architecture**

- CPU: 6502 @ 1 MHz (reference)
- Video: 256×192 bitmap, 4bpp (2 pixels/byte)
- Palette: 16 global colors (3 bytes each) at `0x8000..=0x802F`

**Sprites**

- Count: up to 64
- Sizes: 8×8 or 16×16
- Colors: 3 colors + transparent
- Palette: shared global 16-color palette
- Background mode: irrelevant (sprites always work)

**Sprite Layout (8 bytes per sprite)**

- +0: u8 X position (0–255)
- +1: u8 Y position (0–191)
- +2: u8 Sprite image index
- +3: u8 Attributes
- +4: u8 Color 1 (global palette index 1–15)
- +5: u8 Color 2 (global palette index 1–15)
- +6: u8 Color 3 (global palette index 1–15)
- +7: u8 Reserved (future / padding)

Attributes (bitfield):

- bit 0: SIZE (0 = 8×8, 1 = 16×16)
- bit 1: FLIP_X
- bit 2: FLIP_Y
- bit 3: PRIORITY (0 = in front, 1 = behind background)
- bit 4: ENABLE (0 = hidden, 1 = visible)
- bits 5–7: reserved

**Sprite Graphics**

- Stored in ROM
- 2 bits per pixel:
  - 00 = transparent
  - 01 = Color 1
  - 10 = Color 2
  - 11 = Color 3
- Size/bytes:
  - 8×8  -> 16 bytes
  - 16×16 -> 64 bytes

**Sprite Source Format (.spr)**

Sprites are authored as plain text `.spr` files and compiled into binary sprite graphics stored in ROM.
The `.spr` files are the *source of truth*; image formats like PNG are optional helpers only.

**File Location**

```
sprites/
├─ player.spr
├─ enemy.spr
└─ bullet.spr
```

**Format Overview**

Example: `player.spr`

```
# CHIPcade sprite
size 16x16
colors 12 7 15

pixels
................
....111111......
...12222221.....
..1233333321....
..1233333321....
...12222221.....
....111111......
................
................
....111111......
...12222221.....
..1233333321....
..1233333321....
...12222221.....
....111111......
................
```

**Header Fields**

- `size WxH`
  Sprite size. Must be `8x8` or `16x16`.

- `colors C1 C2 C3`
  Three global palette indices (1–15) used by this sprite.
  These map to Color 1, Color 2, and Color 3 in sprite RAM.

**Pixel Encoding**

Characters in the `pixels` section map directly to the 2bpp sprite encoding:

- `.` → transparent (`00`)
- `1` → Color 1 (`01`)
- `2` → Color 2 (`10`)
- `3` → Color 3 (`11`)

Each row must contain exactly `W` characters, and the number of rows must equal `H`.

**Compilation**

During build, all `.spr` files are:

1. Parsed and validated (size, color count, row width, characters)
2. Packed into 2bpp binary sprite data
3. Written sequentially into sprite graphics ROM
4. Assigned sprite image indices (0, 1, 2, …)

A corresponding include file is generated in include / chipcade.inc.

```
SPR_PLAYER = 0
SPR_ENEMY  = 1
SPR_BULLET = 2
```

These constants are used when writing to `SPRITE_RAM + 2` (sprite image index).

---

**Memory Map (default)**

- Zero page: `0x0000..=0x00FF`
- Stack: `0x0100..=0x01FF`
- System RAM: `0x0200..=0x1FFF`
- VRAM (bitmap 4bpp): `0x2000..=0x7FFF` (24,576 bytes)
- Palette data (16×RGB): `0x8000..=0x802F` (48 bytes)
- Sprite RAM: `0x8030..=0x822F` (0x200 bytes, 64 sprites × 8 bytes)
- I/O: `0x8230..=0x832F` (0x100 bytes placeholder)
- ROM: `0x8330..` upward

**System Constants**

- `VRAM` = `0x2000`, `VRAM_SIZE` = `24,576`
- `PALETTE` = `0x8000`
- `SPRITE_RAM` = `0x8030`
- `IO` = `0x8130`
- `ROM` = `0x8230`
