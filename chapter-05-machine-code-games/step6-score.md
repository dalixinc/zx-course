# Chapter 5, step 6 — Score, lives and an ending

Chapter 2's step 7 turned the bat and ball into a game that can be won or lost: a score on the top row, three lives, 10 points a brick, `GAME OVER` when the lives run out and `WELL DONE` when the wall is gone. This step is its twin, and it finishes the bat and ball part of the chapter.

What is new is printing. The loop has been silent on the screen so far, except for the ball, the bat and the bricks, which are all drawn by copying bytes. A score is text, and text means digits. This lesson looks at two ways to print from machine code, the ROM's and our own, measures both, and says which the game uses and why.

It also decides which parts stay in BASIC. The game itself, with its score and lives, runs in machine code. The two ending screens, with their tunes, are BASIC: nothing is moving at that point, a tune that stalls the program does no harm, and the screens are easier to change in BASIC.

Chapter 2's step 7 took **10.0 frames a step** with nothing happening, and 10.75 a step over 40 steps with two misses in them, timed for this lesson (the count started after the wall was drawn). This step's loop takes **3.00 frames a step** as shipped, and **1.004** with the ball moving every frame, with its sounds and its status line included. With the `halt` taken out it took **0.068 of a frame** a step, and that figure has 243 bat notes, 91 bricks and every status line in it.

Every program here was assembled with pasmo, cross-checked against z80asm, and run in a 48K emulator before it was shown.

## The new instructions and ideas

The small examples are in `step6-examples.asm`, with a BASIC driver, `step6-examples.bas`, that runs each way of printing and times it. `step6-examples.png` is its screen at the end.

### RST 16 — the ROM's print routine

The ROM has a routine that prints one character, the one BASIC's `PRINT` uses for every character it prints. Chapter 3, step 6 used it, and this is the same:

```
        ld a,2          ; the upper screen,
        call 5633       ; made the current channel
        ld a,65         ; the code for "A"
        rst 16          ; print it
```

| Instruction | Bytes (hex) | Bytes (decimal) | T-states |
|-------------|-------------|-----------------|----------|
| `RST 16` | `D7` | 215 | 11, and then the ROM's own time |

`rst 16` is a one-byte call to address 16, which jumps into the ROM's print routine. It prints the character whose code is in A, at the current print position, in the current colours, and moves the print position along. `call 5633` (CHAN-OPEN) sets where it prints to: 2 is the upper screen. `PRINT` does this itself, and from machine code you do it yourself. Calling it at the start of every program that prints is safe and cheap.

Codes below 32 are not letters but orders. 22 is `AT`, and the next two bytes sent to `rst 16` are the row and the column, so printing at a place is four calls:

```
        ld a,22         ; AT
        rst 16
        ld a,(row)      ; the row
        rst 16
        ld a,(col)      ; the column
        rst 16
        ld a,(chr)      ; the character itself
        rst 16
```

That is example 1 of `step6-examples.asm`, and the driver prints an A at row 2, column 2 with it. The ROM changes the registers as it works. Everything the caller needs, A, BC, DE and HL, has to be saved before a call and put back after it. The game's `status` routine does this with four `push` instructions and four `pop`s.

### A string, with its orders inside

A routine prints a string by walking along it: get a byte, send it to `rst 16`, go on until the marker. The marker is 255, as in Chapter 3, because 0 turns up in a string as a row or a column. The game's two strings carry their own `AT`:

```
stext1: db 22,0,1,"SCORE ",255
stext2: db 22,0,22,"LIVES ",255
```

The first is `AT 0,1` and then `SCORE `, the second `AT 0,22` and `LIVES `: the same places as Chapter 2's `PRINT AT 0,1` and `PRINT AT 0,22`. The routine that walks them, `pstr`:

```
pstr:   ld a,(hl)       ; the next byte of the string
        inc hl
        cp 255          ; the end marker?
        ret z           ; yes: done
        rst 16          ; no: print it
        jr pstr
```

Example 2 prints a 22 character string this way, and the driver shows it on row 20.

### A number: pnum

A number is printed as characters, one for each digit, so the number has to be taken to pieces. Chapter 3's `pnum` does it by repeated subtraction: how many times does 10000 go into HL, then 1000, then 100, then 10, with what is left being the units. Each count is a digit, and `add a,'0'` turns it into the character code. A flag in B keeps the leading zeros from being printed. The routine and its helper `digit` are in the listing. They are Chapter 3's, with one change of name, `dloop2`, because the game already has a `dloop`.

Example 3 prints 1234 at row 6, column 2.

