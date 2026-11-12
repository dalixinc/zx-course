# Chapter 3, step 7 — The attribute fill in machine code, timed

Step 2 filled the 768 attribute bytes from BASIC, one `POKE` at a time, and timed it with `FRAMES`: **325 frames**, six and a half seconds. This step is its twin. It does the same job, the same 768 bytes with the same colour, 14 (blue paper, yellow ink), in machine code, and times it the same way.

It does it twice, in two different ways:

1. **A loop.** This is step 4's fill loop, grown up a little. The colour is no longer fixed inside the code: BASIC `POKE`s it into a byte at 50000, and the routine reads it from there. The loop counts with BC and keeps the colour in E, one half of the pair DE.
2. **`LDIR`.** One Z80 instruction that copies a whole block of memory. We colour the first cell by hand, then copy it along to the next 767, so the colour runs from cell to cell down the screen.

A single fill is too quick for `FRAMES` to see, so each routine can repeat itself as many times as BASIC asks. The program times 250 fills of each kind, and then 250 more of each kind in ordinary memory at 60000, where nobody is looking. The last two are a control experiment: they show how much the screen itself slows the Z80 down.

There are three things to compare with step 2:

1. **The speed.** One loop fill took 0.448 frames and one `LDIR` fill 0.304 frames, against BASIC's 325. That is about 725 and about 1070 times as fast.
2. **How it is put together.** Step 2's `FOR A=22528 TO 23295: POKE A,14: NEXT A` becomes six instructions in a loop, or five instructions and an `LDIR`. The section "Side by side" lines them up.
3. **The arithmetic.** In machine code we can count the time each instruction takes, add it up, and check it against `FRAMES`. The counts agree with Fuse, once you know about one thing, *contended memory*, which this step introduces in outline.

The new instructions are few: `LD (HL),r`, a register version of step 4's `LD (HL),n`, and `LDIR`. `LD A,(nn)` and `LD HL,(nn)` from steps 5 and 6 now carry the parameters in from BASIC. Everything else was in steps 4 and 5.

Every program here was assembled with pasmo, cross-checked against a second assembler, z80asm, and run in a 48K emulator before it was shown.

## The new instructions and ideas

### Passing values in from BASIC: parameter bytes

Step 5's examples had an *inbox*, a byte at 50000 that BASIC `POKE`d before calling an example. This step has three of them, at the start of the code, each with a label:

```
colour: db 14           ; 50000: the colour, POKEd by BASIC
times:  db 1            ; 50001: how many fills
where:  dw 22528        ; 50002-50003: where to start
```

The `db` and `dw` give each one a starting value, so the code works even if BASIC pokes nothing. BASIC changes them with `POKE`; the code reads them with `LD A,(nn)` for a single byte, and `LD HL,(nn)` or `LD DE,(nn)` for a two-byte one:

| In the code | Reads | In BASIC, to change it |
|-------------|-------|------------------------|
| `ld a,(colour)` | 50000 | `POKE 50000,14` |
| `ld a,(times)` | 50001 | `POKE 50001,250` |
| `ld hl,(where)` | 50002 and 50003, low byte first | `POKE 50002,0: POKE 50003,88` for 22528; `POKE 50002,96: POKE 50003,234` for 60000 |

22528 is 88*256+0, and 60000 is 234*256+96, so the low byte goes in 50002 and the high byte in 50003.

Parameter bytes are simple to see and to test: `PRINT PEEK 50000` shows you exactly what the code will read.

The code itself starts at 50004, after the parameters. That is why the program calls `RANDOMIZE USR 50004`, not 50000. If BASIC called 50000, the Z80 would try to run the colour byte as an instruction.

### LD (HL),r — store a register in memory

Step 4's loop stored a fixed number: `LD (HL),48`. Now the colour comes from BASIC, so it has to be in a register. `LD (HL),r` writes the register r into memory at the address in HL. r can be A, B, C, D, E, H or L.

