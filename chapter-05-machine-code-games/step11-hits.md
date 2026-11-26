# Chapter 5, step 11 — Shot against invader

Chapter 4's step 5 made the shot kill. A shot arriving on a living invader cleared its entry in the array `V` and put a space in both animation strings, showed a yellow starburst for a few passes, and was gone. The march then took its edges from the living columns, so a thinned block went further, and when all 32 were dead the program printed `WAVE CLEARED`. All of that cost time: an idle pass went from 4.3 frames to 4.7, a shot step with the hit test was 9.7 frames, and a march cycle 86 frames.

This step is its twin. The design rests on one rule, already set up in step 9: **the `alive` table is the only record of who is alive.** A kill is one instruction, `ld (hl),0`. Nothing else has to be told: the next march step skips the dead invader, because `mblock` asks `aliveat`; the edges skip it, because `colalive` reads the table; and a shot passing its cell later goes through, because `invat` reads the table too. Chapter 4 had to keep three things in step, the array and two strings; here there is one.

The costs, measured as before: an idle pass is 0.0055 of a frame, a shot step with its hit test 0.029, and a hit 0.037. The march step is still the big one, 0.78 of a frame for a full block, and a pass with a march step, a shot, a hit and a base move all in it still fitted in its frame every time.

Every program here was assembled with pasmo, cross-checked against z80asm, and run in a 48K emulator before it was shown.

## The new instructions and ideas

There are no new instructions. The new ideas are the hit test in both directions, a kill that is one byte, an explosion with a beat of its own, counting the table, and a fix to the shot's top row. The examples are in `step11-examples.asm`, with a BASIC driver, `step11-examples.bas`; `step11-examples.png` is its screen, and the results below are copied from it.

### The hit test, both ways round

Step 9's `invat` answers "is this screen cell an invader's place, and which one?". Step 9 used it to draw an invader again behind the shot. Now it decides hits, and there are two ways a shot and an invader can meet. The shot can move up onto an invader, or, since the block now marches, an invader can move onto the shot. `sstep` tests both:

```
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
```

`stest` is the second test, on the cell the shot has just come to; `fire` calls it too, for a block that has come down to row 20. If there is no living invader, `stest` goes on to `sdraw`, so a shot through a hole, or a gap, is drawn as before.

Because a shot can no longer share a cell with a living invader, step 9's "draw the invader again behind the shot" has gone from `sstep`. The cell the shot leaves is always empty.

### A kill is one byte

`invat` ends with `jp aliveat`, which leaves HL on the invader's byte in the table, as well as `irow` and `icol`. So `hit` starts with the whole of the kill:

```
hit:    ld (hl),0       ; dead: the table says so, and that is all
        ld a,255
        ld (srow),a     ; the shot is used up
        ld hl,hits
        inc (hl)        ; one more hit
        ld hl,nleft
        dec (hl)        ; one fewer alive
```

The invader's picture is still on the screen, under the starburst that `hit` draws next, and nothing ever draws it again. Example 2 does only the kill, with the block at `bx` 8 and `by` 1:

| Cell | Killed | `irow` | `icol` | Alive after |
|------|-------:|-------:|-------:|------------:|
| 7, 16 | 1 | 3 | 4 | 31 |
| 7, 16 again | 0 | 3 | 4 | 31 |
| 7, 15 | 0 | 3 | 9 | 31 |
| 0, 8 | 0 | 9 | 9 | 31 |
| 1, 8 | 1 | 0 | 0 | 30 |
| 1, 22 | 1 | 0 | 7 | 29 |
| 21, 16 | 0 | 9 | 9 | 29 |

The second shot at 7, 16 finds the place, but its byte is now 0, so nothing happens: a hole. 7, 15 is a gap, so `invat` stops after setting `irow` (9 is the value BASIC poked first, showing what was not set). Row 3 of the table then reads `11110111`.

### The explosion, on a beat of its own

The starburst is Chapter 4's UDG P, in yellow. Chapter 4 showed it for a few passes of its loop, so how long it lasted depended on what else the loop was doing. Here it is a fourth beat, counted in passes, which are frames: `elen`, 12 as shipped, about a quarter of a second.

```
boom:   ld a,(erow)
        inc a           ; 255 becomes 0: is there no explosion?
        jr z,march      ; none: on to the march
        ld hl,etime
        dec (hl)        ; one pass fewer to its end
        call z,erub     ; its time is up: rub it out
```

There is one explosion at a time, as there is one shot at a time; `hit` ends the last one first. `erub` rubs it out, and then asks `invat` whether a living invader has marched onto the cell while it was showing. If one has, it draws it again, the same trick step 9 used behind the shot:

```
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
```

The first version of the loop had a bug worth knowing. The shot's beat jumped to `march` when there was no shot step to take, so it skipped the new `boom` beat, and an explosion stayed until the next shot came along. In Fuse a one-second explosion stayed for well over two. Each beat's "not yet" has to jump to the next beat, not past it.

### Counting the table

`nleft` is the number of invaders alive. `start` counts the table once with `count`, so a table poked by BASIC starts with the right number, and `hit` takes one away. `count` adds the bytes, since each one is 0 or 1:

