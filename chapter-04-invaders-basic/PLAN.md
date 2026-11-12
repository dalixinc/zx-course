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

Eight steps, each one a small, tested, playable program, in the Chapter 2 rhythm. The player appears first, then a shot, then a still block of invaders, then the block marches, then shots hit, then the invaders fire back, then shields if we include them, then the scoring, lives, waves and sound that make it a game. Two-frame animation of the invaders, if it is cheap enough, belongs in that last step, once the formation is already being redrawn.

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
- **New keywords.** A second moving object, with its own row and column, and a flag (or a sentinel row) for "no bullet in flight". The fire key itself is still to be decided (Space or M; see the open questions).
- **Program.** `step2-shot`. The bullet can be a slim UDG or a simple character such as `'`. Each pass of the loop moves the base if a key is held, and moves the bullet up one row if it is live. The bullet should travel faster than the player feels they move, so it may step more than once per loop, or the base may only be allowed to step every other pass.
- **What machine code will fix.** In BASIC the bullet's speed is still whatever time is left in the loop. Once the invaders are in, both the base and the bullet will hitch. Machine code can update the bullet every frame without slowing the player, and could allow more than one shot at a time.

### Step 3 — A block of invaders

- **Goal.** A still block of invaders, drawn as UDGs from `DATA`, sitting above the player. The player can still move and fire. Shots will pass through the block until step 5.
- **New keywords.** `DIM` for a two-dimensional array that records which invaders are alive; more than one UDG (`USR "a"`, `USR "b"`, `USR "c"` and so on) for the base and for one, two or three invader types; `FOR` / `NEXT` to draw the block from the array and the `DATA`.
- **Program.** `step3-block`. The block has a top-left column and row, a width and a height. Each cell of the array is set alive and printed at `base column + column index`, `base row + row index`. Different rows may use different invader UDGs. The number of invaders is an open question; a starting suggestion is three rows of six (18), which is small enough for BASIC to redraw without a long stall, with a "Try this" to grow it.
- **What machine code will fix.** Printing a whole block with `PRINT AT` is already a hitch, and it will get worse as the block grows. Machine code can draw the same UDGs, or later pixel sprites, in a fraction of a frame.

### Step 4 — Marching the block

- **Goal.** The block marches sideways, and when any still-living invader would pass the left or right edge, the block steps down one row and reverses. If the block reaches the player's row, the game can end or simply stop, with a proper "game over" coming in step 8.
- **New keywords.** A direction variable for the block; edge tests against the leftmost and rightmost *living* invaders, not just the original rectangle, so a thin remnant can travel farther towards the side; a march timer, so the block does not try to move on every pass of the loop.
- **Program.** `step4-march`. The player and the shot stay responsive while the block steps every N passes. As invaders later die, N can shrink, which is the classic speeding up of a thinning wave. How the block is redrawn is in the speed section below: prefer moving by rubbing out the trailing edge and drawing the leading one while the block is still solid, and fall back to a careful reprint once there are gaps.
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

### Step 7 — Shields (if we include them)

- **Goal.** If Dalix wants them, three or four shields sit between the player and the invaders, and are eaten away by bullets and bombs (and later, by invaders that march down onto them).
- **New keywords.** Block graphics or a small set of shield UDGs that can be replaced by a more damaged shape; the same array-or-character idea as the wall of bricks in Chapter 2, but with a few damage states rather than a single "on or off".
- **Program.** `step7-shields`. This step is optional. If the answer is no, the chapter goes straight from bombs to the end-of-game step, and the later numbering can skip this one. If yes, the shields should be cheap to test, so a hit looks up a small shield map rather than scanning the screen.
- **What machine code will fix.** In BASIC a shield can only erode by the character cell, or by a handful of pre-drawn damage frames. Machine code can nibble a shield a byte or a pixel at a time, which looks much closer to the arcade game.

### Step 8 — Score, lives, waves, sound, and animation if it is cheap

- **Goal.** Turn the program into a finished game: a score, a life count, a game-over screen, a new wave when the block is cleared (starting lower, or marching faster), and `BEEP` for a shot, a hit, a bomb, a lost life, and a short tune at the end, in the same spirit as Chapter 2. If a two-frame animation for the invaders is cheap, it goes in here as well: two UDGs per invader type, flipped each time the block steps.
- **New keywords.** `GO SUB` / `RETURN` for a status line, as in Chapter 2; `BEEP`; `RUN` to start a new game from scratch. Animation, if included, is only a second set of `DATA` bytes and a frame flag already being redrawn with the march.
- **Program.** `step8-game`. `BEEP` blocks the whole game while it plays, so the in-game notes stay very short, as they did in Chapter 2, and the longer tune waits until play has already stopped. Animation is cheap only if the step is already reprinting invaders as they march; if the step is still trying to move the block by edges alone, animation would force a reprint, and should be dropped.
- **What machine code will fix.** `BEEP` will always freeze the action. Chapter 5 can click the speaker port without stalling the loop. Score and lives updates will also be invisible at machine-code speed, and a new wave can start on the next frame rather than after a visible pause.