| Instruction | Bytes (hex) | Bytes (decimal) | T-states |
|-------------|-------------|-----------------|----------|
| `LD (HL),E` | `73` | 115 | 7 |
| `LD (HL),A` | `77` | 119 | 7 |
| `LD (HL),n` (step 4) | `36` n | 54, n | 10 |

Example: in the loop, `ld (hl),e` colours one cell with the colour in E. It is one byte shorter and three T-states quicker than step 4's `ld (hl),48`, because the Z80 does not have to fetch the number from after the instruction.

Why E and not A? The loop needs A for its zero test, `ld a,b` / `or c`, which overwrites A every time round. So the colour is copied out of A into E before the loop starts. D, the other half of DE, counts the fills.

### LDIR — copy a block of memory

`LDIR` (*load, increment, repeat*) copies a block of bytes from one place in memory to another. Before it starts, three register pairs must be set:

- **HL** = where to copy *from*,
- **DE** = where to copy *to*,
- **BC** = how many bytes.

Then, for each byte, it does this:

1. Copy the byte at (HL) to (DE).
2. Add one to HL and one to DE.
3. Take one from BC.
4. If BC is not zero, go back to 1.

It is the same as this BASIC, in one instruction:

```
FOR I=1 TO BC: POKE DE,PEEK HL: LET HL=HL+1: LET DE=DE+1: NEXT I
```

| Instruction | Bytes (hex) | Bytes (decimal) | T-states |
|-------------|-------------|-----------------|----------|
| `LDIR` | `ED B0` | 237, 176 | 21 per byte, 16 for the last |

**Options.** It has three relatives, all two bytes starting `ED`:

- `LDI` (`ED A0`) copies one byte, steps HL and DE on, takes one from BC, and stops. 16 T-states.
- `LDD` (`ED A8`) is the same, but HL and DE go *down* by one.
- `LDDR` (`ED B8`) repeats `LDD` until BC is zero: a block copy from the top down.

`LDDR` matters when the two blocks overlap and you are moving bytes *up* in memory. This step only needs `LDIR`.

**The flags.** `LDIR` leaves Z, S and the carry as they were. It always clears H and N, and it clears the P/V flag (the parity/overflow flag, not met before) when BC reaches zero. So, unlike `DEC BC`, it does not tell you anything you can test with `JR Z`. You do not need to test: when the next instruction runs, BC is 0.

**Three things to know.**

- **BC = 0 means 65536.** `LDIR` takes one from BC *before* it checks for zero, so if BC starts at 0 it goes round 65536 times and copies over all of memory, including the program that is running. Always set BC first.
- **It can be interrupted.** After each byte, if BC is not zero, the Z80 moves PC back two bytes, to the `LDIR` itself, and fetches it again. An interrupt can happen between any two bytes. On the Spectrum that is what keeps `FRAMES` ticking during a long copy.
- **The 21 T-states.** 16 for the copy, the same as `LDI`, and 5 more for winding PC back to repeat. The last byte does not repeat, so it takes 16. A block of n bytes takes 21n−5.

These figures are from Zilog's *Z80 CPU User Manual* (UM0080).

**Example: the ROM on the screen.** Save this as `romcopy.asm`:

```
        org 50000
start:  ld hl,0         ; HL = from: the start of the ROM
        ld de,16384     ; DE = to: the start of the screen bitmap
        ld bc,6144      ; BC = how many bytes: the whole bitmap
        ldir            ; copy them
        ret
        end start
```

Build it with `windows-tools\build.bat romcopy.asm` (or `tools/build.sh romcopy.asm`). As it loads and runs, the screen fills with a speckle of dots: the first 6144 bytes of the ROM, the BASIC interpreter itself, as pixels. Then `0 OK, 40:1`. pasmo assembles it to 12 bytes: `21 00 00 11 00 40 01 00 18 ED B0 C9`.

### Filling with LDIR: copy a block onto itself, one byte along

`LDIR` copies; it does not fill. The trick is to let it copy into its own path.

