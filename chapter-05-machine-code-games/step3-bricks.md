# Chapter 5, step 3 — The bricks

Chapter 2, step 3 put a wall of bricks across rows 2 to 4: red, green and yellow, each brick a space printed with a coloured `PAPER`. Before the ball moved, `ATTR` read the colour of the cell it was about to move into. If the paper was not black, that cell was a brick, so it was printed over with black paper, and the ball bounced. The same step made the two end cells of the bat steer the ball: the left-hand cell sent it off to the left, the right-hand cell to the right.

This step is its twin. The wall, the colours, the test and the steering are all the same. In machine code the attributes are just bytes in memory, from 22528 to 23295, so:

1. **The wall is 96 bytes.** Drawing it is three rows of 32 stores into the attributes, not 96 `PRINT`s.
2. **`ATTR` is a load.** The code works out the attribute address of the cell ahead and reads the byte there.
3. **Rubbing a brick out is a store.** Writing 7, black paper and white ink, into its attribute makes it vanish. There are no pixels to clear, because a brick never had any: it is a space with coloured paper.

Chapter 2's loop with no delay took **5.5 frames a step**, timed for this lesson. A pass of this step's loop, with a ball step, the brick test and the keys, takes **0.022 of a frame**.

Every program here was assembled with pasmo, cross-checked against z80asm, and run in a 48K emulator before it was shown.

## The new instructions and ideas

The small examples are in `step3-examples.asm`, with a driver, `step3-examples.bas`, that prints three coloured cells, then for five cells prints the attribute address worked out in machine code, the attribute byte read there, and what BASIC's `ATTR` gives for the same cell. `step3-examples.png` is its screen.

### The attribute address of a cell

The attributes are in screen order: row 0 from 22528 to 22559, row 1 from 22560, and so on, 32 bytes a row. So the address of a cell's attribute is simply

```
22528 + 32*row + column
```

In binary, with the row as `000TTRRR` again, that is:

```
010110TT RRRCCCCC
```

The low byte is the same as the cell's screen address in step 1, `RRRCCCCC`. Only the high byte is different: `01011000` is 88, and the third, `TT`, goes into its bottom two bits. 22528 is 88×256.

```
attr:   ld a,b          ; A = 000TTRRR
        rrca
        rrca
        rrca            ; A = RRR000TT
        and 3           ; A = 000000TT
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
```

The first three `rrca`s move `TT` from bits 3 and 4 down to bits 0 and 1. The `RRR` that came round to the top is thrown away by `and 3`. Chapter 3, step 8 worked out the same high byte from a screen address instead, in its "For info" aside.

Example 1, `USR 50100`, gave these, and each one is 22528 + 32×row + column:

| Row, column | Address |
|-------------|--------:|
| 0, 0 | 22528 |
| 2, 5 | 22597 |
| 16, 20 | 23060 |
| 21, 31 | 23231 |
| 5, 5 | 22693 |

### Reading an attribute: ATTR in one instruction

With the address in HL, `ld a,(hl)` is `ATTR`. Example 2 reads the byte and hands it back, and the driver prints `ATTR` beside it:

| Row, column | Printed with | Code | `ATTR` |
|-------------|--------------|-----:|-------:|
| 0, 0 | nothing | 7 | 7 |
| 2, 5 | `PAPER 2` | 23 | 23 |
| 16, 20 | `PAPER 4; INK 1` | 33 | 33 |
| 21, 31 | `PAPER 6; BRIGHT 1` | 113 | 113 |
| 5, 5 | nothing | 7 | 7 |

23 is 8×2 + 7: red paper, white ink. 113 is 64 + 8×6 + 1: bright, yellow paper, and ink 1, because the `INK 1` earlier in the same `PRINT` statement was still in force.

The bits of the byte are the ones from Chapter 1 and Chapter 3, step 3:

```
F B PPP III
7 6 543 210
```

Chapter 2 tested `INT(A/8)<>0`, which is true when the paper or the bright or flash bits are set. The bricks only ever differ in paper, so the code keeps the paper bits alone, with `and 56`, binary `00111000`:

```
        ld a,(hl)
        and 56          ; keep the paper bits, 00111000
        jr z,go2        ; black paper: no brick, so move
```

