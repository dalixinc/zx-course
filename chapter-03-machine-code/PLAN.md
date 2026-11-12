# Chapter 3 — Plan: Z80 machine code, the memory map, and the system variables

This is a plan, not a set of lessons. Nothing here is a listing to type in yet. The aim is for Dalix to read it, agree the shape (or change it), and then we write and test the steps one at a time, in the same style as Chapter 2.

The original course outline split the next work into two parts:

- **Part 3** — screen fills with `POKE` in BASIC, then an interactive fill in which the user picks an attribute and a bit pattern.
- **Part 4** — the same fills rewritten in Z80 machine code, so the speed jump is measured, not just claimed.

Dalix now calls the machine-code work Chapter 3. The proposal is to **fold Parts 3 and 4 into this one chapter**: start with `PEEK` / `POKE` fills in BASIC as the bridge from Chapters 1 and 2, then do the same fills in Z80, with a timing comparison against numbers we already have. The Space Invaders-style game and the sprite engine would then become Chapters 4 and 5. That numbering is marked as proposed in [OUTLINE.md](../OUTLINE.md), and is an open decision.

## What this chapter is for

Chapter 1 already showed the memory map in outline, and used `POKE` to fill the bitmap slowly enough to watch. Chapter 2 used `PEEK`, `POKE`, `USR "a"`, `BIN` and `DATA` for a UDG, and ran into the limits of interpreted BASIC: an empty `FOR I=1 TO 1000: NEXT I` took 5.32 seconds in Fuse; a BASIC poke of all 6144 bitmap bytes took 48.92 seconds; even with the delay removed, the bat-and-ball loop only managed about six steps a second. The figures and the method are in the [Chapter 2 wrap-up](../chapter-02-bat-and-ball/summary.md).

Chapter 3 should make those limits concrete, then cross them:

- Know the 48K memory map in enough detail to place a machine-code routine safely.
- Read and, where it is safe, write a few system variables.
- Write, load and call a first Z80 routine from BASIC (`USR`).
- Fill the attributes and the bitmap in machine code, and time them in Fuse against the BASIC fills above.
- Finish with an interactive fill that is fast enough to use.

## Proposed fold, for a decision

**Recommended order.** Teach the map and the system variables first, then a short run of BASIC `POKE` fills (a recap and an extension of Chapter 1, including a timed attribute fill and a first version of the interactive fill, which will be slow). Then introduce the Z80 from first principles, load a tiny routine, and repeat the fills in machine code, with timings. End on a fast interactive fill that uses the machine-code routine and a BASIC menu.

The other reasonable shapes, if this is wrong:

- Do the BASIC fills first (straight after Chapter 2) and only then open the map and the Z80. Slightly quicker to a visible fill; the map arrives later than we need it for `CLEAR` and `USR`.
- Skip a BASIC interactive fill and only make the fill interactive once the machine-code version is fast. Less repetition; you wait longer for the "pick a pattern" program.

The recommendation is the first of these: one slow interactive fill in BASIC is useful, because the later one can be compared with it, and the map has to come before we put code in RAM.

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

`CLEAR n` sets `RAMTOP` to `n` and forgets the BASIC variables. The usual way to reserve space for machine code is to `CLEAR` just below the address we intend to use (for example `CLEAR 49999` and put the routine at 50000), so that BASIC, its stack and its garbage collection stay below the code and cannot overwrite it. That is the convention this chapter should teach. The printer buffer is a historical 256-byte trick and is a poor place for anything we will want to grow.

`P RAMT` at 23732 is the last byte of physical RAM (65535 on a 48K). Worth a mention; we will not poke it.

### System variables worth a first look

Names are mnemonics from the manual. BASIC will not treat the names as variables; we use the addresses.

| Address | Name | Bytes | Why it is useful here |
|---------|------|------:|------------------------|
| 23560 | `LAST K` | 1 | The code of the key just pressed. A second way to watch the keyboard, beside `INKEY$`. |
| 23672 | `FRAMES` | 3, least significant first | Frame counter, incremented every 20 ms. The timer used for the Chapter 2 measurements. |
| 23675 | `UDG` | 2 | Address of UDG A. Already used, as `USR "a"`, in Chapter 2. |
| 23693 | `ATTR P` | 1 | The permanent attribute (paper, ink, bright, flash) as set by colour statements. In Fuse, after `PAPER 0: INK 7`, this was **7**, which is `8*paper+ink`. |
| 23670 | `SEED` | 2 | The seed for `RND`, set by `RANDOMIZE`. A short optional extra, tying back to step 5. |
| 23730 | `RAMTOP` | 2 | See the map above. Always peek it after a `CLEAR`. |

