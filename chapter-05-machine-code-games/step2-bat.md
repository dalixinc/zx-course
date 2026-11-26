# Chapter 5, step 2 — The bat, read with IN

Chapter 2, step 2 added a bat: four inverse spaces on row 21, moved with O and P through `INKEY$`. The ball bounced off it, and a miss put the ball back at row 5, column 5. This step is its twin. The bat looks the same, moves with the same keys, and the ball does the same things. Two parts are new, and both are about the keyboard.

1. **The keys are read with `IN`.** The keyboard is wired as eight half-rows of five keys. `IN` reads one half-row at a time and gives a bit for every key in it, so it can see O and P, or P and Space, held down together. `INKEY$` gives one key or none.
2. **The bat and the ball keep their own beats.** The loop goes round once a frame. The ball moves every third pass and the keys are looked at every second pass, each with its own countdown. In Chapter 2 both moved once per pass of a slow BASIC loop, so the bat crawled whenever the ball did.

There is one smaller change. Chapter 2 rubbed out all four cells of the bat and drew all four again for every step. Here, a step left rubs out the right-hand cell and draws one new cell on the left: two cells instead of eight. That is Chapter 4's rule, "do not redraw what has not moved".

Space now stops the program. Any key did in step 1, which would not do once O and P are in use.

The BASIC loop of Chapter 2, step 2, timed for this lesson, took **35.2 frames a step** with its delay loop, and **4.1 frames a step** without it. A pass of this step's loop, with the ball moving and the keys read on every pass, takes **0.019 of a frame**.

Every program here was assembled with pasmo, cross-checked against z80asm, and run in a 48K emulator before it was shown.

## The new instructions and ideas

The small examples are in `step2-examples.asm`, with a BASIC driver, `step2-examples.bas`. The driver reads all eight half-rows over and over and shows the bits, so you can hold keys down and watch them. It also prints what `INKEY$` gives at the same moment.

### The keyboard: eight half-rows of five keys

The 40 keys are wired as eight half-rows. Each half-row is chosen by one of the top eight address lines, and the five keys in it come back on bits 0 to 4 of the data. Bit 0 is always the key at the outside edge of the keyboard, and bit 4 the one nearest the middle.

| Half-row (top byte of the port) | Binary | Bit 0 | Bit 1 | Bit 2 | Bit 3 | Bit 4 |
|------:|----------|-------|-------|-------|-------|-------|
| 254 | 11111110 | Caps Shift | Z | X | C | V |
| 253 | 11111101 | A | S | D | F | G |
| 251 | 11111011 | Q | W | E | R | T |
| 247 | 11110111 | 1 | 2 | 3 | 4 | 5 |
| 239 | 11101111 | 0 | 9 | 8 | 7 | 6 |
| 223 | 11011111 | P | O | I | U | Y |
| 191 | 10111111 | Enter | L | K | J | H |
| 127 | 01111111 | Space | Symbol Shift | M | N | B |

The top byte has a single 0 bit, and that 0 picks the half-row. The bottom byte of the port is always 254: the ULA answers any even port, and 254 is the one the ROM uses, the same port as the border in Chapter 3.

A key that is held down reads as **0**. A key that is up reads as 1. That sounds backwards, but it is how the hardware is wired: each key, when pressed, connects its data line to the 0 of the chosen address line. Bits 5 to 7 are not keys. Bit 6 is the tape input, and the others are not reliable, so a program keeps bits 0 to 4 with `and 31` or picks out the bits it wants.

### IN A,(n) — read a port

```
        ld a,223        ; half-row P, O, I, U, Y
        in a,(254)      ; bit 0 is P, bit 1 is O; 0 means held
```

`in a,(n)` reads the port whose bottom byte is n and whose top byte is whatever A holds, and puts the result in A. So the half-row goes into A first, and `in a,(254)` reads port 223×256+254, which is 57342.

| Instruction | Reads port | Bytes (hex) | Bytes (decimal) | T-states |
|-------------|------------|-------------|-----------------|----------|
| `IN A,(n)` | A×256 + n | `DB` n | 219, n | 11 |
| `IN r,(C)` | B×256 + C | `ED`, then 40 + 8×r in hex | 237, ... | 12 |

