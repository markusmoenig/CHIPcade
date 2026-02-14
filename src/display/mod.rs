#[cfg(not(target_arch = "wasm32"))]
pub mod winit_softbuffer;

use crate::bus::ChipcadeBus;
use crate::machine::{BuildArtifacts, Machine};
use mos6502::cpu;
use mos6502::instruction::Nmos6502;

pub struct FrameProducer {
    machine: Machine,
    artifacts: BuildArtifacts,
    cpu: Option<cpu::CPU<ChipcadeBus, Nmos6502>>,
    did_init: bool,
    input_bits: u8,
}

pub trait DisplayBackend {
    fn run(self, producer: FrameProducer, scale: u32) -> Result<(), String>;
}

impl FrameProducer {
    pub fn new(machine: Machine, artifacts: BuildArtifacts) -> Self {
        Self {
            machine,
            artifacts,
            cpu: None,
            did_init: false,
            input_bits: 0,
        }
    }

    pub fn refresh_hz(&self) -> u32 {
        self.machine.config().machine.refresh_hz
    }

    pub fn video_size(&self) -> (u32, u32) {
        self.machine.video_size()
    }

    pub fn next_frame(&mut self) -> Option<(Vec<u8>, u32, u32)> {
        let cpu = self.cpu.get_or_insert_with(|| {
            let mut cpu = self
                .machine
                .create_cpu(
                    &self.artifacts.program,
                    &self.artifacts.sprites,
                    self.artifacts.entry_point,
                )
                .expect("failed to create CPU");
            cpu.memory.set_input_state(self.input_bits);
            cpu
        });
        cpu.memory.set_input_state(self.input_bits);

        if !self.did_init {
            let init = Machine::label_address(&self.artifacts.labels, "Init")
                .or(self.artifacts.entry_point);
            if let Some(addr) = init {
                let init_entry = self.machine.entry_address(Some(addr));
                let (_rgba, _steps, _reason) = self.machine.run_frame(cpu, init_entry);
            }
            self.did_init = true;
        }

        let update =
            Machine::label_address(&self.artifacts.labels, "Update").or(self.artifacts.entry_point);
        let update_entry = self.machine.entry_address(update);
        let (rgba, _steps, _reason) = self.machine.run_frame(cpu, update_entry);
        let (w, h) = self.machine.video_size();
        Some((rgba, w, h))
    }

    pub fn set_input_bits(&mut self, bits: u8) {
        self.input_bits = bits;
        if let Some(cpu) = self.cpu.as_mut() {
            cpu.memory.set_input_state(bits);
        }
    }
}
