use crate::bus::ChipcadeBus;
use crate::config;
use chipcade_asm::assemble;
use mos6502::cpu;
use mos6502::instruction::Nmos6502;
use mos6502::memory::Bus;
use rust_embed::RustEmbed;
use std::collections::HashSet;
use std::fs;
use std::io::Cursor;
use std::path::{Component, Path, PathBuf};

#[derive(Clone)]
struct LineOrigin {
    file: PathBuf,
    line: usize,
}

struct ExpandedAsm {
    bytes: Vec<u8>,
    line_map: Vec<LineOrigin>,
}

#[derive(Clone)]
pub struct RunArtifacts {
    pub config: config::Config,
    pub sys_consts: Vec<SystemConst>,
    pub program: Vec<u8>,
    pub vram_rgba: Vec<u8>,
    pub steps: u64,
    pub reason: String,
}

#[derive(Clone)]
pub struct SystemConst {
    pub name: &'static str,
    pub value: u32,
    pub is_hex: bool,
}

pub struct ProjectPaths {
    pub config: PathBuf,
    pub asm_main: PathBuf,
    pub build_dir: PathBuf,
    pub program_bin: PathBuf,
    pub vram_dump: PathBuf,
    pub palette: PathBuf,
}

#[derive(RustEmbed)]
#[folder = "embedded"]
pub(crate) struct EmbeddedAssets;

impl ProjectPaths {
    pub fn new(root: impl AsRef<Path>) -> Self {
        let root = root.as_ref().to_path_buf();
        let asm_dir = root.join("asm");
        let build_dir = root.join("build");
        let palette = root.join("assets/palettes/default.pal");

        Self {
            config: root.join("chipcade.toml"),
            asm_main: asm_dir.join("main.asm"),
            program_bin: build_dir.join("program.bin"),
            vram_dump: build_dir.join("vram_dump.png"),
            build_dir,
            palette,
        }
    }
}

pub struct Machine {
    paths: ProjectPaths,
    config: config::Config,
    mem_map: config::MemoryMap,
    sys_consts: Vec<SystemConst>,
}

impl Machine {
    pub fn video_size(&self) -> (u32, u32) {
        (self.config.video.width, self.config.video.height)
    }

    pub fn new(project_root: PathBuf) -> Result<Self, String> {
        let paths = ProjectPaths::new(&project_root);
        ensure_project_files(&paths)?;
        let config = config::load_config(
            paths
                .config
                .to_str()
                .expect("config path is not valid UTF-8"),
        )
        .map_err(|e| e)?;
        let mem_map = config::MemoryMap::from_config(&config);
        let sys_consts = system_constants(&mem_map, &config);

        Ok(Self {
            paths,
            config,
            mem_map,
            sys_consts,
        })
    }

    pub fn print_sys_constants(&self) {
        println!("System constants:");
        for c in &self.sys_consts {
            if c.is_hex {
                println!("  {:<18}= ${:04X}", c.name, c.value);
            } else {
                println!("  {:<18}= {}", c.name, c.value);
            }
        }
    }

    pub fn print_run_summary(&self, artifacts: &RunArtifacts) {
        println!(
            "Run finished: steps={}, reason={}",
            artifacts.steps, artifacts.reason
        );
    }

    /// Assemble the current project and return the program bytes.
    pub fn assemble(&self) -> Result<Vec<u8>, String> {
        let prologue = build_system_prologue(&self.sys_consts);
        let expanded = expand_asm(&self.paths.asm_main, &mut HashSet::new())?;

        let mut asm = prologue.bytes.clone();
        asm.extend_from_slice(&expanded.bytes);
        let mut line_map = prologue.line_map.clone();
        line_map.extend_from_slice(&expanded.line_map);

        let mut program = Vec::<u8>::new();
        assemble(&mut Cursor::new(asm), &mut program).map_err(|msg| {
            if let Some((file, line)) = map_error_to_origin(&msg, &line_map) {
                format!(
                    "Assembly error: {}:{} -> {}",
                    file.to_string_lossy(),
                    line,
                    msg
                )
            } else {
                format!("Assembly error: {}", msg)
            }
        })?;

        Ok(program)
    }

