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
7. **Sound.** Clicks on the speaker, bit 4 of port 254, written with `OUT (254),A` from the loop. A note still holds the loop while it plays, as `BEEP` does, so each is kept short enough to end before the next frame, and the border bits of the same port are kept as BORDCR has them.
8. **Interrupts.** Left as BASIC leaves them, in interrupt mode 1, so the ROM's routine keeps `FRAMES` counting and scans the keyboard 50 times a second. `HALT` waits for that interrupt, once a frame. IY is not touched, because the ROM's interrupt routine needs it.
9. **Lesson format.** As in Chapter 3's machine-code steps: an introduction; a subsection for each new instruction or idea (the syntax, the options, a tested example); the listing; the build commands for `windows-tools\build.bat` and `tools/build.sh`; what it showed in Fuse; line by line; the timing against BASIC; limitations; and "Try this". The source is commented on nearly every line. The BASIC driver keeps a `REM` for every variable.
10. **Parameter bytes.** Each program starts with a few bytes at 50000 that BASIC can `POKE` and `PEEK` (speed, counters, positions), as in Chapter 3, steps 7 to 9. The entry point follows them.

## Part A — Bat and ball in machine code (twins of Chapter 2)

### Step 1 — A bouncing ball (twin of Chapter 2, step 1)

- **Goal.** The ball moves diagonally one cell at a time, bounces off the four edges of rows 0 to 21, and is drawn just after a `HALT`, once every `speed` frames. Any key returns to BASIC, which prints the steps, the frames and the frames a step.
- **New.** The screen address of a character cell from its row and column (`010TT000 RRRCCCCC`, built with `AND`, `OR` and three `RRCA`s); drawing a cell by copying eight bytes into the screen with `INC H`; rubbing it out with eight zeros; `HALT` as the beat of a game loop; `ADD A,(HL)`; a step of -1 kept as 255, and `NEG`; one unsigned `CP` that catches both edges; `BIT` and `RES` on the `FLAGS` system variable to see a key press; `equ`.
- **As written.** `step1-ball.asm`, 156 bytes at 50000, with parameters `speed`, `steps`, `row`, `col`, `dr`, `dc` at 50000 to 50006 and the entry point at 50007; driver `step1-ball.bas`; examples `step1-examples.asm` + `step1-examples.bas`.
- **Tested.** In Fuse, `speed` 2 gave exactly 2 frames a step (532 steps in 1064 frames), `speed` 1 gave 515 in 516, `speed` 7 gave 94 in 658. With no `HALT` a step took 0.0166 of a frame, about 1160 T-states. Chapter 2's ball, timed the same way, took 7.0 frames a step with `PAUSE 5` and 2.4 without it, about 146 times as long as the machine code.

### Step 2 — The bat, read with IN (twin of Chapter 2, step 2)

- **Goal.** A four-cell bat on row 21, moved with O and P. The ball bounces off it, and a miss puts the ball back at its start. Space returns to BASIC.
- **New.** `IN A,(254)` with a half-row in A; the eight half-rows and their bits; a 0 bit means the key is down; `CPL`; `BIT b,r`; `INC (HL)`, `DEC (HL)`, `SUB (HL)`; `XOR A`; `equ` sums; a row and column loaded as a pair with `LD BC,(nn)`; `JP` as the last call; holding O and P together, which `INKEY$` could not see; Space read the same way; the bat and the ball on their own beats, counted down once a frame.
- **As written.** `step2-bat.asm`, 341 bytes, parameters at 50000 to 50013 (`halts`, `speed`, `bspeed`, `steps`, `hits`, `misses`, `col`, `row`, `dc`, `dr`, `bat`, `btime`, `ptime`), entry point 50014; driver `step2-bat.bas`; examples `step2-examples.asm` + `step2-examples.bas`, which show all eight half-rows and `INKEY$` side by side.
- **Tested.** O and P held together: `IN` saw both (`11100`), `INKEY$` gave `""`, and the bat stayed put. P and Space together: both seen, and the game stopped. A pass with no `HALT` took 0.0192 of a frame; Chapter 2, step 2 took 4.1 frames a pass without its delay and 35.2 with it.

