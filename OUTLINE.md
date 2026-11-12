# ZX Spectrum programming course — outline

A hands-on course for getting back into Spectrum thinking: the machine, BASIC, the screen, machine code, a Space Invaders-style game built first in BASIC and then in machine code, and a generic sprite engine.

Every program is tested in a 48K Spectrum emulator before it is shown. We work in short chunks, one at a time. Notes stay plain and short.

This is not a beginner's course from a blank slate. It starts from first principles so the later parts sit on a solid base, and it assumes some earlier familiarity with BASIC and Z80.

---

## Chapter 1 — The Spectrum: design, memory, and the screen

What the machine is, and why the screen behaves as it does. The notes and the first fill live in [chapter-01-the-machine](chapter-01-the-machine/).

1. The hardware in brief: Z80, 16K ROM, 48K RAM, the ULA, keyboard, border, and speaker.
2. The memory map: ROM (`0`–`16383`), the display file (`16384`–`22527`), attributes (`22528`–`23295`), system variables, and the space left for programs.
3. The display: 256×192 pixels, 32×24 character cells, the three thirds, and the odd order of pixel rows in memory (why a SCREEN$ loads in stripes).
4. The attribute byte: INK, PAPER, BRIGHT, FLASH, and attribute clash.

Checkpoint: you can point to a pixel or a character cell and say where its bits and its colour live in memory.

---

## Chapter 2 — BASIC, building up to a tiny game

Clear BASIC programs, each one tested, each one adding a little, until there is a small game. The notes and listings live in [chapter-02-bat-and-ball](chapter-02-bat-and-ball/).

The bat-and-ball game is built in these steps, each one tested before the next:

1. A bouncing ball (`PRINT AT`).
2. A bat you move with `INKEY$` (O left, P right).
3. A wall of coloured bricks, with hits detected by `ATTR`.
4. A user-defined graphic for the ball.
5. A little random deflection on the bounce, so the path is not always a perfect diagonal.
6. `BEEP` sounds: a lower pitch when the ball hits the bat, a higher pitch when it hits a wall or a brick.
7. Score, lives, a game-over screen, and a win if you clear the wall.

The earlier BASIC ideas — `PRINT`, `BORDER`, `INK`, `PAPER`, variables, `IF`, `FOR`, and so on — are taught in the steps as they are needed, rather than as a separate first pass.

The slowness of BASIC animation is useful here: it is why Chapter 3 exists. A short wrap-up of what we learned, and why BASIC has gone about as far as it can, is in [chapter-02-bat-and-ball/summary.md](chapter-02-bat-and-ball/summary.md).

---

## Chapter 3 — The memory map, BASIC fills, then the same fills in machine code

The original plan had this as two parts: screen fills with `POKE` in BASIC, then the same fills in Z80. They are now one chapter, so the speed jump is seen in the same place. The plan is in [chapter-03-machine-code/PLAN.md](chapter-03-machine-code/PLAN.md).

The agreed order is the memory map and system variables first, then BASIC fills (including a slow interactive fill), then Z80.

1. The 48K memory map in enough detail to place a routine safely: `CLEAR`, `RAMTOP`, and a few system variables (`FRAMES`, `LAST K`, `UDG`, `ATTR P`).
2. `PEEK` and `POKE`. Fill a character cell, a pixel row, the whole bitmap (`16384`–`22527`), and the attributes (`22528`–`23295`), and time the last two.
3. Bit patterns: solid, stripes, chequer, dither — seeing how a byte becomes eight pixels.
4. A slow interactive fill in BASIC: you pick the attribute and the bit pattern, and the program fills the screen with them.
5. What machine code is: bytes in RAM, and calling them with `USR` / `RANDOMIZE USR`. The Z80 in small pieces: registers (A, F, BC, DE, HL), `LD`, a counted loop, then `LDIR` when it helps.
6. The same fills rewritten in machine code, timed side by side with the BASIC versions, so the speed increase is measured, not just claimed.
7. A fast interactive fill that uses the machine-code routine and a BASIC menu.
8. Just enough more for later chapters: the stack, `CALL` / `RET`, `DJNZ`, and waiting on the frame (`HALT`).

Machine code starts at 50000, after `CLEAR 49999`. We may move it lower later if we need more space. The course assembler is pasmo, using `--tapbas` to write a tape with a short BASIC loader.

