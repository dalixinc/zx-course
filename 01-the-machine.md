# Lesson 1 — The Spectrum: design, memory, and the screen

This is Part 1 of the course. The aim is to have a clear picture of the machine, so that later programs — BASIC, `POKE`, and machine code — sit on solid ground.

Every program is tested in a 48K emulator before it is shown.

## The Z80, ROM and RAM

The 48K Spectrum is built around a Z80, an 8-bit CPU running at 3.5 MHz. It sees a 64K address space, as one stretch of addresses from 0 to 65535.

The first 16K of that, addresses 0 to 16383, is ROM. It holds the BASIC interpreter and the operating system. You can read it; you cannot write to it.

The remaining 48K, addresses 16384 to 65535, is RAM. This is where the screen lives, where the system keeps its variables, and where your programs go.

A 16K Spectrum is the same machine with less RAM. This course uses the 48K.

## Memory map

| Addresses (decimal) | Hex           | What |
|---------------------|---------------|------|
| 0–16383             | `$0000–$3FFF` | ROM (16K) |
| 16384–22527         | `$4000–$57FF` | Screen bitmap, 6144 bytes |
| 22528–23295         | `$5800–$5AFF` | Attributes, 768 bytes |
| 23296–23551         | `$5B00–$5BFF` | Printer buffer |
| 23552 onwards       | `$5C00`…      | System variables, then BASIC and the rest of RAM, up to 65535 |

The two screen areas are ordinary RAM. `PEEK` and `POKE` work on them just as they do on the rest of memory. That is what the program at the end of this lesson uses.

## The ULA

The ULA (Uncommitted Logic Array) is the custom chip that sits beside the Z80. It generates the picture: it reads the bitmap and the attributes, and it paints the border around the screen. It also handles the keyboard, the EAR/MIC tape socket, and the speaker.

While the ULA is fetching screen bytes from the lower 16K of RAM, the CPU is held off if it tries to use the same memory. That delay is called contended memory. It matters later, when we start to count cycles. For now it is enough to know that the screen is not a separate device: it is a region of RAM that the ULA is constantly reading.

## The screen

The display is 256 pixels across and 192 pixels down, one bit per pixel. A byte holds eight horizontal pixels, with bit 7 on the left. A pixel row is therefore 32 bytes.

The bitmap is 32 × 192 = 6144 bytes, at 16384–22527. It is not stored top to bottom. The 192 pixel rows are cut into three *thirds* of 64 rows (2048 bytes) each:

- 16384–18431 — top third, screen Y = 0 to 63
- 18432–20479 — middle third, screen Y = 64 to 127
- 20480–22527 — bottom third, screen Y = 128 to 191

Inside a third, the eight character rows are interleaved by pixel line. First come all eight “line 0”s (the top pixel of each character row), then all eight “line 1”s, and so on. For the top third that looks like this:

```
16384  Y=0      line 0 of character row 0
16416  Y=8      line 0 of character row 1
16448  Y=16     line 0 of character row 2
16480  Y=24     line 0 of character row 3
16512  Y=32     line 0 of character row 4
16544  Y=40     line 0 of character row 5
16576  Y=48     line 0 of character row 6
16608  Y=56     line 0 of character row 7
16640  Y=1      line 1 of character row 0
16672  Y=9      line 1 of character row 1
  ...
18432           start of the middle third (Y=64, 72, 80, ...)
```

So if you fill the bitmap in address order, the first 256 bytes do not paint a solid band at the top of the screen. They paint eight one-pixel lines, eight pixels apart: Y = 0, 8, 16, 24, 32, 40, 48, 56. Then the next 256 bytes thicken those same eight lines by one pixel, and so on. Only after 2048 bytes is the top third solid, and the middle third begins the same way.

That is also why a SCREEN$ loading from tape appears in stripes, third by third.

## Attributes

