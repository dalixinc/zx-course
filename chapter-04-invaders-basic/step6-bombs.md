# Chapter 4, step 6 — Invaders' bombs

This is the sixth step of the Invaders-style game that Chapter 4 builds in pure Sinclair BASIC. [Step 1](step1-base.md) put the player's base on the bottom row. [Step 2](step2-shot.md) added a shot, fired with Space. [Step 3](step3-block.md) put up a still block of 32 invaders. [Step 4](step4-march.md) made that block march. [Step 5](step5-hits.md) made a shot that reaches a living invader kill it. This step gives the invaders a way to fire back: one bomb at a time, dropped from the lowest living invader in a randomly chosen column. A bomb that reaches the base ends the run. A shot and a bomb that meet cancel each other. Lives, and a proper game over, belong in step 8.

The program is laid out in the same way as steps 1 to 5. Line 10 jumps over the loop to the set-up at line 900. The loop sits at the top, and the `REM` lines for the variables stay at the end.

Every program is tested in a 48K emulator before it is shown.

## UDG C, the bomb

UDG C, code 146, is a red chevron (`INK 2`), distinct from the yellow shot and from the three invader inks. Bit 7 is the leftmost pixel and bit 0 the rightmost. `#` is ink (a 1) and `.` is paper (a 0). The pattern repeats as it falls, so it reads as a descending bolt.

```
        bit  7 6 5 4 3 2 1 0      BIN         decimal
row 0        0 0 0 1 1 1 0 0      00011100      28
row 1        0 0 1 1 1 1 1 0      00111110      62
row 2        0 1 1 0 0 0 1 1      01100011      99
row 3        0 0 0 1 1 1 0 0      00011100      28
row 4        0 0 1 1 1 1 1 0      00111110      62
row 5        0 1 1 0 0 0 1 1      01100011      99
row 6        0 0 0 1 1 1 0 0      00011100      28
row 7        0 0 0 0 1 0 0 0      00001000       8

        ...###..
        ..#####.
        .##...##
        ...###..
        ..#####.
        .##...##
        ...###..
        ....#...
```

A first draft used a one-pixel-wide zigzag. In Fuse that was almost invisible against the black paper, so the shipped UDG is this wider chevron.

## One bomb, from the lowest living invader

The player's shot is still only one at a time, and the bomb follows the same rule, so the loop stays lighter. A drop is tried every 12 idle-of-bomb passes, counted in `J`. The program then picks a column with `K=1+INT (RND*8)` and retries up to eight times if that column is already empty, so a thinning wave still drops from a living column rather than wasting the turn. If all eight tries miss, which is rare until the wave is almost gone, the drop is skipped.

The bomb must not appear out of a hole. A second scan, from row 4 up to row 1, finds the lowest living invader in the chosen column. The bomb is printed one row below that invader, in the same screen column, `D=BX+2*K-1`, with the same mid-ripple bookkeeping the shot already uses: a row that has already taken this step is below `BY+1` on a down, or at `BX+DX` on a sideways step.

In Fuse, a test that had already killed the bottom invader of column 5, and that forced the next drop from that column, printed the bomb just under the remaining cyan invader, in the gap above the hole, and the bomb then fell through the empty cell. It did not appear out of the hole. On the official program, with the block marching, bombs appeared under living invaders in their current columns, including after the formation had already stepped right, and fell down those columns while the block continued to ripple.

## A bomb that misses, a bomb that hits, and a cancelled shot

Each pass, if a bomb is in flight, it is rubbed out, moved down one row, and redrawn. If it moves past row 21, it is simply removed. If it arrives on row 21 in the base's column `X`, the run ends: `L` is set to 3, the bomb and any shot are cleared, UDG P is printed in yellow on the base, and `YOU ARE HIT` is printed on row 0, at column 10, in white. Line 64 already refuses a new march step when `L` is not 0. Line 61 also refuses a new shot when `L=3`, and line 62 refuses a new drop. The player can still move the exploded base's column, but there is nothing left to fire and nothing left to duck. A life count, and a proper game over, belong in step 8.

