# Chapter 3 — What we learned about machine code, and how it compares with BASIC

Chapter 3 started where Chapter 2 stopped: BASIC was too slow for a game. It walked the 48K memory map, filled the screen from BASIC with `POKE` and timed it, then wrote the first Z80 machine code of the course and did the same jobs again, one tested step at a time. Steps 1 to 3 are BASIC. Steps 4 and 5 are the bridge: a first routine POKEd in by hand, then pasmo and the Z80 basics. Steps 6 to 9 are machine-code twins of steps 1 to 3, in the same order, so each BASIC program has a twin to set beside it. The listings and lessons are in this folder; this note wraps up what the chapter taught and the figures it measured.

Every figure below was measured in Fuse, on a 48K machine, at normal speed, with the frame counter `FRAMES` (system variable 23672, 50 counts a second), using the stopwatch from step 2: zero `FRAMES`, do the job, read `FRAMES` back, again if the high byte changed during the read. The figures are copied from the lessons, where the method for each one is set out.

## What we learned, step by step

| Step | Lesson | What it taught |
|-----:|--------|----------------|
| 1 | [The memory map and the system variables](step1-memory-map.md) | The 48K map from ROM to `RAMTOP` and the UDGs; `PEEK` and `POKE` of one- and two-byte values; `CLEAR` to move `RAMTOP`; the system variables `PROG`, `VARS`, `E LINE`, `STKEND`, `RAMTOP`, `UDG`, `P RAMT`, `CHARS`, `ATTR P`, `BORDCR`, `FRAMES` and `LAST K`. |
| 2 | [Screen fills in BASIC, timed](step2-fills.md) | `FOR ... STEP`; writing a system variable on purpose, with `FRAMES` as a stopwatch; why the bitmap fills in stripes; `REM` lines above a loop slow it down. |
| 3 | [An interactive fill in BASIC](step3-interactive-fill.md) | `INPUT` and `INPUT LINE`, `LEN`, `VAL`, taking characters out of a string, a number as a condition; the attribute byte and the pattern byte in binary; a bigger program and more variables make the same loop slower. |
| 4 | [The Z80 in small pieces, and a first routine](step4-first-routine.md) | Bytes in RAM as a program; `USR` and `RANDOMIZE USR`; `LD`, `INC`, `DEC`, `OR`, `JR NZ`, `OUT` and `RET`, hand-assembled; a checksum on the `DATA` before running it. |
| 5 | [pasmo, and the Z80 basics](step5-pasmo-and-z80.md) | The assembler, `org`, `db`, labels; loads to and from memory, `ADD`, `SUB`, `CP` and the flags, `DJNZ`, `CALL` and `RET`, `PUSH` and `POP`, the rotates and shifts. |
| 6 | [The system variables, from machine code](step6-sysvars.md) | `LD rr,(nn)` and `LD (nn),HL`, walking a table, printing through the ROM with `RST 16`, control codes as characters, 16-bit `ADD` and `SBC`, a number printer of our own. |
| 7 | [The attribute fill in machine code, timed](step7-attrfill.md) | Parameter bytes from BASIC; `LD (HL),r`; `LDIR`, and filling by copying a block onto itself one byte along; repeating a routine for the stopwatch; T-states and frames; contended memory. |
| 8 | [The bitmap fill in machine code, timed](step8-bitmap.md) | `INC L` and `INC H`, `AND n` and `OR n`, the conditional returns, `HALT`; two loops, one inside the other; the next-line-down routine; why the screen is in thirds, and interleaved; a loop of 24 T-states that never waits for the ULA. |
| 9 | [The interactive fill, now fast](step9-fastfill.md) | Step 3's program with machine code under it; one routine shared by two jobs, with its inputs in registers; `LD D,H` / `LD E,L`; keeping several values on the stack, in the right order. |

## BASIC against machine code, steps 1 to 9

Each row is one job, done in BASIC and in machine code. "Times as fast" is BASIC's frames divided by the machine code's.