The manual marks some variables with X (poking them can crash the machine) or N (a poke has no lasting effect). The plan is to read all of the above, and to poke only where the manual says it is safe and we have a reason (`CLEAR` rather than a raw poke of `RAMTOP`; perhaps `FRAMES` only if a later lesson needs a known starting value).

## Tools

- **Fuse** (48K), as in Chapters 1 and 2, with `--speed 100` for timings. Fuse also has a built-in debugger, which we can use to single-step a routine and watch the registers, once there is a routine to look at.
- **zmakebas**, to build BASIC loaders and the early BASIC-only steps, as before.
- **pasmo** (0.5.3 is on this machine). This should be the assembler the lessons use: it can write a raw binary (`--bin`) or a tape, and `--tapbas` emits a TAP with a short BASIC loader around the code.
- **z80asm** is also installed, and can write a binary and a listing. Useful as a cross-check; not the default, because it does not build a TAP with a loader for us.

All programs are tested in Fuse before they are shown, as usual.

## Proposed steps

Each step is one short, tested piece of work, in the Chapter 2 manner. Titles are working titles.

### Step 1 — The memory map in detail

- **Goal.** Walk the 48K map from ROM to `RAMTOP` and the UDGs, and be able to say what lives at a given address.
- **New concepts.** The table above; `PROG`, `VARS`, `E LINE` and `STKEND` as pointers you can peek to see where BASIC has put things; `CLEAR` and `RAMTOP`; why the printer buffer is not our code area.
- **Program.** A short BASIC listing that prints `PROG`, `VARS`, `E LINE`, `STKEND`, `RAMTOP`, `UDG` and `P RAMT` (each as `PEEK n+256*PEEK (n+1)`), then `CLEAR 49999` and prints `RAMTOP` and `UDG` again so the move is visible.
- **How we test.** Run it in Fuse, 48K. Check the fresh-start values against the figures already peeked (`RAMTOP` 65367, `UDG` 65368) and check that after `CLEAR 49999`, `RAMTOP` is 49999.

### Step 2 — `PEEK`, `POKE`, and a few system variables

- **Goal.** Read `FRAMES`, `LAST K`, `UDG` and `ATTR P`, and believe the addresses by seeing them change.
- **New concepts.** The system variable table; two- and three-byte values, least significant byte first; which of these it is safe to poke.
- **Program.** A small demo: print `ATTR P` after a colour statement; print `UDG` and compare it with `USR "a"`; count 50 ticks of `FRAMES` (which should be one second, and can be checked against a wall clock at `--speed 100`); print `LAST K` in a short loop.
- **How we test.** Fuse, 48K. `ATTR P` after `PAPER 0: INK 7` should be 7. Fifty frames of `FRAMES` should be one second at `--speed 100`. Pressing a key should change `LAST K`.

### Step 3 — Screen fills in BASIC, timed

- **Goal.** Recap Chapter 1, then fill a character cell, a pixel row, the whole bitmap, and the attributes, and time the last two with `FRAMES`.
- **New concepts.** `POKE` into 16384–22527 and 22528–23295 as a deliberate fill, not a one-off; why a linear poke of the bitmap still paints in stripes (Chapter 1, revisited); using `FRAMES` as a stopwatch.
- **Program.** A listing that peeks `FRAMES`, fills 16384–22527, peeks again, then does the same for 22528–23295, and prints the frame counts. A second, shorter listing can fill one character cell and one pixel row first, so the build-up is visible.
- **How we test.** Fuse, 48K, `--speed 100`. Compare the times with the figures already measured for the same loops: 2446 frames (48.92 s) for the bitmap, 341 frames (6.82 s) for the attributes. They should be close, not necessarily identical (the exact surrounding BASIC will differ slightly).

### Step 4 — An interactive fill in BASIC

- **Goal.** The user picks an attribute and a bit pattern, and the program fills the screen with them. It will be slow; that is the point.
- **New concepts.** A tiny menu or prompted input (`INPUT`, or keys with `INKEY$`) for a paper/ink pair and a byte pattern (`BIN` or a small set of named patterns: solid, stripes, chequer).
- **Program.** BASIC only. Reuses the fill loops from step 3.
- **How we test.** Fuse: choose two different patterns and two attributes, and check the screen by eye. Time one fill if it is easy, so step 11 has a number to beat.

### Step 5 — The Z80 in small pieces, and a first routine

