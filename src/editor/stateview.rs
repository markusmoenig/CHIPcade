use crate::machine::DebugLine;
use crate::prelude::*;
use theframework::prelude::*;

pub struct StateView {
    pub width: i32,

    pub startup: bool,
}

#[allow(clippy::new_without_default)]
impl StateView {
    pub fn new() -> Self {
        Self {
            width: 380,

            startup: true,
        }
    }
}
