// use crate::prelude::*;
use theframework::prelude::*;

pub struct Context {
    pub asm_node_id: Uuid,
    pub sprites_node_id: Uuid,

    pub stack_indices: FxHashMap<String, u16>,
    pub tree_item_ids: FxHashMap<String, Uuid>,

    pub changed: FxHashSet<String>,
    pub content: FxHashMap<String, String>,

    pub sprite_offsets: FxHashMap<String, u16>,

    pub current: String,
}

#[allow(clippy::new_without_default)]
impl Context {
    pub fn new() -> Self {
        Self {
            asm_node_id: Uuid::new_v4(),
            sprites_node_id: Uuid::new_v4(),

            stack_indices: FxHashMap::default(),
            tree_item_ids: FxHashMap::default(),

            changed: FxHashSet::default(),
            content: FxHashMap::default(),

            sprite_offsets: FxHashMap::default(),

            current: "".into(),
        }
    }

    /// Return the sprite name for a given offset (index) if present.
    pub fn sprite_name_for_offset(&self, offset: u16) -> Option<String> {
        self.sprite_offsets
            .iter()
            .find_map(|(name, off)| (*off == offset).then(|| name.clone()))
    }

    /// Returns true if any tracked file with changes is a sprite (.spr).
    pub fn has_changed_sprites(&self) -> bool {
        self.changed.iter().any(|name| name.ends_with(".spr"))
    }
}
