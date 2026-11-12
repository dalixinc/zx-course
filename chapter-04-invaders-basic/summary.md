# Chapter 4 — What we learned by building Invaders in BASIC

Chapter 4 built a Space Invaders-style game in pure Sinclair BASIC, one tested step at a time: a base, a shot, a block of invaders, a march, hits, bombs, shields, and then a score, lives, waves and sound. The listings and lessons are in this folder; this note wraps up what the chapter taught, the figures it measured, what BASIC struggled with, and what Chapter 5's machine code has to fix. The shape of the chapter and the decisions already made are in [PLAN.md](PLAN.md).

Every figure below was measured in Fuse, on a 48K machine, at normal speed, with the frame counter `FRAMES` (system variable 23672, 50 counts a second) as the stopwatch. The figures are copied from the lessons, where the method for each one is set out.

## What we learned, step by step

| Step | Lesson | What it taught |
|-----:|--------|----------------|
| 1 | [The player's base](step1-base.md) | A UDG for the base, `PRINT AT` to put it on row 21, O and P to move it, and a tight loop at a low line number. |
| 2 | [One shot](step2-shot.md) | A second UDG, Space to fire, one shot at a time, rubbing the old cell out as it climbs, and the fact that `INKEY$` reads only one key. |
| 3 | [A block of invaders](step3-block.md) | Four rows of eight, three UDG types, a pair of arrays for who is alive and for the row strings, and why a row is printed as one string, not 32 cells. |
| 4 | [Marching the block](step4-march.md) | A two-frame walk, a ripple that draws one row per pass, living-edge scanning, a wait `W` between steps, and a down step at the edge. |
| 5 | [Shot versus invader](step5-hits.md) | An array hit test rather than `ATTR` or `SCREEN$`, a hole that travels with the string, an explosion UDG, a living-column march, and a clipped print so a remnant can leave the old rectangle. |
| 6 | [Invaders' bombs](step6-bombs.md) | A drop from the lowest living invader in a random column, a miss, a hit on the base, a cancel with the shot, and the "2 Variable not found" error when a variable is read before it is assigned. |
| 7 | [Shields](step7-shields.md) | Four shields, six UDGs, a damage map `S(2,12)` that coexists with the scalar march counter `S`, and a hit test by arithmetic from the shot or bomb position. |
| 8 | [Score, lives, waves and sound](step8-game.md) | Points per invader type, three lives and a respawn, a new wave that starts lower and a little faster, game over either way with `RUN` to play again, short `BEEP` notes, and invaders that erase shield cells and update the map. |

## How long the loop took, steps 3 to 8

Each row is the same job, retaken on that step's program, with no key and (from step 6 on) with drops disabled so a bomb in flight does not sit inside the count. An "official cycle" is the wait `W=8` plus one sideways ripple: 11 passes on waves that still use `W=8`.

| Step | One idle pass (frames) | One official cycle (frames) | Seconds a cycle |
|-----:|-----------------------:|----------------------------:|----------------:|
| 3 | 2.6 | — | — |
| 4 | 4.3 | 74 | 1.48 |
| 5 | 4.7 | 86 | 1.72 |
| 6 | 6.7 | 104 | 2.08 |
| 7 | 6.8 | 106 | 2.12 |
| 8, wave 1 | 6.5 | 106 | 2.12 |
| 8, wave 2 (`W=7`, 10 passes) | — | 102 | 2.04 |

The idle pass grew as the loop was asked to do more: the march timer in step 4, the hit test in step 5, the bomb and the drop timer in step 6, and the shield skip-tests in step 7. Step 8 added a score, lives and a wave number, which would usually make every variable lookup a little slower, but it also took out the `L=0` and `L<>3` guards that had been freezing the loop, and the idle pass was not slower than step 7. The official cycle on wave 1 stayed at 106 frames, the same as step 7. Wave 2 is a little faster, by one idle pass, and starts one row lower.

A few more measurements from the lessons fill in what a single pass does not show:

| What was measured | Figures | Step |
|-------------------|---------|-----:|
| A miss that travels 21 steps, block still | 9.7 frames a step, against 7.4 in step 4 | 5 |
| A hit on the bottom row, from row 20 | 10.3 frames a pass in step 5; 13.6 in step 6 with the bomb checks in the same stretch | 5, 6 |
| A bomb that starts on row 8 and leaves the bottom | 14 passes, 126 frames, 9.0 frames a step | 6 |
| A pass that moves a shot from row 20 onto a shield cell | 24 frames | 7 |
| One in-game `BEEP 0.02,18` | 1.2 frames (20 notes in 24 frames) | 8 |

These are the numbers for Chapter 5 to beat.

## The ideas the chapter is built on

**Low line numbers for the main loop.** `GO TO`, `GO SUB` and `NEXT` search for their target from the start of the program. The loop lives at line 20, with a one-line jump at the top to the set-up at line 900. Subroutines, `DATA`, the status line, the end-of-game screen and the `REM` variable lines stay high, so the search for the loop does not walk through them on every pass.

**Few variables, short names.** Every variable is found by searching the variables area, so each new one makes the loop a little slower. The programs reuse `P`, `B`, `Q`, `A`, `R` and `K` in the hit tests rather than inventing a fresh name for each job.

**Do not redraw what has not moved.** The expensive thing is `PRINT AT`. The base and the shot are one cell each and are rubbed out and reprinted as they move. Each invader row is a 17-character string, printed in one go, with a leading and trailing space that rubs out the column the row has just left. When an invader dies, its character in both frame strings becomes a space, so the hole travels with the block for free.

**The arrays are the map.** `V(4,8)` is who is alive, `S(2,12)` is the shield damage. Hit tests use arithmetic from a row and a column, not `ATTR` or `SCREEN$`. A scalar `S` (the march ripple) and the array `S()` coexist, so the two jobs can share a letter.

**A game loop, and `RUN` to leave it.** After the set-up the program reads the keys, moves the base, the shot, the bombs and the block, and goes back to the start of the loop. Game over and `RUN` are the way out. `RUN` forgets the score, the lives and the wave; `GO TO` would not have.

**Sound is a blocking `BEEP`.** The in-game notes are 0.02 seconds, which still costs 1.2 frames, and the longer tune waits until play has already stopped. That is the same choice Chapter 2 made, and it is as far as `BEEP` can reasonably go.

## What BASIC struggled with

The game is playable, and that was the point of the chapter, but the seams show.

The loop is slow. An idle pass is 6.5 frames, so the keys are read about seven or eight times a second, not once a frame. A sideways step of the full block takes more than two seconds. A shot that climbs the screen is in the air for seconds, not a fraction of one. The player can steer in the gaps, but the beat is not the 50 frames a second of the television picture.

`INKEY$` reads one key at a time. You cannot hold O or P and press Space in the same pass; one of the two is ignored. Caps Shift and Space is Break, so a player who reaches for what feels like a fire key on a modern keyboard can drop out of the program.

`BEEP` freezes the action. A 0.02-second note is short enough to use, but it is still a hitch, and a longer note is obvious. There is no way in BASIC to click the speaker and then go on with the loop.

A new wave is a visible pause: the screen is cleared, the strings are rebuilt, and the shields are redrawn, all in BASIC, before the next pass of the loop. The score and the lives are reprinted with `PRINT AT`, and you can see them update.

The graphics move by whole character cells. The shields erode in three pre-drawn stages, not a pixel at a time. A remnant of the block can travel past the original rectangle only because the print is clipped; that was a BASIC pitfall, not a game feature, and it had to be found in the emulator.

Sinclair BASIC also has smaller traps that the lessons recorded as they came up: an unassigned variable is the error `2 Variable not found`, not a quiet 0; a `PRINT AT` off the screen is an error, so a remnant that marched past column 0 had to be clipped; `GO SUB` searches from the start of the program, so a drop routine that was called on every pass, even when it then returned at once, made the idle loop slower until a counter was put in front of it.

## What Chapter 5's machine code must fix

Chapter 5 rebuilds the same game in machine code, in the same order, so the two versions can be compared. These are the things the BASIC game cannot do, and that the machine-code game should:

1. **A loop in time with the picture.** The game loop has to run in machine code, once a frame, with `HALT` (or an equivalent wait for the ULA), not in 6.5-frame BASIC passes.
2. **More than one key at a time.** The keyboard should be read as a port, so O or P can be held and Space pressed together. Caps Shift and Space must not Break the program.
3. **Sound that does not stall the loop.** Short clicks written to the speaker port, not the ROM's `BEEP`.
4. **A shot, a bomb and a march that keep a steady beat.** A shot should be able to fly in a fraction of a second, and the block should step at a chosen number of frames, not at two seconds a cell.
5. **Score, lives and a new wave with no visible pause.** Updating a number or starting the next wave should be done between frames, not after a `CLS` and a BASIC rebuild.
6. **Finer graphics, if the chapter decides to go that way.** Shields that nibble a byte or a pixel at a time, and movement by pixels rather than by cells, were already listed as Chapter 5 questions in the Chapter 3 wrap-up.

The open decisions for Chapter 5, including how much BASIC stays around the game, whether movement is by cells or by pixels, where the code lives, a Kempston joystick, and the speaker-port clicks, are still the ones in [Chapter 3's summary](../chapter-03-machine-code/summary.md).

## What comes next

Chapter 5 starts with a warm-up, the Chapter 2 bat-and-ball game in machine code, which is the first real-time loop of the course. Then it rebuilds this Invaders game in machine code, in the same order as the eight steps above, and times the same jobs again.
