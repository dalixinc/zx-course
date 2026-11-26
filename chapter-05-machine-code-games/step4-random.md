# Chapter 5, step 4 — A little randomness

Step 3's ball has a problem that Chapter 2 found in its own step 3. Every step changes the row and the column by one each, so row plus column stays odd, or stays even, for ever, and half the bricks can never be hit. Chapter 2, step 5 fixed it with a little chance: when the ball bounces off the middle of the bat or off a brick, it sometimes goes straight up or down for a while (`DX` becomes 0), and a ball that is already going straight is always sent off to one side. This step is its twin.

The bat's two end cells still steer, with no chance in them, as in Chapter 2. A hit on a brick or on the two middle cells of the bat is the one that asks for a nudge. The top edge does not.

The new part is the random numbers. BASIC has `RND`. The Z80 has nothing, so we have to make our own, and there is more than one way to do it. This lesson looks at three, measures them, and says plainly what each is good for.

Chapter 2's loop with no delay took **5.1 frames a step**, timed for this lesson (200 steps in 1018 frames, with the count started after the wall was drawn). A pass of this step's loop takes **0.0217 of a frame** when no nudge is called, and a nudge adds about 330 T-states, by the instruction tables, about 0.005 of a frame.

Every program here was assembled with pasmo, cross-checked against z80asm, and run in a 48K emulator before it was shown.

## The new instructions and ideas

The small examples are in `step4-examples.asm`, with a BASIC driver, `step4-examples.bas`, that runs each random number source and prints what it gives. `step4-examples.png` is its first screen and `step4-examples-sources.png` its second.

### Where do random numbers come from?

A computer cannot be random by itself. It can only do the same sum the same way each time. A "random" number on the Spectrum is one of three things: a number from some part of the machine that changes in a way the program cannot predict, a number from a sum that jumbles the last number, or a mixture. Chapter 2's `RND` is the second kind, a sum on a seed kept in the system variable `SEED` (23670), and `RANDOMIZE` sets that seed from `FRAMES`.

We have three choices.

**1. The R register.** The Z80 has a "refresh" register, R, that its own memory-refresh logic adds one to after every instruction it fetches. `ld a,r` reads it. It is cheap, and it looks random when read from BASIC. Example 2 gave, called from BASIC twelve times: 110 113 55 6 94 45 98 49 90 10 5 8 11. But it is a counter, not a random number. Bit 7 never changes, and the low seven bits just count instructions. Example 4 reads it sixteen times in a tight machine-code loop, and the answers are 52 57 62 67 72 77 82 87 92 97 102 107 112 117 122 127: add five each time, because the loop is five instruction fetches round (`ld a,r` is two fetches, because it starts with a prefix byte). Read the same way from a loop that runs the same code every pass, R is as predictable as a clock. It is only unpredictable when you read it at a time that depends on you, such as the moment you press a key.

**2. FRAMES.** The low byte of `FRAMES`, 23672, adds one every fiftieth of a second. Example 3, called from BASIC twelve times in a row, gave 72 73 74 75 76 77 78 79 80 81 82: it changes only once per frame, so many reads in one frame give the same number, and the changes are just counting. It is a clock. It is a fair way to choose a starting point, because you cannot say when the player will press the key, and a poor way to get a stream of numbers.

**3. A small generator on a seed.** The standard answer for a small machine is a *linear feedback shift register*, an LFSR. Keep a byte. To get the next number, shift the byte right one place. If the bit that fell out was a 1, XOR the byte with a fixed pattern, called the taps. That is all. With the right taps, a byte of 8 bits goes through every value from 1 to 255, once each, in a jumbled order, and then repeats. 0 is not allowed, because 0 shifted is 0 for ever.

The taps used here are 184, binary `10111000`. They are the usual ones for 8 bits, and the example confirms that they work: starting from 1, the value came back to 1 after exactly **255** calls.

The first 8 values from seed 1 were `184 92 46 23 179 225 200 100`. You can see that it is a recipe, not magic: 184 shifted right is 92, and 92 shifted right is 46.

So what does this step use? The LFSR, started from a seed that comes from the clock: BASIC pokes the low byte of `FRAMES` into the `seed` byte, just before it clears `FRAMES` to zero for the timing, and the code uses R instead if `seed` is 0. The seed depends on how long the tape took to load and how long you took to press the keys. After that the numbers come from the sum, and they do not depend on timing at all. It is not "truly random", and it does not need to be: the game only needs the nudge to be unpredictable enough that the player cannot count on it.

### A first version that was not good enough

The first version called the LFSR shift once per random number. It worked, and it was biased, and finding out why is worth the space.

