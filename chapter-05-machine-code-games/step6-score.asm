; step6-score.asm - Chapter 5, step 6
; Score, lives and an ending: the twin of Chapter 2, step 7.
; Step 5's game, with a status line on row 0 (SCORE on the left, LIVES on
; the right), 10 points for a brick, three lives, a miss that costs one,
; and two endings: no lives left, or no bricks left. The code returns to
; BASIC when either happens (or when Space is held), and BASIC says
; which, and plays the tune. Row 0 is a ceiling now, so the wall is
; moved down to rows 3 to 5, and the ball starts on row 6, as in Chapter
; 2. The text and the numbers are printed with the ROM's RST 16, as in
; Chapter 3.
;
; BASIC can set or read these bytes at the start of the code:
;   50000        halts   HALTs per pass of the loop; 0 means do not wait
;   50001        speed   passes per ball step, 1 to 255
;   50002        bspeed  passes per look at the keys, 1 to 255
;   50003-50004  steps   ball steps taken
;   50005        hits    times the bat hit the ball
;   50006        misses  times the ball got past the bat
;   50007        kills   bricks the ball has rubbed out
;   50008        col     ball column, 0 to 31
;   50009        row     ball row, 0 to 20 (col and row are read as a pair)
;   50010        dc      column step, 1 or 255 (255 is -1)
;   50011        dr      row step, 1 or 255
;   50012        bat     the bat's left column, 0 to 28
;   50013        btime   passes until the next ball step
;   50014        ptime   passes until the next look at the keys
;   50015        seed    the random number generator's state, 1 to 255;
;                        0 means pick one from the R register at start
;   50016        quiet   0 for sound, anything else for none
;   50017-50018  score   10 for each brick
;   50019        lives   lives left
;   50020        bleft   bricks left on the wall
;   50021        state   0 playing (or stopped with Space), 1 game over,
;                        2 all the bricks gone
;
; Entry point:
;   RANDOMIZE USR 50022  start
;
; Registers:
;   B, C = the row and column of a cell, on the way into put, cell
;          and attr; the cell the ball is about to move into, in step
;   DE   = the graphic being drawn (ball, blank or solid)
;   E    = where on the bat the ball landed, 0 to 3, in step
;   HL   = a screen or attribute address; the address of a variable
;   A    = scratch
;
; Build:  tools/build.sh chapter-05-machine-code-games/step6-score.bas chapter-05-machine-code-games/step6-score.asm score 10

        org 50000

halts:  db 1            ; 50000: HALTs per pass
speed:  db 3            ; 50001: passes per ball step
bspeed: db 2            ; 50002: passes per look at the keys
steps:  dw 0            ; 50003: ball steps taken
hits:   db 0            ; 50005: bat hits
misses: db 0            ; 50006: misses
kills:  db 0            ; 50007: bricks rubbed out
col:    db 5            ; 50008: ball column (C of the pair)
row:    db 6            ; 50009: ball row (B of the pair)
dc:     db 1            ; 50010: column step
dr:     db 1            ; 50011: row step
bat:    db 14           ; 50012: bat left column
btime:  db 1            ; 50013: passes to the next ball step
ptime:  db 1            ; 50014: passes to the next key look
seed:   db 0            ; 50015: the random number state
quiet:  db 0            ; 50016: 0 for sound, anything else for none
score:  dw 0            ; 50017: the score
lives:  db 3            ; 50019: lives left
bleft:  db 96           ; 50020: bricks left
state:  db 0            ; 50021: 0 playing, 1 game over, 2 won

batrow: equ 21          ; the bat's row
batw:   equ 4           ; the bat's width in cells
bordcr: equ 23624       ; system variable: border colour * 8, and more
nbat:   equ 0           ; the sounds: their numbers in the table sounds
nwall:  equ 1
nbrick: equ 2
nmiss:  equ 3
wall:   equ 22528+3*32  ; the attribute of row 3, column 0
nbricks: equ 96         ; bricks in a new wall: 3 rows of 32
nlives: equ 3           ; lives in a new game
points: equ 10          ; the score for a brick
chanopen: equ 5633      ; ROM: open the channel for the stream in A

