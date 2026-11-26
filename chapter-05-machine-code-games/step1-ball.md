# Chapter 5, step 1 — A bouncing ball in machine code

Chapter 2 started its game with a ball: the letter `O`, moved one character cell at a time with `PRINT AT`, bounced off the four edges of rows 0 to 21, with `PAUSE 5` to slow it down. This step is its twin, and the first step of the machine-code bat and ball. The ball moves in the same way, one cell at a time, diagonally, and bounces off the same edges. Only the language has changed.

Three things are new compared with Chapter 3:

1. **A game loop.** Chapter 3's routines did a job and came back. This one goes round and round, once every few frames, until you press a key. The beat of the loop is `HALT`, which waits for the start of the next frame.
2. **Drawing a character cell ourselves.** There is no `PRINT AT`. The routine works out where the cell is in the screen memory, then copies the ball's eight bytes into it, one pixel line at a time. Rubbing it out is the same copy, with eight zeros.
3. **Steps that can be negative.** A step of -1 is kept as the byte 255. Adding 255 to a byte takes one off it, so the same `ADD` moves the ball either way. `NEG` turns +1 into -1 and back again, which is the bounce.

The ball is Chapter 2's round ball from step 4, eight bytes written into the code, instead of the letter `O`.

The figures to compare are Chapter 2's. Timed in Fuse for this lesson, the BASIC ball of Chapter 2, step 1 took **7.0 frames a step** with its `PAUSE 5`, and **2.4 frames a step** with the `PAUSE` taken out. The machine-code ball does a step in about **a sixtieth of a frame**, and then waits for as many frames as you ask it to.

Every program here was assembled with pasmo, cross-checked against a second assembler, z80asm, and run in a 48K emulator before it was shown.

## The new instructions and ideas

The small examples in this section are in `step1-examples.asm`, with a BASIC driver, `step1-examples.bas`, that pokes the inputs, calls each one with `USR`, and prints what comes back in BC. Example n starts at 50000+100*n, as in Chapter 3, step 5. `step1-examples.png` is the driver's screen in Fuse, and every result quoted below is copied from it.

### Parameter bytes, and equ

As in Chapter 3, steps 7 to 9, the code starts with bytes that BASIC can `POKE` and `PEEK`:

```
speed:  db 2            ; 50000: HALTs per step
steps:  dw 0            ; 50001: steps taken, counted here
row:    db 5            ; 50003: ball row
col:    db 5            ; 50004: ball column
dr:     db 1            ; 50005: row step, +1 or -1
dc:     db 1            ; 50006: column step, +1 or -1
```

| Address | Name | What it is | In BASIC |
|--------:|------|------------|----------|
| 50000 | `speed` | HALTs per step: the ball waits this many frames before each step. 0 means do not wait at all. | `POKE 50000,2` |
| 50001–50002 | `steps` | How many steps the ball took, low byte first. The code clears it at the start. | `PEEK 50001+256*PEEK 50002` |
| 50003 | `row` | The ball's row, 0 to 21: BASIC's `R`. | `POKE 50003,5` |
| 50004 | `col` | The ball's column, 0 to 31: BASIC's `X`. | `POKE 50004,5` |
| 50005 | `dr` | The row step: 1 is down, 255 is up. BASIC's `DR`. | `POKE 50005,255` |
| 50006 | `dc` | The column step: 1 is right, 255 is left. BASIC's `DX`. | `POKE 50006,255` |

`row`, `col`, `dr` and `dc` are where the ball's state lives, the same four variables as Chapter 2's `R`, `X`, `DR` and `DX`. The code does not reset them when it starts, so a second run carries on from where the ball stopped. The entry point, `start`, is at 50007.

`equ` gives a name to a number without putting any bytes in the code:

```
flags:  equ 23611       ; system variable; bit 5 is set by a new key
```

From then on, `ld hl,flags` means `ld hl,23611`. It makes the source easier to read, and if the number is ever wrong, it only has to be put right in one place. The label needs its colon here for z80asm; pasmo accepts it with or without.

