# Chapter 4, step 5 — Shot versus invader

This is the fifth step of the Invaders-style game that Chapter 4 builds in pure Sinclair BASIC. [Step 1](step1-base.md) put the player's base on the bottom row. [Step 2](step2-shot.md) added a shot, fired with Space. [Step 3](step3-block.md) put up a still block of 32 invaders, drawn as row strings. [Step 4](step4-march.md) made that block march, walk with two frames, and step down at the edges. This step makes a shot that reaches a living invader kill it. The invader is cleared from the array and from both animation strings, a brief explosion is shown, and the shot is removed. The march then uses only the living columns, so a remnant can travel farther towards the side than the original rectangle. If all 32 are cleared, the program prints a placeholder message and stops the march; a new wave belongs in step 8.

The program is laid out in the same way as steps 1 to 4. Line 10 jumps over the loop to the set-up at line 900. The loop sits at the top, and the `REM` lines for the variables stay at the end.

Every program is tested in a 48K emulator before it is shown.

## UDG P, the explosion

UDG P, code 159, is a yellow starburst (`INK 6`, the same ink as the shot). Bit 7 is the leftmost pixel and bit 0 the rightmost. `#` is ink (a 1) and `.` is paper (a 0). The pattern is symmetric top-to-bottom.

```
        bit  7 6 5 4 3 2 1 0      BIN         decimal
row 0        1 0 1 0 0 1 0 1      10100101     165
row 1        0 1 0 1 1 0 1 0      01011010      90
row 2        1 0 1 1 1 1 0 1      10111101     189
row 3        0 1 1 1 1 1 1 0      01111110     126
row 4        0 1 1 1 1 1 1 0      01111110     126
row 5        1 0 1 1 1 1 0 1      10111101     189
row 6        0 1 0 1 1 0 1 0      01011010      90
row 7        1 0 1 0 0 1 0 1      10100101     165

        #.#..#.#
        .#.##.#.
        #.####.#
        .######.
        .######.
        #.####.#
        .#.##.#.
        #.#..#.#
```

## Why not ATTR or SCREEN$?

There are three realistic ways to decide that a shot has hit an invader, and they are worth walking through, because two of them look tempting and then fall down.

`ATTR`, as used on Chapter 2's bricks, is cheap, and it is a good recap: if the invaders share an ink or a paper that nothing else uses, `ATTR` can say "an invader is in this cell". It cannot say *which* invader. To drop the right entry of `V` you still have to convert the shot's row and column into an index, so `ATTR` does not save the arithmetic. It is also fooled as soon as something else reuses that colour: a bomb in step 6, a shield in step 7, or the status line.

`SCREEN$` looks even better, because it would read the character on the cell. On the Spectrum it is the wrong tool here. `SCREEN$` matches against the standard character set and does not return a user-defined graphic; a UDG cell comes back as an empty string. That is worth knowing, so you do not spend an evening chasing it.

The third way is the one this program uses: the living/dead array `V`, with arithmetic from the shot's position. The block already needs that array so that dead invaders are not redrawn. The shot's row and column, minus the block's current origin, give the index directly, with a bounds check and a test that the slot is still alive. That is reliable over holes, over colour changes, and over the shields and bombs that come next. `ATTR` can be a "Try this" afterwards, as a quick "is this cell even coloured?" experiment, but the hit test itself does not depend on the palette.

## Finding the invader from the shot

The shot is tested after it has been rubbed out and moved, and before it is redrawn, so a hit is decided on the cell the shot has just arrived at. A shot that is fired on row 20 is tested at once as well, in case the bottom of a landed block is already on that row.

An invader row is at `BY`, `BY+2`, `BY+4` or `BY+6`. If `Q=Y-BY` is 0, 2, 4 or 6, the shot is on a row of the block, and the block row is `R=Q/2+1`. Invader column `K` sits at screen column `B+2*K-1`, where `B` is the left column of that row's 17-character string, so `K=(C-B+1)/2` when `C-B+1` is even and in 2 to 16. Anything else is a gap, or is outside the string, and the shot continues.

`B` is not always `BX`. A march step commits `BX` (and the animation frame, and, on a down, `BY` and `DX`) only after the fourth row has rippled, as in step 4. A shot that arrives on a row which has already taken this step must use that row's new place. On a sideways ripple, `B=BX+DX` for rows that have already moved (`R>S`), and `B=BX` for the rest. On a down ripple, already-moved rows are tested at `BY+1`, and the others at `BY`; `B` stays `BX`. Lines 300 to 352 do that bookkeeping, then 360 to 376 do the same hit test for every case.

