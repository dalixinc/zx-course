# Chapter 5, step 7 — The Invaders base

This is the first step of Part B, the machine-code twin of Chapter 4. Chapter 4's step 1 put the base on row 21, a green UDG, and moved it with O and P read by `INKEY$`. This step does the same in machine code: the same eight bytes for the graphic, the same row and the same colour, moved one column at a time.

What is new is how the keys are read. Step 2 read one half-row with `IN`, and showed that `IN` sees every key in it at once, where `INKEY$` sees one. An Invaders game needs more than one half-row: O and P to move, and in step 8 Space to fire, while O or P is held. This step reads three half-rows and packs the keys it wants into one byte, one bit each, so the game can test any of them, or any two together, with one instruction. Q, on a third half-row, stops the game, since Space now belongs to the shot.

Chapter 4's base took **2.4 frames a move** in BASIC, timed with P held all the way across. This step's base moves on a beat: **2.00 frames a move** as shipped, **1.004** with a move every frame, and with the `halt` taken out a pass with a move in it took **0.0192 of a frame**, about 125 times as quick as BASIC. Reading all the game's keys takes 150 T-states; one `INKEY$` in BASIC took about 100 times that.

Every program here was assembled with pasmo, cross-checked against z80asm, and run in a 48K emulator before it was shown.

## The new instructions and ideas

The small examples are in `step7-examples.asm`, with a BASIC driver, `step7-examples.bas`. It shows three readings of the keyboard over and over while you hold keys, with `INKEY$` beside them, and when Q is held it times them. `step7-examples-keys.png` is its screen with O, P and Space held; `step7-examples.png` is the screen at the end, with the times.

### IN A,(254) with more than one half-row

In step 2, A held one half-row, a byte with a single 0 bit. The hardware does not insist on one. Every 0 bit in the top byte of the port chooses its half-row, and all the chosen half-rows answer together: a key held in any of them pulls its bit to 0.

```
        ld a,(half)     ; A = the half-rows: one 0 bit for each
        in a,(254)      ; every chosen half-row answers at once
        cpl             ; 1 = held
        and 31          ; keep the five key bits
```

| A | Binary | Half-rows read |
|----:|----------|----------------|
| 0 | 00000000 | all eight |
| 95 | 01011111 | 127 and 223: Space, Sym Shift, M, N, B and P, O, I, U, Y |
| 223 | 11011111 | P, O, I, U, Y only, as in step 2 |

The instruction is the same `IN A,(n)` as in step 2, `DB` n, 2 bytes and 11 T-states. Example 1 in `step7-examples.asm` is the code above, at 50100. In Fuse, with P held, A = 0 gave `00001`, and so did A = 95. With O alone, both gave `00010`. With O, P and Space held, both gave `00011`: P and Space are both bit 0 of their half-rows, so they land on the same bit and cannot be told apart.

That is what a read of several half-rows is for: a quick "is any key down?", with A = 0. It is no good for telling the keys apart. For that the game reads the half-rows one at a time.

### RLCA — rotate A left

```
        rlca            ; A = A rotated left by one bit
```

`rlca` moves every bit of A one place to the left. Bit 7 goes round to bit 0, and into the carry flag too. It is the mirror of `rrca`, which step 1 used to build a screen address.

| Instruction | Bytes (hex) | Bytes (decimal) | T-states |
|-------------|-------------|-----------------|---------:|
| `RLCA` | `07` | 7 | 4 |
| `RRCA` | `0F` | 15 | 4 |
| `ADD A,A` | `87` | 135 | 4 |

On a byte whose top bit is 0, `rlca` and `add a,a` give the same answer, A times 2. `rkeys`, below, uses both: `add a,a` twice moves Space from bit 0 to bit 2, and `rlca` three times moves Q from bit 0 to bit 3. Either would do in both places; the listing has one of each so that both are seen. In Fuse, with Q held, example 2 gave the mask `1000`: bit 3, after three `rlca`s.

### One byte for every key: rkeys

`rkeys` reads the three half-rows the game uses, keeps the one or two keys it wants from each, and moves them to their own bits:

```
rkeys:  ld a,223        ; half-row P, O, I, U, Y
        in a,(254)      ; bit 0 is P, bit 1 is O; 0 means held
        cpl             ; now 1 means held
        and 3           ; keep P and O: bits 0 and 1 already
        ld c,a
        ld a,127        ; half-row Space, Sym Shift, M, N, B
        in a,(254)
        cpl
        and 1           ; Space is bit 0
        add a,a
        add a,a         ; move it to bit 2
        or c
        ld c,a
        ld a,251        ; half-row Q, W, E, R, T
        in a,(254)
        cpl
        and 1           ; Q is bit 0
        rlca
        rlca
        rlca            ; move it to bit 3
        or c
        ret
```

| Bit | Key | Half-row | Name in the listing |
|----:|-----|---------:|---------------------|
| 0 | P | 223 | `kright` (1) |
| 1 | O | 223 | `kleft` (2) |
| 2 | Space | 127 | `kfire` (4) |
| 3 | Q | 251 | `kquit` (8) |

| Part | T-states |
|------|---------:|
| P and O: `ld a,n`, `in`, `cpl`, `and n`, `ld c,a` | 33 |
| Space: the same, two `add a,a`, `or c`, `ld c,a` | 45 |
| Q: the same, three `rlca`, `or c`, `ret` | 55 |
| `call rkeys` | 17 |
| Total | 150 |

The answer is a byte with a 1 for each key held. The game can test one key with `bit`, or keep the movement keys with `and kright+kleft` and compare: 1 is P alone, 2 is O alone, 3 is both, 0 is neither. Example 2, at 50200, calls `rkeys` and gives the mask back in BC. In Fuse, with P held the driver showed `0001`, with O `0010`, with Space `0100`, with P and Space `0101`, with O, P and Space `0111`, and with Q `1000`. `INKEY$` on the same screens gave `"p"`, `"o"`, `" "`, `""`, `""` and `"q"`: with two or three keys down it gave nothing (`step7-examples-keys.png` is the one with three).

Caps Shift is on half-row 254, which `rkeys` does not read, so it makes no difference. Chapter 4 had to test for `"o"` and `"O"`; this step does not.

### How long a look at the keys takes

Example 3, at 50300, waits for a frame with `halt` and then calls `rkeys` 10000 times. The driver times it with `FRAMES`, and times BASIC's `INKEY$` the same way, 500 times in a `FOR` loop, less 500 passes of an empty `FOR` loop.

| What | Measured in Fuse | Each |
|------|-----------------:|-----:|
| 10000 calls of `rkeys`, in a loop | 27 frames | 188 T-states |
| 500 empty `FOR` passes in BASIC | 174 frames | 0.35 frames |
| 500 `LET K$=INKEY$` in the loop | 290 frames | 0.232 frames more, 16200 T-states |
| 500 `LET K=USR 50200` in the loop | 275 frames | 0.202 frames more |

The loop around `rkeys` adds 26 T-states, so the count says 176 a pass, 25.2 frames for 10000. The extra 1.8 frames are most likely the wait at the first `halt`, up to a frame, and the ROM's own interrupt routine, which runs 50 times a second inside the count. One `INKEY$` costs about 100 times one `rkeys`. Calling `rkeys` from BASIC with `USR` is hardly quicker than `INKEY$`: nearly all of the 0.202 frames is BASIC getting to the code and back.

### Both keys at once

```
        call rkeys      ; A = the keys held, one bit each
        bit 3,a         ; Q?
        ret nz          ; yes: back to BASIC
        and kright+kleft ; keep only P and O
        cp kright       ; only P?
        jr z,right
        cp kleft        ; only O?
        jr nz,loop      ; neither, or both: the base stays put
```

Chapter 4's base could not see both keys held, because `INKEY$` gave `""` for them, so the base stopped. This one sees both, and chooses to stop too: P and O cancel. The choice is in the code now, where it was in the hardware before. In Fuse, with O and P held together for two seconds, the base did not move (`step7-base-both.png`).

### The base: Chapter 4's UDG, and a green row

The eight bytes at `base` are the ones Chapter 4 poked into UDG A, from its `DATA` lines 990 and 995: `24,24,24,126,255,255,255,255`. `put`, from step 1, copies them into the cell. The colour is not drawn with the graphic. `start` sets all 32 attributes of row 21 to 4, green ink on black paper, once, and from then on the base can be drawn anywhere on the row and is green.

