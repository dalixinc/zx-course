# Chapter 5, step 10 — The march

Chapter 4's step 4 made the block march: one column sideways at a time, a row down and back at each edge, and a change between two frames on every step, so the invaders walk. When the bottom row reaches the base's row it stops, with `THEY HAVE LANDED`. It also showed what that costs in BASIC. A sideways step took 45 frames, so long that the program could not do it all at once without freezing the base: it drew one row of the block on each pass of its loop, a ripple over four passes, and started a step only every eighth pass. The block took a step every 74 frames, about one and a half seconds, and the base slowed from 4.6 frames a move to 7.1 while it did.

This step is its twin. The block moves on a beat of its own, `mspeed` frames, 25 as shipped, two steps a second. A whole step, all 32 invaders rubbed out and drawn again in their new places and their other frame, takes **0.785 of a frame**, so the code does it all in one pass, with no ripple, and the base and the shot do not notice: the base still moves every second frame and the shot every frame, as in step 8. Chapter 4's sideways step was 45 frames, 57 times as long.

Every program here was assembled with pasmo, cross-checked against z80asm, and run in a 48K emulator before it was shown.

## The new instructions and ideas

There are no new instructions. The new ideas are about time and about the block's data: a third beat in the loop, moving every invader without a gap on the screen, the edges from the `alive` table, and a block whose left-hand column is off the screen. The examples are in `step10-examples.asm`, with a BASIC driver, `step10-examples.bas`; `step10-examples.png` is its screen, and every result below is copied from it.

### The march's beat

The loop now has three countdowns: the shot's, the march's and the keys'. The march's is the same pattern as the other two:

```
march:  ld hl,mtime
        dec (hl)        ; one pass fewer to the next march step
        jr nz,keys      ; not yet
        ld a,(mspeed)
        ld (hl),a       ; start counting again
        call mstep      ; march
```

A pass is a frame, so `mspeed` 25 is a step every half second. Chapter 4 could not choose its march speed like this. Its march waited `W` passes, and a pass took as long as BASIC took, so the speed changed with everything else in the loop. Here the speed is a number of frames, and it stays the same while the shot flies and the base moves. That is why `mspeed` is a parameter at 50017: step 14's waves will make it smaller to speed the march up, as Chapter 4 did with `W`.

The design rests on one measurement: a march step must fit in a frame with everything else in the pass. It does. A step alone took 0.785 of a frame, and in a game played from the start to the landing, with shots and base moves in it, 6655 passes took 6656 frames: not one pass ran over into the next frame. 0.785 is a lot of a frame, though, and later steps add hits and bombs. If a pass with a march step ever runs over, it costs one frame late for everything, once every `mspeed` frames, and the answer then is Chapter 4's: ripple the block a row a pass. It is not needed yet, and the simpler code is easier to read.

### Moving a block without a gap

There are two ways to move the block: rub it all out and draw it all again, or move it one invader at a time. The first is shorter, but for about half of the 0.785 of a frame the block, or a part of it, is not on the screen at all, and if the picture is sent to the television in that time, it flickers. So `mblock` moves the invaders one at a time:

```
mbinv:  call aliveat
        and a
        jr z,mbnext     ; not alive: nothing to move
        call owhere     ; B, C = where it was
        ld de,blank
        call put        ; rub it out
        call dinv       ; draw it where it is, in the new frame
```

This works because the invaders are two cells apart. A sideways step moves each one into the gap beside it, and a down step into the empty row below it, so the cell an invader moves into never holds another invader, and the order does not matter. Each invader is off the screen for the time between two `put`s, a few hundred T-states.

To rub an invader out where it was and draw it where it is, the code needs both places. `mstep` copies `bx` and `by` into `obx` and `oby` before it changes them, with one `ld hl,(bx)` and one `ld (obx),hl`, since each pair is two bytes side by side. `where` and `owhere` share their code: each puts the address of its pair in HL and goes on to `wpair`, which reads the column, then `inc hl`, then the row. That is why `oby` must come right after `obx`.

### The edges, from the alive table

A step right is only allowed if the right-hand living invader is not already in column 31, and a step left if the left-hand one is not in column 0. Otherwise the step is down, and the direction changes. "Living" is the point. Chapter 4 found its edges by adding the four cells of each column of `V`, from the left and from the right, and stopping at the first that was not 0. `edges` does the same with `colalive`:

```
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
```

`or (hl)` collects the four bytes: the answer is 0 only if all four are 0. Chapter 4 added them; `or` does the same job here, since the bytes are 0 or 1. Example 1 runs `edges` on four tables:

| The table | `lm` | `rm` |
|-----------|-----:|-----:|
| All alive | 0 | 7 |
| Columns 0 and 7 empty | 1 | 6 |
| Only invader 3 of row 2 alive | 3 | 3 |
| None alive | | 65535: the carry is set |