- **Goal.** Registers and flags from first principles, then one routine that returns a value to BASIC.
- **New concepts.** A, F, BC, DE, HL; the flags at a glance (in particular Z and C); `LD`, `RET`. On the Spectrum, `USR address` calls the routine and **the value that comes back to BASIC is the BC register pair**, not A. The brief idea "LD A / RET" therefore needs a last step that puts the result in BC (for example `LD B,0` / `LD C,A`, or simply `LD BC,nn` / `RET`) before `PRINT USR address` will show the number you expect.
- **Program.** Bytes loaded from `DATA` with `POKE`, starting at 50000, after `CLEAR 49999`. `PRINT USR 50000` should print a known number (for example 42).
- **How we test.** Fuse: the printed number is 42 (or whatever was loaded). A wrong return register would show some other value and is the thing to watch for. Optionally, open the Fuse debugger on the routine and confirm BC.

### Step 6 — Calling code: `CLEAR`, `DATA` / `POKE`, then an assembler

- **Goal.** The same "return 42" routine, first as hand-poked bytes (a recap of step 5), then as a source file assembled with pasmo, loaded from a tape that includes a BASIC loader.
- **New concepts.** Origin addresses (`ORG 50000`); `pasmo --tapbas` (and `--bin` if we want the raw bytes); how the loader does `CLEAR` and `RANDOMIZE USR` (or `PRINT USR`); a mention that z80asm can also assemble, but that pasmo is what we will use to make the tape.
- **Program.** A few lines of assembler, the TAP that pasmo writes, and a short note on the BASIC loader it emits.
- **How we test.** Assemble on this machine, load the TAP in Fuse, and get the same 42 as in step 5. If the loader's `CLEAR` is wrong, the machine will crash or the number will be wrong; that is a test, not a surprise.

### Step 7 — Fill the attributes with `LDIR`

- **Goal.** The first useful routine: set every attribute byte to a value in A (or a value passed from BASIC), using `LD HL,nn` / `LD DE,nn` / `LD BC,nn` / `LDIR`.
- **New concepts.** `LDIR` as a counted block copy (and why we seed the first byte, then copy 767 times); passing a colour from BASIC in BC (because of `USR`); contended memory, in outline, as the reason a cycle count will not match a wall clock exactly.
- **Program.** Assembler, `ORG 50000`, called with `RANDOMIZE USR 50000` after a `POKE` or a `USR` argument that holds the attribute. A BASIC typist-friendly `DATA` version can sit beside it for anyone not yet using pasmo.
- **How we test.** Fuse: the whole 32×24 grid changes colour, including the lower screen unless we choose not to fill the last two rows (a small design choice: 22 lines, or all 24). Time it with `FRAMES` around the `USR` call.

### Step 8 — Fill the bitmap in machine code, and compare timings

- **Goal.** Fill 16384–22527 in machine code, and put BASIC and machine-code times for both fills on the same page.
- **New concepts.** The same `LDIR` idea over 6144 bytes; optional: a patterned fill (a stored byte, or a short unrolled pattern) so this is not only a solid ink.
- **Program.** One tape that can run the BASIC fill and the machine-code fill, or two short programs with the same `FRAMES` stopwatch.
- **How we test.** Fuse, `--speed 100`, `FRAMES` as in Chapter 2. Report both times, and the ratio to 48.92 s and 6.82 s. Do not invent a cycle-count "should be" figure and treat it as a measurement; contended memory will make a calculated time optimistic. The Fuse number is the one that goes in the lesson.

### Step 9 — The interactive fill, now fast

- **Goal.** The step 4 idea, with the machine-code fills underneath: pick an attribute and a bit pattern, see the screen change at once.
- **New concepts.** A BASIC front end around `USR` calls; perhaps two entry points (attributes, bitmap) or one routine with a parameter in BC.
- **Program.** BASIC menu plus the routines from steps 7 and 8.
- **How we test.** Fuse: the same two patterns and attributes as step 4, now quick enough to try several in a row. A `FRAMES` reading around one fill, for the write-up.

## What this chapter will not do yet

Pixel-accurate sprites, a game loop with `HALT`, and an Invaders-style game belong in the following chapter (proposed Chapter 4). This chapter stops when we can place code safely, call it from BASIC, fill the screen quickly, and have measured the difference.

## Open decisions

1. Fold original Parts 3 and 4 into Chapter 3, and renumber the Invaders game and the sprite engine as Chapters 4 and 5?
2. Accept the recommended order (map and system variables, BASIC fills, then Z80), or prefer one of the alternatives above?
3. Include a slow interactive fill in BASIC (step 4), or only the fast one at the end?
4. Lead with pasmo (recommended, because of `--tapbas`), and treat z80asm as a second assembler we mention but do not require?
5. Default code address: `CLEAR 49999` / `ORG 50000` (recommended), unless a later step has a reason to move it?

Once these are agreed, the first lesson can be written and tested in Fuse in the usual way.
