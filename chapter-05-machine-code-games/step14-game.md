# Chapter 5, step 14 — The whole game

Chapter 4's step 8 turned the pieces into a game. Each invader shot scored 30 on the top row, 20 on the two middle rows and 10 on the bottom row. There were 3 lives: a bomb on the base took one, and the next base came on in column 15. A cleared wave started the next one at once, a row lower and a beat faster, with the score and the lives carried on and the shields whole again. The game ended when the last life went or when the invaders landed. A game-over screen gave the reason, the score and the wave, and offered another game. `SCORE`, `WAVE` and `LIVES` sat on row 0, and every event had a short `BEEP`. In BASIC an idle pass took 6.5 frames, a march cycle 106, and each 0.02-second `BEEP` stopped the game for 1.2 frames.

This step is its twin, and it finishes the machine-code game. The design keeps the split the chapter started with. **The code plays the game, and BASIC runs everything around it.** `start` sets up a whole new game, so BASIC only has to call it. When the game ends the code returns to BASIC with a byte, `over`, that says why. BASIC then shows the game-over screen and waits for a key, which it can afford to do slowly. The status line is printed by the code itself, from the ROM's character set, and it owns row 0. That fixes the row-0 flaw of steps 10 to 13, where `THEY HAVE LANDED`, `WAVE CLEARED` and `YOU ARE HIT` were all printed with the ROM on row 0, over one another. Now nothing else is printed on row 0, and the messages are on the game-over screen.

The frame budget ran out in this step, as step 13 warned it might. With a score to print and a click to play on every hit, a test copy ran a pass over its frame: 245 frames for 244 passes from row 1, and 48 for 46 on the shield rows. So the fallback the chapter has promised since step 10 is applied: **the march ripples down the block, one row a pass**, as Chapter 4's did. With it, the same tests took exactly one frame a pass.

Every program here was assembled with pasmo, cross-checked against z80asm, and run in a 48K emulator before it was shown.

## The new instructions and ideas

There are no new instructions. The new ideas are:

- printing a number in a fixed width, from a table of powers of ten;
- a status line printed by our own code;
- a game loop with two ways out;
- a wave's settings worked out from its number;
- clicks short enough to play in the middle of a pass;
- the ripple.

The examples are in `step14-examples.asm`, with a BASIC driver, `step14-examples.bas`. `step14-examples.png` is its screen, and the results below are copied from it.

### A number in a fixed width: pdec

Step 6 printed the score with Chapter 3's `pnum`, through the ROM, leaving off the leading zeros. That cost 0.10 of a frame for a number, and step 6 noted that a number that got shorter would leave old digits behind it. `pdec` prints exactly A digits, with zeros in front, so a number always covers the last one. It draws each digit with our own print, the eight-byte copy of step 6. It also walks a table of powers of ten instead of calling a routine five times:

```
pd1:    push de         ; keep the place in the table
        ex de,hl        ; HL = the place, DE = the number
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a          ; HL = this power of ten
        ex de,hl        ; HL = the number, DE = the power
        ld a,'0'-1      ; the digit, one below "0"
pd2:    inc a           ; one more
        and a           ; clear the carry for SBC
        sbc hl,de       ; take the power away
        jr nc,pd2       ; not below 0 yet: again
        add hl,de       ; once too often: put it back
```

The table is `tens: dw 10000,1000,100,10,1`. For fewer than five digits, `pdec` starts that many entries from the end, `2 * (5 - A)` bytes in. The score is printed in 5 digits, the wave in 2 and the lives in 1. Example 1 printed these, each at the left of its row, with BASIC's own print of the number beside it:

| Number | Digits | Printed |
|-------:|-------:|---------|
| 0 | 5 | 00000 |
| 640 | 5 | 00640 |
| 65535 | 5 | 65535 |
| 7 | 2 | 07 |
| 3 | 1 | 3 |

A whole score, 5 digits, took 0.05 of a frame (100 in 5 frames), half the cost of step 6's through the ROM.

### The status line: ptext and pchar

`pchar` is step 6's own print, one character: its 8 bytes are at `15360 + 8 * code` in the ROM, and `put` copies them into the cell. Step 6 read the address from the system variable `CHARS`; the game never changes it, so here it is named, `font`. `ptext` walks a string that ends with 255, as `pstr` did, but calls `pchar` and moves one column on itself, so it needs no `AT`. Example 2 printed `ROM LETTERS: ABC abc 0123 !?*` on row 0 with it.

`status` prints the whole line once, at the start of each wave: the words, then the numbers, in Chapter 4's places, `SCORE` at column 0, `WAVE` at 13 and `LIVES` at 22. That takes 0.4 of a frame (10 in 4 frames). After that, only the number that changed is printed again: `pscore` on a hit, `plives` when a base is lost.

### Two ways out of the loop

The loop has always ended with `ret` when Q is held, back to BASIC. Now there are two more:

- **The base's beat.** When the last base has been down for `rlen` passes, it sets `over` to 1 and returns.
- **The march beat.** After a march step, if `land` has set `over` to 2, it returns.

The loop is not a subroutine. `start` runs straight into it, so a `ret` anywhere in the loop's own code goes back to BASIC. The driver reads `over` at line 95. If it is 0, Q was pressed, and it prints the counts as before. Otherwise it plays Chapter 4's four `BEEP`s, prints the game-over screen with the reason, the score and the wave, waits for a key, and goes back to line 50 for a new game. `start` sets every byte a game needs again, so nothing from the last game is left.

### Each wave from its number

Chapter 4 set `BY=WV` with a cap of 8, and `W=9-WV` with a floor of 2. `newwave` does the same from `wave`, with two bytes BASIC can set for the first wave, `bfirst` and `mfirst`:

- The block's top row is `bfirst + wave - 1`, but no lower than row 8. If `bfirst` itself is lower than 8, that row is kept.
- The passes per march step start at `mfirst` and go down by 3 for each wave after the first. They stop once 3 less would be under 4.

Example 3 runs the same sums for waves 1 to 10, with `bfirst` 1 and `mfirst` 25:

| Wave | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|------|--:|--:|--:|--:|--:|--:|--:|--:|--:|---:|
| Top row | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 8 | 8 |
| Passes a step | 25 | 22 | 19 | 16 | 13 | 10 | 7 | 4 | 4 | 4 |

With `bfirst` 12, wave 3 gave row 12: a test start that is already low is kept low.

`newwave` then sets every invader alive and clears rows 1 to 20, one pixel line of 32 bytes at a time, leaving the base's row alone. It draws the shields and the block, and prints the status line. All of that takes 3.8 frames (10 in 38). It happens only between waves, where Chapter 4 cleared the screen with `CLS`.

### Clicks that fit in a pass

Step 5's `sound` routine plays a note for a whole number of cycles of a square wave, and the game stops while it plays. Step 5's notes were about a hundredth of a second, half a frame. That is too long to play in the middle of a pass with a march step in it. Each cycle takes `52 * n + 110` T-states for a delay count n, so the clicks here are only one to three cycles of a high note:

| Sound | Delay | Cycles | About | Measured, each |
|-------|------:|-------:|-------|---------------:|
| 0 fire | 20 | 3 | 3000 Hz, 1 ms | 0.06 frame |
| 1 hit | 40 | 2 | 1600 Hz, 1.3 ms | 0.07 frame |
| 2 drop | 80 | 1 | 820 Hz, 1.2 ms | 0.06 frame |
| 3 base lost | 400 | 30 | 168 Hz, 0.18 s | |
| 4, 5, 6 new wave | 255, 202, 170 | 5, 7, 8 | C, E, G, 0.02 s each | |

The measured figures are 100 calls each, timed with `FRAMES`: 6, 7 and 6 frames. The long notes play only when the game is paused anyway, for a lost base or a new wave. `quiet` (50049) switches all of them off.

### The ripple

Up to step 13, a march step moved all 32 invaders in one pass, about 0.83 of a frame. Here a hit adds 0.05 for the score and 0.07 for the click, and that is enough to go over. The fix is Chapter 4's. `mstep` still works out the new place and frame, but it moves nothing; it sets `rip` to 0. On each of the next four passes, the march beat calls `mrow`, which moves one block row and adds one to `rip`. A row takes 0.21 of a frame (100 rows in 21 frames), so no pass carries much more than a quarter of a frame of march.

The cost is in what the rest of the code must know while a step is under way. For four passes, rows below `rip` are where the block is, at `bx`, `by`, in the new frame. The rest are where it was, at `obx`, `oby`, in the other frame. Three routines take care of it:

