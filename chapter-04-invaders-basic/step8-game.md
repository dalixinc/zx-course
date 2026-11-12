# Chapter 4, step 8 — Score, lives, waves and sound

This is the eighth and last step of the Invaders-style game that Chapter 4 builds in pure Sinclair BASIC. [Step 1](step1-base.md) put the player's base on the bottom row. [Step 2](step2-shot.md) added a shot. [Step 3](step3-block.md) put up the invaders. [Step 4](step4-march.md) made them march. [Step 5](step5-hits.md) made a shot kill an invader. [Step 6](step6-bombs.md) gave the invaders bombs. [Step 7](step7-shields.md) put four shields between the player and the block. This step turns that program into a finished game: a score that depends on which invader was hit, three lives with a respawn after a hit, a new wave when the block is cleared, a game-over screen when the lives run out or the invaders land, a key to play again, and short `BEEP` sounds. It also closes the gap left in step 7: when the block marches onto the shield rows, those cells are erased and the map `S()` is updated.

The program is laid out in the same way as steps 1 to 7. Line 10 jumps over the loop to the set-up at line 900. The loop sits at the top, and the `REM` lines for the variables stay at the end.

Every program is tested in a 48K emulator before it is shown.

## Score, lives and a status line

Row 0 is now a status line, as it was in [Chapter 2, step 7](../chapter-02-bat-and-ball/step7-score.md): `SCORE` on the left, `WAVE` in the middle, and `LIVES` on the right. A `GO SUB` at line 800 prints all three, using `STR$` so a one-digit score does not leave a stray digit from a previous two-digit value, and so `LIVES` stays in a fixed column.

A top-row invader (magenta, row 1 of the block) is worth 30 points, a middle one (cyan, rows 2 and 3) is worth 20, and a bottom one (white, row 4) is worth 10. The program does not look the colour up. It already has the block row `R` from the hit test, and it adds the points with one expression:

```
LET SC=SC+10+10*(R<4)+10*(R=1)
```

In Sinclair BASIC a comparison is 1 when it is true and 0 when it is false, so a bottom-row hit is 10, a middle-row hit is 20, and a top-row hit is 30. After the add, a short beep plays and the status line is reprinted.

A game starts with three lives. When a bomb hits the base, the base is printed as the explosion UDG P, a slightly longer pair of notes plays, and `LV` is reduced. If any lives remain, the explosion is rubbed out, the base is put back at column 15, and play continues. If `LV` has reached 0, the program goes to the game-over screen with the message `OUT OF LIVES`. A landing is an immediate game over, even if lives remain, with the message `THEY HAVE LANDED`.

Because the status line now lives on row 0, a shot is not allowed to go there. After each upward step, if `Y` is less than 1 the shot is discarded. A shot that flew through to row 0 would otherwise rub a letter out of `SCORE`.

## A new wave, and game over

When the last living invader is hit, `N` reaches 0 and the program does not print `WAVE CLEARED` on row 0 any more. It increments `WV`, plays three very short rising notes, and calls the same set-up subroutine that the first wave used. That routine clears the screen, reprints the status, rebuilds the 32 invaders, redraws the shields, and puts the base back. The score and the remaining lives are left as they are.

Each new wave starts one row lower, and waits a little less between march steps. Wave 1 starts at `BY=1` with `W=8`, as in steps 4 to 7. Wave 2 starts at `BY=2` with `W=7`, and so on, until `BY` is capped at 8 (so a late wave does not begin on the shields) and `W` is capped at 2 (so the block still has a pause between ripple steps). The extra row and the shorter wait were measured in Fuse, and the figures are in the timing table below.

Game over plays a short descending tune, clears the screen, and prints `GAME OVER`, the reason, the score, the wave, and `PRESS ANY KEY TO PLAY AGAIN`. The key wait is the same one as in Chapter 2: wait until any held key has gone up, then wait for a fresh press, then `RUN`. `RUN` forgets the variables and starts the program from the beginning, so the next game has a score of 0, three lives, and wave 1. `GO TO 900` would have jumped back to the set-up without forgetting `SC`, `LV` and `WV`.