With every invader alive, the block of step 10 is 15 columns wide and marches from `bx` 0 to `bx` 17. With its outer columns empty it goes further, as in Chapter 4, and then its left-hand column is off the screen.

### A block that starts off the screen

If columns 0 and 1 are empty and the block is at the left edge, its first living invader is in column 0, and `bx`, the column of invader 0, is -4. A byte cannot be -4, but it can be 252, and the arithmetic still works. `where` adds `2*icol` to `bx`: for `icol` 2, 252 + 4 = 256, and in 8 bits that is 0. The carry out of the top is lost, and the column is right.

Step 9's `invat` did not allow it. It tested `sub (hl)` for a carry, "left of the block", and 0 - 252 gives a carry. This step takes those tests out:

```
        ld hl,bx
        sub (hl)        ; A = column - bx, round past 0 on the left,
        cp 15           ; which also works when bx is "negative"
        jr nc,noinv     ; outside: columns 0, 2, ... 14
```

A cell to the left of the block gives a large number, 256 less a little, so `cp 15` catches it with the cells on the right. Example 2 sets `bx` to 254, -2, and tries cells on row 1:

| Cell | `invat` | `irow` | `icol` |
|------|--------:|-------:|-------:|
| 1, 0 | 1 | 0 | 1 |
| 1, 12 | 1 | 0 | 7 |
| 1, 1 | 0 | 0 | 9 |
| 1, 14 | 0 | 0 | 9 |
| 1, 31 | 0 | 0 | 9 |

Column 0 is invader 1, since invader 0 would be in column -2, and column 12 is invader 7. The rows work the same way, for the day the block is above the screen.

### Two frames, from the rows table

Each type now has two graphics, eight bytes apart: Chapter 4's D and E, F and G, H and I. The `rows` table still points at the first, and `rtype` adds `8*frame`:

```
        ld a,(frame)
        add a,a
        add a,a
        add a,a         ; A = 0 for frame 0, 8 for frame 1
        add a,e
        ld e,a
        jr nc,rtnc
        inc d           ; DE = the graphic of this frame
```

The carry from `add a,e` goes into D with `inc d`, so the sum is right even if the graphic crosses a 256-byte boundary. `mmove` changes the frame with `xor 1` before it moves the block, so every step, sideways or down, draws the other frame. The shot's `dinv`, drawing an invader again behind the shot, uses the frame the block is in.

### Landing

Chapter 4 tested `BY+6>=20` before a step down: the bottom row would then come down onto the base's row. `mdown` does the same with `cp 20-6`, and if the block has landed it sets `landed` and prints `THEY HAVE LANDED` on row 0 with step 6's `pstr` and the ROM. From then on `mstep` returns at once, and the base and the shot carry on, as in Chapter 4.

## The listing

The machine code, `step10-march.asm`. It is step 9's, with the march's parameters, its beat in the loop, `where` split into `where`, `owhere` and `wpair`, `rtype` choosing the frame, `invat` without its carry tests, and `mstep`, `land`, `mblock`, `edges`, `colalive`, `pstr`, the message, the working bytes `obx`, `oby`, `lm` and `rm`, and the second frames added.

