; ULAScreenPaging.asm

zoLogicOperatorsHighPri = false
zoSupportStringEscapes  = false
Zeus_PC                 = Start
BootParaBase            equ $4010                       ; Locate ParaSys full slave in the screen to save memory
Stack                   equ $FFFF

optionsize              12
Mode                    optionlist 15, -15, "Paging Mode","128K R/5/2/0","+3   0/1/2/3","+3   4/5/6/7","+3   4/5/6/3","+3   4/7/6/3"
ModeR520                equ 0
Mode0123                equ 1
Mode4567                equ 2
Mode4563                equ 3
Mode4763                equ 4
SMC                     equ 0

if Mode = ModeR520
                        zeusemulate "128K"

                        org $4000
                        import_bin "main.scr"

                        dispto zeuspage(7)
                        import_bin "shadow.scr"
                        disp 0

                        org $8000
Start:
                        di
                        ld sp, Stack
                        ld a, $BE
                        ld i, a
                        im 2
                        ei
                        Border(0)
                        xor a
                        ld (Page), a                    ; SMC> Start off with page 0 at $C000
                        ld a, %xxxx 0 000
                        ld (Screen), a                  ; SMC> Start off with main screen
Loop:
                        ld a, (Page)
                        inc a
                        and %111
                        ld (Page), a                    ; <SMC

                        halt
                        Border(0)
                        ld bc, zeuskeyaddr("1")
                        in a, (c)
                        ld d, a
                        and zeuskeymask("1")
                        jp nz, Two
                        Border(2)
                        ld a, %xxxx 0 000
                        ld (Screen), a                  ; SMC> Switch to main screen
Two:
                        ld a, d
                        and zeuskeymask("2")
                        jp nz, Set
                        Border(4)
                        ld a, %xxxx 1 000
                        ld (Screen), a                  ; SMC> Switch to shadow screen
Set:
Screen equ $+1:         ld a, SMC                       ; <SMC Main or shadow screen
Page equ $+1:           or SMC                          ; <SMC Page 0..7
                        ld bc, $7FFD
                        out (c), a
                        jp Loop
org $BE00
Begin:
                        loop 257
                          db $BF
                        lend
org $BFBF
                        ei
                        reti

elif Mode = Mode0123

                        zeusemulate "3"

                        org $4000
                        import_bin "main.scr"

                        dispto zeuspage(7)
                        import_bin "shadow.scr"
                        disp 0

                        org $8000
Start:
                        di
                        ld sp, Stack
                        ld a, $BE
                        ld i, a
                        im 2
                        ld a, %xxxxx 00 1               ; Special paging 0/1/2/3
                        ld bc, $1FFD
                        out (c), a
                        ei
                        Border(0)
                        xor a
                        ld (Page), a                    ; SMC> Start off with page 0 at $C000
                        ld a, %xxxx 0 000
                        ld (Screen), a                  ; SMC> Start off with main screen
Loop:

                        halt
                        Border(0)
                        ld bc, zeuskeyaddr("1")
                        in a, (c)
                        ld d, a
                        and zeuskeymask("1")
                        jp nz, Two
                        Border(2)
                        ld a, %xxxx 0 000
                        ld (Screen), a                  ; SMC> Switch to main screen
Two:
                        ld a, d
                        and zeuskeymask("2")
                        jp nz, Set
                        Border(4)
                        ld a, %xxxx 1 000
                        ld (Screen), a                  ; SMC> Switch to shadow screen
Set:
Screen equ $+1:         ld a, SMC                       ; <SMC Main or shadow screen
Page equ $+1:           or SMC                          ; <SMC Page 0..7
                        ld bc, $7FFD
                        out (c), a
                        jp Loop
org $BE00
Begin:
                        loop 257
                          db $BF
                        lend
org $BFBF
                        ei
                        reti

elif Mode = Mode4567

                        zeusemulate "3"

                        org $4000
                        import_bin "main.scr"

                        dispto zeuspage(7)
                        import_bin "shadow.scr"
zeusprinthex $
                        dispto zeuspage(6)
zeusprinthex $
                        org $8000
zeusprinthex $
zeusprinthex zeuspage(6)
Start:
                        di
                        ld sp, Stack
                        ld a, $BE
                        ld i, a
                        im 2
                        ld a, %xxxxx 01 1               ; Special paging 4/5/6/7
                        ld bc, $1FFD
                        out (c), a
                        ei
                        Border(0)
                        xor a
                        ld (Page), a                    ; SMC> Start off with page 0 at $C000
                        ld a, %xxxx 0 000
                        ld (Screen), a                  ; SMC> Start off with main screen
Loop:

                        halt
                        Border(0)
                        ld bc, zeuskeyaddr("1")
                        in a, (c)
                        ld d, a
                        and zeuskeymask("1")
                        jp nz, Two
                        Border(2)
                        ld a, %xxxx 0 000
                        ld (Screen), a                  ; SMC> Switch to main screen
Two:
                        ld a, d
                        and zeuskeymask("2")
                        jp nz, Set
                        Border(4)
                        ld a, %xxxx 1 000
                        ld (Screen), a                  ; SMC> Switch to shadow screen
Set:
Screen equ $+1:         ld a, SMC                       ; <SMC Main or shadow screen
Page equ $+1:           or SMC                          ; <SMC Page 0..7
                        ld bc, $7FFD
                        out (c), a
                        jp Loop
org $BE00
Begin:
                        loop 257
                          db $BF
                        lend
org $BFBF
                        ei
                        reti

endif



Border                  macro(Colour)
                        if Colour=0
                          xor a
                        else
                          ld a, Colour
                        endif

                        out ($FE), a
mend

output_z80 "ULAScreenPaging.z80", $0000, Start          ; Create a 128K snapshot
output_sna "ULAScreenPaging.sna", $0000, Start          ; Create a 128K snapshot

//output_para Begin, End-Begin, Start                     ; Send this code to ParaSys

