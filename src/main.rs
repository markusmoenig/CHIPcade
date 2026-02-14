mod asm6502;
mod bus;
mod config;
mod display;
mod eval;
mod machine;
mod sprites;

#[cfg(not(target_arch = "wasm32"))]
use clap::{Parser, Subcommand};
#[cfg(not(target_arch = "wasm32"))]
use eval::{EvalResult, eval_expression};
use machine::Machine;
#[cfg(not(target_arch = "wasm32"))]
use machine::{ScaffoldLanguage, scaffold_project};
use std::path::PathBuf;
#[cfg(not(target_arch = "wasm32"))]
use std::process::Command;
#[cfg(not(target_arch = "wasm32"))]
use std::sync::mpsc::{self, Receiver};

pub mod prelude {

    pub use crate::{
        bus::{ChipcadeBus, Palette},
        config::Config,
        eval::{EvalResult, eval_expression},
        machine::Machine,
    };
}

#[cfg(not(target_arch = "wasm32"))]
#[derive(Parser)]
#[command(name = "chipcade", about = "CHIPcade toolchain driver", version)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[cfg(not(target_arch = "wasm32"))]
#[derive(Subcommand)]
enum Commands {
    /// Assemble and run a project (default)
    Run {
        /// Project root (contains chipcade.toml, src/, build/, etc.)
        #[arg(default_value = ".")]
        project: PathBuf,
        /// Scale factor for rendering/output (default: 3)
        #[arg(long, default_value_t = 3)]
        scale: u32,
    },
    /// Launch the UI-based editor
    Edit {
        /// Project root (contains chipcade.toml)
        #[arg(default_value = ".")]
        project: PathBuf,
    },
    /// Scaffold a new Chipcade project
    New {
        /// Project directory to create (e.g., my_game)
        name: PathBuf,
        /// Starter language (`c` by default, or `asm`)
        #[arg(long, value_enum, default_value_t = NewLang::C)]
        lang: NewLang,
    },
    /// Show config, memory map, and system constants for a project
    Info {
        /// Project root (contains chipcade.toml)
        #[arg(default_value = ".")]
        project: PathBuf,
    },
    /// Evaluate a hex/dec/bin expression and print all representations
    Eval {
        /// Expression to evaluate (supports + - * / and parentheses; hex: 0x / $, bin: 0b / %)
        #[arg(num_args = 1..)]
        expr: Vec<String>,
    },
    /// Sprite management commands
    Sprites {
        #[command(subcommand)]
        command: SpriteCommands,
    },
    /// Build a distributable 64 KB binary image
    Build {
        /// Project root (contains chipcade.toml, src/, build/, etc.)
        #[arg(default_value = ".")]
        project: PathBuf,
    },
    /// Interactive debugger REPL (step, registers, memory)
    Repl {
        /// Project root (contains chipcade.toml, src/, build/, etc.)
        #[arg(default_value = ".")]
        project: PathBuf,
        /// Disable live preview window (terminal-only REPL).
        #[arg(long, default_value_t = false)]
        no_preview: bool,
        /// Keep preview window in normal stacking order (topmost is default).
        #[arg(long, default_value_t = false)]
        no_topmost: bool,
    },
    /// Build current project and run it in browser via wasm
    Wasm {
        /// Project root (contains chipcade.toml, src/, build/, etc.)
        #[arg(default_value = ".")]
        project: PathBuf,
        /// Build wasm artifacts only (no dev server).
        #[arg(long, default_value_t = false)]
        build_only: bool,
    },
}

#[cfg(not(target_arch = "wasm32"))]
#[derive(Subcommand)]
enum SpriteCommands {
    /// Add a new sprite file
    Add {
        /// Sprite name (e.g., player, enemy)
        name: String,
        /// Sprite size (8 or 16)
        size: u8,
        /// Project root (contains assets/sprites/)
        #[arg(long, default_value = ".")]
        project: PathBuf,
    },
    /// Remove a sprite file
    Remove {
        /// Sprite name to remove
        name: String,
        /// Project root (contains assets/sprites/)
        #[arg(long, default_value = ".")]
        project: PathBuf,
    },
}

#[cfg(not(target_arch = "wasm32"))]
#[derive(clap::ValueEnum, Clone, Copy, Debug)]
enum NewLang {
    C,
    Asm,
}

#[cfg(not(target_arch = "wasm32"))]
fn main() {
    let cli = Cli::parse();

    match cli.command {
        Commands::Run { project, scale } => match Machine::new(project) {
            Ok(machine) => match machine.build() {
                Ok(artifacts) => {
                    let producer = crate::display::FrameProducer::new(machine, artifacts);
                    let backend = crate::display::winit_softbuffer::WinitSoftbufferBackend;
                    if let Err(e) = crate::display::DisplayBackend::run(backend, producer, scale) {
                        eprintln!("{e}");
                    }
                }
                Err(e) => eprintln!("{e}"),
            },
            Err(e) => eprintln!("{e}"),
        },
        Commands::Build { project } => match Machine::new(project) {
            Ok(machine) => match machine.build() {
                Ok(_) => println!("Build finished: {}", machine.program_bin_path().display()),
                Err(e) => eprintln!("{e}"),
            },
            Err(e) => eprintln!("{e}"),
        },
        Commands::Repl {
            project,
            no_preview,
            no_topmost,
        } => {
            if no_preview {
                run_repl(project);
            } else {
                run_repl_with_preview(project, !no_topmost);
            }
        }
        Commands::Wasm {
            project,
            build_only,
        } => {
            if let Err(e) = run_wasm(project, build_only) {
                eprintln!("{e}");
            }
        }
        Commands::New { name, lang } => {
            let scaffold_lang = match lang {
                NewLang::C => ScaffoldLanguage::C,
                NewLang::Asm => ScaffoldLanguage::Asm,
            };
            scaffold_project(name, scaffold_lang);
        }
        Commands::Info { project } => match Machine::new(project) {
            Ok(machine) => machine.print_info(),
            Err(e) => eprintln!("{e}"),
        },
        Commands::Edit { .. } => {
            eprintln!(
                "`edit` is currently disabled. Use your external editor and `chipcade repl`."
            );
        }
        Commands::Eval { expr } => {
            let expression = expr.join(" ");
            match eval_expression(&expression) {
                Ok(EvalResult { value }) => {
                    let u8v = (value as i128).rem_euclid(256) as u8;
                    let hex = format!("${:02X}", u8v);
                    let bin = format!("%{u8v:08b}");
                    println!("dec = {value}, hex = {hex}, bin = {bin}");
                }
                Err(e) => eprintln!("Eval error: {e}"),
            }
        }
        Commands::Sprites { command } => match command {
            SpriteCommands::Add {
                name,
                size,
                project,
            } => {
                if let Err(e) = create_sprite_file(&project, &name, size) {
                    eprintln!("Error: {e}");
                }
            }
            SpriteCommands::Remove { name, project } => {
                if let Err(e) = remove_sprite_file(&project, &name) {
                    eprintln!("Error: {e}");
                }
            }
        },
    }
}