```
        ld hl,22528+baserow*32 ; the attribute of row 21, column 0
        ld b,32         ; 32 cells
grow:   ld (hl),green   ; green ink on black paper
        inc hl
        djnz grow
```

`22528+baserow*32` is worked out by the assembler, 23200. Chapter 4 printed the base with `INK 4` each time it moved it.

## The listing

The machine code, `step7-base.asm`. It is a new file, not step 6's: the bat-and-ball game stays as it was. `put` and `cell` are step 1's.

```
; step7-base.asm - Chapter 5, step 7
; The Invaders base: the twin of Chapter 4, step 1.
; The base is Chapter 4's UDG A, eight bytes copied into a cell on row
; 21, in green. O moves it left and P right, one column at a time, on a
; beat of bspeed frames. The keys are read with IN, all of them on every
; look, so O and P held together are seen as both (and the base stays
; put), and a key from another half-row, Q, can be read beside them.
; Q returns to BASIC. Space is kept for the shot, in step 8.
;
; BASIC can set or read these bytes at the start of the code:
;   50000        halts   HALTs per pass of the loop; 0 means do not wait
;   50001        bspeed  passes per look at the keys, 1 to 255
;   50002-50003  moves   times the base has moved
;   50004-50005  passes  passes of the loop
;   50006        x       the base's column, 0 to 31
;   50007        ptime   passes until the next look at the keys
;
; Entry point:
;   RANDOMIZE USR 50008  start
;
; Build:  tools/build.sh chapter-05-machine-code-games/step7-base.bas chapter-05-machine-code-games/step7-base.asm base 10

        org 50000

halts:  db 1            ; 50000: HALTs per pass
bspeed: db 2            ; 50001: passes per look at the keys
moves:  dw 0            ; 50002: base moves
passes: dw 0            ; 50004: passes of the loop
x:      db 15           ; 50006: the base's column
ptime:  db 1            ; 50007: passes to the next key look

baserow: equ 21         ; the base's row
green:  equ 4           ; INK 4, PAPER 0: the base's attribute
kright: equ 1           ; the bits rkeys gives back: P,
kleft:  equ 2           ; O,
kfire:  equ 4           ; Space,
kquit:  equ 8           ; and Q

; start: clear the counts, colour row 21 green, draw the base, then loop.

start:  ld hl,0
        ld (moves),hl
        ld (passes),hl  ; no moves or passes yet

        ld hl,22528+baserow*32 ; the attribute of row 21, column 0
        ld b,32         ; 32 cells
grow:   ld (hl),green   ; green ink on black paper
        inc hl
        djnz grow

        ld a,(x)
        ld c,a
        ld b,baserow
        ld de,base
        call put        ; draw the base

; The game loop: once a frame, unless halts says otherwise.

loop:   ld a,(halts)    ; A = HALTs to do
        and a           ; is it 0?
        jr z,go         ; yes: do not wait
        ld b,a
wait:   halt            ; wait for the next frame
        djnz wait

go:     ld hl,(passes)
        inc hl
        ld (passes),hl  ; one more pass
        ld hl,ptime
        dec (hl)        ; one pass fewer to the next key look
        jr nz,loop      ; not yet
        ld a,(bspeed)
        ld (hl),a       ; start counting again
        call rkeys      ; A = the keys held, one bit each
        bit 3,a         ; Q?
        ret nz          ; yes: back to BASIC
        and kright+kleft ; keep only P and O
        cp kright       ; only P?
        jr z,right
        cp kleft        ; only O?
        jr nz,loop      ; neither, or both: the base stays put
        call left
        jr loop
right:  call goright
        jr loop

; rkeys: read every key the game uses, in one go, and give back one
; bit for each that is held: bit 0 P, bit 1 O, bit 2 Space, bit 3 Q.
; Changes A and C.

rkeys:  ld a,223        ; half-row P, O, I, U, Y
        in a,(254)      ; bit 0 is P, bit 1 is O; 0 means held
        cpl             ; now 1 means held
        and 3           ; keep P and O: bits 0 and 1 already
        ld c,a
        ld a,127        ; half-row Space, Sym Shift, M, N, B
        in a,(254)
        cpl
        and 1           ; Space is bit 0
        add a,a
        add a,a         ; move it to bit 2
        or c
        ld c,a
        ld a,251        ; half-row Q, W, E, R, T
        in a,(254)
        cpl
        and 1           ; Q is bit 0
        rlca
        rlca
        rlca            ; move it to bit 3
        or c
        ret

; left: move the base one column left, if it can go. Changes A, B, C,
; DE, HL.

left:   ld a,(x)
        and a           ; already at column 0?
        ret z           ; yes
        ld c,a
        ld b,baserow
        ld de,blank
        call put        ; rub it out
        ld hl,x
        dec (hl)        ; one column left
        jr redraw

; goright: the same, to the right.

goright: ld a,(x)
        cp 31           ; already at column 31?
        ret z
        ld c,a
        ld b,baserow
        ld de,blank
        call put
        ld hl,x
        inc (hl)        ; one column right

redraw: ld c,(hl)       ; C = the new column
        ld b,baserow
        ld de,base
        call put        ; draw the base there
        ld hl,(moves)
        inc hl
        ld (moves),hl   ; one more move
        ret

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

; The graphics. The base is Chapter 4's UDG A, from its DATA line 990
; and 995.

base:   db 24,24,24,126,255,255,255,255
blank:  db 0,0,0,0,0,0,0,0

        end
```