```
; step10-march.asm - Chapter 5, step 10
; The march: the twin of Chapter 4, step 4.
; It is step 9's block, base and shot, and the block now marches. Every
; mspeed frames it takes a step: one column sideways, or at an edge one
; row down and back the other way. Each step it changes to its other
; frame, Chapter 4's UDGs E, G and I, so the invaders walk. The edges
; are found from the alive table, so a block with its outer columns
; shot away marches further. When the bottom row would come down past
; row 20 the march stops, and THEY HAVE LANDED is printed on row 0.
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
;
; Entry point:
;   RANDOMIZE USR 50024  start
;
; Build:  tools/build.sh chapter-05-machine-code-games/step10-march.bas chapter-05-machine-code-games/step10-march.asm march 10

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

baserow: equ 21         ; the base's row
chanopen: equ 5633      ; ROM: open the channel for the stream in A
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
        ld (msteps),hl  ; and no march steps
        xor a
        ld (shots),a    ; no shots
        dec a
        ld (srow),a     ; 255: no shot in flight
        ld a,(mspeed)
        ld (mtime),a    ; a full beat to the first march step

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
        jr z,march      ; none: on to the march
        ld hl,stime
        dec (hl)        ; one pass fewer to the shot's next step
        jr nz,march     ; not yet
        ld a,(sspeed)
        ld (hl),a       ; start counting again
        call sstep      ; move the shot up a row

march:  ld hl,mtime
        dec (hl)        ; one pass fewer to the next march step
        jr nz,keys      ; not yet
        ld a,(mspeed)
        ld (hl),a       ; start counting again
        call mstep      ; march

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
        call scell      ; B, C = the shot's cell
        ld de,blank
        call put        ; rub it out
        call scell
        call invat      ; was it over an invader?
        and a
        call nz,dinv    ; yes: draw the invader again
        ld hl,srow
        ld a,(hl)
        and a           ; was it on row 0?
        jr z,sgone      ; yes: it has left the screen
        dec (hl)        ; one row up
        jr sdraw        ; and draw it there
sgone:  ld (hl),255     ; no shot now
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
        ld hl,(msteps)
        inc hl
        ld (msteps),hl  ; one more march step
        ld hl,(bx)      ; L = bx, H = by
        ld (obx),hl     ; where the block is now: obx, oby
        call edges      ; lm, rm = the living edge columns
        ret c           ; none alive: nothing to march
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
; 997, and its invaders, UDGs D to I, from lines 1000 to 1055 of its
; step 4. Each type's frame 1 is 8 bytes after its frame 0.

base:   db 24,24,24,126,255,255,255,255
shot:   db 0,24,24,24,24,24,24,0
inv1:   db 60,126,255,219,255,90,165,66 ; UDG D, the top row, frame 0
        db 60,126,255,219,255,90,66,165 ; UDG E, its frame 1
inv2:   db 66,36,126,219,255,189,165,36 ; UDG F, the middle rows, frame 0
        db 36,165,126,219,255,189,36,165 ; UDG G, frame 1
inv3:   db 60,255,255,231,255,90,165,129 ; UDG H, the bottom row, frame 0
        db 60,255,255,231,255,90,129,165 ; UDG I, frame 1
blank:  db 0,0,0,0,0,0,0,0

        end
```

It is 937 bytes, 50000 to 50936. pasmo's listing puts `start` at 50024, `loop` at 50078, `march` at 50114, `keys` at 50127, `sstep` at 50201, `dinv` at 50430, `where` at 50469, `rtype` at 50491, `invat` at 50521, `mstep` at 50560, `land` at 50652, `mblock` at 50668, `edges` at 50713, `colalive` at 50763, `pstr` at 50785, `alive` at 50821 and `rows` at 50853.