```
count:  ld hl,alive
        ld b,32         ; 32 invaders
        xor a
cnt1:   add a,(hl)      ; add its byte, 0 or 1
        inc hl
        djnz cnt1
        ld (nleft),a
        ret
```

When `nleft` comes down to 0, `hit` prints `WAVE CLEARED` on row 0. Nothing has to stop the march: `edges` finds no living column, returns with the carry set, and `mstep` returns too. `mstep` now counts a march step only after `edges` has found one, so `msteps` stops when the march does.

### The shot stops at row 1

In testing, `WAVE CLEARED` came up with most of its letters missing: the shots that were still flying went up to row 0 and rubbed out the cells they passed. Step 10's code does the same to `THEY HAVE LANDED`; it was not seen there because no shot was fired over it. Row 0 is for messages, and for the score in step 14, so the shot now leaves from row 1: `cp 1` in place of `and a`, one byte more. The block's top row is never above row 1, so nothing can be missed.

## The listing

The machine code, `step11-hits.asm`. It is step 10's, with the hit parameters, the explosion beat, `sstep` with both tests, `stest`, `hit`, `erub`, `count`, the message and the starburst added.

```
; step11-hits.asm - Chapter 5, step 11
; Shot against invader: the twin of Chapter 4, step 5.
; It is step 10's march, and the shot now kills. When the shot arrives
; on a living invader's cell, or an invader marches onto the shot,
; invat gives the invader, its byte in the alive table becomes 0, the
; shot is gone, and a yellow starburst, Chapter 4's UDG P, shows on the
; cell for elen frames. The table is the only record of who is alive:
; the march, the edges and the drawing all read it, so a hole marches
; with the block, and a block with its outer columns shot away marches
; further. When the last one dies, WAVE CLEARED is printed on row 0.
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
;
; Entry point:
;   RANDOMIZE USR 50030  start
;
; Build:  tools/build.sh chapter-05-machine-code-games/step11-hits.bas chapter-05-machine-code-games/step11-hits.asm hits 10

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
        ld (erow),a     ; and no explosion
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
        jr z,march      ; none: on to the march
        ld hl,etime
        dec (hl)        ; one pass fewer to its end
        call z,erub     ; its time is up: rub it out

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
        jr z,sdraw      ; no: draw the shot

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
; step 4, and its explosion, UDG P, from its step 5. Each invader
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
blank:  db 0,0,0,0,0,0,0,0

        end
```

It is 1102 bytes, 50000 to 51101. pasmo's listing puts `start` at 50030, `loop` at 50090, `boom` at 50126, `march` at 50139, `keys` at 50152, `fire` at 50193, `sstep` at 50226, `stest` at 50265, `hit` at 50274, `erub` at 50335, `count` at 50365, `dinv` at 50569, `invat` at 50660, `mstep` at 50699, `mblock` at 50807, `edges` at 50852, `pstr` at 50924, `alive` at 50978, `rows` at 51010 and `burst` at 51086.