### Step 3 — The bricks (twin of Chapter 2, step 3)

- **Goal.** Three rows of coloured bricks, drawn by filling attributes. The ball reads the attribute of the cell ahead, as `ATTR` did, rubs out a brick it hits, and bounces. The ends of the bat steer the ball, as in Chapter 2, step 3.
- **New.** The attribute address of a cell (`010110TT RRRCCCCC`); reading and writing the attribute byte, with `AND 56` for the paper; a brick wall drawn with a loop; `LD (nn),BC`; looking at the cell ahead before moving, and going round again after a brick; steering from the place on the bat.
- **As written.** `step3-bricks.asm`, 429 bytes, step 2's parameters with `kills` added at 50007 (the rest move up one), entry point 50015; driver `step3-bricks.bas`; examples `step3-examples.asm` + `step3-examples.bas`, which set the code's attribute addresses and bytes beside `ATTR`.
- **Tested.** Wall drawn at once; bricks rubbed out and counted; the left and right ends of the bat steer. A pass with no `HALT` took 0.0216 of a frame; Chapter 2, step 3 took 5.5 frames a step without its delay and 43.5 with it.

### Step 4 — A little randomness (twin of Chapter 2, step 5)

- **Goal.** The bounce off the middle of the bat or a brick sometimes sends the ball straight up or down (about 1 in 5), and a ball already going straight is always sent to one side, as in Chapter 2.
- **New.** Three sources of random numbers compared honestly: the R register (`LD A,R`, a counter), `FRAMES` (a clock) and an 8-bit LFSR on a seed (`SRL A`, `JR NC`, `XOR n`); `CP n` as a chance; `AND 1` / `ADD A,A` / `DEC A` for plus or minus one; a subroutine for the bounce. Chapter 2's step 4, the user-defined ball, has no twin: the machine-code ball has been its own eight bytes since step 1.
- **As written.** `step4-random.asm`, 503 bytes, step 3's parameters plus `seed` at 50015, entry point 50016; driver `step4-random.bas` (pokes `PEEK 23672` as the seed); examples `step4-examples.asm` + `step4-examples.bas`.
- **Tested.** The LFSR comes back to its seed after 255 calls. A first version with one shift per number chose "straight" 15.0% of the time instead of 19.9%, because small numbers are followed by small numbers; with eight shifts it chose 19.0% and 19.2%. With a screen-wide bat, step 3 stopped at 48 bricks (half the wall) and step 4 passed 48, to 75. Chapter 2, step 5 took 5.1 frames a step without its delay and 44.1 with it (counted after the wall was drawn; step 6 corrected the first figures, 5.9 and 49.6, which included drawing the wall); a pass of this step with no `HALT` took 0.0217 of a frame.

### Step 5 — Speaker clicks (twin of Chapter 2, step 6)

- **Goal.** A click or a short buzz on the bat, a wall, a brick and a miss, while the ball keeps moving.
- **New.** Bit 4 of port 254 and `OUT (254),A`; a pitch as a delay between flips of the speaker bit, and the formula for it; a length as a count of cycles; keeping the border colour in bits 0 to 2 from `BORDCR`; a table of notes; `PUSH` and `POP` in a routine called from the middle of the game.
- **As written.** `step5-sound.asm`, 606 bytes, step 4's parameters plus `quiet` at 50016, entry point 50017; driver `step5-sound.bas` (the border is blue so that damage to it would show); examples `step5-examples.asm` + `step5-examples.bas`.
- **Tested.** The pitches were checked by recording Fuse's sound with SDL's disk audio driver: 262, 1053, 526 and 131 Hz against Chapter 2's 261.6, 1046.5, 523.3 and 130.8. Counts of notes in a recording matched the driver's counters (25 bat hits, 29 bricks; 21 misses). A note of 7.6 to 11.5 ms plays after the `halt` and ends before the next frame, and the game took 3.00 frames a step, and 1.003 at `speed` 1, with all its sounds; copies with notes of about 38 ms took 3.10. Chapter 2, step 6 took 10.04 frames a step (100 steps in 1004 frames, counted after the wall was drawn; the first figure, 11.03, included drawing the wall). A note that leaves the border bits at 0 turned the border black, in the examples and in a copy of the game. This corrects the intention above: the machine-code note does stall the loop while it plays, it only fits in the frame.

