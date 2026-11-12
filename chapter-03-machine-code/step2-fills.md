# Chapter 3, step 2 — Screen fills in BASIC, timed

Step 1 showed where the screen lives: the bitmap at 16384 to 22527 and the attributes at 22528 to 23295. This step fills both of them from BASIC, one `POKE` at a time, and times each fill with the `FRAMES` counter. These two numbers are the ones the machine-code fills later in the chapter have to beat.

The program clears the screen to black, then pokes the pattern `BIN 10101010` (170) into every bitmap byte. The fill is slow enough to watch, and it does not paint from top to bottom: it lays down thin stripes across the top third of the screen, then fills in between them, then does the same in the middle third and the bottom third. The section "Why the bitmap fills in stripes" below explains why. Then the program pokes 14 (blue paper, yellow ink) into every attribute byte, and the whole screen turns yellow and blue, a row of cells at a time. At the end it prints how many frames each fill took, and the same time in seconds.

Step 1 only read system variables. This step writes one on purpose: it sets `FRAMES` to zero before each fill, so the count afterwards is the time the fill took.

No machine code yet. This step is BASIC only.

Every program is tested in a 48K emulator before it is shown.

## The new BASIC keywords used here

`POKE` and `PEEK` are as in step 1, and `FOR`, `NEXT`, `GO SUB` and `PAUSE 0` are as in Chapter 2. Two things are new: the `STEP` part of `FOR`, and poking a system variable.

### FOR ... STEP

`FOR v=first TO last STEP s` counts in steps of `s` instead of 1. The step can be any number, including a fraction or a negative number. With a negative step the loop counts down, and it stops once the variable has gone below `last`.

```
10 FOR N=10 TO 1 STEP -3
20 PRINT N
30 NEXT N
```

This prints 10, 7, 4 and 1.

`STEP` is handy on the screen, because the bytes of one character cell are 256 apart (see below). This fills the top left character cell, its eight pixel lines from 16384 down to 16384+7*256:

```
10 FOR A=16384 TO 18176 STEP 256
20 POKE A,255
30 NEXT A
```

The program in this step does not use `STEP`. It is here because it makes the 256-byte spacing of a character cell easy to see.

### Writing a system variable: FRAMES as a stopwatch

`FRAMES`, at 23672, is a three-byte counter, low byte first. The ROM adds one to it 50 times a second. Step 1 read it with three `PEEK`s. You can also `POKE` it, and the manual does not mark it as unsafe to change. Setting all three bytes to zero starts a stopwatch:

```
10 POKE 23672,0: POKE 23673,0: POKE 23674,0
20 PAUSE 50
30 PRINT PEEK 23672+256*PEEK 23673
```

`PAUSE 50` waits 50 frames, one second, and the program prints 50.

The low byte is poked first on purpose. If the counter ticks just after the first `POKE`, the low byte goes from 0 to 1 and nothing carries into the other two bytes, which are then set to zero. Poked the other way round, a tick between the `POKE`s could carry into a byte you have already cleared.

Reading it back safely needs a little care, as step 1 mentioned. If the low byte wraps from 255 to 0 between the two `PEEK`s, the answer is out by 256. The program reads the high byte, then the low byte, then the high byte again, and starts again if the high byte has changed. A fill takes at most a few thousand frames, so the third byte stays at zero and the program does not read it.

## Why the bitmap fills in stripes

You saw this in Chapter 1. The program pokes the bitmap in address order, 16384, 16385, 16386 and so on, but the screen does not fill from the top down. The reason is the order in which the bitmap bytes sit on the screen.

The bitmap is 6144 bytes: 192 pixel lines of 32 bytes each. Each byte is eight pixels across. The screen is also 24 rows of character cells, each cell 8 pixels high. The bytes are not stored one pixel line after another. They are grouped like this:

- The screen is split into three thirds, each 8 character rows high. Each third has its own 2048 bytes: 16384 for the top third, 18432 for the middle, 20480 for the bottom.
- Inside a third, the first 256 bytes are the top pixel line of each of its eight character rows: 32 bytes for row 0, then 32 for row 1, and so on to row 7.
- The next 256 bytes are the second pixel line of each of those eight character rows, and so on, down to the eighth pixel line.