#[cfg(not(target_arch = "wasm32"))]
fn run_wasm(project: PathBuf, build_only: bool) -> Result<(), String> {
    let machine = Machine::new(project.clone())?;
    machine.build()?;
    let program_bin = machine.program_bin_path();
    let bundle = program_bin
        .canonicalize()
        .unwrap_or_else(|_| program_bin.to_path_buf());
    let manifest_path = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("Cargo.toml");

    let mut cmd = Command::new("cargo");
    cmd.arg("run-wasm")
        .arg("--manifest-path")
        .arg(&manifest_path)
        .arg("--package")
        .arg("CHIPcade")
        .arg("--bin")
        .arg("CHIPcade");
    if build_only {
        cmd.arg("--build-only");
    }
    cmd.env("CHIPCADE_BUNDLE", &bundle);

    println!("Build finished: {}", program_bin.display());
    println!("Using bundle: {}", bundle.display());

    let status = cmd
        .status()
        .map_err(|e| format!("Failed to launch `cargo run-wasm`: {e}"))?;
    if status.success() {
        Ok(())
    } else {
        Err(format!(
            "`cargo run-wasm` failed with status {}. Install it with `cargo install cargo-run-wasm`.",
            status
        ))
    }
}

#[cfg(not(target_arch = "wasm32"))]
fn run_repl(project: PathBuf) {
    use rustyline::DefaultEditor;
    use rustyline::error::ReadlineError;

    let history_path = repl_history_path(&project);
    let machine = match Machine::new(project) {
        Ok(m) => m,
        Err(e) => {
            eprintln!("{e}");
            return;
        }
    };

    println!("\x1b[1;36mCHIPcade REPL\x1b[0m");
    println!("\x1b[2mType `help` for commands.\x1b[0m");

    let mut session: Option<crate::machine::DebugSession> = None;
    let mut rl = match DefaultEditor::new() {
        Ok(editor) => editor,
        Err(e) => {
            eprintln!("Failed to initialize line editor: {e}");
            return;
        }
    };
    let _ = rl.load_history(&history_path);

    loop {
        let line = match rl.readline("\x1b[1;32mCHIPcade>\x1b[0m ") {
            Ok(line) => line,
            Err(ReadlineError::Interrupted) => continue,
            Err(ReadlineError::Eof) => break,
            Err(e) => {
                eprintln!("Input error: {e}");
                break;
            }
        };

        let cmdline = line.trim();
        if cmdline.is_empty() {
            continue;
        }
        let _ = rl.add_history_entry(cmdline);
        let mut parts = cmdline.split_whitespace();
        let cmd = parts.next().unwrap_or("").to_ascii_lowercase();

        match cmd.as_str() {
            "help" | "h" | "?" => {
                println!("Commands:");
                println!("  help                     Show this help");
                println!("  build                    Build project");
                println!("  debug | reset            Start/restart debug session");
                println!("  pause                    Pause active run");
                println!("  stop                     Stop active run and clear debug session");
                println!("  regs                     Show registers");
                println!("  line                     Show current source line");
                println!("  labels [prefix]          List labels (optionally filtered)");
                println!("  step [n]                 Single-step n instructions (default 1)");
                println!("  cont [n]                 Continue up to n steps (default 10000)");
                println!("  run [n]                  Run until stop (default cap 1000000)");
                println!("  rts                      Run until RTS/stop");
                println!("  mem <addr> [len]         Dump memory bytes");
                println!("  quit | exit              Exit REPL");
            }
            "build" => match machine.build() {
                Ok(_) => println!("Build finished: {}", machine.program_bin_path().display()),
                Err(e) => eprintln!("{e}"),
            },
            "debug" | "reset" => match machine.start_debug_session() {
                Ok(s) => {
                    session = Some(s);
                    println!("Debug session ready.");
                    if let Some(s) = session.as_ref() {
                        print_step(s, None);
                    }
                }
                Err(e) => eprintln!("{e}"),
            },
            "regs" => {
                if let Some(s) = session.as_ref() {
                    print_step(s, None);
                } else {
                    println!("No debug session. Use `debug` first.");
                }
            }
            "line" => {
                if let Some(s) = session.as_ref() {
                    print_step(s, None);
                } else {
                    println!("No debug session. Use `debug` first.");
                }
            }
            "labels" => {
                if let Some(s) = session.as_ref() {
                    let filter = parts.next().map(|v| v.to_ascii_lowercase());
                    for (name, addr) in s.labels() {
                        if let Some(f) = &filter {
                            if !name.to_ascii_lowercase().contains(f) {
                                continue;
                            }
                        }
                        println!("{:<24} ${:04X}", name, addr);
                    }
                } else {
                    println!("No debug session. Use `debug` first.");
                }
            }
            "step" => {
                if let Some(s) = session.as_mut() {
                    let count = parse_usize(parts.next(), 1);
                    for _ in 0..count {
                        let step = s.step();
                        print_step(s, Some(&step));
                        if step.stop_reason.is_some() {
                            break;
                        }
                    }
                } else {
                    println!("No debug session. Use `debug` first.");
                }
            }
            "cont" | "continue" => {
                if let Some(s) = session.as_mut() {
                    let limit = parse_usize(parts.next(), 10_000);
                    let mut last = None;
                    for _ in 0..limit {
                        let step = s.step();
                        let stop = is_terminal_stop(&step);
                        last = Some(step);
                        if stop {
                            break;
                        }
                    }
                    if let Some(step) = last {
                        print_step(s, Some(&step));
                    }
                } else {
                    println!("No debug session. Use `debug` first.");
                }
            }
            "run" => {
                if session.is_none() {
                    match machine.start_debug_session() {
                        Ok(s) => session = Some(s),
                        Err(e) => {
                            eprintln!("{e}");
                            continue;
                        }
                    }
                }
                if let Some(s) = session.as_mut() {
                    let limit = parse_usize(parts.next(), 1_000_000);
                    let mut last = None;
                    for _ in 0..limit {
                        let step = s.step();
                        let stop = is_terminal_stop(&step);
                        last = Some(step);
                        if stop {
                            break;
                        }
                    }
                    if let Some(step) = last {
                        print_step(s, Some(&step));
                    }
                } else {
                    println!("No debug session. Use `debug` first.");
                }
            }
            "pause" => {
                println!("`pause` is only available in preview REPL mode.");
            }
            "stop" => {
                session = None;
                println!("Debug session stopped.");
            }
            "rts" => {
                if let Some(s) = session.as_mut() {
                    let step = s.run_to_rts();
                    print_step(s, Some(&step));
                } else {
                    println!("No debug session. Use `debug` first.");
                }
            }
            "mem" => {
                if let Some(s) = session.as_mut() {
                    let addr_tok = parts.next();
                    if addr_tok.is_none() {
                        println!("Usage: mem <addr> [len]");
                        continue;
                    }
                    let addr = match parse_addr(addr_tok.unwrap(), s) {
                        Ok(v) => v,
                        Err(e) => {
                            println!("{e}");
                            continue;
                        }
                    };
                    let len = match parts.next() {
                        Some(tok) => match parse_addr(tok, s) {
                            Ok(v) => v as usize,
                            Err(e) => {
                                println!("{e}");
                                continue;
                            }
                        },
                        None => 16,
                    }
                    .min(256);
                    dump_mem(s, addr, len.max(1));
                } else {
                    println!("No debug session. Use `debug` first.");
                }
            }
            "quit" | "exit" => break,
            _ => println!("Unknown command `{}`. Type `help`.", cmd),
        }
    }
    let _ = rl.save_history(&history_path);
}

