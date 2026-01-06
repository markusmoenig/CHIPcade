use crate::machine::{DebugLine, DebugStep};
use crate::prelude::*;
use theframework::prelude::*;

pub struct Sidebar {
    pub width: i32,

    pub startup: bool,
}

#[allow(clippy::new_without_default)]
impl Sidebar {
    pub fn new() -> Self {
        Self {
            width: 300,

            startup: true,
        }
    }

    pub fn init_ui(
        &mut self,
        ui: &mut TheUI,
        _ctx: &mut TheContext,
        machine: &Machine,
        context: &mut Context,
        stack_layout: &mut TheStackLayout,
    ) {
        // Tree View

        let mut tree_canvas: TheCanvas = TheCanvas::new();
        let mut tree_layout = TheTreeLayout::new(TheId::named("Project Tree"));
        let root = tree_layout.get_root();

        let mut asm_node: TheTreeNode =
            TheTreeNode::new(TheId::named_with_id("Sources", context.asm_node_id));
        asm_node.set_open(true);
        asm_node.set_root_mode(false);

        // -- Sources

        let mut stack_index: u16 = 0;

        if let Ok(list) = machine.list_include_sources() {
            for item in list {
                let id = Uuid::new_v4();
                let mut widget = TheTreeItem::new(TheId::named_with_id(&item.0.clone(), id));
                widget.set_text(item.0.clone());
                widget.set_background_color(TheColor::from([200, 195, 150, 255]));
                asm_node.add_widget(Box::new(widget));

                context.stack_indices.insert(item.0.clone(), stack_index);
                context.tree_item_ids.insert(item.0.clone(), id);
                context.content.insert(item.0.clone(), item.1.clone());
                stack_index += 1;

                let canvas = self.create_asm_editor(item.0, item.1, true);
                stack_layout.add_canvas(canvas);
            }
        }

        if let Ok(list) = machine.list_asm_sources() {
            for item in list {
                let id = Uuid::new_v4();
                let mut widget = TheTreeItem::new(TheId::named_with_id(&item.0.clone(), id));
                widget.set_text(item.0.clone());
                widget.set_background_color(TheColor::from([160, 175, 190, 255]));
                asm_node.add_widget(Box::new(widget));

                context.stack_indices.insert(item.0.clone(), stack_index);
                context.tree_item_ids.insert(item.0.clone(), id);
                context.content.insert(item.0.clone(), item.1.clone());
                stack_index += 1;

                if item.0 == "main.asm" {
                    asm_node.new_item_selected(&TheId::named_with_id(&item.0.clone(), id));
                    context.current = item.0.clone();
                    stack_layout.set_index(stack_index as usize - 1);
                }

                let canvas = self.create_asm_editor(item.0, item.1, false);
                stack_layout.add_canvas(canvas);
            }
        }

        root.add_child(asm_node);

        // -- Sprites

        let mut sprites_node: TheTreeNode =
            TheTreeNode::new(TheId::named_with_id("Sprites", context.sprites_node_id));
        sprites_node.set_open(true);
        sprites_node.set_root_mode(false);

        let mut widget = TheTreeIcons::new(TheId::named("Sprites"));

        let sprite_size = 40u32;
        let mut sprite_icons = vec![];
        let mut sprite_offset: u16 = 0;

        if let Ok(list) = machine.list_sprite_sources() {
            for item in list {
                if let Ok(preview) =
                    machine.render_sprite_preview_from_disk(&item.0, sprite_size, sprite_size)
                {
                    let buffer = TheRGBABuffer::from(preview, sprite_size, sprite_size);
                    sprite_icons.push(buffer);
                    context.sprite_offsets.insert(item.0.clone(), sprite_offset);
                    sprite_offset += 1;

                    context.stack_indices.insert(item.0.clone(), stack_index);
                    context.content.insert(item.0.clone(), item.1.clone());
                    stack_index += 1;

                    let canvas = self.create_asm_editor(item.0, item.1, false);
                    stack_layout.add_canvas(canvas);
                }
            }
        }
        widget.set_icon_count(sprite_icons.len());
        widget.set_icon_size(sprite_size as i32);
        for (index, buffer) in sprite_icons.iter().enumerate() {
            widget.set_icon(index, buffer.clone());
        }

        sprites_node.add_widget(Box::new(widget));

        root.add_child(sprites_node);

        // --

        tree_canvas.set_layout(tree_layout);

        // Toolbar

        let mut project_context_text = TheText::new(TheId::named("Project Context"));
        project_context_text.set_text("CHIPcade".to_string());

        let mut toolbar_group = TheGroupButton::new(TheId::named("Toolbar Group"));
        toolbar_group.add_text_status("Registers".to_string(), "Show the registers".to_string());
        toolbar_group.add_text_status(
            "Memory".to_string(),
            "Apply procedural materials.".to_string(),
        );
        toolbar_group.add_text_status("Preview".to_string(), "Apply a color.".to_string());

        toolbar_group.set_item_width(70);
        toolbar_group.set_index(0);

        let mut toolbar_hlayout = TheHLayout::new(TheId::empty());
        toolbar_hlayout.set_background_color(None);
        toolbar_hlayout.set_margin(Vec4::new(5, 2, 5, 2));
        toolbar_hlayout.add_widget(Box::new(toolbar_group));

        let mut toolbar_canvas = TheCanvas::default();
        toolbar_canvas.set_widget(TheTraybar::new(TheId::empty()));
        toolbar_canvas.set_layout(toolbar_hlayout);
        tree_canvas.set_bottom(toolbar_canvas);

        // Panel

        // let mut stack_layout = TheStackLayout::new(TheId::named("Tree Stack Layout"));
        // stack_layout.add_canvas(project_canvas);

        // canvas.set_top(header);
        // canvas.set_right(sectionbar_canvas);
        // canvas.top_is_expanding = false;
        // canvas.set_layout(stack_layout);

        // canvas.set_layout(stack_layout);

        // Multi functional footer canvas

        let mut right_canvas = TheCanvas::new();
        let mut shared_layout = TheSharedVLayout::new(TheId::named("Multi Shared"));

        // let mut header = TheCanvas::new();
        // let mut switchbar = TheSwitchbar::new(TheId::named("State"));
        // switchbar.set_text("Settings".to_string());
        // header.set_widget(switchbar);

        // nodes_minimap_canvas.set_top(header);

        // nodes_minimap_shared.add_canvas(node_settings_canvas);
        // nodes_minimap_shared.add_canvas(minimap_canvas);
        // nodes_minimap_canvas.set_layout(nodes_minimap_shared);

        let mut stack_canvas = TheCanvas::default();
        let mut stack_layout = TheStackLayout::new(TheId::named("Panel Stack"));

        // State

        let mut state_canvas = TheCanvas::default();

        let mut vlayout = TheVLayout::new(TheId::empty());
        // vlayout.set_margin(Vec4::new(5, 20, 5, 10));
        vlayout.set_alignment(TheHorizontalAlign::Center);

        let mut text = TheText::new(TheId::named("Registers"));
        text.set_text(format!("A = $00   X = $00   Y = $00"));
        vlayout.add_widget(Box::new(text));

        state_canvas.set_layout(vlayout);

        stack_layout.add_canvas(state_canvas);

        // -

        stack_canvas.set_layout(stack_layout);

        shared_layout.add_canvas(tree_canvas);
        shared_layout.add_canvas(stack_canvas);
        shared_layout.set_mode(TheSharedVLayoutMode::Shared);
        shared_layout.set_shared_ratio(0.6);
        shared_layout.limiter_mut().set_max_width(self.width);

        right_canvas.set_layout(shared_layout);
        right_canvas.top_is_expanding = false;

        // --

        ui.canvas.set_right(right_canvas);
    }

