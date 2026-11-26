# Chapter 5, step 5 — Sound from the speaker

Chapter 2's step 6 gave every bounce a short `BEEP`: the bat low, a wall high, a brick between, and a lower note for a miss. This step is its twin. The game is step 4's, with the same four events, and the same four pitches.

The new part is the speaker. In BASIC, `BEEP` is one statement. In machine code there is no such thing: you turn the speaker on and off yourself, with `OUT`, at the rate that gives the note you want. This lesson shows how that is done, how long the note keeps the game waiting, and one mistake that turns the border black and is easy to make.

Chapter 2's step 6 took **11.03 frames a step**, timed for this lesson, with its beeps included. This step's loop takes **3.00 frames a step** as shipped and **1.003** with the ball moving every frame, with its sounds included. A note in this step stalls the game while it plays, as `BEEP` does, but each one lasts 0.4 to 0.6 of a frame, about half as long as Chapter 2's, and it plays in the part of the frame after the loop's `halt`, so the loop keeps its beat.

Every program here was assembled with pasmo, cross-checked against z80asm, and run in a 48K emulator before it was shown. The pitches were checked by recording the emulator's sound and measuring it.

## The new instructions and ideas

The small examples are in `step5-examples.asm`, with a BASIC driver, `step5-examples.bas`, that plays them. `step5-examples.png` is its screen at the end. `step5-examples-border.png` is the same run stopped in the middle, with the border still red after a note.

### What the speaker is

The Spectrum's speaker is driven by one bit of one port. Port 254, the same one that `in a,(254)` reads the keyboard from in step 2, takes a byte when you write to it with `out`:

| Bit | What it does |
|----:|--------------|
| 0 to 2 | The border colour, 0 to 7 |
| 3 | The MIC socket, the tape output. The code leaves it 0 |
| 4 | The speaker: 1 pushes the cone out, 0 lets it back |

The speaker makes no sound while the bit stays the same. A sound is the *change*: every time the bit goes from 0 to 1, or from 1 to 0, the cone moves, and you hear a click. A note is a string of clicks at an even rate. If bit 4 goes on and off 262 times in a second, the clicks run together as a note of 262 hertz, middle C.

So a note takes four things: a byte with bit 4 set, a byte with bit 4 clear, a wait between them, and a count of how many times to do it. That is the whole of `sound`.

### OUT (n),A — write to a port

```
        ld a,16         ; bit 4 on
        out (254),a     ; the speaker cone goes out
```

| Instruction | Bytes (hex) | Bytes (decimal) | T-states |
|-------------|-------------|-----------------|----------|
| `OUT (n),A` | `D3` n | 211, n | 11 |

It is the partner of step 2's `in a,(n)`. It puts the byte in A on port n. Here n is 254 (`FE`), and A is whatever you want the port to hold. The byte is written whole, all eight bits at once. There is no way to change only bit 4: if you write 16, bits 0 to 2 are 0 as well, and that makes the border black. That is the next section.

### Keeping the border: the system variable BORDCR

The border colour is bits 0 to 2 of this port, and BASIC's `BORDER 2` writes it. When `sound` writes the port, it writes the border bits too, and if they are wrong, the border changes with the click.

The ROM keeps a copy of the border colour in the system variable `BORDCR`, at 23624, which is the attribute for the lower part of the screen: the border colour is in bits 3 to 5, the paper bits, so it is the colour times 8. To get the colour into bits 0 to 2, where the port wants it:

```
        ld a,(bordcr)   ; the border colour is in bits 3 to 5
        rrca
        rrca
        rrca            ; now in bits 0 to 2
        and 7
        ld c,a          ; C = the border colour, speaker off
```

`rrca`, from Chapter 3, step 5, rotates A right one place: three of them move bits 3 to 5 down to 0 to 2, and `and 7` throws away the rest. Then:

```
        ld a,c          ; the border colour, with bit 4 off
        or 16           ; bit 4 on
        out (254),a     ; speaker on, border as it was
```

`or 16` puts bit 4 in and leaves the other bits as they were. Writing C as it stands is the speaker off.

The mistake is to write 16 and 0, and not C with and without 16. Example 3 does it. `step5-examples.bas` runs example 2 with `BORDER 2`, and the border stays red (`step5-examples-border.png`). It then plays example 3, the same note with the border bits left at 0, and the border goes **black** and stays black (the last screen, `step5-examples.png`, taken when the program had stopped). The driver then asks `BORDCR` for the border colour, and it still says 2: the variable is what the ROM thinks the border is, and the port is what it really is. They disagree until something writes the port again, such as another `BORDER`.