Colour the first cell, at 22528, by hand. Then set HL to 22528 and DE to 22529, one byte ahead, with BC = 767, and `LDIR`:

- The first byte copied is 22528 to 22529. Now cell 1 has the colour.
- The next is 22529 to 22530. Cell 1 was coloured a moment ago, so cell 2 gets the colour.
- And so on: each copy reads the cell that the copy before it has just written.

After 767 copies, all 768 cells have the colour. HL is always one cell behind DE, and the colour runs along the row like water. 767, not 768, because the first cell was done by hand.

In the code:

```
        ld a,(colour)   ; A = the colour BASIC POKEd
        ld hl,(where)   ; HL = first address
        ld (hl),a       ; colour the first cell by hand
        ld de,(where)
        inc de          ; DE = the next address, HL+1
        ld bc,767       ; BC = the other 767 cells
        ldir            ; copy (HL) to (DE), HL+1, DE+1, BC-1, until BC = 0
```

This only works going *forwards* with HL behind DE. Swap them, or use `LDDR` the same way round, and each copy reads a cell before it has been coloured.

### Repeating a routine, and keeping a count on the stack

To time a fill properly we need hundreds of them. Each routine has an outer loop that runs the fill `times` times:

- The loop version counts with D, which is free: `ld d,a` before, `dec d` / `jr nz,frep` after.
- The `LDIR` version cannot do that, because `LDIR` uses BC, DE and HL, and the colour is in A. So the count goes on the stack with step 5's `push af` and comes back with `pop af` after the copy.

Both outer loops test with `dec` and `jr nz`, so a `times` of 0 is taken down to 255 by the first `dec` and goes round 256 times. 1 to 255 work as you would expect, and 0 means 256.

### Counting time: T-states and frames

The Z80 in a 48K Spectrum runs at 3.5 MHz: three and a half million *T-states* (clock ticks) a second. The Z80 manual gives the T-states for every instruction. A frame, one fiftieth of a second, is 69888 T-states on a 48K: 312 lines of the TV picture, 224 T-states each. That is the number we divide by to turn a count into frames.

The loop, one cell:

| Instruction | T-states |
|-------------|---------:|
| `ld (hl),e` | 7 |
| `inc hl` | 6 |
| `dec bc` | 6 |
| `ld a,b` | 4 |
| `or c` | 4 |
| `jr nz,floop` | 12 (7 the last time, when it does not jump) |
| **one cell** | **39** |

768 cells is 768×39−5 = 29947 T-states. Add the setup and the outer loop for each fill (`ld a,(colour)` 13, `ld e,a` 4, `ld hl,(where)` 16, `ld bc,768` 10, `dec d` 4, `jr nz,frep` 12, which is 59) and one fill is **30006 T-states**, 0.429 frames.

The `LDIR` version, one fill: `push af` 11, `ld a,(colour)` 13, `ld hl,(where)` 16, `ld (hl),a` 7, `ld de,(where)` 20, `inc de` 6, `ld bc,767` 10, the `LDIR` itself 767×21−5 = 16102, `pop af` 10, `dec a` 4, `jr nz,lrep` 12. One fill is **16211 T-states**, 0.232 frames.

So for 250 fills, the arithmetic says 7501500 T-states for the loop, **107.3 frames**, and 4052750 for `LDIR`, **58.0 frames**.

For comparison, step 2's BASIC took 325 frames for 768 `POKE`s. That is 325×69888/768, about **29600 T-states for each cell**. The loop takes 39 and `LDIR` 21.

### Contended memory, in outline

The screen is in ordinary RAM, at 16384 to 23295. The ULA, the Spectrum's other big chip, reads it fifty times a second to draw the picture. The RAM chips from 16384 to 32767 cannot serve the ULA and the Z80 at the same moment, and the ULA wins. So if the Z80 wants that memory while the ULA is drawing the screen, the Z80 is made to wait, by up to 6 T-states. This is called *contended memory*.

The rules, from the Sinclair Wiki's page "Contended memory":