The BASIC driver, `step10-march.bas`. The entry point is 50024. Line 65 sets the march: its speed, its direction, the frame, and `landed` back to 0, so a second run starts as the first did. After the game it also shows the march steps.

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
70 PRINT #0;"O LEFT, P RIGHT, SPACE FIRES, Q STOPS"
80 POKE 23672,0: POKE 23673,0: POKE 23674,0
90 RANDOMIZE USR 50024
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
230 IF N>0 THEN PRINT "FRAMES A PASS ";F/N
240 IF M>0 THEN PRINT "FRAMES A MOVE ";F/M
250 IF S>0 THEN PRINT "FRAMES A SHOT STEP ";F/S
255 IF G>0 THEN PRINT "FRAMES A MARCH STEP ";F/G
260 IF INKEY$<>"" THEN GO TO 260
```

## Building and running

On Windows, from the course folder:

```
windows-tools\build.bat chapter-05-machine-code-games\step10-march.bas chapter-05-machine-code-games\step10-march.asm march 10
```

On Linux:

```
tools/build.sh chapter-05-machine-code-games/step10-march.bas chapter-05-machine-code-games/step10-march.asm march 10
```

The examples:

```
windows-tools\build.bat chapter-05-machine-code-games\step10-examples.bas chapter-05-machine-code-games\step10-examples.asm examples 20
```

```
tools/build.sh chapter-05-machine-code-games/step10-examples.bas chapter-05-machine-code-games/step10-examples.asm examples 20
```

The block marches at once. O and P move the base, Space fires, and Q stops and shows the counts.

## What it showed in Fuse

The tape was loaded in a 48K Fuse at normal speed.

- **The march.** The block marched right, stepped down at column 31 and came back, changing frame on each step: `step10-march.png` is the block after its first step down, with the other legs.
- **Shots through the marching block.** Shots passed through the block while it marched, and it was whole behind them (`step10-march-shot.png` has a shot above the block).
- **Landing.** After about two minutes the block came down with its bottom row on row 20, the march stopped, and `THEY HAVE LANDED` came up on row 0 (`step10-march-landed.png`). The base still moved. Q then showed `FRAMES 6656`, `PASSES 6655` and `MARCH STEPS 244` (`step10-march-result.png`): 9 steps to the first edge, 13 times 17 back and forth, 13 steps down, and the one that landed.
- **A thinner block.** See Try this: with three columns empty it marched further, off the left of the block's first column.
- **The examples** gave the tables above.

pasmo and z80asm gave the same 937 bytes for `step10-march.asm`, and the same non-zero bytes for `step10-examples.asm`.

## The timing, against BASIC

Chapter 4's step 4 timed an idle pass, a sideways and a down step, an official cycle, and the base and the shot with the block still and with it marching. This step's copies use the `auto` routine from steps 7 and 8 in place of `rkeys`, now able to stop after a number of march steps too. For the idle pass and the base with no march, `landed` was poked to 1, so the march's beat runs but `mstep` returns at once.

| What | Chapter 4, step 4 | This step, as shipped | This step, no `halt` |
|------|------------------:|----------------------:|---------------------:|
| An idle pass | 4.3 | 1 | 0.00588 (29786 passes in 175 frames) |
| A march step | 45 sideways, 54 down | 1 pass, once every 25 | 0.785 (200 steps, 11 of them down, in 157 frames) |
| The march's beat | a step every 74 frames (`W` 8) | a step every 25 frames (`mspeed`) | |
| The base, a move, block still | 4.6 | 2.008 (step 9) | 0.0224 (landed) |
| The base, a move, block marching | 7.1 | 2.008 (248 in 498 frames, 19 march steps) | |
| The shot, a step, block still | 7.4 | 1.00 (step 9) | |
| The shot, a step, block marching | 10 | 1.05 (2100 steps, 100 shots, 2201 passes, 88 march steps) | |

The shot's 1.05 is one frame a step and one frame between shots, the wait for the next look at the keys: 22 passes a shot.

Against Chapter 4, a march step is 57 times as quick sideways and 69 times down, and an idle pass about 730 times. The more useful comparison is what the player feels. In Chapter 4 the base slowed by half while the block marched, and the shot by a third; here neither changed at all, because the march fits in the frame it is given.

A march step is 0.785 of a frame, about 54900 T-states, 1700 for each invader: a `put` to rub it out, and `dinv` to draw it, with its lookups. That is most of the frame, and it is the number to watch in the next steps.

## Line by line

- **`mspeed`, `mtime`, `dx`, `frame`, `landed`, `msteps`** at 50017 to 50023. The entry point moves to 50024.
- **`start`** clears `msteps` and gives the march a full beat before its first step.
- **The shot's beat** now goes on to `march`, not `keys`, when there is no step to take.
- **`march`** counts `mtime` down and calls `mstep` every `mspeed` passes.
- **`where`, `owhere`, `wpair`**: the cell of an invader in the block as it is, or as it was.
- **`rtype`** adds `8*frame` to the graphic's address.
- **`invat`** has lost its two carry tests, so it works with a "negative" `bx` or `by`.
- **`mstep`** does nothing once landed; counts the step; saves `bx` and `by`; finds the edges; decides between a step sideways and a step down; changes the frame; and moves the block with `mblock`.
- **`land`** sets `landed` and prints the message.
- **`mblock`** moves each living invader, rubbing it out where it was and drawing it where it is.
- **`edges`, `colalive`** find the left-hand and right-hand living columns.
- **`pstr`, `ltext`**: step 6's printing and the message, `AT 0,8`, `INK 7`.
- **`obx`, `oby`, `lm`, `rm`**: the working bytes. `oby` must follow `obx`.

## Limitations you will notice

- **The march is most of a frame.** 0.785 of a frame for a step of 32 invaders. It fits now; steps 11 to 14 will have to watch it.
- **Every step moves the whole block.** The arcade game moves one invader a frame, so the block ripples and speeds up as it thins. That is a different design, and a good Try this for later.
- **Shots still pass through.** Hits are step 11.
- **The landing test is Chapter 4's.** It uses the block's rows, not its lowest living row, so a block with its bottom row shot away still lands when it would have.
- **The message stays on row 0.** Nothing else uses row 0 yet; the score will, in step 14.

## Try this

Each of these was tried in Fuse.

- Shoot away columns by hand and march faster: change line 65 to start `POKE 50017,5` and add `66 FOR I=0 TO 3: POKE 50821+8*I,0: POKE 50822+8*I,0: POKE 50828+8*I,0: NEXT I` (with `9 REM I=a block row, for the Try this`). That empties columns 0, 1 and 7 (`alive` is at 50821). The thin block marched ten steps a second, out to column 31 and back to column 0 each time, and landed after 324 march steps in 2675 frames (`step10-march-try.png`). 324 is what the edges predict: 11 steps to the right-hand edge from `bx` 8 to 19, then 13 runs of 23 between `bx` 19 and `bx` -4, 13 steps down and the landing.
- The same thin block at `mspeed` 25, watched at the left edge: its left-hand living column reached column 0, with `bx` at 252, and nothing was drawn in the wrong place (`step10-march-edge.png`).
- In the examples, read the `INVAT` table again with step 9's carry tests in mind: column 0 would have been "left of the block", and the thin block above could not have been drawn on the left.
