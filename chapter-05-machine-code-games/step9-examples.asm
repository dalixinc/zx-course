; step9-examples.asm - Chapter 5, step 9
; The block's two lookups, on their own: where an invader's byte is in
; the alive table, and whether a cell of the screen is an invader's
; place. The routines are copied from step9-block.asm.
;
; BASIC POKEs the inputs first:
;   50000  bx    the column of the block's left-hand invader
;   50001  by    the row of its top row
;   50002  row   a screen row, for example 2
;   50003  col   a screen column, for example 2
;   50004  irow  a block row, 0 to 3 (example 1 sets it too)
;   50005  icol  an invader in that row, 0 to 7 (and this)
;   50300  alive the table, 32 bytes
;
; Example 1 at 50100: BC = invat's answer for row, col: the alive byte
;                     if it is an invader's place, 0 if not; it sets
;                     irow and icol
; Example 2 at 50200: BC = aliveat's address for irow, icol
;
; Build:  tools/build.sh chapter-05-machine-code-games/step9-examples.bas chapter-05-machine-code-games/step9-examples.asm examples 20

        org 50000

bx:     db 8            ; 50000
by:     db 1            ; 50001
row:    db 0            ; 50002
col:    db 0            ; 50003
irow:   db 0            ; 50004
icol:   db 0            ; 50005

        org 50100
        ld a,(row)
        ld b,a
        ld a,(col)
        ld c,a          ; B, C = the cell
        call invat      ; A = its alive byte, or 0
        ld c,a
        ld b,0
        ret

        org 50200
        call aliveat    ; HL = the byte's address
        ld b,h
        ld c,l          ; BC = HL
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
        sub (hl)        ; A = row - by
        jr c,noinv      ; above the block
        cp 7
        jr nc,noinv     ; below it: block rows are 0, 2, 4 and 6
        bit 0,a
        jr nz,noinv     ; an odd row: between two block rows
        rrca            ; A = (row - by) / 2, since bit 0 is 0
        ld (irow),a
        ld a,c
        ld hl,bx
        sub (hl)        ; A = column - bx
        jr c,noinv      ; left of the block
        cp 15
        jr nc,noinv     ; right of it: columns 0, 2, ... 14
        bit 0,a
        jr nz,noinv     ; an odd column: a gap
        rrca
        ld (icol),a
        jp aliveat      ; A = its alive byte
noinv:  xor a           ; not an invader's place
        ret

        org 50300

alive:  db 1,1,1,1,1,1,1,1 ; 50300: the table, as in the game
        db 1,1,1,1,1,1,1,1
        db 1,1,1,1,1,1,1,1
        db 1,1,1,1,1,1,1,1

        end
