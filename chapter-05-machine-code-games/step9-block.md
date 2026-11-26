# Chapter 5, step 9 — The block of invaders

Chapter 4's step 3 put the invaders on the screen: 4 rows of 8, three types, magenta on top, cyan in the middle two rows and white at the bottom, standing still above the base. This step is its twin. The base and the shot are step 8's, unchanged, and the block is drawn from two tables: one that says which invaders are alive, and one that says what each row looks like.

Chapter 4 had to be careful about how it drew the block. Printing the 32 invaders one at a time took 68 frames, so it built each row as a 17-character string and printed four strings, 3.8 frames. Machine code does not need the trick. This step draws each invader into its own cell, as `put` has drawn everything since step 1, and the whole block takes **0.44 of a frame**: 155 times as quick as BASIC cell by cell, and 8.6 times as quick as BASIC's string trick. That decides how the rest of Part B draws: one invader at a time, from the table.

The shot passes through the block, as it did in Chapter 4, and the invader it passed over is drawn again behind it. To do that the code turns a screen cell back into a place in the block, the reverse of drawing, and step 11's hits will use the same routine.

Every program here was assembled with pasmo, cross-checked against z80asm, and run in a 48K emulator before it was shown.

## The new instructions and ideas

There are no new instructions in this step. What is new is the way the data is laid out, and three small routines that work on it. The examples are in `step9-examples.asm`, with a BASIC driver, `step9-examples.bas`, which tries the two lookups on a list of cells and prints a table. `step9-examples.png` is its screen, and every result below is copied from it.

### The alive table: one byte for each invader

```
alive:  db 1,1,1,1,1,1,1,1
        db 1,1,1,1,1,1,1,1
        db 1,1,1,1,1,1,1,1
        db 1,1,1,1,1,1,1,1
```

This is Chapter 4's `V(4,8)`, 32 bytes, row by row: the first 8 are the top row, left to right. 1 is an invader that is there, 0 one that has been shot. It is the source of truth for the block. Nothing finds out whether an invader is alive by looking at the screen, because the screen may have a shot or, later, a bomb drawn over it. Drawing, the march's edges in step 10 and the hits in step 11 all read this table.

A byte for each invader, not a bit, is a choice for teaching and for speed. Eight invaders would fit in one byte, a bit each, but then every look would need a shift and a mask. 32 bytes cost nothing in 48K, and a byte can be tested with `and a` and changed with one `ld`.

Invader `icol` of block row `irow` is at `alive + 8*irow + icol`. `aliveat` works that out:

```
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
```

| Instruction | Bytes (hex) | T-states | Here |
|-------------|-------------|---------:|------|
| `ADD A,A` | `87` | 4 | three of them multiply by 8 |
| `ADD A,(HL)` | `86` | 7 | adds `icol` from memory |
| `LD D,n` | `16` n | 7 | DE = the 8-bit offset |
| `ADD HL,DE` | `19` | 11 | the table's address plus the offset |

Three `add a,a` are 12 T-states, where a multiply by 8 in BASIC is a floating-point sum. Example 2 gives the address in BC. In Fuse, with `alive` at 50300 in the examples, it gave 50300 for row 0 invader 0, 50307 for row 0 invader 7, 50308 for row 1 invader 0 and 50331 for row 3 invader 7.

`irow` and `icol` are two bytes in memory, not registers. Every routine of the block reads them, and `put` and `attr` need B, C, DE and HL, so keeping the two numbers in registers would mean pushing and popping them around every call. In memory they cost a few T-states each time, and the code is easier to follow. The names are not `r` and `k`, as Chapter 4's were: `r` is the name of a Z80 register, the refresh register, and pasmo will not take it as a label.

### The rows table: what each row looks like

```
rows:   dw inv1
        db 3            ; magenta
        dw inv2
        db 5            ; cyan
        dw inv2
        db 5            ; cyan
        dw inv3
        db 7            ; white
```

Three bytes for each block row: the address of its graphic, a word, and its ink. Chapter 4 worked the UDG and the ink out with sums, `147+2*(R>1)+2*(R=4)` and `3+2*(R>1)+2*(R=4)`. A table says the same thing without the arithmetic, and to change a row's colour or its type you change a byte, not the code. `dw inv1` stores the address the assembler gave the label `inv1`, low byte first.

