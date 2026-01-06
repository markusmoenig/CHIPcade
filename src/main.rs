mod bus;
mod config;
mod editor;
mod eval;
mod machine;
mod player;
mod sprites;

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
#[command(name = "chipcade", about = "CHIPcade toolchain driver", version)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
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
    /// Sprite management commands
    Sprites {
        #[command(subcommand)]
        command: SpriteCommands,
    },
    /// Build a distributable 64 KB binary image
    Build {
        /// Project root (contains chipcade.toml, asm/, build/, etc.)
        #[arg(default_value = ".")]
        project: PathBuf,
    },
}

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

fn main() {
    let cli = Cli::parse();

    match cli.command {
        Commands::Run { project, scale } => match Machine::new(project) {
            Ok(machine) => match machine.build() {
                Ok(artifacts) => {
                    let mut player = crate::player::player::Player::new();
                    player.set_machine_with_artifacts(machine, artifacts, scale);
                    let app = TheApp::new();
                    () = app.run(Box::new(player));
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
        Commands::New { name } => scaffold_project(name),
        Commands::Info { project } => match Machine::new(project) {
            Ok(machine) => machine.print_info(),
            Err(e) => eprintln!("{e}"),
        },
        Commands::Edit { project } => match Machine::new(project) {
            Ok(machine) => {
                println!("Launching editor …");
                match machine.assemble() {
                    Ok(_) => {
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
