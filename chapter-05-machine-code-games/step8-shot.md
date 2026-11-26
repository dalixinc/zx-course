# Chapter 5, step 8 — One shot

Chapter 4's step 2 gave the base a shot: Space fires it from the row above the base, it climbs a row at a time to the top of the screen, and only one can be in flight. `INKEY$` made that awkward. It reports one key, so Space could not be seen while O or P was held, and the player had to stop moving to fire. This step is its twin in machine code, and the key byte from step 7 removes the problem: Space is a bit of its own, read on the same look as O and P.

The shot also gets its own beat. In Chapter 4 the base and the shot both moved once a pass of the BASIC loop, so each slowed the other: 2.9 frames a step for either alone, 3.9 for both together. Here the loop runs once a frame, and the shot and the keys each count their own passes, so the shot's speed and the base's are chosen separately and do not change when both are moving.

Chapter 4's shot took **2.9 frames a step**, 60 frames to climb 21 rows. This one, as shipped, takes **one frame a step**, 21 frames for the climb, and the base still moves at **2.00 frames a move** while it does. With the `halt` taken out a pass with a shot step in it took **0.0248 of a frame**, and a pass with a base move and a shot step **0.0389**, about 100 times as quick as Chapter 4's 3.9.

Every program here was assembled with pasmo, cross-checked against z80asm, and run in a 48K emulator before it was shown.

## The new instructions and ideas

The small examples are in `step8-examples.asm`, with a BASIC driver, `step8-examples.bas`, that runs each one on the values 0, 1, 254, 255 and 128 and prints a table. `step8-examples.png` is its screen, and every result below is copied from it.

### INC A as a test for 255

The shot's row is 0 to 20 while it is in flight, and 255 when there is none. 255 is a byte that cannot be a row, the same idea as Chapter 4's `Y=-1`. The loop tests it with `inc a`:

```
        ld a,(srow)
        inc a           ; 255 becomes 0: is there no shot?
        jr z,keys       ; none: on to the keys
```

255 + 1 is 256, which does not fit in a byte, so A becomes 0 and the zero flag is set. Any other value gives a result that is not 0. The value in A is spoiled, but the loop does not need it. `cp 255` does the same job and keeps A.

| Instruction | Bytes (hex) | Bytes (decimal) | T-states | Zero flag set when |
|-------------|-------------|-----------------|---------:|--------------------|
| `INC A` | `3C` | 60 | 4 | A was 255 |
| `CP 255` | `FE FF` | 254, 255 | 7 | A is 255 |
| `AND A` | `A7` | 167 | 4 | A is 0 |

Examples 1 and 2 give 1 in BC if `val` is 255 and 0 if not. In Fuse both gave 1 for 255 and 0 for 0, 1, 254 and 128. `inc a` saves a byte and 3 T-states, once a pass and again in `fire`. That is small, and the point is the idiom: it is common in Spectrum code, and it is worth being able to read.

`inc a` does not change the carry flag, so it cannot be used to test for a carry out of the top. Here only the zero flag matters.

### CALL cc,nn — call only if

```
        bit 2,a         ; Space?
        call nz,fire    ; yes: fire, if no shot is in flight
```

`call nz,fire` calls `fire` only if the zero flag is clear, and otherwise goes straight on to the next instruction. It is the call that matches `jr nz` and `ret nz`. There is one for each flag: `z`, `nz`, `c`, `nc`, and four more for parity and sign.

| Instruction | Bytes (hex) | Bytes (decimal) | T-states |
|-------------|-------------|-----------------|---------:|
| `CALL NZ,nn` | `C4` nn nn | 196, low, high | 17 if it calls, 10 if not |
| `CALL Z,nn` | `CC` nn nn | 204, low, high | 17 if it calls, 10 if not |
| `CALL nn` | `CD` nn nn | 205, low, high | 17 |

Example 3 tests `val` with `and a` and calls `bump`, which adds 1 to `count`, with `call nz,bump`. Starting from a count of 0, the five values gave counts of 0, 1, 2, 3 and 4: no call for 0, one call for each of the others.

`fire` has to give the loop back its keys, since after it the loop tests O and P from the same byte. So it starts with `push af` and ends with `pop af`, as `status` did in step 6.