- Only 16384 to 32767 is affected. Our code at 50000, and the memory at 60000, never wait.
- The Z80 only waits while the ULA is drawing the 192 lines of the screen itself. During the border at the top and the bottom, and at the ends of each line, there is no waiting. That is about a third of each frame when waiting can happen.
- The wait depends on exactly when the Z80 asks: 6, 5, 4, 3, 2, 1, 0 or 0 T-states, repeating every 8.

So the loop, which touches the screen once in 39 T-states (the write in `ld (hl),e`), should lose a little. `LDIR` should lose much more. For each byte, `LDIR` reads from the screen and writes to the screen. And on a 48K, the ULA can also hold it up in the seven T-states when `LDIR` is busy inside the Z80 with DE, a screen address, still on the address lines. That is nine chances to wait in every 21 T-states.

This matters for the timing in two ways. A count of T-states is only exact for code that does not touch 16384 to 32767. And the fastest-looking instruction is not always the fastest on the screen. The section "What it showed in Fuse" measures both.

## The listing

The machine code, `step7-attrfill.asm`:

```
; step7-attrfill.asm - Chapter 3, step 7
; The attribute fill in machine code: the twin of step 2's attribute fill.
; Two routines that do the same job, a loop and LDIR, called from BASIC.
;
; BASIC passes its choices in through three parameter bytes at the start:
;   50000  colour  the attribute byte to fill with (step 2 used 14)
;   50001  times   how many fills to do, 1 to 255 (0 means 256)
;   50002  where   two bytes, the first address to fill, low byte first
;                  (22528, the attributes; 768 bytes from here are filled)
;
; Entry points:
;   RANDOMIZE USR 50004  fill   the loop version
;   RANDOMIZE USR 50029  fldir  the LDIR version
;
; Registers in fill:
;   HL = the address being filled
;   BC = bytes still to fill, 768 down to 0
;   D  = fills still to do
;   E  = the colour
;   A  = a scratch copy of B, for the zero test
;
; Registers in fldir:
;   HL = the address LDIR copies from (one cell behind DE)
;   DE = the address LDIR copies to
;   BC = bytes still to copy, 767 down to 0
;   A  = the colour, then the count of fills (kept on the stack)
;
; Build:  pasmo --tap --name attrcode step7-attrfill.asm step7-attrcode.tap
; It is loaded by the driver, step7-attrfill.bas, with LOAD ""CODE.

        org 50000

colour: db 14           ; 50000: the colour, POKEd by BASIC
times:  db 1            ; 50001: how many fills
where:  dw 22528        ; 50002-50003: where to start

; The loop version: step 4's loop, with the colour and the start from BASIC.

fill:   ld a,(times)    ; A = how many fills
        ld d,a          ; D = fills still to do
frep:   ld a,(colour)   ; A = the colour BASIC POKEd
        ld e,a          ; E = the colour, because the loop needs A
        ld hl,(where)   ; HL = first address to fill
        ld bc,768       ; BC = 768 bytes to fill
floop:  ld (hl),e       ; colour one cell
        inc hl          ; next address
        dec bc          ; one fewer to do
        ld a,b
        or c            ; Z is set only when BC = 0
        jr nz,floop     ; not zero: next cell
        dec d           ; one fewer fill to do
        jr nz,frep      ; not zero: fill again
        ret

; The LDIR version: colour the first cell, then copy it along 767 times.

fldir:  ld a,(times)    ; A = how many fills
lrep:   push af         ; keep the count on the stack
        ld a,(colour)   ; A = the colour BASIC POKEd
        ld hl,(where)   ; HL = first address
        ld (hl),a       ; colour the first cell by hand
        ld de,(where)
        inc de          ; DE = the next address, HL+1
        ld bc,767       ; BC = the other 767 cells
        ldir            ; copy (HL) to (DE), HL+1, DE+1, BC-1, until BC = 0
        pop af          ; A = the count again
        dec a           ; one fewer fill to do
        jr nz,lrep      ; not zero: fill again
        ret

        end
```

