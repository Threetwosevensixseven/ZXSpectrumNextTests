; Level2Order.asm

zeusemulate             "128K"
zoLogicOperatorsHighPri = false
zoSupportStringEscapes  = false
Zeus_PC                 = Start
BootParaBase            equ $4000                       ; Locate ParaSys full stave in the screen to save memory
Stack                   equ $FFFF

optionsize              12
Order                   optionlist 15, -15, "Order (left is topmost)","SLU","LSU","SUL","LUS","USL","ULS"


org $C000
Start:
s:                                                      ; Enables you to type cs in ParaSys to call Start
                        di
                        ld sp, Stack
                        ld a, $BE
                        ld i, a
                        im 2
                        call BootTestSetup              ; Setup ParaSys remote debugger
; Test code starts
                        di
                        Border(0)                       ; Black
                        Fill($4000, $1800, $AA)         ; Fill ULA pixels with vertical stripes
                        Fill($5800, $1B00, $59)         ; Set ULA attrs to bright blue/magenta
                        nextreg $14, $E3                ; Set global transparency to bright magenta
                        nextreg $74, $00                ; Set transparency fallback to black

                                                        ; Garry Lancaster: The default value for bright magenta
                                                        ; in the ULA palette is actually $E7, not $E3. This was done
                                                        ; to ensure existing Spectrum software doesn't display
                                                        ; incorrectly (ie transparent where it shouldn't be)
                                                        ; if using bright magenta.
                        nextreg $43, $00                ; First palettes, autoincrement, edit ULA palette
                        nextreg $40, $1B                ; Choose Bright magenta background index
                        nextreg $41, $E3                ; Redefine to global transparency

                        nextreg $50, 24                 ; MMU page bottom 48K to layer 2
                        nextreg $51, 25
                        nextreg $52, 26
                        nextreg $53, 27
                        nextreg $54, 28
                        nextreg $55, 29
                        nextreg $12, 28                 ; Set layer 2 page to 28

                        Fill($0000, $4000, $C0)         ; Fill layer 2 top    1/3rd with yellow      %111 111 00  $FC
                        Fill($4000, $4000, $E3)         ; Fill layer 2 middle 1/3rd with transparent %111 000 11  $E3
                        Fill($8000, $4000, $1C)         ; Fill layer 2 bottom 1/3rd with green       %000 111 00  $1C

                        PortOut($123B, $02)             ; Set layer 2 visible and disable write paging
                        //nextreg $50, $FF              ; MMU page ROM back into to $0000-1FFF

                        Value=(Order*4)+3
                        nextreg $15, Value              ; Enable sprites, over border, dynamic order
;                       nextreg $15, %0 00 000 1 1      ; Enable sprites, over border, set SLU
;                       nextreg $15, %0 00 001 1 1      ; Enable sprites, over border, set LSU
;                       nextreg $15, %0 00 010 1 1      ; Enable sprites, over border, set SUL
;                       nextreg $15, %0 00 011 1 1      ; Enable sprites, over border, set LUS
;                       nextreg $15, %0 00 100 1 1      ; Enable sprites, over border, set USL
;                       nextreg $15, %0 00 101 1 1      ; Enable sprites, over border, set ULS

                        SetSpritePattern(TestSprite, 0, 0) ; Set test sprite pattern
                        NextSprite(0, 32, 48, 0, false, false, false, true, 0) ; Y=48 is in the top 1/3rd
                        NextSprite(1, 32, 64, 0, false, false, false, true, 0) ; Y=64 is in the middle 1/3rd

                        nextreg $50, 255                ; MMU page bottom 48K back
                        nextreg $51, 255
                        nextreg $52, 10
                        nextreg $53, 11
                        nextreg $54, 4
                        nextreg $55, 5
                        ei
; Test code ends
Loop:
                        halt
                        call BootTest                   ; Check for ParaSys commands every frame
                        jp Loop

TestSprite:
                        db  $E3, $E3, $E3, $E0, $E1, $E0, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3;
                        db  $E3, $E3, $1D, $19, $35, $19, $1D, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3;
                        db  $E3, $E3, $C1, $C1, $C1, $C1, $C1, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3;
                        db  $E3, $E3, $E3, $E0, $E8, $E0, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3;
                        db  $C1, $E0, $FF, $E1, $C5, $E1, $FF, $E0, $C1, $E3, $E3, $E3, $E3, $E3, $E3, $E3;
                        db  $F5, $E0, $E0, $DF, $BF, $DF, $E0, $E0, $F5, $E3, $E3, $E3, $E3, $E3, $E3, $E3;
                        db  $F9, $E3, $E0, $E0, $FF, $E0, $E0, $E3, $F9, $E3, $E3, $E3, $E3, $E3, $E3, $E3;
                        db  $FC, $E3, $E3, $C0, $E0, $C0, $E3, $E3, $FC, $E3, $E3, $E3, $E3, $E3, $E3, $E3;
                        db  $E3, $E3, $E3, $C0, $E0, $C0, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3;
                        db  $E3, $E3, $E1, $E1, $E3, $E1, $E1, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3;
                        db  $E3, $E3, $C4, $C4, $E3, $C4, $C4, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3;
                        db  $E3, $FD, $FC, $F5, $E3, $F5, $FC, $FC, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3;
                        db  $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3;
                        db  $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3;
                        db  $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3;
                        db  $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3, $E3;

Border                  macro(Colour)
                        if Colour=0
                          xor a
                        else
                          ld a, Colour
                        endif

                        out ($FE), a
mend

Fill                    macro(SourceAddr, Size, Value)
                        ld a, Value
                        ld hl, SourceAddr
                        ld (hl), a
                        ld de, SourceAddr+1
                        ld bc, Size-1
                        ldir
mend

PortOut                 macro(Port, Value)
                        ld bc, Port
                        ld a, Value
                        out (c), a
mend

SetSpritePattern        macro (Address, NextPatternNo, DataPatternNo)
                        ld hl, Address+(DataPatternNo*256)
                        ld a, NextPatternNo
                        call WriteSpritePattern
mend

WriteSpritePattern:
                        ld bc, $303B                    ; Set the sprite index
                        out (c), a                      ; (0 to 63)
                        ld a, 0                         ; Send 256 pixel bytes (16*16)
                        ld d, 0                         ; Counter
                        ld bc, $5B
WriteSpritePatternLoop: ld e, (hl)
                        inc hl
                        out (c), e
                        dec d
                        jr nz WriteSpritePatternLoop
                        ret

NextSprite              macro(ID, u16X, u8Y, PaletteOffset, bMirrorX, bMirrorY, bRotate, bVisible, Pattern)
                        ; Port $303B, if written, defines the sprite slot to be configured by ports $57 and $5B,
                        ; and also initializes the address of the palette.
                        ; Port $57 is write-only and is used to send the attributes of the selected sprite slot,
                        ; being the address is auto-incremented each writing and after sending the 4 bytes of
                        ; attributes the address points to the next sprite. The description of each byte follows below:
                        ;   1st: X position (bits 7-0).
                        ;   2nd: Y position (0-255).
                        ;   3rd: bits 7-4 is palette offset, bit 3 is X mirror, bit 2 is Y mirror,
                        ;        bit 1 is rotate flag and bit 0 is X MSB.
                        ;   4th: bit 7 is visible flag, bit 6 is reserved, bits 5-0 is Name (pattern index, 0-63).
                        B1 = low(u16X+32);
                        B2 = (u8Y+32) and %11111111
                        B3a = (PaletteOffset and %1111) shl 4           ; OOOOxxxx
                        B3b = (bMirrorX and %1) shl 3                   ; xxxxXxxx
                        B3c = (bMirrorY and %1) shl 2                   ; xxxxxYxx
                        B3d = (bRotate  and %1) shl 1                   ; xxxxxxRx
                        B3e = (((u16X+32) and %1 00000000) shr 8) and %1; xxxxxxxM
                        B3 = B3a+B3b+B3c+B3d+B3e                        ; OOOOXYRM
                        B4a = (bVisible and %1) shl 7                   ; Vxxxxxxx
                        B4b = Pattern and %111111                       ; xxPPPPPP
                        B4 = B4a+B4b                                    ; VxPPPPPP
                        ld a, ID and %111111
                        ld hl, B1+(B2*256)
                        ld de, B3+(B4*256)
                        call WriteNextSprite
mend

WriteNextSprite:
                        ld bc, $303B                    ; Set the sprite index (port $303B)
                        out (c), a                      ; (0 to 63)
                        ld bc, $57                      ; Send the sprite slot attributes (port $57)
                        out (c), l
                        out (c), h
                        out (c), e
                        out (c), d
                        ret

include "ParaBootStub.inc"                              ; ParaSys remote debugger slave stub
End:
org $BE00
Begin:
                        loop 257
                          db $BF
                        lend
org $BFBF
                        ei
                        reti

output_z80 "Level2Order.z80", $0000, Start              ; Create a 128K snapshot
output_sna "Level2Order.sna", $0000, Start              ; Create a 128K snapshot

output_para Begin, End-Begin, Start                     ; Send this code to ParaSys