A shot and a bomb that meet, or that would pass through each other on this pass, cancel. After the shot has moved, and again after the bomb has moved, the program tests whether they share a column and are on the same row or are one row apart (`Y=U` or `Y=U+1`). Both cells are printed as spaces, and `Y` and `U` are set to -1. There is no explosion; canceling is meant to be cheap.

In Fuse, a bomb started at row 17 in the base's column reached row 21, printed `YOU ARE HIT`, and replaced the base with the yellow starburst. A bomb in column 16, with the base in column 15, fell off the bottom and later drops continued. A shot started at row 13 and a bomb at row 10, in the same column, vanished on the pass they became adjacent, and later bombs still fell. After `L=3`, holding Space produced no new shot.

## An unassigned variable is not zero

The bomb's cancel test uses `C`, the shot's column. In some BASICs an unassigned numeric is treated as 0. Sinclair BASIC is not one of them. If a variable is used before it has been given a value, the result is error `2 Variable not found`.

A first test that dropped a bomb before the player had ever fired crashed at line 402 with that error, because `C` is only set when Space is pressed. The set-up therefore does `LET C=0: LET D=0` as well as `LET Y=-1: LET U=-1`. Until the first shot, `C` is 0, and the cancel test can safely compare it with `D`. This is worth remembering whenever a later feature reads a variable that an earlier path may not have written.

## How long a bomb takes

Measured in Fuse, with a counter in the official loop and `FRAMES` (the 16-bit pair at 23672 and 23673) as the stopwatch. The idle and cycle figures are the same measurements as in step 5, retaken on this program, with drops disabled so a bomb in flight does not sit inside the count. The bomb-fall starts a bomb already on row 8, with the block still (`W=999`), and stops when `U` becomes -1 after the bomb has left row 21. The shot-hit is the step 5 measurement, retaken with the bomb checks in the loop.

| What | Frames | Seconds |
|---|---:|---:|
| One idle pass (no key, no shot, no bomb, no march) | 6.7 | 0.13 |
| One official cycle (`W=8` idle passes plus one sideways step) | 104 | 2.08 |
| A bomb falling from row 8 to off the bottom, block still (14 passes) | 126 | 2.52 |
| A hit at row 7, fired from row 20, block still (13 passes) | 177 | 3.54 |

Forty idle passes took 267 frames, so one is 6.7. In step 5 that was 4.7: the loop now tests the bomb on every pass, increments the drop timer when no bomb is in flight, and has more variables to look up. One official cycle of 11 passes took 104 frames, against 86 in step 5 and 74 in step 4. A bomb that starts on row 8 takes 14 passes to leave the bottom, 126 frames, 9.0 frames a step. A shot that hits the bottom row from row 20 took 177 frames over 13 passes, 13.6 frames a pass, against 134 frames (10.3 a pass) in step 5; the extra is the cancel test and the bomb conditions in the same stretch.

A first timing of the idle loop called `GO SUB 450` on every pass, even when the drop timer had not expired, and was almost twice as slow, because `GO SUB` searches for its target from the start of the program. The shipped loop only increments `J` on those passes, and calls the drop routine when `J` has reached 12. These are the numbers for Chapter 5 to beat.

`W` stays 8. Twelve passes between drop attempts is a choice, not a rule, and is a "Try this".

## The new BASIC used here

### RANDOMIZE and RND

`RANDOMIZE`, with no argument, seeds the generator from `FRAMES`, so a new run does not drop from the same columns as the last one. `RND` returns a number from 0 up to, but not including, 1. `1+INT (RND*8)` is then a column from 1 to 8. A short test program printed ten such values; all were in 1 to 8.

### A variable must be assigned before it is read

