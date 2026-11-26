; step10-examples.asm - Chapter 5, step 10
; The march's two lookups on the alive table: the living edges, and
; invat with a block whose left-hand column is off the screen. The
; routines are copied from step10-march.asm.
;
; BASIC POKEs the inputs first:
;   50000  bx    the column of the block's left-hand invader; 254 is -2
;   50001  by    the row of its top row
;   50002  row   a screen row
;   50003  col   a screen column
;   50004  irow  set by invat
;   50005  icol  set by invat and edges
;   50006  lm    set by edges: the left-hand living column, 0 to 7
;   50007  rm    set by edges: the right-hand one
;   50500  alive the table, 32 bytes
;
; Example 1 at 50100: BC = lm + 256*rm from edges, or 65535 if none
; Example 2 at 50200: BC = invat's answer for row, col
;
; Build:  tools/build.sh chapter-05-machine-code-games/step10-examples.bas chapter-05-machine-code-games/step10-examples.asm examples 20

        org 50000

bx:     db 8            ; 50000
by:     db 1            ; 50001
row:    db 0            ; 50002
col:    db 0            ; 50003
irow:   db 0            ; 50004
icol:   db 0            ; 50005
lm:     db 0            ; 50006
rm:     db 0            ; 50007

        org 50100
        call edges      ; lm, rm; carry if none
        ld bc,65535
        ret c           ; none alive
        ld a,(lm)
        ld c,a
        ld a,(rm)
        ld b,a          ; BC = lm + 256*rm
        ret

        org 50200
        ld a,(row)
        ld b,a
        ld a,(col)
        ld c,a
        call invat      ; A = the alive byte, or 0
        ld c,a
        ld b,0
        ret

; aliveat: A = the alive byte of invader icol in block row irow, and HL its
; address, alive + 8*irow + icol. Changes DE.

aliveat: ld a,(irow)
        add a,a
        add a,a
        add a,a         ; A = 8*irow
        ld hl,icol
        add a,(hl)      ; A = 8*irow + icol
        ld e,a
        ld d,0
        ld hl,alive
        add hl,de       ; HL = its byte in the table
        ld a,(hl)
        ret

; invat: is the cell at row B, column C an invader's place in the
; block? If it is, irow and icol are set to it, and A is its alive byte;
; if not, A = 0. Keeps B and C. Changes DE, HL.

invat:  ld a,b
        ld hl,by
        sub (hl)        ; A = row - by; above the block it goes round
        cp 7            ; past 0 to 255 or so, so one test does both
        jr nc,noinv     ; outside: block rows are 0, 2, 4 and 6
        bit 0,a
        jr nz,noinv     ; an odd row: between two block rows
        rrca            ; A = (row - by) / 2, since bit 0 is 0
        ld (irow),a
        ld a,c
        ld hl,bx
        sub (hl)        ; A = column - bx, round past 0 on the left,
        cp 15           ; which also works when bx is "negative"
        jr nc,noinv     ; outside: columns 0, 2, ... 14
        bit 0,a
        jr nz,noinv     ; an odd column: a gap
        rrca
        ld (icol),a
        jp aliveat      ; A = its alive byte
noinv:  xor a           ; not an invader's place
        ret

; edges: lm = the left-hand column, 0 to 7, with an invader alive in
; it, and rm the right-hand one. Carry set if there is none. Changes
; A, B, DE, HL.

edges:  xor a
        ld (icol),a     ; from the left
eleft:  call colalive
        jr nz,egotl     ; a living invader in this column
        ld hl,icol
        inc (hl)
        ld a,(hl)
        cp 8
        jr nz,eleft
        scf             ; none in any column
        ret
egotl:  ld a,(icol)
        ld (lm),a
        ld a,7
        ld (icol),a     ; and from the right
eright: call colalive
        jr nz,egotr
        ld hl,icol
        dec (hl)
        jr eright       ; it stops at lm at the latest
egotr:  ld a,(icol)
        ld (rm),a
        and a           ; clear the carry: found
        ret

; colalive: A = not 0, and the zero flag clear, if any invader in
; column icol is alive. Changes B, DE, HL.

colalive: ld a,(icol)
        ld e,a
        ld d,0
        ld hl,alive
        add hl,de       ; HL = the top invader of the column
        ld de,8         ; 8 bytes on in the table is the next row
        xor a
        ld b,4          ; 4 rows
calive: or (hl)         ; A = A OR this invader's byte
        add hl,de
        djnz calive
        and a           ; set the zero flag from A
        ret

        org 50500

alive:  db 1,1,1,1,1,1,1,1 ; 50500: the table, as in the game
        db 1,1,1,1,1,1,1,1
        db 1,1,1,1,1,1,1,1
        db 1,1,1,1,1,1,1,1

        end
