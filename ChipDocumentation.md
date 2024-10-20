#  CPU / GCP Documentation

## CPU

16bit processor with 8 registers, flags and a stack.

### Flags

- **Zero Flag (ZF)**. Set when the result of an operation is zero.
- **Carry Flag (CF)**. Set when an arithmetic operation results in an unsigned overflow (carry out of the most significant bit) or underflow (borrow into the most significant bit).
- **Overflow Flag (OF)**. Set when an arithmetic operation results in signed overflow (when the result exceeds the range of the signed data type).
- ** Negative Flag (NF)**. Set when the result of an operation is negative (for signed operations).

### Instruction Set

- **LD Rd, Memory Address**. Load memory to the destination register.
- **LDI Rd, Value**. Load an immediate value to the destination register.
- **LDRESX Rd**. Load the x value of the screen resolution to the destination register.
- **LDRESY Rd**. Load the y value of the screen resolution to the destination register.
- **ST Memory Addres, Rs**. Store the source register at the destination memory address.

- **INC Rd**. Increase the destination register by 1.
- **DEC Rd**. Decrease the destination register by 1.

- **CMP Rd Rs**. Compare two registers.
- **JE Code Tag**. Jump if the zero flag is set (equality check).
- **JNE Code Tag**. Jump if the zero flag is not set (inequality check).
- **JL Code Tag**. Jump if the negative flag is set (less than).
- **JG Code Tag**. Jump if the zero flag is clear and the negative flag is clear (greater than).
- **JC Code Tag**. Jump if the carry flag is set (used for unsigned comparisons).
- **JO Code Tag**. Jump if the overflow flag is set (used for signed overflows).

## GCP (Graphical Co-Processor)

8 layers with 256 hardware sprites, a palette, image groups and other hardware supported features.

### Sprites

256 hardware sprites

- **SPRSET Sd, ImageGroup**. Assign the image group to the sprite.
- **SPRVIS Sd, Rs**. Enable / disable visibility of the sprite (0, 1).
- **SPRX Sd, Rs**. Set the x position of the sprite.
- **SPRY Sd, Rs**. Set the y position of the sprite.
