use crate::bus::ChipcadeBus;
use crate::config;
use crate::sprites::validate_sprite_str;
use crate::sprites::{
    SpritePack, load_sprite_pack, load_sprite_pack_from_embedded, sprite_consts, sprite_to_rgba,
};
use chipcade_asm::assemble_with_labels_at;
use mos6502::cpu;
use mos6502::instruction::Nmos6502;
use mos6502::memory::Bus;
use mos6502::registers::StackPointer;
use rust_embed::RustEmbed;
use std::collections::HashSet;
use std::fs;
use std::io::Cursor;
use std::path::{Component, Path, PathBuf};
use std::time::{Duration, Instant};

#[derive(Clone)]
pub struct LineOrigin {
    pub file: PathBuf,
    pub line: usize,
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
    pub sprites: crate::sprites::SpritePack,
    pub vram_rgba: Vec<u8>,
    pub steps: u64,
    pub reason: String,
}

#[derive(Clone)]
pub struct DebugRegisters {
    pub a: u8,
    pub x: u8,
    pub y: u8,
    pub sp: u8,
    pub pc: u16,
    pub status: u8,
}

pub struct DebugLine {
    pub file: String,
    pub line: usize,
}

pub struct DebugStep {
    pub registers: DebugRegisters,
    pub stop_reason: Option<String>,
    pub line: Option<DebugLine>,
}

pub struct DebugSession {
    cpu: cpu::CPU<ChipcadeBus, Nmos6502>,
    artifacts: BuildArtifacts,
    init_addr: Option<u16>,
    update_addr: Option<u16>,
    did_init: bool,
    in_init: bool,
}

impl DebugSession {
    fn ensure_ready(&mut self) {
        if self.did_init {
            return;
        }
        // Position PC at Init if present, else entry point, else Update.
        if let Some(init) = self.init_addr.or(self.artifacts.entry_point) {
            self.cpu.registers.program_counter = init;
        } else if let Some(update) = self.update_addr {
            self.cpu.registers.program_counter = update;
        }
        self.in_init = self.init_addr.is_some();
        self.did_init = true;
    }

    fn map_line(&self, pc: u16) -> Option<DebugLine> {
        if pc < self.artifacts.load_addr {
            return None;
        }
        let idx = (pc - self.artifacts.load_addr) as usize;
        self.artifacts.pc_line_map.get(idx).map(|orig| DebugLine {
            file: orig
                .file
                .file_name()
                .and_then(|s| s.to_str())
                .unwrap_or_default()
                .to_string(),
            line: orig.line,
        })
    }

    pub fn peek_registers(&self) -> DebugRegisters {
        let regs = &self.cpu.registers;
        DebugRegisters {
            a: regs.accumulator,
            x: regs.index_x,
            y: regs.index_y,
            sp: regs.stack_pointer.0,
            pc: regs.program_counter,
            status: regs.status.bits(),
        }
    }

    pub fn peek_line(&self) -> Option<DebugLine> {
        self.map_line(self.cpu.registers.program_counter)
    }

    pub fn step(&mut self) -> DebugStep {
        self.ensure_ready();
        let pc = self.cpu.registers.program_counter;
        let line = self.map_line(pc);
        let opcode = self.cpu.memory.get_byte(pc);
        let regs_before = self.peek_registers();
        let stop_reason = if opcode == 0x00 {
            if self.in_init {
                if let Some(update) = self.update_addr {
                    self.cpu.registers.program_counter = update;
                    self.in_init = false;
                    Some("Init BRK -> Update".to_string())
                } else {
                    Some("BRK".to_string())
                }
            } else {
                // Loop Update on BRK if present.
                if let Some(update) = self.update_addr {
                    self.cpu.registers.program_counter = update;
                    None
                } else {
                    Some("BRK".to_string())
                }
            }
        } else if opcode == 0xFF {
            Some("HALT".to_string())
        } else {
            self.cpu.single_step();
            if opcode == 0x60 && self.in_init {
                self.in_init = false;
            }
            None
        };

        DebugStep {
            registers: regs_before,
            stop_reason,
            line,
        }
    }

