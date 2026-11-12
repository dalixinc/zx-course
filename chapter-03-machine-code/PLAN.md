# Chapter 3 — Plan: Z80 machine code, the memory map, and the system variables

This is the plan for the chapter. All nine steps are written and tested, and the chapter wrap-up is in [summary.md](summary.md). We write and test the steps one at a time, in the same style as Chapter 2, and Dalix checks each one before it is merged.

The original course outline split the next work into two parts:

- **Part 3** — screen fills with `POKE` in BASIC, then an interactive fill in which the user picks an attribute and a bit pattern.
- **Part 4** — the same fills rewritten in Z80 machine code, so the speed jump is measured, not just claimed.

Those two parts are now one chapter. Chapter 3 starts with the memory map and the system variables, then `PEEK` / `POKE` fills in BASIC as the bridge from Chapters 1 and 2, then the same fills in Z80, with a timing comparison against numbers we already have. The Space Invaders-style game in BASIC is Chapter 4. Chapter 5 translates bat and ball, then Invaders, into machine code. The sprite engine is Chapter 6.

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

Each step is one short, tested piece of work, in the Chapter 2 manner. All nine are written.

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

### Step 7 — The attribute fill in machine code, timed (written)

- **Goal.** The twin of step 2's attribute fill. Step 4's loop, then `LDIR`, both timed with the same `FRAMES` method, and checked against a count of T-states.
- **New concepts.** Parameter bytes at the start of the code (`colour`, `times`, `where`), poked by BASIC and read with `LD A,(nn)` and `LD HL,(nn)` / `LD DE,(nn)`; `LD (HL),r`; `LDIR` (HL from, DE to, BC count; 21 T-states a byte, 16 for the last; flags; BC = 0 means 65536; interruptible), with `LDI`, `LDD` and `LDDR` named; filling by copying a block onto itself one byte along (HL one behind DE); a repeat count in D, or on the stack with `PUSH AF`; T-states, 3.5 MHz and 69888 T-states a frame; contended memory, in outline, from the Sinclair Wiki's rules. All 24 rows are filled, as in step 2.
- **Program.** `step7-attrfill.asm` (55 bytes at 50000, loaded with `LOAD ""CODE`; `fill` at 50004, `fldir` at 50029) and the driver `step7-attrfill.bas`: one visible fill of each kind, then 250 of each timed on the screen and 250 of each at 60000, set beside step 2's 325 frames. `step7-contention.py` counts the T-states with the contention delays.
- **Tested.** pasmo and z80asm give the same 55 bytes. Fuse, 48K, three runs, the same each time: 250 fills on the screen took 112 frames (loop) and 76 (`LDIR`); at 60000, 110 and 60. One fill: 0.448 and 0.304 frames, 725 and 1069 times as fast as step 2. The count without contention says 107.3 and 58.0; with contention, 109.0 and 73.4; Fuse is 2 to 3 frames over each, the BASIC around the call and the interrupt routine. Contention costs the loop 2 frames and `LDIR` 16, so on the screen `LDIR` is only 1.47 times as fast as the loop (1.83 in plain memory). Try-this checks: N=100 gave 45, 31, 45, 24; N=256 with `POKE 50001,0` gave 114, 77, 112, 61; colour 184 flashed; the ROM-to-screen `LDIR` example ran.

### Step 8 — The bitmap fill in machine code, timed (written)

- **Goal.** The twin of step 2's bitmap fill. Fill 16384 to 22527 with a pattern byte from BASIC, time it against step 2's 2468 frames and against a count of T-states, and show the screen layout, with a fill that goes down the screen in screen order.
- **New concepts.** `INC L` and `INC H`; `AND n`, `OR n`; `RET Z`, `RET NZ`, `RET C`; `HALT` (slowing a routine to one line a frame); two nested loops, 192 lines of 32 counted with `DJNZ`; the next-line-down routine `nxtdn`; the attribute address from a bitmap address; contended memory again, and a loop of 24 T-states (3 times 8) falling into step with the ULA. The "For info" aside, a blockquote in the lesson: the address bits `010TTRRR CCCXXXXX`, moving with `INC L` / `INC H`, crossing a character row and a third, `nxtdn`, the attribute address, and why the layout suits the hardware (the ULA reads a bitmap byte and its attribute in DRAM page mode, which needs them to share the row address, the low address lines; Chris Smith, "The ZX Spectrum Dynamic Memory Control", zxdesign.info, 2008) and the code (worded as a happy result, not a confirmed design aim). Step 2's lesson now uses the same letters.
- **Program.** `step8-bitmap.asm` (187 bytes at 50000, loaded with `LOAD ""CODE`; parameters `pattern`, `times`, `where`, `slow` at 50000–50004): `fill` (loop, 50005), `fldir` (`LDIR`, 50030), `rows` (192×32 in memory order, 50056), `sdown` (192×32 in screen order with `nxtdn`, 50085), `nxtdn` (50130), `attr` (50145), and test entries `tdown` 50155, `tattr` 50164, `tincl` 50173, `tinch` 50180. Drivers: `step8-bitmap.bas` (slowed `rows` and `sdown` to watch, the loop and `LDIR` once each, then 50 fills of each on the screen and at 32768, set beside step 2) and `step8-examples.bas` (every worked example of the aside, in hex, binary and decimal). `step8-contention.py` is an optional count with the contention delays.
- **Tested.** pasmo and z80asm give the same 187 bytes. Fuse, 48K, three runs, the same each time, 50 fills: on the screen, loop 178, `LDIR` 120, rows 136, down 126 frames; at 32768, 175, 95, 127, 126. One fill on the screen: 3.56, 2.4, 2.72, 2.52 frames, 693, 1028, 907 and 979 times as fast as step 2. Count without contention 171.5, 92.4, 124.8, 123.6; with contention 174.1, 117.1, 132.2, 123.7. `sdown` did not wait for the ULA at all. Slowed fills (2 `HALT`s a line): 384 frames each; `sdown` with 1: 192. Worked examples in Fuse: `INC L` 16384→16385, `INC H` 16384→16640, seven `INC H` →18176; `nxtdn` 16384→16640, 18176→16416, 18400→18432, 20448→20480; 191 lines down from 16384 is 22496, one more is 22528; `attr` 16384→22528, 16416→22560, 18432→22784, 18501→22853. Try-this checks: the letter A drawn with `POKE 16453+256*P`.

