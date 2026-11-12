# Chapter 4 — Plan: a Space Invaders-style game in BASIC

This is the plan for the chapter. There is no code yet. We will write and test the steps one at a time, in the same style as Chapter 2, and Dalix checks each one before it is merged.

Chapter 2 built a tiny bat-and-ball game in Sinclair BASIC, then stopped because the loop was too slow for anything more ambitious. Chapter 3 measured that slowness and crossed it with machine code, but only for screen fills. This chapter goes back to BASIC and builds a bigger game, a Space Invaders-style shooter, in small, playable steps. It will be slow. That is the point. Learners see how the game is put together, with the same lesson format as Chapter 2, and then Chapter 5 rebuilds it in machine code, in the same order, for a like-for-like comparison of speed and of how the programs are written.

Chapter 5 will start with a shorter warm-up: the Chapter 2 bat-and-ball game translated to machine code, which is the course's first real-time game loop. This chapter does not touch machine code.

## What this chapter is for

- Build a complete, playable Invaders-style game in pure Sinclair BASIC, one tested increment at a time.
- Reuse what Chapter 2 already taught (`PRINT AT`, `INKEY$`, UDGs, `ATTR`, `BEEP`, score and lives) and add the new ideas a formation-shooter needs: a firing step, a block of enemies, marching, bombs, and waves.
- Keep the game as responsive as BASIC will allow, using the line-search and variable-search findings from Chapter 3, so the slowness the learner feels is the real cost of the game logic, not an avoidable waste.
- Leave a clear list of the limits that Chapter 5's machine-code version will fix.

## The shape of the chapter

Eight steps, each one a small, tested, playable program, in the Chapter 2 rhythm. The player appears first, then a shot, then a still block of invaders, then the block marches, then shots hit, then the invaders fire back, then shields, then the scoring, lives, waves and sound that make it a game. The block is four rows of eight invaders (32), and they are animated with two frames, flipping each time the block steps. The fire key is Space.

Movement is by whole character cells, with UDGs. Sound is `BEEP`. The lesson format is the same as Chapter 2, including a `REM` line for every variable.

## Steps

Each step below gives the goal, the new keywords, a note on the program, and the limitation that the machine-code version in Chapter 5 will fix. Program names are provisional.

### Step 1 — The player's base

- **Goal.** A player base at the bottom of the screen, drawn as a UDG, that moves left and right with O and P and stops at the edges.
- **New keywords.** Several of these are a recap from Chapter 2, used together in a new game: `INKEY$`, `PRINT AT`, `CHR$`, `POKE USR "a"`, `BIN`, `DATA` / `READ` / `RESTORE`. The new work is a UDG for a base rather than a ball, and a single object that only moves when a key is held.
- **Program.** `step1-base`. A short loop: read O and P, rub out the base, step one column, reprint it. The status row stays clear. With only the base to draw, this step may feel brisk; a small delay can be added so the base is steerable, and taken out later if the loop has enough to do.
- **What machine code will fix.** The base can only move a whole cell at a time, and its speed is tied to how long the rest of the loop takes. In Chapter 5 the same control can be frame-synced with `HALT`, and, if we choose, a pixel at a time.

### Step 2 — One shot

- **Goal.** Fire one bullet up the screen from the base, with the fire key, only one bullet at a time. If a shot is already in flight, a further press does nothing until it has gone off the top (or, in later steps, hit something).
- **New keywords.** A second moving object, with its own row and column, and a flag (or a sentinel row) for "no bullet in flight". The fire key is Space. `INKEY$` returns `" "` (a single space) while Space is held, so the test is `K$=" "`. Because `INKEY$` reads only one key at a time, holding O or P and pressing Space together will usually give `""`: the player has to let go of a direction key to fire. That limit is worth showing honestly, and Chapter 5 fixes it by reading the keyboard ports with `IN`, which can see several keys at once.
- **Program.** `step2-shot`. The bullet can be a slim UDG or a simple character such as `'`. Each pass of the loop moves the base if a key is held, and moves the bullet up one row if it is live. The bullet should travel faster than the player feels they move, so it may step more than once per loop, or the base may only be allowed to step every other pass.
- **What machine code will fix.** In BASIC the bullet's speed is still whatever time is left in the loop. Once the invaders are in, both the base and the bullet will hitch. Machine code can update the bullet every frame without slowing the player, and could allow more than one shot at a time.

### Step 3 — A block of invaders