`pnum` does not clear anything. A number that gets shorter leaves the old digits behind it: in a first version of the driver, 450 printed over the 1234 from example 3 gave `4504`. The score never goes down, so the new number is never shorter than the old one, and it is safe here. A game that printed a number that could fall would print spaces after it first.

### Our own print: the character set and `put`

The ROM's letters are eight bytes each, in a table, and `put` already knows how to copy eight bytes into a cell: it is what draws the ball. The table is in the ROM, and the system variable `CHARS`, at 23606, holds its address less 256. So the eight bytes of the character with code c are at `CHARS + 8*c`:

```
        ld a,(chr)
        ld l,a
        ld h,0          ; HL = the character code
        add hl,hl
        add hl,hl
        add hl,hl       ; HL = 8 * the code
        ld de,(chars)
        add hl,de       ; HL = the character's 8 bytes
        ex de,hl        ; DE = the graphic, as put wants it
        ld a,(row)
        ld b,a
        ld a,(col)
        ld c,a
        jp put
```

| Instruction | Bytes (hex) | Bytes (decimal) | T-states |
|-------------|-------------|-----------------|----------|
| `LD DE,(nn)` | `ED 5B` n n | 237, 91, n, n | 20 |
| `ADD HL,HL` | `29` | 41 | 11 |
| `EX DE,HL` | `EB` | 235 | 4 |

`add hl,hl` doubles HL, so three of them multiply by 8. `ex de,hl` swaps the two pairs. This is example 5, and the driver prints a B at row 4, column 2 with it. It only draws the pixels. It does not touch the attributes, so the character takes whatever colours that cell already has. The ROM's version sets the colours as it prints.

### Which is quicker?

Each was run 100 times from a BASIC loop with `FRAMES` as the stopwatch. The loop itself took time, so an empty `LET V=USR` call to a bare `RET` was timed first, and taken away. The figures are in frames for 100 calls, so they are hundredths of a frame each:

| Call | Frames for 100 | Less the loop | Each |
|------|---------------:|--------------:|-----:|
| Nothing: `USR` to a `RET` | 57 | 0 | 0 |
| Own print of one character (example 5) | 57 | 0 | under 0.01 frame |
| ROM print of one character (example 1) | 62 | 5 | 0.05 frame |
| The number 1234 (example 3, with its `AT`) | 67 | 10 | 0.10 frame |
| The status line (example 4) | 100 | 43 | 0.43 frame |
| A string of 22 characters (example 2) | 110 | 53 | 0.53 frame |

The same two jobs in BASIC, with the empty `FOR` loop of 38 frames taken away:

| BASIC | Frames for 100 | Less the loop | Each |
|-------|---------------:|--------------:|-----:|
| `PRINT AT 21,28;"A"` | 65 | 27 | 0.27 frame |
| `PRINT AT 0,1;"SCORE "+STR$ N;AT 0,22;"LIVES 2"` | 194 | 156 | 1.56 frames |

The ROM's way is about **5 times** as fast for one character, and about **3.6 times** as fast for the status line, and the cost of a status line, 0.43 frame, is about 8.6 milliseconds. Our own print is faster again, because it is eight byte copies and no ROM, but it is not a way to print a whole line without more code: there is no `AT`, no number, and no colour. The game uses the ROM's, because the score is made of a string and a number, and each is a routine that was already written and tested in Chapter 3. Our own is the one to reach for when a letter has to be drawn every frame and 8 ms is too much.

The price of 8.6 ms is real in this game. A brick in step 5 cost a note of 9.5 ms. In this step it costs the note and a status line, about 18 ms, close to a whole frame, and the figures below show the effect.

### The status line stays out of the way

The status line is on row 0. Chapter 2's step 7 had the same problem and the same answer. A cell with black paper is open space to the brick test, so the ball must never be allowed to enter row 0. The ball's top row is therefore 1, and the ball bounces when its next row would be 0. The bricks move down a row, to rows 3 to 5, so that there is still an empty row, 2, between the ceiling and the wall. The wall colours are as before, red, green and yellow, and the ball starts on row 6, as in Chapter 2.

In step 5 the test was `cp batrow`, with the carry set for rows 0 to 20 and the row 255, off the top, picked out afterwards. Now `add a,(hl)` leaves the zero flag set when the next row is 0:

```
        add a,(hl)      ; A = row + dr
        jr z,top        ; 0 is the status line: a ceiling
        cp batrow       ; 1 to 20 is open space
        jp c,cols       ; carry: it is, look at the column
```

Row 255 cannot happen any more, so the old second test went.

### Counting: the score, the lives and the wall