pasmo's listing (`pasmo -d`) shows where everything landed. These are lines from it, with the addresses in hex:

```
C350:0E		DEFB of 1 bytes
C351:01		DEFB of 1 bytes
C352:0058	DEFW of 1 words
C354:		label fill
C354:3A51C3	LD A, (C351)
...
C362:		label floop
C362:73		LD (HL), E
...
C36D:		label fldir
C36D:3A51C3	LD A, (C351)
...
C380:EDB0	LDIR
...
C386:C9		RET
```

`$C350` is 50000, `$C354` is 50004, `$C36D` is 50029 and `$C386` is 50054. The whole thing is 55 bytes, 50000 to 50054. The two entry points, 50004 and 50029, are the numbers the BASIC uses. If you add an instruction to `fill`, `fldir` moves, and the BASIC must change to match: the listing is where to look.

The BASIC driver, `step7-attrfill.bas`:

```
1 REM N=fills in each timed run
2 REM H=FRAMES high byte
3 REM L=FRAMES low byte
4 REM F=frames since FRAMES was zeroed
5 REM A=frames for N loop fills, screen
6 REM B=frames for N LDIR fills, screen
7 REM C=frames for N loop fills, 60000
8 REM D=frames for N LDIR fills, 60000
10 CLEAR 49999
20 BORDER 0: PAPER 0: INK 7: CLS
30 PRINT "LOADING THE CODE"
40 LOAD ""CODE
50 LET N=250
60 CLS : PRINT "STEP 7: THE ATTRIBUTE FILL"
70 PRINT : PRINT "PRESS A KEY FOR EACH FILL": PAUSE 0
80 POKE 50000,14: POKE 50001,1: RANDOMIZE USR 50004: PAUSE 0
90 POKE 50000,48: RANDOMIZE USR 50029: PAUSE 0
100 POKE 50000,14: POKE 50001,N
110 GO SUB 800: RANDOMIZE USR 50004: GO SUB 900: LET A=F
120 GO SUB 800: RANDOMIZE USR 50029: GO SUB 900: LET B=F
130 POKE 50002,96: POKE 50003,234
140 GO SUB 800: RANDOMIZE USR 50004: GO SUB 900: LET C=F
150 GO SUB 800: RANDOMIZE USR 50029: GO SUB 900: LET D=F
160 POKE 50002,0: POKE 50003,88: POKE 50001,1
170 CLS : PRINT N;" FILLS OF 768 BYTES"
180 PRINT : PRINT "WHERE   HOW   FRAMES  ONE FILL"
190 PRINT "SCREEN  LOOP  ";A;TAB 22;A/N
200 PRINT "SCREEN  LDIR  ";B;TAB 22;B/N
210 PRINT "60000   LOOP  ";C;TAB 22;C/N
220 PRINT "60000   LDIR  ";D;TAB 22;D/N
230 PRINT : PRINT "STEP 2, BASIC: 325 FRAMES"
240 PRINT "LOOP IS ";INT (325*N/A+.5);" TIMES AS FAST"
250 PRINT "LDIR IS ";INT (325*N/B+.5);" TIMES AS FAST"
260 PAUSE 0
270 STOP
800 POKE 23672,0: POKE 23673,0: POKE 23674,0
810 RETURN
900 LET H=PEEK 23673: LET L=PEEK 23672
910 IF PEEK 23673<>H THEN GO TO 900
920 LET F=L+256*H
930 RETURN
```

Lines 800 to 930 are step 2's stopwatch, unchanged: zero `FRAMES`, then read it back safely.

## Side by side

Step 2's attribute fill was lines 70 to 110:

```
70 GO SUB 800
80 FOR A=22528 TO 23295
90 POKE A,14
100 NEXT A
110 GO SUB 900: LET C=F
```