### Step 6 — Score, lives and an ending (twin of Chapter 2, step 7)

- **Goal.** A score and lives on row 0, three lives, a game-over and a win.
- **New.** Printing from machine code: the ROM's `RST 16` with `CALL 5633`, strings with `AT` inside them, Chapter 3's `pnum`, and our own print from the character set with `put`, timed against each other and against BASIC `PRINT`; a state byte that tells BASIC how the game ended; a ceiling on row 1 for the status line. The ending screens and their tunes stay in BASIC, because nothing is moving then.
- **As written.** `step6-score.asm`, 800 bytes, step 5's parameters plus `score` (50017), `lives` (50019), `bleft` (50020) and `state` (50021), entry point 50022; driver `step6-score.bas`; examples `step6-examples.asm` + `step6-examples.bas`.
- **Tested.** Game over after three misses and a new game from a key; a win, with a copy that counted the wall as 5 bricks (50 points), twice running; the score is ten times the bricks in a wide-bat run (61 bricks, 610). The 96-brick wall could not be cleared by a wide bat, which stalled at 810 with 15 bricks left, on a repeating path. A status line costs 0.43 of a frame (9 ms) against BASIC's 1.56; one ROM character 0.05 against 0.27. 3.00 frames a step as shipped, 1.004 at `speed` 1, 0.068 with no `halt`. Chapter 2, step 7: 10.0 frames a step with nothing happening and 10.75 with two misses. Step 6 also corrected the Chapter 2 timings in steps 3, 4 and 5, which had counted the drawing of the wall.
- **Step 6b.** The stall was a parity trap, not the generator: with no nudge at the ceiling, the ball could change the parity of `row + col` only from a brick on row 4. `top` now bounces and calls `nudge` (808 bytes). A Python model cleared the wall on all 255 seeds (5 before; 9 with a 16-bit generator), and a screen-wide bat in Fuse cleared all 96 bricks at `speed` 3 in 6444 steps and 19355 frames (6 min 27 s), matching the model's count for its seed, 155.

A short wrap-up of Part A sets the bat-and-ball timings beside Chapter 2's.

### Step 7 — The Invaders base (twin of Chapter 4, step 1)

- **Goal.** Chapter 4's base, its UDG bytes on row 21 in green, moved a column at a time with O and P.
- **New.** `IN` with several half-rows chosen at once (A = 0 reads all eight, but keys on the same bit cannot be told apart); `RLCA`; `rkeys`, one byte with a bit each for P, O, Space and Q, from three reads, 150 T-states with its call; O and P held together cancel; a row coloured once through its attributes. Q stops the game, since Space is for the shot.
- **As written.** `step7-base.asm`, 222 bytes: `halts` (50000), `bspeed` (50001), `moves` (50002), `passes` (50004), `x` (50006), `ptime` (50007), entry point 50008; driver `step7-base.bas`; examples `step7-examples.asm` + `step7-examples.bas`.
- **Tested.** O, P, both held (no move), Caps Shift with O, the edges, Q; 42 moves in 595 frames and 595 passes. The examples read O, P and Space together (mask `0111`) where `INKEY$` gave `""`. 10000 `rkeys` calls in a loop took 27 frames (188 T-states each); one BASIC `INKEY$` 0.232 frames. With a test routine standing in for the keys: 2.004 frames a move as shipped, 1.004 at `bspeed` 1, 0.0192 with no `halt`, against Chapter 4's 2.4 (3.8 with its delay); an idle pass with no `halt` 0.00464 of a frame.

### Step 8 — One shot (twin of Chapter 4, step 2)