## Keeping BASIC fast enough

The game will be slow. The job of this section is to stop it being slower than it has to be, using what Chapter 3 measured.

**Low line numbers for the main loop.** In Sinclair BASIC, `GO TO`, `GO SUB` and `NEXT` search for their target from the start of the program. Chapter 3's step 2 ran about 6% faster with the `REM` lines above the loop taken out, and step 3's fills went from 74 seconds to 101 when the same subroutines were moved from line 40 to line 1000. The main loop in this chapter should therefore live at low line numbers, with as few lines as possible above it. A useful pattern is a one-line jump at the top to an initialisation routine at a high line number, which defines the UDGs, fills the array and then jumps back to the loop. Subroutines, `DATA` and the end-of-game screens stay high.

**`REM` variable lines, but not above the loop.** The Chapter 2 lesson format, with a `REM` for every variable, stays. Those lines should sit at the end of the program, not at the top, so the search for the game loop does not walk through them on every pass. `REM` lines inside the tight loop should be kept rare.

**Few variables.** Chapter 3 also showed that each new variable makes a BASIC loop slower, because every lookup searches the variables area. Short names, no temporaries that are only used once if a direct expression will do, and no leftover variables from earlier experiments in the shipped listing.

**Do not redraw what has not moved.** The expensive thing in this game is `PRINT AT`. The base and the bullet are one cell each and can be rubbed out and reprinted as they move, as the ball and bat were in Chapter 2. The block of invaders is the danger. While it is still a solid rectangle, a sideways step can rub out the trailing column and draw the leading one, and the middle can be left alone. Once there are holes, that is no longer enough: a hole has to travel with the block, so the characters in the middle must move too. At that point the honest options are to reprint the living invaders, or to reprint one row at a time.

**Update only a few invaders per pass, if a full reprint is too heavy.** If reprinting the whole block in one go makes the player stutter, the loop can move or redraw a few invaders at a time and finish the block over several passes. The formation will ripple rather than step as a unit, but the base and the bullet stay steerable. This is a fallback to try in testing, not a requirement of the first draft of step 4.

**March on a timer, not on every pass.** The player should be read every time round the loop. The block should step only every N passes, and bombs less often than the player's bullet. N can fall as the wave thins, or on later waves.

**Time it.** As in Chapters 2 and 3, `FRAMES` is the stopwatch. Each step should record how long a pass of the loop takes, or how many frames a march step costs, so the Chapter 5 rewrite has numbers to beat, not just a feeling that BASIC was slow.

## What this chapter will not do yet

No machine code, no `HALT`, no pixel movement, no speaker-port clicks, and no joystick. Those belong in Chapter 5. No pre-shifted sprites or a generic sprite engine: those belong in Chapter 6. This chapter stops when the BASIC game is playable, timed, and honest about its limits.

## Decisions already made

1. Chapter 4 is Invaders in pure BASIC, built step by step like Chapter 2. Chapter 5 starts with bat and ball in machine code as a warm-up, then translates this Invaders game into machine code. Chapter 6 is the parameter-driven sprite engine, previously planned as Chapter 5.
2. Movement is by whole character cells, with UDGs.
3. The keys are O and P for left and right, as in Chapter 2, plus a fire key.
4. Sound is `BEEP`, as in Chapter 2, kept short while the game is running.
5. The lesson format is the same as Chapter 2, including a `REM` line for every variable. Those `REM` lines go at the end of the program, for the speed reasons above.
6. Hit detection uses a living/dead array and arithmetic from the bullet's position, not `ATTR` or `SCREEN$`.

## Open questions for Dalix

Only four, and they can be answered as the early steps are tested; steps 1 to 3 do not depend on all of them.

1. **The fire key.** Space or M? Space is the obvious arcade key. M sits under the right hand, next to P.
2. **Shields.** Should step 7 be in the chapter, with three or four eroding bases between the player and the invaders, or should we go straight from bombs to score, lives and waves?
3. **Two-frame animation.** If reprinting the invaders as they march is already planned, should each type flip between two UDGs on each step, or stay on one frame?
4. **How many invaders.** Three rows of six (18) is the suggested start: three types, one per row, small enough to redraw in BASIC. Four rows of eight (32) is closer to the arcade game and may already be a struggle. Five rows of eleven (55) is almost certainly too many for a BASIC loop we still want to be steerable. A "Try this" can grow the block once the small one works.
