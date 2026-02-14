use crate::display::{DisplayBackend, FrameProducer};
use softbuffer::{Context, Surface};
use std::num::NonZeroU32;
use std::rc::Rc;
use std::time::{Duration, Instant};
use winit::application::ApplicationHandler;
use winit::dpi::LogicalSize;
use winit::event::{ElementState, WindowEvent};
use winit::event_loop::{ActiveEventLoop, ControlFlow, EventLoop};
use winit::keyboard::{KeyCode, PhysicalKey};
use winit::window::Window;

pub struct WinitSoftbufferBackend;

impl DisplayBackend for WinitSoftbufferBackend {
    fn run(self, producer: FrameProducer, scale: u32) -> Result<(), String> {
        run_impl(producer, scale)
    }
}

fn run_impl(producer: FrameProducer, scale: u32) -> Result<(), String> {
    let refresh_hz = producer.refresh_hz().max(1);
    let target_frame_time = Duration::from_secs_f64(1.0 / refresh_hz as f64);
    let (vw, vh) = producer.video_size();
    let window_w = vw.saturating_mul(scale.max(1)).max(1);
    let window_h = vh.saturating_mul(scale.max(1)).max(1);

    let event_loop = EventLoop::new().map_err(|e| format!("Failed to create event loop: {e}"))?;
    let mut app = App {
        producer,
        target_frame_time,
        window_w,
        window_h,
        video_w: vw,
        video_h: vh,
        window: None,
        context: None,
        surface: None,
        frame: None,
        last_tick: Instant::now(),
        error: None,
        input_bits: 0,
    };

    event_loop
        .run_app(&mut app)
        .map_err(|e| format!("Run loop error: {e}"))?;
    if let Some(e) = app.error {
        return Err(e);
    }
    Ok(())
}

struct App {
    producer: FrameProducer,
    target_frame_time: Duration,
    window_w: u32,
    window_h: u32,
    video_w: u32,
    video_h: u32,
    window: Option<Rc<Window>>,
    context: Option<Context<Rc<Window>>>,
    surface: Option<Surface<Rc<Window>, Rc<Window>>>,
    frame: Option<(Vec<u8>, u32, u32)>,
    last_tick: Instant,
    error: Option<String>,
    input_bits: u8,
}

impl ApplicationHandler for App {
    fn resumed(&mut self, event_loop: &ActiveEventLoop) {
        if self.window.is_some() {
            return;
        }
        event_loop.set_control_flow(ControlFlow::Poll);
        let window = match event_loop.create_window(
            Window::default_attributes()
                .with_title("CHIPcade — 6502 Fantasy Console")
                .with_inner_size(LogicalSize::new(self.window_w as f64, self.window_h as f64))
                .with_min_inner_size(LogicalSize::new(self.video_w as f64, self.video_h as f64)),
        ) {
            Ok(w) => Rc::new(w),
            Err(e) => {
                self.error = Some(format!("Failed to create window: {e}"));
                event_loop.exit();
                return;
            }
        };

        let context = match Context::new(window.clone()) {
            Ok(c) => c,
            Err(e) => {
                self.error = Some(format!("Failed to create surface context: {e}"));
                event_loop.exit();
                return;
            }
        };
        let surface = match Surface::new(&context, window.clone()) {
            Ok(s) => s,
            Err(e) => {
                self.error = Some(format!("Failed to create softbuffer surface: {e}"));
                event_loop.exit();
                return;
            }
        };

        self.window = Some(window);
        self.context = Some(context);
        self.surface = Some(surface);
    }

    fn about_to_wait(&mut self, _event_loop: &ActiveEventLoop) {
        let Some(window) = &self.window else {
            return;
        };
        self.producer.set_input_bits(self.input_bits);
        if self.last_tick.elapsed() >= self.target_frame_time || self.frame.is_none() {
            self.frame = self.producer.next_frame();
            self.last_tick = Instant::now();
            window.request_redraw();
        }
    }

    fn window_event(
        &mut self,
        event_loop: &ActiveEventLoop,
        _window_id: winit::window::WindowId,
        event: WindowEvent,
    ) {
        match event {
            WindowEvent::CloseRequested => {
                event_loop.exit();
            }
            WindowEvent::KeyboardInput { event, .. } => {
                let pressed = event.state == ElementState::Pressed;
                let bit =
                    match event.physical_key {
                        PhysicalKey::Code(KeyCode::ArrowLeft)
                        | PhysicalKey::Code(KeyCode::KeyA) => Some(0x01),
                        PhysicalKey::Code(KeyCode::ArrowRight)
                        | PhysicalKey::Code(KeyCode::KeyD) => Some(0x02),
                        PhysicalKey::Code(KeyCode::ArrowUp) | PhysicalKey::Code(KeyCode::KeyW) => {
                            Some(0x04)
                        }
                        PhysicalKey::Code(KeyCode::ArrowDown)
                        | PhysicalKey::Code(KeyCode::KeyS) => Some(0x08),
                        PhysicalKey::Code(KeyCode::Space)
                        | PhysicalKey::Code(KeyCode::Enter)
                        | PhysicalKey::Code(KeyCode::KeyZ)
                        | PhysicalKey::Code(KeyCode::KeyX) => Some(0x10),
                        _ => None,
                    };
                if let Some(mask) = bit {
                    if pressed {
                        self.input_bits |= mask;
                    } else {
                        self.input_bits &= !mask;
                    }
                    self.producer.set_input_bits(self.input_bits);
                }
            }
            WindowEvent::RedrawRequested => {
                let (Some(window), Some(surface)) = (&self.window, self.surface.as_mut()) else {
                    return;
                };

                let size = window.inner_size();
                let width = size.width.max(1);
                let height = size.height.max(1);
                if let (Some(nw), Some(nh)) = (NonZeroU32::new(width), NonZeroU32::new(height)) {
                    let _ = surface.resize(nw, nh);
                }

                let Ok(mut buffer) = surface.buffer_mut() else {
                    return;
                };
                for p in buffer.iter_mut() {
                    *p = 0;
                }

                if let Some((rgba, src_w, src_h)) = &self.frame {
                    blit_scaled_rgba_to_buffer(
                        rgba,
                        *src_w,
                        *src_h,
                        width as usize,
                        height as usize,
                        &mut buffer,
                    );
                }
                let _ = buffer.present();
            }
            _ => {}
        }
    }
}

fn blit_scaled_rgba_to_buffer(
    src: &[u8],
    src_w: u32,
    src_h: u32,
    dst_w: usize,
    dst_h: usize,
    dst: &mut [u32],
) {
    if src_w == 0 || src_h == 0 || dst_w == 0 || dst_h == 0 {
        return;
    }

    let scale_x = dst_w as u32 / src_w;
    let scale_y = dst_h as u32 / src_h;
    let scale = scale_x.min(scale_y).max(1);
    let draw_w = (src_w * scale) as usize;
    let draw_h = (src_h * scale) as usize;
    let off_x = (dst_w.saturating_sub(draw_w)) / 2;
    let off_y = (dst_h.saturating_sub(draw_h)) / 2;

    for y in 0..draw_h {
        let sy = (y / scale as usize) as usize;
        for x in 0..draw_w {
            let sx = (x / scale as usize) as usize;
            let si = (sy * src_w as usize + sx) * 4;
            if si + 2 >= src.len() {
                continue;
            }
            let r = src[si] as u32;
            let g = src[si + 1] as u32;
            let b = src[si + 2] as u32;
            let di = (off_y + y) * dst_w + (off_x + x);
            if di < dst.len() {
                dst[di] = (r << 16) | (g << 8) | b;
            }
        }
    }
}