#[cfg(not(target_arch = "wasm32"))]
fn run_repl_with_preview(project: PathBuf, topmost: bool) {
    use rustyline::DefaultEditor;
    use rustyline::error::ReadlineError;
    use softbuffer::{Context, Surface};
    use std::num::NonZeroU32;
    use std::rc::Rc;
    use std::time::{Duration, Instant};
    use winit::application::ApplicationHandler;
    use winit::dpi::LogicalSize;
    use winit::event::WindowEvent;
    use winit::event_loop::{ActiveEventLoop, ControlFlow, EventLoop};
    use winit::window::{Window, WindowLevel};

    let history_path = repl_history_path(&project);
    let machine = match Machine::new(project) {
        Ok(m) => m,
        Err(e) => {
            eprintln!("{e}");
            return;
        }
    };

    let (vw, vh) = machine.video_size();
    let (tx, rx) = mpsc::channel::<String>();
    let (prompt_tx, prompt_rx) = mpsc::channel::<()>();
    std::thread::spawn(move || {
        println!("\x1b[1;36mCHIPcade REPL + Preview\x1b[0m");
        println!("\x1b[2mType `help` for commands.\x1b[0m");
        let mut rl = match DefaultEditor::new() {
            Ok(editor) => editor,
            Err(e) => {
                eprintln!("Failed to initialize line editor: {e}");
                let _ = tx.send("__quit__".to_string());
                return;
            }
        };
        let _ = rl.load_history(&history_path);
        loop {
            match rl.readline("\x1b[1;32mCHIPcade>\x1b[0m ") {
                Ok(line) => {
                    let cmd = line.trim().to_string();
                    if cmd.is_empty() {
                        continue;
                    }
                    let _ = rl.add_history_entry(cmd.as_str());
                    if tx.send(cmd).is_err() {
                        break;
                    }
                    if prompt_rx.recv().is_err() {
                        break;
                    }
                }
                Err(ReadlineError::Interrupted) => continue,
                Err(ReadlineError::Eof) => {
                    let _ = tx.send("__quit__".to_string());
                    break;
                }
                Err(_) => {
                    let _ = tx.send("__quit__".to_string());
                    break;
                }
            }
        }
        let _ = rl.save_history(&history_path);
    });

    enum WorkerEvent {
        Frame(Vec<u8>, u32, u32),
    }

    fn send_frame(
        machine: &Machine,
        session: &crate::machine::DebugSession,
        evt_tx: &mpsc::Sender<WorkerEvent>,
    ) {
        let (w, h) = machine.video_size();
        let _ = evt_tx.send(WorkerEvent::Frame(session.current_frame_rgba(), w, h));
    }

    fn process_worker_command(
        cmdline: &str,
        machine: &mut Machine,
        session: &mut Option<crate::machine::DebugSession>,
        run_remaining: &mut Option<usize>,
        evt_tx: &mpsc::Sender<WorkerEvent>,
    ) -> bool {
        let mut parts = cmdline.split_whitespace();
        let cmd = parts.next().unwrap_or("").to_ascii_lowercase();
        match cmd.as_str() {
            "" => {}
            "__quit__" | "quit" | "exit" => return true,
            "help" | "h" | "?" => {
                println!("Commands:");
                println!("  help                     Show this help");
                println!("  build                    Build project");
                println!("  debug | reset            Start/restart debug session");
                println!("  pause                    Pause active run");
                println!("  stop                     Stop active run and clear debug session");
                println!("  regs                     Show registers");
                println!("  line                     Show current source line");
                println!("  labels [prefix]          List labels (optionally filtered)");
                println!("  step [n]                 Single-step n instructions (default 1)");
                println!("  cont [n]                 Continue up to n steps (default 10000)");
                println!("  run [n]                  Run until stop (default cap 1000000)");
                println!("  rts                      Run until RTS/stop");
                println!("  mem <addr> [len]         Dump memory bytes");
                println!("  quit | exit              Exit REPL + preview");
            }
            "build" => match machine.build() {
                Ok(_) => println!("Build finished: {}", machine.program_bin_path().display()),
                Err(e) => eprintln!("{e}"),
            },
            "debug" | "reset" => match machine.start_debug_session() {
                Ok(s) => {
                    send_frame(machine, &s, evt_tx);
                    *session = Some(s);
                    println!("Debug session ready.");
                    if let Some(s) = session.as_ref() {
                        print_step(s, None);
                    }
                }
                Err(e) => eprintln!("{e}"),
            },
            "regs" => {
                if let Some(s) = session.as_ref() {
                    print_step(s, None);
                } else {
                    println!("No debug session. Use `debug` first.");
                }
            }
            "line" => {
                if let Some(s) = session.as_ref() {
                    print_step(s, None);
                } else {
                    println!("No debug session. Use `debug` first.");
                }
            }
            "labels" => {
                if let Some(s) = session.as_ref() {
                    let filter = parts.next().map(|v| v.to_ascii_lowercase());
                    for (name, addr) in s.labels() {
                        if let Some(f) = &filter {
                            if !name.to_ascii_lowercase().contains(f) {
                                continue;
                            }
                        }
                        println!("{:<24} ${:04X}", name, addr);
                    }
                } else {
                    println!("No debug session. Use `debug` first.");
                }
            }
            "step" => {
                if let Some(s) = session.as_mut() {
                    let count = parse_usize(parts.next(), 1);
                    for _ in 0..count {
                        let step = s.step();
                        print_step(s, Some(&step));
                        if step.stop_reason.is_some() {
                            break;
                        }
                    }
                    send_frame(machine, s, evt_tx);
                } else {
                    println!("No debug session. Use `debug` first.");
                }
            }
            "cont" | "continue" => {
                if let Some(s) = session.as_mut() {
                    let limit = parse_usize(parts.next(), 10_000);
                    let mut last = None;
                    for _ in 0..limit {
                        let step = s.step();
                        let stop = is_terminal_stop(&step);
                        last = Some(step);
                        if stop {
                            break;
                        }
                    }
                    if let Some(step) = last {
                        print_step(s, Some(&step));
                    }
                    send_frame(machine, s, evt_tx);
                } else {
                    println!("No debug session. Use `debug` first.");
                }
            }
            "run" => {
                if session.is_none() {
                    match machine.start_debug_session() {
                        Ok(s) => {
                            send_frame(machine, &s, evt_tx);
                            *session = Some(s);
                        }
                        Err(e) => {
                            eprintln!("{e}");
                            return false;
                        }
                    }
                }
                if session.is_none() {
                    println!("No debug session. Use `debug` first.");
                    return false;
                }
                let limit_tok = parts.next();
                let limit = parse_usize(limit_tok, usize::MAX);
                *run_remaining = Some(limit);
                if limit_tok.is_some() {
                    println!("Running (limit {})...", limit);
                } else {
                    println!("Running...");
                }
            }
            "pause" => {
                if run_remaining.is_some() {
                    *run_remaining = None;
                    println!("Paused.");
                    if let Some(s) = session.as_mut() {
                        send_frame(machine, s, evt_tx);
                    }
                } else {
                    println!("No active run.");
                }
            }
            "stop" => {
                *run_remaining = None;
                if session.is_some() {
                    *session = None;
                    println!("Debug session stopped.");
                } else {
                    println!("No debug session.");
                }
            }
            "rts" => {
                if let Some(s) = session.as_mut() {
                    let step = s.run_to_rts();
                    print_step(s, Some(&step));
                    send_frame(machine, s, evt_tx);
                } else {
                    println!("No debug session. Use `debug` first.");
                }
            }
            "mem" => {
                if let Some(s) = session.as_mut() {
                    let addr_tok = parts.next();
                    if addr_tok.is_none() {
                        println!("Usage: mem <addr> [len]");
                        return false;
                    }
                    let addr = match parse_addr(addr_tok.unwrap_or_default(), s) {
                        Ok(v) => v,
                        Err(e) => {
                            println!("{e}");
                            return false;
                        }
                    };
                    let len = match parts.next() {
                        Some(tok) => match parse_addr(tok, s) {
                            Ok(v) => v as usize,
                            Err(e) => {
                                println!("{e}");
                                return false;
                            }
                        },
                        None => 16,
                    }
                    .min(256);
                    dump_mem(s, addr, len.max(1));
                } else {
                    println!("No debug session. Use `debug` first.");
                }
            }
            _ => println!("Unknown command `{}`. Type `help`.", cmd),
        }
        false
    }

    let (worker_cmd_tx, worker_cmd_rx) = mpsc::channel::<String>();
    let (worker_evt_tx, worker_evt_rx) = mpsc::channel::<WorkerEvent>();
    std::thread::spawn(move || {
        let mut machine = machine;
        let mut session: Option<crate::machine::DebugSession> = None;
        let mut run_remaining: Option<usize> = None;
        let refresh_hz = machine.config().machine.refresh_hz.max(1);
        let frame_interval = Duration::from_secs_f64(1.0 / refresh_hz as f64);
        let mut next_frame_at = Instant::now();

        loop {
            while let Ok(cmdline) = worker_cmd_rx.try_recv() {
                let should_exit = process_worker_command(
                    &cmdline,
                    &mut machine,
                    &mut session,
                    &mut run_remaining,
                    &worker_evt_tx,
                );
                let _ = prompt_tx.send(());
                if should_exit {
                    return;
                }
            }

            if let Some(remaining) = run_remaining {
                let now = Instant::now();
                if now < next_frame_at {
                    let sleep_for = (next_frame_at - now).min(Duration::from_millis(2));
                    std::thread::sleep(sleep_for);
                    continue;
                }
                if let Some(s) = session.as_mut() {
                    let step = loop {
                        let step = s.step();
                        let stop = is_terminal_stop(&step);
                        let frame_done = is_update_frame_boundary(s, &step);
                        if stop || frame_done {
                            break step;
                        }
                    };
                    if is_terminal_stop(&step) {
                        run_remaining = None;
                        print_step(s, Some(&step));
                    } else {
                        if remaining == usize::MAX {
                            run_remaining = Some(usize::MAX);
                        } else {
                            let next = remaining.saturating_sub(1);
                            if next == 0 {
                                run_remaining = None;
                                print_step(s, Some(&step));
                            } else {
                                run_remaining = Some(next);
                            }
                        }
                    }
                    send_frame(&machine, s, &worker_evt_tx);
                    let new_now = Instant::now();
                    next_frame_at = if next_frame_at + frame_interval > new_now {
                        next_frame_at + frame_interval
                    } else {
                        new_now + frame_interval
                    };
                } else {
                    run_remaining = None;
                    println!("No debug session. Use `debug` first.");
                }
                continue;
            }

            match worker_cmd_rx.recv_timeout(Duration::from_millis(16)) {
                Ok(cmdline) => {
                    let should_exit = process_worker_command(
                        &cmdline,
                        &mut machine,
                        &mut session,
                        &mut run_remaining,
                        &worker_evt_tx,
                    );
                    let _ = prompt_tx.send(());
                    if should_exit {
                        return;
                    }
                }
                Err(mpsc::RecvTimeoutError::Timeout) => {}
                Err(mpsc::RecvTimeoutError::Disconnected) => return,
            }
        }
    });

    struct PreviewApp {
        frame: Option<(Vec<u8>, u32, u32)>,
        rx: Receiver<String>,
        worker_cmd_tx: mpsc::Sender<String>,
        worker_evt_rx: Receiver<WorkerEvent>,
        window: Option<Rc<Window>>,
        context: Option<Context<Rc<Window>>>,
        surface: Option<Surface<Rc<Window>, Rc<Window>>>,
        should_exit: bool,
        error: Option<String>,
        video_size: (u32, u32),
        topmost: bool,
    }

    impl PreviewApp {
        fn handle_command(&mut self, cmdline: &str) {
            let cmd = cmdline
                .split_whitespace()
                .next()
                .unwrap_or("")
                .to_ascii_lowercase();
            if cmdline.is_empty() {
                return;
            }
            match cmd.as_str() {
                "__quit__" | "quit" | "exit" => {
                    self.should_exit = true;
                    let _ = self.worker_cmd_tx.send("__quit__".to_string());
                }
                _ => {
                    let _ = self.worker_cmd_tx.send(cmdline.to_string());
                }
            }
        }
    }

    impl ApplicationHandler for PreviewApp {
        fn resumed(&mut self, event_loop: &ActiveEventLoop) {
            if self.window.is_some() {
                return;
            }
            event_loop.set_control_flow(ControlFlow::Poll);
            let (vw, vh) = self.video_size;
            let window = match event_loop.create_window(
                Window::default_attributes()
                    .with_title("CHIPcade Preview")
                    .with_window_level(if self.topmost {
                        WindowLevel::AlwaysOnTop
                    } else {
                        WindowLevel::Normal
                    })
                    .with_inner_size(LogicalSize::new((vw * 3) as f64, (vh * 3) as f64))
                    .with_min_inner_size(LogicalSize::new(vw as f64, vh as f64)),
            ) {
                Ok(w) => Rc::new(w),
                Err(e) => {
                    self.error = Some(format!("Failed to create window: {e}"));
                    event_loop.exit();
                    return;
                }
            };

            let context = match Context::new(window.clone()) {
                Ok(c) => c,
                Err(e) => {
                    self.error = Some(format!("Failed to create surface context: {e}"));
                    event_loop.exit();
                    return;
                }
            };
            let surface = match Surface::new(&context, window.clone()) {
                Ok(s) => s,
                Err(e) => {
                    self.error = Some(format!("Failed to create softbuffer surface: {e}"));
                    event_loop.exit();
                    return;
                }
            };
            self.window = Some(window);
            self.context = Some(context);
            self.surface = Some(surface);
        }

        fn about_to_wait(&mut self, event_loop: &ActiveEventLoop) {
            while let Ok(cmd) = self.rx.try_recv() {
                self.handle_command(&cmd);
            }
            while let Ok(evt) = self.worker_evt_rx.try_recv() {
                match evt {
                    WorkerEvent::Frame(rgba, w, h) => {
                        self.frame = Some((rgba, w, h));
                    }
                }
            }
            if self.should_exit {
                event_loop.exit();
                return;
            }
            if let Some(window) = &self.window {
                window.request_redraw();
            }
        }

        fn window_event(
            &mut self,
            event_loop: &ActiveEventLoop,
            _window_id: winit::window::WindowId,
            event: WindowEvent,
        ) {
            match event {
                WindowEvent::CloseRequested => {
                    let _ = self.worker_cmd_tx.send("__quit__".to_string());
                    event_loop.exit();
                }
                WindowEvent::RedrawRequested => {
                    let (Some(window), Some(surface)) = (&self.window, self.surface.as_mut())
                    else {
                        return;
                    };
                    let size = window.inner_size();
                    let width = size.width.max(1);
                    let height = size.height.max(1);
                    if let (Some(nw), Some(nh)) = (NonZeroU32::new(width), NonZeroU32::new(height))
                    {
                        let _ = surface.resize(nw, nh);
                    }
                    let Ok(mut buffer) = surface.buffer_mut() else {
                        return;
                    };
                    for p in buffer.iter_mut() {
                        *p = 0;
                    }
                    if let Some((rgba, src_w, src_h)) = &self.frame {
                        blit_rgba_scaled(
                            rgba,
                            *src_w,
                            *src_h,
                            width as usize,
                            height as usize,
                            &mut buffer,
                        );
                    }
                    let _ = buffer.present();
                }
                _ => {}
            }
        }
    }

    fn blit_rgba_scaled(
        src: &[u8],
        src_w: u32,
        src_h: u32,
        dst_w: usize,
        dst_h: usize,
        dst: &mut [u32],
    ) {
        if src_w == 0 || src_h == 0 || dst_w == 0 || dst_h == 0 {
            return;
        }
        let scale_x = dst_w as u32 / src_w;
        let scale_y = dst_h as u32 / src_h;
        let scale = scale_x.min(scale_y).max(1);
        let draw_w = (src_w * scale) as usize;
        let draw_h = (src_h * scale) as usize;
        let off_x = (dst_w.saturating_sub(draw_w)) / 2;
        let off_y = (dst_h.saturating_sub(draw_h)) / 2;
        for y in 0..draw_h {
            let sy = (y / scale as usize) as usize;
            for x in 0..draw_w {
                let sx = (x / scale as usize) as usize;
                let si = (sy * src_w as usize + sx) * 4;
                if si + 2 >= src.len() {
                    continue;
                }
                let di = (off_y + y) * dst_w + (off_x + x);
                if di < dst.len() {
                    dst[di] = ((src[si] as u32) << 16)
                        | ((src[si + 1] as u32) << 8)
                        | (src[si + 2] as u32);
                }
            }
        }
    }

    let event_loop = match EventLoop::new() {
        Ok(ev) => ev,
        Err(e) => {
            eprintln!("Failed to create event loop: {e}");
            return;
        }
    };

    let mut app = PreviewApp {
        frame: None,
        rx,
        worker_cmd_tx,
        worker_evt_rx,
        window: None,
        context: None,
        surface: None,
        should_exit: false,
        error: None,
        video_size: (vw, vh),
        topmost,
    };
    if let Err(e) = event_loop.run_app(&mut app) {
        eprintln!("Run loop error: {e}");
    }
    if let Some(e) = app.error {
        eprintln!("{e}");
    }
}

