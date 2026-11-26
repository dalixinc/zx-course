# Chapter 5, step 15 — Moving by pixels

Up to now everything in the game has moved a whole character cell at a time. The base jumped 8 pixels for each press, the shot went up a row at a time, and the bombs came down a row at a time. That is how BASIC's `PRINT AT` works, and it is how Chapter 4's game had to work. Machine code does not have to. The screen is a bitmap, and the code can put any pixel anywhere.

This step moves three things by pixels:

- **the base**, sideways, `pstep` pixels at a time (2 as shipped);
- **the shot**, up, `slines` pixel lines a step (4);
- **the bomb**, down, `dlines` pixel lines a step (2).

All three are drawn with **XOR**, so drawing one twice takes it off again. The base can sit across two screen bytes, so each of its lines is **shifted into place at run time**. The shot and the bomb stay in their character column, so they need no shift; they only need the address of any pixel line, and that is Chapter 3, step 8's screen address, reused as it was.

**The block of invaders, the shields and the explosions stay cell-based.** That is a choice, not something forgotten. An invader moved by pixels would have to be shifted, like the base, and it would also have to leave what is behind it alone and keep its own shape over other things, which XOR does not do (the examples show why). Doing that for 32 invaders a march step, inside a frame, needs copies of every frame shifted in advance, with masks, and a routine that draws a sprite wherever it is told. That is Chapter 6's sprite engine. This step builds the pieces, with one object each way, so that Chapter 6 starts from something you have seen working.

Every program here was assembled with pasmo, cross-checked against z80asm, and run in a 48K emulator before it was shown.

## The new instructions and ideas

There are no new instructions: `srl`, `rr`, `xor`, `and`, `or` and `cpl` have all been used before. The new ideas are:

- the address of any pixel line, not only the top line of a cell;
- shifting a graphic into place at run time;
- shifted copies made in advance;
- drawing with XOR, and drawing with a mask;
- keeping XOR drawing right when cell drawing goes over it;
- testing for hits when things are not on cell boundaries.

The examples are in `step15-examples.asm`, with a BASIC driver, `step15-examples.bas`. `step15-examples.png` is its screen, and the results below are copied from it.

### The address of any pixel line: pixad and nxtdn

`cell` gives the address of the top line of a cell, and `inc h` goes down the cell's eight lines. A shot whose top is on line 161 starts in the middle of a cell, and as it goes up it crosses from one cell to the next. So this step needs the address of any line, y from 0 to 191, in any byte column.

Chapter 3, step 8 explained the bitmap's address bits as `010 TT RRR` in the high byte and `CCC XXXXX` in the low byte: the third, the pixel row in the cell, the character row in the third, and the column. Written in terms of the line y, whose bits are y7 to y0, that is:

```
H = 0 1 0 y7 y6 y2 y1 y0        L = y5 y4 y3 X X X X X
```

y7 y6 is the third (`TT`), y5 y4 y3 the character row in it (`CCC`), and y2 y1 y0 the line in the cell (`RRR`). `pixad` builds exactly that, with B the line and C the byte column:

```
pixad:  ld a,b
        and 7           ; y2 y1 y0: the line in its cell
        or 64           ; 010 on top
        ld h,a
        ld a,b
        rrca
        rrca
        rrca            ; y7 y6 now in bits 4 and 3
        and 24
        or h
        ld h,a          ; H = 010 y7 y6 y2 y1 y0
        ld a,b
        rlca
        rlca            ; y5 y4 y3 now in bits 7, 6 and 5
        and 224
        or c
        ld l,a          ; L = y5 y4 y3 and the column
        ret
```

To go down from there, the shot and the bomb use Chapter 3, step 8's `nxtdn`, copied as it was: `inc h`, and if that leaves the cell, add 32 to L and take back the 8 unless the third changed.

Example 1 works out six addresses with `pixad`:

| y | column | address | |
|--:|--:|--:|---|
| 0 | 0 | 16384 | the top of the screen |
| 1 | 0 | 16640 | one line down is 256 on |
| 8 | 0 | 16416 | the next character row is 32 on, Chapter 3's 16416 |
| 64 | 0 | 18432 | the middle third, Chapter 3's 18432 |
| 168 | 15 | 20655 | the base's top line, in the middle of the bottom row |
| 191 | 31 | 22527 | the last byte of the bitmap |

### Shifting at run time

A byte of the screen holds 8 pixels across. If the base is at pixel column 120, it is all in byte 15, as before. At 121 its 8 pixels are 1 to the right: 7 in byte 15 and 1 in byte 16. So each line of the base has to be shifted right by `px AND 7` pixels, and the pixels that come off the right-hand end go into the byte next to it. `basex` does it with two instructions a pixel:

