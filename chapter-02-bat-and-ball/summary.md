# Chapter 2 — What we learned in BASIC, and why we stop here

Chapter 2 built a small bat-and-ball game in Sinclair BASIC, one tested step at a time: a bouncing ball, a bat, a wall of bricks, a user-defined ball, a little random deflection, beeps, then a score, lives, and an ending. The listings are in this folder; this note wraps up the BASIC we used, and is honest about why this is about as far as BASIC can reasonably go for a game on the 48K Spectrum.

Every figure below was measured in Fuse, on a 48K machine, at `--speed 100`, with the built-in frame counter `FRAMES` (system variable 23672, incremented every 20 ms, so 50 counts a second). The two-byte form of `FRAMES` was read twice if the high byte changed mid-read, so a wrap between the two `PEEK`s could not spoil the count. Time in seconds is frames divided by 50.

## The keywords, grouped by what they are for

Each keyword is listed with the step that introduced it. A few were used earlier without a formal write-up; those are marked as used rather than introduced.

### The screen and printing

| Keyword | Step | Role in the game |
|---------|-----:|------------------|
| `BORDER`, `INK`, `PAPER` (as statements) | 1 | Black border and paper, white ink, set once at the start. |
| `CLS` | 1 | Clear the screen before the wall and bat are drawn, and again on the end-of-game screens. |
| `PRINT` / `PRINT AT` | 1 | Place the ball, the bat, the wall, the status line, and the messages. Rows 0 to 21 only. |
| `INK` and `PAPER` inside `PRINT` | 3 | Temporary paper for each brick row, without changing the permanent colours. |
| `INVERSE` | used in 2 | The bat is a run of inverse spaces. |
| `CHR$` | 4 | `CHR$ 144` prints UDG A, the ball. |
| `STR$` and string `+` | 7 | Build `SCORE 20` and `LIVES 2` at fixed columns, without the spacing of a raw `PRINT` of a number. |

### Program structure and decisions

| Keyword | Step | Role in the game |
|---------|-----:|------------------|
| `REM` | 1 | A remark for every variable, and a place to write down what a line is for. |
| `LET` | 1 | Every change of position, direction, score or lives. |
| `IF` / `THEN` | 1 | Bounce, bat, miss, brick, win and game-over tests. |
| `GO TO` | 1 | The game loop, and the jumps to the bat, miss, brick, nudge, win and game-over code. |
| `AND` / `OR` | 2 | O or P, and the edges of the bat. |
| String comparisons | 2 | `K$="o"`, and later the empty-string test for a key. |
| `GO SUB` / `RETURN` | 7 | The status line, called from three places so they cannot drift apart. |
| `RUN` | 7 | After a win or a loss, forget the variables and start a new game from scratch. |

### Loops, time, and the keyboard

| Keyword | Step | Role in the game |
|---------|-----:|------------------|
| `PAUSE` | 1 | Tried as a delay; dropped, because a key cuts it short. |
| `FOR` / `NEXT` (a delay) | 2 | `FOR I=1 TO 10: NEXT I` is the delay in the shipped game. |
| `FOR` / `NEXT` (with a body, and nested) | 3 | Drawing the wall, and defining the ball UDG. |
| `INKEY$` | 2 | Read O and P each pass of the loop, without waiting. |
| The `INKEY$` wait loop | 7 | Wait for a held key to go up, then for a fresh press, before `RUN`. |

### The screen as data, and the ball graphic

| Keyword | Step | Role in the game |
|---------|-----:|------------------|
| `ATTR` | 3 | The colour of the cell ahead of the ball *is* the map of the wall. |
| `INT` | 3 | `INT(A/8)` is the paper colour, when flash and bright are off. |
| `USR` (the string form) | 4 | `USR "a"` is the address of UDG A. |
| `POKE` / `PEEK` | 4 (first used in Chapter 1) | Write the eight bytes of the ball into the UDG area. `PEEK` is shown alongside, for reading a byte back. |
| `BIN` | 4 | The bit pattern of each row of the ball, written as binary. |
| `DATA` / `READ` / `RESTORE` | 4 | The eight bytes of the ball, kept in the listing and loaded into the UDG. |

### Chance, sound, and an ending

| Keyword | Step | Role in the game |
|---------|-----:|------------------|
| `RANDOMIZE` / `RND` | 5 | A slight deflection: sometimes `DX` becomes 0 for one leg. |
| `INT(RND*n)` | 5 | A random choice of `-1` or `+1` when a vertical rally has to end. |
| `BEEP` | 6 | Short notes on the bat, a wall, a brick, and a miss; a short tune at the end of a game. |

## The ideas the game is built on

**A game loop.** The program does not run through once and stop. After the setup it draws the ball, waits a little, rubs the ball out, reads the keys, decides what the next cell is, and goes back to the draw. `GO TO 130` is that loop. Win, game over, and `RUN` are the ways out.

**Erase, move, draw.** The ball is a character cell. To move it, the old cell is printed as a space, the row and column are updated, and the ball is printed in the new cell. The bat does the same when it steps left or right. There is no separate sprite layer: what you see is whatever was last printed.

**Collision by `ATTR`.** There is no list of brick positions. Just before the ball steps, `ATTR` reads the cell ahead. If the paper is not black, that cell is a brick, and is rubbed out. The same test would be fooled by the status line (paper 0, ink 7), which is why row 0 is treated as a wall and the ball is not allowed to print there.

