; step1-examples.asm - Chapter 5, step 1
; Six small routines, one for each new instruction or idea in the
; lesson. Example n starts at 50000+100*n. Each hands its answer back
; in BC, so PRINT USR shows it. The driver is step1-examples.bas.
;
; BASIC POKEs the inputs first:
;   50000  value  the byte to work on
;   50001  step   the step to add, 1 or 255 (255 is -1)
;   50002  row    a row, 0 to 23, for example 6
;   50003  col    a column, 0 to 31, for example 6
;
; Build:  tools/build.sh chapter-05-machine-code-games/step1-examples.bas chapter-05-machine-code-games/step1-examples.asm examples 10

        org 50000

value:  db 0            ; 50000
step:   db 1            ; 50001
row:    db 0            ; 50002
col:    db 0            ; 50003

; Example 1, NEG: BC = -value, as a byte.

        org 50100
        ld a,(value)
        neg             ; A = 0 - A
        ld c,a
        ld b,0
        ret

; Example 2, ADD A,(HL): BC = value + step, as a byte.

        org 50200
        ld hl,step      ; HL = the address of step
        ld a,(value)
        add a,(hl)      ; A = value + the byte at HL
        ld c,a
        ld b,0
        ret

; Example 3, one CP for both edges: BC = 1 if value is 0 to 21,
; 0 if it is 22 or more (255, which is -1, counts as more).

        org 50300
        ld bc,0         ; BC = 0: off the screen, unless...
        ld a,(value)
        cp 22           ; carry if A < 22
        ret nc          ; no carry: off the screen
        inc c           ; BC = 1: on the screen
        ret

; Example 4, BIT 5,(HL): BC = 1 if bit 5 of value is set, 0 if not.

        org 50400
        ld bc,0
        ld hl,value
        bit 5,(hl)      ; Z is set if the bit is 0
        ret z
        inc c
        ret

; Example 5, RES 5,(HL): clear bit 5 of value, and hand back the new
; value.

        org 50500
        ld hl,value
        res 5,(hl)      ; bit 5 of the byte at HL = 0
        ld c,(hl)
        ld b,0
        ret

; Example 6, the cell address: BC = the screen address of the top
; line of the cell at (row, col). The same code as step1-ball.asm.

        org 50600
        ld a,(row)      ; A = 000TTRRR
        and 24          ; A = 000TT000
        or 64           ; A = 010TT000
        ld h,a
        ld a,(row)
        and 7           ; A = 00000RRR
        rrca
        rrca
        rrca            ; A = RRR00000
        ld b,a
        ld a,(col)
        or b            ; A = RRRCCCCC
        ld l,a
        ld b,h
        ld c,l          ; BC = HL, for USR
        ret

        end
