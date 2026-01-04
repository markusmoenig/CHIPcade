use std::fs;
use std::path::{Path, PathBuf};

#[derive(Clone, Debug)]
pub struct SpriteImage {
    pub name: String,
    pub index: u16,
    pub width: u8,
    pub height: u8,
    pub colors: [u8; 3],
    pub offset: usize,
    pub len: usize,
}

#[derive(Clone, Debug, Default)]
pub struct SpritePack {
    pub data: Vec<u8>,
    pub images: Vec<SpriteImage>,
}

#[derive(Debug)]
struct SprFile {
    name: String,
    path: PathBuf,
    width: u8,
    height: u8,
    colors: [u8; 3],
    pixels: Vec<Vec<char>>,
}

pub fn load_sprite_pack(root: &Path) -> Result<SpritePack, String> {
    let dir = root.join("assets/sprites");
    if !dir.exists() {
        return Ok(SpritePack::default());
    }

    let mut files = Vec::new();
    for entry in fs::read_dir(&dir)
        .map_err(|e| format!("Failed to read sprites dir {}: {e}", dir.display()))?
    {
        let entry = entry.map_err(|e| format!("Failed to read entry in {}: {e}", dir.display()))?;
        let path = entry.path();
        if path.extension().and_then(|s| s.to_str()).unwrap_or("") != "spr" {
            continue;
        }
        let name = path
            .file_stem()
            .and_then(|s| s.to_str())
            .ok_or_else(|| format!("Invalid sprite file name {}", path.display()))?
            .to_string();
        files.push((name, path));
    }

    files.sort_by(|a, b| a.0.cmp(&b.0));

    let mut pack = SpritePack::default();
    for (idx, (name, path)) in files.into_iter().enumerate() {
        let spr = parse_spr_file(&name, &path)?;
        let data = pack_sprite(&spr)?;
        let offset = pack.data.len();
        pack.data.extend_from_slice(&data);
        pack.images.push(SpriteImage {
            name: spr.name,
            index: idx as u16,
            width: spr.width,
            height: spr.height,
            colors: spr.colors,
            offset,
            len: data.len(),
        });
    }

    Ok(pack)
}

pub fn load_sprite_pack_from_embedded<'a, I>(iter: I) -> Result<SpritePack, String>
where
    I: IntoIterator<Item = (String, String)>,
{
    let mut pack = SpritePack::default();
    for (name, content) in iter {
        let spr = parse_spr_str(&name, &content, Path::new(&name))?;
        let data = pack_sprite(&spr)?;
        let offset = pack.data.len();
        pack.data.extend_from_slice(&data);
        pack.images.push(SpriteImage {
            name: spr.name,
            index: pack.images.len() as u16,
            width: spr.width,
            height: spr.height,
            colors: spr.colors,
            offset,
            len: data.len(),
        });
    }
    Ok(pack)
}

fn parse_spr_file(name: &str, path: &Path) -> Result<SprFile, String> {
    let content =
        fs::read_to_string(path).map_err(|e| format!("Failed to read {}: {e}", path.display()))?;
    parse_spr_str(name, &content, path)
}

