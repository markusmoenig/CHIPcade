use crate::config::{Config, MemoryMap, PaletteConfig};
use crate::sprites::SpritePack;
use mos6502::memory::{Bus, Memory};
use std::path::Path;

pub struct Palette {
    data: Vec<u8>, // packed RGB bytes for global palette
    data_len: u16, // bytes of palette color data
    base: u16,
    end: u16,
}

pub struct SpriteRam {
    pub base: u16,
    pub end: u16,
    data: Vec<u8>, // 64 sprites * 8 bytes
}

impl SpriteRam {
    fn new(map: &MemoryMap) -> Self {
        let len = 64 * 8;
        let base = map.sprite_ram;
        let end = base.saturating_add(len as u16 - 1);
        Self {
            base,
            end,
            data: vec![0; len],
        }
    }

    fn read(&self, addr: u16) -> u8 {
        let idx = (addr - self.base) as usize;
        self.data.get(idx).copied().unwrap_or(0)
    }

    fn write(&mut self, addr: u16, value: u8) {
        let idx = (addr - self.base) as usize;
        if let Some(slot) = self.data.get_mut(idx) {
            *slot = value;
        }
    }
}

impl Palette {
    fn new(cfg: &PaletteConfig, map: &MemoryMap, initial_data: Option<&[u8]>) -> Self {
        let color_count = cfg.global_colors as usize;
        let data_len = color_count.saturating_mul(3) as u16; // 3 bytes per color (RGB)
        let base = map.palette_ram;
        let end = base.saturating_add(data_len.saturating_sub(1));

        let mut palette = Palette {
            data: vec![0; data_len as usize],
            data_len,
            base,
            end,
        };

        if let Some(bytes) = initial_data {
            let copy_len = bytes.len().min(palette.data.len());
            palette.data[..copy_len].copy_from_slice(&bytes[..copy_len]);
        } else {
            // Default palette: Sweetie 16 (GrafxKid)
            let default16: &[[u8; 3]] = &[
                [0x1a, 0x1c, 0x2c],
                [0x5d, 0x27, 0x5d],
                [0xb1, 0x3e, 0x53],
                [0xef, 0x7d, 0x57],
                [0xff, 0xcd, 0x75],
                [0xa7, 0xf0, 0x70],
                [0x38, 0xb7, 0x64],
                [0x25, 0x71, 0x79],
                [0x29, 0x36, 0x6f],
                [0x3b, 0x5d, 0xc9],
                [0x41, 0xa6, 0xf6],
                [0x73, 0xef, 0xf7],
                [0xf4, 0xf4, 0xf4],
                [0x94, 0xb0, 0xc2],
                [0x56, 0x6c, 0x86],
                [0x33, 0x3c, 0x57],
            ];

            for (i, rgb) in default16.iter().enumerate().take(color_count) {
                let idx = i * 3;
                if idx + 2 < palette.data.len() {
                    palette.data[idx] = rgb[0];
                    palette.data[idx + 1] = rgb[1];
                    palette.data[idx + 2] = rgb[2];
                }
            }
        }

        palette
    }

    fn read(&self, addr: u16) -> u8 {
        match addr {
            a if (self.base..self.base + self.data_len).contains(&a) => {
                let idx = (a - self.base) as usize;
                self.data.get(idx).copied().unwrap_or(0)
            }
            _ => 0,
        }
    }

    fn write(&mut self, addr: u16, value: u8) {
        match addr {
            a if (self.base..self.base + self.data_len).contains(&a) => {
                let idx = (a - self.base) as usize;
                if let Some(slot) = self.data.get_mut(idx) {
                    *slot = value;
                }
            }
            _ => {}
        }
    }
}

pub struct VideoRam {
    pub base: u16,
    pub end: u16,
    pub width: u32,
    pub height: u32,
    pub data: Vec<u8>,
}

impl VideoRam {
    fn new(width: u32, height: u32, base: u16) -> Self {
        // Bitmap mode: 4bpp, 2 pixels per byte
        let pixels = width.saturating_mul(height);
        let bytes = ((pixels + 1) / 2) as usize;
        let end = base.saturating_add(bytes as u16 - 1);

        VideoRam {
            base,
            end,
            width,
            height,
            data: vec![0; bytes],
        }
    }