- **`where`** gives an invader's cell from `bx` if its row is below `rip`, and from `obx` if not.
- **`rtype`** picks the frame the same way.
- **`invat`** tries the cell against the block as it is, and accepts a row that has moved. Then it tries it against the block as it was, and accepts a row that has not. The test that both use is now its own routine, `inbl`, given the address of a column byte with its row byte after it.

Everything else asks those three, so the shot, the bomb, the explosion and the shields need no change. When a step is not under way, `rip` is 4, so every row has moved and `where`, `rtype` and `invat` work as before. If `mtime` comes round while a step is still rippling, which happens only when `mspeed` is under 4, the step waits a pass.

`step14-game-ripple.png` shows a step in slow motion (`halts` 10): the top row has moved first, then the next two, then the bottom row.

## The listing

The machine code, `step14-game.asm`. It is step 13's, with these changes:

- new bytes from `score` to `nlives`;
- `start` setting up a whole game;
- the base's beat in the loop, and the rippling march beat;
- the score and a click in `hit`;
- clicks in `fire` and `drop`;
- lives in `bhit`;
- `land` ending the game;
- `mrow` in place of `mblock`;
- `where`, `rtype` and `invat` knowing about the ripple;
- the ROM printing replaced by `newwave`, `clear`, `newbase`, `status`, `pdec`, `ptext`, `pchar`, `sound` and their tables.

