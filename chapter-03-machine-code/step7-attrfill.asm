; step7-attrfill.asm - Chapter 3, step 7
; The attribute fill in machine code: the twin of step 2's attribute fill.
; Two routines that do the same job, a loop and LDIR, called from BASIC.
;
; BASIC passes its choices in through three parameter bytes at the start:
;   50000  colour  the attribute byte to fill with (step 2 used 14)
;   50001  times   how many fills to do, 1 to 255 (0 means 256)
;   50002  where   two bytes, the first address to fill, low byte first
;                  (22528, the attributes; 768 bytes from here are filled)
;
; Entry points:
;   RANDOMIZE USR 50004  fill   the loop version
;   RANDOMIZE USR 50029  fldir  the LDIR version
;
; Registers in fill:
;   HL = the address being filled
;   BC = bytes still to fill, 768 down to 0
;   D  = fills still to do
;   E  = the colour
;   A  = a scratch copy of B, for the zero test
;
; Registers in fldir:
;   HL = the address LDIR copies from (one cell behind DE)
;   DE = the address LDIR copies to
;   BC = bytes still to copy, 767 down to 0
;   A  = the colour, then the count of fills (kept on the stack)
;
; Build:  pasmo --tap --name attrcode step7-attrfill.asm step7-attrcode.tap
; It is loaded by the driver, step7-attrfill.bas, with LOAD ""CODE.

        org 50000

colour: db 14           ; 50000: the colour, POKEd by BASIC
times:  db 1            ; 50001: how many fills
where:  dw 22528        ; 50002-50003: where to start

; The loop version: step 4's loop, with the colour and the start from BASIC.

fill:   ld a,(times)    ; A = how many fills
        ld d,a          ; D = fills still to do
frep:   ld a,(colour)   ; A = the colour BASIC POKEd
        ld e,a          ; E = the colour, because the loop needs A
        ld hl,(where)   ; HL = first address to fill
        ld bc,768       ; BC = 768 bytes to fill
floop:  ld (hl),e       ; colour one cell
        inc hl          ; next address
        dec bc          ; one fewer to do
        ld a,b
        or c            ; Z is set only when BC = 0
        jr nz,floop     ; not zero: next cell
        dec d           ; one fewer fill to do
        jr nz,frep      ; not zero: fill again
        ret

; The LDIR version: colour the first cell, then copy it along 767 times.

fldir:  ld a,(times)    ; A = how many fills
lrep:   push af         ; keep the count on the stack
        ld a,(colour)   ; A = the colour BASIC POKEd
        ld hl,(where)   ; HL = first address
        ld (hl),a       ; colour the first cell by hand
        ld de,(where)
        inc de          ; DE = the next address, HL+1
        ld bc,767       ; BC = the other 767 cells
        ldir            ; copy (HL) to (DE), HL+1, DE+1, BC-1, until BC = 0
        pop af          ; A = the count again
        dec a           ; one fewer fill to do
        jr nz,lrep      ; not zero: fill again
        ret

        end
