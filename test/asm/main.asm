; Entry point
.include "include/chipcade.inc"

Start:
; Clear VRAM then write a small pattern (bitmap mode, VRAM base 0x2000)

; Zero page pointers
; $00 -> low byte of VRAM address (always 0)
; $01 -> high byte of VRAM address (0x20..0x7F)

LDA #$00      ; low byte
STA $00
LDA #>VRAM
STA $01

LDA $02       ; fill byte from zero-page color (low nibble used)
LDX #$20      ; high byte loop start

ClearPage:
LDY #$00
ClearLoop:
STA ($00),Y
INY
BNE ClearLoop

INX           ; next page
STX $01
CPX #$80      ; run until high byte reaches 0x80 (0x7F is last page)
BNE ClearPage

; Reset pointer to start of VRAM for the pattern
LDA #>VRAM
STA $01
LDA #$00
STA $00

; Now write a simple pattern at the start of VRAM
LDY #$00
LDX #$80      ; 128 bytes -> 256 pixels on first line
PatternLoop:
LDA #$20      ; hi nibble = clear color (from clear), lo nibble = background(0)
STA ($00),Y
INY
LDA #$02      ; hi nibble = 0, lo nibble = clear color
STA ($00),Y
INY
DEX
BNE PatternLoop

; activate sprite
LDY #$00
LDA #<SPRITE_RAM
STA $00
LDA #>SPRITE_RAM
STA $01

LDA #$50          ; X
STA ($00),Y
INY
LDA #$50          ; Y
STA ($00),Y
INY
LDA #SPR_CHIPCADE ; image index 0 (SPR_CHIPCADE)
STA ($00),Y
INY
LDA #%00010001    ; enable + size=16x16
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

BRK