The second form, with the port in BC, can read into any register, and it sets the flags. This chapter uses the first, which is shorter and is the same idea as BASIC's `IN 57342`. `OUT (254),A`, from Chapter 3, step 4, is its partner.

Example 1 in `step2-examples.asm` reads one half-row and keeps the five key bits:

```
        ld a,(half)     ; A = the half-row, the top half of the port
        in a,(254)      ; read port A*256+254
        and 31          ; keep bits 0 to 4, the five keys
```

The driver shows each half-row as five binary digits, bit 4 on the left, as in the key list. `step2-examples.png` is the screen with O and P both held: row 223 reads `11100`, bits 1 and 0 both low, and every other row reads `11111`. Holding P alone gave `11110`. Holding P and Space gave `11110` on row 223 and `11110` on row 127, both at once (`step2-examples-space.png`).

The same screens show `INKEY$` at the same moment. It gave `"p"` with P alone, but `""` with O and P held, and `""` with P and Space. That is the difference this step is about: `INKEY$` reports one new key, and with two down it reported none. `IN` reports every key in the half-row, every time.

### CPL — turn every bit over

A 0 for a key that is held is awkward to test. `cpl` turns every bit of A over, 0 to 1 and 1 to 0, so afterwards a 1 means held:

```
        in a,(254)      ; bit 0 is P, bit 1 is O; 0 means held
        cpl             ; turn the bits over: now 1 means held
        and 3           ; keep only P and O
```

| Instruction | What it does | Bytes (hex) | Bytes (decimal) | T-states |
|-------------|--------------|-------------|-----------------|----------|
| `CPL` | A = 255 - A, every bit turned over | `2F` | 47 | 4 |

After `and 3`, A is 0 if neither key is held, 1 for P alone, 2 for O alone, and 3 for both. Example 2 is example 1 with `cpl` before the `and 31`. In the driver's last column it gave 3 for row 223 with O and P held, 1 with P alone, and 0 with no keys.

The bat moves only for 1 or 2. With both keys held it stays where it is, because the code can see that both are down. In Chapter 2, holding O and P together leaves `INKEY$` empty, as the examples showed, so that bat does not move either; but there the program cannot tell "both" from "neither".

### BIT b,r — test one bit of a register

Space is bit 0 of half-row 127, and nothing else in that half-row matters to the game, so one bit is tested on its own:

```
noball: ld a,127        ; half-row Space, Sym Shift, M, N, B
        in a,(254)      ; read it: a 0 bit is a key held down
        bit 0,a         ; bit 0 is Space
        jr nz,loop      ; 1: Space is up, round again
        ret             ; 0: Space is down, back to BASIC
```

Step 1 used `bit 5,(hl)` on a byte in memory. `bit b,r` is the same test on a register.

| Instruction | Bytes (hex) | Bytes (decimal) | T-states |
|-------------|-------------|-----------------|----------|
| `BIT 0,A` | `CB 47` | 203, 71 | 8 |
| `BIT 5,(HL)` (step 1) | `CB 6E` | 203, 110 | 12 |

### INC (HL), DEC (HL) and SUB (HL) — work on a byte in memory

Step 1 added a byte from memory with `add a,(hl)`. The Z80 can also add one to a byte in memory, or take one off, without loading it into a register first:

```
go:     ld hl,ptime
        dec (hl)        ; one pass fewer to the next key look
        jr nz,nokeys    ; not yet
```

| Instruction | What it does | Bytes (hex) | Bytes (decimal) | T-states |
|-------------|--------------|-------------|-----------------|----------|
| `INC (HL)` | the byte at HL + 1 | `34` | 52 | 11 |
| `DEC (HL)` | the byte at HL - 1 | `35` | 53 | 11 |
| `SUB (HL)` | A = A - the byte at HL | `96` | 150 | 7 |