Three numbers are kept in the parameter bytes, where BASIC can read them: `score` at 50017, a word; `lives` at 50019; and `bleft` at 50020, the bricks left. `start` gives them their starting values, 0, 3 and 96. A brick calls `scored`:

```
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
```

`dec (hl)` sets the zero flag when the byte reaches 0, so `jr nz` is all that is needed to tell "some left" from "none". A miss calls `lost`, which is the same for the lives, with 1 in `state` for the end of the game. Each ends with `jp status`, a jump rather than a call, so that `status` does the return.

### The state byte: how the game ended

The code does not print `GAME OVER` itself. It writes a code into `state`, at 50021, and the loop notices:

```
noball: ld a,(state)    ; is the game over, or won?
        and a
        ret nz          ; yes: back to BASIC, and it will say which
```

0 is a game being played, or one stopped with Space, 1 is no lives and 2 is no bricks. BASIC reads it after `RANDOMIZE USR` returns. The driver's lines 140 to 170 do the choosing, and the screens are Chapter 2's lines 650 to 780, with `GO TO 60` in place of `RUN`: `RUN` would load the code again.

## The listing

The machine code, `step6-score.asm`. It is step 5's, with `score`, `lives`, `bleft` and `state` added after `quiet`, `start` setting them and printing the status line, the loop checking `state`, the wall moved to row 3, the ceiling test changed, `scored` and `lost` called from the brick and the miss, and `status`, `pstr`, `pnum`, `digit` and the two strings added.

```
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
```

It is 800 bytes, 50000 to 50799. pasmo's listing puts `start` at 50022, `loop` at 50127, `keys` at 50177, `step` at 50251, `mid` at 50320, `top` at 50328, `cols` at 50336, `miss` at 50424, `scored` at 50450, `lost` at 50474, `status` at 50488, `pstr` at 50521, `pnum` at 50529, `digit` at 50564, `turn` at 50604, `nudge` at 50612, `rnd` at 50640, `sound` at 50657, `delay` at 50711, `sounds` at 50719, `put` at 50731, `cell` at 50743 and `attr` at 50758.

The BASIC driver, `step6-score.bas`. The entry point is 50022. After the game it reads `state`, the score, the steps and the frames, and chooses what to show:

```
1 REM S=ball steps taken
2 REM H=FRAMES high byte
3 REM L=FRAMES low byte
4 REM F=frames the game ran for
5 REM Y=how the game ended: 0 Space, 1 no lives, 2 no bricks
6 REM P=the score
10 CLEAR 49999
20 BORDER 1: PAPER 0: INK 7: CLS
30 PRINT "LOADING THE CODE"
40 LOAD ""CODE
50 CLS
60 POKE 50000,1: POKE 50001,3: POKE 50002,2
62 POKE 50015,PEEK 23672
70 PRINT #0;"O LEFT, P RIGHT, SPACE STOPS"
80 POKE 23672,0: POKE 23673,0: POKE 23674,0
90 RANDOMIZE USR 50022
100 LET H=PEEK 23673: LET L=PEEK 23672
110 IF PEEK 23673<>H THEN GO TO 100
120 LET F=L+256*H
130 LET S=PEEK 50003+256*PEEK 50004
140 LET Y=PEEK 50021
150 LET P=PEEK 50017+256*PEEK 50018
160 IF Y=1 THEN GO TO 300
170 IF Y=2 THEN GO TO 200
180 CLS
182 PRINT "BALL STEPS ";S
184 PRINT "FRAMES     ";F
186 IF S>0 THEN PRINT "FRAMES A STEP ";F/S
188 PRINT "HITS ";PEEK 50005;"  MISSES ";PEEK 50006;"  BRICKS ";PEEK 50007
190 IF INKEY$<>"" THEN GO TO 190
195 STOP
200 BEEP 0.08,0: BEEP 0.08,4: BEEP 0.08,7: BEEP 0.25,12
210 CLS
220 PRINT AT 8,11;"WELL DONE"
230 GO TO 400
300 BEEP 0.08,7: BEEP 0.08,4: BEEP 0.08,0: BEEP 0.25,-12
310 CLS
320 PRINT AT 8,11;"GAME OVER"
400 PRINT AT 10,11;"SCORE ";P
410 PRINT AT 14,2;"PRESS ANY KEY TO PLAY AGAIN"
420 IF INKEY$<>"" THEN GO TO 420
430 IF INKEY$="" THEN GO TO 430
440 CLS
450 GO TO 60
```

## Building and running

On Windows, from the course folder:

```
windows-tools\build.bat chapter-05-machine-code-games\step6-score.bas chapter-05-machine-code-games\step6-score.asm score 10
```