If `V(R,K)` is already 0, the shot is in a hole and continues. If it is 1, that invader dies.

## A hole in both frames

A kill writes `V(R,K)=0` and puts a space in both animation strings, at the same character that held the invader: `A$(R,1,C-B+1)` and `A$(R,2,C-B+1)`. The next restore, and the next march step, print those strings, so the hole travels with the block for free. The living count `N` goes down by one.

In Fuse, a shot aimed at each of the four row types, with the block still, killed that invader and left a hole: the white bottom row at screen row 7, both cyan rows at 5 and 3, and the magenta top row at 1, all in column 16. The same happened at the left-hand invader (column 8) and the right-hand invader (column 22). A shot that started just under a hole in the bottom row passed through the empty cell and killed the cyan invader above it. A shot fired up a gap, in column 15 between two invaders, went from row 19 to row 0 and left all 32 alive.

## A brief explosion, then the shot is gone

On a hit the program prints UDG P in yellow on the invader's cell, records that cell in `G` and `H`, sets a short timer `T=3`, and sets `Y=-1` so the shot is not redrawn. `PAUSE` would freeze `INKEY$` for the whole burst, so the timer lives in the main loop instead: each pass decrements `T`, including the hit pass itself, and when `T` reaches 0 the cell is printed as a space. The burst is visible for the hit pass and two more, and the player can still move while it is up.

In Fuse, the yellow starburst appeared on the cell in place of the invader, the neighbours were untouched, and two passes later the cell was empty. The shot did not continue above the hit.

## The march uses only living columns

The edge scan from step 4 was already looking at `V`, but until this step every column was alive, so the living edges were always 1 and 8 and the 17-character string always sat in the official 18 positions, `BX` from -1 to 16. Once an outer column is dead, `LM` or `RM` moves in, and the next sideways step is allowed until a still-living invader would pass column 0 or 31: `BX+2*LM-1+DX<0` or `BX+2*RM-1+DX>31`. A remnant can therefore travel farther towards the side than the original rectangle.

That means `BX` can leave the range -1 to 16, and `PRINT AT` would error if the program still printed the whole 17-character string at that column. The print and erase routines now clip. If `BX` is negative, the off-screen left characters are dropped and the rest is printed at column 0; if `BX` is greater than 15, only the characters that fit up to column 31 are printed, at `BX`. The same number of spaces is used to erase a row on a down step.

In Fuse, a test that started with column 1 already dead, `BX=2` and `DX=-1`, marched left until the first living invader reached column 0, then stepped down and came back right. A test that started with column 8 already dead marched right until the last living invader reached column 31, then stepped down and came back left. In both cases the old rectangle would have turned two columns earlier. After those downs the hole stayed in the outer column, and the clipped print left no trail and no wrap.

If the scan finds no living column at all (`LM=0`), it returns without starting a step, so a cleared wave does not march.

## When the wave is cleared

`N` starts at 32 and is decremented on each kill. When it reaches 0, the program sets `L=2` and prints `WAVE CLEARED` on row 0, at column 10, in white. Line 64 already refuses a new march step when `L` is not 0, so the same flag that stops a landing also stops a cleared wave. The player can still move. A new wave, and a score, belong in step 8. The two messages share row 0; in ordinary play they cannot both appear, because a cleared block never lands.

In Fuse, a test that started with one magenta invader left, in the middle of the top row, let a shot climb through the empty rows beneath it, exploded that last invader, printed `WAVE CLEARED`, and left the march still.

## How long a hit takes

Measured in Fuse, with a counter in the official loop and `FRAMES` (the 16-bit pair at 23672 and 23673) as the stopwatch. The idle and cycle figures are the same measurements as in step 4, retaken on this program. The miss and the hit start a shot already on row 20, with the block still (`W=999`), and stop when `Y` becomes -1.

| What | Frames | Seconds |
|---|---:|---:|
| One idle pass (no key, no shot, no march) | 4.7 | 0.09 |
| One official cycle (`W=8` idle passes plus one sideways step) | 86 | 1.72 |
| A miss, row 20 to off the top, block still (21 passes) | 204 | 4.08 |
| A hit at row 7, fired from row 20, block still (13 passes) | 134 | 2.68 |