```
bs2:    srl a           ; one pixel right; the right-hand one into the carry
        rr c            ; and from the carry into C
        djnz bs2
```

`srl a` moves the line right and puts the pixel that falls off into the carry. `rr c` takes the carry into the top of C, so C collects the spill in the right order. After `px AND 7` times, A is the left-hand byte and C the right-hand one. With a shift of 0 the loop is skipped and C stays 0.

That is simple and needs no extra memory, but its time depends on the shift: a shift of 7 does the pair 7 times on each of 8 lines. Example 2 draws the base 510 times at a shift of 7 and takes **25 frames**, 0.049 of a frame a draw. In the game, `basex` at a shift of 7 took 5 frames for 100 calls, and at a shift of 0, 2 frames. A move is two calls, off and on, so it costs up to 0.1 of a frame.

### Shifted copies made in advance

The other way is to do the shifting once, before the game, and keep the results. Example 5 makes eight copies of the base, shifted 0 to 7 pixels, each 8 lines of 2 bytes: 128 bytes in all. To draw, Example 3 picks the copy for `px AND 7` and XORs its two bytes a line, with no shifting at all. The same 510 draws took **11 frames**, 0.022 a draw, less than half the time, and the same at every shift. The two columns on the left of `step15-examples.png` are the base at pixels 16 to 23 by run time shifting, and at 80 to 87 from the copies: they are the same.

The cost is memory: 16 bytes for each shift of a 1-byte-wide graphic, and more for each frame of an animation. For one base it does not matter which, so the game shifts at run time and keeps the listing short. For 32 invaders in 3 frames it matters a great deal, and that is why Chapter 6 makes copies.

### XOR, and masks

XOR flips pixels: a 1 in the graphic turns the screen's pixel over, and a 0 leaves it alone. So XORing a graphic on and then XORing it again leaves the screen exactly as it was. That is why the game can move the base, the shot and the bomb without knowing what was under them: take it off with XOR, move it, put it on with XOR.

The cost shows over a pattern. On the right of `step15-examples.png` is a checkerboard, and the third column is the base XORed onto it. Where the base's pixels meet pixels that are on, they turn off, so the base comes out as a scramble (`step15-examples-zoom.png` shows it at three times the size). It is still there, and it comes off cleanly, but you can hardly see it.

The fourth column is drawn with a **mask** instead. A mask is a second graphic, with 0 where the base is and on a border one pixel wide round it, and 1 everywhere else. Each screen byte is ANDed with the mask, which clears that shape, and then the base is ORed in:

```
        ld a,(bc)
        and (hl)        ; clear the mask's 0 bits
        ex de,hl
        or (hl)         ; and put the base's 1 bits in
```

The base is solid on the pattern, with a black edge round it. The price is that what was under it is gone: to take it off, the code needs a copy of the background, or to draw the background again. That is the second half of a sprite engine, and Chapter 6's job. Example 5 makes the masks with the copies: each line, ORed with itself shifted a pixel each way, then inverted with `cpl`.

The game uses XOR because most of its screen is black. A bomb that goes over an invader is the one place you see it mix (see "Limitations").

### Cells drawn over XOR: the put wrapper

XOR drawing has a rule: nothing else must change the pixels under the object while it is there, or taking it off will leave a mess. In this game, cells are still drawn by `put` (the march, the explosions, the shields), and some of them are cells the shot or the bomb is passing through. So `put` is now a wrapper. Before it draws a cell, it looks to see if the shot or the bomb covers it:

- the shot covers rows `sr1` and `sr2` (the rows of its top and bottom lines) in column `scol`;
- the bomb covers `br1` and `br2` in `bcol`;
- 255 in `sr1` or `br1` means it is not on the screen.

If one of them is there, `put` takes it off with XOR, draws the cell with `rawput` (the old `put`), and XORs it back on. The cell is right, and the object is on top of it as before.

### Hits when nothing is on a cell boundary

Every test so far has been "the same cell". Now:

- **The shot** is tested at the cell of its top line, `sy / 8`, against invaders (`invat`) and shields (`chip`), so it hits as soon as its tip enters a cell.
- **The bomb** is tested at the cell of its bottom line, `(dy + 7) / 8`. On row 21 it is the base's row, and the base is hit if the bomb's 8 pixel columns and the base's overlap: `bcol * 8 - px` from -7 to 7. Adding 7 makes that 0 to 14, one unsigned test, `cp 15`. Otherwise it goes into the ground.
- **The shot and the bomb** meet (`ctest`) if they are in the same column and their lines overlap. The shot covers `sy` to `sy + 5` and the bomb `dy` to `dy + 7`, so they overlap when `sy - dy` is -5 to 7; adding 5 makes that one test, `cp 13`.