The aside as it was planned is now in the lesson, `step8-bitmap.md`, section "For info: why the screen is in thirds, and interleaved".

### Step 9 — The interactive fill, now fast (written)

- **Goal.** The twin of step 3. The step 3 program, with the machine-code fills underneath: pick an attribute and a bit pattern, see the screen change at once.
- **New concepts.** A BASIC front end around `USR` calls; perhaps two entry points (attributes, bitmap) or one routine with a parameter in BC.
- **Program.** The step 3 program, with its two fill subroutines replaced by `USR` calls to the routines from steps 7 and 8. BASIC asks the questions, machine code does the filling.
- **How we test.** Fuse: the same choices as in step 3, now quick enough to try several in a row. A `FRAMES` reading around each fill, set beside the step 3 figures.
- **As written.** `step9-fastfill.asm` (103 bytes at 50000, loaded with `LOAD ""CODE`; parameters `pattern`, `colour`, `times`, `slow` at 50000–50003): `bitmap` (50004) and `attrs` (50015) load A, HL and BC and share one `LDIR` routine, `ldfill`, which repeats `times` times with HL, BC and the count on the stack; `sdown` (50043), `wait` and `nxtdn` are step 8's, with `sdown` fixed at 16384. Driver `step9-fastfill.bas`: step 3's program with lines 40–110 replaced by three lines of `POKE` and `RANDOMIZE USR`, `CLEAR 49999` / `LOAD ""CODE` added, a new question for the fill order (0 memory order with `LDIR`, 1 screen order with `sdown`), and the table set beside step 3's 3699 and 489 frames. New concepts: one routine for two jobs with its inputs in registers, falling through, `LD D,H` / `LD E,L`, pushing and popping several values in order, a string `AND` a number in BASIC.
- **Tested.** pasmo and z80asm give the same 103 bytes. Fuse, 48K, full input runs typed one key at a time, with bad answers (ink 9, order 5, patterns `1100` and `11021100`) rejected and asked again. Three runs, the same each time: 50 bitmap fills 121 frames in memory order (2.42 a fill, 1529 times as fast as step 3) and 128 in screen order (2.56, 1445 times); 250 attribute fills 77 frames (0.308, 1588 times). A fourth run read 122 for memory order, a frame of jitter. With the fill subroutines moved to line 1000, the same figures. A five-line test with the same code gave 120, 76 and 126, exactly steps 7 and 8. Try-this checks: `sdown` with one `HALT` a line, 192 frames; 256 `LDIR` fills, 610 frames for the bitmap and 77 for the attributes; filling by hand with 255/22 and then 0.

## What this chapter will not do yet

An Invaders-style game in BASIC belongs in Chapter 4. A game loop with `HALT`, and the same games in machine code, belong in Chapter 5. Pixel-accurate sprites belong in Chapter 6. This chapter stops when we can place code safely, call it from BASIC, fill the screen quickly, and have measured the difference.

## Decisions

1. Original Parts 3 and 4 are folded into Chapter 3. Invaders in BASIC is Chapter 4, the same games in machine code are Chapter 5, and the sprite engine is Chapter 6.
2. Order: memory map and system variables first, then BASIC fills, then Z80.
3. There is a slow interactive fill in BASIC (step 3), and a fast one at the end (step 9).
4. pasmo is the course assembler throughout, using `--tapbas`.
5. Machine code starts at 50000, after `CLEAR 49999`. We may move it lower later if we need more space.

Chapter 3 is complete. The Chapter 4 plan is in [chapter-04-invaders-basic/PLAN.md](../chapter-04-invaders-basic/PLAN.md). Decisions for Chapter 4, and the questions carried forward to Chapter 5, are at the end of [summary.md](summary.md).