### A note from a delay and a count

Each half of a cycle waits, and the wait is a loop that counts down a 16-bit number. The routine, which is `delay` in the game:

```
delay:  ld h,d
        ld l,e          ; HL = DE, the count
dloop:  dec hl          ; one less
        ld a,h
        or l            ; A = 0 only if both bytes are 0
        jr nz,dloop     ; not yet: round again
        ret
```

`dec hl` does not set the flags, so the count has to be tested the long way: `ld a,h` and `or l` give a zero result only if both H and L are 0.

| Instruction | Bytes (hex) | Bytes (decimal) | T-states |
|-------------|-------------|-----------------|----------|
| `DEC HL` | `2B` | 43 | 6 |
| `LD A,H` | `7C` | 124 | 4 |
| `OR L` | `B5` | 181 | 4 |
| `OR n` | `F6` n | 246, n | 7 |

One trip round `dloop` is 6 + 4 + 4 + 12 = **26 T-states** while it jumps (the last one, which does not jump, is 5 fewer). A cycle has two waits, so the count n makes a cycle last about 52n T-states, plus the instructions around the waits, which add up to 110 from the tables. The Spectrum 48K's Z80 runs at 3,500,000 T-states a second, so:

```
frequency = 3500000 / (52 * n + 110)
```

Example 1 and the table at the start of `step5-examples.png` show the four counts the game uses, and the frequency that formula gives:

| Note | n | Cycles | Formula | Chapter 2's `BEEP` pitch | Measured |
|------|--:|-------:|--------:|--------------------------|---------:|
| Bat | 255 | 3 | 262 Hz | 0, middle C, 261.6 Hz | 262 Hz |
| Wall | 62 | 10 | 1050 Hz | 24, 1046.5 Hz | 1053 Hz |
| Brick | 126 | 5 | 525 Hz | 12, 523.3 Hz | 526 Hz |
| Miss | 512 | 1 | 131 Hz | -12, 130.8 Hz | 131 Hz |

The last column came from recording Fuse's sound output as the driver played the notes, and finding the time between the clicks in the recording. The notes are within half a percent of Chapter 2's, which is closer than an ear can tell. Counting clicks gave 6 edges for the bat's 3 cycles, 20 for the wall's 10, 10 for the brick's 5 and 2 for the miss's 1, so the counts are what the table says.

The count of cycles sets the *length*: the bat's 3 cycles are 11.5 milliseconds, the wall's 9.5, the brick's 9.5 and the miss's 7.6. Chapter 2's notes were 0.02 seconds, 20 milliseconds, so these are about half as long. They are shorter on purpose, for the reason in the next section.

### A table of notes, and PUSH and POP

The four notes are three bytes each in a table, `sounds`: the count as a word, low byte first, and the cycles as a byte. A note number 0 to 3 picks the entry:

```
        ld c,a          ; keep the note number
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
```

`add hl,de` is the 16-bit add of Chapter 3, step 6. Note number times three, added to the start of the table, is the entry: the same way as the tables in earlier steps.

`sound` uses B, C, D, E, H, L and A, and the game's own code is in the middle of using some of them when it calls it. So `sound` saves BC, DE and HL on the stack as it starts and gets them back when it ends:

| Instruction | Bytes (hex) | Bytes (decimal) | T-states |
|-------------|-------------|-----------------|----------|
| `PUSH BC` | `C5` | 197 | 11 |
| `PUSH DE` | `D5` | 213 | 11 |
| `PUSH HL` | `E5` | 229 | 11 |
| `POP BC` | `C1` | 193 | 10 |
| `POP DE` | `D1` | 209 | 10 |
| `POP HL` | `E1` | 225 | 10 |

`push` and `pop` are Chapter 3, step 5's, and step 2 used them to keep BC across a call. A push puts a register pair on the stack and a pop takes it off again: last in, first out, so the pops are in the opposite order of the pushes. `sound` does not save A or the flags, and the comment on the routine says so: A is gone when it returns. One mistake while writing this step was exactly there. The code on a bat hit was `sub (hl)` for where the ball landed, then `call sound`, then `and a` to test the result: but A is gone by then, and the ball took the wrong side of the bat. The fix was to keep the result in E, and fetch it again after the call:

```
        ld e,a          ; E = where on the bat, 0 to 3
        ld a,nbat
        call sound      ; the bat's note (sound keeps every register)
        ld a,e
```

### A note that stops the loop