Forty idle passes took 188 frames, so one is 4.7. In step 4 that was 4.3: the loop now has the explosion timer, the hit-test subroutine is in the program (it is only called when a shot is in flight), the print routine always builds a clipped copy of the row string, and there are more variables to look up. One official cycle of 11 passes took 86 frames, against 74 in step 4, about 16 per cent slower, for the same reasons. These are the numbers for Chapter 5 to beat, not the step 4 ones.

A miss that travels 21 steps, with the block still, took 204 frames, 9.7 frames a step (4.08 seconds to the top). In step 4 the same flight, with no hit test, was 7.4 frames a step. The extra is `GO SUB 300` on every shot step, even when the cell is a gap or is below the block. A hit at the bottom row, from the same starting row, took 134 frames over 13 passes, 10.3 frames a pass: twelve of those passes are a shot in empty space, and the last one also writes the hole, prints the explosion, and drops `N`.

`W` stays 8 in this step, so the timings can be compared with step 4. Shrinking `W` as `N` falls is a "Try this", and a natural job for step 8.

## The new BASIC used here

### A single character of a string array

`LET A$(R,1,C-B+1)=" "` writes one character of frame 1 of row `R`. The same line does it for frame 2. That is how a hole is cut in both strings without rebuilding them.

### A slice whose start depends on `BX`

`A$(R,F)(1-BX TO 17)` is the on-screen tail of the row string when `BX` is negative: the start index is `1-BX`, so at `BX=-1` it is `(2 TO 17)`, as in step 4, and at `BX=-3` it is `(4 TO 17)`. `A$(R,F)(1 TO 32-BX)` is the on-screen head when `BX` is greater than 15. The erase routine slices a 17-space string in the same way. A short test that marched a remnant to column 0 and to column 31 used these slices without an error.

### Comparisons as 0 or 1, in the mid-ripple origin

`B=BX+DX*(S>0 AND R>S)` uses the fact, already seen in earlier chapters, that a true comparison is 1 and a false one is 0. When a sideways ripple is in progress and this row has already moved, the product is `DX`; otherwise it is 0 and `B` stays `BX`.

## The listing

Line 10 jumps over the loop to the set-up at line 900. That clears the screen, dimensions the arrays, defines the nine UDGs from the `DATA` (A, B, D to I, and now P), builds both frames of the four row strings, prints the block in frame 1, and jumps into the loop at line 20. The loop is the step 4 loop, plus a hit test on every shot step, an explosion timer, and a clipped print so a remnant can leave the old rectangle.