```
; step14-game.asm - Chapter 5, step 14
; The whole game: the twin of Chapter 4, step 8.
; It is step 13's game, made into a game you can win points at and lose.
; An invader shot scores 30 on the top row, 20 on the two middle rows
; and 10 on the bottom row. You have 3 bases: a bomb on the base takes
; one, and after a second the next comes on in the middle. A cleared
; wave brings the next at once, a row lower and 3 passes a step faster,
; with whole shields. The game ends when the last base goes or when the
; invaders land, and BASIC shows why, with the score, and offers
; another game. The status line on row 0 is printed by the code itself,
; from the ROM's character set; nothing else is ever printed there.
; Firing, hits, drops, a lost base and a new wave each make a short
; sound on the speaker. A march step now ripples down the block, a row
; a pass, as Chapter 4's did, so that no pass runs over its frame.
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
;   50015        bx      the column of the block's left-hand invader
;   50016        by      the row of the block's top row
;   50017        mspeed  passes per march step, 1 to 255
;   50018        mtime   passes until the next march step
;   50019        dx      the march: 1 right, 255 (-1) left
;   50020        frame   the invaders' frame, 0 or 1
;   50021        landed  1 once the block has landed, 0 until then
;   50022-50023  msteps  march steps taken
;   50024        hits    invaders shot
;   50025        nleft   invaders alive, 32 at the start
;   50026        elen    frames an explosion shows, 1 to 255
;   50027        etime   passes until the explosion is rubbed out
;   50028        erow    the explosion's row, or 255 for none
;   50029        ecol    the explosion's column
;   50030        seed    the random number state, 1 to 255; 0 = take one
;                        from the R register at the start
;   50031        dwait   passes from one bomb's end to the next drop
;   50032        dtime   passes until the next drop
;   50033        dspeed  passes per step of the bomb, 1 to 255
;   50034        dstime  passes until the bomb's next step
;   50035        brow    the bomb's row, or 255 for no bomb
;   50036        bcol    the bomb's column
;   50037        dead    1 once the base has been hit
;   50038        bombs   bombs dropped
;   50039        cancels shots and bombs that cancelled
;   50040        chips   shield cells chipped by shots and bombs
;   50041        stomps  shield cells wiped out by invaders
;   50042-50043  score   the score
;   50044        lives   bases left, counting the one in play
;   50045        wave    the wave, 1 to 99
;   50046        over    why the game ended: 0 Q, 1 out of lives,
;                        2 they landed
;   50047        rlen    passes a lost base stays down, 1 to 255
;   50048        rtime   passes until the next base comes on
;   50049        quiet   0 for sound, anything else for none
;   50050        mfirst  mspeed on wave 1, 1 to 255
;   50051        bfirst  by on wave 1
;   50052        nlives  lives at the start of a game, 1 to 9
;
; start sets everything else for a new game, so a game started again
; from BASIC starts afresh.
;
; Entry point:
;   RANDOMIZE USR 50053  start
;
; Build:  tools/build.sh chapter-05-machine-code-games/step14-game.bas chapter-05-machine-code-games/step14-game.asm game 10

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
bx:     db 8            ; 50015: the block's left-hand column
by:     db 1            ; 50016: the block's top row
mspeed: db 25           ; 50017: passes per march step
mtime:  db 25           ; 50018: passes to the next march step
dx:     db 1            ; 50019: the march: 1 right, 255 left
frame:  db 0            ; 50020: the invaders' frame, 0 or 1
landed: db 0            ; 50021: 1 once the block has landed
msteps: dw 0            ; 50022: march steps
hits:   db 0            ; 50024: invaders shot
nleft:  db 32           ; 50025: invaders alive
elen:   db 12           ; 50026: frames an explosion shows
etime:  db 0            ; 50027: passes to the explosion's end
erow:   db 255          ; 50028: the explosion's row; 255 = none
ecol:   db 0            ; 50029: the explosion's column
seed:   db 0            ; 50030: the random number state
dwait:  db 50           ; 50031: passes between bombs
dtime:  db 50           ; 50032: passes to the next drop
dspeed: db 4            ; 50033: passes per bomb step
dstime: db 4            ; 50034: passes to the bomb's next step
brow:   db 255          ; 50035: the bomb's row; 255 = none
bcol:   db 0            ; 50036: the bomb's column
dead:   db 0            ; 50037: 1 once the base is hit
bombs:  db 0            ; 50038: bombs dropped
cancels: db 0           ; 50039: shots and bombs cancelled
chips:  db 0            ; 50040: shield cells chipped
stomps: db 0            ; 50041: shield cells wiped out by invaders
score:  dw 0            ; 50042: the score
lives:  db 3            ; 50044: bases left
wave:   db 1            ; 50045: the wave
over:   db 0            ; 50046: 0 Q, 1 out of lives, 2 landed
rlen:   db 50           ; 50047: passes a lost base stays down
rtime:  db 0            ; 50048: passes to the next base
quiet:  db 0            ; 50049: 0 for sound
mfirst: db 25           ; 50050: mspeed on wave 1
bfirst: db 1            ; 50051: by on wave 1
nlives: db 3            ; 50052: lives at the start

baserow: equ 21         ; the base's row
bordcr: equ 23624       ; system variable: the border colour, bits 3-5
font:   equ 15360       ; the ROM's characters, 8 bytes each, less 256
white:  equ 7           ; INK 7, PAPER 0: the status line's attribute
green:  equ 4           ; INK 4, PAPER 0: the base's attribute
yellow: equ 6           ; INK 6, PAPER 0: the shot's attribute
red:    equ 2           ; INK 2, PAPER 0: the bomb's attribute
shrow:  equ 18          ; the shields' top row; their bottom row is 19
kright: equ 1           ; the bits rkeys gives back: P,
kleft:  equ 2           ; O,
kfire:  equ 4           ; Space,
kquit:  equ 8           ; and Q

; start: a new game. Clear the counts and the score, set the lives and
; the wave, colour row 0 white and row 21 green, draw the base, set up
; wave 1 and the status line, then loop.

start:  ld hl,0
        ld (moves),hl
        ld (passes),hl
        ld (ssteps),hl  ; no moves, passes or shot steps yet
        ld (msteps),hl  ; and no march steps
        ld (score),hl   ; and no score
        xor a
        ld (shots),a    ; no shots
        ld (hits),a     ; no hits
        ld (bombs),a    ; no bombs
        ld (cancels),a
        ld (chips),a
        ld (stomps),a   ; and none of the others
        ld (dead),a     ; the base is whole
        ld (over),a     ; and the game is not over
        inc a
        ld (wave),a     ; wave 1
        ld a,(nlives)
        ld (lives),a    ; nlives bases, 3 as shipped
        ld a,15
        ld (x),a        ; the base in the middle
        ld a,(seed)     ; has BASIC given us a seed?
        and a
        jr nz,seeded    ; yes
        ld a,r          ; no: use the R register
        or 1            ; and make sure it is not 0
        ld (seed),a
seeded:
        ld hl,22528     ; the attribute of row 0, column 0
        ld b,32         ; 32 cells
wrow:   ld (hl),white   ; white ink on black paper: the status line
        inc hl
        djnz wrow

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
        call newwave    ; the block, the shields and the status line

; The game loop: once a frame, unless halts says otherwise. The shot,
; the explosion, the lost base, the bomb, the march and the keys each
; have their own beat. Two places go back to BASIC with the game over:
; the base's beat, when no bases are left, and the march's, when the
; invaders land.

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
        jr z,boom       ; none: on to the explosion
        ld hl,stime
        dec (hl)        ; one pass fewer to the shot's next step
        jr nz,boom      ; not yet
        ld a,(sspeed)
        ld (hl),a       ; start counting again
        call sstep      ; move the shot up a row

boom:   ld a,(erow)
        inc a           ; 255 becomes 0: is there no explosion?
        jr z,rbase      ; none: on to the base
        ld hl,etime
        dec (hl)        ; one pass fewer to its end
        call z,erub     ; its time is up: rub it out

rbase:  ld a,(dead)
        and a           ; is the base down?
        jr z,bomb       ; no: on to the bomb
        ld hl,rtime
        dec (hl)        ; one pass fewer to the next base
        jr nz,bomb      ; not yet
        ld a,(lives)
        and a           ; any bases left?
        jr nz,rnew      ; yes
        inc a
        ld (over),a     ; no: 1, out of lives
        ret             ; the game is over: back to BASIC
rnew:   call newbase    ; the next base, in the middle

bomb:   ld a,(brow)
        inc a           ; 255 becomes 0: is there no bomb?
        jr nz,bfall     ; there is: it falls
        ld hl,dtime
        dec (hl)        ; one pass fewer to the next drop
        jr nz,march     ; not yet
        ld a,(dwait)
        ld (hl),a       ; start counting again
        call drop       ; drop one
        jr march
bfall:  ld hl,dstime
        dec (hl)        ; one pass fewer to the bomb's next step
        jr nz,march     ; not yet
        ld a,(dspeed)
        ld (hl),a       ; start counting again
        call bstep      ; move the bomb down a row

march:  ld a,(rip)
        cp 4            ; is a march step rippling down the block?
        call nz,mrow    ; yes: move its next row
        ld hl,mtime
        dec (hl)        ; one pass fewer to the next march step
        jr nz,keys      ; not yet
        ld a,(rip)
        cp 4            ; has the last step moved all four rows?
        jr z,mgo        ; yes
        inc (hl)        ; no: mtime = 1, and try again next pass
        jr keys
mgo:    ld a,(mspeed)
        ld (hl),a       ; start counting again
        call mstep      ; march
        ld a,(over)
        and a           ; have they landed?
        ret nz          ; yes: the game is over, back to BASIC

keys:   ld hl,ptime
        dec (hl)        ; one pass fewer to the next key look
        jp nz,loop      ; not yet: jp, since loop is now too far for jr
        ld a,(bspeed)
        ld (hl),a       ; start counting again
        call rkeys      ; A = the keys held, one bit each
        bit 3,a         ; Q?
        ret nz          ; yes: back to BASIC
        ld c,a          ; keep the keys
        ld a,(dead)
        and a           ; has the base been hit?
        jp nz,loop      ; yes: only Q does anything now
        ld a,c          ; the keys again
        bit 2,a         ; Space?
        call nz,fire    ; yes: fire, if no shot is in flight
        and kright+kleft ; keep only P and O
        cp kright       ; only P?
        jr z,right
        cp kleft        ; only O?
        jp nz,loop      ; neither, or both: the base stays put
        call left
        jp loop
right:  call goright
        jp loop

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
        xor a
        call sound      ; sound 0: a click
        call stest      ; draw it, or hit what is there
nofire: pop af          ; the keys again
        ret

; sstep: move the shot up a row. If an invader has marched onto it,
; that is a hit where it is. Otherwise rub it out and move it up; from
; row 1 it goes, and there is no shot any more, so it never rubs out a
; message on row 0; anywhere else it is tested on the cell it comes to.
; Changes A, B, C, DE, HL.

sstep:  ld hl,(ssteps)
        inc hl
        ld (ssteps),hl  ; one more shot step
        call scell      ; B, C = the shot's cell
        call invat      ; has a living invader marched onto it?
        and a
        jr nz,hit       ; yes: a hit, there
        call scell
        ld de,blank
        call put        ; rub it out
        ld hl,srow
        ld a,(hl)
        cp 1            ; was it on row 1, the top of the play area?
        jr z,sgone      ; yes: it goes, and row 0 is left for messages
        dec (hl)        ; one row up
        jr stest        ; and test the cell it is on now
sgone:  ld (hl),255     ; no shot now
        ret

; stest: is there a living invader on the shot's cell? If so, a hit;
; if not, draw the shot. Changes A, B, C, DE, HL.

stest:  call scell      ; B, C = the shot's cell
        call invat      ; A = 1 if a living invader is there
        and a
        jr nz,hit       ; yes: a hit
        call scell
        call chip       ; has it come to a shield?
        jr c,sused      ; yes: the shield has eaten it
        call ctest      ; has it met the bomb?
        ret c           ; yes: both are gone
        jp sdraw        ; no: draw the shot
sused:  ld a,255
        ld (srow),a     ; no shot now
        ret

; hit: the shot has hit invader icol of block row irow, at row B, column
; C, and HL is its byte in the alive table, as invat left them. Kill it,
; end the shot, score it, and show the explosion on its cell. If it was
; the last, start the next wave. Changes A, B, C, DE, HL.

hit:    ld (hl),0       ; dead: the table says so, and that is all
        ld a,255
        ld (srow),a     ; the shot is used up
        ld hl,hits
        inc (hl)        ; one more hit
        ld hl,nleft
        dec (hl)        ; one fewer alive
        ld a,(irow)     ; its row in the block, from invat
        ld e,a
        ld d,0
        ld hl,points
        add hl,de
        ld e,(hl)       ; DE = its points: 30, 20, 20 or 10
        ld hl,(score)
        add hl,de
        ld (score),hl   ; onto the score
        push bc
        call erub       ; one explosion at a time: end the last one
        pop bc
        ld a,b
        ld (erow),a
        ld a,c
        ld (ecol),a     ; the explosion is here
        ld a,(elen)
        ld (etime),a    ; for elen passes
        call attr       ; HL = the cell's attribute
        ld (hl),yellow
        ld de,burst
        call put        ; draw the starburst over the invader
        call pscore     ; print the new score
        ld a,1
        call sound      ; sound 1: a click
        ld a,(nleft)
        and a           ; was that the last one?
        ret nz          ; no
        ld hl,wave      ; yes: the wave is cleared
        ld a,(hl)
        cp 99           ; the status line has two digits for it
        jr z,hit2
        inc (hl)        ; the next wave
hit2:   ld a,4
        call sound
        ld a,5
        call sound
        ld a,6
        call sound      ; three rising notes
        jp newwave      ; and the next wave starts at once

; erub: rub out the explosion, if there is one, and draw again any
; living invader that has marched onto its cell. Changes A, B, C, DE, HL.

erub:   ld hl,erow
        ld a,(hl)
        cp 255          ; is there an explosion?
        ret z           ; no
        ld (hl),255     ; there will not be
        ld b,a
        ld a,(ecol)
        ld c,a          ; B, C = its cell
        push bc
        ld de,blank
        call put        ; rub it out
        pop bc
        call invat      ; has a living invader come onto the cell?
        and a
        ret z           ; no
        jp dinv         ; yes: draw it again

; drop: drop a bomb, unless the base is hit or none are alive. Pick a
; column with rnd; if none of it is alive, try the next, round to 0
; after 7. The bomb starts on the row below the column's lowest living
; invader. Changes A, B, C, DE, HL.

drop:   ld a,(dead)
        and a
        ret nz          ; the base is hit: no more bombs
        ld a,(nleft)
        and a
        ret z           ; none alive: no bombs
        call rnd        ; A = a random byte
        and 7           ; A = 0 to 7: a column of the block
        ld (icol),a
        ld b,8          ; 8 columns to try at most
dcol:   push bc
        call colalive   ; is any invader in column icol alive?
        pop bc
        jr nz,dgot      ; yes
        ld a,(icol)
        inc a
        and 7           ; the next column, 7 going round to 0
        ld (icol),a
        djnz dcol
        ret             ; cannot happen while nleft is not 0
dgot:   ld a,3
        ld (irow),a     ; from the bottom row up
dlow:   call aliveat
        and a
        jr nz,dfound    ; the lowest living invader of the column
        ld hl,irow
        dec (hl)        ; the row above; one of them is alive
        jr dlow
dfound: call where      ; B, C = its cell
        inc b           ; the row below it
        ld a,b
        ld (brow),a
        ld a,c
        ld (bcol),a     ; the bomb starts there
        ld a,(dspeed)
        ld (dstime),a   ; a full beat to its first step
        ld hl,bombs
        inc (hl)        ; one more bomb
        ld a,2
        call sound      ; sound 2: a lower click
        jr btest        ; and see where it is

; bstep: rub out the bomb and move it down a row. Changes A, B, C, DE,
; HL.

bstep:  call brub       ; rub it out
        ld hl,brow
        inc (hl)        ; one row down

; btest: the bomb has come to brow, bcol. On the base's row it has hit
; the base, if the base is in its column, or it goes into the ground.
; Anywhere else, test it against the shot, then draw it, unless a living
; invader is on its cell: then it falls on behind it, and is drawn again
; when it comes out. Changes A, B, C, DE, HL.

btest:  ld a,(brow)
        cp baserow      ; on the base's row?
        jr nz,bair      ; no: still in the air
        ld a,(x)
        ld hl,bcol
        cp (hl)         ; is the base in its column?
        jr z,bhit       ; yes: the base is hit
        ld a,255
        ld (brow),a     ; no: the bomb is gone, and nothing is drawn
        ret
bair:   call bcell
        call chip       ; has it come to a shield?
        jr c,bused      ; yes: the shield has eaten it
        call ctest      ; has it met the shot?
        ret c           ; yes: both are gone
        call bcell      ; B, C = the bomb's cell
        call invat      ; is a living invader on it?
        and a
        ret nz          ; yes: the bomb is behind it
        call bcell
        call attr
        ld (hl),red     ; red ink on black paper
        ld de,bombg
        jp put          ; draw the bomb
bused:  ld a,255
        ld (brow),a     ; no bomb now
        ret

; brub: rub out the bomb's cell, and draw again any living invader on
; it. Changes A, B, C, DE, HL.

brub:   call bcell      ; B, C = the bomb's cell
        ld de,blank
        call put        ; rub it out
        call bcell
        call invat      ; was a living invader there?
        and a
        ret z           ; no
        jp dinv         ; yes: draw it again

; bcell: B = the bomb's row, C = its column. Changes A.

bcell:  ld a,(brow)
        ld b,a
        ld a,(bcol)
        ld c,a
        ret

; bhit: the bomb has hit the base. End the bomb and the shot, put a
; starburst where the base was, take a life, and keep the base down for
; rlen passes; the base's beat in the loop does the rest. Changes A, B,
; C, DE, HL.

bhit:   ld a,1
        ld (dead),a     ; the base is hit
        ld a,255
        ld (brow),a     ; no bomb
        ld a,(srow)
        cp 255          ; is a shot in flight?
        jr z,bhit2      ; no
        call scell
        ld de,blank
        call put        ; rub it out
        ld a,255
        ld (srow),a     ; no shot
bhit2:  ld a,(x)
        ld c,a
        ld b,baserow    ; B, C = the base's cell
        call attr
        ld (hl),yellow
        ld de,burst
        call put        ; the starburst over the base
        ld hl,lives
        dec (hl)        ; one base fewer
        call plives     ; print it
        ld a,(rlen)
        ld (rtime),a    ; down for rlen passes
        ld a,3
        jp sound        ; sound 3: a long low note

; ctest: if a shot and a bomb are both in flight, in the same column,
; with the shot on the bomb's row or the row below it, they have met:
; rub out both, end both, and return with the carry set. Otherwise
; return with the carry clear. Changes A, B, C, DE, HL.

ctest:  ld a,(brow)
        cp 255
        jr z,noc        ; no bomb
        ld b,a
        ld a,(srow)
        cp 255
        jr z,noc        ; no shot
        sub b           ; A = shot row - bomb row
        cp 2            ; 0 or 1? (a shot above the bomb goes round
        jr nc,noc       ; to 255, which fails too)
        ld a,(bcol)
        ld hl,scol
        cp (hl)         ; the same column?
        jr nz,noc
        call brub       ; rub out the bomb
        call scell
        ld de,blank
        call put        ; and the shot
        ld a,255
        ld (brow),a
        ld (srow),a     ; neither is in flight now
        ld hl,cancels
        inc (hl)        ; one more cancel
        scf             ; they met
        ret
noc:    and a           ; clear the carry: they have not met
        ret

; rnd: the next random byte, in A and in seed. Step 6's 8-bit LFSR, run
; for eight steps. Each step shifts the byte right, and if a 1 fell off
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

; shat: is the cell at row B, column C a shield cell? If not, the carry
; is set. If it is, the carry is clear, HL is its byte in the damage
; map, A is its level, the zero flag is set if the level is 0, and shy
; (0 top, 1 bottom) and shx (0, 1 or 2 across) say which cell of its
; shield it is. The shields start in columns 3, 11, 19 and 27, eight
; apart, so column - 3 is 8 * shield + place, with the place in the
; bottom three bits. Keeps B, C. Changes A, DE, HL.

shat:   ld a,b
        sub shrow       ; A = row - 18
        cp 2            ; 0 or 1? Rows above 18 go round to 255 or so
        jr nc,noshl     ; no: not a shield row
        ld (shy),a
        ld a,c
        sub 3           ; A = column - 3, round to 253 or more left of 3
        cp 27           ; 0 to 26: from the first shield to the last
        jr nc,noshl
        ld e,a
        and 7           ; A = the place in a group of eight columns
        cp 3            ; 0, 1 or 2 is a shield; 3 to 7 is a gap
        jr nc,noshl
        ld (shx),a
        ld d,a          ; D = the place across, 0 to 2
        ld a,e
        rrca
        rrca
        rrca
        and 3           ; A = the shield, 0 to 3
        ld e,a
        add a,a
        add a,e         ; A = 3 * shield
        add a,d         ; A = 3 * shield + place: 0 to 11
        ld e,a
        ld a,(shy)
        and a           ; the top row?
        jr z,shtop
        ld a,e
        add a,12        ; the bottom row's 12 bytes come after the top's
        ld e,a
shtop:  ld d,0
        ld hl,shmap
        add hl,de       ; HL = its byte in the map
        ld a,(hl)       ; A = its level
        and a           ; zero flag from the level; the carry is clear
        ret
noshl:  scf             ; not a shield cell
        ret

; shdraw: draw the shield cell at row B, column C at level A, using shy
; and shx from shat: level 3 is the cell's own shape, 2 damaged, 1
; badly damaged, 0 nothing. Changes A, B, DE, HL.

shdraw: cp 3
        jr c,shworn     ; below 3: the same three pictures for every cell
        ld a,(shy)
        ld e,a
        add a,a
        add a,e         ; A = 3 * shy
        ld hl,shx
        add a,(hl)      ; A = 3 * shy + shx, 0 to 5
        add a,3         ; the shapes come after the three worn pictures
shworn: add a,a         ; two bytes an address
        ld e,a
        ld d,0
        ld hl,shgfx
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)       ; DE = the picture
        call attr
        ld (hl),green   ; green, the base's ink
        jp put

; chip: if the cell at row B, column C is a shield cell above level 0,
; take one off its level, draw it, count it, and return with the carry
; set: whatever came here is used up. If not, return with the carry
; clear. Changes A, DE, HL, and B if it chips.

chip:   call shat
        jr c,nochip     ; not a shield cell
        jr z,nochip     ; a hole: level 0
        dec (hl)        ; one level less
        ld a,(hl)
        call shdraw     ; draw it at the new level
        ld hl,chips
        inc (hl)        ; one more chip
        scf             ; eaten
        ret
nochip: and a           ; clear the carry
        ret

; stomp: an invader is being drawn at row B, column C. If that is a
; shield cell still above level 0, it is gone: set its level to 0 and
; count it. The invader's picture covers it. Keeps B, C, DE. Changes A,
; HL.

stomp:  ld a,b
        cp shrow        ; above the shields?
        ret c           ; yes: nothing to do, quickly
        push de         ; keep the invader's graphic
        call shat
        jr c,stomp1     ; not a shield cell
        jr z,stomp1     ; already gone
        ld (hl),0       ; wiped out
        ld hl,stomps
        inc (hl)
stomp1: pop de
        ret

; dshield: set every byte of the damage map to 3, then draw every cell
; of rows 18 and 19 that shat says is a shield cell. Changes A, B, C, DE,
; HL.

dshield: ld hl,shmap
        ld b,24         ; 24 cells
dsh1:   ld (hl),3       ; whole
        inc hl
        djnz dsh1
        ld b,shrow      ; row 18 first
dsh2:   ld c,0          ; from column 0
dsh3:   call shat       ; a shield cell?
        jr c,dsh4       ; no
        push bc
        call shdraw     ; draw it, at level 3
        pop bc
dsh4:   inc c
        ld a,c
        cp 32
        jr nz,dsh3
        inc b
        ld a,b
        cp shrow+2      ; done row 19?
        jr nz,dsh2
        ret

; count: nleft = the number of 1s in the alive table. Changes A, B, HL.

count:  ld hl,alive
        ld b,32         ; 32 invaders
        xor a
cnt1:   add a,(hl)      ; add its byte, 0 or 1
        inc hl
        djnz cnt1
        ld (nleft),a
        ret

; scell: B = the shot's row, C = its column. Changes A.

scell:  ld a,(srow)
        ld b,a
        ld a,(scol)
        ld c,a
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

; dblock: draw every living invader of the block. Changes A, B, C,
; DE, HL.

dblock: xor a
        ld (irow),a        ; block row 0
dbrow:  xor a
        ld (icol),a        ; invader 0 of the row
dbinv:  call dinv       ; draw it, if it is alive
        ld hl,icol
        inc (hl)        ; the next invader
        ld a,(hl)
        cp 8            ; done all 8?
        jr nz,dbinv
        ld hl,irow
        inc (hl)        ; the next row
        ld a,(hl)
        cp 4            ; done all 4?
        jr nz,dbrow
        ret

; dinv: draw invader icol of block row irow, in its row's colour, if it is
; alive. Changes A, B, C, DE, HL.

dinv:   call aliveat    ; A = 1 if it is alive
        and a
        ret z           ; not alive: nothing to draw
        call rtype      ; DE = its graphic, A = its ink
        push af
        call where      ; B, C = its cell on the screen
        call stomp      ; on a shield cell? then that cell is gone
        call attr       ; HL = the cell's attribute
        pop af
        ld (hl),a       ; the row's ink, on black paper
        jp put          ; draw it, and put returns

; aliveat: A = the alive byte of invader icol in block row irow, and HL its
; address, alive + 8*irow + icol. Changes DE.

aliveat: ld a,(irow)
        add a,a
        add a,a
        add a,a         ; A = 8*irow
        ld hl,icol
        add a,(hl)      ; A = 8*irow + icol
        ld e,a
        ld d,0
        ld hl,alive
        add hl,de       ; HL = its byte in the table
        ld a,(hl)
        ret

; where: B = the screen row of invader icol in block row irow, by + 2*irow,
; and C its column, bx + 2*icol; but from obx and oby if its row has
; not moved yet in a rippling march step (irow is not below rip).
; owhere: always from obx and oby, where the block was before this
; march step. Both go on to wpair, with HL = the address of a column
; byte with its row byte after it. Changes A, HL.

where:  ld a,(irow)
        ld hl,rip
        cp (hl)         ; carry if irow < rip: its row has moved
        ld hl,bx        ; the block as it is (LD keeps the flags)
        jr c,wpair
owhere: ld hl,obx       ; the block as it was
wpair:  ld a,(icol)
        add a,a
        add a,(hl)
        ld c,a          ; C = column + 2*icol
        inc hl          ; the row byte comes next
        ld a,(irow)
        add a,a
        add a,(hl)
        ld b,a          ; B = row + 2*irow
        ret

; rtype: DE = the graphic and A = the ink of block row irow, from the
; rows table, three bytes a row, in the frame of its row: frame if the
; row has moved, the other frame if it has not yet. Changes B, HL.

rtype:  ld a,(irow)
        ld hl,rip
        cp (hl)         ; has its row moved?
        ld a,(frame)
        jr c,rtnow      ; yes: this frame
        xor 1           ; not yet: the other
rtnow:  ld b,a          ; B = the row's frame
        ld a,(irow)
        ld e,a
        add a,a
        add a,e         ; A = 3*irow
        ld e,a
        ld d,0
        ld hl,rows
        add hl,de       ; HL = this row's entry
        ld e,(hl)
        inc hl
        ld d,(hl)       ; DE = the graphic, frame 0
        ld a,b          ; the row's frame
        add a,a
        add a,a
        add a,a         ; A = 0 for frame 0, 8 for frame 1
        add a,e
        ld e,a
        jr nc,rtnc
        inc d           ; DE = the graphic of this frame
rtnc:   inc hl
        ld a,(hl)       ; A = the ink
        ret

; invat: is the cell at row B, column C an invader's place in the
; block? If it is, irow and icol are set to it, and A is its alive byte;
; if not, A = 0. In a rippling march step the rows that have moved are
; where the block is, and the rest where it was, so both are tried.
; Keeps B and C. Changes DE, HL.

invat:  ld hl,bx
        call inbl       ; an invader's place in the block as it is?
        jr nz,invold    ; no
        ld a,(irow)
        ld hl,rip
        cp (hl)         ; and has that row moved?
        jp c,aliveat    ; yes: A = its alive byte
invold: ld hl,obx
        call inbl       ; in the block as it was?
        jr nz,noinv     ; no
        ld a,(irow)
        ld hl,rip
        cp (hl)         ; a row that has not moved yet?
        jp nc,aliveat   ; yes: A = its alive byte
noinv:  xor a           ; not an invader's place
        ret

; inbl: is the cell at row B, column C an invader's place in a block
; whose left-hand column is at HL and top row at HL + 1? If it is, the
; zero flag is set and irow and icol are set to it. Keeps B and C.
; Changes A, HL.

inbl:   ld a,c
        sub (hl)        ; A = column - left; left of it goes round
        cp 15           ; past 0 to 255 or so, so one test does both
        jr nc,inno      ; outside: columns 0, 2, ... 14
        bit 0,a
        jr nz,inno      ; an odd column: a gap
        rrca            ; A = (column - left) / 2, since bit 0 is 0
        ld (icol),a
        inc hl          ; the row byte comes next
        ld a,b
        sub (hl)        ; A = row - top
        cp 7
        jr nc,inno      ; outside: block rows are 0, 2, 4 and 6
        bit 0,a
        jr nz,inno      ; an odd row: between two block rows
        rrca
        ld (irow),a
        xor a           ; zero flag set: found
        ret
inno:   or 1            ; zero flag clear: not found
        ret

; mstep: one step of the march. Find the living edges; at an edge,
; step down (or land), otherwise step sideways; then change frame, and
; set rip to 0: the march beat moves the rows, one a pass, from the
; next pass on. Changes A, B, C, DE, HL.

mstep:  ld a,(landed)
        and a
        ret nz          ; landed: the march is over
        ld a,(dead)
        and a
        ret nz          ; the base is hit: so is the march
        call edges      ; lm, rm = the living edge columns
        ret c           ; none alive: nothing to march
        ld hl,(msteps)
        inc hl
        ld (msteps),hl  ; one more march step
        ld hl,(bx)      ; L = bx, H = by
        ld (obx),hl     ; where the block is now: obx, oby
        ld a,(dx)
        dec a           ; 1 (right) becomes 0
        jr nz,mleft
        ld a,(rm)       ; marching right: the right-hand edge
        add a,a
        ld hl,bx
        add a,(hl)      ; A = the column of the right-hand edge
        cp 31           ; at the right of the screen?
        jr z,mdown
        jr mside
mleft:  ld a,(lm)       ; marching left: the left-hand edge
        add a,a
        ld hl,bx
        add a,(hl)      ; A = the column of the left-hand edge
        and a           ; at column 0?
        jr z,mdown
mside:  ld a,(dx)
        ld hl,bx
        add a,(hl)
        ld (hl),a       ; bx = bx + dx: one column sideways
        jr mmove
mdown:  ld a,(by)
        cp 20-6         ; would the bottom row come down past row 20?
        jr nc,land      ; yes: they have landed
        inc a
        ld (by),a       ; by = by + 1: one row down
        ld a,(dx)
        neg
        ld (dx),a       ; and back the other way
mmove:  ld a,(frame)
        xor 1
        ld (frame),a    ; the other frame
        xor a
        ld (rip),a      ; no row has moved yet
        ret

; land: the march is over, and so is the game: over = 2, and the loop
; goes back to BASIC.

land:   ld a,1
        ld (landed),a
        inc a
        ld (over),a     ; 2: they landed
        ret

; mrow: move block row rip from where the block was to where it is,
; one invader at a time: rub it out where it was, then draw it where it
; is. rip goes up first, so that where and rtype see the row as moved.
; The invaders are two cells apart, so the new cell never holds another
; invader, and none is missing from the screen for more than a moment.
; Changes A, B, C, DE, HL.

mrow:   ld a,(rip)
        ld (irow),a     ; the row to move
        inc a
        ld (rip),a      ; it counts as moved from now on
        xor a
        ld (icol),a     ; from invader 0
mrinv:  call aliveat
        and a
        jr z,mrnext     ; not alive: nothing to move
        call owhere     ; B, C = where it was
        ld de,blank
        call put        ; rub it out
        call dinv       ; draw it where it is, in the new frame
mrnext: ld hl,icol
        inc (hl)
        ld a,(hl)
        cp 8            ; done all 8?
        jr nz,mrinv
        ret

; edges: lm = the left-hand column, 0 to 7, with an invader alive in
; it, and rm the right-hand one. Carry set if there is none. Changes
; A, B, DE, HL.

edges:  xor a
        ld (icol),a     ; from the left
eleft:  call colalive
        jr nz,egotl     ; a living invader in this column
        ld hl,icol
        inc (hl)
        ld a,(hl)
        cp 8
        jr nz,eleft
        scf             ; none in any column
        ret
egotl:  ld a,(icol)
        ld (lm),a
        ld a,7
        ld (icol),a     ; and from the right
eright: call colalive
        jr nz,egotr
        ld hl,icol
        dec (hl)
        jr eright       ; it stops at lm at the latest
egotr:  ld a,(icol)
        ld (rm),a
        and a           ; clear the carry: found
        ret

; colalive: A = not 0, and the zero flag clear, if any invader in
; column icol is alive. Changes B, DE, HL.

colalive: ld a,(icol)
        ld e,a
        ld d,0
        ld hl,alive
        add hl,de       ; HL = the top invader of the column
        ld de,8         ; 8 bytes on in the table is the next row
        xor a
        ld b,4          ; 4 rows
calive: or (hl)         ; A = A OR this invader's byte
        add hl,de
        djnz calive
        and a           ; set the zero flag from A
        ret

; newwave: set up a wave: wave 1 at the start of a game, the next when
; one is cleared. The block goes back to column 8, a row lower each wave
; (bfirst on wave 1, no lower than row 8 after that) and 3 passes a step
; faster (mfirst on wave 1, down to no less than 4). All 32 invaders are
; alive again, the play area is cleared, the shields are whole, and the
; status line is printed. The score and the lives carry on. Changes A,
; B, C, DE, HL.

newwave: ld a,(wave)
        dec a
        ld hl,bfirst
        add a,(hl)      ; A = bfirst + wave - 1
        cp 9            ; row 8 or above?
        jr c,nw1        ; yes: that is the row
        ld a,(hl)       ; no: row 8, unless bfirst itself is lower
        cp 9
        jr nc,nw1
        ld a,8
nw1:    ld (by),a
        ld a,8
        ld (bx),a       ; the block's left-hand column
        ld a,1
        ld (dx),a       ; marching right
        xor a
        ld (frame),a    ; frame 0
        ld (landed),a   ; not landed
        ld a,4
        ld (rip),a      ; and no march step rippling

        ld a,(wave)
        ld b,a          ; B = the wave
        ld a,(mfirst)   ; A = the speed on wave 1
nw2:    dec b           ; a wave after the first?
        jr z,nw3        ; no: A is the speed
        cp 7            ; would 3 less be under 4?
        jr c,nw3        ; yes: keep it
        sub 3           ; no: 3 passes a step faster
        jr nw2
nw3:    ld (mspeed),a
        ld (mtime),a    ; a full beat to the first march step
        ld a,(dwait)
        ld (dtime),a    ; and to the first bomb

        ld hl,alive
        ld b,32
nw4:    ld (hl),1       ; every invader alive
        inc hl
        djnz nw4
        ld a,255
        ld (srow),a     ; no shot
        ld (erow),a     ; no explosion
        ld (brow),a     ; no bomb
        call clear      ; rows 1 to 20 cleared
        call dshield    ; the four shields, whole
        call dblock     ; the block
        call count      ; nleft = 32
        jp status       ; and the status line

; clear: rub out rows 1 to 20: for each row, its 8 pixel lines of 32
; bytes. Leaves the attributes. Changes A, B, C, D, E, HL.

clear:  ld b,1          ; row 1 first
clr1:   ld c,0
        call cell       ; HL = the row's top-left byte
        ld d,8          ; 8 pixel lines
clr2:   push hl
        ld e,32         ; 32 bytes across
clr3:   ld (hl),0
        inc l           ; the next byte of the line
        dec e
        jr nz,clr3
        pop hl
        inc h           ; the next pixel line down
        dec d
        jr nz,clr2
        inc b           ; the next row
        ld a,b
        cp baserow      ; done row 20?
        jr nz,clr1
        ret

; newbase: rub out the starburst where the lost base was, and bring on
; the next base in column 15. Changes A, B, C, DE, HL.

newbase: ld a,(x)
        ld c,a
        ld b,baserow    ; the burst's cell
        call attr
        ld (hl),green   ; green again, for the base when it comes here
        ld de,blank
        call put        ; rub out the burst
        ld a,15
        ld (x),a
        ld c,a
        ld b,baserow
        ld de,base
        call put        ; the new base, in the middle
        xor a
        ld (dead),a     ; in play again
        ret

; status: print the whole status line on row 0: the words, then the
; numbers. Changes A, B, C, DE, HL.

status: ld hl,stext
        ld bc,0         ; B = row 0, C = column 0
        call ptext      ; the words, and spaces between them
        call pscore
        call pwave      ; then the numbers, and plives returns

; plives, pscore, pwave: print one number of the status line. Each
; changes A, B, C, DE, HL.

plives: ld a,(lives)
        ld l,a
        ld h,0          ; HL = the lives
        ld bc,28        ; row 0, column 28
        ld a,1          ; one digit
        jr pdec

pscore: ld hl,(score)
        ld bc,6         ; row 0, column 6
        ld a,5          ; five digits
        jr pdec

pwave:  ld a,(wave)
        ld l,a
        ld h,0
        ld bc,18        ; row 0, column 18
        ld a,2          ; two digits

; pdec: print HL as A decimal digits, 1 to 5, with zeros in front, at
; row B, column C. Each digit is how many times its power of ten can be
; taken away. Changes A, B, C, DE, HL.

pdec:   ld (pdn),a      ; the digits to print
        neg
        add a,5         ; A = 5 - digits: the powers to skip
        add a,a         ; two bytes each
        ld e,a
        ld d,0
        push hl         ; keep the number
        ld hl,tens
        add hl,de
        ex de,hl        ; DE = the first power to use
        pop hl
pd1:    push de         ; keep the place in the table
        ex de,hl        ; HL = the place, DE = the number
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a          ; HL = this power of ten
        ex de,hl        ; HL = the number, DE = the power
        ld a,'0'-1      ; the digit, one below "0"
pd2:    inc a           ; one more
        and a           ; clear the carry for SBC
        sbc hl,de       ; take the power away
        jr nc,pd2       ; not below 0 yet: again
        add hl,de       ; once too often: put it back
        push hl         ; keep what is left
        push bc         ; and the cell
        call pchar      ; print the digit
        pop bc
        pop hl
        inc c           ; the next column
        pop de
        inc de
        inc de          ; the next power of ten
        ld a,(pdn)
        dec a
        ld (pdn),a      ; one digit fewer to go
        jr nz,pd1
        ret

; ptext: print the text at HL, which ends with 255, from row B, column
; C, across. Changes A, DE, HL.

ptext:  ld a,(hl)       ; the next character
        cp 255          ; the end marker?
        ret z           ; yes: done
        push hl
        push bc
        call pchar      ; print it
        pop bc
        pop hl
        inc hl
        inc c           ; the next column
        jr ptext

; pchar: draw character A, 32 to 127, at row B, column C, from the
; ROM's character set: 8 bytes a character, at 15360 + 8 * code.
; Changes A, B, DE, HL.

pchar:  ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl       ; HL = 8 * code
        ld de,font
        add hl,de
        ex de,hl        ; DE = the character's 8 bytes
        jp put          ; draw them, and put returns

; sound: play sound number A, 0 to 6, unless quiet is not 0: step 6's.
; Keeps every register except A and the flags. Each sound in the table
; is a delay count (2 bytes, low first), which sets the pitch, and a
; number of whole cycles, which sets the length.

sound:  push bc
        push de
        push hl
        ld c,a          ; keep the sound's number
        ld a,(quiet)
        and a           ; is the sound switched off?
        jr nz,sdone     ; yes: nothing to do
        ld a,c
        add a,a         ; A = 2 * number
        add a,c         ; A = 3 * number, the size of each entry
        ld e,a
        ld d,0
        ld hl,sounds
        add hl,de       ; HL = this sound's entry
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

; The sounds. The delay n gives a note of 3500000 / (52 * n + 110)
; hertz, and each cycle takes 52 * n + 110 T-states. The three clicks
; are kept under 4500 T-states, about a sixteenth of a frame, since they
; play in the middle of a pass; the others play when the game waits.

sounds: dw 20
        db 3            ; 0 fire: about 3000 Hz, 3 cycles, 1 ms
        dw 40
        db 2            ; 1 hit: about 1600 Hz, 2 cycles, 1.3 ms
        dw 80
        db 1            ; 2 drop: about 820 Hz, 1 cycle, 1.2 ms
        dw 400
        db 30           ; 3 base lost: about 168 Hz, 30 cycles, 0.18 s
        dw 255
        db 5            ; 4 wave: about 262 Hz, C, 0.02 s
        dw 202
        db 7            ; 5 about 330 Hz, E
        dw 170
        db 8            ; 6 about 392 Hz, G

; The status line's words, the points for each block row, and the
; powers of ten for pdec.

stext:  db "SCORE        WAVE     LIVES     ",255
points: db 30,20,20,10  ; block rows 0, 1, 2 and 3
tens:   dw 10000,1000,100,10,1

; The block's working bytes and tables.

irow:   db 0            ; the block row being drawn, 0 to 3
icol:   db 0            ; the invader in that row, 0 to 7
obx:    db 0            ; bx before this march step
oby:    db 0            ; by before it: it must follow obx
lm:     db 0            ; the left-hand living column, 0 to 7
rm:     db 0            ; the right-hand living column
rip:    db 4            ; block rows moved in this march step; 4 = all
pdn:    db 0            ; digits left for pdec to print
shy:    db 0            ; a shield cell's row in its shield, 0 or 1
shx:    db 0            ; its place across, 0 to 2

; shmap: the damage map, 12 bytes for the top row of the four shields,
; then 12 for the bottom row. 3 whole, 2 damaged, 1 badly, 0 gone.

shmap:  ds 24

; shgfx: the shield pictures by level, then the six shapes of a whole
; shield, top row then bottom row.

shgfx:  dw blank,gO,gN ; levels 0, 1 and 2
        dw gK,gJ,gL  ; level 3, top row: corner, block, corner
        dw gJ,gM,gJ  ; level 3, bottom row: block, arch, block

; alive: one byte for each invader, row by row, 1 = alive.

alive:  db 1,1,1,1,1,1,1,1
        db 1,1,1,1,1,1,1,1
        db 1,1,1,1,1,1,1,1
        db 1,1,1,1,1,1,1,1

; rows: for each block row, its graphic (a word) and its ink.

rows:   dw inv1
        db 3            ; magenta
        dw inv2
        db 5            ; cyan
        dw inv2
        db 5            ; cyan
        dw inv3
        db 7            ; white

; The graphics, Chapter 4's UDGs A and B, from its DATA lines 990 to
; 997, its invaders, UDGs D to I, from lines 1000 to 1055 of its
; step 4, its explosion, UDG P, from its step 5, its bomb, UDG C,
; from its step 6, and its shields, UDGs J to O, from its step 7. Each invader
; type's frame 1 is 8 bytes after its frame 0.

base:   db 24,24,24,126,255,255,255,255
shot:   db 0,24,24,24,24,24,24,0
inv1:   db 60,126,255,219,255,90,165,66 ; UDG D, the top row, frame 0
        db 60,126,255,219,255,90,66,165 ; UDG E, its frame 1
inv2:   db 66,36,126,219,255,189,165,36 ; UDG F, the middle rows, frame 0
        db 36,165,126,219,255,189,36,165 ; UDG G, frame 1
inv3:   db 60,255,255,231,255,90,165,129 ; UDG H, the bottom row, frame 0
        db 60,255,255,231,255,90,129,165 ; UDG I, frame 1
burst:  db 165,90,189,126,126,189,90,165 ; UDG P, the explosion
bombg:  db 28,62,99,28,62,99,28,8 ; UDG C, the bomb
gJ:    db 126,255,255,255,255,255,255,126 ; UDG J, a full block
gK:    db 15,31,63,127,255,255,255,255 ; UDG K, the top-left corner
gL:    db 240,248,252,254,255,255,255,255 ; UDG L, the top-right corner
gM:    db 255,255,255,231,195,195,195,195 ; UDG M, the arch
gN:    db 110,219,189,118,221,183,111,218 ; UDG N, damaged
gO:    db 74,144,37,66,148,9,82,136 ; UDG O, badly damaged
blank:  db 0,0,0,0,0,0,0,0

        end
```

