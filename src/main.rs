mod bus;
mod config;
mod editor;
mod machine;
mod player;

use clap::{Parser, Subcommand};
use machine::{Machine, scaffold_project};
use std::path::PathBuf;
use theframework::prelude::*;

pub mod prelude {

    pub use crate::{
        bus::{ChipcadeBus, Palette},
        config::Config,
        machine::Machine,
    };

    pub use crate::editor::prelude::*;
}

#[derive(Parser)]
#[command(name = "chipcade", about = "Chipcade toolchain driver", version)]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
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
    /// Launch the UI-based editor (future)
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
}

fn main() {
    let cli = Cli::parse();
    let command = cli.command.unwrap_or(Commands::Run {
        project: PathBuf::from("."),
        scale: 3,
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
    }
}