It costs 7 T-states for the load and 7 for the `and`. `ATTR(R+DR,X+DX)` in BASIC has to work out two sums in floating point, find the cell, and make a floating-point number of the answer.

### Writing an attribute: LD (HL),n

`ld (hl),n`, from Chapter 3, step 4, stores a number at the address in HL. With HL on a brick's attribute,

```
        ld (hl),7       ; a brick: black paper, white ink, and it is gone
```

does what `PRINT AT R+DR,X+DX; PAPER 0;" "` did in Chapter 2. The cell's pixels were never set, so only its colour has to change.

The wall is drawn in the same way, with `ld (hl),a` into 96 attributes in a row:

```
        ld hl,wall      ; HL = the attribute of row 2, column 0
        ld a,2*8+7      ; red paper, white ink, as PAPER 2 gave in BASIC
        ld c,3          ; C = rows still to fill
wrow:   ld b,32         ; B = cells still to fill in this row
wcell:  ld (hl),a       ; one brick
        inc hl          ; the next attribute
        djnz wcell
        add a,16        ; the next paper colour: +2 is +16 in the byte
        dec c
        jr nz,wrow
```

`wall` is `equ 22528+2*32`, the attribute of row 2, column 0. Rows 2, 3 and 4 follow one another in the attributes, so `inc hl` runs straight on from the end of one row to the start of the next. Chapter 2's paper colours were `2*(L-1)` for rows 2 to 4, so 2, 4 and 6. In the attribute byte the paper is multiplied by 8, so adding 2 to the paper is adding 16 to the byte: 23, 39 and 55.

### LD (nn),BC — store a pair

Step 2 loaded the ball's column and row together with `ld bc,(col)`. This step works out the cell ahead in C and B, and when the ball is free to move there, stores both at once:

```
go2:    ld (col),bc     ; take the step: col = C, row = B
```

| Instruction | What it does | Bytes (hex) | Bytes (decimal) | T-states |
|-------------|--------------|-------------|-----------------|----------|
| `LD (nn),BC` | C to nn, B to nn+1 | `ED 43` low high | 237, 67, low, high | 20 |
| `LD BC,(nn)` (Chapter 3) | C from nn, B from nn+1 | `ED 4B` low high | 237, 75, low, high | 20 |

There is a form for DE as well, and `ld (nn),hl` from Chapter 3, step 6, which is one byte shorter. Example 3 puts 2×256+7 in BC and stores it at 50002; the driver then read **7** at 50002 and **2** at 50003, C first, low byte first.

### Looking before moving

The ball now decides in this order, which is Chapter 2's lines 190 to 260:

1. The row. If the next row is off the top, turn `dr` round. If it is the bat's row and the bat is there, steer by where it landed and turn `dr` round. If the bat is not there, it is a miss.
2. The column. If the next column is off the side, turn `dc` round.
3. The cell ahead, at the row plus `dr` and the column plus `dc`. If it is a brick, rub it out, turn `dr` round, and go back to 2.
4. Move there.

Going back to 2 after a brick is BASIC's `GO TO 210`. It matters when the ball bounces off one brick into another, or into the side of the screen: each one is dealt with before the ball moves. It cannot go round for ever, because every time round rubs out a brick.

### Steering with the ends of the bat

Step 2 already had `col - bat` in A, 0 to 3, to see whether the ball was over the bat. That number also says where:

```
        ld e,a          ; E = where on the bat, 0 to 3
        and a           ; the left-hand cell?
        jr nz,notl
        ld a,255
        ld (dc),a       ; yes: off to the left
notl:   ld a,e
        cp batw-1       ; the right-hand cell?
        jr nz,flipr
        ld a,1
        ld (dc),a       ; yes: off to the right
```

0 is the left-hand cell, so `dc` becomes 255, -1. `batw-1`, 3, is the right-hand cell, so `dc` becomes 1. A landing on the middle two cells leaves `dc` alone. E keeps the number while A is used for the 255.

## The listing

The machine code, `step3-bricks.asm`. It is step 2's, with the wall, the `kills` count, the steering, the look ahead and `attr` added, and the parameter bytes after `misses` moved up one to make room for `kills`.

