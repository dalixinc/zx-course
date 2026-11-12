# Chapter 4, step 7 — Shields

This is the seventh step of the Invaders-style game that Chapter 4 builds in pure Sinclair BASIC. [Step 1](step1-base.md) put the player's base on the bottom row. [Step 2](step2-shot.md) added a shot. [Step 3](step3-block.md) put up the invaders. [Step 4](step4-march.md) made them march. [Step 5](step5-hits.md) made a shot kill an invader. [Step 6](step6-bombs.md) gave the invaders bombs. This step puts four shields between the player and the block. Each shield is three cells wide and two high, and a hit from a shot or a bomb eats a cell in stages: the original shape, a damaged one, a badly damaged one, then a space. A proper score, lives, waves and sound belong in step 8.

The program is laid out in the same way as steps 1 to 6. Line 10 jumps over the loop to the set-up at line 900. The loop sits at the top, and the `REM` lines for the variables stay at the end.

Every program is tested in a 48K emulator before it is shown.

## The shield UDGs

Six new UDGs, J to O, codes 153 to 158, are printed in green (`INK 4`), the same ink as the base. J is a full block, K and L are the top-left and top-right corners, and M is the arch under the middle of a shield. N and O are a damaged and a badly damaged shape, used for every cell once it has been hit, so six UDGs cover the four shields. Bit 7 is the leftmost pixel and bit 0 the rightmost. `#` is ink (a 1) and `.` is paper (a 0).

**UDG J**, a full block, used on the top middle and on the two bottom corners.

```
        bit  7 6 5 4 3 2 1 0      BIN         decimal
row 0        0 1 1 1 1 1 1 0      01111110     126
row 1        1 1 1 1 1 1 1 1      11111111     255
row 2        1 1 1 1 1 1 1 1      11111111     255
row 3        1 1 1 1 1 1 1 1      11111111     255
row 4        1 1 1 1 1 1 1 1      11111111     255
row 5        1 1 1 1 1 1 1 1      11111111     255
row 6        1 1 1 1 1 1 1 1      11111111     255
row 7        0 1 1 1 1 1 1 0      01111110     126

        .######.
        ########
        ########
        ########
        ########
        ########
        ########
        .######.
```

**UDG K**, the top-left corner.

```
        bit  7 6 5 4 3 2 1 0      BIN         decimal
row 0        0 0 0 0 1 1 1 1      00001111      15
row 1        0 0 0 1 1 1 1 1      00011111      31
row 2        0 0 1 1 1 1 1 1      00111111      63
row 3        0 1 1 1 1 1 1 1      01111111     127
row 4        1 1 1 1 1 1 1 1      11111111     255
row 5        1 1 1 1 1 1 1 1      11111111     255
row 6        1 1 1 1 1 1 1 1      11111111     255
row 7        1 1 1 1 1 1 1 1      11111111     255

        ....####
        ...#####
        ..######
        .#######
        ########
        ########
        ########
        ########
```

**UDG L**, the top-right corner, is the mirror of K.

```
        11110000      240        ####....
        11111000      248        #####...
        11111100      252        ######..
        11111110      254        #######.
        11111111      255        ########
        11111111      255        ########
        11111111      255        ########
        11111111      255        ########
```

**UDG M**, the arch under the middle.

```
        11111111      255        ########
        11111111      255        ########
        11111111      255        ########
        11100111      231        ###..###
        11000011      195        ##....##
        11000011      195        ##....##
        11000011      195        ##....##
        11000011      195        ##....##
```

**UDG N**, damaged, and **UDG O**, badly damaged, are generic. They replace whichever original shape sat in the cell.

```
N, damaged:
        01101110      110        .##.###.
        11011011      219        ##.##.##
        10111101      189        #.####.#
        01110110      118        .###.##.
        11011101      221        ##.###.#
        10110111      183        #.##.###
        01101111      111        .##.####
        11011010      218        ##.##.#.

O, badly damaged:
        01001010       74        .#..#.#.
        10010000      144        #..#....
        00100101       37        ..#..#.#
        01000010       66        .#....#.
        10010100      148        #..#.#..
        00001001        9        ....#..#
        01010010       82        .#.#..#.
        10001000      136        #...#...
```

## Four shields, and a damage map

Each shield is three cells wide and two high. The top row is a left corner, a full block and a right corner (K, J, L). The bottom row is a full block, an arch and a full block (J, M, J). Together they read as a small bunker with a doorway.

The four shields sit on rows 18 and 19, in columns 3 to 5, 11 to 13, 19 to 21, and 27 to 29, so there is a two- or three-column margin at each side and a five-column gap between shields. The shot still appears on row 20, just under them, and the base stays on row 21.

The source of truth is a small map, `DIM S(2,12)`, one slot for each of the 12 columns of the four shields, holding a damage level: 3 if the cell is intact, 2 if it is damaged, 1 if it is badly damaged, and 0 if it is gone. A hit decrements that level, prints N, O, or a space, and removes the shot or the bomb. Adjacent cells are left alone. The original UDG is only needed when the shields are first drawn; after a hit the cell is N, O, or empty.