    pub fn step_with_frame(&mut self) -> (DebugStep, Vec<u8>) {
        let step = self.step();
        let frame = self.cpu.memory.render_frame_rgba();
        (step, frame)
    }

    pub fn current_frame_rgba(&self) -> Vec<u8> {
        self.cpu.memory.render_frame_rgba()
    }

    pub fn run_to_rts(&mut self) -> DebugStep {
        self.ensure_ready();
        loop {
            let pc = self.cpu.registers.program_counter;
            let line = self.map_line(pc);
            let opcode = self.cpu.memory.get_byte(pc);
            let regs_before = self.peek_registers();
            if opcode == 0x00 {
                if self.in_init {
                    if let Some(update) = self.update_addr {
                        self.cpu.registers.program_counter = update;
                        self.in_init = false;
                        let regs = self.peek_registers();
                        return DebugStep {
                            registers: regs_before,
                            stop_reason: Some("Init BRK -> Update".to_string()),
                            line: self.map_line(regs.pc).or(line),
                        };
                    }
                } else if let Some(update) = self.update_addr {
                    self.cpu.registers.program_counter = update;
                    continue;
                }
                return DebugStep {
                    registers: regs_before,
                    stop_reason: Some("BRK".to_string()),
                    line,
                };
            }
            if opcode == 0xFF {
                return DebugStep {
                    registers: regs_before,
                    stop_reason: Some("HALT".to_string()),
                    line,
                };
            }
            if opcode == 0x60 {
                return DebugStep {
                    registers: regs_before,
                    stop_reason: Some("RTS".to_string()),
                    line,
                };
            }
            self.cpu.single_step();
        }
    }

    pub fn run_to_rts_with_frame(&mut self) -> (DebugStep, Vec<u8>) {
        let step = self.run_to_rts();
        let frame = self.cpu.memory.render_frame_rgba();
        (step, frame)
    }
}

#[derive(Clone)]
pub struct BuildArtifacts {
    pub program: Vec<u8>,
    pub sprites: crate::sprites::SpritePack,
    pub entry_point: Option<u16>,
    pub labels: std::collections::HashMap<String, u16>,
    pub load_addr: u16,
    pub line_map: Vec<LineOrigin>,
    pub pc_line_map: Vec<LineOrigin>,
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
    last_tick: Option<Instant>,
    tick_accum: Duration,
}

impl Machine {
    pub fn entry_address(&self, entry_point: Option<u16>) -> u16 {
        entry_point.unwrap_or(self.mem_map.ram)
    }

    pub fn config(&self) -> &config::Config {
        &self.config
    }

    pub fn label_address(
        labels: &std::collections::HashMap<String, u16>,
        name: &str,
    ) -> Option<u16> {
        labels.get(name).copied()
    }

    /// Return true when a redraw/update should occur based on configured refresh_hz.
    pub fn should_tick(&mut self) -> bool {
        let hz = self.config.machine.refresh_hz.max(1) as f64;
        let interval = Duration::from_secs_f64(1.0 / hz);
        let now = Instant::now();
        match self.last_tick {
            None => {
                self.last_tick = Some(now);
                self.tick_accum = Duration::ZERO;
                true
            }
            Some(last) => {
                let elapsed = now.duration_since(last);
                self.tick_accum = (self.tick_accum + elapsed).min(interval * 5);
                self.last_tick = Some(now);
                if self.tick_accum >= interval {
                    self.tick_accum -= interval;
                    true
                } else {
                    false
                }
            }
        }
    }

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
            last_tick: None,
            tick_accum: Duration::ZERO,
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

    /// Assemble the current project and return artifacts (program + sprites).
    pub fn assemble(&self) -> Result<BuildArtifacts, String> {
        self.assemble_impl(false)
    }

    /// Assemble silently (no console output for loaded assets).
    pub fn assemble_silent(&self) -> Result<BuildArtifacts, String> {
        self.assemble_impl(true)
    }

