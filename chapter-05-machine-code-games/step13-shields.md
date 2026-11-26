# Chapter 5, step 13 — Shields

Chapter 4's step 7 put four shields between the base and the block, each three cells wide and two high, on rows 18 and 19, in columns 3 to 5, 11 to 13, 19 to 21 and 27 to 29. A damage map, `S(2,12)`, held a level for each cell: 3 whole, 2 damaged, 1 badly damaged, 0 gone. A shot or a bomb that reached a cell above 0 took one off and was used up, and the cell was printed again as UDG N, O or a space. Step 8 then made invaders that marched onto the shield rows wipe the cells out. In BASIC a pass that hit a shield took 24 frames.

This step is its twin, and it does step 8's wiping as well. The design is step 9's again: **the damage map is the record**, one byte a cell, and the screen is drawn from it. A screen cell is turned into a map byte by arithmetic, `shat`; `chip` takes one off a byte and draws the cell; and `stomp`, called whenever an invader is drawn, sets a byte to 0 if the invader has landed on that cell.

The costs: a chip is 0.015 of a frame, and a march step with the block on the shield rows 0.88 against 0.83 above them. The worst pass found, a march step on the shield rows with a bomb, a shot and a hit, still fitted in its frame.

Every program here was assembled with pasmo, cross-checked against z80asm, and run in a 48K emulator before it was shown.

## The new instructions and ideas

There is one new directive, `DS`, and no new instructions. The new ideas are a cell-to-map lookup with `AND 7`, a table of pictures by level, a routine that says yes or no in the carry flag, and keeping the map right when an invader covers a cell. The examples are in `step13-examples.asm`, with a BASIC driver, `step13-examples.bas`; `step13-examples.png` is its screen, and the results below are copied from it.

### DS, space for the map

```
shmap:  ds 24
```

`DS` (define space) reserves bytes without saying what is in them; pasmo and z80asm both fill them with 0. The map is set to 3s by `dshield` at the start of every game, so the tape does not need to carry them. It is the same as `db` with 24 zeros, and shorter to read.

### From a screen cell to the map

The shields start in columns 3, 11, 19 and 27, eight apart. So for a cell in column `c`, `c - 3` is `8 * shield + place`, and the place across the shield is the bottom three bits, `AND 7`. A place of 0, 1 or 2 is a shield cell; 3 to 7 is the gap to the next shield. The shield number is the next two bits, three `RRCA`s and `AND 3`. The map has the 12 top cells first, then the 12 bottom ones, so the byte is `3 * shield + place`, plus 12 on row 19:

```
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
```

Chapter 4 did the same sums with `INT (Q/8)` and `Q-8*INT (Q/8)`. In machine code, dividing by 8 is three shifts and the remainder is an `AND`, because 8 is a power of two: one reason the shields are eight columns apart.

`shat` answers in the carry flag: set for "not a shield cell", clear for "yes", with HL on the byte, A its level, the zero flag set if the level is 0, and `shy` and `shx` saying which of the six cells of its shield it is. The same `sub` and `cp` trick as `ctest` and `invat` turns "row is 18 or 19" into one test. Example 1:

| Cell | Map byte | `shy` | `shx` |
|------|---------:|------:|------:|
| 18, 3 | 0 | 0 | 0 |
| 18, 5 | 2 | 0 | 2 |
| 19, 4 | 13 | 1 | 1 |
| 18, 6 | none | 0 | 9 |
| 19, 27 | 21 | 1 | 0 |
| 19, 29 | 23 | 1 | 2 |
| 17, 4 | none | 9 | 9 |
| 18, 30 | none | 0 | 9 |
| 18, 2 | none | 0 | 9 |

(9 is the value BASIC poked first, so it shows what `shat` did not set.)

Two names had to change on the way. `shr` and `shl` are operators in pasmo, as `r` was a register in step 9, so the bytes are `shy` and `shx`, and the corner pictures `gK` and `gL`.

### Pictures by level

A whole shield has six shapes, Chapter 4's K, J and L on top and J, M and J below, but every damaged cell looks the same: N at level 2, O at level 1, and nothing at 0. `shdraw` finds its picture in one table of addresses:

```
shgfx:  dw blank,gO,gN  ; levels 0, 1 and 2
        dw gK,gJ,gL     ; level 3, top row: corner, block, corner
        dw gJ,gM,gJ     ; level 3, bottom row: block, arch, block
```

A level below 3 is the entry number itself; level 3 is `3 + 3 * shy + shx`. Doubling the entry number gives the offset, since each address is two bytes.

### chip, yes or no in the carry

```
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
```

