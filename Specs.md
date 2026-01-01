**Calculating static RAM layout**

Static RAM usage for 256x192 at 4bpp is 24,576 bytes for VRAM plus 112 bytes for palette and map (palette at 0x2c00 length 96, map at 0x2d00 length 16). VRAM spans 0x2000–0x7fff without overlapping ROM at 0x8000.
</thinking>

With the current config (bitmap mode, 256x192, 32 global colors, 16 visible):

- VRAM (bitmap, 4bpp = 2 pixels per byte): `256 * 192 / 2 = 24,576` bytes. In your map that spans `0x2000..=0x7fff`.
- Palette data (32 colors × 3 bytes RGB): `32 * 3 = 96` bytes at `0x2c00..=0x2c5f`.
- Palette map (16 visible entries, 1 byte each): `16` bytes at `0x2d00..=0x2d0f`.

Total “static” video/palette footprint: `24,576 + 96 + 16 = 24,688` bytes.
