; MMUPaging.asm

zeusemulate             "128K", "ULA+"
zoLogicOperatorsHighPri = false
zoSupportStringEscapes  = false
Zeus_PC                 = Start
Stack                   equ Start
BootParaBase            equ $4000                       ; Locate ParaSys full stave in the screen to save memory

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

; Setup
                        PortOut($DFFD, %xxxxx 000)      ; Next Memory Bank Select - metabank 0
                        PageBankS(1, false)             ; Page 16k-bank 1 in upper 16K using $7FFD
                        ld a, %001
                        ld ($C000), a                   ; Put one dot in bank 1
                        PageBankS(3, false)             ; Page 16k-bank 2 in upper 16K using $7FFD
                        ld a, %101
                        ld ($C000), a                   ; Put two dots in bank 2

                        PortOut($DFFD, %xxxxx 001)      ; Next Memory Bank Select - metabank 1
                        PageBankS(1, false)             ; Page 16k-bank 1 in upper 16K using $7FFD
                        ld a, %011
                        ld ($C000), a                   ; Put one line in bank 1
                        PageBankS(3, false)             ; Page 16k-bank 2 in upper 16K using $7FFD
                        ld a, %11011
                        ld ($C000), a                   ; Put two lines in bank 2

                        PortOut($DFFD, %xxxxx 000)      ; Next Memory Bank Select - metabank 0
                        PageBankS(1, false)             ; Page 16k-bank 1 in upper 16K using $7FFD
; Test 7FFD
                        PortOut($DFFD, %xxxxx 000)      ; Next Memory Bank Select - metabank 0
                        PageBankN(1, false)             ; Page 16k-bank 1 in upper 16K using $7FFD
                        ld a, ($C000)                   ; Read value
                        ld ($4000), a                   ; and write to screen

                        PortOut($DFFD, %xxxxx 001)      ; Next Memory Bank Select - metabank 1
                        ld a, ($C000)                   ; Read value
                        ld ($4001), a                   ; and write to screen

                        PageBankS(1, false)             ; Page 16k-bank 1 in upper 16K using $7FFD
                        ld a, ($C000)                   ; Read value
                        ld ($4002), a                   ; and write to screen

; Test MMU
                        PortOut($DFFD, %xxxxx 000)      ; Next Memory Bank Select - metabank 0
                        PageBankN(1, false)             ; Page 16k-bank 1 in upper 16K using MMU
                        ld a, ($C000)                   ; Read value
                        ld ($4004), a                   ; and write to screen

                        PortOut($DFFD, %xxxxx 001)      ; Next Memory Bank Select - metabank 1
                        ld a, ($C000)                   ; Read value
                        ld ($4005), a                   ; and write to screen

                        PageBankN(1, false)             ; Page 16k-bank 1 in upper 16K using MMU
                        ld a, ($C000)                   ; Read value
                        ld ($4006), a                   ; and write to screen
Loop:
                        ei
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
                        nextreg $56, Bank*2
                        nextreg $57, (Bank*2)+1
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
                        ds 10
org zeuspage(3)
                        ds 10

output_z80 "DFFDPaging.z80", $0000, Start
output_para Start, End-Start, Start                     ; Send this code to ParaSys and execute at Start
output_para zeuspage(1), 10
output_para zeuspage(3), 10

