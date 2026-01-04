; Graphics helpers

; ClearVRAM - Clear all VRAM with a color
; Input: A = color nibble (0-15)
; Modifies: A, X, Y, $00, $01
.const SPR_TMP_SLOT $10
.const SPR_TMP_X $11
.const SPR_TMP_Y $12
.const SPR_TMP_OFF_LO $13
.const SPR_TMP_OFF_HI $14

ClearVRAM:
    ; Set up zero page pointer to VRAM
    PHA           ; save color
    LDA #$00
    STA $00       ; low byte
    LDA #>VRAM
    STA $01       ; high byte
    PLA           ; restore color

    ; Pack color into both nibbles (2 pixels per byte)
    AND #15       ; mask to 4 bits
    TAX
    ASL A
    ASL A
    ASL A
    ASL A
    STX $02       ; temp store
    ORA $02       ; combine hi and lo nibbles

    ; Clear all VRAM pages
    LDX #>VRAM    ; start at VRAM high byte
ClearPage:
    LDY #$00
ClearLoop:
    STA ($00),Y
    INY
    BNE ClearLoop

    INX           ; next page
    CPX #$80  ; run until high byte reaches end of VRAM (temp hardcode for debug)
    BEQ ClearDone
    STX $01
    JMP ClearPage
ClearDone:
    RTS

; SetSprite - configure a sprite entry (slot * 8 bytes) with CHIPCADE image and colors.
; Inputs: A = slot index (0-63), X = X coordinate, Y = Y coordinate.
; Uses: $00-$01 (pointer), SPR_TMP_* temps.
SetSprite:
    STA SPR_TMP_SLOT
    STX SPR_TMP_X
    STY SPR_TMP_Y

    ; offset = slot * 8
    LDA #0
    STA SPR_TMP_OFF_HI
    LDY SPR_TMP_SLOT
    TYA
    ASL A
    ROL SPR_TMP_OFF_HI
    ASL A
    ROL SPR_TMP_OFF_HI
    ASL A
    ROL SPR_TMP_OFF_HI
    STA SPR_TMP_OFF_LO

    ; pointer = SPRITE_RAM + offset
    CLC
    LDA #<SPRITE_RAM
    ADC SPR_TMP_OFF_LO
    STA $00
    LDA #>SPRITE_RAM
    ADC SPR_TMP_OFF_HI
    STA $01

    LDY #$00
    LDA SPR_TMP_X
    STA ($00),Y
    INY
    LDA SPR_TMP_Y
    STA ($00),Y
    INY
    LDA #SPR_CHIPCADE ; image index
    STA ($00),Y
    INY
    LDA #%00010000    ; enable + size=8x8
    STA ($00),Y
    INY
    LDA #12           ; Color 1
    STA ($00),Y
    INY
    LDA #7            ; Color 2
    STA ($00),Y
    INY
    LDA #15           ; Color 3
    STA ($00),Y
    INY
    LDA #0            ; reserved
    STA ($00),Y

    RTS
