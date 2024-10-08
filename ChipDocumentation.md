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
- **ST Memory Addres, Rs**. Store the source register at the destination memory address.

- **INC Rd**. Increase the destination register by 1.
- **DEC Rd**. Decrease the destination register by 1.

## GCP (Graphical Co-Processor)

### Concepts

8 layers in the resolution of the screen and 9 registers R0 - R8. 

The bits of R0 - R7 determine the features for these layers:

- Bit1: Turn layer visibility on / off.
- Bit2: Enabled signed coordinates.   

### Sprites

256 hardware sprites

- **SPRSET Sd, ImageGroup**. Assign the image group to the sprite.
