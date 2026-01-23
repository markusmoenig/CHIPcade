# CHIPcade assembler (fork of asm6502 v0.1.2)
[Upstream](https://github.com/bgourlie/asm6502) (MIT).

Bundled into CHIPcade with fixes and improvements (labels, constants and more). It now lives as
the `asm6502` module inside the main crate instead of a separate dependency.

### Usage

```rust
use chipcade::asm6502::assemble;

let asm = "LDA #1\nADC #1\nCMP #2".as_bytes();
let mut buf = Vec::<u8>::new();
if let Err(msg) = assemble(asm, &mut buf) {
     panic!("Failed to assemble: {}", msg);
}
 
assert_eq!(&[0xa9, 0x1, 0x69, 0x1, 0xc9, 0x2], &buf[..]);
```

The the input and output parameters of the `assemble` function are generic over the 
[`Read`](https://doc.rust-lang.org/stable/std/io/trait.Read.html) and 
[`Write`](https://doc.rust-lang.org/stable/std/io/trait.Write.html) traits, 
respectively. A more typical usage of this function would accept an input file and an output file.