In Sinclair BASIC a scalar `S` and an array `S()` are different variables, so the march ripple can keep using `S` as the number of rows still to draw, and the shields can use `S(R,K)` for damage, without renaming either one.

Finding the slot from a screen position is arithmetic, not a scan of the screen, in the same spirit as the invader hit test. If the row is 18 or 19 and the column `B` is one of the 12 shield cells, `Q=B-3` is 0 to 26, `A=Q-8*INT (Q/8)` is the position inside a group of eight columns, and a value of 0, 1 or 2 means this is a shield cell rather than a gap. The map column is then `3*INT (Q/8)+A+1`, 1 to 12, and the map row is `P-17`, 1 or 2. Anything else, including a hole that is already at 0, is a miss, and the shot or the bomb continues.

In Fuse, all four shields appeared in the planned columns, with the corners, the full blocks and the arches in the right places. A shot that started on the arch of the first shield, at row 19 column 4, turned that cell to N, a second shot (from a test that began already at the damaged level) turned it to O, and a third turned it to a space. Neighbours were untouched. A shot fired up a hole in that cell continued and damaged the full block above it, at row 18 column 4. A bomb that fell from row 16 in column 4 hit the top of the same shield, chipped that cell, and vanished, leaving the arch below intact. A shot in column 7, in the gap between the first two shields, climbed past rows 19 and 18 with every shield cell still intact. Holding Space at column 4, under the first shield, destroyed the arch in three hits, as in the staged tests.

## How long the shields take

Measured in Fuse, with a counter in the official loop and `FRAMES` (the 16-bit pair at 23672 and 23673) as the stopwatch. The idle and cycle figures are the same measurements as in step 6, retaken on this program, with drops disabled so a bomb in flight does not sit inside the count.

| What | Frames | Seconds |
|---|---:|---:|
| One idle pass (no key, no shot, no bomb, no march) | 6.8 | 0.14 |
| One official cycle (`W=8` idle passes plus one sideways step) | 106 | 2.12 |
| One pass that moves a shot from row 20 onto a shield cell and damages it | 24 | 0.48 |

Forty idle passes took 273 frames, so one is 6.8. In step 6 that was 6.7: the extra is the two comparisons that skip the shield test when the shot and the bomb are not on rows 18 or 19, and the extra variables. One official cycle of 11 passes took 106 frames, against 104 in step 6. The one-pass shield hit took 24 frames, which includes the invader test, the cancel test, the map lookup, and the reprint of the damaged cell. These are the numbers for Chapter 5 to beat.

`W` stays 8.

## The new BASIC used here

### A scalar and an array with the same name

`S` is still the number of block rows left in a ripple, as in step 4. `DIM S(2,12)` is a different variable. `LET S=0` does not clear the shield map, and `LET S(R,K)=S(R,K)-1` does not change the ripple counter. The plan's name `S` can be kept for the map without renaming the march.

## The listing

Line 10 jumps over the loop to the set-up at line 900. That clears the screen, seeds `RND`, dimensions `V`, `A$` and `S`, defines the 16 UDGs from the `DATA` (A, B, C, D to I, P, and now J to O), builds the row strings, prints the block, the base and the four shields, and jumps into the loop at line 20. The loop is the step 6 loop, plus a shield test on every shot step and every bomb step.

```
10 GO TO 900
20 LET K$=INKEY$
30 IF (K$="o" OR K$="O") AND X>0 THEN PRINT AT 21,X;" ": LET X=X-1: PRINT AT 21,X; INK 4;CHR$ 144
40 IF (K$="p" OR K$="P") AND X<31 THEN PRINT AT 21,X;" ": LET X=X+1: PRINT AT 21,X; INK 4;CHR$ 144
50 IF Y>=0 THEN PRINT AT Y,C;" ": LET Q=Y-BY: IF Q>=0 AND Q<=6 AND Q/2=INT (Q/2) THEN LET R=Q/2+1: LET I=3+2*(Q>=2)+2*(Q=6): LET P=Y: GO SUB 70
52 IF Y>=0 THEN LET Y=Y-1
54 IF Y>=0 THEN GO SUB 300
56 IF Y>=0 THEN GO SUB 390: IF Y>=0 THEN GO SUB 500: IF Y>=0 THEN PRINT AT Y,C; INK 6;CHR$ 145
58 IF T>0 THEN LET T=T-1: IF T=0 THEN PRINT AT G,H;" ": LET G=-1
59 IF U>=0 THEN PRINT AT U,D;" ": LET U=U+1: GO SUB 400
60 IF U>=0 THEN GO SUB 520: IF U>=0 THEN PRINT AT U,D; INK 2;CHR$ 146
61 IF Y<0 AND K$=" " AND L<>3 THEN LET C=X: LET Y=20: GO SUB 300: IF Y>=0 THEN GO SUB 390: IF Y>=0 THEN GO SUB 500: IF Y>=0 THEN PRINT AT Y,C; INK 6;CHR$ 145
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
969 GO SUB 980
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
9300 REM B=left column of the string for the row being hit
9310 REM A=column total, used to find the living edges
9320 REM D=bomb column, or one byte of a UDG during set-up
9330 REM Z=clipped print column, 0-31
9340 REM U$=clipped row string or spaces, for print and erase
9350 REM U=bomb row, or -1 if no bomb is in flight
9360 REM J=passes since the last drop was tried
9370 REM I=retry count when picking a column to drop from, then the living row found
9380 REM S(2,12)=damage of each shield cell, 3 intact down to 0 gone
```

