use crate::machine::DebugLine;
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
            width: 380,

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

        let mut canvas: TheCanvas = TheCanvas::new();

        let mut project_canvas: TheCanvas = TheCanvas::new();
        let mut project_tree_layout = TheTreeLayout::new(TheId::named("Project Tree"));
        let root = project_tree_layout.get_root();

        let mut asm_node: TheTreeNode =
            TheTreeNode::new(TheId::named_with_id("Assembler", context.asm_node_id));
        asm_node.set_open(true);
        asm_node.set_root_mode(false);

        let mut stack_index: u16 = 0;

        if let Ok(list) = machine.list_asm_sources() {
            for item in list {
                let id = Uuid::new_v4();
                let mut widget = TheTreeItem::new(TheId::named_with_id(&item.0.clone(), id));
                widget.set_text(item.0.clone());
                asm_node.add_widget(Box::new(widget));

                if stack_index == 0 {
                    asm_node.new_item_selected(&TheId::named_with_id(&item.0.clone(), id));
                    context.current = item.0.clone();
                }

                context.stack_indices.insert(item.0.clone(), stack_index);
                context.tree_item_ids.insert(item.0.clone(), id);
                context.content.insert(item.0.clone(), item.1.clone());
                stack_index += 1;

                let canvas = self.create_asm_editor(item.0, item.1);
                stack_layout.add_canvas(canvas);
            }
        }

        root.add_child(asm_node);

        /*
        let characters_node: TheTreeNode = TheTreeNode::new(TheId::named_with_id(
            &fl!("characters"),
            server_ctx.tree_characters_id,
        ));
        root.add_child(characters_node);

        let items_node: TheTreeNode = TheTreeNode::new(TheId::named_with_id(
            &fl!("items"),
            server_ctx.tree_items_id,
        ));
        root.add_child(items_node);

        let tilemaps_node: TheTreeNode = TheTreeNode::new(TheId::named_with_id(
            &fl!("tilesets"),
            server_ctx.tree_tilemaps_id,
        ));
        root.add_child(tilemaps_node);

        let screens_node: TheTreeNode = TheTreeNode::new(TheId::named_with_id(
            &fl!("screens"),
            server_ctx.tree_screens_id,
        ));
        root.add_child(screens_node);

        let mut assets_node: TheTreeNode = TheTreeNode::new(TheId::named_with_id(
            &fl!("assets"),
            server_ctx.tree_assets_id,
        ));

        let fonts_node: TheTreeNode = TheTreeNode::new(TheId::named_with_id(
            &fl!("fonts"),
            server_ctx.tree_assets_fonts_id,
        ));
        assets_node.add_child(fonts_node);
        root.add_child(assets_node);

        let mut config_node: TheTreeNode = TheTreeNode::new(TheId::named(&fl!("game")));

        let mut config_item = TheTreeItem::new(TheId::named("Project Settings"));
        config_item.set_text(fl!("settings"));
        config_node.add_widget(Box::new(config_item));

        root.add_child(config_node);

        // let palette_node: TheTreeNode =
        //     TheTreeNode::new(TheId::named_with_id("Palette", server_ctx.tree_palette_id));
        // root.add_child(palette_node);
        */

        project_canvas.set_layout(project_tree_layout);

        // Tree View Toolbar

        let mut add_button = TheTraybarButton::new(TheId::named("Project Add"));
        add_button.set_icon_name("icon_role_add".to_string());
        add_button.set_status_text("Add to the project");
        add_button.set_context_menu(Some(TheContextMenu {
            items: vec![
                TheContextMenuItem::new("Add Region".to_string(), TheId::named("Add Region")),
                TheContextMenuItem::new("Add Character".to_string(), TheId::named("Add Character")),
                TheContextMenuItem::new("Add Item".to_string(), TheId::named("Add Item")),
                TheContextMenuItem::new("Add Tileset".to_string(), TheId::named("Add Tileset")),
                TheContextMenuItem::new("Add Screen".to_string(), TheId::named("Add Screen")),
                TheContextMenuItem::new(
                    "Add Font Asset".to_string(),
                    TheId::named("Add Font Asset"),
                ),
            ],
            ..Default::default()
        }));

        let mut remove_button = TheTraybarButton::new(TheId::named("Project Remove"));
        remove_button.set_icon_name("icon_role_remove".to_string());
        // remove_button.set_status_text(&fl!("status_project_remove_button"));

        let mut project_context_text = TheText::new(TheId::named("Project Context"));
        project_context_text.set_text("".to_string());

        let mut import_button: TheTraybarButton =
            TheTraybarButton::new(TheId::named("Project Import"));
        import_button.set_icon_name("import".to_string());
        // import_button.set_status_text(&fl!("status_project_import_button"));
        import_button.set_context_menu(Some(TheContextMenu {
            items: vec![
                TheContextMenuItem::new("Import Region".to_string(), TheId::named("Import Region")),
                TheContextMenuItem::new(
                    "Import Character".to_string(),
                    TheId::named("Import Character"),
                ),
                TheContextMenuItem::new("Import Item".to_string(), TheId::named("Import Item")),
                TheContextMenuItem::new(
                    "Import Tileset".to_string(),
                    TheId::named("Import Tileset"),
                ),
                TheContextMenuItem::new("Import Screen".to_string(), TheId::named("Import Screen")),
                TheContextMenuItem::new(
                    "Import Font Asset".to_string(),
                    TheId::named("Import Font Asset"),
                ),
            ],
            ..Default::default()
        }));

        let mut export_button: TheTraybarButton =
            TheTraybarButton::new(TheId::named("Project Export"));
        export_button.set_icon_name("export".to_string());
        // export_button.set_status_text(&fl!("status_project_export_button"));

        let mut toolbar_hlayout = TheHLayout::new(TheId::empty());
        toolbar_hlayout.set_background_color(None);
        toolbar_hlayout.set_margin(Vec4::new(5, 2, 5, 2));
        toolbar_hlayout.add_widget(Box::new(add_button));
        toolbar_hlayout.add_widget(Box::new(remove_button));
        toolbar_hlayout.add_widget(Box::new(TheHDivider::new(TheId::empty())));
        toolbar_hlayout.add_widget(Box::new(project_context_text));
        toolbar_hlayout.add_widget(Box::new(import_button));
        toolbar_hlayout.add_widget(Box::new(export_button));

        toolbar_hlayout.set_reverse_index(Some(2));

        let mut toolbar_canvas = TheCanvas::default();
        toolbar_canvas.set_widget(TheTraybar::new(TheId::empty()));
        toolbar_canvas.set_layout(toolbar_hlayout);
        project_canvas.set_bottom(toolbar_canvas);

        // Shared Layout

        let mut stack_layout = TheStackLayout::new(TheId::named("Tree Stack Layout"));
        stack_layout.add_canvas(project_canvas);

        // canvas.set_top(header);
        // canvas.set_right(sectionbar_canvas);
        // canvas.top_is_expanding = false;
        // canvas.set_layout(stack_layout);

        canvas.set_layout(stack_layout);

        // Multi functional footer canvas

        let mut right_canvas = TheCanvas::new();

        let mut shared_layout = TheSharedVLayout::new(TheId::named("Multi Shared"));

        let mut nodes_minimap_canvas: TheCanvas = TheCanvas::default();
        let mut nodes_minimap_shared = TheSharedVLayout::new(TheId::named("Multi Tab"));
        nodes_minimap_shared.set_shared_ratio(0.5);
        nodes_minimap_shared.set_mode(TheSharedVLayoutMode::Shared);

        let mut minimap_canvas = TheCanvas::default();
        let mut minimap = TheRenderView::new(TheId::named("MiniMap"));
        minimap.limiter_mut().set_max_width(self.width);
        minimap_canvas.set_widget(minimap);

        let mut node_settings_canvas = TheCanvas::default();
        let mut tree_layout = TheTreeLayout::new(TheId::named("Node Settings"));
        tree_layout.limiter_mut().set_max_width(self.width);
        let root = tree_layout.get_root();

        //text_layout.set_fixed_text_width(110);
        // text_layout.set_text_margin(20);
        // text_layout.set_text_align(TheHorizontalAlign::Right);
        let mut settings_node: TheTreeNode =
            TheTreeNode::new(TheId::named_with_id("Settings", Uuid::new_v4()));
        settings_node.set_root_mode(false);
        settings_node.set_open(true);

        root.add_child(settings_node);

        node_settings_canvas.set_layout(tree_layout);

        // let mut header = TheCanvas::new();
        // let mut switchbar = TheSwitchbar::new(TheId::named("Action Header"));
        // switchbar.set_text("Settings".to_string());
        // header.set_widget(switchbar);

        // nodes_minimap_canvas.set_top(header);

        nodes_minimap_shared.add_canvas(node_settings_canvas);
        nodes_minimap_shared.add_canvas(minimap_canvas);
        nodes_minimap_canvas.set_layout(nodes_minimap_shared);

        shared_layout.add_canvas(canvas);
        shared_layout.add_canvas(nodes_minimap_canvas);
        shared_layout.set_mode(TheSharedVLayoutMode::Shared);
        shared_layout.set_shared_ratio(0.6);
        shared_layout.limiter_mut().set_max_width(self.width);

        right_canvas.set_layout(shared_layout);
        right_canvas.top_is_expanding = false;

        // --

        ui.canvas.set_right(right_canvas);
    }

    pub fn create_asm_editor(&self, name: String, content: String) -> TheCanvas {
        let mut code_canvas: TheCanvas = TheCanvas::new();
        let mut textedit = TheTextAreaEdit::new(TheId::named(&format!("ASM: {}", name)));
        textedit.set_continuous(true);
        textedit.display_line_number(true);
        textedit.as_code_editor("Python", TheCodeEditorSettings::default());
        textedit.set_code_theme("base16-eighties.dark");
        textedit.use_global_statusbar(true);
        textedit.set_font_size(14.0);
        textedit.set_text(content);

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

    /// Set the status bar text
    pub fn set_status_text(&self, text: String, ui: &mut TheUI) {
        if let Some(statusbar) = ui.get_widget("Statusbar") {
            statusbar.as_statusbar().unwrap().set_text(text);
        }
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