## Short beeps, and a tune after play has stopped

`BEEP` is a blocking instruction, as it was in Chapter 2. The program stops until the note has finished, so the in-game notes are kept to 0.02 seconds: a high one when a shot is fired, a mid one when an invader is hit, and a low one when a bomb is dropped. Losing a life plays 0.02 seconds at pitch 0 and 0.05 seconds at -12, which is a little longer, but it only happens on a hit. A new wave plays three 0.02-second rising notes after the last invader has already gone. The longer descending tune, 0.08, 0.08, 0.08 and 0.25 seconds, waits until play has already stopped.

Twenty shots of `BEEP 0.02,18` were timed in Fuse with `FRAMES` and took 24 frames, so one note is 1.2 frames (0.024 seconds): the 0.02 seconds of the note, plus a little ROM overhead. That is short, but it is still a hitch in a loop whose idle pass is 6.5 frames. The life pair took 4 frames, and the three wave notes took 3. Those are the numbers for the notes that can sound during play. The game-over tune is written to last about half a second; it is only played on the game-over screen, so it does not stall the loop.

## Invaders that reach the shields

Step 7 recorded a limitation: if the block marched down onto rows 18 and 19, the row strings would overwrite the shields and the map `S()` would not be told. A later shot into one of those cells would then stop on a shield that was no longer on the screen.

The print subroutine at line 80 now calls a short routine at 560 whenever the print row `P` is 18 or 19. That routine walks every column of the clipped string, including the leading and trailing spaces and the gaps between invaders, and sets the matching slot of `S()` to 0 if it was still above 0. The string has already been printed, so the screen and the map stay in step. The first print of a new wave goes through line 884, not through 80, but `BY` is capped at 8, so a wave never begins on the shield rows; the stomp only has to run when a later march step actually draws a row there.

In Fuse, a block whose bottom row was already on 18 marched sideways and erased the top cells of the two middle shields, leaving the outer shields and the bottom row of those two shields in place. A dump of `S()` after that print showed `3 3 3 0 0 0 0 0 0 3 3 3` on the top row of the map and twelve `3`s on the bottom row, which is exactly the band the 17-character string covers from `BX=7`.

## How long the finished game takes

Measured in Fuse, with a counter in the official loop and `FRAMES` (the 16-bit pair at 23672 and 23673) as the stopwatch. The idle and cycle figures are the same measurements as in steps 4 to 7, retaken on this program, with drops disabled so a bomb in flight does not sit inside the count, and with no key and no shot, so the new beeps are not inside the count either.

| What | Frames | Seconds |
|---|---:|---:|
| One idle pass (no key, no shot, no bomb, no march) | 6.5 | 0.13 |
| One official cycle on wave 1 (`W=8` plus one sideways step, 11 passes) | 106 | 2.12 |
| One official cycle on wave 2 (`W=7` plus one sideways step, 10 passes) | 102 | 2.04 |
| One in-game `BEEP 0.02,18` | 1.2 | 0.024 |

Forty idle passes took 261 frames, so one is 6.5. In step 7 that was 6.8 (273 frames). The loop has three new variables, `SC`, `LV` and `WV`, which would usually make every lookup a little slower, but the old `L=0` and `L<>3` guards on the fire, the drop and the march have come out, because those states are no longer used to freeze the loop. The two changes roughly cancel, and the idle pass is not slower. One official cycle of 11 passes on wave 1 took 106 frames, the same as step 7.

A wave 2 cycle, with `W=7` and `BY=2`, is 10 passes and took 102 frames. That is a little faster than wave 1, by one idle pass, about 0.08 seconds a step, and the block also starts one row lower, so it has less far to go before it can land. These are the numbers for Chapter 5 to beat.

## The new BASIC used here

### BEEP