; start: clear the counts, set the score, the lives and the wall, draw
; the wall, the bat, the ball and the status line, then loop.

start:  ld hl,0
        ld (steps),hl   ; no steps yet
        xor a           ; A = 0
        ld (hits),a
        ld (misses),a   ; no hits or misses yet
        ld (kills),a    ; no bricks rubbed out yet
        ld (state),a    ; playing
        ld h,a
        ld l,a          ; HL = 0
        ld (score),hl   ; no score yet
        ld a,nlives
        ld (lives),a
        ld a,nbricks
        ld (bleft),a    ; a whole wall

        ld a,(seed)     ; has BASIC given us a seed?
        and a
        jr nz,seeded    ; yes
        ld a,r          ; no: use the R register
        or 1            ; and make sure it is not 0
        ld (seed),a
seeded:

        ld hl,wall      ; HL = the attribute of row 3, column 0
        ld a,2*8+7      ; red paper, white ink, as PAPER 2 gave in BASIC
        ld c,3          ; C = rows still to fill
wrow:   ld b,32         ; B = cells still to fill in this row
wcell:  ld (hl),a       ; one brick
        inc hl          ; the next attribute
        djnz wcell
        add a,16        ; the next paper colour: +2 is +16 in the byte
        dec c
        jr nz,wrow

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

        ld a,2          ; the upper screen,
        call chanopen   ; the stream RST 16 is to print to
        call status     ; SCORE and LIVES on row 0

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
noball: ld a,(state)    ; is the game over, or won?
        and a
        ret nz          ; yes: back to BASIC, and it will say which
        ld a,127        ; half-row Space, Sym Shift, M, N, B
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

; step: rub the ball out, bounce it off the edges, the bat and any
; brick in its way, move it, and draw it again. Changes A, B, C, DE, HL.

step:   ld bc,(col)     ; C = col, B = row
        ld de,blank
        call put        ; rub the ball out

        ld hl,dr
        ld a,(row)
        add a,(hl)      ; A = row + dr
        jr z,top        ; 0 is the status line: a ceiling
        cp batrow       ; 1 to 20 is open space
        jp c,cols       ; carry: it is, look at the column

        ld a,(col)      ; the bat's row: is the bat under the ball?
        ld hl,bat
        sub (hl)        ; A = col - bat
        cp batw         ; 0 to 3 means over the bat
        jp nc,miss      ; no: a miss
        ld hl,hits
        inc (hl)        ; one more hit
        ld e,a          ; E = where on the bat, 0 to 3
        ld a,nbat
        call sound      ; the bat's note (sound keeps every register)
        ld a,e
        and a           ; the left-hand cell?
        jr nz,notl
        ld a,255
        ld (dc),a       ; yes: off to the left
        jr flipr        ; the ends of the bat steer, with no nudge
notl:   ld a,e
        cp batw-1       ; the right-hand cell?
        jr nz,mid
        ld a,1
        ld (dc),a       ; yes: off to the right
        jr flipr
mid:    call turn       ; a middle cell: bounce,
        call nudge      ; and maybe change the sideways step
        jr cols

top:    ld a,nwall
        call sound      ; the top edge is a wall
        call turn       ; dr = -dr: bounce,
        call nudge      ; and maybe change the sideways step (step 6b:
        jr cols         ; without it, the wall cannot always be cleared)

flipr:  call turn       ; dr = -dr: bounce

cols:   ld hl,dc        ; the column edges, as in step 1
        ld a,(col)
        add a,(hl)      ; A = col + dc
        cp 32
        jr c,ahead      ; 0 to 31: on the screen
        ld a,(hl)
        neg
        ld (hl),a       ; dc = -dc
        ld a,nwall
        call sound      ; a side wall

