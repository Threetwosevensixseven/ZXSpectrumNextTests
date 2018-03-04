; DMACopy.asm

zeusemulate             "128K"
zoLogicOperatorsHighPri = false
zoSupportStringEscapes  = false
Zeus_PC                 = Start
Stack                   equ Start
BootParaBase            equ $4000
optionsize              12
Mode                    optionlist 15, -15, "Mode","DMA Copy","DMA Fill","LDIR Copy","LDIR Fill"

                        org $8000
Start                   proc
::s:
                        di
                        ld sp, Stack
                        ld a, $BE
                        ld i, a
                        im 2
                        call Cls
                        call ClsAttr
                        call BootTestSetup
                        ei

                        nextreg $14, $E3                ; Set global transparency to bright magenta
                        PortOut($123B, $00)             ; Hide layer 2 and disable write paging
                        nextreg $15, %0 00 001 1 0      ; Disable sprites, over border, set LSU

                        if Mode = 0 ; DMA Copy

                          CopyDMA($C000, $4000, $1B00)  ; Copy screen at $C000 to $4000 using DMA
                          Border(Black)                 ; Black border means we did DMA

                        elseif Mode = 1 ; DMA Fill

                          FillDMA($4000, $1800, $AA)    ; Fill ULA screen (DMA) with stripes %10101010
                          FillDMA($5800, $0B00, $46)    ; Fill ULA screen (DMA) with yellow/black
                          Border(Black)                 ; Black border means we did DMA

                        elseif Mode = 2 ; LDIR Copy

                          CopyLDIR($C000, $4000, $1B00) ; Copy screen at $C000 to $4000 using LDIR
                          Border(Blue)                  ; Blue border means we did LDIR

                        elseif Mode = 3 ; LDIR Fill

                          FillLDIR($4000, $1800, $AA)   ; Fill ULA screen (LDIR) with stripes %10101010
                          FillLDIR($5800, $0B00, $42)   ; Fill ULA screen (LDIR) with red/black
                          Border(Blue)                  ; Blue border means we did LDIR

                        endif
Loop:
                        halt
                        call BootTest
                        jp Loop
pend

Cls                     proc
                        di
                        ld (EXIT+1), sp                 ; Save the stack
                        ld sp, $5800                    ; Set stack to end of screen
                        ld de, $0000                    ; All pixels unset
                        ld b, e                         ; Loop 256 times: 12 words * 256 = 6144 bytes
                        noflow
CLS_LOOP:               defs 12, $D5                    ; 12 lots of push de
                        djnz CLS_LOOP
EXIT:                   ld sp, $0000                    ; Restore the stack
                        ei
                        ret
pend

ClsAttr                 proc
                        ClsAttrFull(DimBlackWhiteP)
                        ret
pend

ClsAttrFull             macro(Colour)
                        ld a, Colour
                        ld hl, ATTRS_8x8
                        ld (hl), a
                        ld de, ATTRS_8x8+1
                        ld bc, ATTRS_8x8_COUNT-1
                        ldir
mend

Border                  macro(Colour)
                        if Colour=0
                          xor a
                        else
                          ld a, Colour
                        endif
                        out (ULA_PORT), a
mend

PortOut                 macro(Port, Value)
                        ld bc, Port
                        ld a, Value
                        out (c), a
mend

FillLDIR                macro(SourceAddr, Size, Value)
                        ld a, Value
                        ld hl, SourceAddr
                        ld (hl), a
                        ld de, SourceAddr+1
                        ld bc, Size-1
                        ldir
mend

CopyLDIR                macro(SourceAddr, DestAddr, Size)
                        ld hl, SourceAddr
                        ld de, DestAddr
                        ld bc, Size
                        ldir
mend