`BEEP duration,pitch` plays a note on the Spectrum's speaker and then continues, as in [Chapter 2, step 6](../chapter-02-bat-and-ball/step6-beep.md). `duration` is the length of the note in seconds. `pitch` is measured in semitones from middle C, which is 0. The CPU sits in the note until it ends, so the in-game beeps stay at 0.02 seconds.

### STR$

`STR$ n` turns a number into a string without the leading and trailing spaces that `PRINT n` would add. Building `"SCORE "+STR$ SC+"    "` and printing it at a fixed column keeps `WAVE` and `LIVES` from drifting as the score goes from one digit to three, the same trick as in Chapter 2, step 7.

### GO SUB and RETURN

The status line is a subroutine at line 800. It is called after set-up, after a score, after a lost life, and at the start of a new wave, so those four places cannot drift out of step. The wave rebuild at line 860 is also a subroutine, shared by the first game and by every later wave.

### RUN

`RUN` starts the program from the beginning. It first forgets all variables, clears the `GO SUB` stack, and restores `DATA` (the same work as `CLEAR`), then runs from line 1. After game over, that is the way to start a new game with a fresh score, three lives, and wave 1.

## The listing

Line 10 jumps over the loop to the set-up at line 900. That clears the screen, seeds `RND`, dimensions the arrays, defines the 16 UDGs, sets the score, lives and wave, and calls the wave subroutine at 860, which prints the status, the block, the base and the shields, and returns. The program then jumps into the loop at line 20. The loop is the step 7 loop, plus the short beeps, the status updates, a respawn or a game over on a hit, a new wave when `N` reaches 0, and a stomp of the shield map when a march row is printed on 18 or 19.