| Job | Step 2's BASIC | Step 7's loop | Step 7's `LDIR` |
|-----|----------------|---------------|-----------------|
| The colour | `14`, written in line 90 | `POKE 50000,14`, read with `ld a,(colour)`, kept in E | the same, kept in A |
| Where to start | `22528` in line 80 | `ld hl,(where)` | `ld hl,(where)`, and `ld de,(where)` / `inc de` |
| How many | `TO 23295`: the loop works out the count from the last address | `ld bc,768`, counted down | `ld bc,767`, after one cell by hand |
| Write one cell | `POKE A,14` | `ld (hl),e` | `ld (hl),a` for the first; `ldir` for the rest |
| Next cell | `NEXT A` adds 1 to A | `inc hl` | inside `ldir` |
| Finished yet? | `NEXT A` compares A with 23295 | `dec bc` / `ld a,b` / `or c` / `jr nz,floop` | inside `ldir` |
| Time it | `GO SUB 800` ... `GO SUB 900`, round one fill | the same, round 250 fills | the same |
| Size | 3 lines, run by the interpreter | 6 instructions in the loop, 7 bytes | 1 instruction for 767 cells, 2 bytes |
| One fill | 325 frames | 0.448 frames | 0.304 frames |

The shape of the loop is the same in BASIC and in the first machine-code version: start, write, step on, check, go round. BASIC hides the address and the count inside `FOR` and `NEXT`; the machine code spells them out in HL and BC. `LDIR` is the first time the Z80 does more than BASIC in one step: the write, the step on, the count and the check, all in one instruction.

The other difference is the colour. Step 2 has 14 written into line 90. To change it, you edit the program. Step 7's code has no colour in it at all. BASIC decides, and pokes it in. That is what step 9 needs: BASIC asks the questions, and machine code does the filling.

## Building and running

On Windows, from the course folder:

```
windows-tools\pasmo\pasmo.exe --tap --name attrcode chapter-03-machine-code\step7-attrfill.asm chapter-03-machine-code\step7-attrcode.tap
windows-tools\zmakebas\zmakebas.exe -a 10 -n attrfill -o step7-driver.tap chapter-03-machine-code\step7-attrfill.bas
copy /b step7-driver.tap+chapter-03-machine-code\step7-attrcode.tap chapter-03-machine-code\step7-attrfill.tap
```

On Linux, the same commands without the folder and the `.exe`, and `cat step7-driver.tap chapter-03-machine-code/step7-attrcode.tap > chapter-03-machine-code/step7-attrfill.tap` for the last one.

To see where everything landed, add `-d` to the pasmo line and it prints the listing shown above.

Or let the build script do it, and open Fuse as well:

```
windows-tools\build.bat chapter-03-machine-code\step7-attrfill.bas chapter-03-machine-code\step7-attrfill.asm attrfill 10
```

On Linux:

```
tools/build.sh chapter-03-machine-code/step7-attrfill.bas chapter-03-machine-code/step7-attrfill.asm attrfill 10
```

The build scripts name the code on the tape after the file (`step7-attr`) instead of `attrcode`, and leave the two halves next to the source as `step7-attrfill-driver.tap` and `step7-attrfill-code.tap`. The code is the same, byte for byte.

When the tape has loaded, the program runs by itself. Press a key for the loop fill, a key for the `LDIR` fill, and a key to start the timing. The timing takes about seven seconds, with nothing to see: the screen is filled 500 times with the same blue, then 500 fills go to 60000, where you cannot see them. Then the table appears. Press a key to finish.

## What it showed in Fuse

The tape was loaded in a 48K Fuse.

`step7-attrfill.png` is the screen after the first key. The loop fill at line 80 has turned all 768 cells blue paper, yellow ink. The two lines of text that were printed in white on black are now yellow on blue: the fill changed the colours and left the pixels alone. `step7-attrfill-ldir.png` is after the second key: the `LDIR` fill with 48 has turned everything yellow paper, black ink. Both changes look instant.

`step7-attrfill-result.png` is the table. It was the same on three separate runs:

```
250 FILLS OF 768 BYTES

WHERE   HOW   FRAMES  ONE FILL
SCREEN  LOOP  112     0.448
SCREEN  LDIR  76      0.304
60000   LOOP  110     0.44
60000   LDIR  60      0.24

STEP 2, BASIC: 325 FRAMES
LOOP IS 725 TIMES AS FAST
LDIR IS 1069 TIMES AS FAST
```

### Against step 2

| Attribute fill, 768 bytes | Frames for one fill | Seconds | Times as fast as BASIC |
|---------------------------|--------------------:|--------:|-----------------------:|
| Step 2, BASIC `POKE` | 325 | 6.5 | 1 |
| Step 7, the loop | 0.448 | 0.009 | 725 |
| Step 7, `LDIR` | 0.304 | 0.006 | 1069 |

Step 4 measured its loop at about 0.5 frames, as 100 calls from BASIC minus 100 empty calls. That method had a lot of BASIC in it, and `ld (hl),48` is 3 T-states slower than `ld (hl),e`. Repeating the fill inside the machine code takes BASIC out of the measurement, apart from once at the start and once at the end.

### Against the arithmetic

| 250 fills | Counted, no waiting | Counted, with contended memory | Fuse |
|-----------|--------------------:|-------------------------------:|-----:|
| Loop, at 60000 | 107.3 | 107.3 | 110 |
| `LDIR`, at 60000 | 58.0 | 58.0 | 60 |
| Loop, on the screen | 107.3 | 109.0 | 112 |
| `LDIR`, on the screen | 58.0 | 73.4 | 76 |

The "with contended memory" column comes from `step7-contention.py`, a short Python script in this folder. It goes through the 250 fills one T-state at a time, adding the waits by the rules in "Contended memory, in outline" above. You do not need it to follow the lesson. It is there to show that the numbers add up.

What to notice:

- **At 60000, the count is right.** Nothing there is contended, and Fuse is 2 or 3 frames over the plain count. Those frames are not in the fills. They are the BASIC on either side of the call: `RETURN` from line 800, `RANDOMIZE USR`, and `GO SUB 900`, which all run after `FRAMES` was zeroed. And they are the ROM's interrupt routine, which runs 50 times a second to add one to `FRAMES` and read the keyboard, and takes its time out of ours. With `N` set to 1, every row read 1 or 2 frames, though one fill is under half a frame.
- **On the screen, the loop loses a little and `LDIR` a lot.** The loop went from 110 to 112 frames, `LDIR` from 60 to 76. The script predicts 1.7 and 15.4 frames of waiting; Fuse showed 2 and 16. The loop touches the screen once every 39 T-states. `LDIR` touches it nine times in every 21.
- **So `LDIR`'s lead shrinks on the screen.** In plain memory `LDIR` is 1.83 times as fast as the loop (110 against 60), close to the count's 30006/16211 = 1.85. On the screen it is only 1.47 times as fast (112 against 76). The instruction that copies fastest is the one that waits most for the ULA.
- **Machine code is predictable.** BASIC's 325 frames could only be measured. The machine code's time can be worked out in advance, to within a frame or two, with a table of T-states and the contention rules.

The bytes were checked with a second assembler: z80asm built `step7-attrfill.asm` to the same 55 bytes as pasmo's `--bin`.

## Line by line

The machine code, `step7-attrfill.asm`, by label:

- **Header.** What the three parameters are, the two entry points, what each register holds in each routine, and how to build it.
- **`colour`, `times`, `where`.** The parameter bytes at 50000 to 50003, with starting values 14, 1 and 22528.
- **`fill`, the first two lines.** Read how many fills BASIC wants, and keep the count in D.
- **`frep`.** The start of one fill. Read the colour into A, then copy it to E, because the loop uses A. Load HL with the start address from `where`, and BC with 768.
- **`floop`.** Step 4's loop: colour the cell at HL with E, step HL on, take one from BC, and go round until B and C are both zero.
- **`dec d` / `jr nz,frep`.** One fill done. If D is not zero yet, do another.
- **`ret`.** Back to BASIC.
- **`fldir`.** Read how many fills into A.
- **`lrep`.** `push af` puts the count on the stack, out of the way, because A is needed for the colour. Read the colour, colour the first cell by hand with `ld (hl),a`, point DE one cell further on, set BC to the other 767, and `ldir` copies the colour along.
- **`pop af` / `dec a` / `jr nz,lrep`.** Get the count back, take one off, and go again if it is not zero.
- **`ret`.** Back to BASIC.

