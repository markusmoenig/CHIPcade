#  Design Document

## CPU

### Instruction Set

16bit processor with 8 registers, flags and a stack.

- **LDI Rd, Memory Address**. Load memory to the destination register.
- **LDI Rd, Value.** Load an immediate value to the destination register.
- **ST Memory Addres, Rs.** Store the source register at the destination memory address.

- **INC Rd**. Increase the destination register by 1.
- **DEC Rd**. Decrease the destination register by 1.

## GCP (Graphical Co-Processor)

### Concepts

8 layers in the resolution of the screen and 9 registers R0 - R8. 

The bits of R0 - R7 determine the features for these layers:

- Bit1: Turn layer visibility on / off.
- Bit2: Enabled signed coordinates.   