The shot calls it in `stest` after the invader test, and the bomb in `btest` before the cancel test, each with its new cell in B and C, and each is used up if the carry comes back set. A hole is level 0, so a shot or a bomb goes through a hole and on to the cell beyond. Example 2 chips row 19, column 4, the arch of the first shield, four times, and the levels come back 2, 1, 0 and then 255, nothing to chip. The cell above it then went from 3 to 2. `chips` counted 4.

### Invaders that reach the shields

When the block comes down onto rows 18 and 19, an invader drawn on a shield cell covers it. The screen no longer shows that cell, so the map must not either, or a later shot would stop on a shield that is not there. Every invader is drawn by `dinv`, so that is where the test goes:

```
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
```

Above row 18, which is almost all of the game, it costs a compare and a return. When the invader moves on, `mblock` rubs out its old cell, and the cell is empty on the screen and 0 in the map. Chapter 4 wiped the whole band its row string covered, gaps included; here only the cells an invader actually lands on are wiped, but over a march across the screen every column is landed on.

## The listing

The machine code, `step13-shields.asm`. It is step 12's, with the counts, `dshield` at the start, `chip` in `stest` and `btest`, `stomp` in `dinv`, and `shat`, `shdraw`, `chip`, `stomp`, `dshield`, the map, the picture table and the six shield graphics added.

```
; step13-shields.asm - Chapter 5, step 13
; Shields: the twin of Chapter 4, step 7.
; It is step 12's game, with four shields on rows 18 and 19, each three
; cells wide and two high, in Chapter 4's places and shapes. A damage
; map, one byte a cell, is the record of what is left: 3 whole, 2
; damaged, 1 badly damaged, 0 gone. A shot or a bomb that comes to a
; cell above 0 takes one off it, the cell is drawn at its new level,
; and the shot or bomb is used up. An invader drawn on a shield cell
; wipes it out: the map says 0, as the screen does.
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
;
; Entry point:
;   RANDOMIZE USR 50042  start
;
; Build:  tools/build.sh chapter-05-machine-code-games/step13-shields.bas chapter-05-machine-code-games/step13-shields.asm shields 10

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

baserow: equ 21         ; the base's row
chanopen: equ 5633      ; ROM: open the channel for the stream in A
green:  equ 4           ; INK 4, PAPER 0: the base's attribute
yellow: equ 6           ; INK 6, PAPER 0: the shot's attribute
red:    equ 2           ; INK 2, PAPER 0: the bomb's attribute
shrow:  equ 18          ; the shields' top row; their bottom row is 19
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
        call dshield    ; draw the four shields, all whole
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

It is 1815 bytes, 50000 to 51814. pasmo's listing puts `start` at 50042, `loop` at 50127, `stest` at 50349, `bair` at 50579, `shat` at 50781, `shdraw` at 50841, `chip` at 50876, `stomp` at 50896, `dshield` at 50916, `count` at 50953, `dinv` at 51157, `invat` at 51251, `mstep` at 51290, `shmap` at 51593, `shgfx` at 51617 and `alive` at 51635.

The BASIC driver, `step13-shields.bas`. The entry point is 50042. Line 68 clears the two new counts, and line 229 prints them with the cancels.

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
68 POKE 50040,0: POKE 50041,0
70 PRINT #0;"O LEFT, P RIGHT, SPACE FIRES, Q STOPS"
80 POKE 23672,0: POKE 23673,0: POKE 23674,0
90 RANDOMIZE USR 50042
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
windows-tools\build.bat chapter-05-machine-code-games\step13-shields.bas chapter-05-machine-code-games\step13-shields.asm shields 10
```

On Linux:

```
tools/build.sh chapter-05-machine-code-games/step13-shields.bas chapter-05-machine-code-games/step13-shields.asm shields 10
```

The examples:

```
windows-tools\build.bat chapter-05-machine-code-games\step13-examples.bas chapter-05-machine-code-games\step13-examples.asm examples 20
```

```
tools/build.sh chapter-05-machine-code-games/step13-examples.bas chapter-05-machine-code-games/step13-examples.asm examples 20
```

## What it showed in Fuse

The tape was loaded in a 48K Fuse at normal speed.

- **The shields.** Four green bunkers came up on rows 18 and 19 in Chapter 4's columns, with the corners, blocks and arch in place (`step13-shields.png`; a bomb has already chipped the top-left corner of the fourth).
- **Chipped in stages.** With the base under the first shield's arch, in column 4, and the block held still (`dx` 0, bombs held off with `dwait` 255), single shots turned the arch to N, then O, then nothing; the next shots did the same to the block above it, and then went through the hole (`step13-shields-chip.png`, six crops of the shield, one after each shot). The counts showed 7 chips, with 2 bombs dropped: the six levels of the two cells, and one where a bomb fell. The arch's neighbours were untouched.
- **Bombs** chipped shields where they fell, and stopped there.
- **Invaders wipe them out.** With the block started on row 12, so its bottom row is on 18, the march wiped out the shields it crossed (`step13-shields-stomp.png`, with only the first shield left). By the landing, `STOMPS` was 24: every cell of every shield, and the map agreed with the screen.
- **A whole wave.** The `auto` test copy, with a seed of 77 and hits on the base only counted, cleared the wave after 168 march steps: 32 hits, 43 bombs, 4 cancels, 65 chips (most of them its own shots), in 6001 passes and 6002 frames (`step13-shields-result.png`).
- **The examples** gave the tables above.

