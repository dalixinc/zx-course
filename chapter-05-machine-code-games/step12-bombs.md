# Chapter 5, step 12 — Bombs

Chapter 4's step 6 gave the invaders a way to fire back. Every so often a column was picked with `RND`, and one bomb dropped from the lowest living invader in it. A bomb that reached the base's row in the base's column ended the run with `YOU ARE HIT`, and a shot and a bomb that met cancelled each other. BASIC paid for it again: an idle pass went from 4.7 frames to 6.7, a bomb took 9 frames a row, and a shot that also had to test for a bomb took 13.6 frames a pass.

This step is its twin. The bomb has two beats of its own: `dwait` frames from one bomb's end to the next drop, 50 as shipped, and `dspeed` frames a row as it falls, 4 as shipped, so a bomb comes down from the block in about a second. Its column comes from step 6's random numbers. Everything the bomb needs to know about the invaders, which columns are alive and which invader is lowest, it reads from the `alive` table, like everything else since step 9.

The costs: an idle pass is 0.0062 of a frame, a pass with a bomb step or a drop 0.033, and a shot step with its bomb test 0.0305. A pass with a march step, a drop or bomb step, a shot step and a hit still fitted in its frame every time.

Every program here was assembled with pasmo, cross-checked against z80asm, and run in a 48K emulator before it was shown.

## The new instructions and ideas

There are no new instructions. The new ideas are a random column from the LFSR, the lowest living invader, a bomb that can be hidden behind an invader, the cancel test, the end of the game, and `JP` where `JR` no longer reaches. The examples are in `step12-examples.asm`, with a BASIC driver, `step12-examples.bas`; `step12-examples.png` is its screen, and the results below are copied from it.

### A random column

`rnd` is step 6's 8-bit LFSR: eight shifts right, with the taps 184 XORed in whenever a 1 falls off. Its byte goes from 1 to 255, and `and 7` keeps the bottom three bits, 0 to 7, a column of the block. `start` takes a seed from the R register if BASIC has poked 0, as step 6 did, so each game is different; a test pokes a seed of its own and gets the same game every time. Example 1 prints sixteen columns from seed 1:

```
4 3 3 4 4 5 5 5 7 6 7 1 3 1 3 5
```

### The lowest living invader

A bomb must not come out of a hole. `drop` picks a column and asks `colalive`, from step 10, whether any of it is alive. If not, it tries the next column, round to 0 after 7, so a bomb is always dropped while any invader is alive. Then it looks up the column from the bottom row for the first living invader:

```
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
```

The loop needs no end test, because `colalive` has already said one of the four is alive. Example 2 shows four drops from each of four tables, as (column, row):

| The table | Drops |
|-----------|-------|
| All alive | 2,3  5,3  6,3  6,3 |
| Columns 0 to 5 empty | 7,3  6,3  6,3  6,3 |
| Only row 0 of column 6, and column 7 | 6,0  7,3  6,0  7,3 |
| None alive | 65535 |

The second line shows the price of "try the next column". A random column from 0 to 5 is empty, and the next living column after it is always 6, so column 6 gets seven chances in eight and column 7 one. Chapter 4 picked again with `RND` instead, up to eight times, and sometimes gave up. See Try this.

### A bomb behind an invader

The bomb starts on the row below an invader, which is always empty. But the block marches while the bomb falls, and a low invader in the next column can march onto the bomb's cell. So the bomb is drawn the way the shot was in step 9: `btest` asks `invat` first, and if a living invader is on the cell it does not draw the bomb, which falls on behind it. `brub`, which rubs the bomb out, draws again any living invader that was on its cell, as `erub` does for the starburst.

On the base's row the bomb is not drawn at all. If the base is in its column, the base is hit; if not, the bomb goes into the ground. Chapter 4's bomb could be printed on row 21; here that would leave a red cell on the base's green row, because `put` draws pixels and leaves the attribute alone.

### The cancel test

Chapter 4 cancelled a shot and a bomb that were in the same column with the shot on the bomb's row or the row below it, `Y=U OR Y=U+1`. The shot moves up a row at a time and the bomb down a row at a time, and each is tested after it moves, so they cannot pass each other without being one of those two ways first. `ctest` does the same, with the shot row less the bomb row in one byte:

```
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
```

`sub` and one `cp 2` do both of BASIC's tests. A shot above the bomb gives a negative difference, which is 255 or close to it in a byte, and fails `cp 2` with the rest. `ctest` returns the answer in the carry flag, so `stest` and `btest` can say `call ctest` and `ret c`. Example 3 is the test on its own:

| Shot (row, column) | Bomb | Met |
|--------------------|------|----:|
| 10, 5 | 10, 5 | 1 |
| 11, 5 | 10, 5 | 1 |
| 12, 5 | 10, 5 | 0 |
| 9, 5 | 10, 5 | 0 |
| 11, 6 | 10, 5 | 0 |
| no shot | 10, 5 | 0 |
| 11, 5 | no bomb | 0 |

### The end of the game

`bhit` sets `dead`, ends the bomb and the shot, puts the starburst on the base's cell in yellow, and prints `YOU ARE HIT` on row 0. Then everything checks `dead`: `mstep` and `drop` return at once, and the keys do nothing but Q. Chapter 4 let the player go on moving the exploded base; here the game is simply over. Lives come in step 14.

### Beats in a row, again

The first run dropped no bombs at all. The explosion's beat, from step 11, jumped to `march` when there was no explosion, straight past the new `bomb` beat. It was the same mistake step 11 found in the shot's beat. The rule is worth writing down: in a chain of beats, each "nothing to do" jumps to the next beat.

### JP when JR will not reach

`JR` takes one byte for its distance, -128 to +127. With the bomb code added, the loop grew longer than that, and pasmo stopped at the keys' `jr nz,loop` with "Relative jump out of range". `JP` takes a two-byte address and reaches anywhere, for one more byte and no extra time when the jump is taken (10 T-states, against 12 for a `JR` taken). The keys now use `jp loop`.

## The listing

The machine code, `step12-bombs.asm`. It is step 11's, with the bomb parameters, the seed, the bomb beat, `drop`, `bstep`, `btest`, `brub`, `bcell`, `bhit`, `ctest`, `rnd`, the message and the bomb graphic added, `dead` tested in the keys and in `mstep`, and `stest` calling `ctest`.

