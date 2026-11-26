# Chapter 5, Part B — Invaders in machine code: summary

Eight steps took Chapter 4's Invaders into machine code, one step to one step, in the same order. Each was run in a 48K Fuse and timed with `FRAMES` against its BASIC twin. The BASIC figures are copied from Chapter 4's lessons and [summary](../chapter-04-invaders-basic/summary.md); the machine-code figures are from this chapter's lessons, where the method for each one is set out.

| Step | What it added | Twin in Chapter 4 | Lesson |
|-----:|---------------|-------------------|--------|
| 7 | The base, read with `IN`, several half-rows into one key byte | Step 1 | [step7-base.md](step7-base.md) |
| 8 | One shot, on its own beat, while O or P is held | Step 2 | [step8-shot.md](step8-shot.md) |
| 9 | The block, drawn from an alive table, with a lookup each way | Step 3 | [step9-block.md](step9-block.md) |
| 10 | The march: edges, a step down, two frames, a landing | Step 4 | [step10-march.md](step10-march.md) |
| 11 | Shot against invader, the table as the record, an explosion | Step 5 | [step11-hits.md](step11-hits.md) |
| 12 | Bombs: a random column, the lowest invader, a cancel | Step 6 | [step12-bombs.md](step12-bombs.md) |
| 13 | Four shields with a damage map, chipped and wiped out | Step 7 | [step13-shields.md](step13-shields.md) |
| 14 | Score, lives, waves, game over and clicks; the march rippled | Step 8 | [step14-game.md](step14-game.md) |

## BASIC against machine code, job by job

In frames (a fiftieth of a second). "No `halt`" is the machine-code job timed with the wait for the frame switched off, so it is the time the job itself takes. As shipped, every machine-code pass is one frame.

| Step | Job | BASIC (Chapter 4) | Machine code, as shipped | Machine code, no `halt` | About |
|-----:|-----|------------------:|-------------------------:|------------------------:|------:|
| 7 | A base move | 2.4 (3.8 with its delay) | 2.004 (every second frame) | 0.0192 | 125 × |
| 7 | Reading the keys | 0.232 for `INKEY$` | | 0.0027 (188 T-states for `rkeys`) | 86 × |
| 8 | A shot step | 2.9 | 1.00 | 0.0248 | 117 × |
| 8 | A base move with a shot flying | 3.9 | 2.008 | 0.0389 for both | 100 × |
| 9 | Drawing the whole block | 3.8 as strings, 68 cell by cell | | 0.44 | 9 × |
| 9 | An idle pass | 2.6 | 1 | 0.00535 | 490 × |
| 10 | A march step | 45 sideways, 54 down | 1 pass every 25 | 0.785 | 57 × |
| 10 | A base move while marching | 7.1 | 2.008 | 0.0224 | 320 × |
| 11 | A shot step that misses | 9.7 | 1 | 0.0286 | 340 × |
| 11 | A pass with a hit | 10.3 | 1 | 0.037 | 280 × |
| 12 | A pass with a bomb step | 9.0 | 1 | 0.033 | 270 × |
| 12 | A shot step with the bomb test | 13.6 | 1 | 0.0305 | 450 × |
| 13 | A pass that chips a shield | 24 | 1 | under 0.05 | 500 × |
| 13 | A march step on the shield rows | | | 0.88 | |
| 14 | An idle pass | 6.5 | 1 | 0.0075 | 870 × |
| 14 | A march step | a 106-frame cycle (102 on wave 2) | 25 frames, 4 passes of a row each (22 on wave 2) | 0.21 a row | |
| 14 | A sound in play | 1.2 for `BEEP 0.02` | | 0.06 to 0.07 for a click | 18 × |
| 14 | The score, printed | | | 0.05 | |
| 14 | A new wave, set up | a `CLS` and a rebuild | | 3.8, and 3 of notes | |

The idle pass is the plainest comparison, since it is the same job in every step: the loop going round with nothing to do. In BASIC it grew from 2.6 frames to 6.8 as the game grew. In machine code it stayed between 0.005 and 0.0075 of a frame.

## The frame budget