pasmo and z80asm gave the same 1815 bytes for `step13-shields.asm`, and the same non-zero bytes for `step13-examples.asm`.

## The timing, against BASIC

| What | Chapter 4, step 7 | This step, as shipped | This step, no `halt` |
|------|------------------:|----------------------:|---------------------:|
| An idle pass | 6.8 | 1 | 0.0062 (30001 passes in 187 frames) |
| A pass that chips a shield | 24 | inside its pass | 0.015 for the chip (1024 in 15 frames) |
| A shot step, with the shield test | | 1 | 0.0333 (2100 steps in 70 frames) |
| A march step, block above the shields | a 106-frame cycle | 1 pass, once every 25 | 0.83 (41 steps in 34 frames) |
| A march step, block on the shield rows | | | 0.88 (41 steps in 36 frames) |

The idle pass and the shot step were timed as in step 12: `dead` poked to 1 for the idle pass, and for the shot the block landed, the base in column 0 and no bombs. The chip was timed with a test copy that chips the arch 1024 times, making it whole again each time. The two march figures are the same test, 41 steps from a block on row 1 and from a block on row 12; 41 is as many as the second can take before it lands, so these are coarser than step 10's 200-step 0.785.

Against Chapter 4, an idle pass is about 1100 times as quick, and a chip pass, at under 0.05 of a frame for the shot step and the chip together, about 500 times.

**The frame budget.** On the shield rows every invader drawn costs a `shat`, and the march step goes from about 0.83 of a frame to 0.88. Add a bomb step, a shot step and a hit, and the sum is about 0.98: close. Two copies tested it with a march step on every pass (`mspeed` 1), a drop or bomb step on every pass, and the `auto` routine moving and firing, with a hit on the base only counted:

- From row 1, until the block landed: 244 march steps, 31 hits, 98 bombs, 31 chips and 18 stomps in 2001 passes and 2002 frames.
- From row 12, all of it on the shield rows: 46 march steps, 9 hits, 81 bombs, 4 chips and 24 stomps in 201 passes and 202 frames.

No pass ran over, so no fallback is applied. Step 14 adds a score to print on every hit, and that is where the budget will be tight.

## Line by line

- **`chips`, `stomps`** at 50040 and 50041. The entry point moves to 50042. `shrow` is 18.
- **`start`** calls `dshield` before drawing the block.
- **`stest`** asks `chip` after the invader test; `sused` ends the shot.
- **`bair`** asks `chip` before the cancel test; `bused` ends the bomb.
- **`dinv`** calls `stomp` between `where` and `attr`.
- **`shat`, `shdraw`, `chip`, `stomp`, `dshield`**: as above. `dshield` sets the map to 3s and then draws every cell of rows 18 and 19 that `shat` says is a shield, so the drawing and the lookup cannot disagree.
- **`shy`, `shx`, `shmap`, `shgfx`**, and the graphics `gJ` to `gO`, Chapter 4's UDGs J to O.

## Limitations you will notice

- **A cell is all or nothing at each level.** The arcade game eats its shields a few pixels at a time; here a cell goes whole, N, O, gone. Pixel damage would need the shot's pixel position and a bit of the picture rubbed out: a good later exercise.
- **A shot or a bomb going through a hole leaves its colour on the cell.** The attribute is left yellow or red, on an empty cell, so nothing shows.
- **Your own shots chip your shields**, as in the arcade game. The test player shot most of its own away.
- **The march is now 0.88 of a frame on the shield rows.** See the budget.

## Try this

Each of these was tried in Fuse.

- Start the block low: poke `by` (50016) as 12 on line 60, and `dwait` (50031) as 255 to hold the bombs off. The march wipes out the shields it crosses, and `STOMPS` shows how many cells went; in the test it was all 24 by the landing (`step13-shields-stomp.png`).
- Shoot a shield to pieces: poke `x` (50010) as 4, `dx` (50019) as 0 to hold the block still, and `dwait` as 255. Tap Space, one shot at a time, and watch the arch go N, O, gone, then the block above it, then the shots go through (`step13-shields-chip.png`). Hold Space and a shield cell goes in a few frames: a shot that is eaten on row 19 lets the next one go at once.