ahead:  ld a,(row)      ; the cell the ball will move into
        ld hl,dr
        add a,(hl)
        ld b,a          ; B = row + dr
        ld a,(col)
        ld hl,dc
        add a,(hl)
        ld c,a          ; C = col + dc
        call attr       ; HL = the attribute of that cell
        ld a,(hl)
        and 56          ; keep the paper bits, 00111000
        jr z,go2        ; black paper: no brick, so move

        ld (hl),7       ; a brick: black paper, white ink, and it is gone
        ld hl,kills
        inc (hl)        ; one more brick
        ld a,nbrick
        call sound
        call scored     ; 10 points, one brick fewer, the status line
        call turn       ; dr = -dr: bounce off the brick
        call nudge      ; and maybe change the sideways step
        jr cols         ; and look again, as BASIC's GO TO 210 did

go2:    ld (col),bc     ; take the step: col = C, row = B

draw:   ld bc,(col)
        ld de,ball
        call put        ; draw the ball in its new cell
        ld hl,(steps)
        inc hl
        ld (steps),hl   ; one more step
        ret

miss:   ld hl,misses
        inc (hl)        ; one more miss
        ld a,nmiss
        call sound
        call lost       ; one life fewer, the status line
        ld hl,6*256+5
        ld (col),hl     ; col = 5, row = 6
        ld hl,1*256+1
        ld (dc),hl      ; dc = 1, dr = 1: down and to the right
        jr draw

; scored: add points to the score, take one off the bricks left, and
; set state to 2 if there are none. Then show the status line.
; Changes A, DE and HL; status keeps the rest.

scored: ld hl,(score)
        ld de,points
        add hl,de
        ld (score),hl   ; score = score + 10
        ld hl,bleft
        dec (hl)        ; one brick fewer
        jr nz,show      ; some left
        ld a,2
        ld (state),a    ; none: the wall is cleared
show:   jp status

; lost: take one off the lives, and set state to 1 if there are none.
; Then show the status line. Changes A and HL.

lost:   ld hl,lives
        dec (hl)        ; one life fewer
        jr nz,show2     ; some left
        ld a,1
        ld (state),a    ; none: game over
show2:  jp status

; status: print SCORE and LIVES on row 0. RST 16 and the ROM change
; every register, so all of them are saved and given back.

status: push af
        push bc
        push de
        push hl
        ld hl,stext1    ; AT 0,1; "SCORE "
        call pstr
        ld hl,(score)
        call pnum       ; the score, with no leading zeros
        ld hl,stext2    ; AT 0,22; "LIVES "
        call pstr
        ld a,(lives)
        add a,'0'       ; a digit's character code
        rst 16          ; print it
        pop hl
        pop de
        pop bc
        pop af
        ret

; pstr: print the string at HL, which ends with 255. A string can hold
; control codes: 22,row,column is AT. Changes A and HL.

pstr:   ld a,(hl)       ; the next byte of the string
        inc hl
        cp 255          ; the end marker?
        ret z           ; yes: done
        rst 16          ; no: print it
        jr pstr

; pnum: print HL in decimal, with no leading zeros, as in Chapter 3,
; step 6. BC and DE are kept. Changes A and HL.

pnum:   push bc
        push de
        ld b,0          ; B = 0: no digit printed yet
        ld de,10000
        call digit      ; the ten thousands
        ld de,1000
        call digit      ; the thousands
        ld de,100
        call digit      ; the hundreds
        ld de,10
        call digit      ; the tens
        ld a,l          ; what is left is 0 to 9, the units
        add a,'0'
        rst 16          ; always print the units, even 0
        pop de
        pop bc
        ret

; digit: print how many times DE goes into HL, and leave the rest in
; HL. B is 0 until a digit has been printed, so that leading zeros are
; not.

digit:  ld a,'0'-1      ; one less than the code for "0"
dloop2: inc a           ; one more DE goes in
        and a           ; clear the carry flag
        sbc hl,de       ; HL = HL - DE; carry if it went below 0
        jr nc,dloop2    ; no carry: try again
        add hl,de       ; one too many: put it back
        cp '0'          ; is the digit 0?
        jr nz,dshow     ; no: print it
        inc b
        dec b           ; Z is set if B is 0
        ret z           ; a leading zero: print nothing
dshow:  ld b,1          ; from now on, print every digit
        rst 16
        ret