## The listing

The machine code, `step15-pixels.asm`. It is step 14's, with these changes:

- new bytes `px`, `pstep`, `slines` and `dlines`, 50053 to 50056; the entry point moves to 50057;
- `x` is now worked out from `px`, as the column of the base's middle;
- the base moved by `left`, `goright` and `pmove`, and drawn by `basex`;
- the shot moved by `sstep` and drawn by `son`, `soff` and `sxor`, with its graphic and `sdraw` gone;
- the bomb moved by `bstep` and drawn by `bon`, `boff` and `bxor`, with `brub` gone;
- `ctest` and `btest` testing by pixels;
- `pixad` and `nxtdn`;
- `put` the wrapper, and `rawput` the old `put`;
- the working bytes `sy`, `sr1`, `sr2`, `dy`, `br1` and `br2`.

```
; step15-pixels.asm - Chapter 5, step 15
; Moving by pixels. It is step 14's game, with three things moved by
; pixels instead of by character cells: the base, sideways, pstep
; pixels at a time; the shot, up, slines pixel lines a step; and the
; bomb, down, dlines pixel lines a step. All three are drawn with XOR,
; so drawing one twice takes it off again and leaves what was under it.
; The base is shifted into place at run time, a pixel at a time, since
; it can sit across two bytes. The shot and the bomb stay in their
; character column, so they need no shift, only the pixel line address
; from Chapter 3, step 8. The block, the shields and the explosions are
; still drawn by cells. put now takes the shot or the bomb off any cell
; it is about to draw on, and puts it back after.
;
; BASIC can set or read these bytes at the start of the code:
;   50000        halts   HALTs per pass of the loop; 0 means do not wait
;   50001        bspeed  passes per look at the keys, 1 to 255
;   50002        sspeed  passes per step of the shot, 1 to 255
;   50003-50004  moves   times the base has moved
;   50005-50006  passes  passes of the loop
;   50007-50008  ssteps  steps the shot has taken
;   50009        shots   shots fired
;   50010        x       the column of the base's middle, 0 to 31
;   50011        ptime   passes until the next look at the keys
;   50012        stime   passes until the shot's next step
;   50013        srow    the cell row of the shot's top line, or 255 for
;                        no shot
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
;   50035        brow    the cell row of the bomb's bottom line, or 255
;                        for no bomb
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
;   50053        px      the base's left-hand pixel column, 0 to 248
;   50054        pstep   pixels the base moves at a time, 1 to 8
;   50055        slines  pixel lines the shot moves a step, 1 to 8
;   50056        dlines  pixel lines the bomb moves a step, 1 to 8
;
; start sets everything else for a new game, so a game started again
; from BASIC starts afresh.
;
; Entry point:
;   RANDOMIZE USR 50057  start
;
; Build:  tools/build.sh chapter-05-machine-code-games/step15-pixels.bas chapter-05-machine-code-games/step15-pixels.asm pixels 10

        org 50000

halts:  db 1            ; 50000: HALTs per pass
bspeed: db 1            ; 50001: passes per look at the keys
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
dspeed: db 1            ; 50033: passes per bomb step
dstime: db 1            ; 50034: passes to the bomb's next step
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
px:     db 120          ; 50053: the base's left-hand pixel column
pstep:  db 2            ; 50054: pixels a base move
slines: db 4            ; 50055: pixel lines a shot step
dlines: db 2            ; 50056: pixel lines a bomb step

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
        ld (x),a        ; the base in the middle: column 15,
        ld a,120
        ld (px),a       ; pixel 120
        ld a,255
        ld (sr1),a
        ld (sr2),a
        ld (br1),a
        ld (br2),a      ; no shot or bomb on the screen
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

        call basex      ; draw the base
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

; fire: start a shot above the base, unless one is in flight. Its top
; line is pixel line 161, line 1 of row 20, in x, the column of the
; base's middle. Keeps A, the keys, for the loop. Changes B, C, DE, HL.

fire:   push af         ; keep the keys
        ld a,(srow)
        inc a           ; 255: no shot in flight?
        jr nz,nofire    ; there is one: Space does nothing
        ld a,(x)
        ld (scol),a     ; the shot's column
        ld a,baserow*8-7
        ld (sy),a       ; its top line, 161
        ld a,(sspeed)
        ld (stime),a    ; its first step is a full beat away
        ld hl,shots
        inc (hl)        ; one more shot
        xor a
        call sound      ; sound 0: a click
        call stest      ; draw it, or hit what is there
nofire: pop af          ; the keys again
        ret

; sstep: move the shot up slines pixel lines: take it off the screen,
; move it, and test it where it is now. Once its top line would be on
; row 0 it goes, so it never touches the status line. Changes A, B, C,
; DE, HL.

sstep:  ld hl,(ssteps)
        inc hl
        ld (ssteps),hl  ; one more shot step
        call soff       ; off the screen
        ld a,(slines)
        ld b,a
        ld a,(sy)
        sub b           ; A = its new top line
        cp 8            ; on row 0 (or above, gone round past 0)?
        jr nc,smove     ; no
        ld a,255
        ld (srow),a     ; yes: no shot now
        ret
smove:  ld (sy),a

; stest: the shot's top line is at sy, in the cell row sy / 8, which
; becomes srow. A living invader on that cell is a hit; a shield cell
; eats it; a bomb it meets cancels it. Otherwise it is drawn. The shot
; is not on the screen while it is tested. Changes A, B, C, DE, HL.

stest:  ld a,(sy)
        rrca
        rrca
        rrca
        and 31          ; A = sy / 8: the cell row of its top line
        ld (srow),a
        call scell      ; B, C = that cell
        call invat      ; A = 1 if a living invader is there
        and a
        jr nz,hit       ; yes: a hit
        call scell
        call chip       ; has it come to a shield?
        jr c,sused      ; yes: the shield has eaten it
        call ctest      ; has it met the bomb?
        ret c           ; yes: both are gone
        call scell
        call attr
        ld (hl),yellow  ; its cell in yellow
        jp son          ; and draw it
sused:  ld a,255
        ld (srow),a     ; no shot now
        ret

; son: draw the shot at sy, scol, and note the cell rows it covers,
; sr1 and sr2, for put. soff: take it off, if it is on, and note that
; it is not. Each changes A.

son:    ld a,(srow)
        ld (sr1),a      ; the row of its top line
        ld a,(sy)
        add a,5         ; its bottom line
        rrca
        rrca
        rrca
        and 31
        ld (sr2),a      ; and the row of that
        jr sxor         ; draw it

soff:   ld a,(sr1)
        inc a           ; 255: not on the screen?
        ret z           ; then there is nothing to take off
        ld a,255
        ld (sr1),a
        ld (sr2),a      ; it will not be

; sxor: XOR the shot's six lines, two pixels wide, into the screen at
; pixel line sy, column scol: on if it was off, off if it was on. Keeps
; BC, DE, HL. Changes A.

sxor:   push bc
        push hl
        ld a,(sy)
        ld b,a
        ld a,(scol)
        ld c,a
        call pixad      ; HL = the byte of its top line
        ld b,6          ; 6 lines
sx1:    ld a,(hl)
        xor 24          ; 00011000: its two pixels flip
        ld (hl),a
        call nxtdn      ; the next line down
        djnz sx1
        pop hl
        pop bc
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
        add a,a
        add a,a
        add a,a         ; A = 8 * row: the top line of that row
        ld (dy),a       ; is the bomb's top line
        ld a,c
        ld (bcol),a     ; the bomb starts there
        ld a,(dspeed)
        ld (dstime),a   ; a full beat to its first step
        ld hl,bombs
        inc (hl)        ; one more bomb
        ld a,2
        call sound      ; sound 2: a lower click
        jr btest        ; and see where it is

; bstep: take the bomb off the screen and move it down dlines pixel
; lines. Changes A, B, C, DE, HL.

bstep:  call boff       ; off the screen
        ld a,(dlines)
        ld hl,dy
        add a,(hl)
        ld (hl),a       ; dlines lines down

; btest: the bomb's top line is at dy, and its bottom line, dy + 7, in
; the cell row that becomes brow. On the base's row it has hit the base,
; if the base covers any of its pixel columns, or it goes into the
; ground. Above that, test it against a shield and the shot, then draw
; it. If a living invader is on its cell, the cell keeps the invader's
; colour. Changes A, B, C, DE, HL.

btest:  ld a,(dy)
        add a,7         ; its bottom line
        rrca
        rrca
        rrca
        and 31          ; A = the cell row of its bottom line
        ld (brow),a
        cp baserow      ; on the base's row?
        jr c,bair       ; no: still in the air
        ld a,(bcol)
        add a,a
        add a,a
        add a,a         ; A = 8 * bcol, the bomb's left-hand pixel
        ld hl,px
        sub (hl)        ; A = that - px, round past 0 if negative
        add a,7         ; -7 to 7 becomes 0 to 14
        cp 15           ; within 7 pixels of the base, either way?
        jr c,bhit       ; yes: the base is hit
        jr bused        ; no: it is gone, into the ground
bair:   call bcell      ; B, C = the cell of its bottom line
        call chip       ; has it come to a shield?
        jr c,bused      ; yes: the shield has eaten it
        call ctest      ; has it met the shot?
        ret c           ; yes: both are gone
        call bcell
        call invat      ; is a living invader on its cell?
        and a
        jr nz,bon       ; yes: leave the colour, and draw it
        call bcell
        call attr
        ld (hl),red     ; no: red ink on black paper
        jr bon
bused:  ld a,255
        ld (brow),a     ; no bomb now
        ret

; bon: draw the bomb at dy, bcol, and note its cell rows, br1 and br2,
; for put. boff: take it off, if it is on. Each changes A.

bon:    ld a,(dy)
        rrca
        rrca
        rrca
        and 31
        ld (br1),a      ; the row of its top line
        ld a,(brow)
        ld (br2),a      ; and of its bottom line
        jr bxor

boff:   ld a,(br1)
        inc a           ; 255: not on the screen?
        ret z
        ld a,255
        ld (br1),a
        ld (br2),a

; bxor: XOR the bomb's 8 lines into the screen at pixel line dy, column
; bcol. Keeps BC, DE, HL. Changes A.

bxor:   push bc
        push de
        push hl
        ld a,(dy)
        ld b,a
        ld a,(bcol)
        ld c,a
        call pixad      ; HL = the byte of its top line
        ld de,bombg
        ld b,8          ; 8 lines
bx1:    ld a,(de)
        xor (hl)
        ld (hl),a       ; flip its pixels on this line
        inc de
        call nxtdn
        djnz bx1
        pop hl
        pop de
        pop bc
        ret

; bcell: B = the cell row of the bomb's bottom line, C = its column.
; Changes A.

bcell:  ld a,(brow)
        ld b,a
        ld a,(bcol)
        ld c,a
        ret

; bhit: the bomb has hit the base. End the bomb and the shot, take the
; base off and put a starburst on the cell of its middle, take a life,
; and keep the base down for rlen passes; the base's beat in the loop
; does the rest. Changes A, B, C, DE, HL.

bhit:   ld a,1
        ld (dead),a     ; the base is hit
        ld a,255
        ld (brow),a     ; no bomb (it is not on the screen)
        call soff       ; the shot off the screen, if it is on
        ld a,255
        ld (srow),a     ; and no shot
        call basex      ; the base off the screen
        ld a,(x)
        ld c,a
        ld b,baserow    ; B, C = the cell of its middle
        call attr
        ld (hl),yellow
        ld de,burst
        call put        ; the starburst there
        ld hl,lives
        dec (hl)        ; one base fewer
        call plives     ; print it
        ld a,(rlen)
        ld (rtime),a    ; down for rlen passes
        ld a,3
        jp sound        ; sound 3: a long low note

; ctest: if a shot and a bomb are both in flight, in the same column,
; and their pixel lines overlap, they have met: take both off the
; screen, end both, and return with the carry set. The shot covers lines
; sy to sy + 5 and the bomb dy to dy + 7, so they overlap when sy - dy
; is -5 to 7. Otherwise return with the carry clear. Changes A, B, HL.

ctest:  ld a,(brow)
        inc a
        jr z,noc        ; no bomb
        ld a,(srow)
        inc a
        jr z,noc        ; no shot
        ld a,(bcol)
        ld hl,scol
        cp (hl)         ; the same column?
        jr nz,noc
        ld a,(dy)
        ld b,a
        ld a,(sy)
        sub b           ; A = sy - dy
        add a,5         ; -5 to 7 becomes 0 to 12
        cp 13
        jr nc,noc       ; they do not overlap
        call boff
        call soff       ; both off the screen
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

; left: move the base pstep pixels left, no further than pixel 0. Take
; it off, move it, and draw it again. Changes A, B, C, DE, HL.

left:   ld a,(px)
        and a           ; already at pixel 0?
        ret z           ; yes
        call basex      ; off
        ld a,(pstep)
        ld b,a
        ld a,(px)
        sub b           ; pstep pixels left
        jr nc,pmove
        xor a           ; past 0: stop at 0
        jr pmove

; goright: the same, to the right, no further than pixel 248, where the
; base's right-hand edge is the screen's.

goright: ld a,(px)
        cp 248          ; already at the right?
        ret nc          ; yes
        call basex      ; off
        ld a,(pstep)
        ld hl,px
        add a,(hl)      ; pstep pixels right
        cp 249
        jr c,pmove
        ld a,248        ; past 248: stop at 248

pmove:  ld (px),a       ; the new place
        add a,4
        rrca
        rrca
        rrca
        and 31
        ld (x),a        ; x = (px + 4) / 8, the column of its middle
        call basex      ; draw it there
        ld hl,(moves)
        inc hl
        ld (moves),hl   ; one more move
        ret

; basex: XOR the base into row 21 at pixel column px. Its 8 pixels
; across can sit across two bytes, so each line is shifted right px AND
; 7 times, with the pixels that fall off the right-hand end caught in C
; for the next byte. Changes A, B, C, DE, HL.

basex:  ld a,(px)
        rrca
        rrca
        rrca
        and 31
        ld c,a          ; C = the byte column of its left-hand pixel
        ld b,baserow*8  ; its top line, 168
        call pixad      ; HL = that byte
        ld de,base
        ld b,8          ; 8 lines
bs1:    push bc
        ld a,(px)
        and 7           ; the shift, 0 to 7
        ld b,a
        ld a,(de)       ; A = this line of the base
        ld c,0          ; C = the pixels for the next byte
        jr z,bs3        ; a shift of 0: nothing to do
bs2:    srl a           ; one pixel right; the right-hand one into the carry
        rr c            ; and from the carry into C
        djnz bs2
bs3:    xor (hl)
        ld (hl),a       ; flip the left-hand byte's pixels
        inc l
        ld a,c
        xor (hl)
        ld (hl),a       ; and the right-hand byte's
        dec l
        inc h           ; the next line down: all 8 are in row 21
        inc de
        pop bc
        djnz bs1
        ret

; pixad: HL = the screen address of pixel line B, 0 to 191, byte column
; C, 0 to 31. Chapter 3, step 8's address bits: the line y is
; y7 y6 y5 y4 y3 y2 y1 y0, and the address is
;   H = 0 1 0 y7 y6 y2 y1 y0     L = y5 y4 y3 C C C C C
; Changes A.

pixad:  ld a,b
        and 7           ; y2 y1 y0: the line in its cell
        or 64           ; 010 on top
        ld h,a
        ld a,b
        rrca
        rrca
        rrca            ; y7 y6 now in bits 4 and 3
        and 24
        or h
        ld h,a          ; H = 010 y7 y6 y2 y1 y0
        ld a,b
        rlca
        rlca            ; y5 y4 y3 now in bits 7, 6 and 5
        and 224
        or c
        ld l,a          ; L = y5 y4 y3 and the column
        ret

; nxtdn: HL = the address one pixel line below HL, in the same column.
; Chapter 3, step 8's routine. Changes A.

nxtdn:  inc h           ; down one pixel line
        ld a,h
        and 7           ; still inside the same cell?
        ret nz          ; yes: done
        ld a,l
        add a,32        ; next character row
        ld l,a
        ret c           ; carry: into the next third, H is right
        ld a,h
        sub 8           ; same third: undo the carry into the third
        ld h,a
        ret

; put: copy the 8 bytes at DE into the cell at row B, column C. If the
; shot or the bomb is on that cell, it is taken off first and put back
; after, so that the XOR drawing stays right. Changes A, B, DE and HL.

put:    ld a,(scol)
        cp c            ; the shot's column?
        jr nz,pbomb     ; no
        ld a,(sr1)
        cp b            ; one of the shot's rows?
        jr z,pshot
        ld a,(sr2)
        cp b
        jr nz,pbomb     ; no
pshot:  call sxor       ; take the shot off
        call pbomb      ; the bomb too, if it is there, then the cell
        jp sxor         ; and put the shot back
pbomb:  ld a,(bcol)
        cp c            ; the bomb's column?
        jr nz,rawput    ; no: just draw
        ld a,(br1)
        cp b            ; one of the bomb's rows?
        jr z,pbomb2
        ld a,(br2)
        cp b
        jr nz,rawput    ; no
pbomb2: call bxor       ; take the bomb off
        call rawput     ; draw the cell
        jp bxor         ; and put the bomb back

; rawput: put, as it was: the 8 bytes at DE into the cell.

rawput: call cell       ; HL = the top byte of the cell
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
        ld (sr1),a
        ld (sr2),a
        ld (br1),a
        ld (br2),a      ; and none on the screen: clear rubs them out
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
; the next base at pixel 120, column 15. Changes A, B, C, DE, HL.

newbase: ld a,(x)
        ld c,a
        ld b,baserow    ; the burst's cell
        call attr
        ld (hl),green   ; green again, for the base when it comes here
        ld de,blank
        call put        ; rub out the burst
        ld a,15
        ld (x),a        ; the middle: column 15,
        ld a,120
        ld (px),a       ; pixel 120
        call basex      ; the new base
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
sy:     db 0            ; the shot's top pixel line
sr1:    db 255          ; the cell rows the shot covers on the screen,
sr2:    db 255          ; or 255 when it is not on the screen
dy:     db 0            ; the bomb's top pixel line
br1:    db 255          ; the cell rows the bomb covers on the screen,
br2:    db 255          ; or 255
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

The BASIC driver, `step15-pixels.bas`. It is step 14's, with `bspeed` and `dspeed` set to 1 on line 60 and 65, the new bytes set on line 69, and `USR 50057`:

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
60 POKE 50000,1: POKE 50001,1: POKE 50002,1: POKE 50026,12
65 POKE 50030,0: POKE 50031,50: POKE 50033,1
68 POKE 50047,50: POKE 50049,0: POKE 50050,25: POKE 50051,1: POKE 50052,3
69 POKE 50053,120: POKE 50054,2: POKE 50055,4: POKE 50056,2
70 PRINT #0;"O LEFT, P RIGHT, SPACE FIRES, Q STOPS"
80 POKE 23672,0: POKE 23673,0: POKE 23674,0
90 RANDOMIZE USR 50057
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
windows-tools\build.bat chapter-05-machine-code-games\step15-pixels.bas chapter-05-machine-code-games\step15-pixels.asm pixels 10
```

