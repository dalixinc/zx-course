; step2-bat.asm - Chapter 5, step 2
; The bat: the twin of Chapter 2, step 2.
; A four-cell bat on row 21, moved with O and P, read straight from the
; keyboard with IN, so both keys are seen if both are held. The ball
; bounces off the bat; a miss puts it back at row 5, column 5. Space
; returns to BASIC.
;
; The loop runs once a frame (after halts HALTs). The ball moves every
; speed passes and the keys are read every bspeed passes, so the two
; keep their own beats.
;
; BASIC can set or read these bytes at the start of the code:
;   50000        halts   HALTs per pass of the loop; 0 means do not wait
;   50001        speed   passes per ball step, 1 to 255
;   50002        bspeed  passes per look at the keys, 1 to 255
;   50003-50004  steps   ball steps taken
;   50005        hits    times the bat hit the ball
;   50006        misses  times the ball got past the bat
;   50007        col     ball column, 0 to 31
;   50008        row     ball row, 0 to 20 (col and row are read as a pair)
;   50009        dc      column step, 1 or 255 (255 is -1)
;   50010        dr      row step, 1 or 255
;   50011        bat     the bat's left column, 0 to 28
;   50012        btime   passes until the next ball step
;   50013        ptime   passes until the next look at the keys
;
; Entry point:
;   RANDOMIZE USR 50014  start
;
; Registers:
;   B, C = the row and column of a cell, on the way into put and cell
;   DE   = the graphic being drawn (ball, blank or solid)
;   HL   = a screen address in put; the address of a variable elsewhere
;   A    = scratch
;
; Build:  tools/build.sh chapter-05-machine-code-games/step2-bat.bas chapter-05-machine-code-games/step2-bat.asm bat 10

        org 50000

halts:  db 1            ; 50000: HALTs per pass
speed:  db 3            ; 50001: passes per ball step
bspeed: db 2            ; 50002: passes per look at the keys
steps:  dw 0            ; 50003: ball steps taken
hits:   db 0            ; 50005: bat hits
misses: db 0            ; 50006: misses
col:    db 5            ; 50007: ball column (C of the pair)
row:    db 5            ; 50008: ball row (B of the pair)
dc:     db 1            ; 50009: column step
dr:     db 1            ; 50010: row step
bat:    db 14           ; 50011: bat left column
btime:  db 1            ; 50012: passes to the next ball step
ptime:  db 1            ; 50013: passes to the next key look

batrow: equ 21          ; the bat's row
batw:   equ 4           ; the bat's width in cells

; start: clear the counts, draw the bat and the ball, then loop.

start:  ld hl,0
        ld (steps),hl   ; no steps yet
        xor a           ; A = 0
        ld (hits),a
        ld (misses),a   ; no hits or misses yet

        ld a,(bat)      ; draw the whole bat, batw cells
        ld c,a          ; C = the bat's left column
        ld b,batrow     ; B = its row
        ld e,batw       ; E = cells still to draw
sbat:   push bc         ; keep the row and column: put changes B
        push de         ; keep the count
        ld de,solid
        call put        ; draw one cell of the bat
        pop de
        pop bc
        inc c           ; next column
        dec e
        jr nz,sbat

        ld bc,(col)     ; C = col, B = row
        ld de,ball
        call put        ; draw the ball

; The game loop: once a frame, unless halts says otherwise.

loop:   ld a,(halts)    ; A = HALTs to do
        and a           ; is it 0?
        jr z,go         ; yes: do not wait
        ld b,a
wait:   halt            ; wait for the next frame
        djnz wait

go:     ld hl,ptime
        dec (hl)        ; one pass fewer to the next key look
        jr nz,nokeys    ; not yet
        ld a,(bspeed)
        ld (hl),a       ; start counting again
        call keys       ; move the bat if O or P is held
nokeys: ld hl,btime
        dec (hl)        ; one pass fewer to the next ball step
        jr nz,noball    ; not yet
        ld a,(speed)
        ld (hl),a       ; start counting again
        call step       ; move the ball
noball: ld a,127        ; half-row Space, Sym Shift, M, N, B
        in a,(254)      ; read it: a 0 bit is a key held down
        bit 0,a         ; bit 0 is Space
        jr nz,loop      ; 1: Space is up, round again
        ret             ; 0: Space is down, back to BASIC

