# Chapter 2, step 6 — BEEP sounds

This step takes the random-deflection game from [step 5](step5-random.md) and gives each event a short beep: a lower note when the ball hits the bat, a higher note when it hits a side wall or the top of the screen, a distinct note in between when it clears a brick, and a short low note when you miss. The rest of the game is unchanged.

The delay at line 140 is also shortened. In steps 2 to 5 it was `FOR I=1 TO 100`. That was comfortable in a sped-up emulator, but on a real 48K machine — and in Fuse running at normal Spectrum speed — it made the ball crawl. `FOR I=1 TO 10` is a sensible pace at real speed.

`BEEP` itself also takes time. It is a blocking instruction: the program stops until the note has finished. A long beep on every bounce would make the rally stutter, so the notes here are very short — 0.02 seconds. 0.01 to 0.02 is the range to stay in; anything much longer is obvious in play.

The four pitches are stored in named variables, with a remark for each, so you can retune them without hunting through the loop.

Every program is tested in a 48K emulator before it is shown.

## The new BASIC keyword used here

The keywords from steps 1 to 5 are used again and are not repeated below.

### BEEP

`BEEP duration,pitch` plays a note on the Spectrum's speaker and then continues. `duration` is the length of the note in seconds. `pitch` is measured in semitones from middle C, which is 0: positive values go up, negative values go down. The useful range is -60 to 69.

The speaker is one of the devices the ULA looks after, together with the keyboard and the EAR/MIC tape socket, as described in [Lesson 1](../chapter-01-the-machine/). `BEEP` drives that speaker by holding the Z80 in a loop for the whole of `duration`, clicking the speaker at the chosen pitch. Nothing else in the program runs during that time: the bat will not move, and the ball will not be redrawn, until the note ends. That is why the beeps in this game are kept so short.

```
10 BEEP 0.5,0
20 BEEP 0.25,12
30 BEEP 1,-12
```

Line 10 is a middle C, half a second long. Line 20 is the C one octave above, a quarter of a second long. Line 30 is the C one octave below, one second long.

A few useful pitches:

| Note | Pitch |
|------|------:|
| C (an octave below middle) | -12 |
| G | -5 |
| A | -3 |
| B | -1 |
| C (middle) | 0 |
| D | 2 |
| E | 4 |
| F | 5 |
| G | 7 |
| A | 9 |
| B | 11 |
| C (an octave above middle) | 12 |
| C (two octaves above middle) | 24 |

## The listing

The new work is the remarks and values for `T`, `PB`, `PW`, `PK` and `PM`, the shorter delay at line 140, and a `BEEP` on each of the four events the loop already knew about. Everything else is the game from step 5.

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
16 REM T=beep duration in seconds
17 REM PB=bat pitch (middle C is 0)
18 REM PW=wall pitch
19 REM PK=brick pitch
20 REM PM=miss pitch
21 BORDER 0: PAPER 0: INK 7: CLS
22 RANDOMIZE
30 LET R=5: LET X=5
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
60 FOR L=2 TO 4
70 LET P=2*(L-1)
80 FOR C=0 TO 31
90 PRINT AT L,C; PAPER P;" "
100 NEXT C
110 NEXT L
120 PRINT AT 21,B; INVERSE 1;"    "
130 PRINT AT R,X;CHR$ 144
140 FOR I=1 TO 10: NEXT I
150 PRINT AT R,X;" "
160 LET K$=INKEY$
170 IF (K$="o" OR K$="O") AND B>0 THEN PRINT AT 21,B;"    ": LET B=B-1: PRINT AT 21,B; INVERSE 1;"    "
180 IF (K$="p" OR K$="P") AND B<32-W THEN PRINT AT 21,B;"    ": LET B=B+1: PRINT AT 21,B; INVERSE 1;"    "
190 IF R+DR<0 THEN LET DR=-DR: BEEP T,PW
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
365 LET R=5: LET X=5: LET DR=1: LET DX=1
370 GO TO 130
400 PRINT AT R+DR,X+DX; PAPER 0;" "
405 BEEP T,PK
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