```
; step3-bricks.asm - Chapter 5, step 3
; The bricks: the twin of Chapter 2, step 3.
; Step 2's bat and ball, with three rows of bricks on rows 2 to 4, red,
; green and yellow. Before the ball moves, it looks at the attribute of
; the cell it is about to move into, as ATTR did in BASIC. If the paper
; is not black, that cell is a brick: it is rubbed out by making its
; paper black, and the ball bounces. The two end cells of the bat send
; the ball off to that side. Space returns to BASIC.
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
;   50007        kills   bricks the ball has rubbed out
;   50008        col     ball column, 0 to 31
;   50009        row     ball row, 0 to 20 (col and row are read as a pair)
;   50010        dc      column step, 1 or 255 (255 is -1)
;   50011        dr      row step, 1 or 255
;   50012        bat     the bat's left column, 0 to 28
;   50013        btime   passes until the next ball step
;   50014        ptime   passes until the next look at the keys
;
; Entry point:
;   RANDOMIZE USR 50015  start
;
; Registers:
;   B, C = the row and column of a cell, on the way into put, cell
;          and attr; the cell the ball is about to move into, in step
;   DE   = the graphic being drawn (ball, blank or solid)
;   E    = where on the bat the ball landed, 0 to 3, in step
;   HL   = a screen or attribute address; the address of a variable
;   A    = scratch
;
; Build:  tools/build.sh chapter-05-machine-code-games/step3-bricks.bas chapter-05-machine-code-games/step3-bricks.asm bricks 10

        org 50000

halts:  db 1            ; 50000: HALTs per pass
speed:  db 3            ; 50001: passes per ball step
bspeed: db 2            ; 50002: passes per look at the keys
steps:  dw 0            ; 50003: ball steps taken
hits:   db 0            ; 50005: bat hits
misses: db 0            ; 50006: misses
kills:  db 0            ; 50007: bricks rubbed out
col:    db 5            ; 50008: ball column (C of the pair)
row:    db 5            ; 50009: ball row (B of the pair)
dc:     db 1            ; 50010: column step
dr:     db 1            ; 50011: row step
bat:    db 14           ; 50012: bat left column
btime:  db 1            ; 50013: passes to the next ball step
ptime:  db 1            ; 50014: passes to the next key look

batrow: equ 21          ; the bat's row
batw:   equ 4           ; the bat's width in cells
wall:   equ 22528+2*32  ; the attribute of row 2, column 0

; start: clear the counts, draw the wall, the bat and the ball, then
; loop.

start:  ld hl,0
        ld (steps),hl   ; no steps yet
        xor a           ; A = 0
        ld (hits),a
        ld (misses),a   ; no hits or misses yet
        ld (kills),a    ; no bricks rubbed out yet

        ld hl,wall      ; HL = the attribute of row 2, column 0
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

; step: rub the ball out, bounce it off the edges, the bat and any
; brick in its way, move it, and draw it again. Changes A, B, C, DE, HL.

step:   ld bc,(col)     ; C = col, B = row
        ld de,blank
        call put        ; rub the ball out

        ld hl,dr
        ld a,(row)
        add a,(hl)      ; A = row + dr
        cp batrow       ; 0 to 20 is open space
        jr c,cols       ; carry: it is, look at the column
        cp batrow       ; the bat's row?
        jr nz,flipr     ; no, so 255: off the top, bounce

        ld a,(col)      ; the bat's row: is the bat under the ball?
        ld hl,bat
        sub (hl)        ; A = col - bat
        cp batw         ; 0 to 3 means over the bat
        jr nc,miss      ; no: a miss
        ld hl,hits
        inc (hl)        ; one more hit
        ld e,a          ; E = where on the bat, 0 to 3
        and a           ; the left-hand cell?
        jr nz,notl
        ld a,255
        ld (dc),a       ; yes: off to the left
notl:   ld a,e
        cp batw-1       ; the right-hand cell?
        jr nz,flipr
        ld a,1
        ld (dc),a       ; yes: off to the right

flipr:  ld hl,dr
        ld a,(hl)
        neg
        ld (hl),a       ; dr = -dr: bounce

cols:   ld hl,dc        ; the column edges, as in step 1
        ld a,(col)
        add a,(hl)      ; A = col + dc
        cp 32
        jr c,ahead      ; 0 to 31: on the screen
        ld a,(hl)
        neg
        ld (hl),a       ; dc = -dc

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
        ld hl,dr
        ld a,(hl)
        neg
        ld (hl),a       ; dr = -dr: bounce off the brick
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
```