The BASIC driver, `step11-hits.bas`. The entry point is 50030. Line 66 clears `hits` and sets `elen`. The counts at the end now show the hits and the invaders still alive, read with `PEEK` straight into `PRINT`, so no new variable is needed.

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
70 PRINT #0;"O LEFT, P RIGHT, SPACE FIRES, Q STOPS"
80 POKE 23672,0: POKE 23673,0: POKE 23674,0
90 RANDOMIZE USR 50030
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
230 IF N>0 THEN PRINT "FRAMES A PASS ";F/N
240 IF M>0 THEN PRINT "FRAMES A MOVE ";F/M
250 IF S>0 THEN PRINT "FRAMES A SHOT STEP ";F/S
255 IF G>0 THEN PRINT "FRAMES A MARCH STEP ";F/G
260 IF INKEY$<>"" THEN GO TO 260
```

## Building and running

On Windows, from the course folder:

```
windows-tools\build.bat chapter-05-machine-code-games\step11-hits.bas chapter-05-machine-code-games\step11-hits.asm hits 10
```

On Linux:

```
tools/build.sh chapter-05-machine-code-games/step11-hits.bas chapter-05-machine-code-games/step11-hits.asm hits 10
```

The examples:

```
windows-tools\build.bat chapter-05-machine-code-games\step11-examples.bas chapter-05-machine-code-games\step11-examples.asm examples 20
```

```
tools/build.sh chapter-05-machine-code-games/step11-examples.bas chapter-05-machine-code-games/step11-examples.asm examples 20
```

O and P move the base, Space fires, and Q stops and shows the counts.

## What it showed in Fuse

The tape was loaded in a 48K Fuse at normal speed.

- **A hit.** A shot from under the block's bottom row killed the invader there, and the starburst showed on its cell for about a quarter of a second, then the cell was empty (`step11-hits.png`). With the block held still (see Try this), a second shot up the same column went through the hole and killed the cyan invader above it.
- **Holes march.** The holes moved with the block, and the starburst stayed where the invader died while the block marched on.
- **A remnant.** A test copy, with step 10's `auto` routine in place of the keys, bounced the base from side to side with Space held. The block thinned to a scattered remnant that kept marching, with its edges taken from the living columns as in step 10 (`step11-hits-remnant.png`, with a starburst on the right).
- **Wave cleared.** The last one died after 97 march steps, `WAVE CLEARED` came up on row 0 and stayed whole while shots went on flying, and the march stopped (`step11-hits-cleared.png`). The counts (`step11-hits-result.png`) showed 32 hits, 0 alive, and 6001 passes in 6002 frames: not one pass ran over its frame.
- **The examples** gave the table above.

pasmo and z80asm gave the same 1102 bytes for `step11-hits.asm`, and the same non-zero bytes for `step11-examples.asm`.

## The timing, against BASIC

Chapter 4's step 5 timed an idle pass, an official march cycle, a shot step that misses, with the block still, and a pass with a hit. This step's copies use the `auto` routine again. For the idle pass and the shot, `landed` was poked to 1, so the block stays still; for the shot, the base was put in column 0, below no invader, so every shot misses. A hit was timed on its own: a test copy calls `hit` 1024 times on an invader of the block, with `erub` drawing it again each time, the most `hit` can do short of clearing the wave.

| What | Chapter 4, step 5 | This step, as shipped | This step, no `halt` |
|------|------------------:|----------------------:|---------------------:|
| An idle pass | 4.7 | 1 | 0.0055 (30001 passes in 166 frames) |
| A shot step that misses, block still | 9.7 | 1 | 0.0286 (2100 steps in 60 frames) |
| A hit | 10.3 (the pass with it) | inside its pass | 0.037 (1024 in 38 frames) |
| A march step | an 86-frame cycle | 1 pass, once every 25 | 0.781 (200 steps in 157 frames, full block) |

Against Chapter 4, an idle pass is about 850 times as quick, and a shot step about 340 times.

**The frame budget.** Step 10's march step was 0.785 of a frame, so the question for this step was whether a march step, a shot step, a hit and a base move could all land in one pass and still fit. Adding them up gives about 0.87 of a frame. To test it, a copy ran with `mspeed` 1, a march step on every pass, with the `auto` routine moving the base and firing. Until the block landed, after 244 march steps and 15 hits, every one of those passes had a march step, most had a shot step, and some had hits. 2001 passes took 2002 frames: none ran over. So no fallback is needed yet. If one is needed later, it is Chapter 4's: move the block a row a pass.

## Line by line

- **`hits`, `nleft`, `elen`, `etime`, `erow`, `ecol`** at 50024 to 50029. The entry point moves to 50030. `nleft` is not called `left`, because `left` is already the routine that moves the base: pasmo would stop with "previously defined".
- **`start`** also clears `erow` to 255, no explosion, and counts the table with `count`.
- **The shot's beat** goes on to `boom` when there is no step to take.
- **`boom`** counts the explosion down and calls `erub` when its time is up.
- **`fire`** calls `stest` in place of `sdraw`.
- **`sstep`** tests the shot's cell before and after it moves, and lets it go from row 1.
- **`stest`** draws the shot, or goes on to `hit`.
- **`hit`** writes the 0, ends the shot, counts, ends the last explosion, draws the starburst, and prints `WAVE CLEARED` after the last one.
- **`erub`** rubs out the starburst and draws again any invader that has marched onto it.
- **`count`** adds up the table.
- **`mstep`** counts a step only after `edges` has found a living column.
- **`ctext`, `burst`**: the message, and UDG P.

## Limitations you will notice

- **A shot through a starburst rubs it out.** The explosion is ended a little early, and `erub` rubs out the empty cell later. It is not worth the bytes to prevent.
- **`shots` is one byte.** After 255 shots it goes round: the test that cleared the wave fired 309 and showed 53.
- **The landing test still uses the block's top row.** A remnant with only its top rows left lands when the full block would have, with `by` at 14, so its invaders are still on rows 14 to 18, not on row 20. Chapter 4 had the same rule.
- **Nothing happens after the wave.** A new wave, faster and lower, is step 14.
- **The march does not speed up.** See Try this.

## Try this

Each of these was tried in Fuse.

- Hold the block still and watch a longer explosion: on line 65 poke `mspeed` (50017) as 255 and `dx` (50019) as 0, on line 60 poke `x` (50010) as 16, and on line 66 poke `elen` (50026) as 50. With `dx` 0, a sideways step adds nothing, so the block never reaches an edge and never moves. A shot from column 16 killed the bottom invader, and the starburst stayed for a second, 50 frames (`step11-hits-burst.png`).
- Make the march speed up as the wave thins, as Chapter 4's Try this did with `W`. In `hit`, after `dec (hl)`, add `ld a,(hl)`, `srl a`, `add a,4` and `ld (mspeed),a`, so the beat is `nleft/2 + 4`: 20 frames with 32 alive, 4 with one. With the `auto` routine playing, the last invader then marched at 12 steps a second, the bouncing base could not catch it, and it landed (`step11-hits-try.png`): 31 hits, 290 march steps. A real player has to aim.