It is 222 bytes, 50000 to 50221. pasmo's listing puts `start` at 50008, `loop` at 50039, `rkeys` at 50092, `left` at 50123, `goright` at 50143, `redraw` at 50162, `put` at 50179, `cell` at 50191 and `base` at 50206.

The BASIC driver, `step7-base.bas`. The entry point is 50008. After the game it shows the frames, the moves and the passes.

```
1 REM H=FRAMES high byte
2 REM L=FRAMES low byte
3 REM F=frames the program ran for
4 REM M=moves of the base
5 REM N=passes of the loop
10 CLEAR 49999
20 BORDER 0: PAPER 0: INK 7: CLS
30 PRINT "LOADING THE CODE"
40 LOAD ""CODE
50 CLS
60 POKE 50000,1: POKE 50001,2: POKE 50006,15
70 PRINT #0;"O LEFT, P RIGHT, Q STOPS"
80 POKE 23672,0: POKE 23673,0: POKE 23674,0
90 RANDOMIZE USR 50008
100 LET H=PEEK 23673: LET L=PEEK 23672
110 IF PEEK 23673<>H THEN GO TO 100
120 LET F=L+256*H
130 LET M=PEEK 50002+256*PEEK 50003
140 LET N=PEEK 50004+256*PEEK 50005
150 CLS
160 PRINT "FRAMES ";F
170 PRINT "MOVES  ";M
180 PRINT "PASSES ";N
190 IF N>0 THEN PRINT "FRAMES A PASS ";F/N
200 IF M>0 THEN PRINT "FRAMES A MOVE ";F/M
210 IF INKEY$<>"" THEN GO TO 210
```

## Building and running

On Windows, from the course folder:

```
windows-tools\build.bat chapter-05-machine-code-games\step7-base.bas chapter-05-machine-code-games\step7-base.asm base 10
```

On Linux:

```
tools/build.sh chapter-05-machine-code-games/step7-base.bas chapter-05-machine-code-games/step7-base.asm base 10
```

