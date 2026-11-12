# ZX Spectrum programming course — outline

A hands-on course for getting back into Spectrum thinking: the machine, BASIC, the screen, then machine code, a simple game, and a generic sprite engine.

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

All nine steps of Chapter 3 are written and tested. The wrap-up, with the BASIC against machine code timings and the open decisions for Chapter 4, is in [chapter-03-machine-code/summary.md](chapter-03-machine-code/summary.md).

---

## Chapter 4 — A simple Space Invaders-style game

A small machine-code game that does not need clever sprites. Character cells or simple block graphics are enough.

1. A game loop synced to the frame with `HALT`.
2. Reading the keyboard.
3. The player and bullets.
4. A row of invaders (or a few descending aliens) and their shots.
5. Collisions, score, lives, and game over.
6. The pieces put together, tested as they go in.

This is the bridge to Chapter 5: once things need to move smoothly over a background, character blocks are no longer enough.

---

## Chapter 5 — A parameter-driven sprite engine

A generic sprite engine that can drive more than one kind of game, rather than a one-off blit for a single size.

The engine is parameter-driven. The main parameters are:

- **Sprite size** — width and height (in bytes/pixels, not a fixed 16×16 or 24×24).
- **Frames** — how many animation frames, and how pre-shifted copies of each frame are stored so movement is smooth.
- **Scroll steps per call** — how many pixels the sprite moves each time the engine is called (for example 1-pixel or 2-pixel steps).

Around those:

1. Pixel addresses and a row table, so drawing does not recalculate the shuffled screen layout every line.
2. Masked drawing, and saving/restoring the background (including the order of restore when two sprites overlap).
3. Wiring size, frames, and scroll steps as parameters, then a short demo with two different sprite sizes running from the same engine.

Existing sprite-engine notes from the trilogy can be used as a reference later. This part still builds the generic engine from the ideas in Chapters 1–4, not by lifting game code.

---

## After this course

This course ends at the generic sprite engine.

Later, once the Atlantis trilogy is finished, the same work moves on to a Java version, and then to a mobile game. Those are separate stages, not part of the five chapters above.
