# Chapter 2, step 5 — A little random deflection

This step takes the UDG-ball game from [step 4](step4-udg-ball.md) and gives the bounce a little of the unevenness of the real world. Until now the ball has always moved one row and one column at a time, a perfect diagonal. That carves a straight diagonal tunnel through the wall, and the next bounce follows the same line. Here, on some bounces, the path is allowed to deviate — not wildly, just enough to stop every rally looking the same.

The design is deliberately small, so it stays robust in character-cell BASIC:

- The bat's ends still steer, as in step 3: the left-hand cell sets `DX=-1`, the right-hand cell sets `DX=1`. Those hits are never randomised, so you still have a say in the direction.
- After a hit on the middle of the bat, or after a brick, there is a chance `Q` (0.2 in the listing) that `DX` is set to 0. The ball then travels straight up or down for that one leg — a slight change, not a new speed or a new angle.
- If `DX` is already 0 when a middle-bat or brick bounce happens, it is always set back to `+1` or `-1`, chosen with `INT(RND*2)`. That stops a vertical rally from bouncing for ever between the bat and the top, or between two bricks in the same column.
- Side walls and the top of the screen are ordinary reflections, as before. A miss still restarts at row 5, column 5.

Flipping `DX` on a whim would also break the diagonal, but it is a bigger change of heading (up-right becomes up-left). Setting `DX=0` for one leg is the milder nudge, and the forced return to a diagonal keeps the ball from getting stuck. Both stay inside the same three values of `DX` (`-1`, `0`, `+1`) and the same bounds: columns 0 to 31, rows 0 to 20.

`BEEP` sounds come in the next step. Score and lives can come after that.

Every program is tested in a 48K emulator before it is shown.

## The new BASIC keywords used here

The keywords from steps 1 to 4 are used again and are not repeated below. `INT` was introduced in step 3, to take the paper colour out of an attribute byte. It is used again here as part of a common idiom, and is described with `RND`.

### RANDOMIZE

`RANDOMIZE` sets the seed for the random-number generator. With no number, as in this program, the seed is taken from the frame counter (the number of television frames since the machine was switched on), so each run gets a different sequence.

`RANDOMIZE n` uses the number `n` as the seed instead. The same `n` gives the same sequence every time, which is useful if you want a rally you can repeat. `RANDOMIZE 0` is the same as `RANDOMIZE` with no number: it uses the frame counter.

Call it once at the start, not every time you need a random value. The generator then keeps its own state as you use `RND`.

```
10 RANDOMIZE
```

### RND

`RND` is a function with no argument. It returns a number that is at least 0 and less than 1, and the next call returns the next number in the sequence. A test such as `IF RND<0.2` is therefore true about one time in five.

There is no `RND(n)` form that returns an integer in a range. To get a whole number from 0 to `n-1`, use the idiom below.

```
10 IF RND<0.2 THEN PRINT "nudge"
```

### INT(RND*n)

`INT(number)` returns the integer part of a number, as in step 3. `INT(RND*n)` is the usual way to get a random whole number in 0, 1, …, `n-1`. `INT(RND*2)` is 0 or 1. The program turns that into a direction with `2*INT(RND*2)-1`, which is `-1` or `+1`.

```
10 LET DX=2*INT(RND*2)-1
```

## The listing

`RANDOMIZE` is called once, just after `CLS`. `Q` is set to 0.2. The rest of the setup — the UDG, the wall, the bat — is the same as step 4. After a middle-bat or brick bounce, the new lines at 430–450 decide whether `DX` stays as it is, becomes 0, or (if it was already 0) returns to a diagonal.

```
1 REM R=ball row 0-20
2 REM X=ball column 0-31
3 REM DR=row step +1 or -1
4 REM DX=column step +1, 0 or -1
5 REM B=bat left column 0-28
6 REM W=bat width in characters
7 REM K$=key from INKEY$
8 REM I=delay loop counter
9 REM L=brick row 2-4
10 REM C=brick column 0-31
11 REM P=PAPER colour of a brick row
12 REM A=ATTR of the cell ahead
13 REM N=byte 0-7 of the ball UDG
14 REM D=one row of the ball graphic
15 REM Q=chance of a slight deflection
20 BORDER 0: PAPER 0: INK 7: CLS
21 RANDOMIZE
30 LET R=5: LET X=5
40 LET DR=1: LET DX=1
50 LET W=4: LET B=14
51 LET Q=0.2
52 RESTORE 500
54 FOR N=0 TO 7
56 READ D
58 POKE USR "a"+N,D
59 NEXT N
60 FOR L=2 TO 4
70 LET P=2*(L-1)
80 FOR C=0 TO 31
90 PRINT AT L,C; PAPER P;" "
100 NEXT C
110 NEXT L
120 PRINT AT 21,B; INVERSE 1;"    "
130 PRINT AT R,X;CHR$ 144
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
310 IF X=B THEN LET DX=-1: LET DR=-DR: GO TO 210
320 IF X=B+W-1 THEN LET DX=1: LET DR=-DR: GO TO 210
330 LET DR=-DR
340 GO TO 430
360 LET R=5: LET X=5: LET DR=1: LET DX=1
370 GO TO 130
400 PRINT AT R+DR,X+DX; PAPER 0;" "
410 LET DR=-DR
420 GO TO 430
430 IF DX=0 THEN GO TO 440
432 IF RND>=Q THEN GO TO 210
434 LET DX=0
436 GO TO 210
440 LET DX=2*INT(RND*2)-1
450 GO TO 210
500 DATA BIN 00111100, BIN 01111110, BIN 11111111, BIN 11111111
510 DATA BIN 11111111, BIN 11111111, BIN 01111110, BIN 00111100
```