- **Goal.** Chapter 4's shot, UDG B in yellow, fired with Space from row 20, one at a time, while O or P is held.
- **New.** `INC A` as a test for 255 (the "no shot" row); `CALL NZ`; a second beat in the loop, so the shot (`sspeed`) and the keys (`bspeed`) keep their own speeds; the attribute set per cell as the shot is drawn.
- **As written.** `step8-shot.asm`, 376 bytes: `halts` (50000), `bspeed` (50001), `sspeed` (50002), `moves` (50003), `passes` (50005), `ssteps` (50007), `shots` (50009), `x` (50010), `ptime` (50011), `stime` (50012), `srow` (50013), `scol` (50014), entry point 50015; driver `step8-shot.bas`; examples `step8-examples.asm` + `step8-examples.bas`.
- **Tested.** Firing alone, while moving each way, and with O and P cancelling; one shot at a time (a tap during a flight did nothing); 21 steps a shot. With a test routine for the keys: the shot 1.00 frame a step (Chapter 4: 2.9), the base 2.008 frames a move with or without a shot flying (Chapter 4: 2.9 alone, 3.9 together); with no `halt` 0.0248 of a frame a shot pass and 0.0389 a pass with both, about 117 and 100 times as quick. `sspeed` 2 gave 2 frames a step.

### Step 9 — The block of invaders (twin of Chapter 4, step 3)

- **Goal.** 4 rows of 8, Chapter 4's UDGs D, F and H in magenta, cyan and white, still; the shot passes through.
- **New.** No new instructions. The `alive` table, a byte an invader, as the source of truth; the `rows` table, a graphic address (`dw`) and an ink for each row; drawing invader by invader with `put` and its own attribute; `invat`, from a screen cell back to the block, used to draw an invader again behind the shot (and in step 11 for hits). `r` cannot be a label: it is a register.
- **As written.** `step9-block.asm`, 615 bytes: step 8's parameters plus `bx` (50015) and `by` (50016), entry point 50017; `alive` at 50523, `rows` at 50555; driver `step9-block.bas`; examples `step9-examples.asm` + `step9-examples.bas`.
- **Tested.** The block as Chapter 4's; a shot up an invader column, caught in the block, with the invaders behind it drawn again; `invat` and `aliveat` on 9 cells and 4 invaders; `bx`, `by`, `alive` and `rows` poked. The whole block drawn in 0.44 of a frame (Chapter 4: 3.8 as strings, 68 cell by cell); no `halt`: idle pass 0.00535 (2.6), base move 0.0210 (3.4), shot step 0.0305 (5.5).

### Step 10 — The march (twin of Chapter 4, step 4)

- **Goal.** The block marches sideways, steps down and back at the edges, changes frame each step, and lands with `THEY HAVE LANDED`, on a beat of `mspeed` frames, with the base and the shot unchanged.
- **New.** No new instructions. A third beat in the loop; moving the whole block in one pass, invader by invader (rub where it was, draw where it is), with no gap; `obx`/`oby` and `where`/`owhere` sharing `wpair`; the edges from `alive` with `or (hl)`; a "negative" `bx` (252) working by wrapping in 8 bits, so `invat` drops its carry tests; `rtype` adding `8*frame`.
- **As written.** `step10-march.asm`, 937 bytes: step 9's parameters plus `mspeed` (50017), `mtime`, `dx`, `frame`, `landed`, `msteps` (50022-50023), entry point 50024; `alive` at 50821, `rows` at 50853; graphics D/E, F/G, H/I; driver `step10-march.bas`; examples `step10-examples.asm` + `step10-examples.bas`.
- **Tested.** March, step down, frames, shots through the marching block; landed after 244 march steps (230 sideways, 13 down, 1 landing) in 6656 frames and 6655 passes. Columns 0, 1 and 7 emptied: marched from column 0 (`bx` 252) to 31, landed after 324 steps at `mspeed` 5. A march step 0.785 of a frame with no `halt` (Chapter 4: 45 sideways, 54 down); the base 2.008 frames a move while marching (7.1), the shot a step a frame (10); idle pass 0.00588 (4.3), base move 0.0224 (4.6).

### Step 11 — Shot against invader (twin of Chapter 4, step 5)

