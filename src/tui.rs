use std::error::Error;
use std::path::PathBuf;
use std::time::Duration;

use crossterm::{
    event::{self, Event, KeyCode},
    execute,
    terminal::{EnterAlternateScreen, LeaveAlternateScreen, disable_raw_mode, enable_raw_mode},
};
use ratatui::{
    Frame, Terminal,
    backend::CrosstermBackend,
    layout::{Constraint, Direction, Layout, Rect},
    style::{Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, List, ListItem, Paragraph, Wrap},
};

use crate::project::{ProjectPaths, RunArtifacts, assemble_and_run};

pub fn launch_tui(project: PathBuf) -> Result<(), Box<dyn Error>> {
    enable_raw_mode()?;
    let mut stdout = std::io::stdout();
    execute!(stdout, EnterAlternateScreen)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    let mut app = App::new(project);
    let res = run_app(&mut terminal, &mut app);

    disable_raw_mode()?;
    execute!(terminal.backend_mut(), LeaveAlternateScreen)?;
    terminal.show_cursor()?;

    if let Err(err) = res {
        eprintln!("{err}");
    }

    Ok(())
}

struct App {
    project: PathBuf,
    last_artifacts: Option<RunArtifacts>,
    last_message: String,
}

impl App {
    fn new(project: PathBuf) -> Self {
        Self {
            project,
            last_artifacts: None,
            last_message: "Press 'r' to assemble/run, 'q' to quit".to_string(),
        }
    }

    fn run(&mut self) {
        let paths = ProjectPaths::new(&self.project);
        match assemble_and_run(&paths) {
            Ok(art) => {
                self.last_message =
                    format!("Run finished: steps={}, reason={}", art.steps, art.reason);
                self.last_artifacts = Some(art);
            }
            Err(e) => {
                self.last_message = e;
            }
        }
    }
}

fn run_app<B: ratatui::backend::Backend>(
    terminal: &mut Terminal<B>,
    app: &mut App,
) -> Result<(), Box<dyn Error>> {
    loop {
        terminal.draw(|f| ui(f, app))?;

        if event::poll(Duration::from_millis(200))? {
            if let Event::Key(key) = event::read()? {
                match key.code {
                    KeyCode::Char('q') => return Ok(()),
                    KeyCode::Char('r') => app.run(),
                    _ => {}
                }
            }
        }
    }
}

fn ui(f: &mut Frame, app: &App) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .margin(1)
        .constraints(
            [
                Constraint::Length(3),
                Constraint::Min(5),
                Constraint::Length(2),
            ]
            .as_ref(),
        )
        .split(f.size());

    let header = Paragraph::new(app.last_message.as_str())
        .block(Block::default().borders(Borders::ALL).title("Status"));
    f.render_widget(header, chunks[0]);

    let body_chunks = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Percentage(40), Constraint::Percentage(60)].as_ref())
        .split(chunks[1]);

    render_left(f, body_chunks[0], app);
    render_right(f, body_chunks[1], app);

    let footer =
        Paragraph::new("Keys: r=run, q=quit").block(Block::default().borders(Borders::ALL));
    f.render_widget(footer, chunks[2]);
}

fn render_left(f: &mut Frame, area: Rect, app: &App) {
    let mut lines: Vec<ListItem> = Vec::new();
    if let Some(art) = &app.last_artifacts {
        lines.push(ListItem::new(format!(
            "Video: {}x{} {}",
            art.config.video.width, art.config.video.height, art.config.video.mode
        )));
        lines.push(ListItem::new(format!(
            "CPU: {} clock: {}Hz",
            art.config.machine.cpu, art.config.machine.clock_hz
        )));
        lines.push(ListItem::new(format!("Steps: {}", art.steps)));
        lines.push(ListItem::new(format!("Reason: {}", art.reason)));
        lines.push(ListItem::new("".to_string()));
        lines.push(ListItem::new("System consts:"));
        for c in &art.sys_consts {
            let val = if c.is_hex {
                format!("${:04X}", c.value)
            } else {
                format!("{}", c.value)
            };
            lines.push(ListItem::new(format!("  {:<12}= {}", c.name, val)));
        }
    } else {
        lines.push(ListItem::new("No run yet. Press 'r'.".to_string()));
    }

    let list = List::new(lines).block(Block::default().borders(Borders::ALL).title("Info"));
    f.render_widget(list, area);
}

fn render_right(f: &mut Frame, area: Rect, app: &App) {
    let mut lines: Vec<Line> = Vec::new();
    if let Some(art) = &app.last_artifacts {
        lines.push(Line::from(Span::styled(
            "Program (hex):",
            Style::default().add_modifier(Modifier::BOLD),
        )));
        lines.extend(hex_dump(&art.program, 16));
    } else {
        lines.push(Line::from("Program (hex): --"));
    }

    let para = Paragraph::new(lines)
        .block(Block::default().borders(Borders::ALL).title("Program"))
        .wrap(Wrap { trim: false });
    f.render_widget(para, area);
}

fn hex_dump(bytes: &[u8], width: usize) -> Vec<Line<'static>> {
    let mut out = Vec::new();
    for (i, chunk) in bytes.chunks(width).enumerate() {
        let addr = i * width;
        let hex: Vec<String> = chunk.iter().map(|b| format!("{:02X}", b)).collect();
        out.push(Line::from(format!("{:04X}: {}", addr, hex.join(" "))));
    }
    if out.is_empty() {
        out.push(Line::from("0000:"));
    }
    out
}