fn parse_spr_str(name: &str, content: &str, path: &Path) -> Result<SprFile, String> {
    let mut width = None;
    let mut height = None;
    let mut colors: Option<[u8; 3]> = None;
    let mut pixels_section = false;
    let mut pixels: Vec<Vec<char>> = Vec::new();

    for (idx, line) in content.lines().enumerate() {
        let line_no = idx + 1;
        let trimmed = line.trim();
        if trimmed.is_empty() || trimmed.starts_with('#') {
            continue;
        }
        if pixels_section {
            pixels.push(trimmed.chars().collect());
            continue;
        }
        if let Some(rest) = trimmed.strip_prefix("size") {
            let parts: Vec<&str> = rest.trim().split('x').collect();
            if parts.len() != 2 {
                return Err(format!(
                    "{}:{}: Invalid size declaration (expected WxH)",
                    path.display(),
                    line_no
                ));
            }
            let w: u8 = parts[0]
                .trim()
                .parse()
                .map_err(|_| format!("{}:{}: Invalid width", path.display(), line_no))?;
            let h: u8 = parts[1]
                .trim()
                .parse()
                .map_err(|_| format!("{}:{}: Invalid height", path.display(), line_no))?;
            if !matches!((w, h), (8, 8) | (16, 16)) {
                return Err(format!(
                    "{}:{}: Size must be 8x8 or 16x16",
                    path.display(),
                    line_no
                ));
            }
            width = Some(w);
            height = Some(h);
            continue;
        }
        if let Some(rest) = trimmed.strip_prefix("colors") {
            let parts: Vec<&str> = rest.trim().split_whitespace().collect();
            if parts.len() != 3 {
                return Err(format!(
                    "{}:{}: colors must provide three palette indices",
                    path.display(),
                    line_no
                ));
            }
            let mut vals = [0u8; 3];
            for (i, p) in parts.iter().enumerate() {
                let v: u8 = p
                    .parse()
                    .map_err(|_| format!("{}:{}: Invalid color index", path.display(), line_no))?;
                if v == 0 || v > 15 {
                    return Err(format!(
                        "{}:{}: Color indices must be 1..15",
                        path.display(),
                        line_no
                    ));
                }
                vals[i] = v;
            }
            colors = Some(vals);
            continue;
        }
        if trimmed == "pixels" {
            pixels_section = true;
            continue;
        }
        return Err(format!(
            "{}:{}: Unexpected line (expected size/colors/pixels)",
            path.display(),
            line_no
        ));
    }

    let width = width.ok_or_else(|| format!("{}: missing size", path.display()))?;
    let height = height.ok_or_else(|| format!("{}: missing size", path.display()))?;
    let colors = colors.ok_or_else(|| format!("{}: missing colors", path.display()))?;

    if pixels.len() != height as usize {
        return Err(format!(
            "{}: pixels section has {} rows, expected {}",
            path.display(),
            pixels.len(),
            height
        ));
    }
    for (row_idx, row) in pixels.iter().enumerate() {
        if row.len() != width as usize {
            return Err(format!(
                "{}: row {} has {} cols, expected {}",
                path.display(),
                row_idx + 1,
                row.len(),
                width
            ));
        }
        for &c in row {
            if !matches!(c, '.' | '1' | '2' | '3') {
                return Err(format!(
                    "{}: row {} has invalid char '{}'",
                    path.display(),
                    row_idx + 1,
                    c
                ));
            }
        }
    }

    Ok(SprFile {
        name: name.to_string(),
        path: path.to_path_buf(),
        width,
        height,
        colors,
        pixels,
    })
}

fn pack_sprite(spr: &SprFile) -> Result<Vec<u8>, String> {
    let mut out = Vec::new();
    for row in &spr.pixels {
        let mut bits = Vec::with_capacity(row.len());
        for &c in row {
            let code = match c {
                '.' => 0b00,
                '1' => 0b01,
                '2' => 0b10,
                '3' => 0b11,
                _ => return Err(format!("Invalid pixel '{}' in {}", c, spr.path.display())),
            };
            bits.push(code);
        }
        // pack 4 pixels per byte (2 bits each)
        for chunk in bits.chunks(4) {
            let mut byte = 0u8;
            for (i, &val) in chunk.iter().enumerate() {
                byte |= (val & 0b11) << (6 - i * 2);
            }
            out.push(byte);
        }
    }
    Ok(out)
}

pub fn sprite_consts(images: &[SpriteImage]) -> Vec<(String, u32)> {
    images
        .iter()
        .map(|img| {
            let mut name = img.name.to_uppercase();
            name = name
                .chars()
                .map(|c| if c.is_ascii_alphanumeric() { c } else { '_' })
                .collect();
            (format!("SPR_{}", name), img.index as u32)
        })
        .collect()
}