### Two beats in one loop

The loop goes round once a frame. Two countdowns decide what it does on each pass:

```
        ld hl,stime
        dec (hl)        ; one pass fewer to the shot's next step
        jr nz,keys      ; not yet
        ld a,(sspeed)
        ld (hl),a       ; start counting again
        call sstep      ; move the shot up a row
```

and the same with `ptime` and `bspeed` for the keys. This is the bat's beat from Part A, step 2, used twice. As shipped, `sspeed` is 1 and `bspeed` is 2: the shot climbs a row every frame, and the base moves a column every second frame. Neither depends on the other, or on how long anything else takes, as long as one pass fits in a frame.

### The shot: Chapter 4's UDG B, coloured as it goes

The shot's graphic is Chapter 4's UDG B, `0,24,24,24,24,24,24,0`. It flies through rows 0 to 20, which are white ink as BASIC's `CLS` left them, so `sdraw` sets the attribute of each cell it draws in to 6, yellow ink on black paper, with step 3's `attr`, before it copies the graphic in. Rubbing it out copies `blank` and leaves the attribute yellow, which cannot be seen on an empty cell.

`sstep` rubs out the shot, and if it was on row 0, it sets `srow` to 255 and stops; otherwise it takes 1 from `srow` and draws it again. So a shot fired on row 20 takes 21 steps: 20 to climb to row 0, and one to leave.

## The listing

The machine code, `step8-shot.asm`. It is step 7's, with `sspeed`, `ssteps`, `shots`, `stime`, `srow` and `scol` added to the parameters, the shot's beat in the loop, the fire test after the keys, and `fire`, `sstep`, `sdraw`, step 3's `attr` and the shot graphic added.

