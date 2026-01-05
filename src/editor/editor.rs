use crate::machine::EmbeddedAssets;
use crate::machine::{BuildArtifacts, DebugSession, Machine};
use crate::prelude::*;
use image::load_from_memory;
use mos6502::cpu;
use mos6502::instruction::Nmos6502;
use theframework::prelude::*;

use std::sync::mpsc::Receiver;

#[derive(Debug, PartialEq, Copy, Clone)]
enum EditorState {
    Idle,
    Playing,
    Debugging,
}

pub struct Editor {
    machine: Machine,
    frame: Option<(Vec<u8>, u32, u32)>,

    artifacts: Option<BuildArtifacts>,
    cpu: Option<cpu::CPU<ChipcadeBus, Nmos6502>>,

    integer_scale: bool,
    vertical_margin: u32,
    did_init: bool,
    state: EditorState,
    debug_session: Option<DebugSession>,
    debug_running: bool,

    event_receiver: Option<Receiver<TheEvent>>,

    sidebar: Sidebar,
    context: Context,
}

impl Editor {
    pub fn set_machine(&mut self, machine: Machine) {
        self.machine = machine;
        self.frame = None;
        self.artifacts = None;
        self.cpu = None;
        self.did_init = false;
        self.debug_session = None;
        self.debug_running = false;
    }

    pub fn set_integer_scale(&mut self, integer_scale: bool) {
        self.integer_scale = integer_scale;
    }

    pub fn set_vertical_margin(&mut self, margin: u32) {
        self.vertical_margin = margin;
    }

    fn ensure_frame(&mut self) {
        // Assemble once, then run one frame each draw using a persistent CPU.
        let artifacts = match self.artifacts.clone() {
            Some(a) => a,
            None => match self.machine.assemble_silent() {
                Ok(a) => {
                    self.artifacts = Some(a.clone());
                    a
                }
                Err(e) => {
                    eprintln!("{e}");
                    return;
                }
            },
        };

        let cpu = self.cpu.get_or_insert_with(|| {
            self.machine
                .create_cpu(
                    &artifacts.program,
                    &artifacts.sprites,
                    artifacts.entry_point,
                )
                .expect("failed to create CPU")
        });

        // Run Init once if present; otherwise fall back to Start/entry_point.
        if !self.did_init {
            let init = Machine::label_address(&artifacts.labels, "Init").or(artifacts.entry_point);
            if let Some(addr) = init {
                let init_entry = self.machine.entry_address(Some(addr));
                let (_rgba, _steps, _reason) = self.machine.run_frame(cpu, init_entry);
            }
        }

        if self.state == EditorState::Playing
            || (self.state == EditorState::Idle && self.did_init == false)
        {
            // Per-frame Update; fallback to Start/entry_point if missing.
            let update =
                Machine::label_address(&artifacts.labels, "Update").or(artifacts.entry_point);
            let update_entry = self.machine.entry_address(update);
            let (rgba, _steps, _reason) = self.machine.run_frame(cpu, update_entry);
            let (w, h) = self.machine.video_size();
            self.frame = Some((rgba, w, h));
        }

        self.did_init = true;
    }
}

impl TheTrait for Editor {
    fn new() -> Self
    where
        Self: Sized,
    {
        Self {
            machine: Machine::default(),
            frame: None,
            integer_scale: false,
            vertical_margin: 2,
            did_init: false,

            artifacts: None,
            cpu: None,
            state: EditorState::Idle,
            debug_session: None,
            debug_running: false,

            event_receiver: None,

            sidebar: Sidebar::new(),
            context: Context::new(),
        }
    }

    fn window_title(&self) -> String {
        "CHIPcade — 6502 Fantasy Console".into()
    }

    fn default_window_size(&self) -> (usize, usize) {
        (1200, 720)
    }