#[cfg(not(target_arch = "wasm32"))]
fn parse_usize(tok: Option<&str>, default: usize) -> usize {
    match tok {
        Some(v) => v.parse::<usize>().ok().unwrap_or(default),
        None => default,
    }
}

#[cfg(not(target_arch = "wasm32"))]
fn repl_history_path(project: &std::path::Path) -> PathBuf {
    project.join(".chipcade_history")
}

#[cfg(not(target_arch = "wasm32"))]
fn parse_addr(token: &str, session: &crate::machine::DebugSession) -> Result<u16, String> {
    if let Some(v) = session.label_address(token) {
        return Ok(v);
    }
    eval_expression(token)
        .map_err(|e| format!("Invalid address `{token}`: {e}"))
        .and_then(|v| {
            if !(0..=0xFFFF).contains(&v.value) {
                Err(format!("Address out of range: {}", v.value))
            } else {
                Ok(v.value as u16)
            }
        })
}

#[cfg(not(target_arch = "wasm32"))]
fn print_step(session: &crate::machine::DebugSession, step: Option<&crate::machine::DebugStep>) {
    let regs = session.peek_registers();
    println!("\x1b[1;36mregs:\x1b[0m");
    println!(
        "\t\x1b[33mPC\x1b[0m=${:04X}\t\x1b[33mA\x1b[0m={:02X}\t\x1b[33mX\x1b[0m={:02X}\t\x1b[33mY\x1b[0m={:02X}\t\x1b[33mSP\x1b[0m={:02X}\t\x1b[33mP\x1b[0m={:02X}",
        regs.pc, regs.a, regs.x, regs.y, regs.sp, regs.status
    );

    println!("\x1b[1;36msrc:\x1b[0m");
    if let Some(src) = session.peek_source_line() {
        println!("\t{}:{}\t{}", src.file, src.line, src.text);
    } else if let Some(line) = session.peek_line() {
        println!("\t{}:{}", line.file, line.line);
    } else {
        println!("\t(no mapped source line)");
    }

    println!("\x1b[1;36masm:\x1b[0m");
    let asm_window = session.peek_asm_window(3);
    if asm_window.is_empty() {
        println!("\t(no asm mapping)");
    } else {
        for line in asm_window {
            let marker = if line.is_current {
                "\x1b[1;32m>\x1b[0m"
            } else {
                " "
            };
            println!(
                "\t{} {:04}\t{}",
                marker,
                line.line,
                colorize_asm_line(&line.text)
            );
        }
    }

    if let Some(step) = step {
        if let Some(stop) = &step.stop_reason {
            println!("\x1b[1;31mstop:\x1b[0m\n\t{}", stop);
        } else if let Some(line) = &step.line {
            println!("\x1b[1;35mlast:\x1b[0m\n\t{}:{}", line.file, line.line);
        }
    }
}