To measure it, a test copy of the code counted the nudges. A copy with a bat the width of the screen, so the ball never misses, ran with `nudge` counting how often it chose "straight" when the ball was going sideways. The chance was meant to be 51 in 256, about 19.9%. The measured figure was 258 out of 1718, **15.0%**: five standard errors too low.

The reason is in the sequence. Shifting right once halves the number: 92 follows 184, then 46, then 23. A small number, under 51, is followed by half that number, which is also under 51, unless the XOR with the taps made it big again. Example 5 shows it. Over one whole period of 255 numbers, 50 are under 51, as there should be, and the driver counts how many of those 50 are followed by another number under 51:

| Shifts per number | Under 51 | Followed by another under 51 |
|------------------:|---------:|-----------------------------:|
| 1 | 50 | 25 |
| 8 | 50 | 9 |

If the numbers were independent, about 10 of the 50 would be followed by another small one. With one shift it is 25, so the small numbers come in runs and the nudges that choose "straight" are spread unevenly. With eight shifts, the whole byte has been shifted out and replaced, so the next number shares no bits with the last, and 9 is about right.

So `rnd` shifts eight times, with `djnz` counting them. It costs about 330 T-states instead of about 80, a price worth paying once per bounce. The same test then gave 359 out of 1889, **19.0%**, and 533 out of 2779, **19.2%**, which is close to 19.9%. Left against right, when the ball was sent off sideways, was 168 to 191 and 247 to 286: about 47% to 53%, fair enough for a nudge. Changing 51 to 128 gave 748 out of 1498, 49.9%, as it should.

The lesson in it: a generator that passes the check "all values appear once" can still be biased in the way you use it. Measure it in the use you put it to.

### LD A,R — read the refresh register

```
        ld a,r          ; no: use the R register
```

| Instruction | Bytes (hex) | Bytes (decimal) | T-states |
|-------------|-------------|-----------------|----------|
| `LD A,R` | `ED 5F` | 237, 95 | 9 |
| `LD R,A` | `ED 4F` | 237, 79 | 9 |

Bits 0 to 6 count up by one after each instruction fetched (or two for an instruction with a prefix, like this one). Bit 7 stays as it was loaded, and `ld r,a` is the only way to change it. The code uses `ld a,r` just once, when BASIC gave no seed, with `or 1` after it so that the seed can never be 0.

### SRL, JR NC and XOR n — the shift and the taps

`srl a`, from Chapter 3, step 5, shifts every bit right, puts a 0 in at the left, and the bit that falls out of bit 0 goes into the carry. `jr nc,e` jumps when the carry is clear, the partner of `jr c,e` from step 1. `xor n` is the partner of Chapter 3's `and n` and `or n`: each bit of A is flipped where n has a 1.

```
        srl a           ; bit 0 falls into the carry
        jr nc,rnd2      ; it was 0: nothing more to do
        xor 184         ; it was 1: XOR in the taps, 10111000
```

| Instruction | Bytes (hex) | Bytes (decimal) | T-states |
|-------------|-------------|-----------------|----------|
| `SRL A` | `CB 3F` | 203, 63 | 8 |
| `JR NC,e` | `30` e | 48, e | 12 if taken, 7 if not |
| `XOR n` | `EE` n | 238, n | 7 |

`xor` with a number sets the flags and clears the carry. That does not matter here, because the next thing is `djnz`, which does not look at the flags.

### CP with a constant: how likely?

`cp 51` leaves the carry set when A is 0 to 50. If A is a random byte from 0 to 255, that is 51 chances in 256, or 19.9%: Chapter 2's `RND>=Q` with `Q=0.2`. To change the chance, change the number: `cp 128` is one in two. Step 1's edge test and step 2's bat test used `cp` for a range check; this is the same instruction asking "is the number small?".

### AND 1, ADD A,A and DEC A: 0 or 1 to -1 or +1

Chapter 2 wrote `LET DX=2*INT(RND*2)-1`. Here a random byte becomes 255 or 1 in three instructions:

```
        and 1           ; A = 0 or 1
        add a,a         ; A = 0 or 2
        dec a           ; A = 255 (-1) or 1
```

Step 1 showed 255 as the byte for -1. `and 1` keeps one bit, double it, take one off. It is the same sum as BASIC's, on a byte.

### One subroutine for the bounce

The bounce is `dr = -dr`, and it is now needed in three places, the top edge, the middle of the bat and a brick, so it is a subroutine, `turn`, with a `ret`:

```
turn:   ld hl,dr
        ld a,(hl)
        neg
        ld (hl),a
        ret
```

Chapter 2's BASIC could not do that cheaply, and its `GO SUB` line was avoided in the loop for speed. Here a `call` and a `ret` cost 27 T-states, nothing.