It is 2377 bytes, 50000 to 52376. These are the addresses from pasmo's listing:

| Label | Address | Label | Address | Label | Address |
|---|---|---|---|---|---|
| `start` | 50053 | `invat` | 51410 | `pscore` | 51910 |
| `loop` | 50159 | `inbl` | 51448 | `pwave` | 51920 |
| `rbase` | 50208 | `mstep` | 51482 | `pdec` | 51931 |
| `march` | 50268 | `land` | 51582 | `ptext` | 51986 |
| `keys` | 50304 | `mrow` | 51592 | `pchar` | 52001 |
| `fire` | 50358 | `newwave` | 51706 | `sound` | 52015 |
| `hit` | 50464 | `clear` | 51816 | `sounds` | 52077 |
| `drop` | 50597 | `newbase` | 51846 | `stext` | 52098 |
| `bhit` | 50780 | `status` | 51882 | `points` | 52131 |
| `where` | 51338 | `plives` | 51897 | `tens` | 52135 |
| `rtype` | 51367 | | | `rip` | 52151 |
| | | | | `shmap` | 52155 |
| | | | | `alive` | 52197 |

The BASIC driver, `step14-game.bas`. The entry point is 50053. Lines 60 to 68 set the bytes a player might want to change; `start` sets the rest. Line 95 sends a finished game to the game-over screen at line 300, and line 400 starts another. Q still stops the game with the counts, ending at line 270.

