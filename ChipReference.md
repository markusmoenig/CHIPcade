# Chip Reference

For more detailed information and tutorials please visit [CHIPcade.com](https://chipcade.com).

## CPU

16bit processor with 8 registers, special user event registers, flags and a stack.

## Registers



## Values

16bit Values in CHIPcade can be one of:

- **Unsigned**: Positive integer, ends with *u* (**10u**).
- **Signed**: Integer, positive or negative, ends with *s* (**-2s**).
- **Float**:, Decimal, ends with *f* (**0.02f**).
- **Unicode**: Single character, in " " or `, e.g., "A".

Values can also reference a register, for example to set the friction of sprite #0 you could write **SPRFRI S0 0.5f** or **SPRFRI S0 R2** to set the friction to the content of register 2.

Arithmetic operations automatically convert the source value to match the type of the destination value before execution. As a result, arithmetic operations are guaranteed not to fail.

## Instruction Set

- **TAG CodeTag**. Set a code tag (for Jump or Call instructions).
- **# Text**. Set a comment.
- **NOP**. No operation. Does nothing.

- **LD Rd Memory + (Value|Rs)**. Load memory to the destination register.
- **LDI Rd (Value|Rs)**. Load an immediate value to the destination register.
- **LDRESX Rd**. Load the x value of the screen resolution to the destination register.
- **LDRESY Rd**. Load the y value of the screen resolution to the destination register.
- **LDSPR Rd (Ss|Rs) Attr**. Load an attribute of the sprite into the destination register. All values are returned as floats. Attributes: "x", "y", "width", "height", "rotation", "speed".
- **ST Memory + (Value|Rs) (Value|Rs)**. Store the value at the destination memory address.

- **ADD Rd (Value|Rs)**. Add the source value to the destination register. The source value is automatically converted to match the type of the destination value before execution.
- **SUB Rd (Value|Rs)**. Subtract the source value from the destination register. The source value is automatically converted to match the type of the destination value before execution.
- **MUL Rd (Value|Rs)**. Multiply the source value with the destination register. The source value is automatically converted to match the type of the destination value before execution.
- **DIV Rd (Value|Rs)**. Divide the destination by the source value. The source value is automatically converted to match the type of the destination value before execution.
- **MOD Rd (Value|Rs)**. Modulus of the destination by the source value. The source value is automatically converted to match the type of the destination value before execution.

- **INC Rd**. Increase the destination register by 1.
- **DEC Rd**. Decrease the destination register by 1.

- **COS Rd (Value|Rs)**. Calculates the cosine of the given angle (in radians) and stores the result in the destination register Rd.
- **SIN Rd (Value|Rs)**. Calculates the sine of the given angle (in radians) and stores the result in the destination register Rd.

- **CALL [Module.]Tag**. Saves the current code address on the stack and invokes the subroutine.
- **CALLTM [Module.]Tag (Value|Rs)**. Call a subroutine after a specified delay (in seconds).
- **TIME Rd**. Set the destination register to the elapsed time since game start in seconds (float).

- **RET**. Returns from a subroutine invoked by CALL. Pops the code address from the stack and continues execution after the original CALL statement. If there is no address on the stack, stops execution.

- **BRKPT**. Breakpoint. Halts execution allowing you to step through subsequent instructions for debugging purposes. The simulation remains paused until manually resumed, providing an opportunity to inspect register states, memory, and flags.

- **CMP Rd (Value|Rs)**. Compare the content of the destination register with the source value. The source value is automatically converted to match the type of the destination value before execution. As a result, CMP cannot fail.

- **J [Module.]Tag**. Unconditional jump.
- **JE [Module.]Tag**. Jump if the zero flag is set (equality check).
- **JNE [Module.]Tag**. Jump if the zero flag is not set (inequality check).
- **JL [Module.]Tag**. Jump if the negative flag is set (less than).
- **JG [Module.]Tag**. Jump if the zero flag is clear and the negative flag is clear (greater than).
- **JC [Module.]Tag**. Jump if the carry flag is set (used for unsigned comparisons).
- **JO [Module.]Tag**. Jump if the overflow flag is set (used for signed overflows).

- **RAND Rd (Value|Rs)**. Generates a random number of type Value in the range of 0...Value and stores it in the destination register.

## CPU Flags

- **Zero Flag (ZF)**. Set when the result of an operation is zero.
- **Carry Flag (CF)**. Set when an arithmetic operation results in an unsigned overflow (carry out of the most significant bit) or underflow (borrow into the most significant bit).
- **Overflow Flag (OF)**. Set when an arithmetic operation results in signed overflow (when the result exceeds the range of the signed data type).
- ** Negative Flag (NF)**. Set when the result of an operation is negative (for signed operations).

## GCP (Graphical Co-Processor)

8 layers with 256 hardware sprites, a palette, image groups and other hardware supported features.

## Layers

Layers are drawn starting from index 0 up to 7. By default layers are in the resolution of the screen and invisible.

- **LYRRES L Width Height**. Set a custom layer resolution in the form of "320 200". By default layers are in the resolution of the screen.
- **LYRVIS Ld (Value|Rs)**. Set layer visibility. A value of 0 means invisible, visible otherwise. Default is invisible.
- **LYRCUR Ld**. Set the current layer. The current layer is used for drawing all non-sprites content like text or shapes. By default set to 0.

## Sprites

256 hardware sprites

- **SPRLYR (Sd|Rs) Ls**. Assign a layer to the sprite. By default a sprite is not bound to a layer and will be drawn on top of all layers.

- **SPRSET (Sd|Rs) ImageGroup**. Assign an image group to the sprite.
- **SPRIMG (Sd|Rs) (Value|Rs)**. Set the index of the image in the current image group. Stops any animation. Default is 0.
- **SPRANM (Sd|Rs) From To**. Set the animation range for the sprite and start animation. If the current image index is not inside the range, set it to the animation start frame.
- **SPRFPS (Sd|Rs) (Value|Rs)**. Set the fps for the sprite's animation. Default is 10.

- **SPRACT (Sd|Rs) (Value|Rs)**. Activate / deactivate the sprite. A value of 0 deactivates the sprite, any other value will activate it. Every sprite is deactivated by default.
- **SPRWRP (Sd|Rs) (Value|Rs)**. Set the wrapping mode for the sprite (0 for off, on otherwise). Wrapped sprites wrap around the layer or screen (i.e. when they go offscreen re-appear on the other side).

- **SPRX (Sd|Rs) (Value|Rs)**. Set the x position of the sprite.
- **SPRY (Sd|Rs) (Value|Rs)**. Set the y position of the sprite.
- **SPRROT (Sd|Rs) (Value|Rs)**. Set the rotation of the sprite.
- **SPRROO (Sd|Rs) (Value|Rs)**. Set the rotation offset of the sprite. By default, CHIPcade assumes sprites are oriented upwards (0° points up). If a sprite, like a bullet, is designed to face right, you can apply a rotation offset of **-90s** to align it correctly. This offset adjusts the sprite’s default orientation, effectively rotating it an additional 90° counterclockwise.
- **SPRPRI (Sd|Rs) (Value|Rs)**. Set the priority of the sprite. Sprite with a higher priority are drawn on top of sprites with a lower priority. Default is 0.
- **SPRALP (Sd|Rs) (Value|Rs)**. Set the alpha value of the sprite. Default is 1.0 (fully opaque).
- **SPRSCL (Sd|Rs) (Value|Rs)**. Set the scale of the sprite. Default is 1.0.

- **SPRACC (Sd|Rs) (Value|Rs)**. Apply an acceleration impulse to the sprite.
- **SPRSPD (Sd|Rs) (Value|Rs)**. Set a constant speed to the sprite.
- **SPRMXS (Sd|Rs) (Value|Rs)**. Set the maximum speed for the sprite (for acceleration / impulse driven games).
- **SPRFRI (Sd|Rs) (Value|Rs)**. Set the friction of the sprite (default is 1.0). A friction lower than 1.0 will reduce speed.
- **SPRSTP (Sd|Rs)**. Deactivates the sprite after the current animation finishes. Useful for example for explosions.
- **SPRHLT (Sd|Rs)**. Set the velocity of the sprite to zero. Halt!

- **SPRGRP (Sd|Rs) (Value|Rs)**. Set the collision group of the sprite to the given value. The value can be any numerical value.
- **SPRCOL (Sd|Rs) (Value|Rs)**. Checks if the sprite collides with any sprite in the collision group. If no, sets the ZF to 1, if yes sets the ZF to 0.

## Text

Text is always drawn into the current layer.

- **FNTSET Font (Value|Rs)**. Sets the current font and font-size. Currently font can be one of: "OpenSans", "Square", "SquadaOne". 
- **TXTVAL (Value|Rs)**. Draws the value into the current layer. X, y positions are taken from R0 and R1 and the palette color index from R2.
- **TXTMEM Memory + (Value|Rs)**. Draws the value at the memory address into the current layer. If the value is a unicode character it draws the character and all following characters as a string. The first non-unicode character terminates the string. X, y positions are taken from R0 and R1 and the palette color index from R2.
