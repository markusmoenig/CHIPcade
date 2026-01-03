use serde::Deserialize;
use std::fs;

#[derive(Deserialize, Clone)]
pub struct Config {
    pub machine: MachineConfig,
    pub video: VideoConfig,
    pub palette: PaletteConfig,
}

#[derive(Deserialize, Clone)]
pub struct MachineConfig {
    pub cpu: String,
    pub clock_hz: u32,
    pub refresh_hz: u32,
}

#[derive(Deserialize, Clone)]
pub struct VideoConfig {
    pub width: u32,
    pub height: u32,
    pub mode: String,
}

#[derive(Deserialize, Clone)]
pub struct PaletteConfig {
    pub global_colors: u32,
    pub sprite_palettes: u32,
    pub colors_per_sprite: u32,
}

#[derive(Debug, Clone, Copy)]
pub struct MemoryMap {
    pub zero_page: u16,
    pub stack: u16,
    pub ram: u16,
    pub video_ram: u16,
    pub palette_ram: u16,
    pub palette_map: u16,
    pub sprite_ram: u16,
    pub io: u16,
    pub rom: u16,
}

impl Default for MemoryMap {
    fn default() -> Self {
        Self {
            zero_page: 0x0000,
            stack: 0x0100,
            ram: 0x0200,
            video_ram: 0x2000,
            palette_ram: 0x2C00,
            palette_map: 0x2C60, // palette_ram + (32 colors * 3 bytes)
            sprite_ram: 0x2C70,
            io: 0x3000,
            rom: 0x8000,
        }
    }
}

impl MemoryMap {
    /// Lay out memory segments based on the active config so regions do not overlap.
    ///
    /// - VRAM: fixed base 0x2000, sized to fit bitmap 4bpp (2 pixels per byte)
    /// - Palette data: immediately after VRAM (3 bytes per global color)
    /// - Palette map: 16 visible entries after palette data
    /// - Sprite RAM: 0x100 bytes after palette map (placeholder)
    /// - I/O: 0x100 bytes after sprite RAM (placeholder)
    /// - ROM: starts after I/O
    pub fn from_config(cfg: &Config) -> Self {
        let zero_page = 0x0000;
        let stack = 0x0100;
        let ram = 0x0200;

        let video_ram: u16 = 0x2000;
        let pixels = cfg.video.width.saturating_mul(cfg.video.height);
        let vram_bytes = ((pixels + 1) / 2) as u32; // 4bpp, 2 pixels per byte

        let palette_bytes = cfg
            .palette
            .global_colors
            .saturating_mul(3)
            .min(u16::MAX as u32);

        let palette_ram = video_ram.saturating_add(vram_bytes as u16);
        let palette_map = palette_ram.saturating_add(palette_bytes as u16);
        let sprite_ram = palette_map.saturating_add(16); // 16 entries of palette map
        let io = sprite_ram.saturating_add(0x0100);
        let rom = io.saturating_add(0x0100);

        MemoryMap {
            zero_page,
            stack,
            ram,
            video_ram,
            palette_ram,
            palette_map,
            sprite_ram,
            io,
            rom,
        }
    }
}

pub fn load_config(path: &str) -> Result<Config, String> {
    let raw = fs::read_to_string(path).map_err(|e| format!("Failed to read {path}: {e}"))?;
    toml::from_str::<Config>(&raw).map_err(|e| format!("Failed to parse {path}: {e}"))
}

impl Default for Config {
    fn default() -> Self {
        Self {
            machine: MachineConfig::default(),
            video: VideoConfig::default(),
            palette: PaletteConfig::default(),
        }
    }
}

impl Default for MachineConfig {
    fn default() -> Self {
        Self {
            cpu: "6502".to_string(),
            clock_hz: 1_000_000,
            refresh_hz: 50,
        }
    }
}

impl Default for VideoConfig {
    fn default() -> Self {
        Self {
            width: 256,
            height: 192,
            mode: "bitmap".to_string(),
        }
    }
}

impl Default for PaletteConfig {
    fn default() -> Self {
        Self {
            global_colors: 32,
            sprite_palettes: 4,
            colors_per_sprite: 4,
        }
    }
}