    /// Run an already assembled program.
    pub fn execute(&self, mut program: Vec<u8>) -> Result<RunArtifacts, String> {
        let palette_bytes = load_palette_file(
            &self.paths.palette,
            self.config.palette.global_colors as usize,
        )?;
        let mut cpu = cpu::CPU::new(
            ChipcadeBus::from_config(&self.config, Some(&palette_bytes)),
            Nmos6502,
        );

        // Zero page: $00/$01 used as VRAM pointer, $02 used as clear color (both nibbles)
        let clear_nibble = 0x02u8;
        let clear_byte = (clear_nibble << 4) | clear_nibble;
        let zero_page_data = [
            (self.mem_map.video_ram & 0x00FF) as u8,
            (self.mem_map.video_ram >> 8) as u8,
            clear_byte,
        ];

        // Place an invalid opcode as a stop sentinel so cpu.run() exits
        program.push(0xff);

        // Clear VRAM to color stored at $02 (low nibble)
        cpu.memory.set_bytes(0x00, &zero_page_data);
        let clear_color = cpu.memory.get_byte(0x02) & 0x0F;
        cpu.memory.vram.clear(clear_color);

        cpu.memory.set_bytes(0x00, &zero_page_data);
        cpu.memory.set_bytes(0x10, &program);
        cpu.registers.program_counter = 0x10;

        // Run until BRK (0x00) or invalid (0xFF)
        let mut steps: u64 = 0;
        #[allow(unused_assignments)]
        let mut stop_reason = "unknown".to_string();
        loop {
            if steps >= 1_000_000 {
                stop_reason = "step limit reached".to_string();
                break;
            }
            let pc = cpu.registers.program_counter;
            let opcode = cpu.memory.get_byte(pc);
            if opcode == 0x00 {
                stop_reason = "BRK".to_string();
                break;
            }
            if opcode == 0xFF {
                stop_reason = "HALT".to_string();
                break;
            }
            cpu.single_step();
            steps += 1;
        }

        let vram_rgba = cpu.memory.render_bitmap_rgba();

        Ok(RunArtifacts {
            config: self.config.clone(),
            sys_consts: self.sys_consts.clone(),
            program,
            vram_rgba,
            steps,
            reason: stop_reason,
        })
    }

    /// Assemble and run in one step (current CLI behavior).
    pub fn run(&self) -> Result<RunArtifacts, String> {
        let program = self.assemble()?;
        self.execute(program)
    }

    pub fn persist_artifacts(&self, artifacts: &RunArtifacts) {
        if let Err(e) = fs::create_dir_all(&self.paths.build_dir) {
            eprintln!(
                "Warning: failed to create build dir {}: {e}",
                self.paths.build_dir.display()
            );
        }

        if let Err(e) = fs::write(&self.paths.program_bin, &artifacts.program) {
            eprintln!(
                "Warning: failed to write program.bin to {}: {e}",
                self.paths.program_bin.display()
            );
        } else {
            println!("Wrote program to {}", self.paths.program_bin.display());
        }

        if let Err(e) = save_rgba_png(
            artifacts.config.video.width,
            artifacts.config.video.height,
            &artifacts.vram_rgba,
            &self.paths.vram_dump,
        ) {
            eprintln!("failed to save vram_dump.png: {e}");
        } else {
            println!("Saved VRAM to {}", self.paths.vram_dump.display());
        }
    }

    pub fn print_info(&self) {
        println!("Config:");
        println!("  cpu           = {}", self.config.machine.cpu);
        println!("  clock_hz      = {}", self.config.machine.clock_hz);
        println!("  refresh_hz    = {}", self.config.machine.refresh_hz);
        println!(
            "  video         = {}x{} {}",
            self.config.video.width, self.config.video.height, self.config.video.mode
        );
        println!(
            "  palette       = globals {}, colors_per_sprite {}",
            self.config.palette.global_colors, self.config.palette.colors_per_sprite
        );

        println!("\nMemory map:");
        println!("  zero_page     = ${:04X}", self.mem_map.zero_page);
        println!("  stack         = ${:04X}", self.mem_map.stack);
        println!("  ram           = ${:04X}", self.mem_map.ram);
        println!("  video_ram     = ${:04X}", self.mem_map.video_ram);
        println!("  palette       = ${:04X}", self.mem_map.palette_ram);
        println!("  sprite_ram    = ${:04X}", self.mem_map.sprite_ram);
        println!("  io            = ${:04X}", self.mem_map.io);
        println!("  rom           = ${:04X}", self.mem_map.rom);

        println!("\nSystem constants:");
        for c in &self.sys_consts {
            if c.is_hex {
                println!("  {:<18}= ${:04X}", c.name, c.value);
            } else {
                println!("  {:<18}= {}", c.name, c.value);
            }
        }
    }