### Decisions, and how the code is laid out

The routine `nudge` is Chapter 2's lines 430 to 450:

```
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
```

Where it is called from:

- A **brick**: after `turn`, as Chapter 2's line 420 goes to 430. The code then goes back to `cols`, as before.
- The **middle two cells of the bat**: the same, as `mid`. The end cells jump over it, straight to `flipr`.

A step that is going straight, with `dc` at 0, still takes the column test: `col + 0` is always on the screen.

## The listing

The machine code, `step4-random.asm`. It is step 3's, with `seed` added after `ptime`, the start of `start` choosing a seed, `turn`, `nudge` and `rnd` added, and the bat and brick bounces calling them. The parameters up to `ptime` are where they were in step 3.

```
; step4-random.asm - Chapter 5, step 4
; A little randomness: the twin of Chapter 2, step 5.
; Step 3's bat, ball and bricks. When the ball bounces off the middle of
; the bat or off a brick, there is about a one in five chance that it
; goes straight up or down for a while (dc = 0), and a ball that is
; already going straight is always sent off to one side or the other.
; The random numbers come from an 8-bit LFSR kept in the byte seed.
; Space returns to BASIC.
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
;   50015        seed    the random number generator's state, 1 to 255;
;                        0 means pick one from the R register at start
;
; Entry point:
;   RANDOMIZE USR 50016  start
;
; Registers:
;   B, C = the row and column of a cell, on the way into put, cell
;          and attr; the cell the ball is about to move into, in step
;   DE   = the graphic being drawn (ball, blank or solid)
;   E    = where on the bat the ball landed, 0 to 3, in step
;   HL   = a screen or attribute address; the address of a variable
;   A    = scratch
;
; Build:  tools/build.sh chapter-05-machine-code-games/step4-random.bas chapter-05-machine-code-games/step4-random.asm random 10

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
seed:   db 0            ; 50015: the random number state

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

        ld a,(seed)     ; has BASIC given us a seed?
        and a
        jr nz,seeded    ; yes
        ld a,r          ; no: use the R register
        or 1            ; and make sure it is not 0
        ld (seed),a
seeded:

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

flipr:  call turn       ; dr = -dr: bounce

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
        ld hl,5*256+5
        ld (col),hl     ; col = 5, row = 5
        ld hl,1*256+1
        ld (dc),hl      ; dc = 1, dr = 1: down and to the right
        jr draw

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

It is 503 bytes, 50000 to 50502. pasmo's listing puts `start` at 50016, `loop` at 50095, `keys` at 50140, `step` at 50214, `mid` at 50277, `cols` at 50288, `miss` at 50363, `turn` at 50381, `nudge` at 50389, `rnd` at 50417, `put` at 50434, `cell` at 50446 and `attr` at 50461.

The BASIC driver, `step4-random.bas`, is step 3's, with the entry point changed to 50016 and one new line, 62, which pokes the seed:

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
62 POKE 50015,PEEK 23672
70 PRINT #0;"O LEFT, P RIGHT, SPACE STOPS"
80 POKE 23672,0: POKE 23673,0: POKE 23674,0
90 RANDOMIZE USR 50016
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
windows-tools\build.bat chapter-05-machine-code-games\step4-random.bas chapter-05-machine-code-games\step4-random.asm random 10
```

On Linux:

```
tools/build.sh chapter-05-machine-code-games/step4-random.bas chapter-05-machine-code-games/step4-random.asm random 10
```

The examples:

```
windows-tools\build.bat chapter-05-machine-code-games\step4-examples.bas chapter-05-machine-code-games\step4-examples.asm examples 10
```

```
tools/build.sh chapter-05-machine-code-games/step4-examples.bas chapter-05-machine-code-games/step4-examples.asm examples 10
```

The game looks the same as step 3 on the screen, and plays the same way. The difference is in the way the ball goes after a bounce.

## What it showed in Fuse

The tape was loaded in a 48K Fuse at normal speed.