| Job | BASIC | Frames | Machine code | Frames | Times as fast |
|-----|-------|-------:|--------------|-------:|--------------:|
| Clear the screen and print the system-variable table | step 6's BASIC twin of step 1 | 35 | step 6 | 12 | about 3 |
| Fill the 768 attributes | step 2 | 325 | step 4, a loop (100 calls, less 100 empty calls) | about 0.5 | about 650 |
| | | | step 7, a loop | 0.448 | 725 |
| | | | step 7, `LDIR` | 0.304 | 1069 |
| Fill the 6144 bitmap bytes | step 2 | 2468 | step 8, a loop | 3.56 | 693 |
| | | | step 8, 192 rows of 32 | 2.72 | 907 |
| | | | step 8, down the screen | 2.52 | 979 |
| | | | step 8, `LDIR` | 2.4 | 1028 |
| The interactive fill, bitmap | step 3 | 3699 | step 9, `LDIR` | 2.42 | 1529 |
| | | | step 9, down the screen | 2.56 | 1445 |
| The interactive fill, attributes | step 3 | 489 | step 9, `LDIR` | 0.308 | 1588 |

The machine-code figures for steps 7 to 9 are for one fill, worked out from 50 or 250 fills timed together, because one fill is too quick for `FRAMES` to see. Step 4's is one call from BASIC, with BASIC's own cost taken off.

A few more measurements from the lessons explain the table:

| What was measured | Figures | Step |
|-------------------|---------|-----:|
| Step 2's fills with its six `REM` lines taken out | bitmap 2322 frames instead of 2468; attributes 306 instead of 325 | 2 |
| Step 3's fills with the subroutines at line 1000 instead of line 40 | bitmap 5071 frames instead of 3699; attributes 659 instead of 489 | 3 |
| An attribute fill in BASIC, with sixteen extra variables made first | 461 frames instead of 308 | 3 |
| Calling machine code from BASIC, the call alone | about 0.46 frames a call | 4 |
| Printing 100 numbers: our own `pnum`, against the ROM's routine | 14 frames against 49 | 6 |
| 250 `LDIR` attribute fills, in plain memory at 60000 and on the screen | 60 frames against 76 | 7 |
| 50 bitmap fills on the screen and at 32768: `LDIR`; down the screen | 120 against 95; 126 against 126 | 8 |
| Step 9's fills with the subroutines at line 1000 instead of line 40 | 121, 77 and 128 frames, the same as at line 40 | 9 |

## The ideas the chapter is built on

**Where the time goes in BASIC.** A `POKE` itself is quick. What is slow is everything around it. Every `NEXT` searches the program from the top for the line to go back to, so `REM` lines above a loop slow it down, and so does a loop far down a long program. Every variable is found by searching the variables area, so more variables make it slower too. Every number is five-byte floating point. Step 3's interactive fill was half as slow again as step 2's, with the same loop, only because the program around it was bigger.

**Machine code does not search.** It runs from the address `USR` gives it, and keeps its values in registers. Step 9's fills took the same time wherever the BASIC that called them was. Its speed can even be worked out in advance: steps 7 and 8 counted T-states and matched Fuse to within a few frames.

**A call to the ROM is only as fast as the ROM.** Step 6 printed the same table as step 1 from machine code, and was only about three times as fast, because both versions spend most of their time in the same ROM routines, clearing the screen and drawing characters. The big gains came in steps 7 to 9, which write to screen memory directly.

**The screen is part of the story.** The ULA reads screen memory to draw the picture, and holds up the Z80 when both want it. That is contended memory. It slows `LDIR` on the screen by about a quarter, and a loop whose length is a multiple of 8 T-states can fall into step with the ULA and not wait at all. The bitmap's strange order, in thirds and interleaved, comes from the way the ULA fetches a bitmap byte and its attribute together; the same layout makes "one line down" a single `INC H` inside a character cell.