    pub fn clear(&mut self, color_nibble: u8) {
        let packed = (color_nibble & 0x0F) | ((color_nibble & 0x0F) << 4);
        for byte in &mut self.data {
            *byte = packed;
        }
    }

    fn read(&self, addr: u16) -> u8 {
        let idx = (addr - self.base) as usize;
        self.data.get(idx).copied().unwrap_or(0)
    }

    fn write(&mut self, addr: u16, value: u8) {
        let idx = (addr - self.base) as usize;
        if let Some(slot) = self.data.get_mut(idx) {
            *slot = value;
        }
    }
}

pub struct ChipcadeBus {
    pub mem: Memory,
    pub palette: Palette,
    pub vram: VideoRam,
    pub sprite_ram: SpriteRam,
    pub sprites: SpritePack,
    io_base: u16,
    io_end: u16,
    io_regs: Vec<u8>,
}

impl ChipcadeBus {
    pub fn from_config(cfg: &Config, palette_data: Option<&[u8]>, sprites: SpritePack) -> Self {
        let map = MemoryMap::from_config(cfg);
        let palette = Palette::new(&cfg.palette, &map, palette_data);
        let vram = VideoRam::new(cfg.video.width, cfg.video.height, map.video_ram);
        let sprite_ram = SpriteRam::new(&map);

        let mut mem = Memory::new();
        if !sprites.data.is_empty() {
            let rom_base = map.rom;
            let end = rom_base as usize + sprites.data.len();
            if end <= u16::MAX as usize + 1 {
                mem.set_bytes(rom_base, &sprites.data);
            }
        }

        Self {
            mem,
            palette,
            vram,
            sprite_ram,
            sprites,
            io_base: map.io,
            io_end: map.io.saturating_add(0x00FF),
            io_regs: vec![0; 0x0100],
        }
    }

    pub fn set_input_state(&mut self, bits: u8) {
        if self.io_regs.len() < 6 {
            return;
        }
        // IO + 0: packed bitfield
        self.io_regs[0] = bits;
        // IO + 1..5: per-button byte state for C subset ergonomics
        self.io_regs[1] = if (bits & 0x01) != 0 { 1 } else { 0 }; // left
        self.io_regs[2] = if (bits & 0x02) != 0 { 1 } else { 0 }; // right
        self.io_regs[3] = if (bits & 0x04) != 0 { 1 } else { 0 }; // up
        self.io_regs[4] = if (bits & 0x08) != 0 { 1 } else { 0 }; // down
        self.io_regs[5] = if (bits & 0x10) != 0 { 1 } else { 0 }; // fire
    }

    fn palette_rgb(&self, color_index: u8) -> (u8, u8, u8) {
        let base_index = (color_index as usize).saturating_mul(3);
        if base_index + 2 >= self.palette.data.len() {
            return (0, 0, 0);
        }
        (
            self.palette.data[base_index],
            self.palette.data[base_index + 1],
            self.palette.data[base_index + 2],
        )
    }

    /// Render bitmap VRAM (4bpp, 2 pixels per byte) to RGBA8 vector using palette/map.
    pub fn render_bitmap_rgba(&self) -> Vec<u8> {
        let pixels = self.vram.width.saturating_mul(self.vram.height);
        let mut out = Vec::with_capacity((pixels * 4) as usize);

        for (i, byte) in self.vram.data.iter().enumerate() {
            let lo = byte & 0x0F;
            let hi = (byte >> 4) & 0x0F;

            let (r, g, b) = self.palette_rgb(lo);
            out.extend_from_slice(&[r, g, b, 0xFF]);

            if (i as u32) * 2 + 1 >= pixels {
                break;
            }

            let (r, g, b) = self.palette_rgb(hi);
            out.extend_from_slice(&[r, g, b, 0xFF]);
        }

        out
    }

    pub fn render_frame_rgba(&self) -> Vec<u8> {
        let mut out = self.render_bitmap_rgba();
        self.blit_sprites(&mut out);
        out
    }