    fn asm_root(&self) -> Result<PathBuf, String> {
        self.paths
            .asm_main
            .parent()
            .map(|p| p.to_path_buf())
            .ok_or_else(|| "asm directory missing".to_string())
    }

    /// List ASM sources (non-include), returning file name and contents. `main.asm` is first.
    pub fn list_asm_sources(&self) -> Result<Vec<(String, String)>, String> {
        let root = self.asm_root()?;
        let main = self.paths.asm_main.clone();
        let mut paths = Vec::new();
        collect_asm_paths(&root, &root, &mut paths)?;

        let mut out = Vec::new();
        if main.exists() {
            let content = read_file(&main)?;
            out.push((file_name(&main)?, content));
        }

        for path in paths {
            if path == main {
                continue;
            }
            if is_include_path(&root, &path) {
                continue;
            }
            let content = read_file(&path)?;
            out.push((file_name(&path)?, content));
        }
        Ok(out)
    }

    /// List include files (under asm/include), returning file name and contents.
    pub fn list_include_sources(&self) -> Result<Vec<(String, String)>, String> {
        let root = self.asm_root()?;
        let mut paths = Vec::new();
        collect_asm_paths(&root, &root, &mut paths)?;
        let mut out = Vec::new();
        for path in paths {
            if is_include_path(&root, &path) {
                let content = read_file(&path)?;
                out.push((file_name(&path)?, content));
            }
        }
        Ok(out)
    }

    pub fn write_asm_source(&self, relative: &Path, content: &str) -> Result<PathBuf, String> {
        let root = self.asm_root()?;
        if relative.components().any(|c| {
            matches!(
                c,
                Component::ParentDir | Component::RootDir | Component::Prefix(_)
            )
        }) {
            return Err("Refusing to write outside asm directory".to_string());
        }
        let full = root.join(relative);
        if !full.starts_with(&root) {
            return Err("Refusing to write outside asm directory".to_string());
        }
        if let Some(parent) = full.parent() {
            fs::create_dir_all(parent)
                .map_err(|e| format!("Failed to create directories for {}: {e}", full.display()))?;
        }
        fs::write(&full, content)
            .map_err(|e| format!("Failed to write {}: {e}", full.display()))?;
        Ok(full)
    }

    /// Write an ASM source (e.g., "level.asm") into the asm root (not include/).
    pub fn write_asm_file(&self, name: &str, content: &str) -> Result<PathBuf, String> {
        let root = self.asm_root()?;
        let file = validate_file_name(name)?;
        let target = root.join(file);
        write_file(&target, content)
    }

    /// Validate an ASM source (in-memory, no writes) by assembling it; returns Ok if valid, Err with (line, message) if not.
    pub fn validate_asm(&self, name: &str, content: &str) -> Result<(), (Option<usize>, String)> {
        let root = match self.asm_root() {
            Ok(r) => r,
            Err(e) => return Err((None, e)),
        };
        let file = match validate_file_name(name) {
            Ok(f) => f,
            Err(e) => return Err((None, e)),
        };
        let virtual_path = root.join(&file);
        let base_dir = virtual_path.parent().unwrap_or(&root);

        // Assemble with system prologue so constants are available.
        let prologue = build_system_prologue(&self.sys_consts);
        let expanded =
            match expand_asm_inline(base_dir, &virtual_path, content, &mut HashSet::new()) {
                Ok(e) => e,
                Err(e) => return Err((None, e)),
            };

        let mut asm = prologue.bytes.clone();
        asm.extend_from_slice(&expanded.bytes);
        let mut line_map = prologue.line_map.clone();
        line_map.extend_from_slice(&expanded.line_map);

        if let Err(msg) = assemble(&mut Cursor::new(asm), &mut Vec::<u8>::new()) {
            if let Some((file, line)) = map_error_to_origin(&msg, &line_map) {
                let project_root = self
                    .paths
                    .config
                    .parent()
                    .unwrap_or_else(|| Path::new("."))
                    .canonicalize()
                    .unwrap_or_else(|_| {
                        self.paths
                            .config
                            .parent()
                            .unwrap_or_else(|| Path::new("."))
                            .to_path_buf()
                    });
                let rel = relative_path(&project_root, &file);
                let decorated = if file == virtual_path {
                    msg
                } else {
                    format!("{}: {msg}", rel.display())
                };
                return Err((Some(line), decorated));
            }
            return Err((None, msg));
        }

        Ok(())
    }

