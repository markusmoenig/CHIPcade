use crate::config::{Config, MemoryMap, PaletteConfig};
use mos6502::memory::{Bus, Memory};
use std::path::Path;

pub struct Palette {
    data: Vec<u8>, // packed RGB bytes for global palette
    data_len: u16, // bytes of palette color data
    base: u16,
    end: u16,
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
}

impl ChipcadeBus {
    pub fn from_config(cfg: &Config, palette_data: Option<&[u8]>) -> Self {
        let map = MemoryMap::from_config(cfg);
        let palette = Palette::new(&cfg.palette, &map, palette_data);
        let vram = VideoRam::new(cfg.video.width, cfg.video.height, map.video_ram);

        Self {
            mem: Memory::new(),
            palette,
            vram,
        }
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