The loop in `sound` does nothing else while it plays. It is a busy wait, as `BEEP` is. For 11.5 milliseconds, the longest of the four, the ball does not move, the keys are not read, and the next frame's interrupt is waiting.

A frame is 20 milliseconds, and the loop is built so that the notes fit inside one. The loop `halt`s, and the interrupt that ends the `halt` is the start of a frame. The ball step, with its note, runs straight after it. A note of 11.5 milliseconds or less is over long before the next interrupt, so the next `halt` is waiting for an interrupt that has not yet come, and the loop keeps its beat. If a note is longer than the time to the next interrupt, the interrupt happens during the note, the ROM deals with it there, and the next `halt` waits for the one after: a frame is lost. That was measured, on both sides:

- With the notes as written, a game of 789 ball steps, 25 bat hits, 29 bricks and 31 wall bounces took 2367 frames, **3.00 a step**: the same as step 4's.
- With the ball moving every frame (`speed` 1), 1300 steps took 1304 frames, **1.003 a step**, with 37 hits and 52 bricks and the walls as well.
- With a copy whose notes were about 38 milliseconds, 501 steps took 1554 frames, **3.10 a step**. Each long note had cost the loop roughly a frame (51 frames more than 3.00 a step would have taken, in a game with 16 hits, 17 bricks and some wall bounces).

So a note this short costs nothing in a frame. A longer one does, and gets worse the more of them play. A better design, for notes that matter, would play a little of the note on each frame, from the loop, with no waiting. This step keeps the simple one.

### How `sound` is called

`sound` takes a note number in A, and the game puts one in front of every event Chapter 2 beeped at:

- **The bat**: after the hit is counted, with the note `nbat`.
- **The top edge and the side walls**: `nwall`. A wall here is any of the three edges the ball bounces from, as in Chapter 2.
- **A brick**: `nbrick`, after the brick is rubbed out.
- **A miss**: `nmiss`, when the ball has passed the bat.

The notes are named with `equ`, so the calls read as what they do (`ld a,nbat`), and the table `sounds` holds their sizes in the same order. A ball that cleared a brick on the same step as it met a wall has two notes in a row, as Chapter 2's did with two `BEEP`s: one recording of a test game had a brick note played twice, back to back, and a wall note twice. They were counted as two.

`quiet` at 50016 is a switch, 0 for sound and anything else for none, which the game checks first thing in `sound`. BASIC can set it with `POKE 50016,1`. The driver does not touch it, so the game starts with sound on.

## The listing

The machine code, `step5-sound.asm`. It is step 4's, with `quiet` added after `seed`, `sound` and `delay` and the `sounds` table added, and calls to `sound` put in at the bat, the walls, the bricks and the miss. Two `jr` instructions in `step` became `jp`, because the calls made the code between them too long for a `jr`.

