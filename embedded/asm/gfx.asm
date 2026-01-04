; Graphics helpers

; ClearVRAM - Clear all VRAM with a color
; Input: A = color nibble (0-15)
; Modifies: A, X, Y, $00, $01
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
    CPX #>(VRAM+VRAM_SIZE)  ; run until high byte reaches end of VRAM
    BEQ ClearDone
    STX $01
    JMP ClearPage
ClearDone:
    RTS