    /// Write an include file (e.g., "macros.inc") into asm/include.
    pub fn write_include_file(&self, name: &str, content: &str) -> Result<PathBuf, String> {
        let root = self.asm_root()?;
        let file = validate_file_name(name)?;
        let target = root.join("include").join(file);
        write_file(&target, content)
    }
}

fn is_asm_source(path: &Path) -> bool {
    matches!(
        path.extension()
            .and_then(|e| e.to_str())
            .unwrap_or("")
            .to_ascii_lowercase()
            .as_str(),
        "asm" | "inc"
    )
}

fn is_include_path(root: &Path, path: &Path) -> bool {
    if let Ok(rel) = path.strip_prefix(root) {
        rel.components()
            .next()
            .is_some_and(|c| c.as_os_str() == "include")
    } else {
        false
    }
}

fn file_name(path: &Path) -> Result<String, String> {
    path.file_name()
        .and_then(|s| s.to_str())
        .map(|s| s.to_string())
        .ok_or_else(|| format!("Invalid file name for {}", path.display()))
}

fn read_file(path: &Path) -> Result<String, String> {
    fs::read_to_string(path).map_err(|e| format!("Failed to read {}: {e}", path.display()))
}

fn validate_file_name(name: &str) -> Result<&str, String> {
    let path = Path::new(name);
    if path.components().count() != 1 || path.is_absolute() {
        return Err("File name must not contain path separators or be absolute".to_string());
    }
    Ok(name)
}

fn write_file(path: &Path, content: &str) -> Result<PathBuf, String> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)
            .map_err(|e| format!("Failed to create directories for {}: {e}", path.display()))?;
    }
    fs::write(path, content).map_err(|e| format!("Failed to write {}: {e}", path.display()))?;
    Ok(path.to_path_buf())
}

fn collect_asm_paths(root: &Path, dir: &Path, out: &mut Vec<PathBuf>) -> Result<(), String> {
    for entry in fs::read_dir(dir).map_err(|e| format!("Failed to read {}: {e}", dir.display()))? {
        let entry = entry.map_err(|e| format!("Failed to read entry in {}: {e}", dir.display()))?;
        let path = entry.path();
        if path.is_dir() {
            collect_asm_paths(root, &path, out)?;
        } else if is_asm_source(&path) {
            out.push(path);
        }
    }
    Ok(())
}

impl Default for Machine {
    /// Create a dummy machine using default config and a placeholder path.
    fn default() -> Self {
        let root = PathBuf::from(".");
        let config = config::Config::default();
        let mem_map = config::MemoryMap::from_config(&config);
        let sys_consts = system_constants(&mem_map, &config);
        Self {
            paths: ProjectPaths::new(&root),
            config,
            mem_map,
            sys_consts,
        }
    }
}

fn ensure_project_files(paths: &ProjectPaths) -> Result<(), String> {
    if !paths.config.exists() {
        return Err(format!(
            "Missing chipcade.toml at {}",
            paths.config.display()
        ));
    }
    if !paths.asm_main.exists() {
        return Err(format!(
            "Missing asm/main.asm at {}",
            paths.asm_main.display()
        ));
    }
    if !paths.palette.exists() {
        return Err(format!(
            "Missing palette file at {}",
            paths.palette.display()
        ));
    }
    Ok(())
}

