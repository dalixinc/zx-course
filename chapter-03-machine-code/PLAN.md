# Chapter 3 — Plan: Z80 machine code, the memory map, and the system variables

This is the plan for the chapter. Steps 1 to 6 are written and tested; the rest is still a plan. We write and test the steps one at a time, in the same style as Chapter 2, and Dalix checks each one before it is merged.

The original course outline split the next work into two parts:

- **Part 3** — screen fills with `POKE` in BASIC, then an interactive fill in which the user picks an attribute and a bit pattern.
- **Part 4** — the same fills rewritten in Z80 machine code, so the speed jump is measured, not just claimed.

Those two parts are now one chapter. Chapter 3 starts with the memory map and the system variables, then `PEEK` / `POKE` fills in BASIC as the bridge from Chapters 1 and 2, then the same fills in Z80, with a timing comparison against numbers we already have. The Space Invaders-style game is Chapter 4, and the sprite engine is Chapter 5.

## What this chapter is for

Chapter 1 already showed the memory map in outline, and used `POKE` to fill the bitmap slowly enough to watch. Chapter 2 used `PEEK`, `POKE`, `USR "a"`, `BIN` and `DATA` for a UDG, and ran into the limits of interpreted BASIC: an empty `FOR I=1 TO 1000: NEXT I` took 5.32 seconds in Fuse; a BASIC poke of all 6144 bitmap bytes took 48.92 seconds; even with the delay removed, the bat-and-ball loop only managed about six steps a second. The figures and the method are in the [Chapter 2 wrap-up](../chapter-02-bat-and-ball/summary.md).

Chapter 3 should make those limits concrete, then cross them:

- Know the 48K memory map in enough detail to place a machine-code routine safely.
- Read and, where it is safe, write a few system variables.
- Write, load and call a first Z80 routine from BASIC (`USR`).
- Fill the attributes and the bitmap in machine code, and time them in Fuse against the BASIC fills above.
- Finish with an interactive fill that is fast enough to use.

## The shape of the chapter

The agreed order is: the map and the system variables first, then a short run of BASIC `POKE` fills (a recap and an extension of Chapter 1, including a timed attribute fill and a first version of the interactive fill, which will be slow). Then introduce the Z80 from first principles, load a tiny routine, and repeat the fills in machine code, with timings. End on a fast interactive fill that uses the machine-code routine and a BASIC menu.

The map has to come before we put code in RAM. One slow interactive fill in BASIC is useful, because the later one can be compared with it.

## Addresses we will teach

These are the standard 48K figures, checked against Chapter 25 of the official ZX Spectrum BASIC manual (the text as published on World of Spectrum) and, for the three values it is easy to `PEEK`, against Fuse on a 48K machine after `PAPER 0: INK 7: CLS`.

### The map

| Addresses (decimal) | Hex | What |
|---------------------|-----|------|
| 0–16383 | `$0000–$3FFF` | ROM (BASIC and the operating system). Readable, not writable. |
| 16384–22527 | `$4000–$57FF` | Screen bitmap, 6144 bytes. |
| 22528–23295 | `$5800–$5AFF` | Attributes, 768 bytes (32×24). |
| 23296–23551 | `$5B00–$5BFF` | Printer buffer, 256 bytes. Sometimes used for a very short machine-code stub; not the place we will recommend for this chapter. |
| 23552–23733 | `$5C00–$5CB5` | System variables (official range in the manual). |
| 23734 upwards | `$5CB6`… | Channel information, the BASIC program, variables, the calculator stack, and spare RAM, growing up towards `RAMTOP`. |
| `RAMTOP` (system variable 23730) | | Address of the last byte of the BASIC system area. In Fuse, after a fresh 48K start, `PEEK 23730+256*PEEK 23731` was **65367**. |
| Just above `RAMTOP`, to 65535 | | The UDG area by default, then the end of RAM. In the same Fuse check, the `UDG` pointer (23675) was **65368**, which is `RAMTOP+1`. 21 characters of eight bytes use the rest of memory up to 65535. |

`CLEAR n` sets `RAMTOP` to `n` and forgets the BASIC variables. The usual way to reserve space for machine code is to `CLEAR` just below the address we intend to use (for example `CLEAR 49999` and put the routine at 50000), so that BASIC, its stack and its garbage collection stay below the code and cannot overwrite it. That is the convention this chapter should teach. We may move the origin lower later if a later chapter needs more space. The printer buffer is a historical 256-byte trick and is a poor place for anything we will want to grow.