```
1 REM H=FRAMES high byte
2 REM L=FRAMES low byte
3 REM F=frames the program ran for
4 REM M=moves of the base
5 REM N=passes of the loop
6 REM S=steps of the shot
7 REM T=shots fired
8 REM G=march steps
10 CLEAR 49999
20 BORDER 0: PAPER 0: INK 7: CLS
30 PRINT "LOADING THE CODE"
40 LOAD ""CODE
50 CLS
60 POKE 50000,1: POKE 50001,2: POKE 50002,1: POKE 50026,12
65 POKE 50030,0: POKE 50031,50: POKE 50033,4
68 POKE 50047,50: POKE 50049,0: POKE 50050,25: POKE 50051,1: POKE 50052,3
70 PRINT #0;"O LEFT, P RIGHT, SPACE FIRES, Q STOPS"
80 POKE 23672,0: POKE 23673,0: POKE 23674,0
90 RANDOMIZE USR 50053
95 IF PEEK 50046 THEN GO TO 300
100 LET H=PEEK 23673: LET L=PEEK 23672
110 IF PEEK 23673<>H THEN GO TO 100
120 LET F=L+256*H
130 LET M=PEEK 50003+256*PEEK 50004
140 LET N=PEEK 50005+256*PEEK 50006
150 LET S=PEEK 50007+256*PEEK 50008
160 LET T=PEEK 50009
165 LET G=PEEK 50022+256*PEEK 50023
170 CLS
180 PRINT "FRAMES ";F
190 PRINT "MOVES  ";M
200 PRINT "PASSES ";N
210 PRINT "SHOT STEPS ";S
220 PRINT "SHOTS  ";T
225 PRINT "MARCH STEPS ";G
226 PRINT "HITS ";PEEK 50024
227 PRINT "ALIVE ";PEEK 50025
228 PRINT "BOMBS ";PEEK 50038
229 PRINT "CANCELS ";PEEK 50039;"  CHIPS ";PEEK 50040;"  STOMPS ";PEEK 50041
230 PRINT "SCORE ";PEEK 50042+256*PEEK 50043;"  WAVE ";PEEK 50045;"  LIVES ";PEEK 50044
231 IF N>0 THEN PRINT "FRAMES A PASS ";F/N
240 IF M>0 THEN PRINT "FRAMES A MOVE ";F/M
250 IF S>0 THEN PRINT "FRAMES A SHOT STEP ";F/S
255 IF G>0 THEN PRINT "FRAMES A MARCH STEP ";F/G
260 IF INKEY$<>"" THEN GO TO 260
270 STOP
300 BEEP 0.08,7: BEEP 0.08,4: BEEP 0.08,0: BEEP 0.25,-12
310 CLS
320 PRINT AT 8,11;"GAME OVER"
330 IF PEEK 50046=2 THEN PRINT AT 10,8;"THEY HAVE LANDED"
340 IF PEEK 50046=1 THEN PRINT AT 10,10;"OUT OF LIVES"
350 PRINT AT 12,10;"SCORE ";PEEK 50042+256*PEEK 50043
360 PRINT AT 13,11;"WAVE ";PEEK 50045
370 PRINT AT 16,2;"PRESS ANY KEY TO PLAY AGAIN"
380 IF INKEY$<>"" THEN GO TO 380
390 IF INKEY$="" THEN GO TO 390
400 GO TO 50
```

