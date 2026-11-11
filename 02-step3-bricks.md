# Lesson 2 — Coloured bricks (bat-and-ball, step 3)

This is the third step of the tiny bat-and-ball game. Step 2 added a bat you move with O and P, and the ball bounced off it or restarted at the top on a miss. This step puts a wall of coloured bricks near the top, teaches how PAPER colour is stored in the attribute byte, and uses that colour as the collision test.

There are three rows of bricks, on rows 2, 3 and 4. Each row is a different PAPER colour: red, green and yellow. Each character cell is one brick, drawn as a space with that paper colour — a solid block, with no user-defined graphic. (A later lesson will replace the ball's letter `O` with a UDG; the bricks stay as coloured spaces for now.)

When the ball is about to move into a cell, the program reads that cell's attribute with `ATTR`. If the paper colour is not black, there is a brick there. The brick is rubbed out (the cell is printed as a space with black paper) and `DR` is reversed, so the ball bounces. There is no separate list of brick positions: the colours on the screen *are* the map. Score, lives and `BEEP` come in the next step.

The bat also gains a little steering. If the ball hits the left-hand end, `DX` is set to `-1`; if it hits the right-hand end, `DX` is set to `+1`; if it hits one of the two middle cells, `DX` is left alone. You can already send the ball up to a chosen part of the wall.

The colour numbers and the layout of the attribute byte are in [colour-reference.md](colour-reference.md), and were introduced in [Lesson 1](01-the-machine.md). This step is where they start to do work in a program.

Every program is tested in a 48K emulator before it is shown.

## The new BASIC keywords used here

The keywords from steps 1 and 2 (`REM`, `BORDER`, `INK` and `PAPER` as statements, `CLS`, `LET`, `PRINT AT`, `IF`/`THEN`, `AND`/`OR`, `INKEY$`, `GO TO`, and the empty `FOR`/`NEXT` delay) are used again and are not repeated below. These are the new ones, or the ones used here in a new way.

### FOR and NEXT (with a body, and a loop inside a loop)

In step 2, `FOR I=1 TO 100: NEXT I` was only a delay: there was nothing between `FOR` and `NEXT`. Here the same keywords draw the wall. The body can be any statements, including another `FOR` loop.

The outer loop walks the brick rows in `L`, from 2 to 4. For each row, the inner loop walks the columns in `C`, from 0 to 31, and prints one brick. The inner `NEXT C` must come before the outer `NEXT L`. An optional `STEP` after `TO` sets the increment; it is not used here, so the step is 1.

```
10 FOR L=2 TO 4
20 FOR C=0 TO 31
30 PRINT AT L,C; PAPER 2;" "
40 NEXT C
50 NEXT L
```

### PAPER (and INK) inside PRINT

`PAPER n` and `INK n` can appear as items in a `PRINT` list, as mentioned in step 1. They last only until the end of that statement (or until another such item in the same statement), and they do not change the permanent `INK` and `PAPER` set by the statements at the start of the program. `n` is 0 to 7, or 8 (transparent) or 9 (contrast).

A space has no ink pixels, so what you see is the paper colour. `PRINT AT 2,0; PAPER 2;" "` paints one cell solid red, and writes that colour into the attribute file. The permanent paper is still black, so the ball and the empty playfield stay white on black.

The three rows use `P=2*(L-1)`: row 2 gets paper 2 (red), row 3 gets paper 4 (green), row 4 gets paper 6 (yellow). Those values are in the [colour reference](colour-reference.md).

```
10 PRINT AT 2,0; PAPER 2;" "
```

### ATTR

`ATTR(line,column)` is a function. It returns the attribute byte of that character cell, as a number 0 to 255. `line` is 0 to 23, `column` is 0 to 31. A cell off the screen gives the error `B Integer out of range`, which is why the program bounces off the edges *before* it asks `ATTR` about the cell ahead.

The byte is the one described in Lesson 1:

```
  128 * FLASH  +  64 * BRIGHT  +  8 * PAPER  +  INK
```

In this program FLASH and BRIGHT are 0, and the ink is 7 (white), so the value is simply `8*PAPER+7`. An empty playfield cell is paper 0, ink 7, which is 7. A red brick is paper 2, ink 7, which is `16+7=23`. A green brick is `32+7=39`. A yellow brick is `48+7=55`.

```
10 LET A=ATTR(4,10)
```

### INT

`INT(number)` is a function that returns the integer part of a number, towards zero for positives: `INT(2.875)` is 2. The program uses it to get the paper colour out of the attribute byte: `INT(A/8)`. For the values above, `INT(7/8)` is 0 (empty), `INT(23/8)` is 2 (red), `INT(39/8)` is 4 (green), `INT(55/8)` is 6 (yellow). If the result is not 0, the cell ahead is a brick.

This only equals PAPER while FLASH and BRIGHT are 0. A bright attribute would add 8 to `INT(A/8)`, because BRIGHT lives in bit 6, which is the 64s, and `64/8=8`. The bricks are drawn without BRIGHT, so the test stays simple.

```
10 IF INT(A/8)<>0 THEN PRINT "brick"
```

## The listing

The ball still starts at row 5, column 5, just under the wall, and goes down first, as in step 2. The first time it reaches the bottom it is at column 20, so you still have to move right with P to catch it. After a bounce off the bat it travels up into the wall, a brick disappears, and it comes back down.

```
1 REM R=ball row 0-20
2 REM X=ball column 0-31
3 REM DR=row step +1 or -1
4 REM DX=column step +1 or -1
5 REM B=bat left column 0-28
6 REM W=bat width in characters
7 REM K$=key from INKEY$
8 REM I=delay loop counter
9 REM L=brick row 2-4
10 REM C=brick column 0-31
11 REM P=PAPER colour of a brick row
12 REM A=ATTR of the cell ahead
20 BORDER 0: PAPER 0: INK 7: CLS
30 LET R=5: LET X=5
40 LET DR=1: LET DX=1
50 LET W=4: LET B=14
60 FOR L=2 TO 4
70 LET P=2*(L-1)
80 FOR C=0 TO 31
90 PRINT AT L,C; PAPER P;" "
100 NEXT C
110 NEXT L
120 PRINT AT 21,B; INVERSE 1;"    "
130 PRINT AT R,X;"O"
140 FOR I=1 TO 100: NEXT I
150 PRINT AT R,X;" "
160 LET K$=INKEY$
170 IF (K$="o" OR K$="O") AND B>0 THEN PRINT AT 21,B;"    ": LET B=B-1: PRINT AT 21,B; INVERSE 1;"    "
180 IF (K$="p" OR K$="P") AND B<32-W THEN PRINT AT 21,B;"    ": LET B=B+1: PRINT AT 21,B; INVERSE 1;"    "
190 IF R+DR<0 THEN LET DR=-DR
200 IF R+DR>20 THEN GO TO 300
210 IF X+DX<0 THEN LET DX=-DX
220 IF X+DX>31 THEN LET DX=-DX
230 LET A=ATTR(R+DR,X+DX)
240 IF INT(A/8)<>0 THEN GO TO 400
250 LET R=R+DR
260 LET X=X+DX
270 GO TO 130
300 IF X<B OR X>B+W-1 THEN GO TO 360
310 IF X=B THEN LET DX=-1
320 IF X=B+W-1 THEN LET DX=1
330 LET DR=-DR
340 GO TO 210
360 LET R=5: LET X=5: LET DR=1: LET DX=1
370 GO TO 130
400 PRINT AT R+DR,X+DX; PAPER 0;" "
410 LET DR=-DR
420 GO TO 210
```

The source is `02-bricks.bas`. A tape image ready to load is `02-bricks.tap`.

## Line by line

- **1–12** name the variables. **R**, **X**, **DR**, **DX**, **B**, **W**, **K$** and **I** are the same as in step 2, with the ball now on rows 0 to 20 so it does not sit on the bat. **L** and **C** are the row and column used only while the wall is drawn. **P** is the paper colour of that brick row. **A** is the attribute of the cell the ball is about to enter.
- **20** sets a black border and paper, white ink, and clears the screen. After `CLS`, every cell's attribute is `8*0+7=7`.
- **30–50** place the ball, give it a down-and-right direction, and set up a four-character bat at column 14, as in step 2.
- **60–110** draw the wall. For each row `L` from 2 to 4, line 70 picks the paper colour `2*(L-1)`, and the inner loop prints a space in that colour in every column. That writes `8*P+7` into each of those attribute cells.
- **120** draws the bat on row 21.
- **130–160** print the ball, wait with the same delay loop as step 2, rub the ball out, and read a key.
- **170–180** move the bat with O and P, as in step 2.
- **190** reverses `DR` if the next row would be above the top.
- **200** if the next row would be the bat's row, jumps to the bat check at line 300.
- **210–220** reverse `DX` if the next column would be off the left or right edge. The coordinates of the cell ahead are now on the screen, so `ATTR` is safe.
- **230–240** read that cell's attribute. If `INT(A/8)` is not 0, the paper is not black, so it is a brick, and the program jumps to line 400.
- **250–270** otherwise take the step and go back to print the ball in its new place.
- **300** if the ball is not over the bat, it is a miss: jump to line 360, which restarts it at row 5, column 5, as in step 2.
- **310–320** set the bounce angle: the left-hand cell of the bat (`X=B`) forces `DX=-1`, the right-hand cell (`X=B+W-1`) forces `DX=1`. The two middle cells leave `DX` as it is.
- **330–340** reverse `DR` and go to line 210, so the wall checks and a possible brick test run on the new direction before the step is taken.
- **400–420** a brick was hit. Print a space with paper 0 at the cell ahead, which restores attribute 7 and leaves a hole. Reverse `DR` and go to line 210, so the ball moves away rather than onto the cell it just cleared.

Once every brick has been rubbed out, `INT(A/8)` is 0 everywhere in the playfield, and the ball will bounce off the top of the screen again, as it did in step 1.

## Limitations you will notice

BASIC is still slow, and there is more work per loop than in step 2, so the animation is a little more laboured. The ball still flickers; the wall does not, because it is only drawn at the start, and a brick is only redrawn when it is cleared.

The hit test looks at the single cell the ball is about to enter, `ATTR(R+DR,X+DX)`. If a one-cell gap has opened, the ball can slip through it on a diagonal, because the destination cell is empty even though the cell directly above is not. That is a limit of this simple test, not a bug in `ATTR`. A later, tighter test could also look at `ATTR(R+DR,X)`.

`INKEY$` is still read only once per loop, after the delay, so you should hold O or P to steer, as in step 2.

A screenshot taken just after a yellow brick was cleared, with the ball bouncing off it, is in `02-bricks-screenshot.png`.

To run it yourself: start a 48K emulator, load `02-bricks.tap`, and type `LOAD ""`. The program auto-starts at line 10 (the last of the remarks; the first statement is line 20) and runs until you break it (on a real machine, Caps Shift and Space; in Fuse, often F4 or the menu). Hold O to move left and P to move right, and try to catch the ball on the left end, the middle, or the right end to see the angle change. The helper script `tools/run-tap.sh 02-bricks.bas` builds the tape and runs it in Fuse under Xvfb. To send keys while it captures, see `tools/README.md`.

## Try this

Change the colours. For a traffic-light wall (red, yellow, green from the top), replace line 70 with three tests:

```
70 IF L=2 THEN LET P=2
71 IF L=3 THEN LET P=6
72 IF L=4 THEN LET P=4
```

Or change the `2 TO 4` on line 60 to `1 TO 3` to sit the wall one row higher, and see how the first bounce off the bat meets it.

If you change the delay on line 140, the feel of both the ball and the bat will change, as in step 2.