`P RAMT` at 23732 is the last byte of physical RAM (65535 on a 48K). Worth a mention; we will not poke it.

### System variables worth a first look

Names are mnemonics from the manual. BASIC will not treat the names as variables; we use the addresses.

| Address | Name | Bytes | Why it is useful here |
|---------|------|------:|------------------------|
| 23560 | `LAST K` | 1 | The code of the key just pressed. A second way to watch the keyboard, beside `INKEY$`. |
| 23672 | `FRAMES` | 3, least significant first | Frame counter, incremented every 20 ms. The timer used for the Chapter 2 measurements. |
| 23675 | `UDG` | 2 | Address of UDG A. Already used, as `USR "a"`, in Chapter 2. |
| 23693 | `ATTR P` | 1 | The permanent attribute (paper, ink, bright, flash) as set by colour statements. In Fuse, after `PAPER 0: INK 7`, this was **7**, which is `8*paper+ink`. |
| 23670 | `SEED` | 2 | The seed for `RND`, set by `RANDOMIZE`. A short optional extra, tying back to Chapter 2 step 5. |
| 23730 | `RAMTOP` | 2 | See the map above. Always peek it after a `CLEAR`. |

The manual marks some variables with X (poking them can crash the machine) or N (a poke has no lasting effect). The plan is to read all of the above, and to poke only where the manual says it is safe and we have a reason (`CLEAR` rather than a raw poke of `RAMTOP`; perhaps `FRAMES` only if a later lesson needs a known starting value).

## Tools

- **Fuse** (48K), as in Chapters 1 and 2, with `--speed 100` for timings. Fuse also has a built-in debugger, which we can use to single-step a routine and watch the registers, once there is a routine to look at.
- **zmakebas**, to build BASIC loaders and the early BASIC-only steps, as before.
- **pasmo** is the assembler for the course, including later chapters. It can write a raw binary (`--bin`) or a tape, and `--tapbas` emits a TAP with a short BASIC loader around the code. That one-command tape is why we use it.

All programs are tested in Fuse before they are shown, as usual.

## Steps

Each step is one short, tested piece of work, in the Chapter 2 manner. Steps 1 to 6 are written; the titles of the others are working titles.

The first draft of this plan had nine steps. The memory map and the system variables turned out to fit in one program, so the first two planned steps became step 1, and everything after moved up by one. The list below is the chapter as it is being written.

From step 5 on, the machine-code steps mirror the BASIC steps, in the same order, so each BASIC program has a machine-code twin to set beside it, both for speed and for how the program is put together:

| BASIC step | Machine-code twin |
|------------|-------------------|
| 1. The memory map and the system variables | 6. The system variables, read from machine code |
| 2. Screen fills (attributes and bitmap), timed | 7. The attribute fill; 8. The bitmap fill |
| 3. The interactive fill | 9. The interactive fill, now fast |

Steps 4 and 5 are the bridge: step 4 hand-assembles a first routine, and step 5 brings in pasmo and the rest of the Z80 basics the later steps need.

### Step 1 — The memory map and the system variables (written)

- **Goal.** Walk the 48K map from ROM to `RAMTOP` and the UDGs, be able to say what lives at a given address, and read the main system variables live.
- **New concepts.** The table above; `PROG`, `VARS`, `E LINE` and `STKEND` as pointers you can peek to see where BASIC has put things; two- and three-byte values, least significant byte first; `CLEAR` and `RAMTOP`; why the printer buffer is not our code area.
- **Program.** `step1-memory-map.bas`: a memory map explorer that peeks seven system variables, draws the 64K as a bar, does `CLEAR 49999` and shows what moved, then shows `CHARS`, `ATTR P`, `BORDCR`, `LAST K` and `FRAMES` ticking.
- **Tested.** Fuse, 48K: `RAMTOP` 65367 before and 49999 after the `CLEAR`, `UDG` 65368 both times, `ATTR P` 7, and `FRAMES` going up 50 a second.

### Step 2 — Screen fills in BASIC, timed (written)

- **Goal.** Fill the whole bitmap and the attributes with `POKE`, and time both with `FRAMES`.
- **New concepts.** `FOR ... STEP`; poking a system variable (`FRAMES` as a stopwatch); why a linear poke of the bitmap paints in stripes.
- **Program.** `step2-fills.bas`.
- **Tested.** Fuse, 48K: 2468 frames (49.36 s) for the bitmap and 325 frames (6.5 s) for the attributes. These are the figures the machine-code fills have to beat.

### Step 3 — An interactive fill in BASIC (written)