On Linux:

```
tools/build.sh chapter-05-machine-code-games/step15-pixels.bas chapter-05-machine-code-games/step15-pixels.asm pixels 10
```

The examples:

```
windows-tools\build.bat chapter-05-machine-code-games\step15-examples.bas chapter-05-machine-code-games\step15-examples.asm examples 20
```

```
tools/build.sh chapter-05-machine-code-games/step15-examples.bas chapter-05-machine-code-games/step15-examples.asm examples 20
```

## What it showed in Fuse

The tape was loaded in a 48K Fuse at normal speed.

- **The game plays as step 14's did**, with the base, the shot and the bombs moving smoothly (`step15-pixels.png`: two moments of a game, with a shot and a bomb in flight between cells).
- **The pixel steps.** `step15-pixels-moving.png` is a copy slowed down (`halts` 5, no bombs), taken a few frames apart. In the top row P is held and the base moves right 2 pixels at a time; in the bottom row a shot climbs by pixel lines, through the middle of cells, past the shield beside it without touching it.
- **A whole game.** The `auto` test copy, with a seed of 77, played until it was out of lives: `OVER 1`, a score of 480 on wave 1, 25 hits, 37 bombs, 69 chips and 5 cancels, in 3386 passes and 3417 frames (`step15-pixels-result.png`). The 31 extra frames are the 3 lost-base notes of 9 frames each and `newwave` at the start.
- **No stray pixels.** Each test copy ends with a routine that looks at every cell of rows 1 to 20 that should be empty (no living invader, no shield, no shot, no bomb, no explosion) and counts any with a pixel on. Four games, with seeds 77, 9 and 200 and different bomb rates, one of them through to wave 2 with 45 hits, all counted **0** (`step15-pixels-stray.png`, and the result above). That is the check that the XOR drawing and the `put` wrapper agree: any shot or bomb left behind, or a bit of one, would count.
- **The examples** gave the addresses and timings above (`step15-examples.png`, and `step15-examples-zoom.png` for the checkerboard).