On Linux:

```
tools/build.sh chapter-05-machine-code-games/step6-score.bas chapter-05-machine-code-games/step6-score.asm score 10
```

The examples (the driver's first line is 11, because `CLEAR` is on line 11):

```
windows-tools\build.bat chapter-05-machine-code-games\step6-examples.bas chapter-05-machine-code-games\step6-examples.asm examples 11
```

```
tools/build.sh chapter-05-machine-code-games/step6-examples.bas chapter-05-machine-code-games/step6-examples.asm examples 11
```

The game looks like Chapter 2's step 7: `SCORE` and `LIVES` on the top row, the wall below, the bat at the bottom. O and P move the bat. Space still stops it and shows the statistics, as in the earlier steps. Losing the last life or clearing the last brick ends it with the BASIC screens.

## What it showed in Fuse

The tape was loaded in a 48K Fuse at normal speed.

- **The screen.** `step6-score.png` is a game in progress, with `SCORE 0` on the left and `LIVES 2` on the right, the wall on rows 3 to 5 and the ball below it. The status line is drawn in the ROM's colours, white on black.
- **Game over.** With no key held, the ball missed three times, and the BASIC screen came up: `GAME OVER`, `SCORE 0` and the prompt (`step6-score-over.png`). A key press started a new game, with the wall redrawn, `SCORE 0` and three lives, and the lives came down again as before.
- **A win.** The wall of 96 bricks could not be cleared in a test, and the reason is below, so the win was tested with a copy that counted the wall as 5 bricks and a bat as wide as the screen. After 5 bricks the game returned, and BASIC showed `WELL DONE` and `SCORE 50` (`step6-score-win.png`). A key press started another game, with the whole wall back and `LIVES 3`, and the same copy won again with 50.
- **The count.** With a screen-wide bat, a game stopped with Space after 5160 frames had 61 bricks gone, `SCORE 610`, `LEFT 35` and 53 bat hits. Ten times the bricks is the score, and 96 less the bricks is what is left (`step6-score-result.png`; `step6-score-holes.png` is the wall in the same game). A copy with `nlives` set to 5 and `points` to 25 started with `LIVES 5`, and after 11 bricks had `SCORE 275`.
- **Why the whole wall was not cleared.** The same wide-bat game, with no `halt`, took 91 bricks in one run, and in two runs on another seed it stopped at 810, with 15 bricks left, the same screen both times, after 60 and 100 seconds. The ball had fallen onto a path that repeats, which is what step 4 said about a generator on a seed. With a player and a bat that moves, it does not happen.
- **Nothing lost, nearly.** At `speed` 3 a game of 1718 steps, 61 bricks and every status line took 5160 frames, 3.0035 a step, 6 frames more than 3 a step. At `speed` 1, 2046 steps with 60 bricks took 2055 frames, **1.004** a step: 9 frames over, for 60 bricks and 61 bat hits, with a status line for each brick. A brick costs about 18 ms, a note and a status line, so it fits in a frame only just, and now and then a note and a status line on the same step spill into the next one.

pasmo and z80asm gave the same 800 bytes for `step6-score.asm`, and the same non-zero bytes for `step6-examples.asm`: pasmo pads the gaps between its `org`s with zeros, z80asm does not.

## The timing, against BASIC

Chapter 2's `step7-score.bas` was timed with one extra line counting steps and a stop at 12 and at 40. This time the `FRAMES` count was started after the wall was drawn, where the lessons before this one had started it at the beginning of the program (see below). No key was held, so the ball missed the bat, and in the 40 steps there were two misses with their beeps and status lines.

| Program | Frames a step | Steps a second |
|---------|--------------:|---------------:|
| Chapter 2, step 7, 12 steps with nothing happening | 10.0 (120 frames) | 5.0 |
| Chapter 2, step 7, 40 steps with two misses | 10.75 (430 frames) | 4.7 |
| This step, as shipped (`speed` 3) | 3.00 (1718 steps in 5160 frames) | 16.7 |
| This step, `speed` 1 | 1.004 (2046 steps in 2055 frames) | 49.8 |
| This step, no `halt`, ball and keys every pass | 0.068 (18414 steps in 1254 frames) | about 740 |

The last line has every sound and status line in it: 243 bat notes and 91 bricks, each with a note and a status line, in the 18414 steps. Their cost is most of the figure. Chapter 2's step 7 took about 150 times as long as that. The loop itself, with none of those, was timed in step 4 at about a fiftieth of a frame.

### The whole of Part A, side by side

The BASIC figures were all taken again for this table, with the count started after the wall was drawn. The machine-code figures are those of each step's lesson.

| Step | BASIC twin, with its delay | BASIC twin, no delay | Machine code, as shipped (`speed` 3) | Machine code, `speed` 1 | Machine code, no `halt` |
|------|---------------------------:|---------------------:|-------------------------------------:|------------------------:|------------------------:|
| 1, the ball | 7.0 | 2.4 | 2.00 | 1.002 | 0.0166 |
| 2, the bat | 35.2 | 4.1 | 2.99 | | 0.019 |
| 3, the bricks | 39.1 | 4.8 | 3.00 | | 0.022 |
| 4, randomness | 44.1 | 5.1 | 3.00 | | 0.0217 |
| 5, sound | 9.4 to 10.0 (delay `1 TO 10`) | | 3.00 | 1.003 | |
| 6, score and lives | 10.0 to 10.75 (delay `1 TO 10`) | | 3.00 | 1.004 | 0.068 with sound and status lines |

The BASIC twins of steps 5 and 6 have the short delay of Chapter 2, so they have only the one column. The BASIC figures for steps 1 and 2 are from those lessons and were not taken again. Their set-up is a few lines, not a wall, so the error in them is small, but it has not been measured.

What this says, in the order of the chapter: a machine-code loop that does the whole game takes about a fiftieth of a frame, and it is idle most of the time, waiting for the next frame. What costs time in it is not the game logic but what the screen and the speaker ask for: a note of 10 ms, a status line of 9 ms. Those two together are the reason a brick in step 6 can spill into a second frame. A game that needs more than that on every frame has to do less in a frame, and that is where Part B comes in: Invaders has far more to draw.

### A correction to the earlier timings

The first versions of steps 3, 4 and 5 gave Chapter 2's timings as 5.5, 5.9 and 11.03 frames a step, and 43.5 and 49.6 with the delay. Those runs counted from the start of the BASIC program, so they included the drawing of the wall, 100 to 220 frames, spread over the steps counted. This step re-timed all of them with the count started just before the loop. The figures in steps 3, 4 and 5 are now 4.8, 5.1, 10.04, 39.1 and 44.1, and the "times as long" ratios are about 220, 235 and so on. The machine-code figures were not affected.

## Line by line

The parts that are new since step 5:

- **`score`, `lives`, `bleft`, `state`** at 50017 to 50021. The entry point moves to 50022.
- **`wall`** is the attribute of row 3, column 0. `row` starts at 6, as does the ball after a miss.
- **`start`** sets `state`, `score`, `lives` and `bleft`, opens channel 2 with `chanopen` and prints the status line.
- **`noball`** in the loop returns to BASIC if `state` is not 0.
- **`step`**: the row 0 ceiling, with `jr z,top`.
- **The brick** calls `scored` after its note.
- **`miss`** calls `lost` after its note, and starts the ball again from row 6.
- **`scored`** adds `points` to `score`, takes one from `bleft`, and sets `state` to 2 when it reaches 0.
- **`lost`** takes one from `lives`, and sets `state` to 1 when it reaches 0.
- **`status`** saves AF, BC, DE and HL, prints `SCORE `, the score, `LIVES ` and the lives digit, and gives them back.
- **`pstr`, `pnum`, `digit`** are Chapter 3's.
- **`stext1`, `stext2`** are the two strings, each starting with its own `AT`.

## Limitations you will notice

- **A brick can cost a frame.** The note and the status line together take about 18 ms. At `speed` 1 it cost 9 frames in 2046 steps.
- **The lives are one digit.** `status` adds `'0'` to the byte, so more than 9 lives would print a wrong character. The score is a 16-bit number and `pnum` takes it up to 65535.
- **The wall in the wide-bat test cannot be cleared.** A generator on a seed, with a bat that does not move, can fall onto a path that repeats.
- **The tunes are BASIC `BEEP`s.** They stall BASIC, which is idle, and the machine code is not running, so there is nothing to lose.
- **There is no high score.**
- **The same seed each time in an emulator.** The seed is the low byte of `FRAMES` when the tape has loaded, as in step 4, and in an emulator that is the same each run.

## Try this

Each of these was tried in Fuse.

- More lives and bigger points: change `nlives` to 5 and `points` to 25 and build it again. The game started with `LIVES 5`, and after 11 bricks had `SCORE 275`.
- A win to see: change `nbricks` to 5, and give the driver a bat the width of the screen by changing `batw` to 32 and the `bat` byte to 0. After 5 bricks the game ends with `WELL DONE` and `SCORE 50`.
- Run `step6-examples.tap` and read the table of times at the bottom of its screen (`step6-examples.png`): it is the table in this lesson.
