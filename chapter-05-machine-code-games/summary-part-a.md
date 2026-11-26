# Chapter 5, Part A — Bat and ball in machine code: summary

Six steps took Chapter 2's bat and ball into machine code, one step to one step. Each was run in a 48K Fuse and timed with `FRAMES` against its BASIC twin.

| Step | What it added | Twin in Chapter 2 | Lesson |
|-----:|---------------|-------------------|--------|
| 1 | A ball, kept to the frame with `HALT` | Step 1 | [step1-ball.md](step1-ball.md) |
| 2 | A bat read with `IN`, so O and P can be held together | Step 2 | [step2-bat.md](step2-bat.md) |
| 3 | A wall of bricks, found and rubbed out through the attributes | Step 3 | [step3-bricks.md](step3-bricks.md) |
| 4 | A little randomness, from an 8-bit LFSR | Step 5 | [step4-random.md](step4-random.md) |
| 5 | Notes on the speaker, with the border kept | Step 6 | [step5-sound.md](step5-sound.md) |
| 6 | Score, lives, game over and a win, printed with the ROM | Step 7 | [step6-score.md](step6-score.md) |

## The timings

In frames a step (one frame is a fiftieth of a second). The BASIC figures were taken with the count started after the wall was drawn.

| Step | BASIC twin, with its delay | BASIC twin, no delay | Machine code, as shipped | Machine code, `speed` 1 | Machine code, no `halt` |
|------|---------------------------:|---------------------:|-------------------------:|------------------------:|------------------------:|
| 1 | 7.0 | 2.4 | 2.00 | 1.002 | 0.0166 |
| 2 | 35.2 | 4.1 | 2.99 | | 0.019 |
| 3 | 39.1 | 4.8 | 3.00 | | 0.022 |
| 4 | 44.1 | 5.1 | 3.00 | | 0.0217 |
| 5 | 9.4 to 10.0 | | 3.00 | 1.003 | |
| 6 | 10.0 to 10.75 | | 3.00 | 1.004 | 0.068 |

In steps 5 and 6 the BASIC twin has its short delay, `FOR I=1 TO 10`, and the beeps. The last figure for step 6 has every sound and every status line in it. The BASIC figures for steps 1 and 2 are from those lessons and were not taken again.

## What the six steps showed

- **The loop is not the cost.** A pass of the machine-code loop, with the ball, the bat, the bricks and the keys, takes about a fiftieth of a frame. Chapter 2's loop, with its delay taken out, took 4 to 5 frames. The difference is about 200 times, and in the shipped games the code is idle most of the time, waiting for the next frame.
- **A frame is the unit.** `HALT` gives a steady beat, and `speed` is then a number of frames, exact whatever the ball is doing. Chapter 2's `PAUSE` and `FOR` delays gave a speed that changed with every line added.
- **What costs time is the output.** A note is 8 to 11 ms and a status line 9 ms, against a frame of 20. Each fits, and the two together nearly fill one: at `speed` 1 a brick, with both, now and then spilled into the next frame.
- **A sound that is a delay loop stalls the loop.** It is not a way to play sound "without stalling". It is a way to stall for 10 ms rather than 20, and to know exactly how long. A note longer than a frame loses beats (3.10 frames a step instead of 3.00 in a test).
- **The screen is the data.** The brick test reads the attribute of the cell ahead, as Chapter 2's `ATTR` did. The status line works for the same reason it did in BASIC: row 0 is made a ceiling.
- **Randomness has to be measured in the use it is put to.** An LFSR with one shift per number was biased (15.0% where 19.9% was meant); with eight shifts it was close. It is still not random: a wide bat fell onto a repeating path in step 4, and again in step 6, with 15 bricks left.
- **The ROM is worth using for text.** Its print routine was 5 times as quick as BASIC for a character and 3.6 times for the status line, and it is already written. Our own print, from the character set, is faster again and does less.
- **The border is a side effect of the speaker.** Port 254 is one byte with both in it. Writing only the speaker bit turns the border black, and `BORDCR` goes on saying the old colour.

## Corrections made on the way

- Step 2's bat-drawing routine put part of the bat on row 0 until `put`'s register was saved. It is in the lesson.
- Step 5 first said a note "never stalls the game". It does, and it fits in a frame. The plan, the outline and the lesson now say so. Chapter 4's summary still says "sound that does not stall the loop", and will want the same change.
- Steps 3, 4 and 5 first gave Chapter 2's timings with the drawing of the wall counted in. Step 6 re-timed them and changed the figures and the ratios.

## What Part B takes from here

Invaders has many things to draw and move on every frame. Part A has the pieces to do that with: a loop on `HALT`, a `put` that copies a graphic into a cell, a table of what is where, a key read with `IN`, a note and a number. What it does not have is more than one object that moves on its own beat. Step 7 of the plan starts with the base on row 21, and adds the shot, the block, the march, the bombs, the shields and the score in the order of Chapter 4.
