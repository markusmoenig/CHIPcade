; Entry point
    .include "include/chipcade.inc"

Start:
    LDA #$00
    STA $2000       ; example: write a byte to VRAM base
    BRK
