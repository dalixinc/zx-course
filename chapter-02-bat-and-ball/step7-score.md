# Chapter 2, step 7 — Score, lives, and game over

This step takes the game from [step 6](step6-beep.md) and turns it into a short game you can win or lose. There is a score, there are three lives, a miss still makes the low beep and now costs a life, and the game ends in one of two ways: `GAME OVER` when the lives run out, or `WELL DONE` when the last brick is cleared. In both cases the final score is shown, and a key starts a new game.

The design is deliberately small.

- The score `S` goes up by 10 for each brick. That is 960 if you clear the whole wall, which is enough of a number to feel like a score without any extra bonuses.
- Lives are kept in `V`, so the letter is not confused with `L` (the brick row) or `I` (the delay counter). You start with 3. A miss still plays the miss beep, then `V` is reduced by one. The ball is sent back to its starting place for the next life, and the wall is left as it is.
- `U` is the number of bricks still standing. It is counted while the wall is drawn (3 rows of 32, so 96) and reduced by one whenever a brick is rubbed out. When `U` reaches 0, you have won.
- The score and lives are printed on row 0, as `SCORE` on the left and `LIVES` on the right. That line has to stay put. The status is paper 0, so `ATTR` would treat those cells as empty playfield, and a ball printed there would overwrite the text. The program therefore treats row 0 as a wall: the ball's top row is 1, and it bounces when the next row would be 0. The bricks are moved down one row, to rows 3 to 5, so there is still an empty row under that ceiling for `ATTR` to look at — the same reason there used to be a gap above the wall. The colours are still red, green and yellow; the formula is `P=2*(L-2)` to match the new row numbers. The ball now starts at row 6, just below the wall.
- Game over plays a short descending tune, clears the screen, and prints `GAME OVER`, the score, and `PRESS ANY KEY TO PLAY AGAIN`. A win plays a short rising tune and prints `WELL DONE`, then the same score and key prompt. After a key, `RUN` starts a new game from scratch.

The delay at line 140 is still `FOR I=1 TO 10`. The beeps on bat, wall, brick and miss are unchanged; the two end-of-game tunes are a little longer, because play has already stopped.

Every program is tested in a 48K emulator before it is shown.

## The new BASIC keywords used here

The keywords from steps 1 to 6 are used again and are not repeated below. `INKEY$` was introduced in step 2, to read O and P; it is used again here in a wait loop, and is described with that pattern.

### STR$ and string concatenation

`STR$ number` converts a number into a string of its digits. `+` joins two strings into one.

That is useful when a number has to sit inside a line of text, and you want control over the spaces. `PRINT S` (or `PRINT "SCORE";S`) prints a number with its own spacing, which can shift the rest of the line as the score goes from one digit to three. Building the text with `STR$` and `+` and printing it at a fixed column keeps `SCORE` on the left and `LIVES` on the right.

```
10 LET S=10
20 PRINT "SCORE "+STR$ S
```

### GO SUB and RETURN

`GO SUB line` jumps to a subroutine at that line. When the subroutine has finished, `RETURN` comes back to the statement after the `GO SUB`. The same short routine can be called from more than one place without copying it.

The status line is a subroutine at line 600. It is called after the wall is drawn, after a brick is scored, and after a life is lost, so those three places cannot drift out of step.

```
10 GO SUB 100
20 PRINT "back"
30 STOP
100 PRINT "in the subroutine"
110 RETURN
```

`STOP` ends the program, so you can try this as a little listing of its own. A `GO SUB` without a matching `RETURN` will run on into whatever follows. A `RETURN` without a `GO SUB` is an error.

### RUN

`RUN` starts the program from the beginning. It first forgets all variables, clears the `GO SUB` stack, and restores `DATA` to the first item (the same work as `CLEAR`), then runs from line 1 — or from a line you give, as in `RUN 24`.

After game over or a win, that is the simplest way to start a new game: `S`, `V` and `U` are set up again, the wall is redrawn, and line 24 clears the end-of-game message. `GO TO 24` would jump back to the same place, but it would leave the old values of `S`, `V` and `U` unless you reset them first. `RUN` does that for you.

```
10 PRINT "again"
20 RUN
```

(Do not leave that example running; it will start itself over and over. Break it the same way as the game.)

### Waiting for a key

`INKEY$` is `""` when no key is down, and the character of the key when one is. A two-line loop can wait for the next key, but if the player is still holding O or P from the rally that just ended, a single `IF INKEY$="" THEN GO TO ...` would see that key at once and start a new game immediately. The program therefore waits twice:

```
10 IF INKEY$<>"" THEN GO TO 10
20 IF INKEY$="" THEN GO TO 20
```