### The screen address of a character cell

`PRINT AT R,X` found the cell for us. In machine code we work it out. Chapter 3's "For info" aside, in step 8, showed the bits of a screen address:

```
010TTRRR CCCXXXXX
```

For the top pixel line of a character cell, the three pixel-line bits are 0, and the address splits up like this:

| Part | Bits | Comes from |
|------|------|------------|
| H, the high byte | `010TT000` | `TT` is the third of the screen, 0 to 2: the top two bits of the row |
| L, the low byte | `RRRCCCCC` | `RRR` is the row inside the third, 0 to 7: the bottom three bits of the row. `CCCCC` is the column, 0 to 31 |

A row number from 0 to 23 is `000TTRRR` in binary. So:

- `and 24` (binary `00011000`) keeps `TT` where it is, and `or 64` puts in the `010`: that is H.
- `and 7` keeps `RRR` at the bottom. Three `rrca`s rotate it round to the top, `RRR00000`, the same as multiplying by 32. `or` with the column gives L.

```
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
```

Three `rrca`s move the bits right by three places, and the three that fall off the bottom come round to the top: on eight bits, that is the same as moving them left by five. `rrca` is 1 byte and 4 T-states, so three of them cost 12 T-states. Chapter 3, step 5 introduced `rrca`.

Example 6 is the same code, with `ld b,h` / `ld c,l` at the end so `USR` hands the address back. In Fuse:

| Row, column | `USR 50600` | Check |
|-------------|------------:|-------|
| 0, 0 | 16384 | the first byte of the screen |
| 5, 5 | 16549 | 16384 + 5×32 + 5 |
| 8, 0 | 18432 | 16384 + 2048: the first cell of the middle third |
| 21, 31 | 20671 | 16384 + 2×2048 + 5×32 + 31: third 2, row 5 inside it |

### Drawing a cell: eight bytes down, with INC H

The eight pixel lines of a character cell are 256 bytes apart in memory. Chapter 3, step 8 showed that `inc h` moves down one pixel line, as long as we stay inside the cell. A cell never crosses into the next cell's lines, so eight `inc h`s are always safe. `put` copies the eight bytes at DE into the cell at (`row`, `col`):

```
put:    call cell       ; HL = the top byte of the cell
        ld b,8          ; 8 pixel lines in a cell
pline:  ld a,(de)       ; A = one line of the graphic
        ld (hl),a       ; onto the screen
        inc de          ; next line of the graphic
        inc h           ; next pixel line down the cell
        djnz pline
        ret
```

The graphic is any eight bytes, one per pixel line, top first: the same bytes that Chapter 2, step 4 poked into UDG A with `BIN`.

```
ball:   db 60,126,255,255,255,255,126,60
blank:  db 0,0,0,0,0,0,0,0
```

60 is `00111100`, 126 is `01111110` and 255 is `11111111`: the round ball. To draw it, `ld de,ball` and `call put`. To rub it out, `ld de,blank` and `call put`. That is what `PRINT AT R,X;" "` did in Chapter 2, without the ROM's work of finding the character, the channel and the colours.

`put` only writes pixels. The colour of the cell is its attribute, and `put` leaves that alone: the ball is white because BASIC's `CLS` set every attribute to white ink on black paper.

### ADD A,(HL) — add a byte from memory

`add a,n` (Chapter 3, step 5) adds a number written into the code. `add a,(hl)` adds the byte at the address in HL. The ball's step is a byte in memory, `dr`, so:

```
        ld hl,dr        ; HL = the address of dr
        ld a,(row)
        add a,(hl)      ; A = row + dr
```

| Instruction | Bytes (hex) | Bytes (decimal) | T-states |
|-------------|-------------|-----------------|----------|
| `ADD A,(HL)` | `86` | 134 | 7 |
| `ADD A,n` | `C6` n | 198, n | 7 |

It sets the flags as `add a,n` does. There is no `add a,(nn)`: to add a byte from memory, its address has to be in HL first (or in IX or IY, which come later).

### A step of -1 is 255