`rtype` finds the entry, `rows + 3*irow`, and reads the word into DE and the ink into A:

```
        ld e,(hl)
        inc hl
        ld d,(hl)       ; DE = the graphic
        inc hl
        ld a,(hl)       ; A = the ink
```

This is the word-from-a-table pattern from step 5's table of notes. `3*irow` is `irow + irow + irow`, with `add a,a` and `add a,e`.

The graphics are Chapter 4's UDGs D, F and H, its first frames, as eight bytes each. Step 10 adds the second frames, E, G and I.

### Drawing an invader: the table, a cell and an attribute

```
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
```

`where` puts invader `icol` of row `irow` at screen row `by + 2*irow` and column `bx + 2*icol`. With `bx` 8 and `by` 1, as shipped, the block is on rows 1, 3, 5 and 7, in columns 8 to 22, where Chapter 4's was: its strings started at column 7 with a space. `dblock` calls `dinv` for all 32, row by row.

Each invader sets its own attribute, so the colour goes with the invader wherever it is drawn. That matters in step 10, when the block moves. Chapter 4 did the same with `INK` in each `PRINT`.

### invat: from a screen cell back to the block

The shot is drawn over whatever is in its cell. When it moves on, the cell is rubbed out, and if an invader was there, it has to come back. `invat` takes the cell in B and C and answers the question "is this an invader's place, and is it alive?":

```
invat:  ld a,b
        ld hl,by
        sub (hl)        ; A = row - by
        jr c,noinv      ; above the block
        cp 7
        jr nc,noinv     ; below it: block rows are 0, 2, 4 and 6
        bit 0,a
        jr nz,noinv     ; an odd row: between two block rows
        rrca            ; A = (row - by) / 2, since bit 0 is 0
        ld (irow),a
```

and the same for the column, with `bx`, 15 and `icol`, then `jp aliveat`. The tests are the reverse of `where`. A carry from `sub (hl)` means the cell is above or to the left of the block. `bit 0,a` finds the gaps, the odd rows and columns between invaders. `rrca` halves A when bit 0 is 0: the 0 goes round to bit 7, and the rest move down one place.

Example 1 runs `invat` on a list of cells, with `irow` and `icol` set to 9 first, so you can see which it changed:

| Cell (row, column) | `invat` | `irow` | `icol` | Why |
|--------------------|--------:|-------:|-------:|-----|
| 1, 8 | 1 | 0 | 0 | the top-left invader |
| 7, 22 | 1 | 3 | 7 | the bottom-right invader |
| 3, 14 | 1 | 1 | 3 | row 1, invader 3 |
| 2, 8 | 0 | 9 | 9 | between rows |
| 1, 9 | 0 | 0 | 9 | a gap between invaders: the row was set before the column failed |
| 0, 8 | 0 | 9 | 9 | above the block |
| 9, 8 | 0 | 9 | 9 | below it |
| 1, 24 | 0 | 0 | 9 | right of it |
| 7, 22, with that invader's byte set to 0 | 0 | 3 | 7 | its place, but it is not alive |

The last line is the reason `invat` ends with `aliveat`: a place in the block is only an invader if the table says so. In step 11 the same routine will tell a shot what it hit.

`sstep` uses it after rubbing the shot out:

```
        call scell
        call invat      ; was it over an invader?
        and a
        call nz,dinv    ; yes: draw the invader again
```

`invat` has set `irow` and `icol`, so `dinv` draws the right one.

## The listing

The machine code, `step9-block.asm`. It is step 8's, with `bx` and `by` added to the parameters, `dblock` called from `start`, `sstep` drawing an invader again behind the shot, and `dblock`, `dinv`, `aliveat`, `where`, `rtype`, `invat`, the two tables and three graphics added.