```
10 GO TO 900
20 LET K$=INKEY$
30 IF (K$="o" OR K$="O") AND X>0 THEN PRINT AT 21,X;" ": LET X=X-1: PRINT AT 21,X; INK 4;CHR$ 144
40 IF (K$="p" OR K$="P") AND X<31 THEN PRINT AT 21,X;" ": LET X=X+1: PRINT AT 21,X; INK 4;CHR$ 144
50 IF Y>=0 THEN PRINT AT Y,C;" ": LET Q=Y-BY: IF Q>=0 AND Q<=6 AND Q/2=INT (Q/2) THEN LET R=Q/2+1: LET I=3+2*(Q>=2)+2*(Q=6): LET P=Y: GO SUB 70
52 IF Y>=0 THEN LET Y=Y-1
54 IF Y>=0 THEN GO SUB 300
56 IF Y>=0 THEN PRINT AT Y,C; INK 6;CHR$ 145
58 IF T>0 THEN LET T=T-1: IF T=0 THEN PRINT AT G,H;" ": LET G=-1
60 IF Y<0 AND K$=" " THEN LET C=X: LET Y=20: GO SUB 300: IF Y>=0 THEN PRINT AT Y,C; INK 6;CHR$ 145
62 IF S>0 THEN GO SUB 220: GO TO 68
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
900 BORDER 0: PAPER 0: INK 7: CLS
905 DIM V(4,8): DIM A$(4,2,17)
910 RESTORE 990
920 FOR N=0 TO 7: READ D: POKE USR "a"+N,D: NEXT N
930 FOR N=0 TO 7: READ D: POKE USR "b"+N,D: NEXT N
932 RESTORE 1000
934 FOR N=0 TO 47: READ D: POKE USR "d"+N,D: NEXT N
936 RESTORE 1060
938 FOR N=0 TO 7: READ D: POKE USR "p"+N,D: NEXT N
940 LET X=15: LET Y=-1
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
966 LET N=32: LET T=0: LET G=-1
968 PRINT AT 21,X; INK 4;CHR$ 144
970 GO TO 20
990 DATA BIN 00011000,BIN 00011000,BIN 00011000,BIN 01111110
995 DATA BIN 11111111,BIN 11111111,BIN 11111111,BIN 11111111
996 DATA BIN 00000000,BIN 00011000,BIN 00011000,BIN 00011000
997 DATA BIN 00011000,BIN 00011000,BIN 00011000,BIN 00000000
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
9040 REM C=shot column, set when the shot is fired
9050 REM BX=left column of the 17-character row strings, or -1 at the left edge
9060 REM BY=top row of the block
9070 REM V(4,8)=1 if that invader is alive, 0 if not
9080 REM A$(4,2,17)=four rows, two animation frames, 17 characters each
9090 REM F=animation frame 1 or 2
9100 REM DX=march direction, 1 right or -1 left
9110 REM M=passes since the last march step finished
9120 REM W=passes to wait before starting the next march step
9130 REM L=1 if landed, 2 if the wave is cleared, 0 otherwise
9140 REM S=block rows still to draw in this march step, or 0
9150 REM E=1 if this march step is a down step, 0 if sideways
9160 REM LM=leftmost living invader column 1-8
9170 REM RM=rightmost living invader column 1-8
9180 REM Q=shot row relative to BY, used to restore a row or to test a hit
9190 REM P=print row for a row-string or an erase
9200 REM I=ink for an invader row: 3, 5, 5 or 7
9210 REM R=block row 1-4
9220 REM K=invader column 1-8
9230 REM J=frame 1 or 2, used only while the strings are built
9240 REM U=UDG code 147 to 152
9250 REM S$=a row string built up, then copied into A$
9260 REM N=living invaders, 32 down to 0
9270 REM T=passes left to show an explosion, or 0
9280 REM G=explosion row, or -1 if none
9290 REM H=explosion column, used when G>=0
9300 REM B=left column of the string for the row being hit
9310 REM A=column total, used to find the living edges
9320 REM D=one byte of a UDG
9330 REM Z=clipped print column, 0-31
9340 REM U$=clipped row string or spaces, for print and erase
```

The source is `step5-hits.bas`. A tape image ready to load is `step5-hits.tap`, with the program name `hits`.

## Line by line

- **10** jumps over the loop to the set-up at line 900, as before.
- **20–40** read the key and move the base with O and P, exactly as before.
- **50** if a shot is in flight: prints a space over it, and if it was on an invader row, `GO SUB 70` to restore that row, as in step 4, so a miss does not leave a hole in the string.
- **52** moves the shot up one row, if it is still in flight.
- **54** `GO SUB 300` tests for a hit at the new cell, if the shot is still on the screen.
- **56** redraws the shot, but only if the hit test left `Y` at 0 or more.
- **58** if an explosion is showing, `T` is decreased; when it reaches 0 the cell is printed as a space.
- **60** if there is no shot in flight, Space fires one at the base, and the new cell is tested at once in case it is already on an invader.
- **62–68** are the march timer and the ripple, as in step 4. A new step is still refused when `L` is not 0, which now also covers a cleared wave.
- **70–76** restore a row the shot has just left, at the mid-ripple place if that row has already moved, as in step 4.
- **80–84** print `A$(R,F)` at row `P`, clipped to columns 0 to 31. `Z` is the on-screen column and `U$` is the on-screen slice.
- **90–94** print the same number of spaces at the same place, to erase a row on a down step.
- **100–128** start a step: the living-edge scan sets `LM` and `RM`, and returns at once if nothing is alive. The edge test uses those living columns, then the first row of the ripple is drawn.
- **150–156** land, or start a down step, as in step 4.
- **220–248** draw one row of a sideways or down step, as in step 4, now through the clipped print and erase.
- **300–352** work out the block row `R` and the string's left column `B` for this shot, including mid-ripple and mid-down cases, or return if the shot is not on an invader row.
- **360–364** convert the shot column to invader column `K`, or return if it is a gap, outside the string, or already a hole.
- **366–376** kill the invader: clear `V`, cut a space in both frame strings, print the explosion, start the timer, remove the shot, and decrement `N`. If `N` is 0, set `L=2` and print `WAVE CLEARED`.
- **900–938** set the colours, dimension `V` and `A$`, and define the nine UDGs. P is poked from `USR "p"` after the 48 invader bytes.
- **940–970** put the base and the block at their starting places, set `N=32`, `T=0` and `G=-1`, and jump into the loop. `W` is still 8.
- **990–1055** hold A, B, and D to I, as in step 4.
- **1060–1065** hold P, eight bytes, written with `BIN`.
- **9000–9340** name the variables. The new ones are **N** (the living count), **T**, **G** and **H** (the explosion timer and cell), **B** (the left column of the string for the row being hit), **Z** and **U$** (the clipped print column and string). **L** is now 1 if landed, 2 if the wave is cleared, and 0 otherwise.

