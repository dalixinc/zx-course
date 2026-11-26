# Chapter 5 — Plan: the same games in machine code

This is the plan for the chapter. We write and test the steps one at a time, in the same style as Chapters 2 to 4, and Dalix checks each one before it is merged.

Chapter 2 built bat and ball in BASIC and stopped when BASIC was too slow for more. Chapter 3 showed what machine code can do, but only for screen fills. Chapter 4 built a whole Invaders game in BASIC, and measured how slow it is: an idle pass of 6.5 frames, and more than two seconds for each march step. This chapter rebuilds both games in Z80 machine code, in the same order as the BASIC steps, so each machine-code step can be set beside its BASIC twin, for speed and for how the program is put together.

## What this chapter is for

- Write the course's first real-time game loop in machine code: wait for the frame with `HALT`, read the keys, move things, test for collisions, draw.
- Rebuild the Chapter 2 game first, as a short warm-up, then the Chapter 4 game, step by step.
- Time each step against the BASIC figures in [Chapter 2's summary](../chapter-02-bat-and-ball/summary.md) and [Chapter 4's summary](../chapter-04-invaders-basic/summary.md), with `FRAMES` as the stopwatch, as before.
- Fix the list at the end of Chapter 4's summary: a loop in time with the picture, more than one key at a time, sound that does not stall the loop, a steady beat for the shot, bombs and march, and no visible pause between waves.

## Decisions for this chapter

Dalix asked Quintus to carry on and choose sensible defaults for the questions carried forward from Chapters 3 and 4. These are those defaults. Any of them can be changed, and the steps already written would then be revisited.

1. **Where the code lives.** At 50000, after `CLEAR 49999`, as in Chapter 3. That leaves about 15K, which should be plenty. The start can move lower if the Invaders game outgrows it.
2. **How much BASIC stays.** A small BASIC driver loads the code with `LOAD ""CODE`, sets any parameter bytes with `POKE`, calls the code with `RANDOMIZE USR`, and prints the timing when the code returns. The game loop itself is always machine code. In the early steps BASIC also prints the results; later steps move the score and the screens between games into machine code, so there is no visible pause.
3. **Building.** pasmo throughout. Each step is a driver and a code file, built with the two-file form of the build scripts (`driver.bas code.asm`), which uses `pasmo --tap` for the code. `pasmo --tapbas`, with its own loader, is still the right choice for a quick test of a single `.asm` file, as in Chapter 3.
4. **Movement.** By whole character cells first, as in Chapters 2 and 4, so each step is a like-for-like translation. Pixel movement comes later in the chapter, once the cell version of Invaders works (step 15 below), and leads into Chapter 6.
5. **The keys.** The same keys as before: O and P to move, in both games, and Space to fire in Invaders. Chapter 2 did not use Q and A, so neither does this chapter. From step 2 on, the keys are read with `IN` from the keyboard half-rows, so several keys can be down at once, unlike `INKEY$`.
6. **Kempston joystick.** A later, optional step (step 16), reading port 31. Fuse can emulate one.
7. **Sound.** Clicks on the speaker, bit 4 of port 254, written with `OUT (254),A` from the loop, so a sound never stalls the game the way `BEEP` does. The border bits of the same port are kept black.
8. **Interrupts.** Left as BASIC leaves them, in interrupt mode 1, so the ROM's routine keeps `FRAMES` counting and scans the keyboard 50 times a second. `HALT` waits for that interrupt, once a frame. IY is not touched, because the ROM's interrupt routine needs it.
9. **Lesson format.** As in Chapter 3's machine-code steps: an introduction; a subsection for each new instruction or idea (the syntax, the options, a tested example); the listing; the build commands for `windows-tools\build.bat` and `tools/build.sh`; what it showed in Fuse; line by line; the timing against BASIC; limitations; and "Try this". The source is commented on nearly every line. The BASIC driver keeps a `REM` for every variable.
10. **Parameter bytes.** Each program starts with a few bytes at 50000 that BASIC can `POKE` and `PEEK` (speed, counters, positions), as in Chapter 3, steps 7 to 9. The entry point follows them.

## Part A — Bat and ball in machine code (twins of Chapter 2)

### Step 1 — A bouncing ball (twin of Chapter 2, step 1)