- **Goal.** The user picks an ink, a paper, bright on or off, and a bit pattern, and the program fills the screen with them. It is slow; that is the point.
- **New concepts.** `INPUT` and `INPUT LINE`, `LEN`, `VAL`, picking one character out of a string; checking what the user typed before using it; the attribute byte and the pattern byte broken down bit by bit.
- **Program.** `step3-interactive-fill.bas`. The two fill loops are subroutines on their own, so a later step can swap each one for a `USR` call.
- **Tested.** Fuse: bad answers to the one-digit check and the pattern check, then a full fill with timings, then a second go with different choices. The fills took 3699 frames (bitmap) and 489 (attributes) on the first go, slower than step 2 because of the longer program and the extra variables.

### Step 4 — The Z80 in small pieces, and a first routine (written)

- **Goal.** What the processor does with bytes (fetch, decode, execute, the program counter), a few registers, and the first routines, hand-assembled and called from BASIC.
- **New concepts.** A, B, C, H, L and the pairs BC and HL; the zero flag (carry and DE are named, for later); decimal and hex, low byte first; `USR address`, which hands back BC, and `RANDOMIZE USR`; the instructions `LD rr,nn`, `LD r,n`, `LD r,r`, `LD (HL),n`, `INC HL`, `DEC BC`, `OR C`, `JR NZ,e` (and how the distance byte is worked out), `OUT (254),A` and `RET`; a checksum of the `DATA`; why a wrong byte can crash the machine.
- **Program.** `step4-first-routine.bas`: `CLEAR 49999`, then 27 bytes poked from `DATA` into 50000 to 50026 and checked against a sum of 2110. Three routines: `LD BC,42` / `RET` (`PRINT USR 50000` gives 42); a red border that hands back its colour (`USR 50004` gives 2); and an attribute fill with a `DEC BC` / `LD A,B` / `OR C` / `JR NZ` loop, timed as 100 calls minus 100 calls of a lone `RET`.
- **Tested.** Fuse, 48K, four runs: 42 and 2 printed, border red; 100 fills 96 frames, 100 empty calls 46 (once 47), so one fill is 0.5 frames, about 650 times as fast as step 2's 325. A mistyped byte gave `SUM IS 2109, NOT 2110` and stopped before any code ran. The bytes match pasmo's output for the same source, byte for byte.

### Step 5 — pasmo, and the Z80 basics (written)

- **Goal.** Stop counting bytes by hand. Assemble with pasmo, read its listing, and load its `--tapbas` tape. Meet the rest of the Z80 basics the later steps need, gently, one tiny example each.
- **New concepts.** Source files, labels, comments, `org`, `db`, `end`; `pasmo --tapbas`, `--tap`, `--bin`, `--name`, `-d` (the listing) and the symbol file; the loader pasmo writes (`CLEAR`, `POKE 23610,255`, `LOAD ""CODE`, `RANDOMIZE USR`); joining tapes (`cat` / `copy /b`). Registers A, F (Z and C only), B, C, D, E, H, L and the pairs BC, DE, HL; `LD` with registers, numbers, `(HL)` and `(nn)`; `ADD`, `SUB`, `INC`, `DEC`, `SCF`; `CP` with `JR` / `JP` on `Z`, `NZ`, `C`, `NC`; `DJNZ`; `CALL` / `RET`; `PUSH` / `POP`; `RLCA`, `RRCA`, `RLA`, `RRA`, `SLA`, `SRL`, with the bits and the carry shown in binary.
- **Program.** `step5-routines.asm`: step 4's three routines as source, built with `--tapbas`, the same 27 bytes. `step5-examples.asm`: sixteen tiny routines, example n at 50000+100*n, with a BASIC driver, `step5-examples.bas`, that calls each one and prints what came back.
- **Tested.** pasmo and z80asm give the same bytes for both files. In Fuse: the `--tapbas` tape turns the border red as it loads, `PRINT USR 50000` gives 42, `USR 50004` gives 2, `RANDOMIZE USR 50012` fills the screen yellow. The driver printed every expected result (listed in the lesson).

### Step 6 — The system variables, from machine code (written)