It is 429 bytes, 50000 to 50428. pasmo's listing puts `start` at 50015, `loop` at 50081, `keys` at 50126, `step` at 50200, `cols` at 50266, `ahead` at 50281, `miss` at 50342, `put` at 50360, `cell` at 50372 and `attr` at 50387.

The BASIC driver, `step3-bricks.bas`, is step 2's, with the new entry point, 50015, and the bricks count, `PEEK 50007`, in line 180:

```
1 REM S=ball steps taken
2 REM H=FRAMES high byte
3 REM L=FRAMES low byte
4 REM F=frames the game ran for
10 CLEAR 49999
20 BORDER 0: PAPER 0: INK 7: CLS
30 PRINT "LOADING THE CODE"
40 LOAD ""CODE
50 CLS
60 POKE 50000,1: POKE 50001,3: POKE 50002,2
70 PRINT #0;"O LEFT, P RIGHT, SPACE STOPS"
80 POKE 23672,0: POKE 23673,0: POKE 23674,0
90 RANDOMIZE USR 50015
100 LET H=PEEK 23673: LET L=PEEK 23672
110 IF PEEK 23673<>H THEN GO TO 100
120 LET F=L+256*H
130 LET S=PEEK 50003+256*PEEK 50004
140 CLS
150 PRINT "BALL STEPS ";S
160 PRINT "FRAMES     ";F
170 IF S>0 THEN PRINT "FRAMES A STEP ";F/S
180 PRINT "HITS ";PEEK 50005;"  MISSES ";PEEK 50006;"  BRICKS ";PEEK 50007
190 IF INKEY$<>"" THEN GO TO 190
```

## Building and running

On Windows, from the course folder:

```
windows-tools\build.bat chapter-05-machine-code-games\step3-bricks.bas chapter-05-machine-code-games\step3-bricks.asm bricks 10
```

On Linux:

```
tools/build.sh chapter-05-machine-code-games/step3-bricks.bas chapter-05-machine-code-games/step3-bricks.asm bricks 10
```

The examples:

```
windows-tools\build.bat chapter-05-machine-code-games\step3-examples.bas chapter-05-machine-code-games\step3-examples.asm examples 10
```

```
tools/build.sh chapter-05-machine-code-games/step3-examples.bas chapter-05-machine-code-games/step3-examples.asm examples 10
```

When the tape has loaded, the wall appears at once, with the bat and the ball. O and P move the bat, and Space stops the game. BASIC then prints the ball steps, the frames, the frames a step, and the hits, misses and bricks.

## What it showed in Fuse

The tape was loaded in a 48K Fuse at normal speed.

- `step3-bricks.png` is the start: the red, green and yellow rows across the whole width, the bat in the middle of row 21, and the ball on its way down.
- With no key held, the ball missed the bat every time, as it did in step 2, and never reached the wall: one run counted 505 steps in 1515 frames, 31 misses, 0 hits and 0 bricks.
- The bricks were tested by starting the bat under the ball's first fall, in copies of the driver. With the bat at column 20, the ball landed on its left-hand cell and went off up and to the left, as Chapter 2's did. It knocked holes in the wall and went through them into rows 0 and 1 above the wall, and bounced about up there, taking bricks out from above. `step3-bricks-holes.png` is the wall after about seven seconds of that, and `step3-bricks-result.png` the result: 372 steps, 9 hits, 2 misses and 4 bricks.
- For the right-hand end, the ball was started at column 30 moving down and to the left, and the bat at column 12, so the ball landed on the bat's right-hand cell, column 15. It went off up and to the right, and took out the yellow brick at row 4, column 31, as its new path said it should.

The examples gave the table above: every address was 22528 + 32×row + column, and every attribute matched `ATTR`.

pasmo and z80asm gave the same 429 bytes for `step3-bricks.asm`, and the same 51 bytes of code for `step3-examples.asm`.

## The timing, against BASIC

Chapter 2's `step3-bricks.bas` was timed as before, with one extra line counting steps, once with its `FOR I=1 TO 100` delay and once without it. No key was held, and the ball did not reach the wall.

