// use crate::prelude::*;
use theframework::prelude::*;

pub struct Context {
    pub asm_node_id: Uuid,

    pub stack_indices: FxHashMap<String, u16>,
    pub tree_item_ids: FxHashMap<String, Uuid>,

    pub changed: FxHashSet<String>,
    pub content: FxHashMap<String, String>,

    pub current: String,
}

#[allow(clippy::new_without_default)]
impl Context {
    pub fn new() -> Self {
        Self {
            asm_node_id: Uuid::new_v4(),

            stack_indices: FxHashMap::default(),
            tree_item_ids: FxHashMap::default(),

            changed: FxHashSet::default(),
            content: FxHashMap::default(),

            current: "".into(),
        }
    }
}