```
10 GO TO 900
20 LET K$=INKEY$
30 IF (K$="o" OR K$="O") AND X>0 THEN PRINT AT 21,X;" ": LET X=X-1: PRINT AT 21,X; INK 4;CHR$ 144
40 IF (K$="p" OR K$="P") AND X<31 THEN PRINT AT 21,X;" ": LET X=X+1: PRINT AT 21,X; INK 4;CHR$ 144
50 IF Y>=0 THEN PRINT AT Y,C;" ": LET Q=Y-BY: IF Q>=0 AND Q<=6 AND Q/2=INT (Q/2) THEN LET R=Q/2+1: LET I=3+2*(Q>=2)+2*(Q=6): LET P=Y: GO SUB 70
52 IF Y>=0 THEN LET Y=Y-1: IF Y<1 THEN LET Y=-1
54 IF Y>=0 THEN GO SUB 300
56 IF Y>=0 THEN GO SUB 390: IF Y>=0 THEN GO SUB 500: IF Y>=0 THEN PRINT AT Y,C; INK 6;CHR$ 145
58 IF T>0 THEN LET T=T-1: IF T=0 THEN PRINT AT G,H;" ": LET G=-1
59 IF U>=0 THEN PRINT AT U,D;" ": LET U=U+1: GO SUB 400
60 IF U>=0 THEN GO SUB 520: IF U>=0 THEN PRINT AT U,D; INK 2;CHR$ 146
61 IF Y<0 AND K$=" " THEN LET C=X: LET Y=20: BEEP 0.02,18: GO SUB 300: IF Y>=0 THEN GO SUB 390: IF Y>=0 THEN GO SUB 500: IF Y>=0 THEN PRINT AT Y,C; INK 6;CHR$ 145
62 IF U<0 THEN LET J=J+1: IF J>=12 THEN GO SUB 450
63 IF S>0 THEN GO SUB 220: GO TO 68
64 LET M=M+1: IF M>=W THEN GO SUB 100
68 GO TO 20
70 IF S=0 OR R<=S THEN GO SUB 80: RETURN
72 IF E=1 THEN LET P=P+1: LET F=3-F: GO SUB 80: LET F=3-F: RETURN
74 LET BX=BX+DX: LET F=3-F: GO SUB 80: LET F=3-F: LET BX=BX-DX
76 RETURN
80 LET Z=BX: LET U$=A$(R,F)
81 IF BX<0 THEN LET Z=0: LET U$=A$(R,F)(1-BX TO 17)
82 IF BX>15 THEN LET U$=A$(R,F)(1 TO 32-BX)
83 PRINT AT P,Z; INK I;U$
84 IF P=18 OR P=19 THEN GO SUB 560
85 RETURN
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
150 IF BY+6>=20 THEN LET L=1: GO TO 810
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
374 LET N=N-1: LET SC=SC+10+10*(R<4)+10*(R=1): BEEP 0.02,8: GO SUB 800
375 IF N=0 THEN GO SUB 850
376 RETURN
390 IF U<0 OR C<>D OR (Y<>U AND Y<>U+1) THEN RETURN
392 PRINT AT Y,C;" ": IF U>=0 AND (U<>Y) THEN PRINT AT U,D;" "
394 LET Y=-1: LET U=-1
396 RETURN
400 IF U>21 THEN LET U=-1: RETURN
402 IF Y>=0 AND C=D AND (Y=U OR Y=U+1) THEN GO SUB 392: RETURN
404 IF U=21 AND D=X THEN GO TO 410
406 RETURN
410 LET U=-1: LET Y=-1
412 PRINT AT 21,X; INK 6;CHR$ 159
414 BEEP 0.02,0: BEEP 0.05,-12
416 LET LV=LV-1: GO SUB 800
418 IF LV=0 THEN LET L=3: GO TO 810
420 PRINT AT 21,X;" ": LET X=15
422 PRINT AT 21,X; INK 4;CHR$ 144
424 RETURN
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
477 BEEP 0.02,-20
478 RETURN
500 LET P=Y: LET B=C: GO SUB 530: IF P=-1 THEN LET Y=-1
502 RETURN
520 LET P=U: LET B=D: GO SUB 530: IF P=-1 THEN LET U=-1
522 RETURN
530 IF P<>18 AND P<>19 THEN RETURN
532 LET Q=B-3: IF Q<0 OR Q>26 THEN RETURN
534 LET A=Q-8*INT (Q/8): IF A>2 THEN RETURN
536 LET K=3*INT (Q/8)+A+1: LET R=P-17
538 IF S(R,K)=0 THEN RETURN
540 LET S(R,K)=S(R,K)-1
542 IF S(R,K)=0 THEN PRINT AT P,B;" ": GO TO 548
544 IF S(R,K)=1 THEN PRINT AT P,B; INK 4;CHR$ 158: GO TO 548
546 PRINT AT P,B; INK 4;CHR$ 157
548 LET P=-1
550 RETURN
560 FOR B=Z TO Z+LEN U$-1
562 LET Q=B-3: IF Q<0 OR Q>26 THEN GO TO 578
564 LET A=Q-8*INT (Q/8): IF A>2 THEN GO TO 578
566 LET K=3*INT (Q/8)+A+1
568 IF S(P-17,K)>0 THEN LET S(P-17,K)=0
578 NEXT B
580 RETURN
800 PRINT AT 0,0;"SCORE "+STR$ SC+"    "
802 PRINT AT 0,13;"WAVE "+STR$ WV
804 PRINT AT 0,22;"LIVES "+STR$ LV
806 RETURN
810 BEEP 0.08,7: BEEP 0.08,4: BEEP 0.08,0: BEEP 0.25,-12
812 CLS
814 PRINT AT 8,11;"GAME OVER"
816 IF L=1 THEN PRINT AT 10,7;"THEY HAVE LANDED"
817 IF L=3 THEN PRINT AT 10,9;"OUT OF LIVES"
818 PRINT AT 12,10;"SCORE "+STR$ SC
819 PRINT AT 13,11;"WAVE "+STR$ WV
820 PRINT AT 16,2;"PRESS ANY KEY TO PLAY AGAIN"
822 IF INKEY$<>"" THEN GO TO 822
824 IF INKEY$="" THEN GO TO 824
826 RUN
850 LET WV=WV+1
852 BEEP 0.02,0: BEEP 0.02,4: BEEP 0.02,7
854 GO SUB 860
856 RETURN
860 LET BX=7: LET BY=WV: IF BY>8 THEN LET BY=8
862 LET W=9-WV: IF W<2 THEN LET W=2
864 CLS
866 GO SUB 800
868 FOR R=1 TO 4
870 FOR J=1 TO 2
872 LET U=146+J+2*(R>1)+2*(R=4)
874 LET S$=" "
876 FOR K=1 TO 8: LET V(R,K)=1: LET S$=S$+CHR$ U+" ": NEXT K
878 LET A$(R,J)=S$
880 NEXT J
882 LET I=3+2*(R>1)+2*(R=4)
884 PRINT AT BY+2*(R-1),BX; INK I;A$(R,1)
886 NEXT R
888 LET F=1: LET DX=1: LET M=0: LET L=0: LET S=0: LET E=0
890 LET N=32: LET T=0: LET G=-1: LET U=-1: LET J=0: LET Y=-1
892 PRINT AT 21,X; INK 4;CHR$ 144
894 GO SUB 980
896 RETURN
900 BORDER 0: PAPER 0: INK 7: CLS
902 RANDOMIZE
905 DIM V(4,8): DIM A$(4,2,17): DIM S(2,12)
910 RESTORE 990
920 FOR N=0 TO 7: READ D: POKE USR "a"+N,D: NEXT N
930 FOR N=0 TO 7: READ D: POKE USR "b"+N,D: NEXT N
931 FOR N=0 TO 7: READ D: POKE USR "c"+N,D: NEXT N
932 RESTORE 1000
934 FOR N=0 TO 47: READ D: POKE USR "d"+N,D: NEXT N
936 RESTORE 1060
938 FOR N=0 TO 7: READ D: POKE USR "p"+N,D: NEXT N
939 RESTORE 1070: FOR N=0 TO 47: READ D: POKE USR "j"+N,D: NEXT N
940 LET X=15: LET Y=-1: LET C=0: LET D=0
941 LET SC=0: LET LV=3: LET WV=1
942 GO SUB 860
970 GO TO 20
980 FOR K=0 TO 3
981 LET B=3+8*K
982 PRINT AT 18,B; INK 4;CHR$ 154;CHR$ 153;CHR$ 155
983 PRINT AT 19,B; INK 4;CHR$ 153;CHR$ 156;CHR$ 153
984 FOR R=1 TO 2: FOR A=1 TO 3: LET S(R,3*K+A)=3: NEXT A: NEXT R
985 NEXT K
986 RETURN
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
1070 DATA BIN 01111110,BIN 11111111,BIN 11111111,BIN 11111111
1072 DATA BIN 11111111,BIN 11111111,BIN 11111111,BIN 01111110
1074 DATA BIN 00001111,BIN 00011111,BIN 00111111,BIN 01111111
1076 DATA BIN 11111111,BIN 11111111,BIN 11111111,BIN 11111111
1078 DATA BIN 11110000,BIN 11111000,BIN 11111100,BIN 11111110
1080 DATA BIN 11111111,BIN 11111111,BIN 11111111,BIN 11111111
1082 DATA BIN 11111111,BIN 11111111,BIN 11111111,BIN 11100111
1084 DATA BIN 11000011,BIN 11000011,BIN 11000011,BIN 11000011
1086 DATA BIN 01101110,BIN 11011011,BIN 10111101,BIN 01110110
1088 DATA BIN 11011101,BIN 10110111,BIN 01101111,BIN 11011010
1090 DATA BIN 01001010,BIN 10010000,BIN 00100101,BIN 01000010
1092 DATA BIN 10010100,BIN 00001001,BIN 01010010,BIN 10001000
9000 REM Variables, kept at the end so GO TO 20 does not walk past them
9010 REM X=base column 0-31, on row 21
9020 REM K$=key read by INKEY$, or ""
9030 REM Y=shot row, or -1 if no shot is in flight; a shot stops at row 1 so it does not rub out the status line
9040 REM C=shot column, 0 until a shot is fired, then set to X
9050 REM BX=left column of the 17-character row strings, or -1 at the left edge
9060 REM BY=top row of the block, set from the wave number, and capped at 8
9070 REM V(4,8)=1 if that invader is alive, 0 if not
9080 REM A$(4,2,17)=four rows, two animation frames, 17 characters each
9090 REM F=animation frame 1 or 2
9100 REM DX=march direction, 1 right or -1 left
9110 REM M=passes since the last march step finished
9120 REM W=passes to wait before starting the next march step, 8 on wave 1, down to 2
9130 REM L=1 if the invaders have landed, 3 if the last life was lost, 0 during play
9140 REM S=block rows still to draw in this march step, or 0; S(2,12) is the shield map
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
9300 REM B=left column of the string for the row being hit, or a column in a shield test
9310 REM A=column total, used to find the living edges, or a remainder in a shield test
9320 REM D=bomb column, or one byte of a UDG during set-up
9330 REM Z=clipped print column, 0-31
9340 REM U$=clipped row string or spaces, for print and erase
9350 REM U=bomb row, or -1 if no bomb is in flight
9360 REM J=passes since the last drop was tried
9370 REM I=retry count when picking a column to drop from, then the living row found
9380 REM S(2,12)=damage of each shield cell, 3 intact down to 0 gone
9390 REM SC=score, 30 for a top invader, 20 for a middle, 10 for a bottom
9400 REM LV=lives left, 3 at the start of a game
9410 REM WV=wave number, 1 at the start of a game
```