Line 10 waits until every key is up. Line 20 then waits for a fresh press.

## The listing

The game loop is the loop from step 6, with a new top bound, a call to the status subroutine, and a little more work on a miss and on a brick. The new material is the remarks and values for `S`, `V` and `U`, the status subroutine, and the win and game-over screens.

```
1 REM R=ball row 1-20
2 REM X=ball column 0-31
3 REM DR=row step +1 or -1
4 REM DX=column step +1, 0 or -1
5 REM B=bat left column 0-28
6 REM W=bat width in characters
7 REM K$=key from INKEY$
8 REM I=delay loop counter
9 REM L=brick row 3-5
10 REM C=brick column 0-31
11 REM P=PAPER colour of a brick row
12 REM A=ATTR of the cell ahead
13 REM N=byte 0-7 of the ball UDG
14 REM D=one row of the ball graphic
15 REM Q=chance of a slight deflection
16 REM T=beep duration in seconds
17 REM PB=bat pitch (middle C is 0)
18 REM PW=wall pitch
19 REM PK=brick pitch
20 REM PM=miss pitch
21 REM S=score
22 REM V=lives left
23 REM U=bricks left
24 BORDER 0: PAPER 0: INK 7: CLS
25 RANDOMIZE
26 LET S=0: LET V=3
30 LET R=6: LET X=5
40 LET DR=1: LET DX=1
50 LET W=4: LET B=14
51 LET Q=0.2
52 LET T=0.02
53 LET PB=0: LET PW=24: LET PK=12: LET PM=-12
54 RESTORE 500
55 FOR N=0 TO 7
56 READ D
57 POKE USR "a"+N,D
58 NEXT N
59 LET U=0
60 FOR L=3 TO 5
70 LET P=2*(L-2)
80 FOR C=0 TO 31
90 PRINT AT L,C; PAPER P;" "
91 LET U=U+1
100 NEXT C
110 NEXT L
120 PRINT AT 21,B; INVERSE 1;"    "
125 GO SUB 600
130 PRINT AT R,X;CHR$ 144
140 FOR I=1 TO 10: NEXT I
150 PRINT AT R,X;" "
160 LET K$=INKEY$
170 IF (K$="o" OR K$="O") AND B>0 THEN PRINT AT 21,B;"    ": LET B=B-1: PRINT AT 21,B; INVERSE 1;"    "
180 IF (K$="p" OR K$="P") AND B<32-W THEN PRINT AT 21,B;"    ": LET B=B+1: PRINT AT 21,B; INVERSE 1;"    "
190 IF R+DR<1 THEN LET DR=-DR: BEEP T,PW
200 IF R+DR>20 THEN GO TO 300
210 IF X+DX<0 THEN LET DX=-DX: BEEP T,PW
220 IF X+DX>31 THEN LET DX=-DX: BEEP T,PW
230 LET A=ATTR(R+DR,X+DX)
240 IF INT(A/8)<>0 THEN GO TO 400
250 LET R=R+DR
260 LET X=X+DX
270 GO TO 130
300 IF X<B OR X>B+W-1 THEN GO TO 360
305 BEEP T,PB
310 IF X=B THEN LET DX=-1: LET DR=-DR: GO TO 210
320 IF X=B+W-1 THEN LET DX=1: LET DR=-DR: GO TO 210
330 LET DR=-DR
340 GO TO 430
360 BEEP T,PM
362 LET V=V-1
363 GO SUB 600
364 IF V=0 THEN GO TO 700
365 LET R=6: LET X=5: LET DR=1: LET DX=1
370 GO TO 130
400 PRINT AT R+DR,X+DX; PAPER 0;" "
405 BEEP T,PK
406 LET S=S+10
407 LET U=U-1
408 GO SUB 600
409 IF U=0 THEN GO TO 650
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
600 PRINT AT 0,1;"SCORE "+STR$ S
610 PRINT AT 0,22;"LIVES "+STR$ V
620 RETURN
650 BEEP 0.08,0: BEEP 0.08,4: BEEP 0.08,7: BEEP 0.25,12
655 CLS
660 PRINT AT 8,11;"WELL DONE"
665 GO TO 730
700 BEEP 0.08,7: BEEP 0.08,4: BEEP 0.08,0: BEEP 0.25,-12
705 CLS
710 PRINT AT 8,11;"GAME OVER"
730 PRINT AT 10,11;"SCORE "+STR$ S
740 PRINT AT 14,2;"PRESS ANY KEY TO PLAY AGAIN"
760 IF INKEY$<>"" THEN GO TO 760
770 IF INKEY$="" THEN GO TO 770
780 RUN
```

The source is `step7-score.bas`. A tape image ready to load is `step7-score.tap`.

