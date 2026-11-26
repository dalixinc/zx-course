; step1-ball.asm - Chapter 5, step 1
; A bouncing ball in machine code: the twin of Chapter 2, step 1.
; The ball moves one character cell at a time, diagonally, and bounces
; off the four edges of rows 0 to 21. It is drawn straight into the
; screen memory, eight bytes a cell, just after a HALT, so the beam
; never catches it half drawn. Any key returns to BASIC.
;
; BASIC can set or read these bytes at the start of the code:
;   50000        speed  HALTs per step, 1 to 255; 0 means do not wait
;   50001-50002  steps  how many steps the ball took (BASIC reads it)
;   50003        row    the ball's row, 0 to 21
;   50004        col    the ball's column, 0 to 31
;   50005        dr     row step, 1 or 255 (255 is -1)
;   50006        dc     column step, 1 or 255
;
; Entry point:
;   RANDOMIZE USR 50007  start
;
; Registers:
;   A  = the row or column being worked on, and scratch
;   B  = HALTs still to do in wait; bytes still to copy in put
;   DE = the graphic being drawn (ball or blank)
;   HL = a screen address in put; the address of dr, dc, steps or
;        FLAGS elsewhere
;
; Build:  tools/build.sh chapter-05-machine-code-games/step1-ball.bas chapter-05-machine-code-games/step1-ball.asm ball 10
; The code is loaded by the driver, step1-ball.bas, with LOAD ""CODE.

        org 50000

speed:  db 2            ; 50000: HALTs per step
steps:  dw 0            ; 50001: steps taken, counted here
row:    db 5            ; 50003: ball row
col:    db 5            ; 50004: ball column
dr:     db 1            ; 50005: row step, +1 or -1
dc:     db 1            ; 50006: column step, +1 or -1

flags:  equ 23611       ; system variable; bit 5 is set by a new key

; start: draw the ball, then go round the loop until a key is pressed.

start:  ld hl,0
        ld (steps),hl   ; no steps yet
        ld hl,flags
        res 5,(hl)      ; forget any key pressed before we started
        ld de,ball
        call put        ; draw the ball where it starts

loop:   ld a,(speed)    ; A = HALTs to do
        and a           ; is it 0?
        jr z,move       ; yes: do not wait
        ld b,a          ; B = HALTs still to do
wait:   halt            ; wait for the next frame
        djnz wait       ; B-1; not zero: wait again

move:   ld de,blank
        call put        ; rub the ball out

        ld hl,dr        ; HL = the address of dr
        ld a,(row)
        add a,(hl)      ; A = row + dr
        cp 22           ; 0 to 21 is on the screen
        jr c,rowok      ; carry: A < 22, so it is
        ld a,(hl)
        neg             ; A = -dr
        ld (hl),a       ; dr = -dr: bounce
        ld a,(row)
        add a,(hl)      ; A = row + the new dr
rowok:  ld (row),a      ; take the step

        ld hl,dc        ; the same for the column
        ld a,(col)
        add a,(hl)      ; A = col + dc
        cp 32           ; 0 to 31 is on the screen
        jr c,colok
        ld a,(hl)
        neg
        ld (hl),a       ; dc = -dc
        ld a,(col)
        add a,(hl)
colok:  ld (col),a

        ld de,ball
        call put        ; draw the ball in its new cell

        ld hl,(steps)
        inc hl
        ld (steps),hl   ; one more step

        ld hl,flags
        bit 5,(hl)      ; has a key been pressed?
        jr z,loop       ; no: round again
        ret             ; yes: back to BASIC

; put: copy the 8 bytes at DE into the cell at (row, col).
; Changes A, B, DE and HL.

put:    call cell       ; HL = the top byte of the cell
        ld b,8          ; 8 pixel lines in a cell
pline:  ld a,(de)       ; A = one line of the graphic
        ld (hl),a       ; onto the screen
        inc de          ; next line of the graphic
        inc h           ; next pixel line down the cell
        djnz pline
        ret

; cell: HL = the screen address of the top line of the cell at
; (row, col). The address is 010TT000 RRRCCCCC, where TT is the third
; of the screen, RRR the row inside the third, CCCCC the column.
; Changes A and B.

cell:   ld a,(row)      ; A = 000TTRRR
        and 24          ; A = 000TT000, the third
        or 64           ; A = 010TT000
        ld h,a          ; H is done
        ld a,(row)
        and 7           ; A = 00000RRR, the row in the third
        rrca
        rrca
        rrca            ; A = RRR00000, the row times 32
        ld b,a
        ld a,(col)      ; A = 000CCCCC
        or b            ; A = RRRCCCCC
        ld l,a          ; L is done
        ret

; The graphics: Chapter 2's ball, and a blank cell to rub it out.

ball:   db 60,126,255,255,255,255,126,60
blank:  db 0,0,0,0,0,0,0,0

        end