**UDGs and binary.** The ball is eight bytes in the user-defined graphics area. `BIN` makes those bytes readable as a picture of pixels; `POKE USR "a"+N,D` writes them; `CHR$ 144` prints them.

**`RND` is enough for a small nudge.** The bat's ends still steer. A middle-bat or brick bounce has a chance to set `DX` to 0 for one leg, and a vertical rally is always broken on the next such bounce. Three values of `DX` (`-1`, `0`, `+1`) are the whole of the "physics".

**Sound is a blocking `BEEP`.** The speaker is driven by the ULA, as in Chapter 1. The CPU sits in the note until it ends, so the in-game beeps are kept to 0.02 seconds and the longer tunes wait until play has already stopped.

**Subroutines and state.** Score, lives, and bricks left are ordinary variables. A `GO SUB` keeps the status line in one place. `RUN` (which includes a `CLEAR`) is the way to forget that state and start again; `GO TO` would not have forgotten it.

## Why this is about as far as BASIC goes

The game is complete enough to play, and that is a good place to stop and change tools. The limits below are not taste: they are properties of Sinclair BASIC on this machine.

**It is interpreted, and it is slow.** Each line is decoded as it runs. An empty loop is already expensive, because `I` is a five-byte floating-point number, not a machine register. In Fuse, `FOR I=1 TO 1000: NEXT I` took 266 frames every time in five runs, which is 5.32 seconds. A single `FOR I=1 TO 10000: NEXT I` took 2345 frames, 46.9 seconds. The delay in the shipped game, `FOR I=1 TO 10: NEXT I`, was timed as 200 repetitions in 629 frames (12.58 seconds), or about 63 milliseconds each including the outer counting loop. The older delay of `1 TO 100`, twenty times, took 610 frames (12.2 seconds), or about 0.61 seconds each — which is why the ball crawled at real Spectrum speed in steps 2 to 5.

The game loop itself is much more than that delay. A copy of the step 7 loop was instrumented to count iterations for 250 frames, peeking `FRAMES` on every pass (so this is a slightly heavy version of the real loop). With the `1 TO 10` delay it managed 19 loops in 251 frames, 3.78 loops a second. With the delay removed it managed 31 loops in 257 frames, 6.03 a second. In the uninstrumented game, earlier playtests (Fuse at `--speed 100`, miss-to-miss from the ball's path and from a sound recording) were about five cell-steps a second with the delay in place. Taking the delay out does not suddenly give a fluid game: most of the time is `PRINT AT`, `ATTR` and `INKEY$`, still running through the interpreter. Six steps a second is the same sort of pace.

A whole-screen fill makes the same point in a different way. A BASIC loop that `POKE`d 255 into every bitmap byte, 16384 to 22527 (6144 bytes), took 2446 frames, 48.92 seconds. Filling the attributes, 22528 to 23295 (768 bytes), took 341 frames, 6.82 seconds. That is why the fill in Chapter 1 is slow enough to watch, and why a later machine-code fill will be worth measuring against these numbers.

**Movement is by whole character cells.** The ball jumps 8×8 pixels at a time. There are only 32 columns and, in the finished game, 20 rows of play. A diagonal is `DX` and `DR` of plus or minus one cell. There is no hardware sprite, no smooth pixel scroll, and no way in this BASIC to draw the ball at an arbitrary pixel without a lot of `POKE` and a lot more time.

**The draw is not synchronised with the display.** The picture is refreshed 50 times a second by the ULA. The BASIC loop erases the ball, does some work, and draws it again, at its own pace, a handful of times a second. The result is flicker. `PAUSE` cannot be used to wait for a frame, because a key cuts it short, and BASIC has no built-in "wait for the start of the next picture".

**`INKEY$` reads one key, when you happen to ask.** If two keys are down, you see one of them, or none, depending on the keyboard matrix. The bat cannot easily move and do something else at the same moment. There is no queue of keys, other than what you build yourself.

**`BEEP` blocks.** A collision sound that lasted a tenth of a second would hitch the rally. The CPU is not free to move the bat while a note is playing. Games that need music or effects under moving graphics do this in machine code, on the same speaker, without sitting in the ROM's `BEEP` routine.

**Every number is floating point.** Positions, loop counters, scores and random values all use the same five-byte form. That is convenient, and it is why `INT` keeps appearing, and it is part of why a tight `FOR` loop is slow.

**The machine does not help you draw.** There are no sprites, no hardware scrolling, and no second pixel buffer to compose a frame off-screen and flip it. The ULA paints what is in the display file. Attribute clash — one ink and one paper per 8×8 cell — is the same limit as in Chapter 1, and a UDG ball on a black field hides it rather than removing it.

## What machine code is for, here

The next chapter is there to do the things this game cannot: move by pixels, fill a screen in a fraction of the time BASIC took above, and run a tight loop in time with the display, with the CPU free between beeps. The ideas from this chapter still apply — a game loop, a picture in RAM, attributes as colour, a timer in `FRAMES` — but the instructions will be the Z80's, not a line of BASIC interpreted as it runs.

The plan for that work is in [Chapter 3](../chapter-03-machine-code/PLAN.md).