    fn assemble_impl(&self, silent: bool) -> Result<BuildArtifacts, String> {
        let project_root = self
            .paths
            .config
            .parent()
            .unwrap_or_else(|| Path::new("."))
            .to_path_buf();
        let mut sprite_pack = load_sprite_pack(&project_root)?;
        if sprite_pack.images.is_empty() {
            let mut embedded = Vec::new();
            for file in EmbeddedAssets::iter() {
                let path = file.as_ref();
                if path.starts_with("assets/sprites/") && path.ends_with(".spr") {
                    if let Some(data) = EmbeddedAssets::get(path) {
                        let content = String::from_utf8_lossy(data.data.as_ref()).to_string();
                        let name = Path::new(path)
                            .file_stem()
                            .and_then(|s| s.to_str())
                            .unwrap_or("sprite")
                            .to_string();
                        embedded.push((name, content));
                    }
                }
            }
            sprite_pack = load_sprite_pack_from_embedded(embedded)?;
            if !silent {
                println!(
                    "Loaded {} sprite(s) from embedded assets.",
                    sprite_pack.images.len()
                );
            }
        } else {
            if !silent {
                println!(
                    "Loaded {} sprite(s) from {}.",
                    sprite_pack.images.len(),
                    project_root.join("assets/sprites").display()
                );
            }
        }
        let sprite_consts = sprite_consts(&sprite_pack.images);

        write_chipcade_inc(&self.paths, &self.sys_consts, &sprite_consts)?;

        let expanded = expand_asm(&self.paths.asm_main, &mut HashSet::new())?;
        let asm = expanded.bytes.clone();
        let line_map = expanded.line_map.clone();

        let origin = self.mem_map.ram;
        let assembled = assemble_with_labels_at(&mut Cursor::new(asm), origin).map_err(|msg| {
            if let Some((file, line)) = map_error_to_origin(&msg, &line_map) {
                let project_root = self.paths.config.parent().unwrap_or_else(|| Path::new("."));
                let rel = relative_path(project_root, &file);
                let trimmed = msg
                    .splitn(2, ':')
                    .nth(1)
                    .map(|s| s.trim())
                    .unwrap_or(msg.as_str());
                format!("Assembly error: {}:{} -> {}", rel.display(), line, trimmed)
            } else {
                format!("Assembly error: {}", msg)
            }
        })?;

        let mut pc_line_map = Vec::new();
        for line_no in &assembled.pc_line {
            if let Some(orig) = line_map.get(line_no.saturating_sub(1)) {
                pc_line_map.push(orig.clone());
            }
        }

        let entry_point = assembled
            .labels
            .get("Start")
            .or_else(|| assembled.labels.get("Init"))
            .or_else(|| assembled.labels.get("Update"))
            .copied();

        Ok(BuildArtifacts {
            entry_point,
            program: assembled.bytes,
            sprites: sprite_pack,
            labels: assembled.labels,
            load_addr: origin,
            line_map,
            pc_line_map,
        })
    }

    pub fn create_cpu(
        &self,
        program: &[u8],
        sprites: &SpritePack,
        entry_point: Option<u16>,
    ) -> Result<cpu::CPU<ChipcadeBus, Nmos6502>, String> {
        let palette_bytes = load_palette_file(
            &self.paths.palette,
            self.config.palette.global_colors as usize,
        )?;
        let mut cpu = cpu::CPU::new(
            ChipcadeBus::from_config(&self.config, Some(&palette_bytes), sprites.clone()),
            Nmos6502,
        );

        let load_addr: u16 = self.mem_map.ram;
        let mut program = program.to_vec();
        // Place an invalid opcode as a stop sentinel so cpu.run() exits
        program.push(0xff);

        cpu.memory.set_bytes(load_addr, &program);

        if entry_point.is_none() {
            println!("Warning: 'Start' label not found; starting at program base.");
        }
        let start_pc = self.entry_address(entry_point);
        cpu.registers.program_counter = start_pc;
        cpu.registers.stack_pointer = StackPointer(0xFF); // Initialize stack pointer to top of stack

        Ok(cpu)
    }