| Program | Frames a step | Steps a second |
|---------|--------------:|---------------:|
| Chapter 2, step 3, with its delay | 43.5 (50 steps in 2175 frames) | 1.1 |
| Chapter 2, step 3, with no delay | 5.5 (200 steps in 1108 frames) | 9.0 |
| This step, as shipped (`speed` 3) | 3 (505 steps in 1515 frames) | 16.7 |
| This step, no `HALT`, ball and keys every pass | 0.0216 (23957 steps in 519 frames) | about 2300 |

The last line was run with `POKE 50000,0: POKE 50001,1: POKE 50002,1: CLS : GO TO 70`, as in step 2. A pass now takes about 1510 T-states, about 170 more than step 2's: the look at the cell ahead, with `attr`, on every step. Chapter 2's loop with no delay grew from 4.1 frames to 5.5 for the same job, mostly the `ATTR` test and the longer program. That is about **255 times as long** as the machine code.

## Line by line

The parts that are new since step 2:

- **`kills`** at 50007 counts the bricks. The ball's state, the bat and the two countdowns move up one byte, to 50008 to 50014, and the entry point to 50015.
- **`wall`** names the attribute of row 2, column 0.
- **`start`** also clears `kills`, then fills 3 rows of 32 attributes with 23, 39 and 55: Chapter 2's lines 60 to 110.
- **`step`**, the row: as step 2, but a hit on the bat also steers by E, the place on the bat. That is Chapter 2's lines 300 to 340.
- **`flipr`** turns `dr` round, for the top edge and the bat.
- **`cols`** is the column edge test, as before: Chapter 2's lines 210 and 220.
- **`ahead`** works out the cell ahead in B and C, finds its attribute, and keeps the paper bits: Chapter 2's lines 230 and 240.
- **The brick.** If the paper is not black, the attribute becomes 7, `kills` goes up, `dr` turns round, and the code goes back to `cols`: Chapter 2's lines 400 to 420.
- **`go2`** stores B and C as the new row and column: Chapter 2's lines 250 and 260.
- **`attr`** is the attribute address of row B, column C.

`keys`, `left`, `right`, `miss`, `put`, `cell` and the graphics are step 2's.

## Limitations you will notice

- **The ball can only ever hit half the bricks.** Every step changes the row and the column by one each, so row plus column stays odd, or stays even, for ever, as step 1's trail showed. The bat's steering changes the direction but not that. Starting from row 5, column 5, the ball can only move into cells where row plus column is even, so the other half of the bricks can never be hit. Every hole in `step3-bricks-holes.png` is on an even cell. Chapter 2 had the same problem until step 5 added a little randomness, which can send the ball straight up for a while; step 4 here is its twin.
- **There is no end.** When the wall is gone, the ball goes on bouncing. The score, the lives and a win are step 6.
- **A brick only knows its colour.** The paper colour is the map of the wall, as in Chapter 2. Anything else drawn on rows 2 to 4 with coloured paper would count as a brick too.
- **The counts are single bytes,** as in step 2, and wrap round after 255.

## Try this

Each of these was tried in Fuse.

- Put the bat under the ball, and watch the wall go without touching a key. Stop the game with Space, then type `POKE 50008,5: POKE 50009,5: POKE 50010,1: POKE 50011,1: POKE 50012,20: CLS : GO TO 70`. The first four `POKE`s put the ball back at row 5, column 5, moving down and right, because `GO TO 70` would otherwise carry on from where it stopped. The fifth puts the bat at column 20, under the ball's path. A run of about 12 seconds gave 206 steps, 5 hits, 2 misses and 4 bricks.
- Change the colours. In `step3-bricks.asm`, change `ld a,2*8+7` to `ld a,1*8+7` and `add a,16` to `add a,8`, and build it again. The rows are blue, red and magenta: papers 1, 2 and 3.
- A thicker wall, and a surprise. Change `ld c,3` to `ld c,5`, and build it again. Five rows are filled, rows 2 to 6, with 23, 39, 55, 71 and 87. But 71 is 64 + 7: the 64 is the bright bit, not a paper colour, so row 5 has bright black paper and looks empty. 87 is 64 + 16 + 7, bright red paper, so row 6 is a bright red row. The ball starts in row 5, at column 5, and `and 56` gives 0 for row 5's attribute, so the ball moves through it freely, knocking bricks out of rows 4 and 6 on either side. Adding 16 a row only works while the paper stays below 8.