As above, using `C` (or any other numeric) before `LET` has given it a value is error `2 Variable not found`, not a silent 0. The set-up assigns `C` and `D` as well as `Y` and `U`.

## The listing

Line 10 jumps over the loop to the set-up at line 900. That clears the screen, seeds `RND`, dimensions the arrays, defines the ten UDGs from the `DATA` (A, B, C, D to I, and P), builds both frames of the four row strings, prints the block in frame 1, and jumps into the loop at line 20. The loop is the step 5 loop, plus a bomb that can drop, fall, cancel a shot, or hit the base.

```
10 GO TO 900
20 LET K$=INKEY$
30 IF (K$="o" OR K$="O") AND X>0 THEN PRINT AT 21,X;" ": LET X=X-1: PRINT AT 21,X; INK 4;CHR$ 144
40 IF (K$="p" OR K$="P") AND X<31 THEN PRINT AT 21,X;" ": LET X=X+1: PRINT AT 21,X; INK 4;CHR$ 144
50 IF Y>=0 THEN PRINT AT Y,C;" ": LET Q=Y-BY: IF Q>=0 AND Q<=6 AND Q/2=INT (Q/2) THEN LET R=Q/2+1: LET I=3+2*(Q>=2)+2*(Q=6): LET P=Y: GO SUB 70
52 IF Y>=0 THEN LET Y=Y-1
54 IF Y>=0 THEN GO SUB 300
56 IF Y>=0 THEN GO SUB 390: IF Y>=0 THEN PRINT AT Y,C; INK 6;CHR$ 145
58 IF T>0 THEN LET T=T-1: IF T=0 THEN PRINT AT G,H;" ": LET G=-1
59 IF U>=0 THEN PRINT AT U,D;" ": LET U=U+1: GO SUB 400
60 IF U>=0 THEN PRINT AT U,D; INK 2;CHR$ 146
61 IF Y<0 AND K$=" " AND L<>3 THEN LET C=X: LET Y=20: GO SUB 300: IF Y>=0 THEN GO SUB 390: IF Y>=0 THEN PRINT AT Y,C; INK 6;CHR$ 145
62 IF U<0 AND L=0 THEN LET J=J+1: IF J>=12 THEN GO SUB 450
63 IF S>0 THEN GO SUB 220: GO TO 68
64 LET M=M+1: IF M>=W AND L=0 THEN GO SUB 100
68 GO TO 20
70 IF S=0 OR R<=S THEN GO SUB 80: RETURN
72 IF E=1 THEN LET P=P+1: LET F=3-F: GO SUB 80: LET F=3-F: RETURN
74 LET BX=BX+DX: LET F=3-F: GO SUB 80: LET F=3-F: LET BX=BX-DX
76 RETURN
80 LET Z=BX: LET U$=A$(R,F)
81 IF BX<0 THEN LET Z=0: LET U$=A$(R,F)(1-BX TO 17)
82 IF BX>15 THEN LET U$=A$(R,F)(1 TO 32-BX)
83 PRINT AT P,Z; INK I;U$
84 RETURN
90 LET Z=BX: LET U$="                 "
91 IF BX<0 THEN LET Z=0: LET U$=U$(1 TO 17+BX)
92 IF BX>15 THEN LET U$=U$(1 TO 32-BX)
93 PRINT AT P,Z;U$
94 RETURN
100 LET M=0
102 LET LM=0: LET RM=0
104 FOR K=1 TO 8
106 LET A=V(1,K)+V(2,K)+V(3,K)+V(4,K)
108 IF A>0 THEN LET LM=K: LET K=8
110 NEXT K
112 FOR K=8 TO 1 STEP -1
114 LET A=V(1,K)+V(2,K)+V(3,K)+V(4,K)
116 IF A>0 THEN LET RM=K: LET K=1
118 NEXT K
120 IF LM=0 THEN RETURN
122 IF BX+2*LM-1+DX<0 OR BX+2*RM-1+DX>31 THEN GO TO 150
124 LET E=0: LET S=4
126 GO SUB 220
128 RETURN
150 IF BY+6>=20 THEN LET L=1: PRINT AT 0,8; INK 7;"THEY HAVE LANDED": RETURN
152 LET E=1: LET S=4
154 GO SUB 220
156 RETURN
220 LET R=S
222 LET I=3+2*(R>1)+2*(R=4)
224 IF E=1 THEN GO TO 240
226 LET P=BY+2*(R-1)
228 LET BX=BX+DX: LET F=3-F: GO SUB 80: LET F=3-F: LET BX=BX-DX
230 LET S=S-1: IF S=0 THEN LET BX=BX+DX: LET F=3-F
232 RETURN
240 LET P=BY+1+2*(R-1)
242 LET F=3-F: GO SUB 80: LET F=3-F
244 LET P=BY+2*(R-1): GO SUB 90
246 LET S=S-1: IF S=0 THEN LET BY=BY+1: LET DX=-DX: LET F=3-F
248 RETURN
300 IF S>0 AND E=1 THEN GO TO 340
302 LET Q=Y-BY
304 IF Q<0 OR Q>6 OR Q/2<>INT (Q/2) THEN RETURN
306 LET R=Q/2+1
308 LET B=BX+DX*(S>0 AND R>S)
310 GO TO 360
340 LET Q=Y-(BY+1)
342 IF Q>=0 AND Q<=6 AND Q/2=INT (Q/2) THEN LET R=Q/2+1: IF R>S THEN LET B=BX: GO TO 360
344 LET Q=Y-BY
346 IF Q<0 OR Q>6 OR Q/2<>INT (Q/2) THEN RETURN
348 LET R=Q/2+1
350 IF R>S THEN RETURN
352 LET B=BX
360 IF C-B+1<2 OR C-B+1>16 OR (C-B+1)/2<>INT ((C-B+1)/2) THEN RETURN
362 LET K=(C-B+1)/2
364 IF V(R,K)=0 THEN RETURN
366 LET V(R,K)=0
368 LET A$(R,1,C-B+1)=" ": LET A$(R,2,C-B+1)=" "
370 PRINT AT Y,C; INK 6;CHR$ 159
372 LET G=Y: LET H=C: LET T=3: LET Y=-1
374 LET N=N-1: IF N=0 THEN LET L=2: PRINT AT 0,10; INK 7;"WAVE CLEARED"
376 RETURN
390 IF U<0 OR C<>D OR (Y<>U AND Y<>U+1) THEN RETURN
392 PRINT AT Y,C;" ": IF U>=0 AND (U<>Y) THEN PRINT AT U,D;" "
394 LET Y=-1: LET U=-1
396 RETURN
400 IF U>21 THEN LET U=-1: RETURN
402 IF Y>=0 AND C=D AND (Y=U OR Y=U+1) THEN GO SUB 392: RETURN
404 IF U=21 AND D=X THEN GO TO 410
406 RETURN
410 LET L=3: LET U=-1: LET Y=-1
412 PRINT AT 21,X; INK 6;CHR$ 159
414 PRINT AT 0,10; INK 7;"YOU ARE HIT"
416 RETURN
450 LET J=0
454 FOR I=1 TO 8
456 LET K=1+INT (RND*8)
458 IF V(1,K)+V(2,K)+V(3,K)+V(4,K)>0 THEN LET I=8
460 NEXT I
462 IF V(1,K)+V(2,K)+V(3,K)+V(4,K)=0 THEN RETURN
464 LET I=0
465 FOR R=4 TO 1 STEP -1
466 IF V(R,K)=1 THEN LET I=R: LET R=1
468 NEXT R
469 IF I=0 THEN RETURN
470 LET R=I
471 LET U=BY+2*(R-1)+1+E*(S>0 AND R>S)
472 LET D=BX+DX*(S>0 AND E=0 AND R>S)+2*K-1
474 IF U>21 THEN LET U=-1: RETURN
475 IF U=21 AND D=X THEN GO TO 410
476 PRINT AT U,D; INK 2;CHR$ 146
478 RETURN
900 BORDER 0: PAPER 0: INK 7: CLS
902 RANDOMIZE
905 DIM V(4,8): DIM A$(4,2,17)
910 RESTORE 990
920 FOR N=0 TO 7: READ D: POKE USR "a"+N,D: NEXT N
930 FOR N=0 TO 7: READ D: POKE USR "b"+N,D: NEXT N
931 FOR N=0 TO 7: READ D: POKE USR "c"+N,D: NEXT N
932 RESTORE 1000
934 FOR N=0 TO 47: READ D: POKE USR "d"+N,D: NEXT N
936 RESTORE 1060
938 FOR N=0 TO 7: READ D: POKE USR "p"+N,D: NEXT N
940 LET X=15: LET Y=-1: LET C=0: LET D=0
942 LET BX=7: LET BY=1
944 FOR R=1 TO 4
946 FOR J=1 TO 2
948 LET U=146+J+2*(R>1)+2*(R=4)
950 LET S$=" "
952 FOR K=1 TO 8: LET V(R,K)=1: LET S$=S$+CHR$ U+" ": NEXT K
954 LET A$(R,J)=S$
956 NEXT J
958 LET I=3+2*(R>1)+2*(R=4)
960 PRINT AT BY+2*(R-1),BX; INK I;A$(R,1)
962 NEXT R
964 LET F=1: LET DX=1: LET M=0: LET W=8: LET L=0: LET S=0: LET E=0
966 LET N=32: LET T=0: LET G=-1: LET U=-1: LET J=0
968 PRINT AT 21,X; INK 4;CHR$ 144
970 GO TO 20
990 DATA BIN 00011000,BIN 00011000,BIN 00011000,BIN 01111110
995 DATA BIN 11111111,BIN 11111111,BIN 11111111,BIN 11111111
996 DATA BIN 00000000,BIN 00011000,BIN 00011000,BIN 00011000
997 DATA BIN 00011000,BIN 00011000,BIN 00011000,BIN 00000000
998 DATA BIN 00011100,BIN 00111110,BIN 01100011,BIN 00011100
999 DATA BIN 00111110,BIN 01100011,BIN 00011100,BIN 00001000
1000 DATA BIN 00111100,BIN 01111110,BIN 11111111,BIN 11011011
1005 DATA BIN 11111111,BIN 01011010,BIN 10100101,BIN 01000010
1010 DATA BIN 00111100,BIN 01111110,BIN 11111111,BIN 11011011
1015 DATA BIN 11111111,BIN 01011010,BIN 01000010,BIN 10100101
1020 DATA BIN 01000010,BIN 00100100,BIN 01111110,BIN 11011011
1025 DATA BIN 11111111,BIN 10111101,BIN 10100101,BIN 00100100
1030 DATA BIN 00100100,BIN 10100101,BIN 01111110,BIN 11011011
1035 DATA BIN 11111111,BIN 10111101,BIN 00100100,BIN 10100101
1040 DATA BIN 00111100,BIN 11111111,BIN 11111111,BIN 11100111
1045 DATA BIN 11111111,BIN 01011010,BIN 10100101,BIN 10000001
1050 DATA BIN 00111100,BIN 11111111,BIN 11111111,BIN 11100111
1055 DATA BIN 11111111,BIN 01011010,BIN 10000001,BIN 10100101
1060 DATA BIN 10100101,BIN 01011010,BIN 10111101,BIN 01111110
1065 DATA BIN 01111110,BIN 10111101,BIN 01011010,BIN 10100101
9000 REM Variables, kept at the end so GO TO 20 does not walk past them
9010 REM X=base column 0-31, on row 21
9020 REM K$=key read by INKEY$, or ""
9030 REM Y=shot row, or -1 if no shot is in flight
9040 REM C=shot column, 0 until a shot is fired, then set to X
9050 REM BX=left column of the 17-character row strings, or -1 at the left edge
9060 REM BY=top row of the block
9070 REM V(4,8)=1 if that invader is alive, 0 if not
9080 REM A$(4,2,17)=four rows, two animation frames, 17 characters each
9090 REM F=animation frame 1 or 2
9100 REM DX=march direction, 1 right or -1 left
9110 REM M=passes since the last march step finished
9120 REM W=passes to wait before starting the next march step
9130 REM L=1 if landed, 2 if the wave is cleared, 3 if the base was hit, 0 otherwise
9140 REM S=block rows still to draw in this march step, or 0
9150 REM E=1 if this march step is a down step, 0 if sideways
9160 REM LM=leftmost living invader column 1-8
9170 REM RM=rightmost living invader column 1-8
9180 REM Q=shot row relative to BY, used to restore a row or to test a hit
9190 REM P=print row for a row-string or an erase
9200 REM I=ink for an invader row: 3, 5, 5 or 7
9210 REM R=block row 1-4
9220 REM K=invader column 1-8
9230 REM J=frame 1 or 2 while the strings are built, then the drop timer
9240 REM U=UDG code 147 to 152 during set-up, then the bomb row
9250 REM S$=a row string built up, then copied into A$
9260 REM N=living invaders, 32 down to 0
9270 REM T=passes left to show an explosion, or 0
9280 REM G=explosion row, or -1 if none
9290 REM H=explosion column, used when G>=0
9300 REM B=left column of the string for the row being hit
9310 REM A=column total, used to find the living edges
9320 REM D=bomb column, or one byte of a UDG during set-up
9330 REM Z=clipped print column, 0-31
9340 REM U$=clipped row string or spaces, for print and erase
9350 REM U=bomb row, or -1 if no bomb is in flight
9360 REM J=passes since the last drop was tried
9370 REM I=retry count when picking a column to drop from, then the living row found
```

