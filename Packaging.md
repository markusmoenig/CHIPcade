## Packaging / Runtime Images

CHIPcade builds a single flat 64 KB image at `build/program.bin`. This file contains everything needed to run on desktop or WASM—no sidecars.

### Binary Layout (64 KB)

- `0x0000 .. 0x00FF` : Zero page (reserved)
- `0x0100 .. 0x01FF` : Stack
- `0x0200 ..`        : Program code/data at the RAM load address (from `chipcade.toml`)
- `0x2000 ..`        : Video RAM (size = width * height / 2 bytes for 4bpp)
- `0x8000 ..`        : Palette RAM (16 colors * 3 bytes = 48 bytes by default)
- `0x8030 ..`        : Sprite RAM (64 sprites * 8 bytes each = 0x200 bytes)
- `0x8230 ..`        : IO (placeholder, 0x100 bytes)
- `0x8330 ..`        : Sprite graphics in ROM (packed 2bpp)
- `0xF000 ..`        : Header (metadata, see below)
- `0xF000+N ..`      : Padding/unused up to 64 KB

### Header at 0xF000

```
offset size  description
0x000  4    magic "CHPC"
0x004  4    meta_len (u32 LE)
0x008  N    meta payload (bincode BuildMeta)
```

`BuildMeta` (bincode-serialized):
- `config` (machine/video config)
- `entry_point` (Init/Update)
- `labels` map (name -> u16)
- `palette_bytes` (global palette bytes)
- `sprite_base` (u16: start of sprite graphics in the image)
- `program_len` (usize)
- `sprite_images` (Vec<SpriteImage>: name, index, width/height, colors, offset, len)

### Build Steps
1) `cargo run -- build [project]`  
   - Assembles sources, packs sprites, writes palette/sprites/program into a 64K image, embeds header at `0xF000`, and writes `build/program.bin` relative to the project root.
2) `build.rs` copies the latest bundle into the crate-root `build/program.bin` (or uses `CHIPCADE_BUNDLE` if set). This ensures `include_bytes!("../build/program.bin")` works for WASM.

### Runtime (desktop / wasm)
- Desktop run uses the in-memory artifacts (from build) and also prefers loading from `build/program.bin` if present.
- WASM uses `include_bytes!("../build/program.bin")`, parses the header at `0xF000`, reconstructs the program/palette/sprites, and runs the player. Default scale is `3×` for parity with native.

### Notes
- Only `Init`/`Update` are considered for the entry point (no `Start`).
- If you build a different project, set `CHIPCADE_BUNDLE=/path/to/project/build/program.bin` before building WASM to embed that bundle.
