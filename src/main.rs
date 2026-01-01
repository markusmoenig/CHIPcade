mod bus;
mod config;

use bus::ChipcadeBus;
use chipcade_asm::assemble;
use mos6502::cpu;
use mos6502::instruction::Nmos6502;
use mos6502::memory::Bus;
use std::fs;
use std::io::Cursor;

fn main() {
    // Load machine configuration
    let config = config::load_config("chipcade.toml").expect("failed to load chipcade.toml");
    println!(
        "Config loaded: cpu={}, clock={}Hz, refresh={}Hz, video={}x{} {}, palette global={}, sprite_palettes={}, colors_per_sprite={}",
        config.machine.cpu,
        config.machine.clock_hz,
        config.machine.refresh_hz,
        config.video.width,
        config.video.height,
        config.video.mode,
        config.palette.global_colors,
        config.palette.sprite_palettes,
        config.palette.colors_per_sprite
    );

    // Static memory map for the machine (auto-laid out from config)
    let mem_map = config::MemoryMap::from_config(&config);
    println!(
        "Memory map: zero_page={:#06x}, stack={:#06x}, ram={:#06x}, video_ram={:#06x}, palette_ram={:#06x}, palette_map={:#06x}, sprite_ram={:#06x}, io={:#06x}, rom={:#06x}",
        mem_map.zero_page,
        mem_map.stack,
        mem_map.ram,
        mem_map.video_ram,
        mem_map.palette_ram,
        mem_map.palette_map,
        mem_map.sprite_ram,
        mem_map.io,
        mem_map.rom
    );

    // 1. Load assembly source from test.asm
    let asm = fs::read("test.asm").expect("failed to read asm file");
    println!("Read {} bytes from test.asm", asm.len());
    println!("Content: {}", String::from_utf8_lossy(&asm));

    let mut program = Vec::<u8>::new();
    let result = assemble(&mut Cursor::new(asm), &mut program);
    println!("Assembly result: {:?}", result);

    println!("Assembled program: {:?}", program);
    println!("Program length: {}", program.len());

    let mut cpu = cpu::CPU::new(ChipcadeBus::from_config(&config), Nmos6502);

    // Zero page: $00/$01 used as VRAM pointer, $02 used as clear color (both nibbles)
    let clear_nibble = 0x02u8;
    let clear_byte = (clear_nibble << 4) | clear_nibble;
    let zero_page_data = [
        (mem_map.video_ram & 0x00FF) as u8,
        (mem_map.video_ram >> 8) as u8,
        clear_byte,
    ];

    // Place an invalid opcode as a stop sentinel so cpu.run() exits
    program.push(0xff);

    // Clear VRAM to color stored at $02 (low nibble)
    cpu.memory.set_bytes(0x00, &zero_page_data);
    let clear_color = cpu.memory.get_byte(0x02) & 0x0F;
    cpu.memory.vram.clear(clear_color);

    cpu.memory.set_bytes(0x00, &zero_page_data);
    cpu.memory.set_bytes(0x10, &program);
    cpu.registers.program_counter = 0x10;

    // Run until BRK (0x00) or invalid (0xFF) with debug output per step
    for _ in 0..1_000_000 {
        let pc = cpu.registers.program_counter;
        let opcode = cpu.memory.get_byte(pc);
        println!(
            "PC={:04X} A={:02X} X={:02X} Y={:02X} SP={:02X} FLAGS={:08b}",
            pc,
            cpu.registers.accumulator,
            cpu.registers.index_x,
            cpu.registers.index_y,
            cpu.registers.stack_pointer.to_u16(),
            cpu.registers.status
        );
        if opcode == 0x00 || opcode == 0xFF {
            break;
        }
        cpu.single_step();
    }

    // Dump VRAM to PNG (bitmap 4bpp: 2 pixels per byte, palette index 0..15 -> grayscale)
    cpu.memory
        .save_bitmap_png("vram_dump.png")
        .expect("failed to save vram_dump.png");
    println!("Saved VRAM to vram_dump.png");
}
