---
title: "Reference"
weight: 3
---

## CPU

16bit processor with 8 registers, flags and a stack.

### Instruction Set

- **TAG CodeTag**. Set a code tag (for Jump or Call instructions).
- **# Text**. Set a comment.
- **NOP**. No operation. Does nothing.

- **LD Rd Memory + Offset**. Load memory to the destination register.
- **LDI Rd Value**. Load an immediate value to the destination register.
- **LDRESX Rd**. Load the x value of the screen resolution to the destination register.
- **LDRESY Rd**. Load the y value of the screen resolution to the destination register.
- **ST Memory + Offset Rs**. Store the source register at the destination memory address.

- **ADD Rd Rs**. Add the source to the destination register.
- **SUB Rd Rs**. Subtract the source from the destination register.
- **MUL Rd Rs**. Multiply the source with the destination register.
- **DIV Rd Rs**. Divide the destination by the source register.
- **MOD Rd Rs**. Modulus of the destination by the source register.

- **INC Rd**. Increase the destination register by 1.
- **DEC Rd**. Decrease the destination register by 1.

- **CALL CodeTag**. Saves the current code address on the stack and invokes the subroutine.
- **RET**. Returns from a subroutine invoked by CALL. Pops the code address from the stack and continues execution after the original CALL statement. If there is no address on the stack, stops execution.

- **CMP Rd Rs**. Compare two registers.
- **J CodeTag**. Unconditional jump.
- **JE CodeTag**. Jump if the zero flag is set (equality check).
- **JNE CodeTag**. Jump if the zero flag is not set (inequality check).
- **JL CodeTag**. Jump if the negative flag is set (less than).
- **JG CodeTag**. Jump if the zero flag is clear and the negative flag is clear (greater than).
- **JC CodeTag**. Jump if the carry flag is set (used for unsigned comparisons).
- **JO CodeTag**. Jump if the overflow flag is set (used for signed overflows).

- **RAND Rd Value**. Generates a random number of type Value in the range of 0...Value and stores it in the destination register.

### CPU Flags

- **Zero Flag (ZF)**. Set when the result of an operation is zero.
- **Carry Flag (CF)**. Set when an arithmetic operation results in an unsigned overflow (carry out of the most significant bit) or underflow (borrow into the most significant bit).
- **Overflow Flag (OF)**. Set when an arithmetic operation results in signed overflow (when the result exceeds the range of the signed data type).
- ** Negative Flag (NF)**. Set when the result of an operation is negative (for signed operations).

## GCP (Graphical Co-Processor)

8 layers with 256 hardware sprites, a palette, image groups and other hardware supported features.

### Layers

Layers are drawn starting from index 0 up to 7. By default layers are in the resolution of the screen and invisible.

- **LYRRES L Width Height**. Set a custom layer resolution in the form of "320 200". By default layers are in the resolution of the screen.
- **LYRVIS Ld State**. Set layer visibility. Default is invisible.

### Sprites

256 hardware sprites

- **SPRLYR Sd Ls**. Assign a layer to the sprite. By default a sprite is not bound to a layer and will be drawn on top of all layers.

- **SPRSET Sd ImageGroup**. Assign an image group to the sprite.
- **SPRIMG Sd Rs**. Set the index of the image in the current image group. Stops any animation. Default is 0.
- **SPRANM Sd From To**. Set the animation range for the sprite and start animation. If the current image index is not inside the range set it to the animation start frame.
- **SPRFPS Sd Value**. Set the fps for the sprite's animation. Default is 10.

- **SPRVIS Sd State**. Set sprite visibility (Invisible/Visible). Default is invisible.
- **SPRWRP Sd State**. Set the wrapping mode for the sprite (Off/On). Wrapped sprites wrap around the layer or screen (i.e. when they go offscreen re-appear on the other side).

- **SPRX Sd Rs**. Set the x position of the sprite.
- **SPRY Sd Rs**. Set the y position of the sprite.
- **SPRROT Sd Rs**. Set the rotation of the sprite.
- **SPRPRI Sd Rs**. Set the priority of the sprite. Sprite with a lower priority are drawn last. Default is 0.

- **SPRACC Sd Rs**. Apply an acceleration impulse to the sprite.
- **SPRSPD Sd Rs**. Set a constant speed to the sprite.
- **SPRMXS Sd Rs**. Set the maximum speed for the sprite (for acceleration / impulse driven games).
- **SPRFRI Sd Rs**. Set the friction of the sprite (default is 1.0). A friction lower than 1.0 will reduce speed.

- **SPRGRP Sd Value**. Set the collision group of the sprite to the given value. The value can be any numerical value.
- **SPRCOL Sd Value**. Checks if the sprite collides with any sprite in the collision group. If no, sets the ZF to 1, if yes sets the ZF to 0.
