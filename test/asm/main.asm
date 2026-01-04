.include "include/chipcade.inc"
.include "gfx.asm"

Start:
; Clear VRAM
LDA #$01
JSR ClearVRAM

; activate sprite
LDA #0            ; slot
LDX #$50          ; X
LDY #$50          ; Y
JSR SetSprite

BRK