The source is `step6-bombs.bas`. A tape image ready to load is `step6-bombs.tap`, with the program name `bombs`.

## Line by line

- **10–58** are the step 5 loop, with two small changes on a shot: line 56 also `GO SUB 390` to cancel against a bomb before the shot is redrawn, and the explosion timer is unchanged.
- **59** if a bomb is in flight, print a space over it, move it down one row, and `GO SUB 400` to test a miss off the bottom, a cancel, or a hit on the base.
- **60** redraws the bomb, but only if that test left `U` at 0 or more.
- **61** fires with Space, as in step 5, but only when `L` is not 3, and the new cell is also tested for a cancel.
- **62** if no bomb is in flight and the run has not ended, `J` is increased, and when it reaches 12 the program `GO SUB 450` to try a drop.
- **63–68** are the march timer and the ripple, as in step 5. A new step is still refused when `L` is not 0, which now also covers a hit on the base.
- **70–376** are the restore, the clipped print and erase, the march, and the invader-hit test, as in step 5.
- **390–396** cancel a shot and a bomb that share a column and are on the same row, or one row apart: both cells are printed as spaces, and `Y` and `U` become -1.
- **400–406** after a bomb has moved: if it has left row 21 it is cleared; if it meets the shot it is cancelled; if it has arrived on row 21 in the base's column the run ends.
- **410–416** end the run: `L=3`, the bomb and the shot are cleared, the base is drawn as an explosion, and `YOU ARE HIT` is printed.
- **450–478** try a drop: `J` is cleared, a living column is picked with `RND`, the lowest living invader in that column is found, and the bomb is printed one row below it, at the mid-ripple place if that row has already moved. If the start row is already 21 in the base's column, the run ends at once.
- **900–970** set the colours, seed `RND` from `FRAMES`, dimension `V` and `A$`, and define the ten UDGs. C is poked from `USR "c"` after B. `C` and `D` are set to 0, `U` to -1, `J` to 0. `W` is still 8.
- **990–997** hold A and B, as before.
- **998–999** hold C, eight bytes, written with `BIN`.
- **1000–1065** hold D to I and P, as in step 5.
- **9000–9370** name the variables. The new ones are **U** (the bomb row, or -1), **D** (the bomb column, or a UDG byte during set-up), **J** (the drop timer, after it has been the frame while the strings are built), and **I** (a retry count, then the living row, in the drop routine). **L** is now also 3 if the base was hit. **C** is 0 until the first shot, so the cancel test does not hit error 2.

