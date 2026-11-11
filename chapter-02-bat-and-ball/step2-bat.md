# Lesson 2 — A bat you can move (bat-and-ball, step 2)

This is the second step of the tiny bat-and-ball game in Part 2 of the course. Step 1 got a ball bouncing around the main screen with `PRINT AT`. This step adds a bat at the bottom, which you move with the keys, and makes the ball bounce off it.

The keys are **O** for left and **P** for right. That is the usual convention on the Spectrum (the two keys sit together on the bottom row, under the right hand). Both lowercase and capitals work.

If the ball reaches the bottom and is over the bat, it bounces up. If it misses, it is sent back to its starting place at the top and starts again. That is the simpler of the two obvious choices (the other was to bounce off the bottom anyway, which would have made a miss look the same as a hit). The next step adds a row of bricks. A later step adds `BEEP` sounds; score and lives can come after that. A miss will mean more then.

The ball now uses rows 0 to 20, so it does not print on top of the bat. The bat lives on row 21, is four characters wide, and is drawn as four inverse spaces — a solid bar. `INVERSE` in a `PRINT` list was covered in step 1.

Every program is tested in a 48K emulator before it is shown.

## The new BASIC keywords used here

The keywords from step 1 (`REM`, `BORDER`, `INK`, `PAPER`, `CLS`, `LET`, `PRINT AT`, `IF`/`THEN`, `GO TO`) are used again and are not repeated below. These are the new ones, in the form the 48K Spectrum uses them. A one-line example is given for each.

### INKEY$

`INKEY$` is a function, not a command. It returns a one-character string for the key that is down at that moment, or an empty string (`""`) if no key is down. It does not wait. The program stores the result in `K$` and then looks at it.

Only one key is read at a time. If you press two letter keys together, you will usually get `""`, not both. Caps Shift and Symbol Shift are the exception, because they are used to make a single character.

Letter keys come back in lowercase unless Caps Lock is on, or you are holding Caps Shift. The program therefore checks for both `"o"` and `"O"`, and both `"p"` and `"P"`.

```
10 LET K$=INKEY$
20 IF K$="p" THEN PRINT "right"
```

### FOR and NEXT

`FOR variable=start TO end: ... : NEXT variable` repeats the statements between `FOR` and `NEXT`. An optional `STEP` after `end` sets the increment; if you omit it, the step is 1.

This program uses an empty loop, `FOR I=1 TO 100: NEXT I`, only as a delay, in place of the `PAUSE 5` from step 1. A key press cuts a `PAUSE` short, so holding O or P would have made the ball and the bat race. The `FOR` loop is not interrupted by a key, so the speed stays even while you steer.

The 48K Spectrum has no built-in "wait this many milliseconds" other than `PAUSE`, so a counted loop is the usual way to do a delay that ignores the keyboard.

```
10 FOR I=1 TO 100: NEXT I
```

### AND and OR

`AND` and `OR` join conditions in an `IF`. The statement after `THEN` runs only when the whole condition is true: both sides for `AND`, either side for `OR`.

When you mix them, put brackets around the part that should be worked out first. In the program, the key test is bracketed so it is not mixed up with the edge test: move left only if the key is O *and* the bat is not already at column 0.

```
10 IF (K$="o" OR K$="O") AND B>0 THEN LET B=B-1
```

`NOT` is available too, but is not used here.

### String comparisons

A string variable ends in `$`. Comparisons use the same signs as numbers: `=`, `<>`, `<`, `>`, `<=` and `>=`. They are case-sensitive: `"o"` and `"O"` are not equal. An empty string is `""`.

```
10 IF K$="p" OR K$="P" THEN LET B=B+1
```

## The listing

The ball still starts at row 5, column 5, and steps one character diagonally, as in step 1. The bat starts at column 14, which is roughly in the middle of the 32-column row (it occupies columns 14 to 17). From that start, the first time the ball reaches the bottom it is at column 20, just to the right of the bat, so you have to move right with P to catch it. A miss sends it back to row 5, column 5.

The old ball is rubbed out with a space, as before. The bat is rubbed out and redrawn only when it actually moves, so it does not flicker on every pass of the loop.

