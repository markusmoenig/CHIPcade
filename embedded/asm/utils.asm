
; ClearVRAM
;   In:  A = 4-bit color index (0..15)
;   Out: VRAM filled with packed nibble color
;   Clobbers: A, X, Y, $00, $01, $03
ClearVRAM:
    AND #$0F
    STA $03
    ASL A
    ASL A
    ASL A
    ASL A
    ORA $03

    LDX #>VRAM_SIZE
    LDA #<VRAM
    STA $00
    LDA #>VRAM
    STA $01
    LDA $03
    ASL A
    ASL A
    ASL A
    ASL A
    ORA $03

ClearPage:
    LDY #$00
ClearByte:
    STA ($00),Y
    INY
    BNE ClearByte
    INC $01
    DEX
    BNE ClearPage
    RTS

; BlitSprite0
;   In:  A = x, Y = y, X = sprite tile index
;   Out: sprite #0 attributes written
;   Clobbers: A, Y, $04, $05
BlitSprite0:
    STY $04
    STX $05

    LDY #$00
    STA SPRITE_RAM,Y
    INY
    LDA $04
    STA SPRITE_RAM,Y
    INY
    LDA $05
    STA SPRITE_RAM,Y
    INY
    LDA #$10
    STA SPRITE_RAM,Y
    INY
    LDA #12
    STA SPRITE_RAM,Y
    INY
    LDA #7
    STA SPRITE_RAM,Y
    INY
    LDA #15
    STA SPRITE_RAM,Y
    INY
    LDA #0
    STA SPRITE_RAM,Y
    RTS