In Fuse, with the official `W=8`, the block still waited, rippled, walked, and stepped down. Bombs dropped from the lowest living invader of a random column, fell while the block marched, missed the base when they were in a different column, and ended the run when they were not. A shot still killed an invader, and a shot and a bomb in the same column cancelled. After `YOU ARE HIT`, Space did not fire. The base could be steered the whole time, until a hit replaced it with the explosion.

## Limitations you will notice

The loop is slower than in step 5: 6.7 frames for an idle pass against 4.7, and 104 frames for an official cycle against 86. A bomb in flight is slower still, 9.0 frames a step, and a shot that also has to test for a cancel is 13.6 frames a pass against 10.3. Machine code can drop more bombs, update them every frame, and keep the player on a steady beat.

There is still only one bomb at a time, and there are no lives. Both can wait until step 8, with a score, a new wave, and sound. More than one bomb is a "Try this" if the loop can bear it.

The landing message, the cleared-wave message, and `YOU ARE HIT` all sit on row 0. A shot that later flies through one of those columns can rub a letter out. A proper end screen in step 8 can take the screen over.

`INKEY$` still reads one key at a time, and Caps Shift and Space is still Break, as in step 2. If you hold a direction and Space together, the fire can be missed.

## Running it

A screenshot of a bomb falling under the right-hand side of the block, after the formation has already marched, with the base still in the middle, is in `step6-bombs.png`.