## Building and running

On Windows, from the course folder:

```
windows-tools\build.bat chapter-05-machine-code-games\step14-game.bas chapter-05-machine-code-games\step14-game.asm game 10
```

On Linux:

```
tools/build.sh chapter-05-machine-code-games/step14-game.bas chapter-05-machine-code-games/step14-game.asm game 10
```

The examples:

```
windows-tools\build.bat chapter-05-machine-code-games\step14-examples.bas chapter-05-machine-code-games\step14-examples.asm examples 20
```

```
tools/build.sh chapter-05-machine-code-games/step14-examples.bas chapter-05-machine-code-games/step14-examples.asm examples 20
```

## What it showed in Fuse

The tape was loaded in a 48K Fuse at normal speed.

- **A whole game.** The `auto` test copy, with a seed of 77, played a game to its end.
  - It cleared wave 1 with the score at exactly 640, which is 8 × 30 + 16 × 20 + 8 × 10.
  - Wave 2 came on at once, a row lower, with whole shields and `WAVE 02` (`step14-game.png`, taken just after, with one base already lost).
  - The game ended with the third base, `OVER 1`, at a score of 1240 on wave 2. There were 62 hits, 62 bombs and 125 chips, in 5803 passes and 5841 frames (`step14-game-result.png`).
  - The 38 extra frames were the waits: 3 lost-base notes of 9 frames each, 2 `newwave`s of 3.8 and one set of wave notes of 3, about 37 in all.