```
; step8-shot.asm - Chapter 5, step 8
; The base and one shot: the twin of Chapter 4, step 2.
; It is step 7's base, with a shot fired by Space. The shot is Chapter
; 4's UDG B, drawn in yellow. It starts on row 20, above the base, and
; climbs a row every sspeed frames until it leaves the top of the
; screen; then Space can fire again. Only one shot is in flight at a
; time. The keys are all read at once, so Space fires while O or P is
; held, and the base keeps moving. Q returns to BASIC.
;
; BASIC can set or read these bytes at the start of the code:
;   50000        halts   HALTs per pass of the loop; 0 means do not wait
;   50001        bspeed  passes per look at the keys, 1 to 255
;   50002        sspeed  passes per step of the shot, 1 to 255
;   50003-50004  moves   times the base has moved
;   50005-50006  passes  passes of the loop
;   50007-50008  ssteps  steps the shot has taken
;   50009        shots   shots fired
;   50010        x       the base's column, 0 to 31
;   50011        ptime   passes until the next look at the keys
;   50012        stime   passes until the shot's next step
;   50013        srow    the shot's row, or 255 for no shot
;   50014        scol    the shot's column
;
; Entry point:
;   RANDOMIZE USR 50015  start
;
; Build:  tools/build.sh chapter-05-machine-code-games/step8-shot.bas chapter-05-machine-code-games/step8-shot.asm shot 10

        org 50000

halts:  db 1            ; 50000: HALTs per pass
bspeed: db 2            ; 50001: passes per look at the keys
sspeed: db 1            ; 50002: passes per step of the shot
moves:  dw 0            ; 50003: base moves
passes: dw 0            ; 50005: passes of the loop
ssteps: dw 0            ; 50007: shot steps
shots:  db 0            ; 50009: shots fired
x:      db 15           ; 50010: the base's column
ptime:  db 1            ; 50011: passes to the next key look
stime:  db 1            ; 50012: passes to the shot's next step
srow:   db 255          ; 50013: the shot's row; 255 = no shot
scol:   db 0            ; 50014: the shot's column

baserow: equ 21         ; the base's row
green:  equ 4           ; INK 4, PAPER 0: the base's attribute
yellow: equ 6           ; INK 6, PAPER 0: the shot's attribute
kright: equ 1           ; the bits rkeys gives back: P,
kleft:  equ 2           ; O,
kfire:  equ 4           ; Space,
kquit:  equ 8           ; and Q

; start: clear the counts, colour row 21 green, draw the base, then loop.

start:  ld hl,0
        ld (moves),hl
        ld (passes),hl
        ld (ssteps),hl  ; no moves, passes or shot steps yet
        xor a
        ld (shots),a    ; no shots
        dec a
        ld (srow),a     ; 255: no shot in flight

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

; The game loop: once a frame, unless halts says otherwise. The shot
; and the keys each have their own beat.

loop:   ld a,(halts)    ; A = HALTs to do
        and a           ; is it 0?
        jr z,go         ; yes: do not wait
        ld b,a
wait:   halt            ; wait for the next frame
        djnz wait

go:     ld hl,(passes)
        inc hl
        ld (passes),hl  ; one more pass

        ld a,(srow)
        inc a           ; 255 becomes 0: is there no shot?
        jr z,keys       ; none: on to the keys
        ld hl,stime
        dec (hl)        ; one pass fewer to the shot's next step
        jr nz,keys      ; not yet
        ld a,(sspeed)
        ld (hl),a       ; start counting again
        call sstep      ; move the shot up a row

keys:   ld hl,ptime
        dec (hl)        ; one pass fewer to the next key look
        jr nz,loop      ; not yet
        ld a,(bspeed)
        ld (hl),a       ; start counting again
        call rkeys      ; A = the keys held, one bit each
        bit 3,a         ; Q?
        ret nz          ; yes: back to BASIC
        bit 2,a         ; Space?
        call nz,fire    ; yes: fire, if no shot is in flight
        and kright+kleft ; keep only P and O
        cp kright       ; only P?
        jr z,right
        cp kleft        ; only O?
        jr nz,loop      ; neither, or both: the base stays put
        call left
        jr loop
right:  call goright
        jr loop

; fire: start a shot on row 20, above the base, unless one is in flight.
; Keeps A, the keys, for the loop. Changes B, C, DE, HL.

fire:   push af         ; keep the keys
        ld a,(srow)
        inc a           ; 255: no shot in flight?
        jr nz,nofire    ; there is one: Space does nothing
        ld a,(x)
        ld (scol),a     ; the shot's column is the base's
        ld a,baserow-1
        ld (srow),a     ; row 20
        ld a,(sspeed)
        ld (stime),a    ; its first step is a full beat away
        ld hl,shots
        inc (hl)        ; one more shot
        call sdraw      ; draw it
nofire: pop af          ; the keys again
        ret

; sstep: rub out the shot and move it up a row; on row 0 it goes off
; the top and there is no shot any more. Changes A, B, C, DE, HL.

sstep:  ld hl,(ssteps)
        inc hl
        ld (ssteps),hl  ; one more shot step
        ld a,(srow)
        ld b,a
        ld a,(scol)
        ld c,a
        ld de,blank
        call put        ; rub it out
        ld hl,srow
        ld a,(hl)
        and a           ; was it on row 0?
        jr z,sgone      ; yes: it has left the screen
        dec (hl)        ; one row up
        jr sdraw        ; and draw it there
sgone:  ld (hl),255     ; no shot now
        ret

; sdraw: draw the shot at srow, scol, in yellow. Changes A, B, C, DE, HL.

sdraw:  ld a,(srow)
        ld b,a
        ld a,(scol)
        ld c,a
        call attr       ; HL = the attribute of the cell
        ld (hl),yellow  ; yellow ink on black paper
        ld de,shot
        jp put          ; draw it, and put returns

; rkeys: read every key the game uses, in one go, and give back one
; bit for each that is held: bit 0 P, bit 1 O, bit 2 Space, bit 3 Q.
; Step 7's. Changes A and C.

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

; left: move the base one column left, if it can go. Step 7's.
; Changes A, B, C, DE, HL.

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

; attr: HL = the attribute address of the cell at row B, column C:
; 010110TT RRRCCCCC, which is 22528 + 32*row + column. Step 3's.
; Changes A.

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

; The graphics, Chapter 4's UDGs A and B, from its DATA lines 990 to
; 997.

base:   db 24,24,24,126,255,255,255,255
shot:   db 0,24,24,24,24,24,24,0
blank:  db 0,0,0,0,0,0,0,0

        end
```