The source is `step7-shields.bas`. A tape image ready to load is `step7-shields.tap`, with the program name `shields`.

## Line by line

- **10–54** are the step 6 loop up to the invader hit test, unchanged.
- **56** after a possible cancel, `GO SUB 500` tests the new shot cell against the shields, and only then is the shot redrawn.
- **58–59** are the explosion timer and the bomb move, as in step 6.
- **60** `GO SUB 520` tests the new bomb cell against the shields before the bomb is redrawn.
- **61** fires with Space, as in step 6, and the new cell is also tested against the shields.
- **62–68** are the drop timer and the march, as in step 6.
- **70–478** are the restore, the clipped print, the march, the invader hit, the shot/bomb cancel, the base hit, and the drop, as in step 6.
- **500–502** test the shot: copy `Y` and `C` into `P` and `B`, `GO SUB 530`, and if the shield ate the shot, set `Y=-1`.
- **520–522** do the same for the bomb, with `U` and `D`.
- **530–550** if `P` is 18 or 19 and `B` is a shield column, look up `S(R,K)`. If the level is already 0, return and the shot or bomb continues. Otherwise decrement it, print a space, O, or N, and set `P=-1` so the caller clears the shot or the bomb.
- **900–939** set the colours, seed `RND`, dimension the arrays, and define all 16 UDGs. J to O are poked from `USR "j"` in one loop of 48 bytes, after P.
- **940–970** put the base and the block at their starting places, `GO SUB 980` to draw the shields, and jump into the loop. `W` is still 8.
- **980–986** print the four shields and set every slot of `S(2,12)` to 3.
- **990–1065** hold A, B, C, D to I, and P, as in step 6.
- **1070–1092** hold J, K, L, M, N and O, eight bytes each, in that order, written with `BIN`.
- **9000–9380** name the variables. The new array is **S(2,12)**. The shield test reuses **P**, **B**, **Q**, **A**, **R** and **K**.

In Fuse, with the official `W=8`, the block still marched, bombs still dropped, and a shot still killed an invader above the shields. A shot or a bomb that hit a shield cell ate it in three stages, a shot through a hole damaged the cell above, and a shot in a gap climbed through. The base could be steered the whole time.

## Limitations you will notice

The loop is almost as fast as step 6 when no shot or bomb is on a shield row: 6.8 frames for an idle pass against 6.7, and 106 frames for an official cycle against 104. A pass that actually hits a shield is heavier, 24 frames. Machine code can nibble a shield a byte or a pixel at a time, which looks much closer to the arcade game.

If the invaders march down onto rows 18 and 19, their row strings will simply overwrite the shields, and the map `S` will not be told. The plan asked for invaders to eat shields too; this step does not yet do that. A later pass, or step 8, can test a march row against the map.

The landing message, the cleared-wave message, and `YOU ARE HIT` still share row 0. A shot that later flies through one of those columns can rub a letter out.

`INKEY$` still reads one key at a time, and Caps Shift and Space is still Break, as in step 2.

## Running it

A screenshot of the four shields in place, with the block and the base at their starting positions, is in `step7-shields.png`.

To build the tape and open it in Fuse, from the course folder, on Windows:

```
windows-tools\build.bat chapter-04-invaders-basic\step7-shields.bas shields 10
```

On Linux:

```
tools/build.sh chapter-04-invaders-basic/step7-shields.bas shields 10
```

`shields` is the name stored on the tape, which `LOAD` shows as `Program: shields`, and `10` is the line the program runs from after it loads. Fuse opens with the tape loading by itself. Hold O and P to move, and press Space to fire. Shots and bombs will eat the shields in stages. Break the program with Caps Shift and Space (in Fuse, Shift and Space).

You can also load the ready-made `step7-shields.tap` in any 48K emulator and type `LOAD ""`. The helper script `tools/run-tap.sh chapter-04-invaders-basic/step7-shields.bas` builds the tape and runs it in Fuse under Xvfb; see [tools/README.md](../tools/README.md). Set `TAP_NAME=shields` if you want the name on the tape to match the ready-made file.

## Try this

Move the shields by changing the `3+8*K` on line 981. `2+9*K` spreads them differently, and you will also need to change the arithmetic on lines 532 to 536 so the map still matches the screen.

A colour per shield, or a different ink for a damaged cell, is a one-line change in 544 and 546, and does not affect the hit test, which uses the map, not `ATTR`.