## Line by line

- **10–50** are the step 7 loop up to the shot restore, unchanged.
- **52** after the shot has been rubbed out, `Y` is reduced, and if it would now be on the status line it is discarded.
- **54–60** are the invader test, the cancel, the shield test, the explosion timer, and the bomb move, as in step 7.
- **61** fires with Space, plays `BEEP 0.02,18`, and then tests the new cell as before. The old `L<>3` guard has gone, because a lost life no longer freezes the loop.
- **62–64** are the drop timer and the march. The old `L=0` guards have gone for the same reason.
- **70–76** restore a row that a shot has just left, as in step 7.
- **80–85** print a clipped row string, and if that row is 18 or 19, `GO SUB 560` to clear any shield cells the string has just covered.
- **90–156** erase a row, start a march step, and land or go down, as in step 7, except that a landing now sets `L=1` and goes to the game-over screen at 810.
- **220–248** draw one row of a ripple, as in step 7. A down step still erases the old row with line 90; by then the stomp has already run on the print.
- **300–372** are the invader hit test, as in step 7.
- **374–375** add the points for that row, play `BEEP 0.02,8`, reprint the status, and if `N` is now 0, `GO SUB 850` to start the next wave.
- **390–406** cancel a shot against a bomb, and test a bomb against the base, as in step 7.
- **410–424** a bomb has hit the base: print the explosion, play the life beeps, reduce `LV`, and reprint the status. If no lives remain, set `L=3` and go to game over. Otherwise rub the explosion out, put the base back at column 15, and return to the loop.
- **450–478** drop a bomb as in step 7, then play `BEEP 0.02,-20`.
- **500–550** are the shield hit test, as in step 7.
- **560–580** walk each column of the clipped string on row 18 or 19 and set the matching slot of `S()` to 0.
- **800–806** print `SCORE`, `WAVE` and `LIVES` on row 0, then return.
- **810–826** play the descending tune, clear the screen, print the game-over message, wait for a fresh key, and `RUN`.
- **850–856** increment the wave, play the three short notes, and `GO SUB 860`.
- **860–896** set `BX`, `BY` and `W` from the wave number, clear the screen, reprint the status, rebuild the 32 invaders, reset the march, the shot and the bomb, print the base, and redraw the shields.
- **900–942** set the colours, seed `RND`, dimension the arrays, define the 16 UDGs, set `SC=0`, `LV=3` and `WV=1`, and `GO SUB 860` for wave 1. The program then jumps into the loop at line 20.
- **980–1092** are the shield drawer and the UDG `DATA`, as in step 7.
- **9000–9410** name the variables. The new ones are **SC**, **LV** and **WV**. **L** is now only 1 or 3 on the way to game over, and 0 during play. **Y** is no longer allowed to be 0.