CopyDMA                 macro(SourceAddr, DestAddr, Size)
                        ld a, %01010100
                        ld (DMAinit.Source), a
                        call DMAinit
                        ld hl, SourceAddr
                        ld de, #7DCD                    ; AD = cont, CD = burst   0 1111 1 01
                        ld bc, DMAPort                  ; DataGear
                        out (c), d                      ; R0-Transfer mode, A -> B
                        out (c), l                      ; R0-Port A, Start address (source)
                        out (c), h
                        ld a, high Size
                        if low Size = 0
                          out (c), b                    ; R0-Block length
                        else
                          ld d, low Size
                          out (c), d
                        endif
                        out (c), a
                        out (c), e                      ; R4-Continuous (burst) mode
                        ld a, high DestAddr
                        if low DestAddr = 0
                          out (c), b                    ; R0-Block length
                        else
                          ld d, low DestAddr
                          out (c), d
                        endif
                        out (c), a
                        call DMAexe
mend

FillDMA                 macro(DestAddr, Size, Value)
                        ld a, Value
                        ld (DMAinit.SourceValue), a
                        ld a, %01110100
                        ld (DMAinit.Source), a
                        call DMAinit
                        ld hl, DMAinit.SourceValue
                        ld de, #7DCD                    ; AD = cont, CD = burst   0 1111 1 01
                        ld bc, DMAPort                  ; DataGear
                        out (c), d                      ; R0-Transfer mode, A -> B
                        out (c), l                      ; R0-Port A, Start address (source)
                        out (c), h
                        ld a, high Size
                        if low Size = 0
                          out (c), b                    ; R0-Block length
                        else
                          ld d, low Size
                          out (c), d
                        endif
                        out (c), a
                        out (c), e                      ; R4-Continuous (burst) mode
                        ld a, high DestAddr
                        if low DestAddr = 0
                          out (c), b                    ; R0-Block length
                        else
                          ld d, low DestAddr
                          out (c), d
                        endif
                        out (c), a
                        call DMAexe
mend

DMAinit                 proc
                        ld hl, Data
                        ld bc,(End-Data)*256+DMAPort
                        otir
                        ret
Data:                   db $C3                          ; R6-RESET DMA
                        db $C7                          ; R6-RESET PORT A Timing
                        db $CB                          ; R6-SET PORT B Timing same as PORT A
Source:                 db %01010100                    ; R1-Port A address incrementing, variable timing (D5=1 no source increment)
                        db $02                          ; R1-Cycle length 2T
Dest:                   db %01010000                    ; R2-Port B address incrementing, variable timing
                        db $02                          ; R2-Cycle length 2T
                        db $82                          ; R5-Stop on end of block, RDY active LOW
End:
SourceValue:            db $00
pend

DMAexe                  proc
                        ld a, $CF                       ; R6-Load
                        out (c), a
                        ld a, $AB
                        out (c), a
                        ld a, $B7
                        out (c), a
                        ld a, $B3                       ; R6-Force ready
                        out (c), a
                        ld a, $87                       ; Enable DMA
                        out (c), a
                        ret
pend

DMAPort                 equ $6B
SCREEN                  equ $4000                       ; Start of screen bitmap
ATTRS_8x8               equ $5800                       ; Start of 8x8 attributes
ATTRS_8x8_END           equ $5B00                       ; End of 8x8 attributes
ATTRS_8x8_COUNT         equ ATTRS_8x8_END-ATTRS_8x8     ; 768
ULA_PORT                equ $FE                         ; out (254), a
DimBlackWhiteP          equ $38
Black                   equ 0
Blue                    equ 1
Red                     equ 2
Magenta                 equ 3
Green                   equ 4
Cyan                    equ 5
Yellow                  equ 6
White                   equ 7

include                 "ParaBootStub.inc"      ; Parasys remote debugger slave stub

org $BE00                                       ; Have an IM 2 ISR at $BE00...
                        loop 257
                          db $BF
                        lend
org $BFBF
                        ei                      ; ...which doesn't do anything
                        reti                    ; except avoid the ROM IM 2 ISR being called

org $C000
import_bin              "Test.scr"              ; Test screen used as the source of the copy

if zeusver < 72                                 ; Make sure we have the latest features ('don't care' x bits in binary literals)
  zeuserror "Upgrade to Zeus v3.99 or above, available at http://www.desdes.com/products/oldfiles/zeus.htm."
endif

output_z80              "DMACopy.z80", $0000, Start
output_para             Start, $FFFF-Start