#[cfg(not(target_arch = "wasm32"))]
fn colorize_asm_line(text: &str) -> String {
    let trimmed = text.trim_start();
    if trimmed.is_empty() {
        return text.to_string();
    }
    if trimmed.ends_with(':') {
        return format!("\x1b[35m{}\x1b[0m", text);
    }
    let mut parts = trimmed.split_whitespace();
    let Some(first) = parts.next() else {
        return text.to_string();
    };
    let leading_ws = text.len().saturating_sub(trimmed.len());
    let prefix = " ".repeat(leading_ws);
    let rest = trimmed[first.len()..].to_string();
    format!("{prefix}\x1b[36m{first}\x1b[0m{rest}")
}

#[cfg(not(target_arch = "wasm32"))]
fn is_terminal_stop(step: &crate::machine::DebugStep) -> bool {
    match step.stop_reason.as_deref() {
        Some("Init BRK -> Update") => false,
        Some(_) => true,
        None => false,
    }
}

#[cfg(not(target_arch = "wasm32"))]
fn is_update_frame_boundary(
    session: &mut crate::machine::DebugSession,
    step: &crate::machine::DebugStep,
) -> bool {
    if step.stop_reason.is_some() {
        return false;
    }
    session.read_byte(step.registers.pc) == 0x00
}

