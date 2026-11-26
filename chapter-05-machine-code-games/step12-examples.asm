; step12-examples.asm - Chapter 5, step 12
; The bomb's three decisions: a random column, the lowest living invader
; in a living column, and whether a shot and a bomb have met. rnd,
; colalive and aliveat are copied from step12-bombs.asm; examples 2 and
; 3 are the deciding parts of drop and ctest.
;
; BASIC POKEs the inputs first:
;   50000  seed  the random number state, 1 to 255
;   50001  icol  set by examples 1 and 2
;   50002  irow  set by example 2
;   50003  srow  the shot's row, 255 for none
;   50004  brow  the bomb's row, 255 for none
;   50005  scol  the shot's column
;   50006  bcol  the bomb's column
;   50600  alive the table, 32 bytes
;
; Example 1 at 50100: BC = the next random column, 0 to 7
; Example 2 at 50200: BC = icol + 256*irow of the invader a bomb drops
;                     from, or 65535 if none is alive
; Example 3 at 50300: BC = 1 if the shot and the bomb have met, else 0
;
; Build:  tools/build.sh chapter-05-machine-code-games/step12-examples.bas chapter-05-machine-code-games/step12-examples.asm examples 20

        org 50000

seed:   db 1            ; 50000
icol:   db 0            ; 50001
irow:   db 0            ; 50002
srow:   db 255          ; 50003
brow:   db 255          ; 50004
scol:   db 0            ; 50005
bcol:   db 0            ; 50006

; Example 1: rnd, and AND 7 to keep 0 to 7.

        org 50100
        call rnd        ; A = the next random byte
        and 7           ; A = 0 to 7
        ld (icol),a
        ld c,a
        ld b,0          ; BC = the column, for USR
        ret

; Example 2: drop's choice. A random column; if none of it is alive,
; the next, round to 0 after 7; then the lowest living invader in it.

        org 50200
        call rnd
        and 7
        ld (icol),a
        ld b,8          ; 8 columns to try at most
dcol:   push bc
        call colalive   ; is any invader in column icol alive?
        pop bc
        jr nz,dgot      ; yes
        ld a,(icol)
        inc a
        and 7           ; the next column, 7 going round to 0
        ld (icol),a
        djnz dcol
        ld bc,65535     ; none alive at all
        ret
dgot:   ld a,3
        ld (irow),a     ; from the bottom row up
dlow:   call aliveat
        and a
        jr nz,dfound    ; the lowest living invader of the column
        ld hl,irow
        dec (hl)
        jr dlow
dfound: ld a,(icol)
        ld c,a
        ld a,(irow)
        ld b,a          ; BC = icol + 256*irow
        ret

; Example 3: ctest's test. Met if both are in flight, in the same
; column, with the shot on the bomb's row or the row below it.

        org 50300
        ld bc,0         ; not met, until shown otherwise
        ld a,(brow)
        cp 255
        ret z           ; no bomb
        ld d,a
        ld a,(srow)
        cp 255
        ret z           ; no shot
        sub d           ; A = shot row - bomb row
        cp 2            ; 0 or 1? A shot above the bomb goes round
        ret nc          ; to 255 or so, and fails too
        ld a,(bcol)
        ld hl,scol
        cp (hl)         ; the same column?
        ret nz
        inc c           ; BC = 1: they have met
        ret

; The routines, from step12-bombs.asm.

        org 50400

rnd:    ld a,(seed)
        ld b,8          ; eight shifts
rnd1:   srl a           ; bit 0 falls into the carry
        jr nc,rnd2      ; it was 0: nothing more to do
        xor 184         ; it was 1: XOR in the taps, 10111000
rnd2:   djnz rnd1
        ld (seed),a
        ret

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

        org 50600
alive:  db 1,1,1,1,1,1,1,1 ; 50600
        db 1,1,1,1,1,1,1,1
        db 1,1,1,1,1,1,1,1
        db 1,1,1,1,1,1,1,1

        end