To build the tape and open it in Fuse, from the course folder, on Windows:

```
windows-tools\build.bat chapter-04-invaders-basic\step6-bombs.bas bombs 10
```

On Linux:

```
tools/build.sh chapter-04-invaders-basic/step6-bombs.bas bombs 10
```

`bombs` is the name stored on the tape, which `LOAD` shows as `Program: bombs`, and `10` is the line the program runs from after it loads. Fuse opens with the tape loading by itself. Hold O and P to move, and press Space to fire. Bombs will drop from the block and fall towards the base. A hit on the base ends the run; a shot can still kill an invader, or cancel a bomb. Break the program with Caps Shift and Space (in Fuse, Shift and Space).

You can also load the ready-made `step6-bombs.tap` in any 48K emulator and type `LOAD ""`. The helper script `tools/run-tap.sh chapter-04-invaders-basic/step6-bombs.bas` builds the tape and runs it in Fuse under Xvfb; see [tools/README.md](../tools/README.md). Set `TAP_NAME=bombs` if you want the name on the tape to match the ready-made file.

## Try this

Change the 12 on line 62. `LET J=J+1: IF J>=6 THEN GO SUB 450` drops twice as often; `J>=20` gives the player more time to dodge. In Fuse, 6 felt busy, and 20 felt sparse. Time a whole wave against the official 12 before step 8 bakes in a rule.

A second bomb needs a second row and column, or a tiny array, and a second test against the shot and the base. If the idle pass stays near 7 frames with one extra bomb, it is a reasonable "Try this"; if it does not, it is a limit for Chapter 5 to fix.

`RANDOMIZE 1`, instead of `RANDOMIZE` with no argument, repeats the same sequence of columns, which is handy when you want to watch the same drop again.