    fn blit_sprites(&self, out: &mut [u8]) {
        let width = self.vram.width as i32;
        let height = self.vram.height as i32;

        for i in 0..64 {
            let base = i * 8;
            if base + 7 >= self.sprite_ram.data.len() {
                continue;
            }
            let sprite = &self.sprite_ram.data[base..base + 8];
            let x = sprite[0] as i32;
            let y = sprite[1] as i32;
            let image_index = sprite[2] as usize;
            let attrs = sprite[3];
            let c1 = sprite[4];
            let c2 = sprite[5];
            let c3 = sprite[6];

            let enable = (attrs & 0b0001_0000) != 0;
            if !enable {
                continue;
            }
            let priority_back = (attrs & 0b0000_1000) != 0;
            if priority_back {
                continue; // behind opaque background
            }
            let size_flag = (attrs & 0b0000_0001) != 0;
            let flip_x = (attrs & 0b0000_0010) != 0;
            let flip_y = (attrs & 0b0000_0100) != 0;

            let Some(img) = self.sprites.images.get(image_index) else {
                continue;
            };
            let size = if size_flag { 16 } else { 8 };
            let w = size.min(img.width as i32);
            let h = size.min(img.height as i32);
            let data = &self.sprites.data[img.offset..img.offset + img.len];

            for sy in 0..h {
                let iy = if flip_y { h - 1 - sy } else { sy };
                let dest_y = y + sy;
                if dest_y < 0 || dest_y >= height {
                    continue;
                }
                for sx in 0..w {
                    let ix = if flip_x { w - 1 - sx } else { sx };
                    let dest_x = x + sx;
                    if dest_x < 0 || dest_x >= width {
                        continue;
                    }
                    let pixel_idx = (iy * size + ix) as usize;
                    let pp = get_2bpp(data, pixel_idx);
                    let pal_index = match pp {
                        0 => continue,
                        1 => c1,
                        2 => c2,
                        3 => c3,
                        _ => continue,
                    };
                    let (r, g, b) = self.palette_rgb(pal_index);
                    let di = (dest_y as usize * width as usize + dest_x as usize) * 4;
                    if di + 3 < out.len() {
                        out[di] = r;
                        out[di + 1] = g;
                        out[di + 2] = b;
                        out[di + 3] = 0xFF;
                    }
                }
            }
        }
    }

    #[allow(dead_code)]
    pub fn save_bitmap_png<P: AsRef<Path>>(&self, path: P) -> Result<(), String> {
        let rgba = self.render_bitmap_rgba();
        let img = image::ImageBuffer::<image::Rgba<u8>, _>::from_raw(
            self.vram.width,
            self.vram.height,
            rgba,
        )
        .ok_or_else(|| "failed to build image buffer".to_owned())?;
        img.save(path)
            .map_err(|e| format!("failed to save image: {e}"))
    }
}

impl Bus for ChipcadeBus {
    fn get_byte(&mut self, address: u16) -> u8 {
        if (self.palette.base..=self.palette.end).contains(&address) {
            return self.palette.read(address);
        }
        if (self.sprite_ram.base..=self.sprite_ram.end).contains(&address) {
            return self.sprite_ram.read(address);
        }
        if (self.vram.base..=self.vram.end).contains(&address) {
            return self.vram.read(address);
        }
        if (self.io_base..=self.io_end).contains(&address) {
            let idx = (address - self.io_base) as usize;
            return self.io_regs.get(idx).copied().unwrap_or(0);
        }
        self.mem.get_byte(address)
    }

    fn set_byte(&mut self, address: u16, value: u8) {
        if (self.palette.base..=self.palette.end).contains(&address) {
            self.palette.write(address, value);
            return;
        }
        if (self.sprite_ram.base..=self.sprite_ram.end).contains(&address) {
            self.sprite_ram.write(address, value);
            return;
        }
        if (self.vram.base..=self.vram.end).contains(&address) {
            self.vram.write(address, value);
            return;
        }
        if (self.io_base..=self.io_end).contains(&address) {
            let idx = (address - self.io_base) as usize;
            if let Some(slot) = self.io_regs.get_mut(idx) {
                *slot = value;
            }
            return;
        }
        self.mem.set_byte(address, value);
    }
}

fn get_2bpp(data: &[u8], pixel_index: usize) -> u8 {
    let byte_index = pixel_index / 4;
    let shift = 6 - (pixel_index % 4) * 2;
    data.get(byte_index)
        .map(|b| (b >> shift) & 0b11)
        .unwrap_or(0)
}
