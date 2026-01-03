use crate::bus::ChipcadeBus;
use crate::config;
use chipcade_asm::assemble;
use mos6502::cpu;
use mos6502::instruction::Nmos6502;
use mos6502::memory::Bus;
use std::collections::HashSet;
use std::fs;
use std::io::Cursor;
use std::path::{Path, PathBuf};

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
}

impl ProjectPaths {
    pub fn new(root: impl AsRef<Path>) -> Self {
        let root = root.as_ref().to_path_buf();
        let asm_dir = root.join("asm");
        let build_dir = root.join("build");

        Self {
            config: root.join("chipcade.toml"),
            asm_main: asm_dir.join("main.asm"),
            program_bin: build_dir.join("program.bin"),
            vram_dump: build_dir.join("vram_dump.png"),
            build_dir,
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
        let mut cpu = cpu::CPU::new(ChipcadeBus::from_config(&self.config), Nmos6502);

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
            "  palette       = globals {}, sprite_palettes {}, colors_per_sprite {}",
            self.config.palette.global_colors,
            self.config.palette.sprite_palettes,
            self.config.palette.colors_per_sprite
        );

        println!("\nMemory map:");
        println!("  zero_page     = ${:04X}", self.mem_map.zero_page);
        println!("  stack         = ${:04X}", self.mem_map.stack);
        println!("  ram           = ${:04X}", self.mem_map.ram);
        println!("  video_ram     = ${:04X}", self.mem_map.video_ram);
        println!("  palette       = ${:04X}", self.mem_map.palette_ram);
        println!("  palette_map   = ${:04X}", self.mem_map.palette_map);
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
    Ok(())
}

fn expand_asm(path: &Path, visited: &mut HashSet<PathBuf>) -> Result<ExpandedAsm, String> {
    let canonical = path.canonicalize().unwrap_or_else(|_| path.to_path_buf());
    if !visited.insert(canonical.clone()) {
        return Err(format!("Include cycle detected at {}", canonical.display()));
    }

    let content = fs::read_to_string(path)
        .map_err(|e| format!("failed to read asm file {}: {e}", path.display()))?;
    let base_dir = path.parent().unwrap_or_else(|| Path::new("."));
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
            return Err(format!("Malformed include directive in {}", path.display()));
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
            name: "PALETTE_MAP",
            value: map.palette_map as u32,
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
        root.join("scripts"),
    ];
    for dir in dirs {
        if let Err(e) = fs::create_dir_all(&dir) {
            eprintln!("Failed to create {}: {e}", dir.display());
            return;
        }
    }

    // chipcade.toml
    let toml = r#"[machine]
cpu = "6502"
clock_hz = 1000000
refresh_hz = 50

[video]
width = 256
height = 192
mode = "bitmap"

[palette]
global_colors = 32
sprite_palettes = 4
colors_per_sprite = 4
"#;

    // asm/main.asm
    let main_asm = r#"; Entry point
    .include "include/chipcade.inc"

Start:
    LDA #$00
    STA $2000       ; example: write a byte to VRAM base
    BRK
"#;

    // asm/include/chipcade.inc
    let include_inc = r#"; Chipcade hardware constants
.const VRAM_BASE $2000
.const PALETTE_BASE $2C00
.const PALETTE_MAP $2C60
"#;

    // assets/palettes/default.pal (Endesga 32)
    let palette_txt = r#";paint.net Palette File
;Palette Name: Endesga 32
FFbe4a2f
FFd77643
FFead4aa
FFe4a672
FFb86f50
FF733e39
FF3e2731
FFa22633
FFe43b44
FFf77622
FFfeae34
FFfee761
FF63c74d
FF3e8948
FF265c42
FF193c3e
FF124e89
FF0099db
FF2ce8f5
FFffffff
FFc0cbdc
FF8b9bb4
FF5a6988
FF3a4466
FF262b44
FF181425
FFff0044
FF68386c
FFb55088
FFf6757a
FFe8b796
FFc28569
"#;

    // scripts (placeholders)
    let build_sh = "#!/usr/bin/env bash\nset -e\ncargo run --quiet -- run ${1:-.}\n";
    let run_sh = "#!/usr/bin/env bash\nset -e\ncargo run --quiet -- run ${1:-.}\n";

    // .gitignore
    let gitignore = r#"/build
/target
*.png
*.bin
"#;

    let writes = [
        (paths.config.clone(), toml),
        (paths.asm_main.clone(), main_asm),
        (root.join("asm/irq.asm"), "; IRQ handler (stub)\nBRK\n"),
        (root.join("asm/gfx.asm"), "; Graphics helpers (stub)\nRTS\n"),
        (root.join("asm/include/chipcade.inc"), include_inc),
        (root.join("assets/palettes/default.pal"), palette_txt),
        (root.join("scripts/build.sh"), build_sh),
        (root.join("scripts/run.sh"), run_sh),
        (root.join(".gitignore"), gitignore),
        (root.join("README.md"), "# New Chipcade project\n"),
    ];

    for (path, content) in writes {
        if path.exists() {
            eprintln!("Refusing to overwrite existing file {}", path.display());
            continue;
        }
        if let Err(e) = fs::write(&path, content) {
            eprintln!("Failed to write {}: {e}", path.display());
        }
    }

    println!("Created new Chipcade project at {}", root.display());
}