    fn init_ui(&mut self, ui: &mut TheUI, ctx: &mut TheContext) {
        // Embedded Icons
        for file in EmbeddedAssets::iter() {
            let name: &str = file.as_ref();

            if name.ends_with(".png") {
                if let Some(file) = EmbeddedAssets::get(name) {
                    if let Ok(img) = load_from_memory(&file.data) {
                        let rgba = img.to_rgba8();
                        let (w, h) = rgba.dimensions();

                        let mut cut_name = name.replace("icons/", "");
                        cut_name = cut_name.replace(".png", "");

                        ctx.ui.add_icon(
                            cut_name.to_string(),
                            TheRGBABuffer::from(rgba.into_raw(), w, h),
                        );
                    }
                }
            }
        }

        ui.set_statusbar_name("Statusbar".to_string());

        // Menu

        let mut menu_canvas = TheCanvas::new();
        let mut menu = TheMenu::new(TheId::named("Menu"));

        let mut file_menu = TheContextMenu::named("File".to_string());
        file_menu.add(TheContextMenuItem::new_with_accel(
            "Save".to_string(),
            TheId::named("Save"),
            TheAccelerator::new(TheAcceleratorKey::CTRLCMD, 's'),
        ));
        let mut edit_menu = TheContextMenu::named("Edit".to_string());
        edit_menu.add(TheContextMenuItem::new_with_accel(
            "Undo".to_string(),
            TheId::named("Undo"),
            TheAccelerator::new(TheAcceleratorKey::CTRLCMD, 'z'),
        ));
        edit_menu.add(TheContextMenuItem::new_with_accel(
            "Redo".to_string(),
            TheId::named("Redo"),
            TheAccelerator::new(TheAcceleratorKey::CTRLCMD | TheAcceleratorKey::SHIFT, 'z'),
        ));
        edit_menu.add_separator();
        edit_menu.add(TheContextMenuItem::new_with_accel(
            "Cut".to_string(),
            TheId::named("Cut"),
            TheAccelerator::new(TheAcceleratorKey::CTRLCMD, 'x'),
        ));
        edit_menu.add(TheContextMenuItem::new_with_accel(
            "Copy".to_string(),
            TheId::named("Copy"),
            TheAccelerator::new(TheAcceleratorKey::CTRLCMD, 'c'),
        ));
        edit_menu.add(TheContextMenuItem::new_with_accel(
            "Paste".to_string(),
            TheId::named("Paste"),
            TheAccelerator::new(TheAcceleratorKey::CTRLCMD, 'v'),
        ));

        let mut actions_menu = TheContextMenu::named("Actions".to_string());
        actions_menu.add(TheContextMenuItem::new_with_accel(
            "Play".to_string(),
            TheId::named("Play"),
            TheAccelerator::new(TheAcceleratorKey::CTRLCMD, 'p'),
        ));
        actions_menu.add(TheContextMenuItem::new_with_accel(
            "Stop".to_string(),
            TheId::named("Stop"),
            TheAccelerator::new(TheAcceleratorKey::CTRLCMD, 'b'),
        ));
        actions_menu.add_separator();
        actions_menu.add(TheContextMenuItem::new_with_accel(
            "Debug".to_string(),
            TheId::named("Debug"),
            TheAccelerator::new(TheAcceleratorKey::CTRLCMD, 'd'),
        ));
        actions_menu.add(TheContextMenuItem::new_with_accel(
            "Step".to_string(),
            TheId::named("Step"),
            TheAccelerator::new(TheAcceleratorKey::CTRLCMD, 'e'),
        ));
        actions_menu.add(TheContextMenuItem::new_with_accel(
            "Run to RTS".to_string(),
            TheId::named("RunRTS"),
            TheAccelerator::new(TheAcceleratorKey::CTRLCMD, 't'),
        ));
        actions_menu.add(TheContextMenuItem::new_with_accel(
            "Continue".to_string(),
            TheId::named("Continue"),
            TheAccelerator::new(TheAcceleratorKey::CTRLCMD, 'o'),
        ));
        actions_menu.add(TheContextMenuItem::new_with_accel(
            "Pause".to_string(),
            TheId::named("Pause"),
            TheAccelerator::new(TheAcceleratorKey::CTRLCMD, 'a'),
        ));

        file_menu.register_accel(ctx);
        edit_menu.register_accel(ctx);
        actions_menu.register_accel(ctx);

        menu.add_context_menu(file_menu);
        menu.add_context_menu(edit_menu);
        menu.add_context_menu(actions_menu);
        menu_canvas.set_widget(menu);

        // Menubar
        let mut top_canvas = TheCanvas::new();

        let mut menubar = TheMenubar::new(TheId::named("Menubar"));
        menubar.limiter_mut().set_max_height(43 + 22);

        let mut logo_button = TheMenubarButton::new(TheId::named("Logo"));
        logo_button.set_icon_name("logo".to_string());
        logo_button.set_status_text("Logo");

        let mut save_button = TheMenubarButton::new(TheId::named("Save"));
        save_button.set_status_text("Save the current file to disk");
        save_button.set_icon_name("icon_role_load".to_string());

        let mut undo_button = TheMenubarButton::new(TheId::named("Undo"));
        undo_button.set_status_text("Undo last action");
        undo_button.set_icon_name("icon_role_undo".to_string());

        let mut redo_button = TheMenubarButton::new(TheId::named("Redo"));
        redo_button.set_status_text("Redo last action");
        redo_button.set_icon_name("icon_role_redo".to_string());

        let mut hlayout = TheHLayout::new(TheId::named("Menu Layout"));
        hlayout.set_background_color(None);
        hlayout.set_margin(Vec4::new(10, 2, 10, 1));
        hlayout.add_widget(Box::new(logo_button));
        hlayout.add_widget(Box::new(TheMenubarSeparator::new(TheId::empty())));
        hlayout.add_widget(Box::new(save_button));
        hlayout.add_widget(Box::new(TheMenubarSeparator::new(TheId::empty())));
        hlayout.add_widget(Box::new(undo_button));
        hlayout.add_widget(Box::new(redo_button));

        // hlayout.set_reverse_index(Some(3));

        top_canvas.set_widget(menubar);
        top_canvas.set_layout(hlayout);
        top_canvas.set_top(menu_canvas);
        ui.canvas.set_top(top_canvas);

        let mut editor_canvas: TheCanvas = TheCanvas::new();
        let render_view = TheRenderView::new(TheId::named("RenderView"));
        editor_canvas.set_widget(render_view);

        let mut code_canvas: TheCanvas = TheCanvas::new();
        let mut textedit = TheTextAreaEdit::new(TheId::named("ASMEdit"));
        textedit.set_continuous(true);
        textedit.display_line_number(true);
        textedit.as_code_editor("Python", TheCodeEditorSettings::default());
        textedit.set_code_theme("base16-eighties.dark");
        textedit.use_global_statusbar(true);
        textedit.set_font_size(14.0);

        if let Some(bytes) = crate::machine::EmbeddedAssets::get("parser/gruvbox-dark.tmTheme") {
            if let Ok(source) = std::str::from_utf8(bytes.data.as_ref()) {
                textedit.add_theme_from_string(source);
                textedit.set_code_theme("Gruvbox Dark");
            }
        }

        if let Some(bytes) = crate::machine::EmbeddedAssets::get("parser/6502.sublime-syntax") {
            if let Ok(source) = std::str::from_utf8(bytes.data.as_ref()) {
                textedit.add_syntax_from_string(source);
                textedit.set_code_type("6502 Assembly");
            }
        }
        textedit.as_code_editor(
            "6502",
            TheCodeEditorSettings {
                indicate_space: false,
                ..Default::default()
            },
        );
        code_canvas.set_widget(textedit);

        let mut code_stack_canvas = TheCanvas::new();

        let mut code_layout = TheStackLayout::new(TheId::named("Code Stack"));

        // Sidebar
        self.sidebar
            .init_ui(ui, ctx, &self.machine, &mut self.context, &mut code_layout);
        // code_layout.add_canvas(code_canvas);

        code_stack_canvas.set_layout(code_layout);

        // Toolbar

        let mut toolbar_canvas = TheCanvas::default();
        let traybar_widget = TheTraybar::new(TheId::empty());
        toolbar_canvas.set_widget(traybar_widget);
        let mut toolbar_hlayout = TheHLayout::new(TheId::empty());
        toolbar_hlayout.set_background_color(None);

        let mut play_button = TheTraybarButton::new(TheId::named("Play"));
        play_button.set_icon(ctx.ui.icon("play-fill").unwrap().clone());
        play_button.set_status_text("Play");
        toolbar_hlayout.add_widget(Box::new(play_button));

        toolbar_hlayout.add_widget(Box::new(TheHDivider::new(TheId::empty())));

        let mut debug_button = TheTraybarButton::new(TheId::named("Debug"));
        debug_button.set_icon(ctx.ui.icon("bug-fill").unwrap().clone());
        debug_button.set_status_text("Debug");
        toolbar_hlayout.add_widget(Box::new(debug_button));

        let mut step_button = TheTraybarButton::new(TheId::named("Step"));
        step_button.set_icon(ctx.ui.icon("play-pause-fill").unwrap().clone());
        step_button.set_status_text("Step");
        toolbar_hlayout.add_widget(Box::new(step_button));

        let mut run_rts_button = TheTraybarButton::new(TheId::named("RunRTS"));
        run_rts_button.set_icon(ctx.ui.icon("skip-end-fill").unwrap().clone());
        run_rts_button.set_status_text("Run to RTS");
        toolbar_hlayout.add_widget(Box::new(run_rts_button));

        let mut cont_button = TheTraybarButton::new(TheId::named("Continue"));
        cont_button.set_icon(ctx.ui.icon("play-circle-fill").unwrap().clone());
        cont_button.set_status_text("Continue");
        toolbar_hlayout.add_widget(Box::new(cont_button));

        let mut pause_button = TheTraybarButton::new(TheId::named("Pause"));
        pause_button.set_icon(ctx.ui.icon("pause-fill").unwrap().clone());
        pause_button.set_status_text("Pause");
        toolbar_hlayout.add_widget(Box::new(pause_button));

        toolbar_hlayout.add_widget(Box::new(TheHDivider::new(TheId::empty())));

        let mut stop_button = TheTraybarButton::new(TheId::named("Stop"));
        stop_button.set_icon(ctx.ui.icon("stop-fill").unwrap().clone());
        stop_button.set_status_text("Stop");
        toolbar_hlayout.add_widget(Box::new(stop_button));

        toolbar_canvas.set_layout(toolbar_hlayout);
        code_stack_canvas.set_top(toolbar_canvas);

        // Main V Layout
        let mut vsplitlayout = TheSharedVLayout::new(TheId::named("Shared VLayout"));
        vsplitlayout.add_canvas(editor_canvas);
        vsplitlayout.add_canvas(code_stack_canvas);
        vsplitlayout.set_shared_ratio(0.50);
        vsplitlayout.set_mode(TheSharedVLayoutMode::Shared);

        let mut shared_canvas = TheCanvas::new();
        shared_canvas.set_layout(vsplitlayout);

        ui.canvas.set_center(shared_canvas);

        let mut status_canvas = TheCanvas::new();
        let mut statusbar = TheStatusbar::new(TheId::named("Statusbar"));
        statusbar.set_text("Welcome to CHIPcade".into());
        status_canvas.set_widget(statusbar);

        ui.canvas.set_bottom(status_canvas);

        self.event_receiver = Some(ui.add_state_listener("Main Receiver".into()));
    }