The source is `step6-beep.bas`. A tape image ready to load is `step6-beep.tap`.

## Line by line

- **1–20** name the variables. **1–15** are as in step 5. **T** is the length of every beep, in seconds. **PB**, **PW**, **PK** and **PM** are the pitches for the bat, a wall, a brick and a miss, in semitones from middle C.
- **21–51** are the setup from step 5: colours, `RANDOMIZE`, the starting ball and bat, and the chance `Q`.
- **52–53** set the duration to 0.02 seconds and the four pitches. The bat is middle C (`PB=0`). A wall — a side or the top of the screen — is two octaves above that (`PW=24`), so it reads as a clearly higher 'ping'. A brick sits in the middle, one octave above the bat (`PK=12`): it is a different event from a wall bounce, but it is not as low as the bat. A miss is one octave below the bat (`PM=-12`), a short low note so you hear that the ball has gone. The four notes are an octave apart, which is easy to tell even when each one lasts only a twentieth of a second.
- **54–120** define the ball UDG, draw the wall and the bat, as in step 5.
- **130–180** are the game loop from step 5: print the ball, delay, rub it out, and read O and P. The delay at **140** is now `FOR I=1 TO 10`.
- **190** if the next row would be above the top of the screen, reverse `DR` and play the wall pitch.
- **200** if the next row would be past the bat row, go to the bat-or-miss code, as in step 5.
- **210–220** if the next column would be off the left or right of the screen, reverse `DX` and play the same wall pitch. Sides and top share `PW` because they are the same kind of bounce: the ball has hit the edge of the playfield, not a brick or the bat.
- **230–270** test for a brick with `ATTR` and take the step, as in step 5.
- **300** if the ball is not over the bat, it is a miss: go to line 360.
- **305** a hit: play the lower bat pitch, once, before the end-or-middle tests. The beep is here rather than on each of the three bat cases, so a hit is always one note.
- **310–340** are the bat-end steering and the middle-bat nudge from step 5.
- **360–370** a miss: play the low miss pitch, then restart at row 5, column 5, going down and right, as before.
- **400–420** a brick was hit: rub it out, play the brick pitch, reverse `DR`, and go to the nudge.
- **430–450** are the slight-deflection rules from step 5.
- **500–510** are the eight bytes of the ball graphic, as in step 4.

## Limitations you will notice

`BEEP` blocks. Even at `T=0.02` a busy rally adds a little pause on every bounce. If you raise `T` to a tenth of a second or more, the game will visibly hitch. The delay loop and `BEEP` share the same budget: the delay was cut to `1 TO 10` so the ball moves at a decent pace, and the beeps have to stay short so they do not give that time back.

The four pitches are a taste, not a tune. They are spaced an octave apart so a 0.02-second blip is still identifiable. You can change them on line 53.

The flicker of the ball, the need to hold O or P, the simple `ATTR` test, and the slight random deflection are unchanged from step 5.

A screenshot of a rally in progress, after a yellow brick and a green brick have been cleared, is in `step6-beep.png`.

To run it yourself: start a 48K emulator, load `step6-beep.tap`, and type `LOAD ""`. The program auto-starts at line 10 (a remark; the first statement is line 21) and runs until you break it (on a real machine, Caps Shift and Space; in Fuse, often F4 or the menu). The helper script `tools/run-tap.sh chapter-02-bat-and-ball/step6-beep.bas` (from the course root) builds the tape and runs it in Fuse under Xvfb. To send keys while it captures, see [tools/README.md](../tools/README.md).

## Try this

Change the pitches on line 53. `LET PW=7` (a G above middle C) makes the wall less shrill; `LET PK=4` (an E) brings the brick closer to the bat. If two events start to sound the same, you will notice how useful the octave spacing was.

Change `T` on line 52. `LET T=0.2` makes each bounce easy to hear — and makes the stutter obvious. Put it back to 0.02 (or try 0.01) when you want the game to run smoothly again.

To hear the four notes in isolation, type this in as a separate program:

```
10 BEEP 0.5,-12
20 BEEP 0.5,0
30 BEEP 0.5,12
40 BEEP 0.5,24
```