It is 376 bytes, 50000 to 50375. pasmo's listing puts `start` at 50015, `loop` at 50057, `keys` at 50093, `fire` at 50134, `sstep` at 50167, `sdraw` at 50201, `rkeys` at 50220, `left` at 50251, `goright` at 50271, `put` at 50307, `cell` at 50319, `attr` at 50334, `base` at 50352 and `shot` at 50360.

The BASIC driver, `step8-shot.bas`. The entry point is 50015. After the game it shows the frames, the moves, the passes, the shot steps and the shots.

```
1 REM H=FRAMES high byte
2 REM L=FRAMES low byte
3 REM F=frames the program ran for
4 REM M=moves of the base
5 REM N=passes of the loop
6 REM S=steps of the shot
7 REM T=shots fired
10 CLEAR 49999
20 BORDER 0: PAPER 0: INK 7: CLS
30 PRINT "LOADING THE CODE"
40 LOAD ""CODE
50 CLS
60 POKE 50000,1: POKE 50001,2: POKE 50002,1: POKE 50010,15
70 PRINT #0;"O LEFT, P RIGHT, SPACE FIRES, Q STOPS"
80 POKE 23672,0: POKE 23673,0: POKE 23674,0
90 RANDOMIZE USR 50015
100 LET H=PEEK 23673: LET L=PEEK 23672
110 IF PEEK 23673<>H THEN GO TO 100
120 LET F=L+256*H
130 LET M=PEEK 50003+256*PEEK 50004
140 LET N=PEEK 50005+256*PEEK 50006
150 LET S=PEEK 50007+256*PEEK 50008
160 LET T=PEEK 50009
170 CLS
180 PRINT "FRAMES ";F
190 PRINT "MOVES  ";M
200 PRINT "PASSES ";N
210 PRINT "SHOT STEPS ";S
220 PRINT "SHOTS  ";T
230 IF N>0 THEN PRINT "FRAMES A PASS ";F/N
240 IF M>0 THEN PRINT "FRAMES A MOVE ";F/M
250 IF S>0 THEN PRINT "FRAMES A SHOT STEP ";F/S
260 IF INKEY$<>"" THEN GO TO 260
```

## Building and running

On Windows, from the course folder:

```
windows-tools\build.bat chapter-05-machine-code-games\step8-shot.bas chapter-05-machine-code-games\step8-shot.asm shot 10
```

On Linux:

```
tools/build.sh chapter-05-machine-code-games/step8-shot.bas chapter-05-machine-code-games/step8-shot.asm shot 10
```