#[cfg(not(target_arch = "wasm32"))]
fn dump_mem(session: &mut crate::machine::DebugSession, addr: u16, len: usize) {
    let bytes = session.read_bytes(addr, len);
    for (row_idx, chunk) in bytes.chunks(16).enumerate() {
        let row_addr = addr.wrapping_add((row_idx * 16) as u16);
        print!("{:04X}: ", row_addr);
        for b in chunk {
            print!("{:02X} ", b);
        }
        for _ in 0..(16 - chunk.len()) {
            print!("   ");
        }
        print!("|");
        for b in chunk {
            let c = if (0x20..=0x7E).contains(b) {
                *b as char
            } else {
                '.'
            };
            print!("{c}");
        }
        println!("|");
    }
}

#[cfg(target_arch = "wasm32")]
fn main() {
    console_error_panic_hook::set_once();
    if let Err(e) = run_wasm_player() {
        web_sys::console::error_1(&e.into());
    }
}

#[cfg(target_arch = "wasm32")]
fn run_wasm_player() -> Result<(), String> {
    use crate::bus::ChipcadeBus;
    use mos6502::cpu;
    use mos6502::instruction::Nmos6502;
    use mos6502::memory::Bus;
    use std::cell::RefCell;
    use std::rc::Rc;
    use wasm_bindgen::Clamped;
    use wasm_bindgen::JsCast;
    use wasm_bindgen::closure::Closure;
    use web_sys::KeyboardEvent;

    fn key_to_input_mask(key: &str) -> Option<u8> {
        match key {
            "ArrowLeft" | "a" | "A" => Some(0x01),
            "ArrowRight" | "d" | "D" => Some(0x02),
            "ArrowUp" | "w" | "W" => Some(0x04),
            "ArrowDown" | "s" | "S" => Some(0x08),
            " " | "Enter" | "z" | "Z" | "x" | "X" => Some(0x10),
            _ => None,
        }
    }

    fn run_frame_cpu(cpu: &mut cpu::CPU<ChipcadeBus, Nmos6502>, entry_point: u16) -> Vec<u8> {
        cpu.registers.program_counter = entry_point;
        let mut steps: u64 = 0;
        loop {
            if steps >= 1_000_000 {
                break;
            }
            let pc = cpu.registers.program_counter;
            let opcode = cpu.memory.get_byte(pc);
            if opcode == 0x00 || opcode == 0xFF {
                break;
            }
            cpu.single_step();
            steps += 1;
        }
        cpu.memory.render_frame_rgba()
    }

    struct WasmState {
        cpu: cpu::CPU<ChipcadeBus, Nmos6502>,
        update_entry: u16,
        ctx: web_sys::CanvasRenderingContext2d,
        width: u32,
        height: u32,
    }

    let image = include_bytes!("../build/program.bin");
    let (meta, artifacts) = Machine::artifacts_from_image(image)?;
    let machine = Machine::from_build_meta(meta);
    let mut cpu = machine.create_cpu(
        &artifacts.program,
        &artifacts.sprites,
        artifacts.entry_point,
    )?;

    let init = Machine::label_address(&artifacts.labels, "Init").or(artifacts.entry_point);
    if let Some(addr) = init {
        let init_entry = machine.entry_address(Some(addr));
        let _ = run_frame_cpu(&mut cpu, init_entry);
    }
    let update = Machine::label_address(&artifacts.labels, "Update").or(artifacts.entry_point);
    let update_entry = machine.entry_address(update);

    let (width, height) = machine.video_size();

    let window = web_sys::window().ok_or_else(|| "window not available".to_string())?;
    let document = window
        .document()
        .ok_or_else(|| "document not available".to_string())?;
    let body = document
        .body()
        .ok_or_else(|| "document.body not available".to_string())?;
    let canvas = document
        .create_element("canvas")
        .map_err(|e| format!("failed to create canvas: {e:?}"))?
        .dyn_into::<web_sys::HtmlCanvasElement>()
        .map_err(|_| "created element is not a canvas".to_string())?;
    canvas.set_width(width);
    canvas.set_height(height);
    canvas.set_tab_index(0);
    let style = format!(
        "width:{}px;height:{}px;image-rendering:pixelated;image-rendering:crisp-edges;",
        width.saturating_mul(3),
        height.saturating_mul(3)
    );
    canvas
        .set_attribute("style", &style)
        .map_err(|e| format!("failed to set canvas style: {e:?}"))?;
    body.append_child(&canvas)
        .map_err(|e| format!("failed to append canvas: {e:?}"))?;

    let ctx = canvas
        .get_context("2d")
        .map_err(|e| format!("failed to get 2d context: {e:?}"))?
        .ok_or_else(|| "2d context unavailable".to_string())?
        .dyn_into::<web_sys::CanvasRenderingContext2d>()
        .map_err(|_| "context is not CanvasRenderingContext2d".to_string())?;

    let state = Rc::new(RefCell::new(WasmState {
        cpu,
        update_entry,
        ctx,
        width,
        height,
    }));
    let input_bits = Rc::new(RefCell::new(0u8));

    let keydown_bits = Rc::clone(&input_bits);
    let keydown = Closure::<dyn FnMut(KeyboardEvent)>::new(move |event: KeyboardEvent| {
        if let Some(mask) = key_to_input_mask(&event.key()) {
            let mut bits = keydown_bits.borrow_mut();
            *bits |= mask;
            event.prevent_default();
        }
    });
    window
        .add_event_listener_with_callback("keydown", keydown.as_ref().unchecked_ref())
        .map_err(|e| format!("failed to register keydown: {e:?}"))?;

    let keyup_bits = Rc::clone(&input_bits);
    let keyup = Closure::<dyn FnMut(KeyboardEvent)>::new(move |event: KeyboardEvent| {
        if let Some(mask) = key_to_input_mask(&event.key()) {
            let mut bits = keyup_bits.borrow_mut();
            *bits &= !mask;
            event.prevent_default();
        }
    });
    window
        .add_event_listener_with_callback("keyup", keyup.as_ref().unchecked_ref())
        .map_err(|e| format!("failed to register keyup: {e:?}"))?;

    let blur_bits = Rc::clone(&input_bits);
    let blur = Closure::<dyn FnMut()>::new(move || {
        let mut bits = blur_bits.borrow_mut();
        *bits = 0;
    });
    window
        .add_event_listener_with_callback("blur", blur.as_ref().unchecked_ref())
        .map_err(|e| format!("failed to register blur: {e:?}"))?;
    let _ = canvas.focus();

    let hz = machine.config().machine.refresh_hz.max(1);
    let interval_ms = (1000u32 / hz).max(1) as i32;

    let tick_state = Rc::clone(&state);
    let tick_input_bits = Rc::clone(&input_bits);
    let tick = Closure::<dyn FnMut()>::new(move || {
        let mut state = tick_state.borrow_mut();
        let bits = *tick_input_bits.borrow();
        state.cpu.memory.set_input_state(bits);
        let update_entry = state.update_entry;
        let rgba = run_frame_cpu(&mut state.cpu, update_entry);
        let img = web_sys::ImageData::new_with_u8_clamped_array_and_sh(
            Clamped(rgba.as_slice()),
            state.width,
            state.height,
        );
        match img {
            Ok(image_data) => {
                if let Err(e) = state.ctx.put_image_data(&image_data, 0.0, 0.0) {
                    web_sys::console::error_1(&format!("put_image_data failed: {e:?}").into());
                }
            }
            Err(e) => web_sys::console::error_1(&format!("ImageData failed: {e:?}").into()),
        }
    });

    window
        .set_interval_with_callback_and_timeout_and_arguments_0(
            tick.as_ref().unchecked_ref(),
            interval_ms,
        )
        .map_err(|e| format!("setInterval failed: {e:?}"))?;
    keydown.forget();
    keyup.forget();
    blur.forget();
    tick.forget();

    Ok(())
}

