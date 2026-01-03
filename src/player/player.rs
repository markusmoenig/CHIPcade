use crate::machine::Machine;
use theframework::prelude::*;

pub struct Player {
    machine: Machine,
    scale: u32,
    frame: Option<(Vec<u8>, u32, u32)>,
}

impl Player {
    pub fn set_machine(&mut self, machine: Machine, scale: u32) {
        self.machine = machine;
        self.scale = scale;
        self.frame = None;
    }

    fn ensure_frame(&mut self) {
        if self.frame.is_some() {
            return;
        }
        match self.machine.run() {
            Ok(artifacts) => {
                let w = artifacts.config.video.width;
                let h = artifacts.config.video.height;
                self.frame = Some((artifacts.vram_rgba, w, h));
            }
            Err(e) => eprintln!("{e}"),
        }
    }

    fn blit_scaled(&self, pixels: &mut [u8], ctx: &TheContext) {
        let Some((ref src, w, h)) = self.frame else {
            return;
        };
        let sw = w as usize;
        let cw = ctx.width as u32;
        let ch = ctx.height as u32;
        // Pick the largest integer scale that fits the current window.
        let scale: u32 = ((cw / w.max(1)).min(ch / h.max(1))).max(1);
        let dw = (w * scale) as i32;
        let dh = (h * scale) as i32;
        let ox = ((cw as i32 - dw) / 2).max(0);
        let oy = ((ch as i32 - dh) / 2).max(0);

        for y in 0..ctx.height as i32 {
            for x in 0..ctx.width as i32 {
                if x < ox || x >= ox + dw || y < oy || y >= oy + dh {
                    continue;
                }
                let src_x = ((x - ox) / scale as i32).clamp(0, w as i32 - 1);
                let src_y = ((y - oy) / scale as i32).clamp(0, h as i32 - 1);
                let si = (src_y as usize * sw + src_x as usize) * 4;
                let di = ((y as usize * ctx.width as usize) + x as usize) * 4;
                if si + 3 < src.len() && di + 3 < pixels.len() {
                    pixels[di..di + 4].copy_from_slice(&src[si..si + 4]);
                }
            }
        }
    }
}

impl TheTrait for Player {
    fn new() -> Self
    where
        Self: Sized,
    {
        Self {
            machine: Machine::default(),
            scale: 3,
            frame: None,
        }
    }

    fn default_window_size(&self) -> (usize, usize) {
        let (width, height) = self.machine.video_size();
        (
            (width * self.scale) as usize,
            (height * self.scale) as usize,
        )
    }

    fn draw(&mut self, pixels: &mut [u8], ctx: &mut TheContext) {
        self.ensure_frame();
        ctx.draw.rect(
            pixels,
            &(0, 0, ctx.width, ctx.height),
            ctx.width,
            &[0, 0, 0, 255],
        );
        self.blit_scaled(pixels, ctx);
    }

    /// Touch down event
    fn touch_down(&mut self, _x: f32, _y: f32, _ctx: &mut TheContext) -> bool {
        false
    }

    /// Touch up event
    fn touch_up(&mut self, _x: f32, _y: f32, _ctx: &mut TheContext) -> bool {
        false
    }

    /// Query if the widget needs a redraw
    fn update(&mut self, _ctx: &mut TheContext) -> bool {
        false
    }
}