- **A lost base.** In a copy with bombs every 5 passes, a bomb hit the base in column 30. The starburst showed and `LIVES` went from 2 to 1. About a second later the next base was in column 15 (`step14-game-respawn.png`: before, the burst, the new base).
- **Out of lives.** With 2 lives and the base left still, the second hit ended the game. The game-over screen said `OUT OF LIVES`, with the score and the wave (`step14-game-over.png`). A key started a new game, with the score at 00000, wave 01 and the shields drawn again (`step14-game-again.png`; a bomb has already chipped the second).
- **They landed.** With `bfirst` 12, `mfirst` 3 and no bombs, the block landed within seconds, and the game-over screen said `THEY HAVE LANDED` (`step14-game-landed.png`).
- **Row 0.** The status line was whole in every screenshot. Nothing else prints there now: shots stop at row 1, and the messages are on the game-over screen.
- **The ripple** is shown in `step14-game-ripple.png`.
- **The examples** gave the tables above (`step14-examples.png`).

pasmo and z80asm gave the same 2377 bytes for `step14-game.asm`, and the same non-zero bytes for `step14-examples.asm`.

## The timing, against BASIC

| What | Chapter 4, step 8 | This step, as shipped | This step, no `halt` |
|------|------------------:|----------------------:|---------------------:|
| An idle pass | 6.5 | 1 | 0.0075 (30001 passes in 224 frames) |
| A march step | a 106-frame cycle (102 on wave 2) | 25 frames (41 steps in 1025 frames), 22 on wave 2 | 4 rows of 0.21 |
| A sound in play | 1.2 for each `BEEP 0.02` | | 0.06 to 0.07 for a click |
| A lost base | 4 for its two `BEEP`s | about 1.2 seconds down | 9 frames for its note |
| A new wave | 3 for its notes, and a redrawn screen | | 3 for its notes, 3.8 to set up |
| The score, printed | | | 0.05 (100 in 5 frames) |
| The status line | | | 0.4 (10 in 4 frames) |