    /// Run an already assembled program.
    pub fn execute(
        &self,
        mut program: Vec<u8>,
        sprites: SpritePack,
        entry_point: Option<u16>,
    ) -> Result<RunArtifacts, String> {
        let palette_bytes = load_palette_file(
            &self.paths.palette,
            self.config.palette.global_colors as usize,
        )?;
        let mut cpu = cpu::CPU::new(
            ChipcadeBus::from_config(&self.config, Some(&palette_bytes), sprites.clone()),
            Nmos6502,
        );

        let load_addr: u16 = self.mem_map.ram;
        // Place an invalid opcode as a stop sentinel so cpu.run() exits
        program.push(0xff);

        cpu.memory.set_bytes(load_addr, &program);

        if entry_point.is_none() {
            println!("Warning: 'Start' label not found; starting at program base.");
        }
        let start_pc = entry_point.unwrap_or(load_addr);
        cpu.registers.program_counter = start_pc;
        cpu.registers.stack_pointer = StackPointer(0xFF); // Initialize stack pointer to top of stack

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

        let vram_rgba = cpu.memory.render_frame_rgba();

        println!(
            "Execution stopped after {} steps, reason: {}",
            steps, stop_reason
        );
        println!(
            "Final PC: ${:04X}, SP: ${:02X}",
            cpu.registers.program_counter, cpu.registers.stack_pointer.0
        );

        Ok(RunArtifacts {
            config: self.config.clone(),
            sys_consts: self.sys_consts.clone(),
            program,
            sprites,
            vram_rgba,
            steps,
            reason: stop_reason,
        })
    }

    /// Run one frame starting at the given entry point on an existing CPU. Returns the rendered VRAM along with step count and stop reason.
    pub fn run_frame(
        &self,
        cpu: &mut cpu::CPU<ChipcadeBus, Nmos6502>,
        entry_point: u16,
    ) -> (Vec<u8>, u64, String) {
        cpu.registers.program_counter = entry_point;
        let mut steps: u64 = 0;
        let stop_reason: String = loop {
            if steps >= 1_000_000 {
                break "step limit reached".to_string();
            }
            let pc = cpu.registers.program_counter;
            let opcode = cpu.memory.get_byte(pc);
            if opcode == 0x00 {
                break "BRK".to_string();
            }
            if opcode == 0xFF {
                break "HALT".to_string();
            }
            cpu.single_step();
            steps += 1;
        };

        let vram_rgba = cpu.memory.render_frame_rgba();
        (vram_rgba, steps, stop_reason)
    }

    /// Assemble and run in one step (current CLI behavior).
    pub fn run(&self) -> Result<RunArtifacts, String> {
        let build = self.assemble_impl(true)?; // silent=true to avoid duplicate output
        self.execute(build.program, build.sprites, build.entry_point)
    }

