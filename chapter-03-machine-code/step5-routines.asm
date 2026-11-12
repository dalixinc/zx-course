; step5-routines.asm - Chapter 3, step 5
; Step 4's three routines, written for pasmo instead of by hand.
;
; Registers:
;   A  = border colour (border); a scratch copy of B (fill)
;   BC = the number handed back to BASIC (ret42, border);
;        bytes still to fill (fill)
;   HL = the attribute address being filled (fill)
;
; Build:  pasmo --tapbas --name routines step5-routines.asm step5-routines.tap
; Then in BASIC: PRINT USR 50000 gives 42, PRINT USR 50004 gives 2,
; RANDOMIZE USR 50012 fills the attributes yellow.

        org 50000

ret42:  ld bc,42        ; BC = 42, the answer
        ret             ; back to BASIC, which reads BC

border: ld a,2          ; A = 2, red
        out (254),a     ; the border turns red
        ld b,0          ; B = 0
        ld c,a          ; C = A, so BC = 2
        ret

fill:   ld hl,22528     ; HL = first attribute byte, $5800
        ld bc,768       ; BC = 768 bytes to fill
loop:   ld (hl),48      ; yellow paper, black ink
        inc hl          ; next address
        dec bc          ; one fewer to do
        ld a,b
        or c            ; Z is set only when BC = 0
        jr nz,loop      ; not zero: go round again
        ret

        end border      ; the loader calls this one: RANDOMIZE USR 50004