pasmo and z80asm gave the same 2656 bytes for `step15-pixels.asm`, and the same non-zero bytes for `step15-examples.asm`.

## The timing, against BASIC

| What | Chapter 4, step 8 | Step 14 | This step, no `halt` |
|------|------------------:|--------:|---------------------:|
| An idle pass | 6.5 | 0.0075 (keys every 2 passes) | 0.018 (57657 passes in 1052 frames, keys every pass) |
| A march step, as shipped | a 106-frame cycle | 25 frames | 25 frames (112 steps in 2804 frames) |
| Drawing the base once | | | 0.05 at a shift of 7, 0.02 at 0 (100 in 5 and 2 frames) |
| A base move, off and on | | | up to 0.1 |
| Drawing the shot once | | | 0.01 (100 in 1 frame) |
| Drawing the bomb once | | | 0.01 (100 in 1 frame) |
| A march row | | 0.21 | 0.22 (100 in 22 frames) |

The idle pass was timed in a copy with the bombs and the march switched off, `halts` 0 and nothing pressed. It is more than twice step 14's because the keys are now read on every pass (`bspeed` 1, against step 14's 2), so a press moves the base 2 pixels a pass rather than 8 pixels every second pass. The routines were timed in a copy with loops added, with `FRAMES` as the stopwatch. A march row costs a little more than step 14's, since `put` now checks for the shot and the bomb on every cell.