```
; step12-bombs.asm - Chapter 5, step 12
; Bombs: the twin of Chapter 4, step 6.
; It is step 11's game, and the invaders now fire back. Every dwait
; frames with no bomb in flight, one is dropped: a column is picked with
; step 6's random numbers, and the bomb starts below the lowest living
; invader in it. It falls a row every dspeed frames. If it comes down
; onto the base's row in the base's column, the base is hit, a starburst
; replaces it, YOU ARE HIT is printed, and the game stops but for Q. A
; shot and a bomb that meet, or would pass each other, cancel.
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
;
; Entry point:
;   RANDOMIZE USR 50040  start
;
; Build:  tools/build.sh chapter-05-machine-code-games/step12-bombs.bas chapter-05-machine-code-games/step12-bombs.asm bombs 10

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

baserow: equ 21         ; the base's row
chanopen: equ 5633      ; ROM: open the channel for the stream in A
green:  equ 4           ; INK 4, PAPER 0: the base's attribute
yellow: equ 6           ; INK 6, PAPER 0: the shot's attribute
red:    equ 2           ; INK 2, PAPER 0: the bomb's attribute
kright: equ 1           ; the bits rkeys gives back: P,
kleft:  equ 2           ; O,
kfire:  equ 4           ; Space,
kquit:  equ 8           ; and Q

; start: clear the counts, colour row 21 green, draw the base, then loop.

start:  ld hl,0
        ld (moves),hl
        ld (passes),hl
        ld (ssteps),hl  ; no moves, passes or shot steps yet
        ld (msteps),hl  ; and no march steps
        xor a
        ld (shots),a    ; no shots
        dec a
        ld (srow),a     ; 255: no shot in flight
        ld (erow),a     ; and no explosion
        ld (brow),a     ; and no bomb
        ld a,(mspeed)
        ld (mtime),a    ; a full beat to the first march step
        ld a,(dwait)
        ld (dtime),a    ; and to the first bomb
        ld a,(seed)     ; has BASIC given us a seed?
        and a
        jr nz,seeded    ; yes
        ld a,r          ; no: use the R register
        or 1            ; and make sure it is not 0
        ld (seed),a
seeded:

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
        call dblock     ; draw the block of invaders
        call count      ; nleft = the invaders alive in the table

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
        jr z,boom       ; none: on to the explosion
        ld hl,stime
        dec (hl)        ; one pass fewer to the shot's next step
        jr nz,boom      ; not yet
        ld a,(sspeed)
        ld (hl),a       ; start counting again
        call sstep      ; move the shot up a row

boom:   ld a,(erow)
        inc a           ; 255 becomes 0: is there no explosion?
        jr z,bomb       ; none: on to the bomb
        ld hl,etime
        dec (hl)        ; one pass fewer to its end
        call z,erub     ; its time is up: rub it out

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

march:  ld hl,mtime
        dec (hl)        ; one pass fewer to the next march step
        jr nz,keys      ; not yet
        ld a,(mspeed)
        ld (hl),a       ; start counting again
        call mstep      ; march

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
        call ctest      ; has it met the bomb?
        ret c           ; yes: both are gone
        jp sdraw        ; no: draw the shot

; hit: the shot has hit invader icol of block row irow, at row B, column
; C, and HL is its byte in the alive table, as invat left them. Kill it,
; end the shot, and show the explosion on its cell. Changes A, B, C, DE,
; HL.

hit:    ld (hl),0       ; dead: the table says so, and that is all
        ld a,255
        ld (srow),a     ; the shot is used up
        ld hl,hits
        inc (hl)        ; one more hit
        ld hl,nleft
        dec (hl)        ; one fewer alive
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
        ld a,(nleft)
        and a           ; was that the last one?
        ret nz          ; no
        ld a,2          ; yes: the wave is cleared
        call chanopen
        ld hl,ctext
        jp pstr         ; print it; the march stops by itself

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
bair:   call ctest      ; has it met the shot?
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
; starburst where the base was, and print YOU ARE HIT. Changes A, B, C,
; DE, HL.

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
        ld a,2
        call chanopen
        ld hl,htext
        jp pstr         ; print YOU ARE HIT

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
; and C its column, bx + 2*icol. owhere: the same from obx and oby,
; where the block was before this march step. Both go on to wpair,
; with HL = the address of a column byte with its row byte after it.
; Changes A, HL.

where:  ld hl,bx        ; the block as it is
        jr wpair
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
; rows table, three bytes a row. Changes HL.

rtype:  ld a,(irow)
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
        ld a,(frame)
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
; if not, A = 0. Keeps B and C. Changes DE, HL.

invat:  ld a,b
        ld hl,by
        sub (hl)        ; A = row - by; above the block it goes round
        cp 7            ; past 0 to 255 or so, so one test does both
        jr nc,noinv     ; outside: block rows are 0, 2, 4 and 6
        bit 0,a
        jr nz,noinv     ; an odd row: between two block rows
        rrca            ; A = (row - by) / 2, since bit 0 is 0
        ld (irow),a
        ld a,c
        ld hl,bx
        sub (hl)        ; A = column - bx, round past 0 on the left,
        cp 15           ; which also works when bx is "negative"
        jr nc,noinv     ; outside: columns 0, 2, ... 14
        bit 0,a
        jr nz,noinv     ; an odd column: a gap
        rrca
        ld (icol),a
        jp aliveat      ; A = its alive byte
noinv:  xor a           ; not an invader's place
        ret

; mstep: one step of the march. Find the living edges; at an edge,
; step down (or land), otherwise step sideways; then change frame and
; move every living invader. Changes A, B, C, DE, HL.

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
        jr mblock       ; move them all

; land: the march is over. Print THEY HAVE LANDED on row 0 with the ROM,
; as in step 6.

land:   ld a,1
        ld (landed),a
        ld a,2
        call chanopen   ; the stream RST 16 prints to: the upper screen
        ld hl,ltext
        jp pstr

; mblock: move every living invader from obx, oby to bx, by, one at a
; time: rub it out where it was, then draw it where it is. The invaders
; are two cells apart, so the new cell never holds another invader, and
; none is missing from the screen for more than a moment.

mblock: xor a
        ld (irow),a
mbrow:  xor a
        ld (icol),a
mbinv:  call aliveat
        and a
        jr z,mbnext     ; not alive: nothing to move
        call owhere     ; B, C = where it was
        ld de,blank
        call put        ; rub it out
        call dinv       ; draw it where it is, in the new frame
mbnext: ld hl,icol
        inc (hl)
        ld a,(hl)
        cp 8
        jr nz,mbinv
        ld hl,irow
        inc (hl)
        ld a,(hl)
        cp 4
        jr nz,mbrow
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

; pstr: print the string at HL, which ends with 255, with the ROM.
; Step 6's. Changes A and HL.

pstr:   ld a,(hl)       ; the next byte of the string
        inc hl
        cp 255          ; the end marker?
        ret z           ; yes: done
        rst 16          ; no: print it
        jr pstr

ltext:  db 22,0,8,16,7,"THEY HAVE LANDED",255 ; AT 0,8; INK 7
ctext:  db 22,0,10,16,7,"WAVE CLEARED",255 ; AT 0,10; INK 7
htext:  db 22,0,10,16,7,"YOU ARE HIT",255 ; AT 0,10; INK 7

; The block's working bytes and tables.

irow:   db 0            ; the block row being drawn, 0 to 3
icol:   db 0            ; the invader in that row, 0 to 7
obx:    db 0            ; bx before this march step
oby:    db 0            ; by before it: it must follow obx
lm:     db 0            ; the left-hand living column, 0 to 7
rm:     db 0            ; the right-hand living column

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
; step 4, its explosion, UDG P, from its step 5, and its bomb, UDG C,
; from its step 6. Each invader
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
blank:  db 0,0,0,0,0,0,0,0

        end
```