The idle pass was timed with the march and the bombs switched off in a test copy, and nothing pressed. The march figure is 41 steps with nothing else happening: 25 frames a step, exactly `mspeed`. The routines were timed in a copy with loops added, each called 10, 25 or 100 times with `FRAMES` as the stopwatch.

Against Chapter 4, an idle pass is about 870 times as quick. A click stops the game for less than a tenth of the time a `BEEP` did.

**The frame budget.** Both budget tests ran a march step as often as it could go (`mfirst` 1), a drop or bomb step on every pass, and the `auto` routine moving and firing, with a hit on the base only counted. Frames were counted from the first pass of the loop, since `newwave` at the start takes 3.8 of its own.

| Copy | From row 1, until the landing | From row 12, on the shield rows |
|------|------|------|
| Without the ripple | 244 march steps, 17 hits: 244 passes in 245 frames | 46 march steps, 7 hits: 46 passes in 48 frames |
| With the ripple, as shipped | 254 march steps, 27 hits, 130 bombs, 62 chips: 1013 passes in 1013 frames | 48 march steps, 23 hits, 58 bombs, 15 stomps: 189 passes in 189 frames |

Without the ripple, a pass with a march step and a hit, a score and a click ran over. It did so once in 244 passes from row 1, and twice in 46 on the shield rows. With the ripple, not one pass ran over. The worst pass now adds up to about half a frame:

- a march row, 0.21;
- a hit with its score and click, about 0.16;
- a bomb step, a shot step and a drop click, about 0.12.

The budget test is also 4 times as long in passes, because a march step now takes 4 of them (`mfirst` 1 waits for the ripple to finish).

`step14-game-budget.png` shows the two counts screens from row 1, without and with the ripple.

## Line by line

- **`score` to `nlives`**, 50042 to 50052: the score, the lives, the wave, `over`, the lost base's wait (`rlen`, `rtime`), `quiet`, and the first wave's speed, row and lives. The entry point moves to 50053. `bordcr`, `font` and `white` are new names; `chanopen` has gone.
- **`start`** clears every count and the score, sets the lives from `nlives` and the wave to 1, puts the base in column 15, colours row 0 white and row 21 green, draws the base and calls `newwave`.
- **The loop** has a new beat, `rbase`, after the explosion's. While `dead` is set it counts `rtime` down. At 0 it calls `newbase`, or returns with `over` = 1 if no lives are left. The march beat calls `mrow` while `rip` is under 4. It starts a step only when the last one has finished, and after `mstep` it returns if `over` is set.
- **`fire`** plays sound 0. **`drop`** plays sound 2.
- **`hit`** adds the row's points, from `points`, before `erub` can change `irow`. It prints the score and plays sound 1. When the last invader goes, it counts the wave up (to 99 at most), plays sounds 4 to 6 and jumps to `newwave`.
- **`bhit`** takes a life, prints it, sets `rtime` from `rlen` and plays sound 3. `dead` still stops the march, the bombs and the keys while the base is down.
- **`land`** sets `landed` and `over` = 2.
- **`mstep`** ends by setting `rip` to 0 instead of moving the block. **`mrow`** moves one row.
- **`where`**, **`rtype`**, **`invat`** and **`inbl`**: as above.
- **`newwave`**, **`clear`**, **`newbase`**, **`status`**, **`plives`**, **`pscore`**, **`pwave`**, **`pdec`**, **`ptext`**, **`pchar`**: as above. `newbase` makes the burst's cell green again before rubbing it out, since `redraw` does not set the base's colour.
- **`sound`** and **`delay`** are step 6's. **`sounds`**, **`stext`**, **`points`** and **`tens`** are the tables. `pstr` and the three messages have gone.

## Limitations you will notice

- **A short pause between waves**, about a seventh of a second: 3 frames of notes and 3.8 to set up. Chapter 4 paused there too, for its notes and its `CLS`.
- **A lost base stops everything** for its note, 0.18 of a second, and then the block and the bombs wait for the next base.
- **The score stops at 65535**, which is about 100 waves. It would go round to 0 after that. The wave stops at 99.
- **The status line is printed with the ROM's letters.** A game font would be eight bytes a letter in the program, with `font` pointing at it.
- **The game-over screen is BASIC's**, and it waits for a key. That is the right place for slow code, but it means a full game needs both halves loaded.
- **`nlives` above 9** shows a wrong character, since `plives` prints one digit.

## Try this

Each of these was tried in Fuse.

- Make the game your own: poke `nlives` (50052) as 5, `bfirst` (50051) as 6 and `mfirst` (50050) as 10 on line 69. The game starts with `LIVES 5` and a lower, faster block. In the test, after 12 seconds, it had already stepped down past row 6 (left of `step14-game-try.png`).
- Change the points: they are the four bytes at `points`, 52131 to 52134. Poked all as 50, every hit scores 50. In the test, 21 hits gave a score of 1050 (right of `step14-game-try.png`).
- Watch the ripple: poke `halts` (50000) as 10 and `dwait` (50031) as 255, and the game runs at a tenth of its speed. Each march step goes down the block a row at a time, top row first (`step14-game-ripple.png`).