```
; step9-block.asm - Chapter 5, step 9
; The block of invaders: the twin of Chapter 4, step 3.
; It is step 8's base and shot, with 4 rows of 8 invaders above them.
; The invaders are Chapter 4's UDGs D, F and H, in magenta, cyan and
; white, drawn from two tables: alive, one byte for each invader, 1 if
; it is there, and rows, the graphic and the ink of each row. They do
; not move yet. The shot passes through the block, and the invader it
; passed over is drawn again behind it.
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
;
; Entry point:
;   RANDOMIZE USR 50017  start
;
; Build:  tools/build.sh chapter-05-machine-code-games/step9-block.bas chapter-05-machine-code-games/step9-block.asm block 10

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

; aliveat: A = the alive byte of invader k in block row r, and HL its
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

; where: B = the screen row of invader k in block row r, by + 2*irow,
; and C its column, bx + 2*icol. Changes A, HL.

where:  ld a,(irow)
        add a,a
        ld hl,by
        add a,(hl)
        ld b,a          ; B = by + 2*irow
        ld a,(icol)
        add a,a
        ld hl,bx
        add a,(hl)
        ld c,a          ; C = bx + 2*icol
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
        ld d,(hl)       ; DE = the graphic
        inc hl
        ld a,(hl)       ; A = the ink
        ret

; invat: is the cell at row B, column C an invader's place in the
; block? If it is, irow and icol are set to it, and A is its alive byte;
; if not, A = 0. Keeps B and C. Changes DE, HL.

invat:  ld a,b
        ld hl,by
        sub (hl)        ; A = row - by
        jr c,noinv      ; above the block
        cp 7
        jr nc,noinv     ; below it: block rows are 0, 2, 4 and 6
        bit 0,a
        jr nz,noinv     ; an odd row: between two block rows
        rrca            ; A = (row - by) / 2, since bit 0 is 0
        ld (irow),a
        ld a,c
        ld hl,bx
        sub (hl)        ; A = column - bx
        jr c,noinv      ; left of the block
        cp 15
        jr nc,noinv     ; right of it: columns 0, 2, ... 14
        bit 0,a
        jr nz,noinv     ; an odd column: a gap
        rrca
        ld (icol),a
        jp aliveat      ; A = its alive byte
noinv:  xor a           ; not an invader's place
        ret

; The block's working bytes and tables.

irow:   db 0            ; the block row being drawn, 0 to 3
icol:   db 0            ; the invader in that row, 0 to 7

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
; 997, and its invaders, UDGs D, F and H, from lines 1000 to 1025 of
; its step 3.

base:   db 24,24,24,126,255,255,255,255
shot:   db 0,24,24,24,24,24,24,0
inv1:   db 60,126,255,219,255,90,165,66 ; UDG D, the top row
inv2:   db 66,36,126,219,255,189,165,36 ; UDG F, the middle two rows
inv3:   db 60,255,255,231,255,90,165,129 ; UDG H, the bottom row
blank:  db 0,0,0,0,0,0,0,0

        end
```

It is 615 bytes, 50000 to 50614. pasmo's listing puts `start` at 50017, `loop` at 50062, `sstep` at 50172, `put` at 50326, `attr` at 50353, `dblock` at 50371, `dinv` at 50401, `aliveat` at 50421, `where` at 50440, `rtype` at 50459, `invat` at 50478, `irow` at 50521, `icol` at 50522, `alive` at 50523, `rows` at 50555 and `inv1` at 50583.