It is 1515 bytes, 50000 to 51514. pasmo's listing puts `start` at 50040, `loop` at 50122, `boom` at 50158, `bomb` at 50171, `march` at 50205, `keys` at 50218, `sstep` at 50305, `stest` at 50344, `hit` at 50360, `drop` at 50451, `bstep` at 50531, `btest` at 50538, `brub` at 50586, `bhit` at 50615, `ctest` at 50674, `rnd` at 50731, `count` at 50748, `invat` at 51043, `mstep` at 51082, `alive` at 51383, `rows` at 51415 and `bombg` at 51499.

The BASIC driver, `step12-bombs.bas`. The entry point is 50040. Line 67 sets the seed to 0, so the R register picks one, the drop and fall beats, and clears `dead` and the counts. The counts at the end now show the bombs, the cancels and whether the base was hit.

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
60 POKE 50000,1: POKE 50001,2: POKE 50002,1: POKE 50010,15: POKE 50015,8: POKE 50016,1
65 POKE 50017,25: POKE 50019,1: POKE 50020,0: POKE 50021,0
66 POKE 50024,0: POKE 50026,12
67 POKE 50030,0: POKE 50031,50: POKE 50033,4: POKE 50037,0: POKE 50038,0: POKE 50039,0
70 PRINT #0;"O LEFT, P RIGHT, SPACE FIRES, Q STOPS"
80 POKE 23672,0: POKE 23673,0: POKE 23674,0
90 RANDOMIZE USR 50040
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
229 PRINT "CANCELS ";PEEK 50039
230 IF PEEK 50037 THEN PRINT "THE BASE WAS HIT"
231 IF N>0 THEN PRINT "FRAMES A PASS ";F/N
240 IF M>0 THEN PRINT "FRAMES A MOVE ";F/M
250 IF S>0 THEN PRINT "FRAMES A SHOT STEP ";F/S
255 IF G>0 THEN PRINT "FRAMES A MARCH STEP ";F/G
260 IF INKEY$<>"" THEN GO TO 260
```

## Building and running

On Windows, from the course folder:

```
windows-tools\build.bat chapter-05-machine-code-games\step12-bombs.bas chapter-05-machine-code-games\step12-bombs.asm bombs 10
```

On Linux:

```
tools/build.sh chapter-05-machine-code-games/step12-bombs.bas chapter-05-machine-code-games/step12-bombs.asm bombs 10
```

The examples:

```
windows-tools\build.bat chapter-05-machine-code-games\step12-examples.bas chapter-05-machine-code-games\step12-examples.asm examples 20
```

```
tools/build.sh chapter-05-machine-code-games/step12-examples.bas chapter-05-machine-code-games/step12-examples.asm examples 20
```

O and P move the base, Space fires, and Q stops and shows the counts. Keep moving.

## What it showed in Fuse

The tape was loaded in a 48K Fuse at normal speed.

- **Bombs.** About once every two seconds a red bomb came out of the block, below a bottom-row invader, and fell to the ground (`step12-bombs.png`). Screenshots taken as fast as possible caught three bombs in their first ten seconds, in three columns.
- **The base hit.** Left standing in column 15, the base was hit by the ninth bomb, after 35 march steps. The starburst replaced it, `YOU ARE HIT` came up, and the block stopped (`step12-bombs-hit.png`). P did nothing after that; Q stopped the program and showed the counts (`step12-bombs-result.png`).
- **A whole wave, with bombs.** A test copy with the `auto` routine and a fixed seed, changed so that a hit on the base is only counted and the game goes on, cleared the wave after 157 march steps: 32 hits, 41 bombs, 2 cancels, and the base hit 3 times, in 6001 passes and 6001 frames.
- **The examples** gave the tables above.

pasmo and z80asm gave the same 1515 bytes for `step12-bombs.asm`, and the same non-zero bytes for `step12-examples.asm`.

## The timing, against BASIC

Chapter 4's step 6 timed an idle pass, an official cycle, a bomb's step, and a shot step that also tests for a cancel. This step's copies use the `auto` routine again.

- **Idle:** `dead` poked to 1, so there is no march, no bomb, and no shot.
- **Shot:** the block landed, the base in column 0, and `drop` made to return at once.
- **Bomb:** the block landed, the base in column 0 out of the bombs' way, and a drop or a bomb step on every pass (`dwait` and `dspeed` 1), stopped after 2001 bomb steps.

| What | Chapter 4, step 6 | This step, as shipped | This step, no `halt` |
|------|------------------:|----------------------:|---------------------:|
| An idle pass | 6.7 | 1 | 0.0062 (30001 passes in 186 frames) |
| A bomb step | 9.0 | 1 pass, once every 4 | 0.033 a pass (2001 steps and 154 drops in 2155 passes, 71 frames) |
| A shot step, with the bomb test | 13.6 (with a hit test too) | 1 | 0.0305 (2100 steps in 64 frames) |
| A march step | a 104-frame cycle | 1 pass, once every 25 | 0.781, as in step 11 |

Against Chapter 4, an idle pass is about 1100 times as quick, a bomb step about 270 times, and a shot step about 450 times.

**The frame budget.** Adding up the worst pass, a march step, a bomb step or drop, a shot step and a hit, gives about 0.88 of a frame. To test it, a copy ran with a march step on every pass (`mspeed` 1), a drop or bomb step on every pass (`dwait` and `dspeed` 1), and the `auto` routine moving and firing, with a hit on the base only counted. Until the block landed, 244 passes had a march step, and most of them a bomb step or a drop and a shot step as well; there were 27 hits, 118 bombs, 5 cancels and 9 hits on the base. 2001 passes took 2002 frames: none ran over. No fallback is needed. The march is still 0.78 of the 0.88, so if step 13's shields push a pass over, the march is the place to save time, with Chapter 4's row-a-pass ripple.

## Line by line

- **`seed`, `dwait`, `dtime`, `dspeed`, `dstime`, `brow`, `bcol`, `dead`, `bombs`, `cancels`** at 50030 to 50039. The entry point moves to 50040.
- **`start`** clears `brow`, gives the first drop a full `dwait`, and takes a seed from R if BASIC poked 0.
- **`boom`** goes on to `bomb`, not `march`, when there is no explosion.
- **`bomb`** counts down to a drop when there is no bomb, and down to the next step when there is one.
- **The keys** use `jp loop`, and once `dead` is set only Q does anything.
- **`stest`** calls `ctest` before it draws the shot.
- **`mstep`** returns once the base is hit.
- **`drop`** picks a living column, finds its lowest living invader, and starts the bomb below it.
- **`bstep`, `btest`** move the bomb, and decide: the base, the ground, the shot, behind an invader, or drawn.
- **`brub`, `bcell`** rub the bomb out, and give its cell.
- **`bhit`** ends the game.
- **`ctest`** decides whether the shot and the bomb have met, and cancels them.
- **`rnd`**: step 6's.
- **`htext`, `bombg`**: the message, and UDG C.

## Limitations you will notice

- **Column 6 and the next-column rule.** When a gap of empty columns is followed by a living one, that column drops most of the bombs (see example 2).
- **One bomb at a time.** The arcade game has more. A second bomb needs a second set of bytes and a second beat, and a loop over them; it is a good exercise once step 14 is done.
- **Bombs do not touch the explosion.** A bomb falling through a starburst rubs it out early, as a shot does.
- **The game is over after one hit.** Lives are step 14.
- **`bombs` and `cancels` are one byte each**, like `shots`.

## Try this

Each of these was tried in Fuse.

- In the examples, change example 2's "next column" to "another random column": replace `ld a,(icol)` and `inc a` with `push bc`, `call rnd` and `pop bc` (`rnd` changes B, which counts the tries). With columns 0 to 5 empty, twelve drops then went to column 6 three times and column 7 seven times, and twice all eight tries missed and gave 65535, no bomb, as in Chapter 4 (`step12-examples-try.png`).
- A hailstorm: on line 67 poke `dwait` (50031) as 10 and `dspeed` (50033) as 2. The base, left in column 15, was hit by the sixth bomb after 8 march steps, against the ninth after 35 as shipped (`step12-bombs-try.png`).
