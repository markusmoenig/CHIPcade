#  Design Document

## CPU

### Instruction Set

16bit processor with 8 registers, flags? and a stack.

- LDI Rd, Value. Load an immediate value to the register.

## GCP (Graphical Co-Processor)

### Concepts

8 layers in the resolution of the screen and 9 registers R0 - R8. 

The bits of R0 - R7 determine the features for these layers:

- Bit1: Turn layer visibility on / off.
- Bit2: Enabled signed coordinates.   