    /// Create a debugging session with a CPU initialized to the program entry.
    pub fn start_debug_session(&self) -> Result<DebugSession, String> {
        let build = self.assemble_impl(true)?; // silent
        let cpu = self.create_cpu(&build.program, &build.sprites, build.entry_point)?;
        let init_addr = build.labels.get("Init").copied();
        let update_addr = build.labels.get("Update").copied();
        Ok(DebugSession {
            cpu,
            artifacts: build,
            init_addr,
            update_addr,
            did_init: false,
            in_init: init_addr.is_some(),
        })
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

    /// List sprite files (assets/sprites), returning file name and contents.
    pub fn list_sprite_sources(&self) -> Result<Vec<(String, String)>, String> {
        let root = self
            .paths
            .config
            .parent()
            .unwrap_or_else(|| Path::new("."))
            .join("assets/sprites");
        if !root.exists() {
            return Ok(Vec::new());
        }
        let mut entries = Vec::new();
        for entry in fs::read_dir(&root)
            .map_err(|e| format!("Failed to read sprites dir {}: {e}", root.display()))?
        {
            let entry =
                entry.map_err(|e| format!("Failed to read entry in {}: {e}", root.display()))?;
            let path = entry.path();
            if path.extension().and_then(|s| s.to_str()) != Some("spr") {
                continue;
            }
            let content = read_file(&path)?;
            entries.push((file_name(&path)?, content));
        }
        entries.sort_by(|a, b| a.0.cmp(&b.0));
        Ok(entries)
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
        let project_root = self
            .paths
            .config
            .parent()
            .unwrap_or_else(|| Path::new("."))
            .to_path_buf();
        let mut sprite_pack = match load_sprite_pack(&project_root) {
            Ok(p) => p,
            Err(e) => return Err((None, e)),
        };
        if sprite_pack.images.is_empty() {
            let mut embedded = Vec::new();
            for file in EmbeddedAssets::iter() {
                let path = file.as_ref();
                if path.starts_with("assets/sprites/") && path.ends_with(".spr") {
                    if let Some(data) = EmbeddedAssets::get(path) {
                        let content = String::from_utf8_lossy(data.data.as_ref()).to_string();
                        let name = Path::new(path)
                            .file_stem()
                            .and_then(|s| s.to_str())
                            .unwrap_or("sprite")
                            .to_string();
                        embedded.push((name, content));
                    }
                }
            }
            sprite_pack = load_sprite_pack_from_embedded(embedded).map_err(|e| (None, e))?;
        }
        let sprite_consts = sprite_consts(&sprite_pack.images);
        if let Err(e) = write_chipcade_inc(&self.paths, &self.sys_consts, &sprite_consts) {
            return Err((None, e));
        }

        let expanded =
            match expand_asm_inline(base_dir, &virtual_path, content, &mut HashSet::new()) {
                Ok(e) => e,
                Err(e) => return Err((None, e)),
            };

        let mut asm = expanded.bytes.clone();
        let mut line_map = expanded.line_map.clone();
        // Prepend include to ensure constants are seen first unless the source already does.
        let already_includes_chipcade = content.lines().any(|line| {
            let trimmed = line.trim_start();
            trimmed
                .strip_prefix(".include")
                .map(|rest| rest.contains("chipcade.inc"))
                .unwrap_or(false)
        });
        if !already_includes_chipcade {
            let include_line = b".include \"include/chipcade.inc\"\n";
            asm.splice(0..0, include_line.iter().copied());
            line_map.iter_mut().for_each(|l| l.line += 1);
            line_map.insert(
                0,
                LineOrigin {
                    file: virtual_path.clone(),
                    line: 1,
                },
            );
        }

        let origin = self.mem_map.ram;
        if let Err(msg) = assemble_with_labels_at(&mut Cursor::new(asm), origin) {
            if let Some((file, line)) = map_error_to_origin(&msg, &line_map) {
                let project_root = self.paths.config.parent().unwrap_or_else(|| Path::new("."));
                let rel = relative_path(project_root, &file);
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

    /// Validate a sprite source in-memory.
    pub fn validate_sprite(&self, name: &str, content: &str) -> Result<(), String> {
        validate_sprite_str(name, content)
    }

    /// Write a sprite file into assets/sprites/.
    pub fn write_sprite_file(&self, name: &str, content: &str) -> Result<PathBuf, String> {
        let root = self
            .paths
            .config
            .parent()
            .unwrap_or_else(|| Path::new("."))
            .join("assets/sprites");
        fs::create_dir_all(&root)
            .map_err(|e| format!("Failed to create sprites dir {}: {e}", root.display()))?;
        let file = validate_file_name(name)?;
        let target = root.join(file);
        write_file(&target, content)
    }

    /// Render a sprite preview into an RGBA buffer of the given canvas size, centered and scaled up as much as possible while preserving aspect ratio.
    /// `sprite_rgba` must be sprite_w * sprite_h * 4 bytes.
    pub fn render_sprite_preview(
        &self,
        sprite_w: u32,
        sprite_h: u32,
        sprite_rgba: &[u8],
        canvas_w: u32,
        canvas_h: u32,
    ) -> Vec<u8> {
        let canvas_len = (canvas_w as usize)
            .saturating_mul(canvas_h as usize)
            .saturating_mul(4);
        let mut out = vec![0; canvas_len]; // black background

        if sprite_w == 0 || sprite_h == 0 || canvas_w == 0 || canvas_h == 0 {
            return out;
        }
        let expected = sprite_w as usize * sprite_h as usize * 4;
        if sprite_rgba.len() < expected {
            return out;
        }

        let scale_x = canvas_w as f32 / sprite_w as f32;
        let scale_y = canvas_h as f32 / sprite_h as f32;
        let scale = scale_x.min(scale_y).max(1.0);
        let dest_w = (sprite_w as f32 * scale).round() as i32;
        let dest_h = (sprite_h as f32 * scale).round() as i32;
        let ox = ((canvas_w as i32 - dest_w) / 2).max(0);
        let oy = ((canvas_h as i32 - dest_h) / 2).max(0);

        for y in 0..canvas_h as i32 {
            for x in 0..canvas_w as i32 {
                if x < ox || x >= ox + dest_w || y < oy || y >= oy + dest_h {
                    continue;
                }
                let src_x = (((x - ox) as f32) / scale)
                    .floor()
                    .clamp(0.0, sprite_w as f32 - 1.0) as usize;
                let src_y = (((y - oy) as f32) / scale)
                    .floor()
                    .clamp(0.0, sprite_h as f32 - 1.0) as usize;
                let si = (src_y * sprite_w as usize + src_x) * 4;
                let di = ((y as usize * canvas_w as usize) + x as usize) * 4;
                if si + 3 < sprite_rgba.len() && di + 3 < out.len() {
                    out[di..di + 4].copy_from_slice(&sprite_rgba[si..si + 4]);
                }
            }
        }

        out
    }

    /// Load a sprite by name from assets/sprites/, decode to RGBA, and render a preview.
    pub fn render_sprite_preview_from_disk(
        &self,
        name: &str,
        canvas_w: u32,
        canvas_h: u32,
    ) -> Result<Vec<u8>, String> {
        let sprites = self
            .paths
            .config
            .parent()
            .unwrap_or_else(|| Path::new("."))
            .join("assets/sprites")
            .join(name);
        if !sprites.exists() {
            return Err(format!("Sprite {} not found", sprites.display()));
        }
        let content = read_file(&sprites)?;
        let palette = load_palette_file(
            &self.paths.palette,
            self.config.palette.global_colors as usize,
        )?;
        let spr = crate::sprites::parse_spr_str(name, &content, &sprites)
            .map_err(|e| format!("Failed to parse {}: {}", sprites.display(), e))?;
        let rgba = sprite_to_rgba(&spr, Some(&palette));
        Ok(self.render_sprite_preview(
            spr.width as u32,
            spr.height as u32,
            &rgba,
            canvas_w,
            canvas_h,
        ))
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
            last_tick: None,
            tick_accum: Duration::ZERO,
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
    let includes: Vec<ExpandedAsm> = Vec::new();

    for (idx, line) in content.lines().enumerate() {
        let trimmed = line.trim_start();
        if let Some(rest) = trimmed.strip_prefix(".include") {
            let rest = rest.trim_start();
            if let Some(stripped) = rest.strip_prefix('"') {
                if let Some(end_quote) = stripped.find('"') {
                    let include_path = &stripped[..end_quote];
                    let include_full = base_dir.join(include_path);
                    let included = expand_asm(&include_full, visited)?;

                    // Inline all includes at the point they're declared
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

    // Append all includes at the end
    for included in includes {
        bytes.extend_from_slice(&included.bytes);
        line_map.extend_from_slice(&included.line_map);
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

fn write_chipcade_inc(
    paths: &ProjectPaths,
    sys_consts: &[SystemConst],
    sprite_consts: &[(String, u32)],
) -> Result<(), String> {
    let include_path = paths
        .asm_main
        .parent()
        .unwrap_or_else(|| Path::new("."))
        .join("include/chipcade.inc");
    if let Some(parent) = include_path.parent() {
        fs::create_dir_all(parent)
            .map_err(|e| format!("Failed to create include dir {}: {e}", parent.display()))?;
    }

    let mut out = String::new();
    out.push_str("; Auto-generated by chipcade. Do not edit.\n");
    out.push_str("; System constants\n");
    for c in sys_consts {
        if c.is_hex {
            out.push_str(&format!(".const {} ${:04X}\n", c.name, c.value));
        } else {
            out.push_str(&format!(".const {} {}\n", c.name, c.value));
        }
    }
    if !sprite_consts.is_empty() {
        out.push_str("\n; Sprite indices\n");
        for (name, val) in sprite_consts {
            out.push_str(&format!(".const {} {}\n", name, val));
        }
    }

    fs::write(&include_path, out)
        .map_err(|e| format!("Failed to write {}: {e}", include_path.display()))
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
            "assets/sprites/chipcade.spr",
            root.join("assets/sprites/chipcade.spr"),
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