In Fuse, the status line showed `SCORE 0`, `WAVE 1` and `LIVES 3` at the start of a game. A shot up one column scored 10, then 30, then 50, then 80 as it took a bottom, a middle, a middle and a top invader, and the status line followed. A bomb on the base printed the explosion, left `LIVES 2`, and put the base back at column 15, and the player could still fire. With one life left, the same hit went to `GAME OVER` / `OUT OF LIVES`. A block that had already reached the landing row went to `GAME OVER` / `THEY HAVE LANDED`. A last remaining invader, once shot, led to wave 2: the status showed `SCORE 110` (the test started at 100 and added 10 for that bottom invader), `WAVE 2` and `LIVES 3`, the block was rebuilt one row lower with `W=7`, and the shields were fresh. After game over, a key ran the program from the start. A shot up column 0 stopped at row 1 and left the status line intact.

## Limitations you will notice

The loop is no slower than step 7 when nothing is being fired or dropped: 6.5 frames for an idle pass against 6.8, and 106 frames for an official cycle, the same as step 7. A `BEEP 0.02` still adds 1.2 frames whenever a shot is fired, an invader is hit, or a bomb is dropped, and that hitch is visible. Machine code can click the speaker without sitting in the ROM's `BEEP` routine, and it can update the score and start a new wave on the next frame rather than after a visible clear and rebuild.