    pub fn create_asm_editor(&self, name: String, content: String, readonly: bool) -> TheCanvas {
        let mut code_canvas: TheCanvas = TheCanvas::new();
        let mut textedit = TheTextAreaEdit::new(TheId::named(&format!("ASM: {}", name)));
        textedit.set_continuous(true);
        textedit.display_line_number(true);
        textedit.as_code_editor("Python", TheCodeEditorSettings::default());
        textedit.set_code_theme("base16-eighties.dark");
        textedit.use_global_statusbar(true);
        textedit.set_font_size(14.0);
        textedit.set_text(content);

        textedit.readonly(readonly);

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

        code_canvas
    }

    /// Set the title for a tree item
    pub fn set_tree_item_title(&self, title: String, ui: &mut TheUI, context: &mut Context) {
        if context.current.ends_with(".asm") {
            if let Some(tree_layout) = ui.get_tree_layout("Project Tree") {
                if let Some(node) = tree_layout.get_node_by_id_mut(&context.asm_node_id) {
                    if let Some(index) = context.stack_indices.get(&context.current) {
                        node.widgets[*index as usize].set_value(TheValue::Text(title));
                    }
                }
            }
        }
    }

    /// Set the title for a tree item
    pub fn set_tree_node_title(&self, title: String, id: Uuid, ui: &mut TheUI) {
        if let Some(tree_layout) = ui.get_tree_layout("Project Tree") {
            if let Some(node) = tree_layout.get_node_by_id_mut(&id) {
                node.widget.set_value(TheValue::Text(title));
            }
        }
    }