`inc (hl)` and `dec (hl)` set the zero flag the same way as `inc a` and `dec a`, so `dec (hl)` / `jr nz` is a countdown kept in memory. The code uses it for the two beats, for moving the bat (`dec (hl)` and `inc (hl)` on `bat`), and for counting hits and misses.

`sub (hl)` is the partner of `add a,(hl)`. It is used for the bat test below.

### Two beats from one loop

The loop waits for one frame, then counts down two bytes:

| Byte | Starts at | When it reaches 0 |
|------|-----------|-------------------|
| `ptime` | `bspeed`, 2 | look at O and P, move the bat, and start again from `bspeed` |
| `btime` | `speed`, 3 | move the ball, and start again from `speed` |

So the bat can move every second frame, 25 cells a second, and the ball moves every third frame, about 17 cells a second. Either can be changed from BASIC without touching the other. `halts`, the number of `HALT`s a pass, is step 1's `speed` under a new name: 1 is one pass a frame, and 0 means no waiting at all, which is how the loop is timed below.

`speed` and `bspeed` must be 1 or more here. A countdown that starts at 0 goes to 255 on the first `dec`, so 0 would mean 256 passes.

### The bat test: one more unsigned compare

When the ball's next row would be 21, the bat's row, the code asks whether the ball's column is over the bat. Chapter 2 asked it as `X>=B AND X<=B+W-1`. Here it is one subtraction and one compare:

```
        ld a,(col)      ; the bat's row: is the bat under the ball?
        ld hl,bat
        sub (hl)        ; A = col - bat
        cp batw         ; 0 to 3 means over the bat
        jr nc,miss      ; no: a miss
```

If the ball is over the bat, `col - bat` is 0, 1, 2 or 3. If the ball is to the left of the bat, the subtraction goes below 0 and wraps round to 255 or so, which is more than 3. So `cp 4` catches both sides at once, the same trick as step 1's edge test.

### XOR A, and constants with equ

`xor a` sets A to 0 in one byte. Each bit of A is compared with itself, and the same bits always give 0:

| Instruction | Bytes (hex) | Bytes (decimal) | T-states |
|-------------|-------------|-----------------|----------|
| `XOR A` | `AF` | 175 | 4 |
| `LD A,0` | `3E 00` | 62, 0 | 7 |

It is the usual way to clear A in Z80 code. It also clears the carry flag and sets the zero flag, where `ld a,0` leaves the flags alone.

The bat's row and width are named with `equ`, as `flags` was in step 1:

```
batrow: equ 21          ; the bat's row
batw:   equ 4           ; the bat's width in cells
```

The assembler can work sums out with them, so `cp 32-batw` is `cp 28`, and `add a,batw-1` is `add a,3`. A wider bat is then a one-line change, and "Try this" makes one.

### A row and a column as a pair

`put` and `cell` now take the row in B and the column in C, so they can draw the bat as well as the ball. The ball's column and row sit next to each other in memory, column first:

```
col:    db 5            ; 50007: ball column (C of the pair)
row:    db 5            ; 50008: ball row (B of the pair)
```

`ld bc,(col)`, from Chapter 3, step 6, loads the byte at `col` into C and the next byte into B, low byte first. So one instruction loads both, ready for `put`. In the same way, `ld hl,5*256+5` / `ld (col),hl` sets both back to 5 after a miss.

`put` changes B, because it counts its eight lines with `djnz`. The loop that draws the bat at the start keeps BC on the stack round each `call put`. The first version of this step did not, and the second, third and fourth cells of the bat came out on row 0, because B was 0 after the first `put`. Anything a routine changes has to be written in its comment, and checked by the code that calls it.

### JP as the last call

The two ends of `keys` finish by drawing one cell:

```
        ld de,solid
        jp put          ; draw it, and put returns for us
```

A `call put` followed by `ret` would work. `jp put` jumps to `put` instead, and the `ret` at the end of `put` returns straight to whoever called `keys`. It saves a byte and 17 T-states. Chapter 3, step 9 did the same with `jr ldfill`.

## The listing

The machine code, `step2-bat.asm`:

