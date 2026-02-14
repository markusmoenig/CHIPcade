    .include "include/chipcade.inc"
    .include "utils.asm"

; Zero-page state
.const SPR_POS_X $40
.const SPR_FRAME $41
.const SPR_DIR   $42

Init:
    LDA #$20
    STA SPR_POS_X
    LDA #$00
    STA SPR_FRAME
    STA SPR_DIR

    ; Clear background color 0
    LDA #$00
    JSR ClearVRAM

    ; Draw first sprite frame
    LDA SPR_POS_X
    LDY #$50
    LDX #SPR_CHIPCADE
    JSR BlitSprite0
    BRK

Update:
    LDA SPR_DIR
    BEQ MoveRight

MoveLeft:
    DEC SPR_POS_X
    LDA SPR_POS_X
    CMP #$10
    BCS AfterMove
    LDA #$00
    STA SPR_DIR
    JMP AfterMove

MoveRight:
    INC SPR_POS_X
    LDA SPR_POS_X
    CMP #$DC
    BCC AfterMove
    LDA #$01
    STA SPR_DIR

AfterMove:
    INC SPR_FRAME
    LDA SPR_POS_X
    LDY #$50
    LDX #SPR_CHIPCADE
    JSR BlitSprite0
    BRK