- **The generator.** `step4-examples.png` shows the LFSR from seed 1: 255 calls round, and the first eight values as given above. The numbers were checked against the same sum in Python, which gave the same first eight values, the same 255, and the same counts of 50 and 25 and 50 and 9. `step4-examples-sources.png` shows the R and FRAMES readings quoted above.
- **The ball.** The game starts as step 3's did (`step4-random.png`). To see the random numbers at work without a player, a copy of the code was built with a bat as wide as the screen, so that the ball never missed. Step 3 built the same way stopped at **48** bricks, exactly half the wall, after 4509 frames (90 seconds), which is the parity fault, seen. This step's copy had cleared 75 bricks when it was stopped after 2051 frames (41 seconds), and still 75 when another run was stopped after 4518 frames (90 seconds), so both kinds of cell were being hit. `step4-random-holes.png` is the wall part way through the first run and `step4-random-result.png` its result.
- **The chances.** The counts quoted above, 15.0% with one shift, 19.0% and 19.2% with eight, and 49.9% for `cp 128`, came from test copies of the code that counted the nudges in memory, 60000 on. The test copies are not in the course files.
- **The nudge off.** With `ret` as the first instruction of `nudge`, the wide-bat copy had 48 bricks after 2755 frames, as step 3's did.

pasmo and z80asm gave the same 503 bytes for `step4-random.asm`, and the same 62 bytes of code for `step4-examples.asm`.

## The timing, against BASIC

Chapter 2's `step5-random.bas` was timed as before, with one extra line counting steps, once with its delay and once without it. No key was held, so the ball missed the bat each time, and no nudge was called in either.

| Program | Frames a step | Steps a second |
|---------|--------------:|---------------:|
| Chapter 2, step 5, with its delay | 44.1 (50 steps in 2205 frames) | 1.1 |
| Chapter 2, step 5, with no delay | 5.1 (200 steps in 1018 frames) | 9.8 |
| This step, as shipped (`speed` 3) | 3 | 16.7 |
| This step, no `HALT`, ball and keys every pass | 0.0217 (23541 steps in 510 frames) | about 2300 |

The last line was typed in after a game, as in steps 2 and 3. The pass with no nudge is as fast as step 3's, 0.0216, because the extra code only runs when a nudge is called, and in this run none was. Chapter 2's loop with no delay is about **235 times as long**.

*A correction.* This lesson first gave 5.9 frames a step (1173 frames for 200 steps), 49.6 with the delay (2479 for 50), and 270 times. Those runs counted from the start of the program, so they included drawing the wall. The figures above were taken again with the count started after the wall was drawn. The cost of a nudge was not timed in Fuse. Adding up the instruction times gives about 330 T-states for `rnd` with its call, and about 60 more for the rest of `nudge`, about 0.005 of a frame: a nudge costs about a fifth of a step of the ball.

## Line by line

The parts that are new since step 3:

- **`seed`** at 50015 is the generator's state. The entry point moves to 50016.
- **`start`** gives `seed` a value from R if BASIC left it 0.
- **`mid`**: a hit on a middle cell of the bat. The end cells go to `flipr`. `mid` turns the ball round and calls `nudge`, and goes to `cols`.
- **`flipr`** is only the top edge and the two end cells now. It is a `call turn`, and the code runs on into `cols`.
- **The brick** does `call turn` and `call nudge`, and goes back to `cols`.
- **`turn`** is the bounce.
- **`nudge`** is Chapter 2's lines 430 to 450.
- **`rnd`** shifts the seed eight times, with the taps, and gives it back in A.

## Limitations you will notice

- **It is not random.** `rnd` repeats every 255 numbers, and every number depends on the one before. The ball's path is a sum of the bat, the keys and the generator, and for a given seed and the same keys at the same times, it is always the same. The wide-bat test shows it. After 75 bricks the ball went round a repeating path that never reached the other 21: the count was 75 at 2051 frames and still 75 at 4518. Against a person, with a bat they move, that will not happen, but the game is not secretly random.
- **The seed is the time the tape took to load.** On a real machine that varies. In an emulator with a fixed tape speed, the same tape gives the same seed every time, so two runs from loading look alike. The seed is set again every time the program is run from line 10, but `GO TO 70` keeps the numbers coming from where they were.
- **The chance is the same for the bat and the bricks.** Chapter 2's was too.
- **There is still no sound, score or lives.** Those are steps 5 and 6.

## Try this

Each of these was tried in Fuse.

- Make the nudge happen half the time: change `cp 51` to `cp 128` and build it again. In a copy that counted, 748 of 1498 went straight, 49.9%.
- Switch the nudge off: put `ret` on a line of its own as the first instruction of `nudge`, and build it again. The ball goes back to step 3's way, and with a bat the width of the screen it had 48 bricks after 2755 frames,.
- Run the examples twice. The R and FRAMES readings on the second screen are different each time: a second run gave 9 14 19 24 29 34 39 44 49 54 59 64 69 74 79 84 from the tight loop, which still adds five each time, and 62 63 64 64 65 66 67 68 69 70 71 72 from FRAMES. The first screen, the LFSR, is the same every time, because it is a sum on a seed.
- Start from another seed. Change line 62 of the driver to `POKE 50015,100` and build it again. Every game now starts the generator at 100.