The machine-code game does all its work inside one frame a pass, and every step from 10 on tested that with a copy that put a march step, a bomb step and a shot on every pass:

| Step | Worst pass, added up | Budget test | Result |
|-----:|---------------------:|-------------|--------|
| 10 | 0.79 | a game played to the landing: 6655 passes | 6656 frames: none over |
| 11 | | `mspeed` 1, with shots and hits, 2001 passes | 2002 frames: none over |
| 12 | about 0.88 | march, bomb and shot every pass, 2001 passes | 2002 frames: none over |
| 13 | about 0.98 | the same, from row 1 and on the shield rows | 2002 for 2001, 202 for 201: none over |
| 14, without the ripple | over 1 | the same, counted from the first pass | 245 for 244, 48 for 46: passes ran over |
| 14, with the ripple | about 0.5 | the same | 1013 for 1013, 189 for 189: none over |

In steps 10 to 13 the count started before the first pass, and the one extra frame was taken as the set-up. Step 14 counted from the first pass, because its set-up takes 3.8 frames. So the march, three-quarters of the worst pass, was the place to save. Step 14 applied Chapter 4's answer, a row a pass, which step 10 had kept in reserve.

## What the eight steps showed

- **The same design, at another speed.** Every idea Chapter 4 found carried over:
  - the alive table and the damage map as the record;
  - the hit test by arithmetic, not by reading the screen;
  - the living edges;
  - the drop from the lowest invader.
  
  What changed is that each idea costs a hundredth of what it did, or less. The game's beats became numbers of frames, so a shot can fly every frame and the base move every second one.
- **One idea came back.** Chapter 4 rippled the march because a step took 45 frames. Machine code did not need it until the last step, when a score and a click on a hit pushed a pass over. Then the ripple was the fix again, at a cost: the routines that find an invader have to know which rows have moved.
- **The keys are a port.** O or P and Space together, and no Break, were the first things BASIC could not do (step 7).
- **A table is the source of truth.** The block is never read back from the screen. It is drawn from `alive` and `bx`, `by`, and every test asks the table.
- **The beat chain has to be kept.** Twice, in steps 11 and 12, a beat that had nothing to do jumped past the next beat instead of to it, and a whole job stopped while another was busy. Both were found in Fuse and kept in the lessons.
- **The output is still the cost.** As in Part A, what takes time is drawing. A march step is 32 invaders rubbed out and drawn again, and it was over three-quarters of the worst pass until the ripple split it.
- **Sound is a stall you can size.** A `BEEP 0.02` cost 1.2 frames. A click of one to three cycles costs 0.06, small enough to play in the middle of a pass. The long notes are kept for when the game is paused anyway.
- **BASIC is still useful around the game.** The game-over screen, the wait for a key and the four-note tune are BASIC's, at line 300 of the driver. They are not in a hurry, and the code returns to BASIC with a byte that says why the game ended.

## Corrections made on the way

- Step 10's shot went on to row 0, where it could rub out `THEY HAVE LANDED`. One instruction, `dec a` for `and a`, fixed it at the same size, and the lesson says so.
- Steps 11 and 12 each had a beat that skipped the next one, found in Fuse and fixed.
- In step 13, `shr` and `shl` were refused as labels, being pasmo operators.
- Step 14 first ran without the ripple. The budget tests showed passes over their frame, and the ripple went in.
- Steps 10 to 13 printed their messages on row 0 with the ROM, where they could land over one another. Step 14 gives row 0 to the status line, and the messages go to the game-over screen.

## What is left

Chapter 4's summary listed what the machine code had to fix.

- **Done:**
  - a loop in time with the picture;
  - more than one key at a time;
  - clicks that cost about a sixteenth of a frame instead of whole frames;
  - a shot, a bomb and a march on steady beats;
  - a score that is printed in 0.05 of a frame.
- **Nearly done.** A new wave has a short pause, about a seventh of a second: 3.8 frames to set up and 3 of notes. The plan asked for no visible pause.
- **Left for later:**
  - movement and shield damage by pixels;
  - a game font;
  - more than one bomb;
  - a Kempston joystick.