- **Goal.** A shot that meets a living invader kills it: a 0 in `alive`, a yellow starburst (Chapter 4's UDG P) for `elen` frames, the shot gone. Holes march with the block, the edges come from the living columns, and `WAVE CLEARED` after the last one.
- **New.** No new instructions. The hit tested both ways (the shot moving onto an invader, and an invader marching onto the shot); a kill is one byte; the explosion as a fourth beat, one at a time, with `erub` drawing again an invader that has marched onto it; `count` adds the table; the shot now leaves from row 1, so it no longer rubs out messages on row 0 (step 10's did). `left` was taken, so the count is `nleft`.
- **As written.** `step11-hits.asm`, 1102 bytes: step 10's parameters plus `hits`, `nleft`, `elen` (12), `etime`, `erow`, `ecol` (50024 to 50029), entry point 50030; `alive` at 50978; driver `step11-hits.bas`; examples `step11-examples.asm` + `step11-examples.bas`.
- **Tested.** Hits, a second shot through the hole, the starburst for 12 and for 50 frames; with the `auto` routine, the wave cleared after 97 march steps, 32 hits, 6001 passes in 6002 frames; `WAVE CLEARED` stays whole. No `halt`: idle pass 0.0055 (Chapter 4: 4.7), a missing shot step 0.0286 (9.7), a hit 0.037. Frame budget: with `mspeed` 1, 244 march steps with shots and hits in 2001 passes, 2002 frames, so no pass ran over. A bug found and kept in the lesson: the shot's beat skipped the explosion's.

### Step 12 — Bombs (twin of Chapter 4, step 6)

- **Goal.** One bomb at a time, from the lowest living invader of a random living column, every `dwait` frames, falling a row every `dspeed` frames; the base hit ends the game with `YOU ARE HIT`; a shot and a bomb that meet cancel.
- **New.** No new instructions. Step 6's LFSR and `and 7` for a column; the next living column if it is empty (biased: see the lesson); the lowest living invader from `aliveat`; a bomb hidden behind an invader that marches onto it; `ctest` with one `sub` and `cp 2` for BASIC's `Y=U OR Y=U+1`, answering in the carry; `dead`; `JP` where `JR` no longer reaches. The explosion's beat skipped the bomb's, the same bug as in step 11.
- **As written.** `step12-bombs.asm`, 1515 bytes: step 11's parameters plus `seed`, `dwait` (50), `dtime`, `dspeed` (4), `dstime`, `brow`, `bcol`, `dead`, `bombs`, `cancels` (50030 to 50039), entry point 50040; `alive` at 51383; driver `step12-bombs.bas`; examples `step12-examples.asm` + `step12-examples.bas`.
- **Tested.** Bombs in play, the base hit and the game stopping but for Q; a whole wave with a test copy that only counts hits on the base (32 hits, 41 bombs, 2 cancels, 3 base hits, 6001 passes and frames). No `halt`: idle pass 0.0062 (Chapter 4: 6.7), a pass with a bomb step 0.033 (9.0), a shot step with the bomb test 0.0305 (13.6). Frame budget: march, bomb and shot on every pass, 2001 passes in 2002 frames.

### Step 13 — Shields (twin of Chapter 4, step 7, and step 8's wiping)

- **Goal.** Four 3x2 shields on rows 18 and 19 in Chapter 4's columns and shapes, with a damage map, chipped by shots and bombs, and wiped out where invaders are drawn on them.
- **New.** `DS`. `shat`: screen cell to map byte with `sub`/`cp`, `AND 7` and shifts (the shields are eight columns apart); `shdraw` from a table of pictures by level; `chip` answering in the carry; `stomp` in `dinv`; `dshield` drawing from the same lookup. `shr` and `shl` are pasmo operators, so the names are `shy`, `shx`, `gK`, `gL`.
- **As written.** `step13-shields.asm`, 1815 bytes: step 12's parameters plus `chips`, `stomps` (50040, 50041), entry point 50042; `shmap` at 51593, `alive` at 51635; driver `step13-shields.bas`; examples `step13-examples.asm` + `step13-examples.bas`.
- **Tested.** Staged chips by shots, bomb chips, a shot through a hole; a low block wiped all 24 cells; a whole wave (auto, seed 77): 168 march steps, 6001 passes, 6002 frames. No `halt`: idle 0.0062 (Chapter 4: 6.8), a chip 0.015 (a 24-frame pass), a march step 0.88 on the shield rows against 0.83 above. Frame budget: march, bomb and shot every pass, from row 1 (2001 passes, 2002 frames) and all on the shield rows (201, 202): no overrun.

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