```
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
```

It is 341 bytes, 50000 to 50340. pasmo's listing puts `start` at 50014, `loop` at 50059, `keys` at 50104, `step` at 50178, `miss` at 50272, `put` at 50290 and `cell` at 50302.

The BASIC driver, `step2-bat.bas`:

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
90 RANDOMIZE USR 50014
100 LET H=PEEK 23673: LET L=PEEK 23672
110 IF PEEK 23673<>H THEN GO TO 100
120 LET F=L+256*H
130 LET S=PEEK 50003+256*PEEK 50004
140 CLS
150 PRINT "BALL STEPS ";S
160 PRINT "FRAMES     ";F
170 IF S>0 THEN PRINT "FRAMES A STEP ";F/S
180 PRINT "HITS ";PEEK 50005;"  MISSES ";PEEK 50006
190 IF INKEY$<>"" THEN GO TO 190
```

## Building and running

On Windows, from the course folder:

```
windows-tools\build.bat chapter-05-machine-code-games\step2-bat.bas chapter-05-machine-code-games\step2-bat.asm bat 10
```

On Linux:

```
tools/build.sh chapter-05-machine-code-games/step2-bat.bas chapter-05-machine-code-games/step2-bat.asm bat 10
```

The examples:

```
windows-tools\build.bat chapter-05-machine-code-games\step2-examples.bas chapter-05-machine-code-games\step2-examples.asm examples 10
```

```
tools/build.sh chapter-05-machine-code-games/step2-examples.bas chapter-05-machine-code-games/step2-examples.asm examples 10
```

When the tape has loaded, the bat appears in the middle of row 21 and the ball starts at row 5, column 5. O moves the bat left and P moves it right. Space stops the game, and BASIC prints the ball's steps, the frames, the frames a step, and the hits and misses.

The examples program shows the eight half-rows and goes on until you break it with Caps Shift and Space, as a BASIC program. The table is redrawn about once a second, because the BASIC that prints it is slow; the code that reads the keys is not.

## What it showed in Fuse

The tape was loaded in a 48K Fuse at normal speed, and the keys were held down the way a player would hold them.

- `step2-bat.png` is the start: the four-cell bat in columns 14 to 17, and the ball on its way down.
- Holding O moved the bat to the left edge, where it stopped. Holding P moved it to the right edge, columns 28 to 31, where it stopped.
- Holding O and P together for two seconds left the bat where it was. Letting go of O, with P still held, set it moving right straight away.
- Holding P and then pressing Space stopped the game. The Space was seen while P was still held.
- A miss put the ball back at row 5, column 5, moving down and to the right.
- The bat hits were checked by starting the bat at column 18, under the ball's first fall (`POKE 50011,18` in a copy of the driver). The ball bounced off it, and with no key touched the game counted 5 hits and 5 misses in 290 steps.

`step2-bat-result.png` is the end of one run with the driver as it is: 339 ball steps in 1015 frames, 2.99 frames a step, with `speed` at 3, and 21 misses, because no attempt was made to hit the ball.

pasmo and z80asm gave the same 341 bytes for `step2-bat.asm`, and the same 24 bytes of code for `step2-examples.asm`.

## The timing, against BASIC

Chapter 2's `step2-bat.bas` was timed the same way as in step 1, with one extra line counting steps, once with its delay, `FOR I=1 TO 100: NEXT I`, and once without it. No key was held.

| Program | Frames a step | Steps a second |
|---------|--------------:|---------------:|
| Chapter 2, step 2, with its delay | 35.2 (50 steps in 1762 frames) | 1.4 |
| Chapter 2, step 2, with no delay | 4.1 (200 steps in 816 frames) | 12.3 |
| This step, as shipped (`speed` 3) | 3 (339 steps in 1015 frames) | 16.7 |
| This step, no `HALT`, ball and keys every pass | 0.0192 (26622 steps in 511 frames) | about 2600 |

The last line was run by typing `POKE 50000,0: POKE 50001,1: POKE 50002,1: CLS : GO TO 70` after a game. A pass of the loop, with a look at O and P, a ball step and the Space test, took 0.0192 of a frame, about 1340 T-states. That is about 180 T-states more than step 1's ball alone. Chapter 2's loop with no delay took 4.1 frames a pass: about **210 times as long**.

The bat is quicker still in comparison. In Chapter 2 it moved once per pass of the loop, so with the delay in it moved 1.4 cells a second, and crossing the screen took twenty seconds. Here it moves every `bspeed` passes, 2 frames, so 25 cells a second, and the 14 cells from the middle to the edge take 28 frames, just over half a second. It does not slow down when the ball moves.

## Line by line

The driver is step 1's, with three parameters poked in line 60 (`halts` 1, `speed` 3, `bspeed` 2), the entry point at 50014, the step count at 50003, and the hits and misses printed in line 180.

The machine code:

- **`halts` to `ptime`** are the parameter bytes, 50000 to 50013. `batrow` and `batw` name the bat's row and width.
- **`start`** clears the counts, draws the four cells of the bat, keeping BC round each `put`, and draws the ball.
- **`loop` to `wait`** wait for `halts` frames, as step 1 did.
- **`go`** counts `ptime` down, and when it reaches 0, starts it again from `bspeed` and calls `keys`.
- **`nokeys`** does the same with `btime`, `speed` and `step`.
- **`noball`** reads the Space half-row, and goes round again unless bit 0 is 0.
- **`keys`** reads half-row 223, turns it over, keeps bits 0 and 1, and goes to `right` for 1 (P), `left` for 2 (O), or returns for 0 or 3. That is Chapter 2's lines 65 to 80.
- **`left`** returns at column 0, rubs out the right-hand cell, moves `bat` one left, and draws the new left-hand cell.
- **`right`** returns at column 28, rubs out the left-hand cell, moves `bat` one right, and draws the new right-hand cell.
- **`step`** is step 1's ball, with one more case. If the next row is 21, the bat's row, the ball is over the bat when `col - bat` is 0 to 3: count a hit and bounce, as for the top edge. Otherwise go to `miss`. That is Chapter 2's lines 90 to 140 and 200.
- **`miss`** counts the miss, puts the ball back at row 5, column 5, moving down and right, and draws it there. That is Chapter 2's line 210.
- **`put`** and **`cell`** are step 1's, with the row and column in B and C.
- **`ball`**, **`blank`** and **`solid`** are the graphics. A cell of `solid` is what `INVERSE 1` and a space gave in Chapter 2.

## Limitations you will notice

- **The bat's ends do not steer yet.** The ball always bounces straight back up the way it came, as in Chapter 2, step 2. Chapter 2, step 3 made the bat's ends send the ball off to the side, and so will step 3 here.
- **The hits and misses are single bytes.** They count up to 255 and then start again from 0. In the no-`HALT` run above, the misses read 128 after 1664 misses, which is 6 times 256 plus 128.
- **The ball still rubs out what is under it,** as in step 1. It never goes into row 21, so it cannot rub out the bat.
- **There is no sound and no score.** Those are steps 5 and 6.

## Try this

Each of these was tried in Fuse. Stop the game with Space first, then type the line and press ENTER. `GO TO 70` starts it again, with the bat and the ball where they were.

- Speed the ball up: `POKE 50001,2: CLS : GO TO 70`. A run gave 255 steps in 511 frames, 2.0 frames a step.
- Take the brakes off, as in "The timing" above: `POKE 50000,0: POKE 50001,1: POKE 50002,1: CLS : GO TO 70`, and stop it within twenty seconds. A run gave 26622 steps in 511 frames.
- Make the bat wider. In `step2-bat.asm`, change `batw: equ 4` to `batw: equ 6`, and build it again. The bat is six cells wide, and it stops at column 26, with its right-hand cell in column 31. Nothing else in the code had to change, because every other use of the width is worked out from `batw`.
- Watch the bits yourself. Run the examples, and hold different keys together: two keys in the same half-row, like O and P, or in different ones, like P and Space. Both show up, where `INKEY$` shows nothing.