After the bitmap come 768 attribute bytes, at 22528–23295. There is one byte for each 8×8 character cell, 32 cells across and 24 down, stored in ordinary left-to-right, top-to-bottom row order (unlike the bitmap).

The bits of each attribute byte are:

```
  7       6       5  4  3    2  1  0
  FLASH   BRIGHT  PAPER      INK
```

- INK (bits 0–2) is the colour of the “1” pixels, 0 to 7.
- PAPER (bits 3–5) is the colour of the “0” pixels, 0 to 7.
- BRIGHT (bit 6) makes both INK and PAPER the bright version of that colour, except that black stays black.
- FLASH (bit 7) swaps INK and PAPER several times a second.

The eight colours are: 0 black, 1 blue, 2 red, 3 magenta, 4 green, 5 cyan, 6 yellow, 7 white. A one-page table of INK and PAPER values, including how PAPER sits in the attribute byte, is in [colour-reference.md](colour-reference.md).

One limitation follows from this design: every 8×8 cell can have only two colours (plus bright and flash). Two different INK colours cannot share a cell. That is attribute clash. We will meet it again when we start to move graphics.

## A program that shows the line order

The listing below fills the bitmap in address order, slowly enough to watch. First it gives each character row a different INK colour, so the interleaved lines are easy to tell apart. Then it `POKE`s 255 into every bitmap byte, from 16384 upwards. 255 is eight “1” pixels, so you see the INK colour.

```
1 REM R=character row 0-23
2 REM X=column 0-31
3 REM C=colour, INK 1-7
4 REM A=screen address
10 BORDER 0: PAPER 0: INK 7: CLS
20 REM Colour each character row (INK 1-7, PAPER 0)
30 FOR R=0 TO 23
40 LET C=1+(R-7*INT(R/7))
50 FOR X=0 TO 31
60 POKE 22528+R*32+X,C
70 NEXT X
80 NEXT R
90 REM Fill the bitmap in address order
100 FOR A=16384 TO 22527
110 POKE A,255
120 NEXT A
130 PAUSE 0
```

The source is `01-fill.bas`. A tape image ready to load is `01-fill.tap`.

Line by line:

- **1–4** are remarks only: they name the variables for reading the listing. **R** is the character row, 0 to 23 (not a pixel row). **X** is the column, 0 to 31. **C** is the colour, as an INK value from 1 to 7. **A** is the bitmap address being poked. They do not change what the program does.
- **10** sets a black border and a black paper, then `CLS`. That clears the bitmap (all pixels off) and fills the attributes from the current INK and PAPER, so you start with a black screen.
- **20** is a comment.
- **30–80** walk the 24 character rows. For each row, **40** picks an INK in the range 1 to 7 (blue, red, magenta, green, cyan, yellow, white, then back to blue). Zero is skipped so a line is never black-on-black. **50–70** write that value into all 32 attribute bytes of the row, starting at 22528. Until the bitmap is filled, the pixels are still off, so the screen stays black.
- **90** is a comment.
- **100–120** count through every bitmap address in order and poke 255. This is the part to watch. The first 256 bytes draw eight thin coloured lines in the top third, eight pixels apart. Further bytes thicken those same lines, then the middle third repeats the pattern, then the bottom third. If the bitmap were linear, you would instead see a solid band growing down from the top.
- **130** waits for a key, so the finished screen stays up.

A screenshot taken partway through is in `01-screenshot.png`. It shows the top third after the first pixel-line of each character row has been drawn, and the second pixel-line has started: eight coloured bars (blue, red, magenta, green, cyan, yellow, white, blue) with gaps between them. The middle and bottom thirds are still black. That is address order, not top-to-bottom order.

To run it yourself: start a 48K emulator, load `01-fill.tap`, and type `LOAD ""`. The program auto-starts at line 10. The fill takes a little while; that slowness is the point. There is also a helper script, `tools/run-tap.sh`, which builds the tape and runs it in Fuse under Xvfb.