stext1: db 22,0,1,"SCORE ",255
stext2: db 22,0,22,"LIVES ",255

; turn: dr = -dr, the bounce. Changes A and HL.

turn:   ld hl,dr
        ld a,(hl)
        neg
        ld (hl),a
        ret

; nudge: Chapter 2's lines 430 to 450. If the ball is going straight up
; or down (dc = 0), send it off to the left or the right, 50/50. If not,
; with a chance of 51 in 256, about one in five, make it go straight.
; Changes A, B and HL.

nudge:  ld a,(dc)
        and a           ; going straight?
        jr z,sides      ; yes
        call rnd        ; A = a random byte
        cp 51           ; carry if A < 51: about 1 in 5
        ret nc          ; no: leave dc alone
        xor a
        ld (dc),a       ; dc = 0: straight for a while
        ret
sides:  call rnd
        and 1           ; A = 0 or 1
        add a,a         ; A = 0 or 2
        dec a           ; A = 255 (-1) or 1
        ld (dc),a
        ret

; rnd: the next random byte, in A and in seed. An 8-bit LFSR, run for
; eight steps so that the byte it hands back has no bits in common with
; the last one. Each step shifts the byte right, and if a 1 fell off
; the end, XORs in the taps, 184. Over 255 calls it gives every value
; from 1 to 255 once, and then repeats. Changes A and B.

rnd:    ld a,(seed)
        ld b,8          ; eight shifts
rnd1:   srl a           ; bit 0 falls into the carry
        jr nc,rnd2      ; it was 0: nothing more to do
        xor 184         ; it was 1: XOR in the taps, 10111000
rnd2:   djnz rnd1
        ld (seed),a
        ret

;
; sound: play note number A, 0 to 3, for about a hundredth of a second,
; unless quiet is not 0. Keeps every register except A and the flags.
; Each note in the table is a delay count (2 bytes, low first), which
; sets the pitch, and a number of whole cycles, which sets the length.

sound:  push bc
        push de
        push hl
        ld c,a          ; keep the note number
        ld a,(quiet)
        and a           ; is the sound switched off?
        jr nz,sdone     ; yes: nothing to do
        ld a,c
        add a,a         ; A = 2 * note
        add a,c         ; A = 3 * note, the size of each table entry
        ld e,a
        ld d,0
        ld hl,sounds
        add hl,de       ; HL = this note's entry
        ld e,(hl)
        inc hl
        ld d,(hl)       ; DE = the delay count
        inc hl
        ld b,(hl)       ; B = the number of cycles

        ld a,(bordcr)   ; the border colour is in bits 3 to 5
        rrca
        rrca
        rrca            ; now in bits 0 to 2
        and 7
        ld c,a          ; C = the border colour, speaker off

cycle:  ld a,c
        or 16           ; bit 4 on: the speaker cone goes out
        out (254),a
        call delay
        ld a,c          ; bit 4 off: it comes back
        out (254),a
        call delay
        djnz cycle      ; B-1; not zero: another cycle
sdone:  pop hl
        pop de
        pop bc
        ret

; delay: count DE down to 0. Changes A and HL.

delay:  ld h,d
        ld l,e
dloop:  dec hl
        ld a,h
        or l
        jr nz,dloop
        ret

; The notes, as in Chapter 2: BEEP T,P with P = 0, 24, 12, -12. Each
; is the delay and the number of cycles. The delay n gives a note of
; 3500000 / (52 * n + 110) hertz.

sounds: dw 255
        db 3            ; 0 bat, about 262 Hz, middle C
        dw 62
        db 10           ; 1 wall, about 1050 Hz
        dw 126
        db 5            ; 2 brick, about 525 Hz
        dw 512
        db 1            ; 3 miss, about 131 Hz

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

; attr: HL = the attribute address of the cell at row B, column C:
; 010110TT RRRCCCCC, which is 22528 + 32*row + column. Changes A.

attr:   ld a,b          ; A = 000TTRRR
        rrca
        rrca
        rrca            ; A = RRR000TT
        and 3           ; A = 000000TT, the third
        or 88           ; A = 010110TT
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