```
; step5-sound.asm - Chapter 5, step 5
; Sound: the twin of Chapter 2, step 6.
; Step 4's game, with a short note on the speaker for every bounce, as
; BEEP gave in Chapter 2: the bat low (middle C), a wall higher (two
; octaves above), a brick between (one octave above), and a miss lower
; still (one octave below). The note is made by writing bit 4 of port
; 254 on and off with OUT, with the border colour kept in bits 0 to 2.
; Space returns to BASIC.
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
;
; Entry point:
;   RANDOMIZE USR 50017  start
;
; Registers:
;   B, C = the row and column of a cell, on the way into put, cell
;          and attr; the cell the ball is about to move into, in step
;   DE   = the graphic being drawn (ball, blank or solid)
;   E    = where on the bat the ball landed, 0 to 3, in step
;   HL   = a screen or attribute address; the address of a variable
;   A    = scratch
;
; Build:  tools/build.sh chapter-05-machine-code-games/step5-sound.bas chapter-05-machine-code-games/step5-sound.asm sound 10

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
quiet:  db 0            ; 50016: 0 for sound, anything else for none

batrow: equ 21          ; the bat's row
batw:   equ 4           ; the bat's width in cells
bordcr: equ 23624       ; system variable: border colour * 8, and more
nbat:   equ 0           ; the sounds: their numbers in the table sounds
nwall:  equ 1
nbrick: equ 2
nmiss:  equ 3
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
        jp c,cols       ; carry: it is, look at the column
        cp batrow       ; the bat's row?
        jr nz,top       ; no, so 255: off the top

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

It is 606 bytes, 50000 to 50605. pasmo's listing puts `start` at 50017, `loop` at 50096, `keys` at 50141, `step` at 50215, `mid` at 50286, `top` at 50294, `cols` at 50302, `miss` at 50387, `turn` at 50410, `nudge` at 50418, `rnd` at 50446, `sound` at 50463, `delay` at 50517, `sounds` at 50525, `put` at 50537, `cell` at 50549 and `attr` at 50564.

The BASIC driver, `step5-sound.bas`. It is step 4's with the entry point moved to 50017 and the border blue, so that a border damaged by the speaker would show:

```
1 REM S=ball steps taken
2 REM H=FRAMES high byte
3 REM L=FRAMES low byte
4 REM F=frames the game ran for
10 CLEAR 49999
20 BORDER 1: PAPER 0: INK 7: CLS
30 PRINT "LOADING THE CODE"
40 LOAD ""CODE
50 CLS
60 POKE 50000,1: POKE 50001,3: POKE 50002,2
62 POKE 50015,PEEK 23672
70 PRINT #0;"O LEFT, P RIGHT, SPACE STOPS"
80 POKE 23672,0: POKE 23673,0: POKE 23674,0
90 RANDOMIZE USR 50017
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
windows-tools\build.bat chapter-05-machine-code-games\step5-sound.bas chapter-05-machine-code-games\step5-sound.asm sound 10
```

On Linux:

```
tools/build.sh chapter-05-machine-code-games/step5-sound.bas chapter-05-machine-code-games/step5-sound.asm sound 10
```

The examples:

```
windows-tools\build.bat chapter-05-machine-code-games\step5-examples.bas chapter-05-machine-code-games\step5-examples.asm examples 10
```

```
tools/build.sh chapter-05-machine-code-games/step5-examples.bas chapter-05-machine-code-games/step5-examples.asm examples 10
```

The game looks the same as step 4's, with a blue border, and now it clicks. Press O and P to move the bat and Space to stop.

## What it showed in Fuse

The tape was loaded in a 48K Fuse at normal speed. To hear what it played, Fuse was run with its sound sent to a file by SDL's disk audio driver, and the file was read back: it is 44100 samples a second, and a note shows as a run of the speaker going up and down. That is how the pitches in the table were measured. Nobody listened to it in this test, so the note that "sounds right" is not a claim made here: only that the right pitches were recorded.

- **The notes.** `step5-examples.png` shows the table the driver printed, with the frequencies from the formula. The recording of that run had a note for example 1 (262 Hz, 6 edges), the four notes from the table (262, 1053, 526 and 131 Hz, with 6, 20, 10 and 2 edges), the note with `BORDER 2` (262 Hz) and the bad note (262 Hz).
- **The border.** With `BORDER 2`, a note from example 2 left the border red: `step5-examples-border.png`. After the same note from example 3, with the border bits left at 0, the border was black, with `BORDCR` still saying 2. In the game, `step5-sound.png` is a game with the border blue, and `step5-sound-result.png` is the screen after a game in which sounds had been played 85 times: the border was still blue. The sounds made no change to it.
- **The game.** `step5-sound.png` is the start. To see every kind of event without a player, a copy was built with the bat as wide as the screen, as in step 4 (`step5-sound-holes.png`, part way through, and `step5-sound-result.png`, the result): in 2367 frames it counted 25 hits and 29 bricks. A recording of that game had **25** bat notes, **28** brick notes of which one was twice as long, so **29**, and 30 wall notes of which one was twice as long, so **31**. The driver's counts and the recording agree. A game with the normal bat and no keys held had 21 misses in 1045 frames, and the recording had **21** low notes.
- **Nothing lost.** The three runs under "A note that stops the loop" gave 3.00, 1.003 and, for the long notes, 3.10 frames a step. `step5-sound-fast.png` is the 1.003 run's result.
- **Sound off.** In a copy of the driver with `POKE 50016,1`, a wide-bat game ran for 1454 frames with 485 ball steps, 14 hits and 32 bricks and recorded no notes at all. That is 2.998 frames a step.

pasmo and z80asm gave the same 606 bytes for `step5-sound.asm`, and the same 130 non-zero bytes for `step5-examples.asm`: pasmo pads the gaps between its `org`s with zeros, z80asm does not.

## The timing, against BASIC

Chapter 2's `step6-beep.bas` was timed with one extra line counting steps and a stop at 100. No key was held, so the ball missed the bat, and the beeps on each bounce and miss were all included.

| Program | Frames a step | Steps a second |
|---------|--------------:|---------------:|
| Chapter 2, step 6, with its delay and beeps | 11.03 (100 steps in 1103 frames) | 4.5 |
| This step, as shipped (`speed` 3) | 3.00 (789 steps in 2367 frames) | 16.7 |
| This step, `speed` 1 | 1.003 (1300 steps in 1304 frames) | 49.9 |
| This step, `speed` 3, notes of about 38 ms | 3.10 (501 steps in 1554 frames) | 16.1 |

This step's loop takes at least a frame for each step, because of the `halt`, so 1 is as fast as it goes. The 11 for BASIC includes the delay loop in line 140, `FOR I=1 TO 10`, and the time for the beeps.

The notes themselves, from a BASIC loop of 50 calls. This one is a less direct measure, because the BASIC loop is in it too:

| 50 times | Frames | Frames each |
|----------|-------:|------------:|
| `BEEP .02,0` | 59 | 1.18 |
| `POKE`, then a call to the bat note | 57 | 1.14 |
| `POKE`, then a call to the brick note | 53 | 1.06 |
| `POKE` alone | 22 | 0.44 |

So a bat note takes about 0.7 of a frame (57 less 22, over 50) and a brick note about 0.6, where the formula gives 0.57 and 0.48. A `BEEP .02` takes about a frame, which is its 20 milliseconds with the call to the ROM; its loop was lighter, so its overhead is not known. In machine code a note costs about half of what a `BEEP` does because it is half as long: it is not that machine code beeps faster. The notes this step plays are shorter than Chapter 2's. The reason for the machine-code game's speed is the loop around the note, not the note.

## Line by line

The parts that are new since step 4:

- **`quiet`** at 50016 is the on/off switch. The entry point moves to 50017.
- **`bordcr`, `nbat`, `nwall`, `nbrick`, `nmiss`** are constants. The note numbers are 0 to 3, the entries in `sounds`.
- **The bat**: the code that works out where on the bat the ball landed puts the answer in E, calls `sound` with `nbat`, and takes the answer back. `sound` changes A.
- **`top`** is the top edge: a wall note, then `flipr`.
- **`cols`**: the side walls ask for `nwall` after the sign of `dc` is reversed.
- **The brick** asks for `nbrick`.
- **`miss`** asks for `nmiss`.
- **`sound`** saves BC, DE and HL, leaves at once if `quiet` is not 0, finds the note's entry in `sounds`, reads the border colour from `bordcr` into C, and plays B cycles, each a write with bit 4 on, a `delay`, a write with bit 4 off and a `delay`.
- **`delay`** counts DE down in HL.
- **`sounds`** is four entries of 3 bytes: the count, then the cycles.
- Two `jr` became `jp`: after the bat's row was tested, `jp c,cols` and `jp nc,miss`, because `sound` calls pushed `cols` and `miss` out of range of `jr`.

## Limitations you will notice

- **The notes stall the game.** While a note plays, nothing else happens. It fits inside a frame here, and not more than a frame; a long tune would need a different design.
- **The pitch is a little off.** The formula gives 1050 Hz for the wall and Chapter 2's `BEEP` gives 1046.5. The formula counts T-states from the instruction tables, and it does not allow for anything that slows the Z80, such as the screen sharing memory with it. The recorded notes were within 0.7% of Chapter 2's pitches, and nearer to the formula.
- **The notes are shorter than Chapter 2's.** 8 to 11 milliseconds, against 20. They were shortened so that they are surely inside one frame, not to match anything.
- **The speaker is a square wave.** A click on and off has a harsh tone, a buzz more than a bell, and there is no volume. `BEEP` has the same tone, because it works the same way.
- **The border colour is read from `BORDCR`.** A program that writes the port to change the border without telling `BORDCR` would see its change undone, by the next note.
- **There are still no score or lives.** That is step 6.

## Try this

Each of these was tried in Fuse.

- Turn the sound off: in the driver, add `POKE 50016,1` to line 62. The game plays silently, as in the test above.
- Longer notes: change `db 3` for the bat in `sounds` to `db 10`, `db 10` for the wall to `db 40` and `db 5` for the brick to `db 20`. In a wide-bat test copy the frames a step went from 3.00 to 3.10.
- Another border: change line 20 of the driver to `BORDER 2` and build it again. After a game with 24 misses and all their notes, the border was still red.
- Break the border: in `sound`, replace the four lines from `cycle:` to the first `out (254),a` with `cycle: ld a,16` and `out (254),a`, and the `ld a,c` before the second `out` with `xor a`. This is example 3's mistake in the game. Built and run with `BORDER 2`, the border was black (`step5-sound-black.png`), though the game worked as before, at 2.997 frames a step.
