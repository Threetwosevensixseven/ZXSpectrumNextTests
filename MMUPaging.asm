; MMUPaging.asm

zeusemulate             "128K", "ULA+"
zoLogicOperatorsHighPri = false
zoSupportStringEscapes  = false
Zeus_PC                 = Start
Stack                   equ Start
BootParaBase            equ $4000                       ; Locate ParaSys full stave in the screen to save memory
optionsize              5
Standard                optionbool 15, -15, "Use port $7FFD instead of MMU", false

                        org $6000
Start                   proc
::s:
                        di
                        ld sp, Stack
                        ld a, $BE
                        ld i, a
                        im 2
                        call Cls
                        call ClsAttr
                        call BootTestSetup              ; Setup ParaSys remote debugger

                        nextreg $14, $E3                ; Set global transparency to bright magenta
                        PortOut($123B, $00)             ; Hide layer 2 and disable write paging
                        nextreg $15, %0 00 001 1 0      ; Disable sprites, over border, set LSU

if enabled Standard
                        PageBankS(1, true)
                        ld a, ($C000)
                        ld ($4000), a

                        PageBankS(3, true)
                        ld a, ($C01E)
                        ld ($4002), a

                        PageBankS(4, true)
                        ld a, ($C000)
                        ld ($4004), a

                        PageBankS(6, true)
                        ld a, ($C000)
                        ld ($4006), a
else
                        PageBankS(1, true)
                        ld a, ($C000)
                        ld ($4000), a

                        PageBankN(3, true)
                        ld a, ($001E)
                        ld ($4002), a

                        PageBankS(3, true)
                        ld a, ($C01E)
                        ld ($4004), a

                        //PageBankN(3, true)
                        ld a, ($001E)
                        ld ($4006), a

                        PageBankN(4, true)
                        ld a, ($001E)
                        ld ($4008), a

endif

Loop:
                        halt
                        call BootTest                   ; Check for ParaSys commands every frame
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

PageBankS               macro(Bank, ReEnableInterrupts)
                        ld bc, 0x7ffd
                        di
                        ld a, (Bank & 7) | 16
                        out (c), a
                        if (ReEnableInterrupts)
                          ei
                        endif
mend

PageBankN               macro(Bank, ReEnableInterrupts)
                        ld bc, $243B
                        ld a, $50
                        ld e, Bank*2
                        out (c), a                      ; Slot 6 ($C000..$DFFF)
                        inc b
                        out (c), e                      ; 16-bank 0 is 8-banks 0+1; 16-bank 1 is 8-banks 2+3; etc
                        dec b
                        inc a
                        out (c), a                      ; Slot 7 ($E000..$FFFF)
                        inc b
                        inc e
                        out (c), e
                        if (ReEnableInterrupts)
                          ei
                        endif
mend

PortOut                 macro(Port, Value)
                        ld bc, Port
                        ld a, Value
                        out (c), a
mend

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

include "ParaBootStub.inc"                              ; ParaSys remote debugger slave stub

org $BE00
                        loop 257
                          db $BF
                        lend
org $BFBF
                        ei
                        reti
End:
org zeuspage(1)
                        db $FF
org zeuspage(3)+$1E
                        db $AA
org zeuspage(4)
                        db $CC
org zeuspage(4)+$1E
                        db $CC
org zeuspage(6)
                        db $49

output_z80 "MMUPaging.z80", $0000, Start
output_para Start, End-Start                            ; Send this code to ParaSys
output_para zeuspage(1), 1
output_para zeuspage(3), $20
output_para zeuspage(4), $20
output_para zeuspage(6), 1