Against Chapter 4, the base moves a quarter as far each time and much more often, and it is still far inside the frame.

**The frame budget.** As in step 14, both budget tests ran a march step as often as it could go (`mfirst` 1), a bomb step on every pass with a new bomb on the next (`dwait` 1), and the `auto` routine moving and firing, with a hit on the base only counted. Frames were counted from the first pass of the loop.

| Copy | From row 1, until the landing | From row 12, on the shield rows |
|------|------|------|
| This step | 244 march steps, 19 hits, 46 bombs, 55 chips: 973 passes in 973 frames | 46 march steps, 9 hits, 22 stomps: 181 passes in 181 frames |

Not one pass ran over. The worst pass adds up to well under a frame: a march row, 0.22; a hit with its score and click, about 0.16 (step 14's figures); a base move, up to 0.1; a shot step and a bomb step, each about 0.02 for off and on, plus their tests.

`step15-pixels-budget.png` shows the two counts screens.

## Line by line

- **`px` to `dlines`**, 50053 to 50056: the base's left-hand pixel column, 0 to 248, and the three step sizes. The entry point moves to 50057. `bspeed` and `dspeed` are now 1, so the base and the bomb step every pass.
- **`start`** puts the base at pixel 120 (the old column 15), marks the shot and the bomb off the screen in `sr1`, `sr2`, `br1` and `br2`, and draws the base with `basex`. **`newbase`** puts the next base at pixel 120 and draws it the same way. **`newwave`** marks them off the screen before it clears it.
- **`left`** and **`goright`** take the base off, move `px` by `pstep`, no further than 0 or 248, and fall into **`pmove`**, which stores it, works out `x = (px + 4) / 8`, the column of the base's middle, draws it and counts the move. Firing and the burst use `x`.
- **`basex`**: as above. All 8 lines are in row 21, so `inc h` is enough to go down.
- **`fire`** starts the shot with its top on line 161, in column `x`, and calls `stest`.
- **`sstep`** takes the shot off, moves `sy` up `slines`, and ends it if the top would be above line 8, so it never touches the status line. Otherwise it falls into **`stest`**, which works out `srow` and tests the cell of the top line: an invader is a hit, a shield eats it, a bomb cancels it, and otherwise it is coloured yellow and drawn by **`son`**.
- **`son`**, **`soff`** and **`sxor`**: draw it and note `sr1` and `sr2`; take it off if it is on and mark it off; and the XOR itself, 6 lines of the two middle pixels, with `pixad` and `nxtdn`.
- **`drop`** puts the bomb's top on the top line of the row below the lowest living invader of its column.
- **`bstep`** takes the bomb off and moves `dy` down `dlines`, and falls into **`btest`**, as above. In the air it is coloured red, unless a living invader is on its cell, and drawn by **`bon`**.
- **`bon`**, **`boff`**, **`bxor`** and **`bcell`**: the same for the bomb, 8 lines of `bombg`.
- **`bhit`** ends the bomb and the shot, takes the base off with `basex`, and puts the starburst on the cell of its middle.
- **`ctest`**: as above.
- **`pixad`** and **`nxtdn`**: as above.
- **`put`** and **`rawput`**: as above.

## Limitations you will notice

- **The invaders, the shields and the explosions still move by cells.** For why, and what it takes, see the start of this step: it is Chapter 6.
- **The shot leaves from the cell column of the base's middle**, not from the barrel's exact pixel, so it can be up to 4 pixels to one side of the barrel. Moving the shot by pixels sideways too would need it shifted like the base, and every test against the cell-based invaders and shields would have to cover two columns.
- **A bomb over an invader mixes with it**, since it is XORed on: where their pixels meet, they go off. It lasts only while the bomb passes.
- **The speeds are not step 14's.** The base moves 2 pixels a pass, so it crosses the screen in about 2.5 seconds, more slowly than step 14's 8 pixels every second pass. The shot climbs 4 lines a pass, half step 14's speed. The bomb falls 2 lines a pass, the same as step 14's. All three are bytes you can poke (see below).
- **The stray-cell test covers rows 1 to 20.** Row 21, the base's row, is where the base and the starburst are drawn, and it was checked by eye in the screenshots only.

## Try this

Each of these was tried in Fuse, with bombs held off (`dwait` 255) on line 75 so the base could be moved freely, holding P for one second from the middle, and `PX` added to the counts screen (`step15-pixels-try.png`).

- Poke `pstep` (50054) as 1 on line 69. The base creeps: 51 moves in the second took it from 120 to 171.
- Poke `pstep` as 4. It moved 32 times and reached the right-hand edge, 248, within the second.
- Poke `slines` (50055) as 8: the shot goes up a whole row a step, as in step 14. A shot from the right-hand edge took 20 steps to reach the top, against 39 at 4 (`step15-pixels-try2.png`, top).
- Poke `slines` as 2: it took 77 steps, and you can follow it with your eye (`step15-pixels-try2.png`, bottom).
- Poke `dlines` (50056) as 4 and as 1, with `dwait` 20. In the same time, 25 bombs fell at 4 and 9 at 1.
- Poke `halts` (50000) as 5 and `dwait` as 255 for slow motion, and watch the pixel steps, as in `step15-pixels-moving.png`.