```
1 REM R=ball row 0-20
2 REM X=ball column 0-31
3 REM DR=row step +1 or -1
4 REM DX=column step +1 or -1
5 REM B=bat left column 0-28
6 REM W=bat width in characters
7 REM K$=key from INKEY$
8 REM I=delay loop counter
10 BORDER 0: PAPER 0: INK 7: CLS
20 LET R=5: LET X=5
30 LET DR=1: LET DX=1
32 LET W=4: LET B=14
35 PRINT AT 21,B; INVERSE 1;"    "
40 PRINT AT R,X;"O"
50 FOR I=1 TO 100: NEXT I
60 PRINT AT R,X;" "
65 LET K$=INKEY$
70 IF (K$="o" OR K$="O") AND B>0 THEN PRINT AT 21,B;"    ": LET B=B-1: PRINT AT 21,B; INVERSE 1;"    "
80 IF (K$="p" OR K$="P") AND B<32-W THEN PRINT AT 21,B;"    ": LET B=B+1: PRINT AT 21,B; INVERSE 1;"    "
90 IF R+DR<0 THEN LET DR=-DR
100 IF R+DR>20 THEN GO TO 200
110 IF X+DX<0 THEN LET DX=-DX
120 IF X+DX>31 THEN LET DX=-DX
130 LET R=R+DR
140 LET X=X+DX
150 GO TO 40
200 IF X>=B AND X<=B+W-1 THEN LET DR=-DR: GO TO 110
210 LET R=5: LET X=5: LET DR=1: LET DX=1
220 GO TO 40
```

The source is `step2-bat.bas`. A tape image ready to load is `step2-bat.tap`.

## Line by line

- **1–8** name the variables. **R** and **X** are the ball's row and column, now 0 to 20 and 0 to 31. **DR** and **DX** are the steps, `+1` or `-1`, as in step 1. **B** is the column of the left-hand end of the bat, 0 to 28 when the width is 4. **W** is that width. **K$** is the key just read, or empty. **I** is only used in the delay loop.
- **10** sets a black border and paper, white ink, and clears the screen, as in step 1.
- **20–30** place the ball and give it a down-and-right direction, the same start as step 1.
- **32** sets a four-character bat and puts it at column 14.
- **35** draws the bat on row 21 as four inverse spaces. The four spaces in the quotes must match `W`. `INVERSE` here lasts only for this `PRINT`, so it does not affect the ball.
- **40** prints the `O` at the current row and column.
- **50** waits by counting to 100, so you can see the ball (and so a held key does not speed the game up).
- **60** prints a space at the same place, which rubs the `O` out.
- **65** reads the keyboard into `K$`.
- **70** if the key is O and the bat is not already at the left edge, rubs the old bat out with four ordinary spaces, moves `B` one column left, and draws the bat in the new place.
- **80** does the same to the right, stopping when `B` reaches `32-W` (column 28 when `W` is 4), so the bat's right-hand end stays on the screen.
- **90** reverses `DR` if the next row would be above the top.
- **100** if the next row would be the bat's row, jumps to the hit-or-miss check at line 200.
- **110–120** reverse `DX` if the next column would be off the left or right edge.
- **130–140** take the step, now known to be on the screen (or, after a bounce, heading back from the bat).
- **150** goes back to print the ball in its new place.
- **200** if the ball's column is on the bat (`X` from `B` to `B+W-1`), reverses `DR` and goes to line 110 to finish the move — a bounce off the bat.
- **210–220** otherwise it was a miss: put the ball back at row 5, column 5, going down and right, and jump to line 40 to print it there. The bat is left where it is.

If the ball hits a top corner, both `DR` and `DX` reverse, as in step 1.

## Limitations you will notice

BASIC is slow, and this is more work per loop than step 1, so the animation is a little more laboured. That is useful: it is one of the reasons the course later looks at machine code.

The ball still flickers, because it is printed, delayed, and then rubbed out. The bat is steadier, because it is only redrawn when it moves, but you may catch a brief flash of a gap as the old bar is rubbed out and the new one is drawn.

`INKEY$` is looked at only once per loop, after the delay, so a very short tap can be missed. Hold O or P to steer. It also reads only one key at a time, so there is no diagonal "two keys at once" to worry about here, but the same limit will matter later if you want more than left and right.

A screenshot taken while the ball is about to meet the bat is in `step2-bat.png`.

To run it yourself: start a 48K emulator, load `step2-bat.tap`, and type `LOAD ""`. The program auto-starts at line 10 and runs until you break it (on a real machine, Caps Shift and Space; in Fuse, often F4 or the menu). Hold O to move left and P to move right. The helper script `tools/run-tap.sh chapter-02-bat-and-ball/step2-bat.bas` (from the course root) builds the tape and runs it in Fuse under Xvfb. To send keys while it captures, see [tools/README.md](../tools/README.md) (`KEY_HOLD=p` holds P, for example).

## Try this

Change the `100` on line 50 to `50` to speed the game up, or to `200` to slow it down. Run it again and see which you prefer.

Or start the bat further left, so the first catch is a longer run to the right: `32 LET W=4: LET B=6`. You will need to hold P for longer to get under the ball at column 20.

If you change `W`, change the four spaces (and the four spaces used to rub the bat out) to the same length, and remember the right-hand limit is `32-W`.