`INKEY$` still reads one key at a time, so you cannot hold O or P and fire at the same moment. Caps Shift and Space is still Break, as in step 2. Those are the first things Chapter 5's machine code has to fix.

`RUN` forgets the last score, so there is no high-score line to beat. A late wave is only a little faster than wave 1, and the invaders still move by whole character cells. The shields still erode a cell at a time. All of those can be improved in machine code, and some are left as exercises here.

## Running it

A screenshot of the finished game at the start of wave 1, with `SCORE 0`, `WAVE 1` and `LIVES 3` on the status line, the block at its starting row, the four shields, and the base, is in `step8-game.png`.

To build the tape and open it in Fuse, from the course folder, on Windows:

```
windows-tools\build.bat chapter-04-invaders-basic\step8-game.bas step8 10
```

On Linux:

```
tools/build.sh chapter-04-invaders-basic/step8-game.bas step8 10
```

`step8` is the name stored on the tape, which `LOAD` shows as `Program: step8`, and `10` is the line the program runs from after it loads. Fuse opens with the tape loading by itself. Hold O and P to move, and press Space to fire. Break the program with Caps Shift and Space (in Fuse, Shift and Space).

You can also load the ready-made `step8-game.tap` in any 48K emulator and type `LOAD ""`. The helper script `tools/run-tap.sh chapter-04-invaders-basic/step8-game.bas` builds the tape and runs it in Fuse under Xvfb; see [tools/README.md](../tools/README.md). Set `TAP_NAME=step8` if you want the name on the tape to match the ready-made file.

## Try this

Change the points on line 374. `20*(5-R)` would give 80, 60, 40 and 20 down the block, and you will see the status line follow, as long as you keep the `STR$` and the padding.

Give yourself one life, or five, by changing the `3` on line 941. The respawn at 420 and the game-over test at 418 do not care what the starting count was.

Make later waves quicker by changing `9-WV` on line 862 to `8-WV`, or drop the floor from 2 to 1. Time a cycle again with `FRAMES` if you do: the wave 2 figure above is 102 frames with `W=7`.

Raise the in-game `BEEP` on line 61 from 0.02 to a tenth of a second and fire a few shots. The hitch in the loop is then obvious, which is why the notes were kept short.
