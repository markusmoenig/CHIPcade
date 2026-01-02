mod bus;
mod config;
mod project;

use clap::{Parser, Subcommand};
use std::path::PathBuf;

use project::{run_project, scaffold_project};

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
    });

    match command {
        Commands::Run { project } => run_project(project),
        Commands::New { name } => scaffold_project(name),
        Commands::Info { project } => project::info_project(project),
    }
}