All nine steps of Chapter 3 are written and tested. The wrap-up, with the BASIC against machine code timings, is in [chapter-03-machine-code/summary.md](chapter-03-machine-code/summary.md). Several of the questions that wrap-up asked about Chapter 4 now have answers, and the ones that still apply have been moved to Chapter 5.

---

## Chapter 4 — A Space Invaders-style game in BASIC

A Space Invaders-style game in pure Sinclair BASIC, built in small, tested, playable steps, in the same rhythm as Chapter 2. It will be slow: that is the point. Learners see how the game is put together, then Chapter 5 rebuilds it in machine code, in the same order, for a like-for-like comparison.

The plan is in [chapter-04-invaders-basic/PLAN.md](chapter-04-invaders-basic/PLAN.md).

The game is built in these steps, each one tested before the next:

1. The player's base, as a UDG, moving left and right with O and P.
2. One shot at a time, fired with Space.
3. A still block of four rows of eight invaders (32) as UDGs, drawn from `DATA` into an array.
4. Marching the block sideways, and stepping down at the edges, with the invaders animated in two frames.
5. Shot-versus-invader hits. The living/dead array is the source of truth; `ATTR` and `SCREEN$` are discussed and set aside.
6. Invaders' bombs.
7. Four shields that erode as they are hit.
8. Score, lives, waves, game over and `BEEP`.

Movement is by whole character cells. Sound is `BEEP`. The lesson format is the same as Chapter 2, including a `REM` line for every variable. Dalix's answers are in the plan: Space to fire, shields in, two-frame animation, and four rows of eight invaders.

---

## Chapter 5 — The same games in machine code

Chapter 5 starts with a warm-up: the Chapter 2 bat-and-ball game translated to machine code. That is the course's first real-time game loop (`HALT`, reading the keyboard, moving things, collisions). Then it rebuilds the Chapter 4 Invaders game in machine code, step by step in the same order, so the two versions can be compared for speed and for how the programs are written.

Questions that still need a decision before that chapter is written, carried forward from the Chapter 3 wrap-up:

1. How much BASIC stays around the machine-code games: just the loader and menu, or the score and the screens between games too? The game loop itself has to be machine code.
2. Movement by whole character cells, as in Chapter 4, or a pixel at a time sideways? Pixels are smoother and lead into Chapter 6, but they are more work.
3. Where the code lives. 50000 after `CLEAR 49999` leaves about 15K, which should be plenty; the start can move lower if the game grows, as decision 5 in the [Chapter 3 plan](chapter-03-machine-code/PLAN.md) allows.
4. Whether a Kempston joystick should work as well as the keys (Fuse can emulate one). Chapter 4 already uses O and P, and Space to fire.
5. Sound. Chapter 4 uses `BEEP`, which stops everything while it plays. Short clicks written straight to the speaker port are the usual answer in a machine-code game, and would be new.

---

## Chapter 6 — A parameter-driven sprite engine

A generic sprite engine that can drive more than one kind of game, rather than a one-off blit for a single size. This was previously planned as Chapter 5. It comes after the machine-code games, once character cells are no longer enough and things need to move smoothly over a background.

The engine is parameter-driven. The main parameters are:

- **Sprite size** — width and height (in bytes/pixels, not a fixed 16×16 or 24×24).
- **Frames** — how many animation frames, and how pre-shifted copies of each frame are stored so movement is smooth.
- **Scroll steps per call** — how many pixels the sprite moves each time the engine is called (for example 1-pixel or 2-pixel steps).

Around those:

1. Pixel addresses and a row table, so drawing does not recalculate the shuffled screen layout every line.
2. Masked drawing, and saving/restoring the background (including the order of restore when two sprites overlap).
3. Wiring size, frames, and scroll steps as parameters, then a short demo with two different sprite sizes running from the same engine.

Existing sprite-engine notes from the trilogy can be used as a reference later. This part still builds the generic engine from the ideas in Chapters 1–5, not by lifting game code.

---

## After this course

This course ends at the generic sprite engine.

Later, once the Atlantis trilogy is finished, the same work moves on to a Java version, and then to a mobile game. Those are separate stages, not part of the six chapters above.