    /// Update sprite icon
    pub fn update_sprite_icon(
        &self,
        name: String,
        ui: &mut TheUI,
        context: &mut Context,
        machine: &Machine,
    ) {
        if let Some(tree_layout) = ui.get_tree_layout("Project Tree") {
            if let Some(node) = tree_layout.get_node_by_id_mut(&context.sprites_node_id) {
                if let Some(index) = context.sprite_offsets.get(&context.current) {
                    if let Some(widget) = node.widgets[*index as usize].as_tree_icons() {
                        if let Ok(preview) = machine.render_sprite_preview_from_disk(&name, 40, 40)
                        {
                            let buffer = TheRGBABuffer::from(preview, 40, 40);
                            widget.set_icon(*index as usize, buffer);
                        }
                    }
                }
            }
        }
    }

    /// Set the status bar text
    pub fn set_status_text(&self, text: String, ui: &mut TheUI) {
        if let Some(statusbar) = ui.get_widget("Statusbar") {
            statusbar.as_statusbar().unwrap().set_text(text);
        }
    }

    pub fn clear_debug_step(&self, ui: &mut TheUI, ctx: &mut TheContext, _context: &mut Context) {
        ui.set_widget_value(
            "Registers",
            ctx,
            TheValue::Text(format!("A= {:02X} X= {:02X} Y= {:02X}", 0, 0, 0)),
        );
        ctx.ui.relayout = true;
        ctx.ui.redraw_all = true;
    }

    pub fn show_debug_step(
        &self,
        step: &DebugStep,
        ui: &mut TheUI,
        ctx: &mut TheContext,
        _context: &mut Context,
    ) {
        ui.set_widget_value(
            "Registers",
            ctx,
            TheValue::Text(format!(
                "A={:02X} X={:02X} Y={:02X}",
                step.registers.a, step.registers.x, step.registers.y
            )),
        );
        ctx.ui.relayout = true;
        ctx.ui.redraw_all = true;
    }

    pub fn goto_debug_line(
        &self,
        line: &DebugLine,
        ui: &mut TheUI,
        ctx: &mut TheContext,
        context: &mut Context,
    ) {
        if context.current != line.file {
            if let Some(edit) = ui.get_text_area_edit(&format!("ASM: {}", context.current)) {
                edit.set_debug_line(None);
            }
            if let Some(stack) = ui.get_stack_layout("Code Stack") {
                if let Some(index) = context.stack_indices.get(&line.file) {
                    stack.set_index(*index as usize);
                    ctx.ui.relayout = true;
                    ctx.ui.redraw_all = true;
                    context.current = line.file.clone();
                }
            }
            if let Some(tree_layout) = ui.get_tree_layout("Project Tree") {
                if let Some(node) = tree_layout.get_node_by_id_mut(&context.asm_node_id) {
                    if let Some(id) = context.tree_item_ids.get(&line.file) {
                        node.new_item_selected(&TheId::named_with_id(&line.file, *id));
                    }
                }
            }
        }

        if let Some(edit) = ui.get_text_area_edit(&format!("ASM: {}", line.file)) {
            edit.goto_line(line.line);
            edit.set_debug_line(Some(line.line - 1));
        }
    }
}