So the address of a bitmap byte is:

```
16384 + 2048*third + 256*line + 32*row + column
```

where `third` is 0 to 2, `line` is the pixel line inside the character cell (0 to 7), `row` is the character row inside the third (0 to 7), and `column` is 0 to 31. For character row `R` (0 to 23) of the whole screen, `third` is `INT (R/8)` and `row` is `R-8*INT (R/8)`.

That is why the fill looks the way it does. The first 32 pokes draw a thin line across the top of character row 0. The next 32 draw one across the top of row 1, a whole cell lower. After 256 pokes the top third has eight thin lines, one at the top of each character row. The next 256 pokes add the second line of each cell, and so on. After 2048 pokes the top third is solid, and the same thing starts again in the middle third.

This short program uses the formula to fill one character cell, row 10, column 5, and colours it with an attribute:

```
10 LET R=10: LET X=5
20 FOR P=0 TO 7
30 POKE 16384+2048*INT (R/8)+256*P+32*(R-8*INT (R/8))+X,255
40 NEXT P
50 POKE 22528+32*R+X,16+6
60 PRINT AT 0,0;16384+2048*INT (R/8)+32*(R-8*INT (R/8))+X
70 PAUSE 0
```

It prints 18501, the address of the top line of the cell, and draws a solid yellow cell on red paper (16+6 is `8*2+6`: paper 2, ink 6). Only the ink shows, because every pixel is set.

The attributes are simpler. They are 24 rows of 32 bytes, in order, so the attribute of character row `R`, column `X` is at `22528+32*R+X`. The attribute fill goes from the top down, a row at a time.

In binary, the layout is easier to see. A bitmap address is `010TTLLL RRRCCCCC`: `TT` is the third, `LLL` the pixel line, `RRR` the character row inside the third, and `CCCCC` the column. Counting up through the addresses changes the column fastest, then the row, then the pixel line, then the third. The hardware was designed this way so the ULA could fetch the screen cheaply, and it will matter again when we draw in machine code: moving down one pixel line inside a cell is adding 256, which on the Z80 is just adding 1 to the high byte.

## The listing

```
1 REM A=screen address being filled
2 REM H=FRAMES high byte
3 REM L=FRAMES low byte
4 REM F=frames since FRAMES was zeroed
5 REM B=frames for the bitmap fill
6 REM C=frames for the attribute fill
10 BORDER 0: PAPER 0: INK 7: CLS
20 GO SUB 800
30 FOR A=16384 TO 22527
40 POKE A,170
50 NEXT A
60 GO SUB 900: LET B=F
70 GO SUB 800
80 FOR A=22528 TO 23295
90 POKE A,14
100 NEXT A
110 GO SUB 900: LET C=F
120 PRINT AT 18,0;"BASIC FILLS     FRAMES  SECONDS "
130 PRINT AT 19,0;"BITMAP  6144";TAB 16;B;TAB 24;B/50;TAB 31;" "
140 PRINT AT 20,0;"ATTRS    768";TAB 16;C;TAB 24;C/50;TAB 31;" "
150 PRINT AT 21,0;"                                "
160 PAUSE 0
170 STOP
800 POKE 23672,0: POKE 23673,0: POKE 23674,0
810 RETURN
900 LET H=PEEK 23673: LET L=PEEK 23672
910 IF PEEK 23673<>H THEN GO TO 900
920 LET F=L+256*H
930 RETURN
```

The source is `step2-fills.bas`. A tape image ready to load is `step2-fills.tap`.

## What it showed in Fuse

These figures are from a 48K Fuse at normal speed, with the program loaded from the tape above. The program was run twice, and gave the same figures both times.

| Fill | Bytes | Frames | Seconds |
|------|------:|-------:|--------:|
| Bitmap, 16384–22527 | 6144 | 2468 | 49.36 |
| Attributes, 22528–23295 | 768 | 325 | 6.5 |