The driver, `step7-attrfill.bas`:

- **1–8** name the variables.
- **10** moves `RAMTOP` to 49999, so the code can load at 50000. It comes first, because `CLEAR` wipes the variables.
- **20–40** set the colours, clear the screen, and load the code from the tape.
- **50** sets how many fills to time.
- **60–70** print the title and wait for a key.
- **80** pokes step 2's colour, 14, and asks for one fill, then calls the loop at 50004.
- **90** pokes 48, yellow paper and black ink, and calls the `LDIR` version at 50029. `times` is still 1 from line 80.
- **100** pokes 14 again, and N into `times`.
- **110–120** time N loop fills and N `LDIR` fills on the screen, with step 2's stopwatch: zero `FRAMES`, call, read `FRAMES`.
- **130** points `where` at 60000, plain memory above the code, low byte 96, high byte 234.
- **140–150** time the same two at 60000. Nothing on the screen changes.
- **160** puts `where` back to 22528 and `times` back to 1, so you can call the routines by hand afterwards.
- **170–220** clear the screen and print the four times, and the time for one fill.
- **230–250** set them beside step 2's 325 frames. `INT (...+.5)` rounds to the nearest whole number.
- **260–270** wait for a key, then stop.
- **800–930** step 2's stopwatch subroutines.

## Limitations you will notice

- **`where` must point somewhere safe.** The routines fill 768 bytes from `where`, whatever is there. 22528 is the attributes and 60000 is free memory above the code. Point it at 23000, and the fill runs on past 23295 into the printer buffer and the system variables, and the machine will probably crash.
- **768 bytes, every time.** The length is fixed in the code. To fill part of the screen, you would make the length a parameter too.
- **`times` goes up to 256.** It is one byte, and 0 means 256. For more, call the routine again.
- **One colour for the whole screen.** Both routines write the same byte everywhere. Patterns of colour need a different routine, or a block of colours to copy with `LDIR`.
- **The timing includes some BASIC.** Two or three frames of every measurement are the BASIC around the call and the interrupt routine. Over 250 fills that is 2 to 4 percent. For a single fill it would be most of the answer, which is why we repeat.
- **`LDIR` is not the fastest fill there is.** It does the most work in one instruction, but at 21 T-states a byte, and with the ULA in the way, there are quicker tricks: a row of `LDI`s, at 16 T-states each, with no repeat, or writing two bytes at a time with `PUSH`. They are longer and harder to read, and a later chapter will meet them when the speed matters.
- **The screen fill is still only the attributes.** The bitmap is eight times bigger, 6144 bytes. That is step 8.

## Try this

- Change `N` in line 50 to 100. The table showed **45, 31, 45 and 24** frames. Each is about 100/250 of the figure for 250, plus the same frame or two of BASIC.
- Make the screen flash. Change the 48 in line 90 to 184, which is 128 (`FLASH 1`) + 56 (white paper, black ink). After the second key the whole screen flashes, and the text swaps between black on white and white on black, about three times a second. One byte from BASIC changed what 768 cells do.
- Try 256 fills. Change line 50 to `LET N=256` and the end of line 100 to `POKE 50001,0`, because `POKE 50001,256` is out of range. The table showed **114, 77, 112 and 61**: a little more than for 250, so 0 really did mean 256.
- If you have Python, run `python3 step7-contention.py` in this folder. It prints the counted times for all four rows, with the waits on the screen and without them: 109.0, 107.3, 73.4 and 58.0 frames.