fn load_palette_file(path: &Path, expected_colors: usize) -> Result<Vec<u8>, String> {
    let content = fs::read_to_string(path)
        .map_err(|e| format!("Failed to read palette file {}: {e}", path.display()))?;

    let mut colors = Vec::new();
    for line in content.lines() {
        let trimmed = line.trim();
        if trimmed.is_empty() || trimmed.starts_with(';') {
            continue;
        }
        let without_hash = trimmed.trim_start_matches('#');
        let hex = if without_hash.len() == 8 {
            &without_hash[2..]
        } else {
            without_hash
        };
        if hex.len() != 6 {
            return Err(format!(
                "Invalid palette entry `{}` in {} (expected 6 hex digits, optionally prefixed by alpha)",
                trimmed,
                path.display()
            ));
        }
        let r = u8::from_str_radix(&hex[0..2], 16)
            .map_err(|e| format!("Invalid red component in {}: {}", path.display(), e))?;
        let g = u8::from_str_radix(&hex[2..4], 16)
            .map_err(|e| format!("Invalid green component in {}: {}", path.display(), e))?;
        let b = u8::from_str_radix(&hex[4..6], 16)
            .map_err(|e| format!("Invalid blue component in {}: {}", path.display(), e))?;
        colors.push([r, g, b]);
        if colors.len() == expected_colors {
            break;
        }
    }

    if colors.len() < expected_colors {
        return Err(format!(
            "Palette file {} contains {} colors, expected {}",
            path.display(),
            colors.len(),
            expected_colors
        ));
    }

    let mut out = Vec::with_capacity(expected_colors * 3);
    for rgb in colors.into_iter().take(expected_colors) {
        out.extend_from_slice(&rgb);
    }
    Ok(out)
}

fn expand_asm(path: &Path, visited: &mut HashSet<PathBuf>) -> Result<ExpandedAsm, String> {
    let canonical = path.canonicalize().unwrap_or_else(|_| path.to_path_buf());
    let content = fs::read_to_string(path)
        .map_err(|e| format!("failed to read asm file {}: {e}", path.display()))?;
    let base_dir = path.parent().unwrap_or_else(|| Path::new("."));
    expand_asm_inline(base_dir, &canonical, &content, visited)
}

fn expand_asm_inline(
    base_dir: &Path,
    virtual_path: &Path,
    content: &str,
    visited: &mut HashSet<PathBuf>,
) -> Result<ExpandedAsm, String> {
    let canonical = virtual_path
        .canonicalize()
        .unwrap_or_else(|_| virtual_path.to_path_buf());
    if !visited.insert(canonical.clone()) {
        return Err(format!("Include cycle detected at {}", canonical.display()));
    }

    let mut bytes = Vec::new();
    let mut line_map = Vec::new();

    for (idx, line) in content.lines().enumerate() {
        let trimmed = line.trim_start();
        if let Some(rest) = trimmed.strip_prefix(".include") {
            let rest = rest.trim_start();
            if let Some(stripped) = rest.strip_prefix('"') {
                if let Some(end_quote) = stripped.find('"') {
                    let include_path = &stripped[..end_quote];
                    let include_full = base_dir.join(include_path);
                    let included = expand_asm(&include_full, visited)?;
                    bytes.extend_from_slice(&included.bytes);
                    line_map.extend_from_slice(&included.line_map);
                    continue;
                }
            }
            return Err(format!(
                "Malformed include directive in {}",
                virtual_path.display()
            ));
        }
        bytes.extend_from_slice(line.as_bytes());
        bytes.push(b'\n');
        line_map.push(LineOrigin {
            file: canonical.clone(),
            line: idx + 1,
        });
    }

    visited.remove(&canonical);
    Ok(ExpandedAsm { bytes, line_map })
}

fn map_error_to_origin(msg: &str, map: &[LineOrigin]) -> Option<(PathBuf, usize)> {
    // Expect format: "Parse error on line X: ..."
    let needle = "Parse error on line ";
    let idx = msg.find(needle)?;
    let rest = &msg[idx + needle.len()..];
    let line_str = rest.split(':').next()?.trim();
    let line_num: usize = line_str.parse().ok()?;
    let origin = map.get(line_num.saturating_sub(1))?;
    Some((origin.file.clone(), origin.line))
}

fn relative_path(base: &Path, path: &Path) -> PathBuf {
    if let Ok(rel) = path.strip_prefix(base) {
        return rel.to_path_buf();
    }
    if let Ok(canon_path) = path.canonicalize() {
        if let Ok(rel) = canon_path.strip_prefix(base) {
            return rel.to_path_buf();
        }
    }
    path.file_name()
        .map(PathBuf::from)
        .unwrap_or_else(|| path.to_path_buf())
}

