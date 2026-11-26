; step11-examples.asm - Chapter 5, step 11
; The hit, on the alive table alone: kill whatever invader is on a
; screen cell, and count the invaders left. invat, aliveat and count
; are copied from step11-hits.asm; kill is hit's first instruction.
;
; BASIC POKEs the inputs first:
;   50000  bx    the column of the block's left-hand invader
;   50001  by    the row of its top row
;   50002  row   a screen row
;   50003  col   a screen column
;   50004  irow  set by invat
;   50005  icol  set by invat
;   50006  nleft set by count
;   50500  alive the table, 32 bytes
;
; Example 1 at 50100: BC = count's answer, the invaders alive
; Example 2 at 50200: BC = 1 if there was a living invader on row, col,
;                     now killed, or 0 if there was none
;
; Build:  tools/build.sh chapter-05-machine-code-games/step11-examples.bas chapter-05-machine-code-games/step11-examples.asm examples 20

        org 50000

bx:     db 8            ; 50000
by:     db 1            ; 50001
row:    db 0            ; 50002
col:    db 0            ; 50003
irow:   db 0            ; 50004
icol:   db 0            ; 50005
nleft:  db 0            ; 50006

; Example 1: count the 1s in the table.

        org 50100
        call count      ; nleft = the invaders alive
        ld a,(nleft)
        ld c,a
        ld b,0          ; BC = nleft, for USR
        ret

; Example 2: a shot arrives on row, col. Is a living invader there?
; If so, kill it: one 0 in the table is the whole of the kill.

        org 50200
        ld a,(row)
        ld b,a
        ld a,(col)
        ld c,a          ; B, C = the cell
        call invat      ; A = its alive byte, HL = its address
        ld bc,0
        and a
        ret z           ; no living invader: BC = 0
        ld (hl),0       ; dead
        inc c           ; BC = 1
        ret

; The routines, from step11-hits.asm.

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

count:  ld hl,alive
        ld b,32         ; 32 invaders
        xor a
cnt1:   add a,(hl)      ; add its byte, 0 or 1
        inc hl
        djnz cnt1
        ld (nleft),a
        ret

        org 50500
alive:  db 1,1,1,1,1,1,1,1 ; 50500
        db 1,1,1,1,1,1,1,1
        db 1,1,1,1,1,1,1,1
        db 1,1,1,1,1,1,1,1

        end