The source is `step5-random.bas`. A tape image ready to load is `step5-random.tap`.

## Line by line

- **1–15** name the variables. **1–14** are as in step 4, except that **DX** may now also be 0. **Q** is the chance of a slight deflection, between 0 and 1.
- **20** sets the colours and clears the screen, as before.
- **21** seeds the generator from the frame counter, once.
- **30–50** place the ball and the bat, as in step 4.
- **51** sets `Q` to 0.2, so about one middle-bat or brick bounce in five will start a straight leg.
- **52–120** define the ball UDG, draw the wall and the bat, as in step 4.
- **130–270** are the game loop from step 4: print the ball, delay, rub it out, read O and P, bounce off the top and the sides, test for a brick with `ATTR`, then take the step. When `DX` is 0, `X+DX` is just `X`, so the side-wall tests do nothing and `ATTR` looks at the cell directly above or below.
- **300** if the ball is not over the bat, it is a miss: restart at row 5, column 5, going down and right, as before.
- **310–320** are the bat-end steering from step 3. The left-hand cell forces `DX=-1`, the right-hand cell forces `DX=1`, `DR` is reversed, and the program goes back to the wall checks *without* visiting the random nudge, so a carefully aimed edge shot is not overwritten.
- **330–340** a hit on one of the two middle cells: reverse `DR` and go to the nudge at line 430.
- **400–420** a brick was hit: rub it out, reverse `DR`, and go to the same nudge.
- **430–436** if `DX` is not 0, most of the time (`RND>=Q`) it is left alone. About one time in five, `DX` is set to 0, and the next leg is straight up or down. Then go to the wall checks with the new `DX`.
- **440–450** if `DX` is already 0, it is always set back to `-1` or `+1` with `2*INT(RND*2)-1`, and the next leg is a diagonal again.
- **500–510** are the eight bytes of the ball graphic, as in step 4.

## Limitations you will notice

The ball still moves a whole character cell at a time, and `DX` still has only three values, so this is a small nudge rather than a true bounce angle. A later part of the course looks at moving things by pixels.

Because a straight leg is only started on a bounce, and is always ended on the next middle-bat or brick bounce, you will not see the ball travel vertically for ever. It may go straight from the bat to the wall and back, or from the bat up to a brick, and then a diagonal is restored. That is enough to punch a hole that is not on the old diagonal, which was the point.

The chance `Q=0.2` is a taste. If it is much larger, the path feels twitchy; if it is much smaller, you may watch several rallies before you notice a change. `RANDOMIZE` at the start means two runs will not match.

The flicker of the ball, the need to hold O or P, and the simple `ATTR` test (including the chance of slipping through a one-cell gap on a diagonal) are unchanged from earlier steps.

A screenshot taken just after a yellow brick was cleared by a straight-up leg, with the ball leaving on a diagonal again, is in `step5-random.png`.

To run it yourself: start a 48K emulator, load `step5-random.tap`, and type `LOAD ""`. The program auto-starts at line 10 (the last of the remarks; the first statement is line 20) and runs until you break it (on a real machine, Caps Shift and Space; in Fuse, often F4 or the menu). The helper script `tools/run-tap.sh chapter-02-bat-and-ball/step5-random.bas` (from the course root) builds the tape and runs it in Fuse under Xvfb. To send keys while it captures, see [tools/README.md](../tools/README.md).

## Try this

Change `Q` on line 51. `LET Q=0.5` will start a straight leg on about half of the middle-bat and brick bounces, which makes the effect easy to see. `LET Q=0` turns the nudge off and gives you the step 4 game again.

To get a repeatable rally while you experiment, replace line 21 with `RANDOMIZE 1` (or any other non-zero number). The same seed gives the same sequence of `RND` values every time you load the program. Put `RANDOMIZE` back, with no number, when you want each run to be different.
