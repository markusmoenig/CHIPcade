use crate::bus::ChipcadeBus;
use crate::machine::{BuildArtifacts, Machine};
use mos6502::cpu;
use mos6502::instruction::Nmos6502;
use theframework::prelude::*;

pub struct Player {
    machine: Machine,
    scale: u32,
    frame: Option<(Vec<u8>, u32, u32)>,
    artifacts: Option<BuildArtifacts>,
    cpu: Option<cpu::CPU<ChipcadeBus, Nmos6502>>,
    did_init: bool,
    tick_due: bool,
}

impl Player {
    pub fn set_machine(&mut self, machine: Machine, scale: u32) {
        self.machine = machine;
        self.scale = scale;
        self.frame = None;
        self.artifacts = None;
        self.cpu = None;
        self.did_init = false;
        self.tick_due = true;
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
            self.did_init = true;
        }

        // Per-frame Update; fallback to Start/entry_point if missing.
        let update = Machine::label_address(&artifacts.labels, "Update").or(artifacts.entry_point);
        let update_entry = self.machine.entry_address(update);
        let (rgba, _steps, _reason) = self.machine.run_frame(cpu, update_entry);
        let (w, h) = self.machine.video_size();
        self.frame = Some((rgba, w, h));
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
            artifacts: None,
            cpu: None,
            did_init: false,
            tick_due: true,
        }
    }

    fn window_title(&self) -> String {
        "CHIPcade — 6502 Fantasy Console".into()
    }

    fn default_window_size(&self) -> (usize, usize) {
        let (width, height) = self.machine.video_size();
        (
            (width * self.scale) as usize,
            (height * self.scale) as usize,
        )
    }

    fn draw(&mut self, pixels: &mut [u8], ctx: &mut TheContext) {
        // Only advance simulation when a tick is due; always paint the last frame.
        if self.tick_due || self.frame.is_none() {
            self.ensure_frame();
            // self.tick_due = false;
        }
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
    // fn update(&mut self, _ctx: &mut TheContext) -> bool {
    //     // Align to machine refresh rate; only advance when tick is due.
    //     if true {
    //         //self.machine.should_tick() {
    //         self.tick_due = true;
    //         true
    //     } else {
    //         false
    //     }
    // }

    fn target_fps(&self) -> f64 {
        self.machine.config().machine.refresh_hz as f64
    }
}