**Parameters, not edits.** From step 7 on, the machine code has no colour or pattern written into it. BASIC pokes the values into parameter bytes, and the code reads them. In step 9 the bytes are your answers. Inside the machine code, step 9 went one step further: a routine that takes its inputs in registers can do two jobs.

**BASIC and machine code share the work.** Step 9 is the shape the chapter was aiming for. BASIC does what happens once: the questions, the checks, the arithmetic, the breakdown, the table. Machine code does what happens thousands of times. Of step 3's 73 program lines, 61 were kept as they were; the eight lines that filled became three.

**Safe places for code.** `CLEAR 49999` moves `RAMTOP` below 50000, so BASIC, its stack and its variables stay out of the way. The machine stack sits just under `RAMTOP`.

## What machine code still has not done

The chapter filled the screen with one byte. It has not yet drawn anything at a chosen place, moved anything, read the keyboard from machine code, or run a loop in time with the picture. The fills are also called from BASIC, and the step 4 figures showed that once the code is fast, the call from BASIC is the slow part: about half a frame each time. A game loop has to stay in machine code. Chapter 4 stays in BASIC, so those jobs wait until Chapter 5.

## What comes next

Chapter 4 is a Space Invaders-style game in pure BASIC, built in the same small-step way as Chapter 2. It will be slow, and that is the point: learners see how the game is written, then Chapter 5 translates it into machine code. The plan is in [chapter-04-invaders-basic/PLAN.md](../chapter-04-invaders-basic/PLAN.md).

Chapter 5 starts with a warm-up, the Chapter 2 bat-and-ball game in machine code, which is the first real-time loop of the course (`HALT`, reading the keyboard, moving things, collisions). Then it rebuilds the Invaders game in machine code, in the same order as Chapter 4, so the two can be compared for speed and for how the programs are written. That chapter will reuse what this one built: `CLEAR 49999` and code at 50000, parameter bytes, `HALT` to wait for a frame, `nxtdn` and the screen-address arithmetic from step 8, and `FRAMES` to measure what we build.

Chapter 6 is the parameter-driven sprite engine, previously planned as Chapter 5.

Several of the questions this wrap-up first asked about Chapter 4 now have answers. The ones that still apply have been moved to Chapter 5.

## Decisions for Chapter 4

1. **How much BASIC stays.** Chapter 4 is BASIC throughout. The game loop in machine code belongs in Chapter 5.
2. **Movement.** Chapter 4 moves by whole character cells, with UDGs. Whether the machine-code version should move a pixel at a time is a question for Chapter 5.
3. **The keys.** O and P for left and right, as in Chapter 2, plus a fire key. Which fire key, and whether a Kempston joystick should be added later, are still open (the fire key in the Chapter 4 plan; the joystick under Chapter 5).
4. **Sound.** Chapter 4 uses `BEEP`, as Chapter 2 did. Short clicks on the speaker port are a question for Chapter 5.

## Open decisions for Chapter 5

These are for Dalix to decide before the machine-code games are written:

1. **How much BASIC stays.** A BASIC loader and menu around an all-machine-code game, or BASIC kept for the score and the screens between games, as step 9 kept it for the questions? The game loop itself has to be machine code.
2. **Movement by cells or by pixels.** Moving the player and the invaders a whole cell at a time, as Chapter 4 does, is the closest translation. Moving them a pixel at a time sideways is smoother, and leads into Chapter 6's pre-shifted sprites, but it is more work.
3. **Where the code goes.** 50000 after `CLEAR 49999` leaves about 15K, from 50000 up to the UDGs at 65368. That should be plenty, but if the game, its graphics and a row table grow, we could move the start lower, as decision 5 in the [plan](PLAN.md) allows.
4. **A Kempston joystick.** Whether to support one as well as the keys (Fuse can emulate it).
5. **Sound.** The ROM's `BEEP` stops everything while it plays. Short clicks written straight to the speaker port are the usual answer in a machine-code game, and would be new.

## Still open from Chapter 3

Steps 7 and 8 each have a short optional Python script that counts T-states with contended memory. Keep them, or take them out of the course and leave the figures in the lessons.
