# ZX Spectrum programming course — outline

A hands-on course for getting back into Spectrum thinking: the machine, BASIC, the screen, then machine code, a simple game, and a generic sprite engine.

Every program is tested in a 48K Spectrum emulator before it is shown. We work in short chunks, one at a time. Notes stay plain and short.

This is not a beginner's course from a blank slate. It starts from first principles so the later parts sit on a solid base, and it assumes some earlier familiarity with BASIC and Z80.

---

## Part 1 — The Spectrum: design, memory, and the screen

What the machine is, and why the screen behaves as it does.

1. The hardware in brief: Z80, 16K ROM, 48K RAM, the ULA, keyboard, border, and speaker.
2. The memory map: ROM (`0`–`16383`), the display file (`16384`–`22527`), attributes (`22528`–`23295`), system variables, and the space left for programs.
3. The display: 256×192 pixels, 32×24 character cells, the three thirds, and the odd order of pixel rows in memory (why a SCREEN$ loads in stripes).
4. The attribute byte: INK, PAPER, BRIGHT, FLASH, and attribute clash.

Checkpoint: you can point to a pixel or a character cell and say where its bits and its colour live in memory.

---

## Part 2 — BASIC, building up to a tiny game

Clear BASIC programs, each one tested, each one adding a little, until there is a small game. The notes and listings live in [chapter-01-the-machine](chapter-01-the-machine/) (the machine itself) and [chapter-02-bat-and-ball](chapter-02-bat-and-ball/) (the game).

The bat-and-ball game in Chapter 2 is built in these steps, each one tested before the next:

1. A bouncing ball (`PRINT AT`).
2. A bat you move with `INKEY$` (O left, P right).
3. A wall of coloured bricks, with hits detected by `ATTR`.
4. A user-defined graphic for the ball.
5. A little random deflection on the bounce, so the path is not always a perfect diagonal.
6. `BEEP` sounds: a lower pitch when the ball hits the bat, a higher pitch when it hits a wall or a brick.
7. Score, lives, game over, and a win when the wall is cleared.

The earlier BASIC ideas — `PRINT`, `BORDER`, `INK`, `PAPER`, variables, `IF`, `FOR`, and so on — are taught in the steps as they are needed, rather than as a separate first pass.

The slowness of BASIC animation is useful here: it is why Parts 3 and 4 exist.

---

## Part 3 — Screen fills with POKE, then an interactive fill

The aim is to think in Spectrum screens again: bitmap bytes and attribute bytes, not `PRINT` and `PLOT`.

1. `PEEK` and `POKE`. Poke one display-file byte and one attribute byte, and see the result.
2. Fill a character cell, then a pixel row, then the whole bitmap (`16384`–`22527`).
3. Fill the attributes separately (`22528`–`23295`).
4. Bit patterns: solid, stripes, chequer, dither — seeing how a byte becomes eight pixels.
5. An interactive fill: you pick the attribute and the bit pattern, and the program fills the screen with them.

---

## Part 4 — The same fills in machine code

Machine code from first principles, using the fills from Part 3 so the speed jump is obvious.

1. What machine code is: bytes in RAM, and calling them with `USR` / `RANDOMIZE USR`.
2. The Z80 in small pieces: registers (A, F, BC, DE, HL), `LD`, a counted loop, then `LDIR` when it helps.
3. The same fills as Part 3, rewritten in machine code: bitmap, attributes, and patterned fills.
4. Side by side with the BASIC versions, so the speed increase is measured, not just claimed.
5. Just enough more for later parts: the stack, `CALL` / `RET`, `DJNZ`, and waiting on the frame (`HALT`).

---

## Part 5 — A simple Space Invaders-style game

A small machine-code game that does not need clever sprites. Character cells or simple block graphics are enough.

1. A game loop synced to the frame with `HALT`.
2. Reading the keyboard.
3. The player and bullets.
4. A row of invaders (or a few descending aliens) and their shots.
5. Collisions, score, lives, and game over.
6. The pieces put together, tested as they go in.

This is the bridge to Part 6: once things need to move smoothly over a background, character blocks are no longer enough.

---

## Part 6 — A parameter-driven sprite engine

A generic sprite engine that can drive more than one kind of game, rather than a one-off blit for a single size.

The engine is parameter-driven. The main parameters are:

- **Sprite size** — width and height (in bytes/pixels, not a fixed 16×16 or 24×24).
- **Frames** — how many animation frames, and how pre-shifted copies of each frame are stored so movement is smooth.
- **Scroll steps per call** — how many pixels the sprite moves each time the engine is called (for example 1-pixel or 2-pixel steps).

Around those:

1. Pixel addresses and a row table, so drawing does not recalculate the shuffled screen layout every line.
2. Masked drawing, and saving/restoring the background (including the order of restore when two sprites overlap).
3. Wiring size, frames, and scroll steps as parameters, then a short demo with two different sprite sizes running from the same engine.

Existing sprite-engine notes from the trilogy can be used as a reference later. This part still builds the generic engine from the ideas in Parts 1–5, not by lifting game code.

---

## After this course

This course ends at the generic sprite engine.

Later, once the Atlantis trilogy is finished, the same work moves on to a Java version, and then to a mobile game. Those are separate stages, not part of the six parts above.