The examples (the driver's first line after its notes is 20, `CLEAR`):

```
windows-tools\build.bat chapter-05-machine-code-games\step8-examples.bas chapter-05-machine-code-games\step8-examples.asm examples 20
```

```
tools/build.sh chapter-05-machine-code-games/step8-examples.bas chapter-05-machine-code-games/step8-examples.asm examples 20
```

The screen is step 7's, with `O LEFT, P RIGHT, SPACE FIRES, Q STOPS` below the base, over two lines. Space fires; O and P move the base, with or without Space; Q stops and shows the counts.

## What it showed in Fuse

The tape was loaded in a 48K Fuse at normal speed.

- **A shot.** Space fired a yellow shot from above the base, in column 15, and it climbed to the top (`step8-shot.png`, a quarter of a second after the key).
- **Firing while moving.** With P and Space held together, the base moved right and fired as it went; each shot kept the column it was fired from, and the base went on past it (`step8-shot-moving.png`). O and Space did the same to the left.
- **The counts.** After those, Q gave `FRAMES 448`, `PASSES 447`, `MOVES 34`, `SHOTS 6` and `SHOT STEPS 126`, 21 steps a shot (`step8-shot-result.png`).
- **One shot at a time.** Three taps of Space about 0.35 seconds apart gave `SHOTS 2` and 42 steps: a shot takes about 0.42 seconds, so the second tap came while the first shot was still climbing, and did nothing. Space held for 2 seconds gave `SHOTS 5`, a new shot each time the last one had gone.
- **The examples** gave the tables in the sections above (`step8-examples.png`).

pasmo and z80asm gave the same 376 bytes for `step8-shot.asm`, and the same non-zero bytes for `step8-examples.asm`.

## The timing, against BASIC

Chapter 4 timed its shot from row 20 to its rubbing out at the top, 21 steps, with the base still; then the base with no shot, P held all the way across; then both together. This step's timing copies use step 7's `auto` routine in place of `rkeys`, with Space added: it holds P to column 31 and then O back to 0, or not at all, holds Space or not, and gives back Q after a set number of base moves or shot steps. It is in the test copies only.

| What | Chapter 4, step 2 | This step, as shipped | This step, no `halt` |
|------|------------------:|----------------------:|---------------------:|
| The shot alone, a step | 2.9 (21 in 60 frames) | 1.00 (21 steps on 21 passes; the run was 23 passes, 24 frames) | 0.0248 (2100 steps in 2101 passes, 52 frames) |
| The base alone, a move | 2.9 (31 in 90 frames) | 2.008 (248 in 498 frames) | |
| The base with the shot flying, a move | 3.9 (31 in 121 frames) | 2.008 (248 in 498 frames, 474 shot steps in the same time) | 0.0389 (6200 passes, each with a move and a shot step, in 241 frames) |

In Chapter 4, adding the shot to the loop slowed the base from 2.4 frames a move to 2.9, even with no shot in flight, and to 3.9 with one. Here the base took 2.008 frames a move with no shot, as in step 7, and 2.008 with a shot flying all the time: the same number, because the pass still fits in a frame. The shot's 21 steps took 21 passes; the two passes more in the count are the look at the keys that fired it and the one that stopped the run.

With no `halt`, a pass with a shot step and a look at the keys took 0.0248 of a frame, about 1730 T-states, and Chapter 4 took about 117 times as long for its shot step. A pass with both a base move and a shot step took 0.0389, about 2720 T-states, against Chapter 4's 3.9: 100 times as long. The frame has 69888 T-states, so this pass uses 4% of it, and the other 96% is what is left for the invaders.

## Line by line

- **`sspeed`** at 50002: passes a shot step. The parameters after it move up: `moves` 50003, `passes` 50005, `ssteps` 50007, `shots` 50009, `x` 50010, `ptime` 50011, then `stime` 50012, `srow` 50013 and `scol` 50014. The entry point is 50015.
- **`start`** also clears `ssteps` and `shots`, and sets `srow` to 255 with `xor a` and `dec a`.
- **The shot's beat**, after the pass count: `inc a` on `srow` skips it when there is no shot; otherwise `stime` counts down and `sstep` is called when it reaches 0.
- **`keys`**: the label for the key beat, step 7's code. After the Q test, `bit 2,a` and `call nz,fire`.
- **`fire`** keeps AF, does nothing if a shot is in flight, otherwise puts the shot on row 20 in the base's column, gives it a full beat before its first step, counts it and draws it.
- **`sstep`** counts the step, rubs the shot out, and either moves it up a row and draws it, through `sdraw`, or on row 0 sets `srow` to 255.
- **`sdraw`** sets the cell's attribute to yellow and draws the shot, ending with `jp put`.
- **`rkeys`, `left`, `goright`, `redraw`, `put`, `cell`** are step 7's; **`attr`** is step 3's.

## Limitations you will notice

- **One shot.** Space does nothing while a shot is in flight, as in Chapter 4.
- **It hits nothing.** There is nothing to hit yet; the invaders are step 9, and hitting them step 11.
- **Fire is looked at on the key beat.** Space is read with O and P, every second frame, so a new shot can wait up to a frame longer than it need.
- **The shot leaves its colour behind.** Rows 0 to 20 turn yellow where a shot has been. With nothing else drawn there it cannot be seen. When the invaders arrive they will set their own colours.
- **Holding Space fires again and again.** A new shot starts as soon as the last has gone, as Chapter 4's did.

## Try this

Each of these was tried in Fuse.

- A slower shot: `POKE 50002,2` in line 60. In the timing copy the shot's 21 steps took 2 frames each, and the run 43 passes and 44 frames; the climb takes 0.84 seconds, against Chapter 4's 1.2.
- Fire as fast as you can: hold Space and count. 2 seconds gave `SHOTS 5`.
- Hold O, P and Space together. The base stays put, since O and P cancel, and the shots still go: 1.5 seconds gave `SHOTS 4` and `MOVES 0`.