; keys: read O and P together, and move the bat one cell if exactly
; one of them is held. Changes A, B, C, DE, HL.

keys:   ld a,223        ; half-row P, O, I, U, Y
        in a,(254)      ; bit 0 is P, bit 1 is O; 0 means held
        cpl             ; turn the bits over: now 1 means held
        and 3           ; keep only P and O
        cp 1            ; only P?
        jr z,right
        cp 2            ; only O?
        ret nz          ; neither, or both: the bat stays put

left:   ld a,(bat)
        and a           ; already at column 0?
        ret z           ; yes: it cannot go further
        add a,batw-1    ; A = the bat's right-hand cell
        ld c,a
        ld b,batrow
        ld de,blank
        call put        ; rub out the right-hand cell
        ld hl,bat
        dec (hl)        ; the bat is one column further left
        ld c,(hl)       ; C = its new left-hand cell
        ld b,batrow
        ld de,solid
        jp put          ; draw it, and put returns for us

right:  ld a,(bat)
        cp 32-batw      ; already at the right edge?
        ret z           ; yes
        ld c,a          ; C = the bat's left-hand cell
        ld b,batrow
        ld de,blank
        call put        ; rub it out
        ld hl,bat
        inc (hl)        ; one column further right
        ld a,(hl)
        add a,batw-1    ; A = the new right-hand cell
        ld c,a
        ld b,batrow
        ld de,solid
        jp put          ; draw it

; step: rub the ball out, move it, bounce it off the edges and the bat,
; and draw it again. Changes A, B, C, DE, HL.

step:   ld bc,(col)     ; C = col, B = row
        ld de,blank
        call put        ; rub the ball out

        ld hl,dr
        ld a,(row)
        add a,(hl)      ; A = row + dr
        cp batrow       ; 0 to 20 is open space
        jr c,rowok      ; carry: it is
        cp batrow       ; the bat's row?
        jr nz,flipr     ; no, so 255: off the top, bounce

        ld a,(col)      ; the bat's row: is the bat under the ball?
        ld hl,bat
        sub (hl)        ; A = col - bat
        cp batw         ; 0 to 3 means over the bat
        jr nc,miss      ; no: a miss
        ld hl,hits
        inc (hl)        ; one more hit

flipr:  ld hl,dr
        ld a,(hl)
        neg
        ld (hl),a       ; dr = -dr: bounce
        ld a,(row)
        add a,(hl)      ; A = row + the new dr
rowok:  ld (row),a      ; take the step

        ld hl,dc        ; the column, as in step 1
        ld a,(col)
        add a,(hl)      ; A = col + dc
        cp 32
        jr c,colok
        ld a,(hl)
        neg
        ld (hl),a       ; dc = -dc
        ld a,(col)
        add a,(hl)
colok:  ld (col),a

draw:   ld bc,(col)
        ld de,ball
        call put        ; draw the ball in its new cell
        ld hl,(steps)
        inc hl
        ld (steps),hl   ; one more step
        ret

miss:   ld hl,misses
        inc (hl)        ; one more miss
        ld hl,5*256+5
        ld (col),hl     ; col = 5, row = 5
        ld hl,1*256+1
        ld (dc),hl      ; dc = 1, dr = 1: down and to the right
        jr draw

; put: copy the 8 bytes at DE into the cell at row B, column C.
; Changes A, B, DE and HL.

put:    call cell       ; HL = the top byte of the cell
        ld b,8          ; 8 pixel lines in a cell
pline:  ld a,(de)       ; A = one line of the graphic
        ld (hl),a       ; onto the screen
        inc de
        inc h           ; next pixel line down the cell
        djnz pline
        ret

; cell: HL = the screen address of the top line of the cell at row B,
; column C: 010TT000 RRRCCCCC. Changes A.

cell:   ld a,b          ; A = 000TTRRR
        and 24          ; A = 000TT000
        or 64           ; A = 010TT000
        ld h,a
        ld a,b
        and 7           ; A = 00000RRR
        rrca
        rrca
        rrca            ; A = RRR00000
        or c            ; A = RRRCCCCC
        ld l,a
        ret

; The graphics.

ball:   db 60,126,255,255,255,255,126,60
blank:  db 0,0,0,0,0,0,0,0
solid:  db 255,255,255,255,255,255,255,255 ; one cell of the bat

        end