- **Goal.** The ball moves diagonally one cell at a time, bounces off the four edges of rows 0 to 21, and is drawn just after a `HALT`, once every `speed` frames. Any key returns to BASIC, which prints the steps, the frames and the frames a step.
- **New.** The screen address of a character cell from its row and column (`010TT000 RRRCCCCC`, built with `AND`, `OR` and three `RRCA`s); drawing a cell by copying eight bytes into the screen with `INC H`; rubbing it out with eight zeros; `HALT` as the beat of a game loop; `ADD A,(HL)`; a step of -1 kept as 255, and `NEG`; one unsigned `CP` that catches both edges; `BIT` and `RES` on the `FLAGS` system variable to see a key press; `equ`.
- **Program.** `step1-ball.asm` and its driver `step1-ball.bas`.

### Step 2 — The bat, read with IN (twin of Chapter 2, step 2)

- **Goal.** A four-cell bat on row 21, moved with O and P. The ball bounces off it, and a miss puts the ball back at its start. Space returns to BASIC.
- **New.** `IN A,(254)` with a half-row in A; the eight half-rows and their bits; a 0 bit means the key is down; testing a bit with `AND` or `BIT`; holding O and P together, which `INKEY$` could not see; Space read the same way; the bat moving on its own beat, separate from the ball's.

### Step 3 — The bricks (twin of Chapter 2, step 3)

- **Goal.** Three rows of coloured bricks, drawn by filling attributes. The ball reads the attribute of the cell ahead, as `ATTR` did, rubs out a brick it hits, and bounces.
- **New.** The attribute address of a cell (`010110TT RRRCCCCC`); reading and writing the attribute byte; a brick wall drawn with a loop.

### Step 4 — A little randomness (twin of Chapter 2, step 5)

- **Goal.** The bounce off the middle of the bat or a brick sometimes sends the ball straight up, and a vertical rally is broken, as in Chapter 2.
- **New.** A small random-number routine; the `R` register, and why it is not random enough alone. Chapter 2's step 4, the user-defined ball, has no twin: the machine-code ball has been its own eight bytes since step 1.

### Step 5 — Speaker clicks (twin of Chapter 2, step 6)

- **Goal.** A click or a short buzz on the bat, a wall, a brick and a miss, while the ball keeps moving.
- **New.** Bit 4 of port 254; a pitch as a delay between flips of the speaker bit; keeping the border colour in bits 0 to 2.

### Step 6 — Score, lives and an ending (twin of Chapter 2, step 7)

- **Goal.** A score and lives on row 0, three lives, a game-over and a win.
- **New.** Printing a number from machine code (Chapter 3's `pnum` and `RST 16`); deciding which screens stay in BASIC.

A short wrap-up of Part A sets the bat-and-ball timings beside Chapter 2's.

## Part B — Invaders in machine code (twins of Chapter 4)

The eight steps of Chapter 4, in the same order. Each one times the same jobs as its twin, and the table in Chapter 4's summary is the one to beat.

| Step | Twin | Goal |
|-----:|------|------|
| 7 | Chapter 4, step 1 | The base, on row 21, with O and P. |
| 8 | Chapter 4, step 2 | One shot, fired with Space, while O or P is held. |
| 9 | Chapter 4, step 3 | The block of 4 rows of 8 invaders, from a table. |
| 10 | Chapter 4, step 4 | Marching, stepping down, two-frame animation, on a beat of a chosen number of frames. |
| 11 | Chapter 4, step 5 | Shot against invader, with the living table as the source of truth. |
| 12 | Chapter 4, step 6 | Bombs. |
| 13 | Chapter 4, step 7 | Four shields that erode. |
| 14 | Chapter 4, step 8 | Score, lives, waves and sound, with no visible pause between waves. |

The graphics are Chapter 4's UDGs, copied as bytes into the code, so the two games look the same.

## Later steps

- **Step 15 — Moving by pixels.** The base sideways by pixels, then the shot and the bombs by pixel lines, so the move from cells to pixels is seen on a game that already works. This leads into Chapter 6's pre-shifted sprites.
- **Step 16 — A Kempston joystick (optional).** Port 31, read beside the keys.

A wrap-up for the whole chapter sets every timing beside its BASIC twin.

## What this chapter will not do yet

No generic sprite engine, no masked sprites over a background, and no pre-shifted graphics. Those are Chapter 6.

## Open questions for Dalix

None that block the next steps. The decisions above are Quintus's defaults, and any of them can be changed.