## Line by line

- **1–23** name the variables. **1–20** are as in step 6, except that the ball's rows are now 1 to 20 and the bricks live on rows 3 to 5. **S** is the score, **V** is the lives left, and **U** is the number of bricks still standing.
- **24–25** set the colours and seed the generator, as before.
- **26** starts a new game at score 0 with three lives.
- **30–53** place the ball (now at row 6, just under the wall), the bat, the delay and the beep pitches, as in step 6.
- **54–58** define the ball UDG, as before.
- **59–110** draw the wall on rows 3 to 5 and count the bricks into `U` as they go down, so `U` stays right if you later change the size of the wall.
- **120–125** draw the bat and print the status line.
- **130–180** are the game loop from step 6: print the ball, delay, rub it out, and read O and P. The delay is still `FOR I=1 TO 10`.
- **190** if the next row would be the status line, reverse `DR` and play the wall pitch. The top of the screen is now row 0, not row -1.
- **200–270** are the bat-row test, the side walls, and the `ATTR` brick test, as in step 6.
- **300–340** a bat hit: the same beep and the same end-or-middle rules as in step 6.
- **360–370** a miss: play the miss beep, lose a life, and update the status line. If `V` is now 0, go to game over. Otherwise restart the ball at row 6, column 5, going down and right, and go back to the loop. The remaining bricks are not redrawn.
- **400–420** a brick was hit: rub it out, play the brick pitch, add 10 to the score, reduce `U`, and update the status line. If `U` is now 0, go to the win screen. Otherwise reverse `DR` and go to the nudge, as in step 6.
- **430–450** are the slight-deflection rules from step 5.
- **500–510** are the eight bytes of the ball graphic, as in step 4.
- **600–620** print `SCORE` at column 1 and `LIVES` at column 22, then return.
- **650–665** a win: a short rising scale, clear the screen, print `WELL DONE`, and join the common ending at line 730.
- **700–710** game over: a short descending scale, clear the screen, and print `GAME OVER`.
- **730–740** print the score and the key prompt, used by both endings.
- **760–770** wait for any still-held key to be released, then wait for a new press.
- **780** `RUN` starts the whole program again, with a fresh score, three lives, and a new wall.

## Limitations you will notice

The score is only a brick count in disguise: every brick is worth the same, and there is no bonus for a remaining life or a shorter game. `RUN` forgets the last score, so there is no high-score line to beat. Both of those are easy to add, and are left as exercises.

The playfield is one row shorter than in step 6, because row 0 is now the status line. The gap under the status is required, unless you invent a different way to keep the ball off the text.

The two end-of-game tunes are a taste, and they block for about half a second before the message appears. That is acceptable once, at the end of a game; the in-game beeps stay short for the reason given in step 6.

The flicker of the ball, the need to hold O or P, the simple `ATTR` test, and the slight random deflection are unchanged from earlier steps.

A screenshot of a rally in progress, with the status line showing `SCORE 20` and `LIVES 2` after two bricks have been cleared, is in `step7-score.png`.

To run it yourself: start a 48K emulator, load `step7-score.tap`, and type `LOAD ""`. The program auto-starts at line 10 (a remark; the first statement is line 24) and runs until you break it (on a real machine, Caps Shift and Space; in Fuse, often F4 or the menu). The helper script `tools/run-tap.sh chapter-02-bat-and-ball/step7-score.bas` (from the course root) builds the tape and runs it in Fuse under Xvfb. To send keys while it captures, see [tools/README.md](../tools/README.md). If you use that script, set `TAP_NAME=score` so the program name on the tape stays `score`.

## Try this

Change the points on line 406, or the starting lives on line 26. `LET V=1` makes every miss fatal, which is a short way to try the game-over screen; `LET S=S+10*(6-(R+DR))` in the brick code (instead of a flat 10) would make the top, red row worth more than the yellow one, because `R+DR` is the row of the brick you just hit.

To hear the two endings without playing a full game, you can `GO TO 650` or `GO TO 700` from the 48K's `L` cursor, but only once the program has been run at least as far as setting `S` — otherwise the score line has nothing to print. Easier is to set `LET V=1` and miss on purpose, or, while you are experimenting, to draw a very short wall (for example `FOR L=3 TO 3` and `FOR C=15 TO 16`) so a win comes quickly. Put the wall back to three full rows when you have seen `WELL DONE`.

`PAUSE 0` also waits for a key, and is shorter than the two `INKEY$` loops. Try it in place of lines 760–770 and then hold P into a miss with `V=1`: the new game may start at once, because `PAUSE 0` treats the key you are still holding as the key it was waiting for. That is why the listing waits for a release first.