    fn update_ui(&mut self, ui: &mut TheUI, ctx: &mut TheContext) -> bool {
        let mut redraw = true;

        if let Some(render_view) = ui.get_render_view("RenderView") {
            let dim = *render_view.dim();

            let buffer = render_view.render_buffer_mut();
            buffer.resize(dim.width, dim.height);

            if self.state != EditorState::Debugging || self.debug_session.is_none() {
                self.ensure_frame();
            }

            let width = dim.width.max(0) as u32;
            let height = dim.height.max(0) as u32;
            let pixels = buffer.pixels_mut();
            // Clear to black
            for chunk in pixels.chunks_mut(4) {
                chunk.copy_from_slice(&[0, 0, 0, 255]);
            }

            if let Some((ref src, w, h)) = self.frame {
                let sw = w as usize;
                let vpad = (self.vertical_margin * 2).min(height);
                let available_height = height.saturating_sub(vpad);
                let fit = ((width as f32) / (w.max(1) as f32))
                    .min((available_height as f32) / (h.max(1) as f32));
                let scale = if self.integer_scale {
                    fit.max(1.0).floor()
                } else {
                    fit
                };
                if scale > 0.0 {
                    let dw = (w as f32 * scale).round() as i32;
                    let dh = (h as f32 * scale).round() as i32;
                    let ox = ((width as i32 - dw) / 2).max(0);
                    let oy =
                        ((available_height as i32 - dh) / 2 + self.vertical_margin as i32).max(0);
                    for y in 0..height as i32 {
                        for x in 0..width as i32 {
                            if x < ox || x >= ox + dw || y < oy || y >= oy + dh {
                                continue;
                            }
                            let src_x = (((x - ox) as f32) / scale)
                                .floor()
                                .clamp(0.0, w as f32 - 1.0)
                                as usize;
                            let src_y = (((y - oy) as f32) / scale)
                                .floor()
                                .clamp(0.0, h as f32 - 1.0)
                                as usize;
                            let si = (src_y * sw + src_x) * 4;
                            let di = ((y as usize * width as usize) + x as usize) * 4;
                            if si + 3 < src.len() && di + 3 < pixels.len() {
                                pixels[di..di + 4].copy_from_slice(&src[si..si + 4]);
                            }
                        }
                    }
                }
            }
        }

        if let Some(receiver) = &mut self.event_receiver {
            while let Ok(event) = receiver.try_recv() {
                // redraw = self.sidebar.handle_event(
                //     &event,
                //     ui,
                //     ctx,
                //     &mut self.project,
                //     &mut self.server_ctx,
                // );
                //

                match event {
                    TheEvent::ValueChanged(id, value) => {
                        if id.name.ends_with(".asm") {
                            if let Some(value) = value.to_string() {
                                self.context.content.insert(id.name.clone(), value);
                                self.sidebar.set_tree_item_title(
                                    format!("{} *", id.name),
                                    ui,
                                    &mut self.context,
                                );
                                self.context.changed.insert(id.name);
                            }
                        }
                    }
                    TheEvent::StateChanged(id, _state) => {
                        if id.name == "Undo" || id.name == "Redo" {
                            if ui.focus_widget_supports_undo_redo(ctx) {
                                if id.name == "Undo" {
                                    ui.undo(ctx);
                                } else {
                                    ui.redo(ctx);
                                }
                            }
                        } else if id.name.ends_with(".asm") {
                            // Show the assembler file
                            if let Some(stack) = ui.get_stack_layout("Code Stack") {
                                if let Some(index) = self.context.stack_indices.get(&id.name) {
                                    stack.set_index(*index as usize);
                                    ctx.ui.relayout = true;
                                    ctx.ui.redraw_all = true;
                                    self.context.current = id.name.clone();
                                }
                            }
                        } else if id.name == "Cut" {
                            if ui.focus_widget_supports_clipboard(ctx) {
                                // Widget specific
                                ui.cut(ctx);
                            } else {
                                // Global
                                ctx.ui.send(TheEvent::Cut);
                            }
                        } else if id.name == "Copy" {
                            if ui.focus_widget_supports_clipboard(ctx) {
                                // Widget specific
                                ui.copy(ctx);
                            } else {
                                // Global
                                ctx.ui.send(TheEvent::Copy);
                            }
                        } else if id.name == "Paste" {
                            if ui.focus_widget_supports_clipboard(ctx) {
                                // Widget specific
                                ui.paste(ctx);
                            } else {
                                // Global
                                if let Some(value) = &ctx.ui.clipboard {
                                    ctx.ui.send(TheEvent::Paste(
                                        value.clone(),
                                        ctx.ui.clipboard_app_type.clone(),
                                    ));
                                } else {
                                    ctx.ui.send(TheEvent::Paste(
                                        TheValue::Empty,
                                        ctx.ui.clipboard_app_type.clone(),
                                    ));
                                }
                            }
                        } else if id.name == "Save" {
                            if self.context.changed.contains(&self.context.current) {
                                if let Some(content) =
                                    self.context.content.get(&self.context.current)
                                {
                                    let is_asm = self.context.current.ends_with(".asm");
                                    if is_asm {
                                        match self
                                            .machine
                                            .validate_asm(&self.context.current, content)
                                        {
                                            Ok(_) => {}
                                            Err((line, error)) => {
                                                let msg = if let Some(line) = line {
                                                    format!("line {}: {}", line, error)
                                                } else {
                                                    error
                                                };
                                                self.sidebar.set_status_text(msg, ui);
                                                // Do not write on validation failure.
                                                continue;
                                            }
                                        }
                                    }

                                    // Save (ASM or other)
                                    let save_result = if is_asm {
                                        self.machine.write_asm_file(&self.context.current, content)
                                    } else {
                                        Err("Saving non-asm files is not supported yet".into())
                                    };

                                    match save_result {
                                        Ok(_) => {
                                            self.sidebar.set_status_text(
                                                format!(
                                                    "'{}' saved successfully.",
                                                    self.context.current
                                                ),
                                                ui,
                                            );
                                            self.context.changed.remove(&self.context.current);
                                            self.sidebar.set_tree_item_title(
                                                format!("{}", self.context.current),
                                                ui,
                                                &mut self.context,
                                            );
                                        }
                                        Err(error) => {
                                            self.sidebar
                                                .set_status_text(format!("Error: {}", error), ui);
                                        }
                                    }
                                }
                            } else {
                                self.sidebar.set_status_text(
                                    format!("'{}' has no changes.", self.context.current),
                                    ui,
                                );
                            }
                        } else if id.name == "Play" {
                            self.artifacts = None;
                            self.cpu = None;
                            self.debug_session = None;
                            if let Some(edit) =
                                ui.get_text_area_edit(&format!("ASM: {}", self.context.current))
                            {
                                edit.set_debug_line(None);
                            }
                            self.debug_running = false;
                            self.did_init = false;
                            self.state = EditorState::Playing;
                        } else if id.name == "Stop" {
                            self.artifacts = None;
                            self.cpu = None;
                            self.debug_session = None;
                            if let Some(edit) =
                                ui.get_text_area_edit(&format!("ASM: {}", self.context.current))
                            {
                                edit.set_debug_line(None);
                            }
                            self.debug_running = false;
                            self.did_init = false;
                            self.state = EditorState::Idle;
                        } else if id.name == "Debug" {
                            self.artifacts = None;
                            self.cpu = None;
                            self.debug_running = false;
                            self.did_init = false;
                            self.state = EditorState::Debugging;
                            match self.machine.start_debug_session() {
                                Ok(session) => {
                                    // Render current frame/registers without stepping.
                                    let (w, h) = self.machine.video_size();
                                    let frame = session.current_frame_rgba();
                                    self.frame = Some((frame, w, h));

                                    let regs = session.peek_registers();
                                    let mut msg = format!(
                                        "PC=${:04X} A={:02X} X={:02X} Y={:02X} SP={:02X} P={:02X}",
                                        regs.pc, regs.a, regs.x, regs.y, regs.sp, regs.status
                                    );
                                    if let Some(line) = session.peek_line() {
                                        msg.push_str(&format!(" at {}:{}", line.file, line.line));
                                        self.sidebar.goto_debug_line(
                                            &line,
                                            ui,
                                            ctx,
                                            &mut self.context,
                                        );
                                    }
                                    self.sidebar.set_status_text(msg, ui);

                                    self.debug_session = Some(session);
                                }
                                Err(err) => println!("Error: {}", err),
                            }
                        } else if id.name == "Step" {
                            if let Some(session) = &mut self.debug_session {
                                let (step, rgba) = session.step_with_frame();
                                let (w, h) = self.machine.video_size();
                                self.frame = Some((rgba, w, h));
                                let mut msg = format!(
                                    "PC=${:04X} A={:02X} X={:02X} Y={:02X} SP={:02X} P={:02X}",
                                    step.registers.pc,
                                    step.registers.a,
                                    step.registers.x,
                                    step.registers.y,
                                    step.registers.sp,
                                    step.registers.status
                                );
                                if let Some(line) = step.line {
                                    msg.push_str(&format!(" at {}:{}", line.file, line.line));
                                    self.sidebar
                                        .goto_debug_line(&line, ui, ctx, &mut self.context);
                                }
                                if let Some(reason) = step.stop_reason {
                                    msg.push_str(&format!(" stop={}", reason));
                                }
                                self.sidebar.set_status_text(msg, ui);
                                redraw = true;
                            }
                        } else if id.name == "RunRTS" {
                            if let Some(session) = &mut self.debug_session {
                                let (step, rgba) = session.run_to_rts_with_frame();
                                let (w, h) = self.machine.video_size();
                                self.frame = Some((rgba, w, h));
                                let mut msg = format!(
                                    "PC=${:04X} A={:02X} X={:02X} Y={:02X} SP={:02X} P={:02X}",
                                    step.registers.pc,
                                    step.registers.a,
                                    step.registers.x,
                                    step.registers.y,
                                    step.registers.sp,
                                    step.registers.status
                                );
                                if let Some(line) = step.line {
                                    msg.push_str(&format!(" at {}:{}", line.file, line.line));
                                    self.sidebar
                                        .goto_debug_line(&line, ui, ctx, &mut self.context);
                                }
                                if let Some(reason) = step.stop_reason {
                                    msg.push_str(&format!(" stop={}", reason));
                                }
                                self.sidebar.set_status_text(msg, ui);
                                redraw = true;
                            }
                        } else if id.name == "Continue" {
                            if self.state == EditorState::Debugging {
                                self.debug_running = true;
                            }
                        } else if id.name == "Pause" {
                            if self.state == EditorState::Debugging {
                                self.debug_running = false;
                            }
                        }
                    }
                    _ => {}
                }
            }
        }

        if self.state == EditorState::Debugging && self.debug_running {
            if self.machine.should_tick() {
                if let Some(session) = &mut self.debug_session {
                    let (step, rgba) = session.step_with_frame();
                    let (w, h) = self.machine.video_size();
                    self.frame = Some((rgba, w, h));
                    let mut msg = format!(
                        "PC=${:04X} A={:02X} X={:02X} Y={:02X} SP={:02X} P={:02X}",
                        step.registers.pc,
                        step.registers.a,
                        step.registers.x,
                        step.registers.y,
                        step.registers.sp,
                        step.registers.status
                    );
                    if let Some(line) = step.line {
                        msg.push_str(&format!(" at {}:{}", line.file, line.line));
                        self.sidebar
                            .goto_debug_line(&line, ui, ctx, &mut self.context);
                    }
                    if let Some(reason) = step.stop_reason {
                        msg.push_str(&format!(" stop={}", reason));
                        self.debug_running = false; // pause on stop
                    }
                    self.sidebar.set_status_text(msg, ui);
                    redraw = true;
                }
            }
        }

        redraw
    }

    fn target_fps(&self) -> f64 {
        self.machine.config().machine.refresh_hz as f64
    }
}