In Fuse, with the official `W=8`, the block still waited, rippled, walked, and stepped down at the edges. A shot that hit a living invader left a hole, showed the explosion, and vanished; a shot in a gap or a hole continued. After the outer columns were killed, the remnant reached column 0 and column 31 before turning. Clearing the last invader printed `WAVE CLEARED` and stopped the march. The base could be steered the whole time.

## Limitations you will notice

The loop is a little slower than in step 4: 4.7 frames for an idle pass against 4.3, and 86 frames for an official cycle against 74. A shot in flight is slower still, because every step of it runs the hit test, 9.7 frames a miss-step with the block still, against 7.4 in step 4. Machine code can test a hit every frame and keep the player and the shot on a steady beat.

There is still only one shot at a time, and there is no score. Both can wait until step 8, with lives, a new wave, and sound.

The explosion lasts a few passes of the loop, not a fixed number of frames, so it will linger a little longer if a march row happens to be drawn in the same stretch. That is good enough to read, and it does not freeze the keys.

The landing message and the cleared-wave message both sit on row 0. A shot that later flies through one of those columns can rub a letter out. A proper end screen in step 8 can take the screen over.

`INKEY$` still reads one key at a time, and Caps Shift and Space is still Break, as in step 2. If you hold a direction and Space together, the fire can be missed.

## Running it

A screenshot of a shot that has just hit a bottom-row invader, with the yellow explosion on that cell and the rest of the block intact, is in `step5-hits.png`.

To build the tape and open it in Fuse, from the course folder, on Windows:

```
windows-tools\build.bat chapter-04-invaders-basic\step5-hits.bas hits 10
```

On Linux:

```
tools/build.sh chapter-04-invaders-basic/step5-hits.bas hits 10
```

`hits` is the name stored on the tape, which `LOAD` shows as `Program: hits`, and `10` is the line the program runs from after it loads. Fuse opens with the tape loading by itself. Hold O and P to move, and press Space to fire. A hit leaves a hole and a brief explosion; a miss in a gap climbs to the top. The block will still march, walk, and step down, and once the outer columns are gone it will travel to the very edge before turning. Break the program with Caps Shift and Space (in Fuse, Shift and Space).

You can also load the ready-made `step5-hits.tap` in any 48K emulator and type `LOAD ""`. The helper script `tools/run-tap.sh chapter-04-invaders-basic/step5-hits.bas` builds the tape and runs it in Fuse under Xvfb; see [tools/README.md](../tools/README.md). Set `TAP_NAME=hits` if you want the name on the tape to match the ready-made file.

## Try this

`ATTR` can still be a useful first check. On a shot step, `ATTR (Y,C)` with the official inks will be 3, 5 or 7 when the cell holds an invader, and 0 on paper, and you can print that value for a moment to see it change. It is not enough, on its own, to know which slot of `V` to clear, and a later bomb or shield that reuses an ink will fool it, which is why the shipped test uses the array.

Change line 64 so that `W` depends on `N`. `LET W=1+N/4`, for example, waits eight passes at the start of the wave and only one or two when a handful of invaders remain. In Fuse this is the classic speeding up of a thinning wave, and it is worth timing against the official `W=8` before step 8 bakes in a rule.

Add a running hit count on row 0, `PRINT AT 0,0;32-N`, if you want to see `N` fall while you play. A proper score, with different points per row, belongs in step 8.