A byte holds 0 to 255. Adding 256 to a byte gives the same byte back, because the carry out of bit 7 is lost. So adding 255 is the same as adding 256 and taking one away: it takes one away. That makes 255 a perfectly good -1, and the same `add a,(hl)` moves the ball down when `dr` is 1 and up when it is 255.

Example 2, `USR 50200`, adds the byte at 50001 to the byte at 50000:

| Sum | Answer |
|-----|-------:|
| 5 + 1 | 6 |
| 5 + 255 | 4 |
| 0 + 255 | 255 |

The last line is the one that matters at the top of the screen. Row 0 plus a step of -1 is 255, not -1. That is how the code sees that the ball would go off the top.

Reading a byte this way, with 128 to 255 standing for -128 to -1, is called *two's complement*. The Z80 does not need to be told: the bits of the answer are the same either way. Only our reading of them changes.

### NEG — turn a number round

`neg` works out 0 - A and puts it in A. With two's complement, that turns +1 into -1 and -1 into +1:

```
        ld a,(hl)
        neg             ; A = -dr
        ld (hl),a       ; dr = -dr: bounce
```

| Instruction | Bytes (hex) | Bytes (decimal) | T-states |
|-------------|-------------|-----------------|----------|
| `NEG` | `ED 44` | 237, 68 | 8 |

It is BASIC's `LET DR=-DR`. Example 1, `USR 50100`, gave:

| A | After `neg` |
|--:|------------:|
| 1 | 255 |
| 255 | 1 |
| 0 | 0 |

`neg` sets the flags as a subtraction would, and it only works on A.

### One CP for both edges

Chapter 2 tested the two edges separately: `IF R+DR<0` and `IF R+DR>21`. Here there is only one test. After `add a,(hl)`, A is the row the ball would move to. If that is the top edge, -1, A is 255. If it is the bottom edge, A is 22. `cp 22` sets the carry flag only when A is 0 to 21, so one test catches both:

```
        cp 22           ; 0 to 21 is on the screen
        jr c,rowok      ; carry: A < 22, so it is
```

`cp` compares as if both numbers were 0 to 255, so 255 is "more than 22", not "less than 0". Example 3, `USR 50300`, gives 1 when the carry is set:

| Next row | Carry after `cp 22` |
|---------:|--------------------:|
| 0 | 1 |
| 21 | 1 |
| 22 | 0 |
| 255 | 0 |

The column uses `cp 32` in the same way, for columns 0 to 31.

### BIT and RES — test and clear one bit in memory

The ball keeps going until a key is pressed. The ROM already watches the keyboard: 50 times a second, its interrupt routine scans the keys, and when a new key goes down it puts the code in `LAST K` (23560) and sets bit 5 of the system variable `FLAGS` (23611). So the loop only has to look at that one bit.

```
        ld hl,flags
        res 5,(hl)      ; forget any key pressed before we started
        ...
        ld hl,flags
        bit 5,(hl)      ; has a key been pressed?
        jr z,loop       ; no: round again
```

| Instruction | What it does | Bytes (hex) | Bytes (decimal) | T-states |
|-------------|--------------|-------------|-----------------|----------|
| `BIT 5,(HL)` | Z = 1 if bit 5 of the byte at HL is 0, Z = 0 if it is 1. The byte does not change. | `CB 6E` | 203, 110 | 12 |
| `RES 5,(HL)` | Clear bit 5 of the byte at HL. No flags change. | `CB AE` | 203, 174 | 15 |
| `SET 5,(HL)` | Set bit 5 of the byte at HL. No flags change. | `CB EE` | 203, 238 | 15 |

Any bit from 0 to 7 can be used: the second byte goes up by 8 for each bit, so `bit 0,(hl)` is `CB 46` and `bit 7,(hl)` is `CB 7E`. There are forms for every register too, such as `bit 0,a` and `set 7,c`, each two bytes and 8 T-states.