- **Goal.** The twin of step 1. Read the same system variables from machine code, print them with the ROM, and compare the output, the way the program is put together, and the time with a BASIC version.
- **New concepts.** `LD rr,(nn)` (HL, DE, BC) and `LD (nn),HL`; `LD A,(nn)` and `LD (nn),A`; `LD A,(DE)` and walking a table with `LD E,(HL)` / `INC HL`; `dw`; `RST 16`, channel 2 with `CALL 5633`, and the control codes for `AT`, `TAB` and `INVERSE` inside strings (ending in 255, because 0 appears in `AT 7,0`); `CALL` to the ROM (CLS at 3435); three ways to print a number: OUT-NUM-1 (6683, only up to 9999), STACK-BC + PRINT-FP (11563, 11747), and our own `pnum` by repeated subtraction; `SBC HL,DE`, `ADD HL,DE`, `AND A` to clear the carry. ROM addresses checked in Logan and O'Hara's *Complete Spectrum ROM Disassembly* (SkoolKit edition at speccy.xyz/rom) and against the bytes of the 48K ROM. IY left alone.
- **Program.** `step6-sysvars.asm` (`--tapbas`): step 1's screen after `CLEAR 49999`, with a table-driven loop for the seven two-byte variables, then `CHARS`, `ATTR P`, `BORDCR`, `FRAMES` and `LAST K`, timed with `FRAMES`, ENTER to return. `step6-basic.bas`: the same screen in BASIC, with step 1's statements, timed the same way. `step6-examples.asm` + `step6-examples.bas`: thirteen small examples, including timings of the two number printers and of CLS.
- **Tested.** pasmo and z80asm give the same bytes for both source files. Fuse, 48K: `PROG` 23755, `RAMTOP` 49999, `UDG` 65368, `P RAMT` 65535, `CHARS` 15360, `ATTR P` 7, `BORDCR` 7, `LAST K` 99 after `c`, all as in step 1; `VARS` 23826, `E LINE` 23827 (matching BASIC `PEEK`s afterwards), `STKEND` 23832, free 26167. The table took 12 frames in machine code (three runs) and 35 in BASIC: about three times as fast, because CLS (about 3 frames) and the ROM drawing characters take most of the time. 100 numbers: `pnum` 14 frames, PRINT-FP 49. OUT-NUM-1 printed 12345 as `<345` and 49999 as `0`.

### Step 7 — The attribute fill in machine code, timed

- **Goal.** The twin of step 2's attribute fill. Step 4's loop, then `LDIR`, both timed with the same `FRAMES` method.
- **New concepts.** `LDIR` as a counted block copy (seed the first byte, then copy 767 times, with HL one behind DE); passing the colour in from BASIC through the inbox byte (or in BC); contended memory, in outline, as the reason a cycle count will not match a wall clock exactly.
- **Program.** Assembler, `org 50000`, called with `RANDOMIZE USR` after a `POKE` of the colour.
- **How we test.** Fuse: the whole 32x24 grid changes colour (22 lines or all 24 is a small design choice). Time 100 calls minus 100 empty calls, as in step 4, for the loop and for `LDIR`, and set both beside step 2's 325 frames.

### Step 8 — The bitmap fill in machine code, timed

- **Goal.** The twin of step 2's bitmap fill. Fill 16384 to 22527 with a pattern byte, and put BASIC and machine-code times for both fills on the same page.
- **New concepts.** The same `LDIR` idea over 6144 bytes; a fill that walks the screen line by line using the address bits, which is where the aside below comes in.
- **Program.** A routine with the pattern byte passed from BASIC, and the `FRAMES` stopwatch.
- **How we test.** Fuse, normal speed, `FRAMES` as in Chapter 2. Report the time and the ratio to step 2's 2468 frames. Do not invent a cycle-count "should be" figure and treat it as a measurement; the Fuse number is the one that goes in the lesson.

#### For info (planned aside): why the screen is in thirds, and interleaved

A plain-text aside in the step 8 lesson, set off from the main text, for readers who want to know why the bitmap is laid out so strangely. It is not needed for the fill itself, which writes every byte and does not care about the order, but it is what makes drawing in machine code easy in Chapter 4.

**The address bits.** A bitmap address, written as its high byte and its low byte, is:

```
H = 0 1 0 T T R R R      L = C C C X X X X X
```

- `010` is fixed: it puts the bitmap at `$4000`–`$57FF`.
- `TT` is the third of the screen, 0 to 2.
- `RRR` is the pixel row inside the character cell, 0 to 7.
- `CCC` is the character row inside the third, 0 to 7.
- `XXXXX` is the column, 0 to 31.