That is about 8 milliseconds for every byte, for both fills (2468/6144 and 325/768 are both about 0.4 of a frame). The bitmap has eight times as many bytes, so it takes about eight times as long. Each 256-byte pass across one third, one pixel line of eight character rows, takes about two seconds, which is why the stripes are so easy to watch.

`step2-fills.png` was taken about halfway through the bitmap fill, roughly 25 seconds in. The top third is finished, and the middle third has the first four pixel lines of each of its eight character rows, with gaps between them where the other four will go. `step2-fills-result.png` is the end: blue paper and yellow ink everywhere, and the two times printed over it.

The Chapter 2 wrap-up gave 2446 frames for the bitmap and 341 for the attributes. Those were measured with a different listing, and the figures here are close to them, not the same. Small changes to the BASIC around a loop change its speed. For example, the six `REM` lines at the top of this listing cost time. With lines 1 to 6 taken out, and nothing else changed, the same program measured 2322 frames (46.44 seconds) for the bitmap and 306 (6.12 seconds) for the attributes. Every time `NEXT` goes back round the loop, the ROM finds the line it has to go back to by searching from the start of the program, one line at a time, so every line above the loop slows it down. The listing keeps its `REM` lines, because they are the course's rule and because the times in the table are the ones for the program as printed.

## Line by line

- **1–6** name the variables.
- **10** sets black border and paper, white ink, and clears the screen.
- **20** zeroes `FRAMES` (the subroutine at 800).
- **30–50** poke 170, `BIN 10101010`, into every bitmap byte, in address order. Each byte becomes four ink pixels and four paper pixels, so the screen fills with thin vertical lines.
- **60** reads `FRAMES` (the subroutine at 900) and keeps it in `B`, the bitmap time.
- **70** zeroes `FRAMES` again.
- **80–100** poke 14 into every attribute byte: `8*1+6`, paper 1 (blue) and ink 6 (yellow), not bright, not flashing.
- **110** reads `FRAMES` again and keeps it in `C`, the attribute time.
- **120–150** print the table over the bottom of the picture. The text uses the permanent colours from line 10, white on black. `TAB` lines the columns up, and the last `TAB 31;" "` overwrites the rest of each line with spaces. Line 150 blanks row 21 so there is a gap between the table and the stripes below it.
- **160** waits for a key. Without it the program would end, and the report at the bottom ("0 OK") would clear the bottom two rows of the picture.
- **170** stops, so the program does not run on into the subroutines.
- **800–810** set the three bytes of `FRAMES` to zero, low byte first.
- **900–930** read the two low bytes of `FRAMES` into `F`, again if the high byte changed during the read.

## Limitations you will notice

It is slow. Nearly fifty seconds to fill the bitmap, over six to fill the attributes, and that is with the simplest loop there is: one `POKE` and one `NEXT` for each byte. About 8 milliseconds a byte is roughly 28,000 Z80 clock cycles, at 3.5 MHz, for a job the Z80 can do with a handful of instructions. The rest is the interpreter: finding the line, decoding the `POKE`, turning the five-byte floating-point `A` into an address, adding one to it, comparing it with the limit, and finding the line again.

The time depends on the BASIC around the loop, as the `REM` measurement shows. A loop at the top of a small program is faster than the same loop at the bottom of a long one.

The pattern and the colours are fixed in lines 40 and 90. The next step asks the user for them, and fills the screen with their choice, at the same slow speed.

The machine-code version of these two loops comes later in this chapter. It will be timed with the same `FRAMES` stopwatch, against 2468 and 325 frames.

## Try this

- Change 170 in line 40 to 255, or to `BIN 11001100`, and run it again.
- Change 14 in line 90. `8*paper+ink` gives the value; add 64 for bright and 128 for flashing.
- Take lines 1 to 6 out and run it again. The two times drop, as in the measurement above.
- Fill just the top line of character row 1 (32 bytes): `FOR A=16416 TO 16447: POKE A,255: NEXT A`. The line appears a whole character cell below the top of the screen, not at the very top.