- **Goal.** A still block of invaders, drawn as UDGs from `DATA`, sitting above the player. The player can still move and fire. Shots will pass through the block until step 5.
- **New keywords.** `DIM` for a two-dimensional array that records which invaders are alive, and a string array (`DIM A$(4,17)`) holding each row ready to print; more than one UDG (`USR "a"`, `USR "b"`, `USR "c"` and so on) for the base and for one, two or three invader types; `FOR` / `NEXT` to draw the block from the array and the `DATA`.
- **Program.** `step3-block`. The block has a top-left column and row, a width and a height. Each cell of the array is set alive and printed at `base column + column index`, `base row + row index`. The block is four rows of eight invaders (32), held in `DIM V(4,8)`. There are three invader types, as in the arcade game: the top row is one type, the middle two rows a second, and the bottom row a third. Each invader takes two columns, the invader and a gap, so a row is 15 columns wide, and a blank row separates the rows, so the block is 7 rows deep. That leaves 17 columns of room to march across a 32-column screen. Each row is also kept as a string (see the speed section), so the block can be printed with four `PRINT AT`s rather than 32. Only the first frame of each type is shown in this step. A "Try this" can shrink the block to three rows of six (18) for a quicker loop.
- **What machine code will fix.** Printing a whole block with `PRINT AT` is already a hitch, and it will get worse as the block grows. Machine code can draw the same UDGs, or later pixel sprites, in a fraction of a frame.

### Step 4 — Marching the block

- **Goal.** The block marches sideways, and when any still-living invader would pass the left or right edge, the block steps down one row and reverses. Each step also flips the invaders between their two frames, so they walk as they march. If the block reaches the player's row, the game can end or simply stop, with a proper "game over" coming in step 8.
- **New keywords.** A direction variable for the block; edge tests against the leftmost and rightmost *living* invaders, not just the original rectangle, so a thin remnant can travel farther towards the side; a march timer, so the block does not try to move on every pass of the loop.
- **Program.** `step4-march`. The player and the shot stay responsive while the block steps every N passes. As invaders later die, N can shrink, which is the classic speeding up of a thinning wave. How the block is redrawn is in the speed section below: the block is reprinted a row at a time from the row strings, with a space at each end of the string so the trailing column is rubbed out as the leading one is drawn. There are two strings per row, one for each animation frame, so flipping the frame costs nothing extra: the loop prints the other string.
- **What machine code will fix.** In BASIC the march will be uneven, and a full reprint will make the player and the bullet stutter. Machine code can move the whole formation on a steady frame beat, and keep the player moving smoothly in between.

### Step 5 — Shot versus invader

- **Goal.** A bullet that reaches an invader kills it, rubs it out, clears it from the array, and removes the bullet. A wave that has been cleared can simply stop in this step; a new wave belongs in step 8.
- **New keywords.** Index arithmetic from a screen position back into the array (`column - block column`, `row - block row`). `ATTR` and `SCREEN$` are discussed here, then set aside for this job (see below).
- **Program.** `step5-hits`. On each bullet step, if the bullet's cell falls inside the block's current rectangle, the program looks up that array slot. If the invader is alive, it dies; if not, the bullet is in a hole and continues. Score can wait until step 8, or a simple running count of hits can be shown if it helps with testing.
- **Choosing how to detect a hit.** There are three realistic options, and the plan is to use the array as the source of truth.

  1. **`ATTR`, as in Chapter 2's bricks.** Cheap, and a good recap: if invaders share a paper or ink that nothing else uses, `ATTR` can say "an invader is in this cell". It cannot say *which* invader, and it is fooled if a bomb, a shield or the status line reuses that colour. To drop the right array entry you still have to convert the bullet's position into an index, so `ATTR` does not save the arithmetic.
  2. **`SCREEN$`.** Attractive, because it would read the character on the cell. On the Spectrum it is the wrong tool here. `SCREEN$` matches against the standard character set and does not return a user-defined graphic; a UDG cell comes back as an empty string. That limitation is worth a short note in the lesson, so learners do not chase it.
  3. **The array, with arithmetic.** The block already needs an array so that dead invaders are not marched or redrawn. The bullet's row and column minus the block's origin give the index directly, with a bounds check and a test that the slot is still alive. That is reliable over holes, over colour changes, and over later shields and bombs.

  The array is the pick. `ATTR` can be shown as a quick "is this cell even coloured?" experiment, then dropped, so the hit test does not depend on the palette.
- **What machine code will fix.** Walking this test in BASIC is fine for one bullet against a small block, but it still costs time on every bullet step. Machine code can test every frame, and can later test pixel overlap instead of whole cells.

### Step 6 — Invaders' bombs