`bit` is like `and` with a single-bit mask, but it leaves the byte alone, and it works on memory as well as on A. Example 4, `USR 50400`, gives 1 when bit 5 of the byte at 50000 is set, and example 5, `USR 50500`, clears it and hands the byte back:

| Byte | `bit 5` gives | After `res 5` |
|-----:|--------------:|--------------:|
| 255 (`11111111`) | 1 | 223 (`11011111`) |
| 16 (`00010000`) | 0 | 16 |

The `res` at the start is a precaution: it makes sure that only a key pressed after the ball starts can stop it, whatever happened in BASIC before. In Fuse the ball also ran with it taken out, so it is there for safety, not because the program was seen to fail without it.

This only works because the ROM's interrupt routine runs every frame. Chapter 3 left the interrupts on, and so does this step. It is also why `FRAMES` keeps counting while the code runs, and so why BASIC can time it.

### HALT as the beat of the game

Chapter 3, step 8 used `halt` to slow a fill down to one line a frame. Here it is the heartbeat of the game. Each time round the loop, the code does `speed` `halt`s, then rubs out the ball, moves it, and draws it again:

```
loop:   ld a,(speed)    ; A = HALTs to do
        and a           ; is it 0?
        jr z,move       ; yes: do not wait
        ld b,a          ; B = HALTs still to do
wait:   halt            ; wait for the next frame
        djnz wait       ; B-1; not zero: wait again
```

Two things follow from that.

**The speed is exact.** The work of a step takes far less than a frame, so a step takes exactly `speed` frames, whatever the ball is doing. Chapter 2's `PAUSE 5` gave 7 frames a step, because BASIC's own work added two more frames on top, and the figure would grow with every line added to the game.

**The ball is drawn before the picture reaches it.** The interrupt comes at the start of each frame, while the TV is still drawing the border above the picture. The top border takes 64 lines of 224 T-states, 14336 T-states, before the first line of the screen is drawn. The ROM's interrupt routine and one step of the ball, rub out, move and draw, take a few thousand of those. So the ball is always complete by the time the picture is drawn, and is never caught half rubbed out. Chapter 2's ball was rubbed out and redrawn whenever BASIC got round to it, and you could see it flicker.

## The listing

The machine code, `step1-ball.asm`:

```
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
```

It is 156 bytes, 50000 to 50155. pasmo's listing (`-d`) puts `start` at 50007, `loop` at 50024, `put` at 50105, `cell` at 50117 and `ball` at 50140.

The BASIC driver, `step1-ball.bas`:

```
1 REM S=steps the ball took
2 REM H=FRAMES high byte
3 REM L=FRAMES low byte
4 REM F=frames the ball ran for
10 CLEAR 49999
20 BORDER 0: PAPER 0: INK 7: CLS
30 PRINT "LOADING THE CODE"
40 LOAD ""CODE
50 CLS
60 POKE 50000,2
70 PRINT #0;"PRESS A KEY TO STOP"
80 POKE 23672,0: POKE 23673,0: POKE 23674,0
90 RANDOMIZE USR 50007
100 LET H=PEEK 23673: LET L=PEEK 23672
110 IF PEEK 23673<>H THEN GO TO 100
120 LET F=L+256*H
130 LET S=PEEK 50001+256*PEEK 50002
140 CLS
150 PRINT "STEPS  ";S
160 PRINT "FRAMES ";F
170 IF S>0 THEN PRINT "FRAMES A STEP ";F/S
180 IF INKEY$<>"" THEN GO TO 180
```

`PRINT #0` prints in the lower part of the screen, rows 22 and 23, the part BASIC uses for its messages and for typing. The ball never goes there, so the message is not rubbed out.

## Building and running

On Windows, from the course folder:

```
windows-tools\build.bat chapter-05-machine-code-games\step1-ball.bas chapter-05-machine-code-games\step1-ball.asm ball 10
```

On Linux:

```
tools/build.sh chapter-05-machine-code-games/step1-ball.bas chapter-05-machine-code-games/step1-ball.asm ball 10
```