fn system_constants(map: &config::MemoryMap, cfg: &config::Config) -> Vec<SystemConst> {
    let pixels = cfg.video.width.saturating_mul(cfg.video.height);
    let vram_bytes = ((pixels + 1) / 2) as u32; // 4bpp bitmap
    vec![
        SystemConst {
            name: "VRAM",
            value: map.video_ram as u32,
            is_hex: true,
        },
        SystemConst {
            name: "VRAM_SIZE",
            value: vram_bytes,
            is_hex: true,
        },
        SystemConst {
            name: "PALETTE",
            value: map.palette_ram as u32,
            is_hex: true,
        },
        SystemConst {
            name: "SPRITE_RAM",
            value: map.sprite_ram as u32,
            is_hex: true,
        },
        SystemConst {
            name: "IO",
            value: map.io as u32,
            is_hex: true,
        },
        SystemConst {
            name: "ROM",
            value: map.rom as u32,
            is_hex: true,
        },
        SystemConst {
            name: "VIDEO_WIDTH",
            value: cfg.video.width,
            is_hex: false,
        },
        SystemConst {
            name: "VIDEO_HEIGHT",
            value: cfg.video.height,
            is_hex: false,
        },
    ]
}

fn build_system_prologue(constants: &[SystemConst]) -> ExpandedAsm {
    let mut bytes = Vec::new();
    let mut line_map = Vec::new();
    let sys_path = PathBuf::from("<system>");
    for (idx, c) in constants.iter().enumerate() {
        let line = if c.is_hex {
            format!(".const {} ${:04X}\n", c.name, c.value)
        } else {
            format!(".const {} {}\n", c.name, c.value)
        };
        bytes.extend_from_slice(line.as_bytes());
        line_map.push(LineOrigin {
            file: sys_path.clone(),
            line: idx + 1,
        });
    }
    ExpandedAsm { bytes, line_map }
}

fn save_rgba_png(width: u32, height: u32, rgba: &[u8], path: &Path) -> Result<(), String> {
    let img = image::ImageBuffer::<image::Rgba<u8>, _>::from_raw(width, height, rgba.to_vec())
        .ok_or_else(|| "failed to build image buffer".to_owned())?;
    img.save(path)
        .map_err(|e| format!("failed to save image: {e}"))
}

fn write_embedded_file(asset_path: &str, dest: &Path) -> Result<(), String> {
    let Some(data) = EmbeddedAssets::get(asset_path) else {
        return Err(format!("Missing embedded asset {asset_path}"));
    };
    fs::write(dest, data.data.as_ref())
        .map_err(|e| format!("Failed to write {}: {e}", dest.display()))
}

pub fn scaffold_project(name: PathBuf) {
    let root = name;
    if root.exists() {
        eprintln!("Refusing to overwrite existing path: {}", root.display());
        return;
    }

    let paths = ProjectPaths::new(&root);
    // Create directory tree
    let dirs = [
        root.clone(),
        root.join("asm/include"),
        root.join("build"),
        root.join("assets/palettes"),
        root.join("assets/bitmaps"),
        root.join("assets/tiles"),
        root.join("assets/sprites"),
        root.join("data"),
    ];
    for dir in dirs {
        if let Err(e) = fs::create_dir_all(&dir) {
            eprintln!("Failed to create {}: {e}", dir.display());
            return;
        }
    }

    let writes = [
        ("chipcade.toml", paths.config.clone()),
        ("asm/main.asm", paths.asm_main.clone()),
        ("asm/irq.asm", root.join("asm/irq.asm")),
        ("asm/gfx.asm", root.join("asm/gfx.asm")),
        (
            "asm/include/chipcade.inc",
            root.join("asm/include/chipcade.inc"),
        ),
        (
            "assets/palettes/default.pal",
            root.join("assets/palettes/default.pal"),
        ),
        (
            "assets/palettes/sprites/chipcade.spr",
            root.join("assets/palettes/sprites/chipcade.spr"),
        ),
        (".gitignore", root.join(".gitignore")),
        ("README.md", root.join("README.md")),
    ];

    for (asset_path, path) in writes {
        if path.exists() {
            eprintln!("Refusing to overwrite existing file {}", path.display());
            continue;
        }
        if let Err(e) = write_embedded_file(asset_path, &path) {
            eprintln!("{e}");
        }
    }

    println!("Created new Chipcade project at {}", root.display());
}