- **Goal.** The invaders drop bombs towards the player. A bomb that hits the base costs a life, or, until step 8 adds lives, ends the run. The player can still shoot; a bullet and a bomb that meet can cancel each other if that is cheap to test.
- **New keywords.** `RND` / `RANDOMIZE` to pick a column (or a living invader) to drop from; a second falling object, or a very small number of them, with the same "only one in flight" rule as the player's shot if that keeps the loop lighter.
- **Program.** `step6-bombs`. A bomb should start from the lowest living invader in a chosen column, so it does not appear out of a hole. One bomb at a time is enough for this step; more than one can be a "Try this" if the loop can bear it.
- **What machine code will fix.** BASIC will only manage a few, slow bombs, and they will hitch with the rest of the loop. Machine code can drop more of them, update them every frame, and keep the player's motion independent.

### Step 7 — Shields

- **Goal.** Four shields sit between the player and the invaders, and are eaten away by bullets and bombs (and later, by invaders that march down onto them).
- **New keywords.** Block graphics or a small set of shield UDGs that can be replaced by a more damaged shape; the same array-or-character idea as the wall of bricks in Chapter 2, but with a few damage states rather than a single "on or off".
- **Program.** `step7-shields`. Each shield is three cells wide and two high: a top-left corner, a full block and a top-right corner on the top row, and a full block, an arch and a full block underneath. A hit swaps the cell for a damaged shape, then a badly damaged one, then a space. The shields should be cheap to test, so a hit looks up a small shield map (`DIM S(2,12)` for the 12 columns of four three-cell shields, holding each cell's damage level) rather than scanning the screen.
- **What machine code will fix.** In BASIC a shield can only erode by the character cell, or by a handful of pre-drawn damage frames. Machine code can nibble a shield a byte or a pixel at a time, which looks much closer to the arcade game.

### Step 8 — Score, lives, waves and sound

- **Goal.** Turn the program into a finished game: a score, a life count, a game-over screen, a new wave when the block is cleared (starting lower, or marching faster), and `BEEP` for a shot, a hit, a bomb, a lost life, and a short tune at the end, in the same spirit as Chapter 2. The two-frame animation is already in from step 4.
- **New keywords.** `GO SUB` / `RETURN` for a status line, as in Chapter 2; `BEEP`; `RUN` to start a new game from scratch.
- **Program.** `step8-game`. `BEEP` blocks the whole game while it plays, so the in-game notes stay very short, as they did in Chapter 2, and the longer tune waits until play has already stopped.
- **What machine code will fix.** `BEEP` will always freeze the action. Chapter 5 can click the speaker port without stalling the loop. Score and lives updates will also be invisible at machine-code speed, and a new wave can start on the next frame rather than after a visible pause.

## Keeping BASIC fast enough

The game will be slow. The job of this section is to stop it being slower than it has to be, using what Chapter 3 measured.

**Low line numbers for the main loop.** In Sinclair BASIC, `GO TO`, `GO SUB` and `NEXT` search for their target from the start of the program. Chapter 3's step 2 ran about 6% faster with the `REM` lines above the loop taken out, and step 3's fills went from 74 seconds to 101 when the same subroutines were moved from line 40 to line 1000. The main loop in this chapter should therefore live at low line numbers, with as few lines as possible above it. A useful pattern is a one-line jump at the top to an initialisation routine at a high line number, which defines the UDGs, fills the array and then jumps back to the loop. Subroutines, `DATA` and the end-of-game screens stay high.

**`REM` variable lines, but not above the loop.** The Chapter 2 lesson format, with a `REM` for every variable, stays. Those lines should sit at the end of the program, not at the top, so the search for the game loop does not walk through them on every pass. `REM` lines inside the tight loop should be kept rare.

**Few variables.** Chapter 3 also showed that each new variable makes a BASIC loop slower, because every lookup searches the variables area. Short names, no temporaries that are only used once if a direct expression will do, and no leftover variables from earlier experiments in the shipped listing.

**Do not redraw what has not moved.** The expensive thing in this game is `PRINT AT`. The base and the bullet are one cell each and can be rubbed out and reprinted as they move, as the ball and bat were in Chapter 2. The block of invaders is the danger. With 32 invaders, and holes that have to travel with the block, the middle of the block cannot simply be left alone. The answer is to keep each row as a string and print a whole row at once.

**Print a row as one string, not 32 cells.** Each row of the block is a 17-character string: a space, then eight pairs of an invader and a gap. The leading and trailing spaces rub out the column the row has just left, whichever way it is moving. When an invader dies, its character in the string becomes a space, so the hole travels with the block for free, and the array `V(4,8)` stays the record of who is alive. There are two strings per row, one per animation frame, and both are updated on a kill. A quick test in Fuse, with the same 4 rows of 8 UDGs, measured the two ways of drawing the block:

| Drawing the block of 32 | Frames per redraw | Seconds |
|---|---:|---:|
| Four `PRINT AT`s, one string per row | 5 | 0.10 |
| 32 `PRINT AT`s, one per living invader, from the array | 36.5 | 0.73 |

So a whole-block step with strings costs about a tenth of a second, which the player will feel as a short hitch, but not a stall. Printing invader by invader would freeze the base for three-quarters of a second on every march step, which is not playable. The array-and-cells form stays in the lesson as the obvious first idea, with these numbers, and then the strings replace it.

**Update one row per pass, if a whole-block step is too heavy.** If a tenth of a second still makes the player stutter, the loop can print one row of the block per pass and finish the step over four passes. The formation will ripple from the bottom row up rather than step as a unit, which is in fact what the arcade game does, and the base and the bullet stay steerable. This is a fallback to try in testing, not a requirement of the first draft of step 4.

**March on a timer, not on every pass.** The player should be read every time round the loop. The block should step only every N passes, and bombs less often than the player's bullet. N can fall as the wave thins, or on later waves.

**Time it.** As in Chapters 2 and 3, `FRAMES` is the stopwatch. Each step should record how long a pass of the loop takes, or how many frames a march step costs, so the Chapter 5 rewrite has numbers to beat, not just a feeling that BASIC was slow.

## The UDGs

The 48K Spectrum has 21 UDGs, A to U (`CHR$ 144` to `CHR$ 164`). The game needs 16, so there are five to spare. The letters are fixed here so that each step adds its own without renumbering the earlier ones.

| UDG | Code | Used for | First used |
|---|---:|---|---|
| A | 144 | the player's base | step 1 |
| B | 145 | the player's shot | step 2 |
| C | 146 | an invader's bomb | step 6 |
| D, E | 147, 148 | top-row invader, frames 1 and 2 | step 3 (frame 2 in step 4) |
| F, G | 149, 150 | middle-rows invader, frames 1 and 2 | step 3 (frame 2 in step 4) |
| H, I | 151, 152 | bottom-row invader, frames 1 and 2 | step 3 (frame 2 in step 4) |
| J | 153 | shield, full block | step 7 |
| K, L | 154, 155 | shield, top-left and top-right corners | step 7 |
| M | 156 | shield, the arch under the middle | step 7 |
| N, O | 157, 158 | shield, damaged and badly damaged | step 7 |
| P | 159 | an invader exploding | step 5 |
| Q to U | 160 to 164 | spare | |

The spares leave room for a "Try this" with a fourth invader type (one per row, two more UDGs), a two-frame bomb that wiggles as it falls, or a flying saucer. The count stays inside 19 as well, which matters only on a 128K machine in 128 BASIC, where T and U become the keywords `SPECTRUM` and `PLAY`. The course runs in 48K mode, where all 21 are there.

## What this chapter will not do yet

No machine code, no `HALT`, no pixel movement, no speaker-port clicks, and no joystick. Those belong in Chapter 5. No pre-shifted sprites or a generic sprite engine: those belong in Chapter 6. This chapter stops when the BASIC game is playable, timed, and honest about its limits.

## Decisions already made

1. Chapter 4 is Invaders in pure BASIC, built step by step like Chapter 2. Chapter 5 starts with bat and ball in machine code as a warm-up, then translates this Invaders game into machine code. Chapter 6 is the parameter-driven sprite engine, previously planned as Chapter 5.
2. Movement is by whole character cells, with UDGs.
3. The keys are O and P for left and right, as in Chapter 2, and Space to fire.
4. Sound is `BEEP`, as in Chapter 2, kept short while the game is running.
5. The lesson format is the same as Chapter 2, including a `REM` line for every variable. Those `REM` lines go at the end of the program, for the speed reasons above.
6. Hit detection uses a living/dead array and arithmetic from the bullet's position, not `ATTR` or `SCREEN$`.

7. Shields are in: step 7 stays, with four shields that erode in stages.
8. The invaders are animated with two frames per type, flipped each time the block steps, from step 4 on.
9. The block is four rows of eight invaders (32), with three types: one for the top row, one for the middle two, and one for the bottom row.

## Open questions for Dalix

None at the moment. Dalix answered the four that were here (the fire key, shields, animation, and how many invaders), and the answers are the decisions above.