This is the two-file form from Chapter 3: zmakebas makes the driver, with the name `ball` and auto-run from line 10, pasmo `--tap` makes the code, and the two are joined, driver first, into `step1-ball.tap`. The two halves are left next to the source as `step1-ball-driver.tap` and `step1-ball-code.tap`. Then Fuse opens and loads the tape.

The examples are built the same way:

```
windows-tools\build.bat chapter-05-machine-code-games\step1-examples.bas chapter-05-machine-code-games\step1-examples.asm examples 10
```

```
tools/build.sh chapter-05-machine-code-games/step1-examples.bas chapter-05-machine-code-games/step1-examples.asm examples 10
```

When the tape has loaded, the screen clears, `PRESS A KEY TO STOP` appears at the bottom, and the ball starts to move. Press any key, and BASIC prints the steps, the frames and the frames a step.

## What it showed in Fuse

The tape was loaded in a 48K Fuse at normal speed. `step1-ball.png` is the ball on its way, with the message underneath.

The ball bounced off all four edges, as Chapter 2's did, and never went into rows 22 and 23. A key held for a fifth of a second stopped it. `step1-ball-result.png` is the result of one run:

```
STEPS  532
FRAMES 1064
FRAMES A STEP 2
```

Another run gave 632 steps in 1264 frames. With `speed` at 2, every step took exactly two frames.

pasmo and z80asm gave the same 156 bytes for `step1-ball.asm`, and the same 80 bytes of code for `step1-examples.asm`.

## The timing, against BASIC

To time Chapter 2's ball, a copy of `chapter-02-bat-and-ball/step1-ball.bas` was given one extra line to count 200 steps and read `FRAMES`, once with its `PAUSE 5` and once without it. The machine-code figure with no waiting is from "Try this" below.

| Program | Frames a step | Steps a second |
|---------|--------------:|---------------:|
| Chapter 2, step 1, with `PAUSE 5` | 7.0 (200 steps in 1401 frames) | 7.1 |
| Chapter 2, step 1, with no `PAUSE` | 2.4 (200 steps in 487 frames) | 20.5 |
| This step, `speed` 7 | 7 (94 steps in 658 frames) | 7.1 |
| This step, `speed` 2 (as shipped) | 2 (532 steps in 1064 frames) | 25 |
| This step, `speed` 1 | 1.002 (515 steps in 516 frames) | 50 |
| This step, `speed` 0, no `HALT` | 0.0166 (63342 steps in 1054 frames) | about 3000 |

The extra counting line makes the BASIC figures a little slower than the real loop, but only a little.

With no waiting, one step of the ball, the rub out, the two edge tests, the draw, the count and the key test, takes 0.0166 of a frame. A frame is 69888 T-states, so that is about 1160 T-states, including a share of the ROM's interrupt routine. Chapter 2's ball, with nothing slowing it down, took 2.4 frames: about **146 times as long**.

The speed of the game is now ours to choose. At `speed` 7 the machine-code ball goes exactly as fast as Chapter 2's did, and the CPU spends almost all of those seven frames waiting in `halt`. That spare time is what the bat, the bricks and, later, a whole Invaders game will use.

## Line by line

The driver:

- **1–4** name the variables, as in every BASIC listing in the course.
- **10** `CLEAR 49999` keeps BASIC below 50000, so the code is safe there.
- **20–40** set the colours, clear the screen, and load the code that follows on the tape.
- **50** clears the screen again, to black paper and white ink, which is the ball's colour.
- **60** sets `speed` to 2 HALTs a step.
- **70** prints the message in the lower screen, out of the ball's way.
- **80** zeroes `FRAMES`, as in Chapter 3.
- **90** runs the ball. BASIC waits here until the code returns.
- **100–120** read `FRAMES`, twice if its high byte changed while it was read.
- **130** reads the step count, low byte first.
- **140–170** print the result.
- **180** waits until the key is let go, so it does not type a keyword into the editor when the program ends.

The machine code:

- **`speed` to `dc`** are the parameter bytes, 50000 to 50006. `flags` names the system variable `FLAGS`.
- **`start`** clears the step count, clears bit 5 of `FLAGS` so an old key press does not count, and draws the ball where it is.
- **`loop` to `wait`** do `speed` `halt`s, or none if `speed` is 0. `and a` sets the zero flag when A is 0, as in Chapter 3.
- **`move`** rubs the ball out by drawing `blank` over it.
- **The row.** HL points at `dr`. A is the row plus the step. If that is 0 to 21, it is used. If not, `dr` is turned round with `neg`, and the row plus the new step is used instead. That is Chapter 2's lines 70, 80 and 110.
- **The column.** The same, with `dc` and `cp 32`: Chapter 2's lines 90, 100 and 120.
- **`ld de,ball` / `call put`** draw the ball in its new cell: Chapter 2's line 40.
- **`ld hl,(steps)` to `ld (steps),hl`** add one to the count. There is no `inc (nn)` for a pair, so it goes through HL.
- **`bit 5,(hl)` / `jr z,loop`** go round again until a key is pressed. Then `ret` goes back to BASIC, to line 100. That is Chapter 2's `GO TO 40`, with a way out.
- **`put`** finds the cell with `cell`, then copies eight bytes from DE down it with `inc h`.
- **`cell`** builds `010TT000` in H and `RRRCCCCC` in L.
- **`ball` and `blank`** are the two graphics.

If the ball hits a corner, both tests fail, both steps are turned round, and the ball comes back the way it came, as in Chapter 2.

## Limitations you will notice

- **It rubs out whatever was under it.** `put` writes eight bytes over the cell, and rubbing out writes eight zeros. Anything else in that cell is lost. `step1-ball-holes.png` shows a second run started with `GO TO 70` and no `CLS`: the ball has bitten holes out of the last run's figures. The game draws nothing else on its rows yet, so it does not matter here. Saving and restoring what is under a moving object is part of Chapter 6.
- **It moves a whole cell at a time.** Eight pixels a step, as in Chapter 2. That is deliberate for now, so the two versions can be compared. Moving by pixels comes later in the chapter.
- **The colour is whatever the cell already had.** `put` does not touch the attributes, so the ball takes the colour of the screen under it. Step 3 will read the attributes to find the bricks.
- **The step count goes up to 65535.** With `speed` 0, the ball does about 60 steps a frame and the count wraps round to 0 after about 22 seconds, so stop it sooner than that.
- **Any key stops it, including the ones a game would use.** The next step reads the keys properly, with `IN`, and keeps the bat's keys for the bat.

## Try this

Each of these was tried in Fuse. Stop the ball with a key first, then type the line and press ENTER. `GO TO 70` runs the ball again without reloading, from where it stopped. `CLS` clears the last result, so the ball does not bite holes in it.

- Slow it to Chapter 2's pace: `POKE 50000,7: CLS : GO TO 70`. It went at 7 frames a step, the speed of the BASIC ball with its `PAUSE 5`.
- Speed it up: `POKE 50000,1: CLS : GO TO 70`. One step a frame, 50 cells a second. A run gave 515 steps in 516 frames.
- Take the brakes off: `POKE 50000,0: CLS : GO TO 70`, and stop it within twenty seconds. There is no `halt`, so the ball moves about 60 times a frame, and the picture catches it wherever it happens to be, often half drawn or half rubbed out: `step1-ball-nohalt.png` shows only a few lines of it. Two runs gave 63342 steps in 1054 frames, and 28864 in 481: 0.0166 of a frame a step both times.
- Start it up and to the left, as Chapter 2's "Try this" did: `POKE 50005,255: POKE 50006,255: CLS : GO TO 70`.
- Leave a trail. In `step1-ball.asm`, put a `;` in front of the `call put` after `move:`, so the ball is never rubbed out, and build it again. The screen fills with balls in a chequer pattern. A diagonal step changes the row and the column by one each, so the ball only ever visits half the cells, the ones where row plus column is odd, or even, as it was at the start.
- Make your own ball. Change the eight numbers after `ball:`, for example to `24,60,126,255,255,126,60,24`, a diamond, and build it again.
