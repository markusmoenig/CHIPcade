.include "include/chipcade.inc"
.include "gfx.asm"

.const SPR_POS_X $20
.const SPR_DIR   $21
.const SPR_FRAME $22
.const SPR_INIT  $23

; One-time init (guarded by SPR_INIT flag)
Init:
    LDA SPR_INIT
    BNE InitDone

    ; Clear VRAM
    LDA #$01
    JSR ClearVRAM

    ; activate sprite
    LDA #0            ; slot
    LDX #$50          ; X
    LDY #$50          ; Y
    JSR SetSprite

    ; init anim state
    LDA #$50
    STA SPR_POS_X
    LDA #0
    STA SPR_DIR       ; 0 = right, 1 = left
    STA SPR_FRAME

    LDA #1
    STA SPR_INIT
InitDone:
    BRK

; Per-frame update (called once per run)
Update:
    JSR AnimateSprite
    INC SPR_FRAME
    BRK

; Move sprite left/right based on zero page state.
AnimateSprite:
    LDA SPR_DIR
    BEQ MoveRight
MoveLeft:
    LDA SPR_POS_X
    CMP #$10          ; left clamp
    BCC SwitchToRight
    DEC SPR_POS_X
    JMP DoUpdate
MoveRight:
    LDA SPR_POS_X
    CMP #$DC          ; right clamp (leaves room on screen)
    BCS SwitchToLeft
    INC SPR_POS_X
    JMP DoUpdate
SwitchToLeft:
    LDA #1
    STA SPR_DIR
    DEC SPR_POS_X
    JMP DoUpdate
SwitchToRight:
    LDA #0
    STA SPR_DIR
    INC SPR_POS_X

DoUpdate:
    LDX SPR_POS_X
    LDY #$50
    LDA #0            ; slot
    JSR SetSprite
    RTS