fn create_sprite_file(project: &PathBuf, name: &str, size: u8) -> Result<(), String> {
    use std::fs;

    if size != 8 && size != 16 {
        return Err("Size must be 8 or 16".to_string());
    }

    if name.is_empty() {
        return Err("Sprite name cannot be empty".to_string());
    }

    if !name
        .chars()
        .all(|c| c.is_ascii_alphanumeric() || c == '_' || c == '-')
    {
        return Err(
            "Sprite name must contain only alphanumeric characters, '_', or '-'".to_string(),
        );
    }

    let sprites_dir = project.join("assets/sprites");
    fs::create_dir_all(&sprites_dir)
        .map_err(|e| format!("Failed to create sprites directory: {e}"))?;

    let sprite_path = sprites_dir.join(format!("{}.spr", name));
    if sprite_path.exists() {
        return Err(format!("Sprite '{}' already exists", name));
    }

    let template = generate_sprite_template(size);
    fs::write(&sprite_path, template).map_err(|e| format!("Failed to write sprite file: {e}"))?;

    println!("Created sprite: {}", sprite_path.display());
    Ok(())
}

fn remove_sprite_file(project: &PathBuf, name: &str) -> Result<(), String> {
    use std::fs;

    if name.is_empty() {
        return Err("Sprite name cannot be empty".to_string());
    }

    let sprites_dir = project.join("assets/sprites");
    if !sprites_dir.exists() {
        return Err("Sprites directory does not exist".to_string());
    }

    let sprite_path = sprites_dir.join(format!("{}.spr", name));
    if !sprite_path.exists() {
        return Err(format!("Sprite '{}' does not exist", name));
    }

    fs::remove_file(&sprite_path).map_err(|e| format!("Failed to remove sprite file: {e}"))?;

    println!("Removed sprite: {}", sprite_path.display());
    Ok(())
}

fn generate_sprite_template(size: u8) -> String {
    // Load templates from embedded assets
    const TEMPLATE_8X8: &str = include_str!("../embedded/assets/sprites/template_8x8.spr");
    const TEMPLATE_16X16: &str = include_str!("../embedded/assets/sprites/template_16x16.spr");

    let template = match size {
        8 => TEMPLATE_8X8,
        16 => TEMPLATE_16X16,
        _ => return String::new(),
    };

    template.to_string()
}
