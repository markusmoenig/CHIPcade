use crate::config::{Config, MemoryMap, PaletteConfig};
use mos6502::memory::{Bus, Memory};
use std::path::Path;

pub struct Palette {
    data: Vec<u8>, // packed RGB bytes for global palette
    map: [u8; 16], // 16 visible colors, each byte is index into global palette (0..global_colors-1)
    data_len: u16, // bytes of palette color data
    base: u16,
    end: u16,
    map_base: u16,
    map_end: u16,
}

impl Palette {
    fn new(cfg: &PaletteConfig, map: &MemoryMap) -> Self {
        let color_count = cfg.global_colors as usize;
        let data_len = color_count.saturating_mul(3) as u16; // 3 bytes per color (RGB)
        let base = map.palette_ram;
        let map_base = map.palette_map;
        let map_end = map_base.saturating_add(16 - 1);
        let end = map_end;

        let mut palette = Palette {
            data: vec![0; data_len as usize],
            map: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
            data_len,
            base,
            end,
            map_base,
            map_end,
        };

        // https://lospec.com/palette-list/endesga-32
        // Hardcoded default palette: Endesga 32 (RGB)
        let endesga32: &[[u8; 3]] = &[
            [0xbe, 0x4a, 0x2f],
            [0xd7, 0x76, 0x43],
            [0xea, 0xd4, 0xaa],
            [0xe4, 0xa6, 0x72],
            [0xb8, 0x6f, 0x50],
            [0x73, 0x3e, 0x39],
            [0x3e, 0x27, 0x31],
            [0xa2, 0x26, 0x33],
            [0xe4, 0x3b, 0x44],
            [0xf7, 0x76, 0x22],
            [0xfe, 0xae, 0x34],
            [0xfe, 0xe7, 0x61],
            [0x63, 0xc7, 0x4d],
            [0x3e, 0x89, 0x48],
            [0x26, 0x5c, 0x42],
            [0x19, 0x3c, 0x3e],
            [0x12, 0x4e, 0x89],
            [0x00, 0x99, 0xdb],
            [0x2c, 0xe8, 0xf5],
            [0xff, 0xff, 0xff],
            [0xc0, 0xcb, 0xdc],
            [0x8b, 0x9b, 0xb4],
            [0x5a, 0x69, 0x88],
            [0x3a, 0x44, 0x66],
            [0x26, 0x2b, 0x44],
            [0x18, 0x14, 0x25],
            [0xff, 0x00, 0x44],
            [0x68, 0x38, 0x6c],
            [0xb5, 0x50, 0x88],
            [0xf6, 0x75, 0x7a],
            [0xe8, 0xb7, 0x96],
            [0xc2, 0x85, 0x69],
        ];

        for (i, rgb) in endesga32.iter().enumerate().take(color_count) {
            let idx = i * 3;
            if idx + 2 < palette.data.len() {
                palette.data[idx] = rgb[0];
                palette.data[idx + 1] = rgb[1];
                palette.data[idx + 2] = rgb[2];
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
            a if (self.map_base..=self.map_end).contains(&a) => {
                let idx = (a - self.map_base) as usize;
                self.map.get(idx).copied().unwrap_or(0)
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
            a if (self.map_base..=self.map_end).contains(&a) => {
                let idx = (a - self.map_base) as usize;
                if let Some(slot) = self.map.get_mut(idx) {
                    *slot = value % (self.data_len / 3) as u8;
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
}

impl ChipcadeBus {
    pub fn from_config(cfg: &Config) -> Self {
        let map = MemoryMap::from_config(cfg);
        let palette = Palette::new(&cfg.palette, &map);
        let vram = VideoRam::new(cfg.video.width, cfg.video.height, map.video_ram);

        Self {
            mem: Memory::new(),
            palette,
            vram,
        }
    }

    fn palette_rgb(&self, map_index: u8) -> (u8, u8, u8) {
        let base_index = (map_index as usize).saturating_mul(3);
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

            let lo_map = self.palette.map[lo as usize];
            let (r, g, b) = self.palette_rgb(lo_map);
            out.extend_from_slice(&[r, g, b, 0xFF]);

            if (i as u32) * 2 + 1 >= pixels {
                break;
            }

            let hi_map = self.palette.map[hi as usize];
            let (r, g, b) = self.palette_rgb(hi_map);
            out.extend_from_slice(&[r, g, b, 0xFF]);
        }

        out
    }

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
        if (self.vram.base..=self.vram.end).contains(&address) {
            return self.vram.read(address);
        }
        self.mem.get_byte(address)
    }

    fn set_byte(&mut self, address: u16, value: u8) {
        if (self.palette.base..=self.palette.end).contains(&address) {
            self.palette.write(address, value);
            return;
        }
        if (self.vram.base..=self.vram.end).contains(&address) {
            self.vram.write(address, value);
            return;
        }
        self.mem.set_byte(address, value);
    }
}
