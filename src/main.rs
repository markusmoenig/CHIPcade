mod bus;
mod config;
mod editor;
mod eval;
mod machine;
mod player;

use clap::{Parser, Subcommand};
use eval::{EvalResult, eval_expression};
use machine::{Machine, scaffold_project};
use std::path::PathBuf;
use theframework::prelude::*;

pub mod prelude {

    pub use crate::{
        bus::{ChipcadeBus, Palette},
        config::Config,
        eval::{EvalResult, eval_expression},
        machine::Machine,
    };

    pub use crate::editor::prelude::*;
}

#[derive(Parser)]
#[command(
    name = "chipcade",
    about = "CHIPcade toolchain driver",
    version,
    subcommand_precedence_over_arg = true
)]
struct Cli {
    /// Subcommands (default: run)
    #[command(subcommand)]
    command: Option<Commands>,
    /// Project root (used when no subcommand is provided; defaults to current dir)
    #[arg(default_value = ".")]
    project: PathBuf,
    /// Scale factor for rendering/output when running (default subcommand)
    #[arg(long, default_value_t = 3)]
    scale: u32,
}

#[derive(Subcommand)]
enum Commands {
    /// Assemble and run a project (default)
    Run {
        /// Project root (contains chipcade.toml, asm/, build/, etc.)
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
}

fn main() {
    let cli = Cli::parse();
    let command = cli.command.unwrap_or(Commands::Run {
        project: cli.project.clone(),
        scale: cli.scale,
    });

    match command {
        Commands::Run { project, scale } => match Machine::new(project) {
            Ok(machine) => match machine.assemble() {
                Ok(_bytes) => {
                    let mut player = crate::player::player::Player::new();
                    player.set_machine(machine, scale);
                    let app = TheApp::new();
                    () = app.run(Box::new(player));
                }
                Err(e) => eprintln!("{e}"),
            },
            Err(e) => eprintln!("{e}"),
        },
        Commands::New { name } => scaffold_project(name),
        Commands::Info { project } => match Machine::new(project) {
            Ok(machine) => machine.print_info(),
            Err(e) => eprintln!("{e}"),
        },
        Commands::Edit { project } => match Machine::new(project) {
            Ok(machine) => {
                println!("Launching editor (preview)…");
                match machine.assemble() {
                    Ok(_bytes) => {
                        let mut editor = crate::editor::editor::Editor::new();
                        editor.set_machine(machine);
                        editor.set_integer_scale(false);
                        editor.set_vertical_margin(10);
                        let app = TheApp::new();
                        () = app.run(Box::new(editor));
                    }
                    Err(e) => eprintln!("{e}"),
                }
            }
            Err(e) => eprintln!("{e}"),
        },
        Commands::Eval { expr } => {
            let expression = expr.join(" ");
            match eval_expression(&expression) {
                Ok(EvalResult { value }) => {
                    let abs = value.saturating_abs() as u64;
                    let sign = if value < 0 { "-" } else { "" };
                    let hex = format!("{sign}${:X}", abs);
                    let bin = format!("{sign}%{:b}", abs);
                    println!("dec = {value}, hex = {hex}, bin = {bin}");
                }
                Err(e) => eprintln!("Eval error: {e}"),
            }
        }
    }
}