The examples (the driver's first line after its notes is 20, `CLEAR`):

```
windows-tools\build.bat chapter-05-machine-code-games\step7-examples.bas chapter-05-machine-code-games\step7-examples.asm examples 20
```

```
tools/build.sh chapter-05-machine-code-games/step7-examples.bas chapter-05-machine-code-games/step7-examples.asm examples 20
```

The screen is black, with the green base in the middle of row 21 and `O LEFT, P RIGHT, Q STOPS` below it. O and P move it. Q stops and shows the counts.

## What it showed in Fuse

The tape was loaded in a 48K Fuse at normal speed.

- **The base.** It came up green, in column 15 of row 21 (`step7-base.png`), the same shape as Chapter 4's.
- **O, P, both, and Caps Shift.** O held for 0.3 seconds took the base 8 columns left, to column 7. O and P held together for 2 seconds left it there (`step7-base-both.png`). P held for 3 seconds took it to column 31, where it stopped at the edge. Caps Shift and O together moved it left again, 10 columns in 0.4 seconds.
- **The counts.** Q then stopped it, and BASIC showed `FRAMES 595`, `MOVES 42` and `PASSES 595` (`step7-base-result.png`): 8 + 24 + 10 moves, and exactly one pass a frame.
- **The keys.** The examples gave the results in the sections above, with O, P and Space read together and `INKEY$` giving `""` for them.

pasmo and z80asm gave the same 222 bytes for `step7-base.asm`, and the same non-zero bytes for `step7-examples.asm`: pasmo pads the gaps between its `org`s with zeros, z80asm does not.

## The timing, against BASIC

Chapter 4 timed its base with a copy that pretended P was held, from column 0 to column 31. This step's timing copy does the same with a routine, `auto`, in place of `rkeys`: it holds P until the base reaches column 31, then O back to column 0, and gives back Q after a set number of moves. It is in the test copies only, not in `step7-base.asm`. The base starts at column 0.

| Program | Frames a move | Moves a second |
|---------|--------------:|---------------:|
| Chapter 4, step 1 (31 moves in 74 frames) | 2.4 | 21 |
| Chapter 4, step 1, with its delay | 3.8 | 13 |
| This step, as shipped (`bspeed` 2): 248 moves in 497 frames | 2.004 | 25 |
| This step, `bspeed` 1: 248 moves in 249 frames | 1.004 | 50 |
| This step, no `halt`: 6200 moves in 119 frames | 0.0192 | about 2600 |

The shipped speed is a choice, not a limit: one move every second frame is a little quicker than Chapter 4's base, and the same speed as the bat in Part A. With nothing to wait for, a pass with a move in it took 0.0192 of a frame, 1340 T-states, and Chapter 4's step took about 125 times as long. A pass with no key held, with `halts` 0 and the real `rkeys`, took 0.00464 of a frame (32761 passes in 152 frames), about 324 T-states.

The odd frame in 497 and in 249 is the last look at the keys, the one at which `auto` gives back Q: the first move is on the first pass, and a pass is a frame.

## Line by line

- **`halts`, `bspeed`** at 50000 and 50001, as in Part A: HALTs a pass, and passes a look at the keys.
- **`moves`, `passes`** at 50002 and 50004, words, for the timings.
- **`x`** at 50006, the base's column, and **`ptime`** at 50007, the countdown to the next look at the keys.
- **`baserow`, `green`** and the four key bits are `equ`s, so they cost no bytes.
- **`start`** clears the counts, colours row 21 and draws the base at `x`.
- **`loop`** waits for `halts` frames, counts the pass, and every `bspeed` passes calls `rkeys`.
- **`bit 3,a` / `ret nz`**: Q returns to BASIC.
- **`and kright+kleft`, `cp kright`, `cp kleft`**: P alone goes right, O alone left; neither or both, nothing.
- **`rkeys`** is described above.
- **`left`, `goright`** stop at columns 0 and 31, rub out the base with `blank`, change `x`, and share **`redraw`**, which draws it again and counts the move.
- **`put`, `cell`** are step 1's.
- **`base`, `blank`** are the graphic and eight zeros.

## Limitations you will notice

- **A column at a time.** The base moves by whole cells, 8 pixels, as Chapter 4's did. Moving by pixels is step 15.
- **A very short tap can be missed.** The keys are looked at once every `bspeed` passes, every second frame as shipped, so a key held for less than that may fall between two looks.
- **BREAK does nothing while it runs.** The machine code does not test it, so Q is the only way out.
- **The whole of row 21 is green.** Anything else drawn on that row will be green too. In Chapter 4 nothing else is.
- **Space does nothing yet.** `rkeys` reads it, for step 8.

## Try this

Each of these was tried in Fuse.

- A quicker, yellow base: change `green` to 6 and build it again, and make line 60 `POKE 50000,1: POKE 50001,1: POKE 50006,0`, a move every frame from column 0. The base came up yellow, P held for half a second took it to column 31, and Q showed `MOVES 31`.
- No waiting: `POKE 50000,0: POKE 50001,1` in line 60, and press Q after a second or two with no other key. BASIC showed about 32761 passes in 152 frames, 0.0046 of a frame each. Do not wait long: `passes` is a word, and it goes round to 0 after 65535, about 5 seconds.
- In the examples, watch the second line, A = 95, while you hold Space, then P as well: it shows `00001` both times, since the two keys share bit 0, while the mask line goes from `0100` to `0101`.
