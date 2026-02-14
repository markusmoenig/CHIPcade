## Packaging / Runtime Images

CHIPcade builds a single flat 64 KB image at `build/program.bin`. This file contains everything needed to run on desktop or WASM—no sidecars.

### Binary Layout (64 KB)

- `0x0000 .. 0x00FF` : Zero page (reserved)
- `0x0100 .. 0x01FF` : Stack
- `0x0200 ..`        : Program code/data at RAM load address
- `0x2000 ..`        : Video RAM (size = `width * height / 2` bytes for 4bpp)
- `video_end ..`     : Palette RAM (`global_colors * 3` bytes)
- `palette_end ..`   : Sprite RAM (`64 * 8 = 0x200` bytes)
- `sprite_end ..`    : IO (placeholder, `0x100` bytes)
- `io_end ..`        : Sprite graphics in ROM (packed 2bpp)
- `0xF000 ..`        : Header (metadata, see below)
- `0xF000+N ..`      : Padding/unused up to 64 KB

Default addresses for `256x192`, `16` colors:
- `VRAM = 0x2000`
- `PALETTE = 0x8000`
- `SPRITE_RAM = 0x8030`
- `IO = 0x8230`
- `ROM = 0x8330`

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
2) `build.rs` ensures a crate-root `build/program.bin` exists for compile-time embedding:
   - uses `CHIPCADE_BUNDLE` if set
   - otherwise uses crate-root `build/program.bin` if present
   - otherwise writes a placeholder 64K image with a `CHPC` header

### Runtime (desktop / wasm)
- Desktop `chipcade run` builds and runs from in-memory artifacts for the selected project.
- `build/program.bin` remains the canonical packaged runtime image.
- WASM runtime is currently disabled during the winit/softbuffer migration.

### Notes
- Only `Init`/`Update` are considered for the entry point (no `Start`).
- To embed a specific bundle at compile time, set `CHIPCADE_BUNDLE=/path/to/project/build/program.bin`.