So H holds the third and the pixel row, and L holds the character row and the column. (Step 2 wrote the same layout as `010TTLLL RRRCCCCC`, with different letters. When this aside is written, the two lessons should use the same letters; Dalix's letters above are the ones to keep.)

**Moving around with one instruction.**

- `INC L` moves one column to the right: `$4000` (16384) becomes `$4001` (16385).
- `INC H` moves down one pixel line inside the same character cell: `$4000` (16384) becomes `$4100` (16640). Seven `INC H`s from `$4000` reach `$4700` (18176), the bottom line of the top-left cell. That is the `STEP 256` loop from step 2, now one instruction per line.

**Crossing a character row.** From the bottom line of a cell, `INC H` does not go to the next cell down. `$4700` plus one in H is `$4800` (18432), which is the top of the middle third. To go from pixel row 7 of character row 0 to pixel row 0 of character row 1, take 7 off H (back to `RRR` = 0) and add 32 to L (one more `CCC`): `$4700` (18176) becomes `$4020` (16416). That is the address step 2's "Try this" used for the top line of row 1.

**Crossing a third.** At character row 7 of a third, L is `$E0` or more. Adding 32 to L overflows past 255, and the carry is the sign that we have left the third. Then H must go up by 8 instead (`TT` plus one, `RRR` back to 0): from the bottom line of row 7, `$47E0` (18400), the next line down is `$4800` (18432), the top of row 8.

The usual "next line down" routine puts these three cases together. The plan is to show it, and to test it in Fuse on the three worked addresses above:

```
        inc h           ; down one pixel line
        ld a,h
        and 7           ; still inside the same cell?
        ret nz          ; yes: done
        ld a,l
        add a,32        ; next character row
        ld l,a
        ret c           ; carry: crossed into the next third, H is already right
        ld a,h
        sub 8           ; same third: undo the carry into TT
        ld h,a
        ret
```

Worked through: `$4000` gives `$4100`; `$4700` gives `$4020`; `$47E0` gives `$4800`; `$4FE0` (20448) gives `$5000` (20480), the top of the bottom third.

**The attribute for a bitmap address.** The attribute address is `$5800 + 32*(character row on the whole screen) + column`. Its low byte is the same `CCCXXXXX` as the bitmap's low byte, and its high byte is `$58` plus `TT`. So from any bitmap address in HL, the attribute is three rotates and an `OR`:

```
        ld a,h
        rrca
        rrca
        rrca
        and 3           ; keep TT
        or $58
        ld h,a          ; HL is now the attribute address
```

Worked through: `$4000` (16384) gives `$5800` (22528); `$4020` (16416) gives `$5820` (22560); `$4800` (18432) gives `$5900` (22784).

**Why it is laid out like this.** For the code: the common moves are one-byte, four-cycle instructions. `INC L` goes across, `INC H` goes down a pixel line, and drawing an 8-line character or sprite column is eight `INC H`s with no 16-bit add. Only the move into the next character row or third costs more, and that happens once every eight lines. For the hardware: the ULA works out the screen address from its own line and column counters, and the layout lets those counter bits go straight onto the address lines, with no adding. It also means the bitmap byte and the attribute byte for a cell share the same low byte, and the ULA fetches both for each cell as it draws the line. The exact hardware reason (often given as a saving in the ULA's logic, and a good fit for the DRAM's row and column addressing) should be checked against a reliable source, such as Chris Smith's book on the ZX Spectrum ULA, before the lesson states it as fact.

### Step 9 — The interactive fill, now fast

- **Goal.** The twin of step 3. The step 3 program, with the machine-code fills underneath: pick an attribute and a bit pattern, see the screen change at once.
- **New concepts.** A BASIC front end around `USR` calls; perhaps two entry points (attributes, bitmap) or one routine with a parameter in BC.
- **Program.** The step 3 program, with its two fill subroutines replaced by `USR` calls to the routines from steps 7 and 8. BASIC asks the questions, machine code does the filling.
- **How we test.** Fuse: the same choices as in step 3, now quick enough to try several in a row. A `FRAMES` reading around each fill, set beside the step 3 figures.

## What this chapter will not do yet

Pixel-accurate sprites, a game loop with `HALT`, and an Invaders-style game belong in the following chapter (Chapter 4). This chapter stops when we can place code safely, call it from BASIC, fill the screen quickly, and have measured the difference.

## Decisions

1. Original Parts 3 and 4 are folded into Chapter 3. The Invaders-style game is Chapter 4, and the sprite engine is Chapter 5.
2. Order: memory map and system variables first, then BASIC fills, then Z80.
3. There is a slow interactive fill in BASIC (step 3), and a fast one at the end (step 9).
4. pasmo is the course assembler throughout, using `--tapbas`.
5. Machine code starts at 50000, after `CLEAR 49999`. We may move it lower later if we need more space.

The next lesson to write is step 7.