The BASIC driver, `step9-block.bas`. The entry point is 50017. It is step 8's, with `bx` and `by` poked on line 60.

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
60 POKE 50000,1: POKE 50001,2: POKE 50002,1: POKE 50010,15: POKE 50015,8: POKE 50016,1
70 PRINT #0;"O LEFT, P RIGHT, SPACE FIRES, Q STOPS"
80 POKE 23672,0: POKE 23673,0: POKE 23674,0
90 RANDOMIZE USR 50017
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
windows-tools\build.bat chapter-05-machine-code-games\step9-block.bas chapter-05-machine-code-games\step9-block.asm block 10
```

On Linux:

```
tools/build.sh chapter-05-machine-code-games/step9-block.bas chapter-05-machine-code-games/step9-block.asm block 10
```

The examples:

```
windows-tools\build.bat chapter-05-machine-code-games\step9-examples.bas chapter-05-machine-code-games\step9-examples.asm examples 20
```

```
tools/build.sh chapter-05-machine-code-games/step9-examples.bas chapter-05-machine-code-games/step9-examples.asm examples 20
```

The block appears at once, with the base below it. O and P move the base, Space fires, and Q stops and shows the counts.

## What it showed in Fuse

The tape was loaded in a 48K Fuse at normal speed.

- **The block.** 32 invaders, magenta, cyan, cyan and white, on rows 1, 3, 5 and 7, columns 8 to 22, the same shapes and place as Chapter 4's (`step9-block.png`).
- **The shot through the block.** Fired from column 22, the shot was caught on row 3, drawn over the cyan invader there, with the invaders it had passed on rows 5 and 7 drawn again behind it (`step9-block-shot.png`). When it had gone, the column was whole. A shot fired from column 15, a gap, left the block as it was.
- **The lookups.** The examples gave the tables above.
- **Moving the block and changing the tables.** See Try this.

pasmo and z80asm gave the same 615 bytes for `step9-block.asm`, and the same non-zero bytes for `step9-examples.asm`.

## The timing, against BASIC

Chapter 4's step 3 timed an idle pass, the base and the shot through the still block, and the drawing of the block, as strings and cell by cell. This step's timing copies use step 8's `auto` routine in place of `rkeys`, and for the block a copy whose `start` draws it 100 times and returns.

| What | Chapter 4, step 3 | This step, as shipped | This step, no `halt` |
|------|------------------:|----------------------:|---------------------:|
| An idle pass | 2.6 | 1 (a pass a frame) | 0.00535 (32719 passes in 175 frames) |
| The base, a move | 3.4 | 2.008 (248 in 498 frames) | 0.0210 (6200 in 130 frames) |
| The shot, a step, up an invader column | 5.5 | 1.00 (21 steps on 21 passes) | 0.0305 (2100 steps in 64 frames) |
| The whole block drawn | 3.8 as strings, 68 cell by cell | | 0.44 (100 blocks in 44 frames) |

Against Chapter 4, an idle pass is about 490 times as quick, a base move 160, a shot step 180, and the block 155 times as quick as BASIC drawing the same cells, 8.6 times as quick as BASIC's strings.

The shot step costs more than in step 8, 0.0305 against 0.0248, because each step now asks `invat` about the cell it leaves and, in an invader's column, draws the invader again: about 400 T-states. An idle pass is 0.00535, against step 7's 0.00464: the extra is the test for a shot, which step 8 added.

0.44 of a frame for 32 invaders is about 960 T-states each, `aliveat`, `rtype`, `where`, `attr` and `put`, with the loop around them. That is the number step 10 has to live with: a march step that redraws the block is about half a frame.

## Line by line

- **`bx`, `by`** at 50015 and 50016: where the block is. The entry point moves to 50017.
- **`start`** calls `dblock` after drawing the base.
- **`sstep`** gets the shot's cell from `scell` twice, because `put` changes B; after rubbing it out it calls `invat`, and `dinv` if there was a living invader there.
- **`scell`** loads B and C from `srow` and `scol`.
- **`dblock`** counts `irow` from 0 to 3 and `icol` from 0 to 7, with `inc (hl)` and `cp`, and calls `dinv` for each.
- **`dinv`** returns at once for a dead invader; otherwise it gets the graphic and the ink, the cell and its attribute, sets the ink and draws.
- **`aliveat`, `where`, `rtype`** turn `irow` and `icol` into the table byte, the screen cell, and the graphic and ink.
- **`invat`** turns a screen cell back into `irow` and `icol`, and the alive byte.
- **`irow`, `icol`, `alive`, `rows`** are the working bytes and the tables; **`inv1`, `inv2`, `inv3`** the graphics.

## Limitations you will notice

- **The block does not move.** That is step 10.
- **Shots do not hit.** The shot passes through, as in Chapter 4's step 3. Step 11 uses `invat` to find what it hit.
- **The alive table is not reset.** `start` draws whatever the table says. A change poked into it stays until the tape is loaded again.
- **The block cannot start to the left of column 0.** `bx` is an unsigned byte, so the left-hand invader's column cannot be off the screen. Once the outer columns are shot away the block will need to go further; that is for step 11.
- **The shot hides an invader while it is on it.** For one frame, the yellow shot is drawn in the invader's cell, as BASIC's was.

## Try this

Each of these was tried in Fuse.

- Move the block and thin it out: on line 60 poke `bx` and `by` as 2 and 4, and add `62 POKE 50523,0: POKE 50523+31,0: POKE 50557,2`. That kills the top-left and bottom-right invaders (`alive` is at 50523) and makes the top row red (its ink is the third byte of `rows`, at 50557). The block came up with its left-hand invader in column 2 and its rows on 4, 6, 8 and 10, red on top, with the two corners missing (`step9-block-try.png`).
