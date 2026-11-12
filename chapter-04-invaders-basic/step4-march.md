# Chapter 4, step 4 — Marching the block

This is the fourth step of the Invaders-style game that Chapter 4 builds in pure Sinclair BASIC. [Step 1](step1-base.md) put the player's base on the bottom row. [Step 2](step2-shot.md) added a shot, fired with Space. [Step 3](step3-block.md) put up a still block of 32 invaders, drawn as row strings. This step makes that block march: it steps sideways, walks with a two-frame animation, and steps down a row and reverses when a living invader would pass the left or right edge of the screen. The base and the shot still work. Shots still pass through the invaders; a hit will kill one in step 5.

The program is laid out in the same way as steps 1 to 3. Line 10 jumps over the loop to the set-up at line 900. The loop sits at the top, and the `REM` lines for the variables stay at the end. The march itself is in subroutines below the loop, so a pass that is not mid-step does not walk past them.

Every program is tested in a 48K emulator before it is shown.

## The second frames

UDGs D, F and H are the first frame of each type, unchanged from step 3, and are still printed in magenta, cyan and white. This step adds the second frame of each type, UDGs E, G and I, codes 148, 150 and 152. The two frames of a type are used on alternate march steps, so the invaders walk as they move. As before, bit 7 is the leftmost pixel and bit 0 the rightmost. `#` is ink (a 1) and `.` is paper (a 0).

**UDG E**, the top-row invader's second frame, is printed in magenta (`INK 3`). The body matches D; the last two rows are swapped, so the legs step.

```
        bit  7 6 5 4 3 2 1 0      BIN         decimal
row 0        0 0 1 1 1 1 0 0      00111100      60
row 1        0 1 1 1 1 1 1 0      01111110     126
row 2        1 1 1 1 1 1 1 1      11111111     255
row 3        1 1 0 1 1 0 1 1      11011011     219
row 4        1 1 1 1 1 1 1 1      11111111     255
row 5        0 1 0 1 1 0 1 0      01011010      90
row 6        0 1 0 0 0 0 1 0      01000010      66
row 7        1 0 1 0 0 1 0 1      10100101     165

        ..####..
        .######.
        ########
        ##.##.##
        ########
        .#.##.#.
        .#....#.
        #.#..#.#
```

**UDG G**, the middle-rows invader's second frame, is printed in cyan (`INK 5`). The claws are out, where F had them in.

```
        bit  7 6 5 4 3 2 1 0      BIN         decimal
row 0        0 0 1 0 0 1 0 0      00100100      36
row 1        1 0 1 0 0 1 0 1      10100101     165
row 2        0 1 1 1 1 1 1 0      01111110     126
row 3        1 1 0 1 1 0 1 1      11011011     219
row 4        1 1 1 1 1 1 1 1      11111111     255
row 5        1 0 1 1 1 1 0 1      10111101     189
row 6        0 0 1 0 0 1 0 0      00100100      36
row 7        1 0 1 0 0 1 0 1      10100101     165

        ..#..#..
        #.#..#.#
        .######.
        ##.##.##
        ########
        #.####.#
        ..#..#..
        #.#..#.#
```

**UDG I**, the bottom-row invader's second frame, is printed in white (`INK 7`). As with E, the last two rows of H are swapped.

```
        bit  7 6 5 4 3 2 1 0      BIN         decimal
row 0        0 0 1 1 1 1 0 0      00111100      60
row 1        1 1 1 1 1 1 1 1      11111111     255
row 2        1 1 1 1 1 1 1 1      11111111     255
row 3        1 1 1 0 0 1 1 1      11100111     231
row 4        1 1 1 1 1 1 1 1      11111111     255
row 5        0 1 0 1 1 0 1 0      01011010      90
row 6        1 0 0 0 0 0 0 1      10000001     129
row 7        1 0 1 0 0 1 0 1      10100101     165

        ..####..
        ########
        ########
        ###..###
        ########
        .#.##.#.
        #......#
        #.#..#.#
```

The six invader UDGs sit in a row in memory, D then E then F then G then H then I. The set-up therefore points `READ` at line 1000 and pokes 48 bytes from `USR "d"` in one loop, rather than six separate eight-byte loops.

## Two strings per row, and room to march

Each row still has a 17-character string: a leading space, then eight invader-and-gap pairs, the last of which is a trailing space. There are now two of those strings per row, one for each animation frame, in `DIM A$(4,2,17)`. `A$(R,1)` is frame 1 (D, F or H) and `A$(R,2)` is frame 2 (E, G or I). Flipping the walk is then just printing the other string.

The leading and trailing spaces are what rub out the trail when the block steps sideways. The string is printed at column `BX`. The invaders occupy columns `BX+1` to `BX+15`. After a step right, the new print sits one column further over, and the leading space covers the column the left-hand invaders just left. After a step left, the trailing space covers the column the right-hand invaders just left. In Fuse, after a sideways step, the old first-invader column was empty: no trail was left behind.

The formation is 15 columns wide, so it has 18 legal positions on a 32-column screen, from the first invader in column 0 to the last invader in column 31. That is 17 columns of travel. `BX` is the left-hand column of the 17-character string, and it runs from `-1` (first invader at 0) to `16` (last invader at 31). A `PRINT AT` that starts at column `-1`, or that would run off column 31, would wrap or error, so at those two edges the program prints a 16-character slice of the string instead: `A$(R,F)(2 TO 17)` at column 0 when `BX=-1`, and `A$(R,F)(1 TO 16)` at column 16 when `BX=16`. In Fuse the last invader reached column 31 with no wrap onto the next line, and the first invader reached column 0, then the block stepped down and came back the other way.

## One row per pass, not the whole block at once

The [plan](PLAN.md#keeping-basic-fast-enough) said the block should be reprinted from the row strings, and that if a whole-block step still made the player stutter, the loop could print one row per pass and finish the step over four passes, rippling from the bottom up, as the arcade game does.

A test of reprinting all four rows in one pass, together with a scan of all 32 cells of `V` to find the living edges, froze the player for about 85 frames (1.7 seconds) on every sideways step. Almost 50 of those frames were the scan itself: a nested loop of 32 tests, `IF V(R,K)=1 THEN IF K<LM THEN LET LM=K` and the same for `RM`, took 49.5 frames in a short timing program (two scans in 99 frames). Four `PRINT AT`s of the row strings are only 4.1 frames on their own, as in step 3, but they cannot start until the scan has finished, and the player is not read while that work runs.

This step therefore does two things the first draft of a whole-block reprint did not. The living-edge scan stops as soon as it has found a living column from the left and from the right, by adding the four cells in that column and, if the total is greater than zero, assigning `LM` or `RM` and setting the loop variable `K` so that `NEXT K` finishes. When all 32 invaders are alive, that is two columns, eight additions, and 4.6 frames (ten scans in 46 frames, with `LM=1` and `RM=8`). If only the middle column is still alive, the same scan takes 15.4 frames and correctly reports `LM=5` and `RM=5`. Step 5 can keep this scan, and will need it once invaders start to die, so a thin remnant can travel farther towards the side.

The reprint itself is spread over four passes. The first pass of a step finds the living edges, then draws the bottom row at the new place and in the new frame. The next three passes of the loop each draw one more row, working up to the top. The player and the shot are still read on every one of those passes. In Fuse the formation ripples from the bottom row up: the white row moves first, then the lower cyan, then the upper cyan, then the magenta, and only then are all 32 in the new position and the new frame.

A down step draws each new row one line lower *before* it erases the old row, so the block never vanishes for a frame. `BX` and `F` (and, on a down step, `BY` and `DX`) are only committed once the fourth row has been drawn, so a shot that has to restore a row which has not yet rippled still reprints it at the old place, in the old frame.

## How often the block moves

The player is read every pass. The block only starts a new step after `W` idle passes since the previous step finished, counted in `M`. This program uses `W=8`. That is a choice, not a rule: small enough that the wave is clearly marching, large enough that the base can still be steered and a shot can be fired in between ripples. `W` can shrink in later steps as the wave thins, which is the classic speeding up.

Measured in Fuse, with a counter in the official loop and `FRAMES` (the 16-bit pair at 23672 and 23673) as the stopwatch:

| What | Frames | Seconds |
|---|---:|---:|
| One idle pass (no key, no shot, no march) | 4.3 | 0.09 |
| One sideways march step (four row-passes, including the edge scan on the first) | 45.1 | 0.90 |
| One down step (four row-passes, each also erasing the old row) | 54 | 1.08 |
| One official cycle (`W=8` idle passes plus one sideways step) | 74 | 1.48 |
| One move of the base, no march in the loop | 4.6 | 0.09 |
| One move of the base, official `W`, averaged over 31 columns | 7.1 | 0.14 |
| One step of the shot, no march in the loop | 7.4 | 0.15 |
| One step of the shot, official `W`, averaged over a flight to the top | 10 | 0.20 |

Fifty idle passes took 215 frames, so one is 4.3. In step 3 that was 2.6: the loop now has the march timer, more variables, and a longer shot-restore test. Eight sideways steps, with `W=1` so that each step is four row-passes and no extra wait, took 361 frames, so one step is 45.125 frames, about 11 frames a row-pass. Three official cycles of 11 passes (seven idle, then the first row of the step, then the three remaining rows) took 222 frames, and one cycle took 74 frames, the same as a single-cycle run. Seven idle passes at 4.3 frames plus one 45-frame step is 75, which matches.

A down step took 54 frames (13.5 a row-pass), a little more than a sideways step, because each of the four passes also prints 16 or 17 spaces over the old row.

The base, with no march, crossed the screen in 143 frames, 4.6 frames a column. With the official `W`, 31 columns took 220 frames, 7.1 a column: the extra 77 frames are about one official cycle falling inside those 31 moves. The shot, with no march, flew 21 steps in 156 frames, 7.4 a step (3.1 seconds to the top). With the official `W`, the same flight was 210 frames, 10 a step (4.2 seconds), so two or three march cycles happen while one shot is in the air. On a cycle that is only idle, the base can still move at 4.6 frames a column, about sixteen columns in the 74-frame wait; averaged with the slower ripple passes, it is about ten columns per cycle.

These are the numbers for Chapter 5 to beat: 4.3 frames for an idle pass, 45 frames for a sideways march step, 74 frames for an official cycle, 4.6 frames for one move of the base when the block is still, and 7.4 frames for one step of the shot when the block is still.

## When the block reaches the base

The bottom invaders sit on row `BY+6`. A down step is refused, and the march stops, when that row is already 20, so the next down would put them on the base's row 21. The program prints `THEY HAVE LANDED` on row 0, sets `L=1`, and leaves the block where it is. The player can still move and fire; the shot still passes through. A proper "game over" belongs in step 8.

In Fuse, a test that started the block already at the right edge with `BY=14` (bottom on row 20) printed the message, then left all 32 invaders in place. Holding P moved the base to column 31, a shot fired there passed through the right-hand edge of the block (the `BX=16` slice) and the invaders were put back, and holding O moved the base back again. The block did not take another step.

From the ordinary starting position, the first down happens after nine steps to the right. Thirteen successful downs bring the bottom to row 20; the next edge-hit lands. That is a few minutes at `W=8`, which is long enough that the landing is a real end, not a surprise that arrives too soon.

## The new BASIC used here

### GO SUB and RETURN

`GO SUB 80` jumps to line 80, and `RETURN` comes back to the statement after the `GO SUB`. The print, the erase, the start of a march step, and one row of a ripple are all subroutines, so the tight loop at the top stays short. `GO SUB` searches for the line from the start of the program, which is why the print routine is at line 80, close to the loop, and why the `REM`s stay at 9000.

### String slicing

`A$(R,F)(2 TO 17)` is characters 2 to 17 of that row-and-frame string, 16 characters. `A$(R,F)(1 TO 16)` is the first 16. These are only used at the two edges, as described above. A short test program printed a 17-character string, then the `(2 TO 17)` slice, without an error.

### A three-dimensional string array

`DIM A$(4,2,17)` is four rows, two frames, each a string of length 17. `A$(R,F)` is one of those strings. A timing of 20 inline `PRINT AT`s of `A$(1,1)` took 25 frames, 1.25 a print, against 1.15 for the same print from the two-dimensional `DIM A$(4,17)` of step 3, so the extra subscript is almost free.

### FOR with STEP -1

The right-edge scan is `FOR K=8 TO 1 STEP -1`. `NEXT K` counts down. When a living column is found, `LET K=1` makes that `NEXT` finish the loop.

## The listing

Line 10 jumps over the loop to the set-up at line 900. That clears the screen, dimensions the arrays, defines the eight UDGs from the `DATA` (A, B, and D to I), builds both frames of the four row strings, prints the block in frame 1, and jumps into the loop at line 20. The loop is the step 3 loop, plus a march timer and, when a step is in progress, one row of the ripple.

```
10 GO TO 900
20 LET K$=INKEY$
30 IF (K$="o" OR K$="O") AND X>0 THEN PRINT AT 21,X;" ": LET X=X-1: PRINT AT 21,X; INK 4;CHR$ 144
40 IF (K$="p" OR K$="P") AND X<31 THEN PRINT AT 21,X;" ": LET X=X+1: PRINT AT 21,X; INK 4;CHR$ 144
50 IF Y>=0 THEN PRINT AT Y,C;" ": LET Q=Y-BY: IF Q>=0 AND Q<=6 AND Q/2=INT (Q/2) THEN LET R=Q/2+1: LET I=3+2*(Q>=2)+2*(Q=6): LET P=Y: GO SUB 70
52 IF Y>=0 THEN LET Y=Y-1: IF Y>=0 THEN PRINT AT Y,C; INK 6;CHR$ 145
60 IF Y<0 AND K$=" " THEN LET C=X: LET Y=20: PRINT AT Y,C; INK 6;CHR$ 145
62 IF S>0 THEN GO SUB 220: GO TO 68
64 LET M=M+1: IF M>=W AND L=0 THEN GO SUB 100
68 GO TO 20
70 IF S=0 OR R<=S THEN GO SUB 80: RETURN
72 IF E=1 THEN LET P=P+1: LET F=3-F: GO SUB 80: LET F=3-F: RETURN
74 LET BX=BX+DX: LET F=3-F: GO SUB 80: LET F=3-F: LET BX=BX-DX
76 RETURN
80 IF BX=-1 THEN PRINT AT P,0; INK I;A$(R,F)(2 TO 17): RETURN
81 IF BX=16 THEN PRINT AT P,16; INK I;A$(R,F)(1 TO 16): RETURN
82 PRINT AT P,BX; INK I;A$(R,F)
83 RETURN
90 IF BX=-1 THEN PRINT AT P,0;"                ": RETURN
91 IF BX=16 THEN PRINT AT P,16;"                ": RETURN
92 PRINT AT P,BX;"                 "
93 RETURN
100 LET M=0
102 FOR K=1 TO 8
104 LET A=V(1,K)+V(2,K)+V(3,K)+V(4,K)
106 IF A>0 THEN LET LM=K: LET K=8
108 NEXT K
110 FOR K=8 TO 1 STEP -1
112 LET A=V(1,K)+V(2,K)+V(3,K)+V(4,K)
114 IF A>0 THEN LET RM=K: LET K=1
116 NEXT K
118 IF BX+2*LM-1+DX<0 OR BX+2*RM-1+DX>31 THEN GO TO 150
120 LET E=0: LET S=4
122 GO SUB 220
124 RETURN
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
900 BORDER 0: PAPER 0: INK 7: CLS
905 DIM V(4,8): DIM A$(4,2,17)
910 RESTORE 990
920 FOR N=0 TO 7: READ D: POKE USR "a"+N,D: NEXT N
930 FOR N=0 TO 7: READ D: POKE USR "b"+N,D: NEXT N
932 RESTORE 1000
934 FOR N=0 TO 47: READ D: POKE USR "d"+N,D: NEXT N
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
966 PRINT AT 21,X; INK 4;CHR$ 144
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
9130 REM L=1 once the block has landed, 0 until then
9140 REM S=block rows still to draw in this march step, or 0
9150 REM E=1 if this march step is a down step, 0 if sideways
9160 REM LM=leftmost living invader column 1-8
9170 REM RM=rightmost living invader column 1-8
9180 REM Q=shot row relative to BY, used to restore a row
9190 REM P=print row for a row-string or an erase
9200 REM I=ink for an invader row: 3, 5, 5 or 7
9210 REM R=block row 1-4
9220 REM K=invader column 1-8
9230 REM J=frame 1 or 2, used only while the strings are built
9240 REM U=UDG code 147 to 152
9250 REM S$=a row string built up, then copied into A$
9260 REM N=UDG byte being poked
9270 REM A=column total, used to find the living edges
9280 REM D=one byte of a UDG
```

The source is `step4-march.bas`. A tape image ready to load is `step4-march.tap`, with the program name `march`.

## Line by line

- **10** jumps over the loop to the set-up at line 900, as before.
- **20–40** read the key and move the base with O and P, exactly as before.
- **50** if a shot is in flight: prints a space over it, and if it was on an invader row, sets `R`, `I` and `P` and `GO SUB 70` to restore that row. Line 70 prints the row at the old place if the march is still, or if this row has not yet rippled (`S=0` or `R<=S`). If the row has already taken this step, lines 72–76 print it at the new place, in the new frame, then put `BX` and `F` back.
- **52–60** move the shot, or fire with Space, as in step 3.
- **62** if a march step is in progress (`S>0`), `GO SUB 220` draws the next row and `GO TO 68`, so the timer on line 64 is not counted during the ripple.
- **64** on an idle pass, `M` is increased, and if it has reached `W` and the block has not landed, `GO SUB 100` starts a new step.
- **68** goes back to the top of the loop.
- **80–83** print `A$(R,F)` at row `P`, using a 16-character slice at the two edges.
- **90–93** print 16 or 17 spaces at the same place, to erase a row on a down step.
- **100–116** start a step: `M` is cleared, then the living-edge scan sets `LM` and `RM`.
- **118–124** if the next sideways step would take a living invader past column 0 or 31, the routine goes to 150. Otherwise this is a sideways step (`E=0`), `S` is set to 4, and the first (bottom) row is drawn at once.
- **150–156** if the bottom of the block is already on row 20, the march stops and the message is printed. Otherwise this is a down step (`E=1`), `S` is set to 4, and the first new row is drawn.
- **220–232** draw one row of a sideways step: `R` is `S` (4, then 3, then 2, then 1), the string is printed at `BX+DX` in the other frame, then `BX` and `F` are put back. When `S` falls to 0, `BX` and `F` are committed.
- **240–248** draw one row of a down step at `BY+1`, then erase the old row at `BY`. When `S` falls to 0, `BY` is increased, `DX` reverses, and `F` flips.
- **900–934** set the colours, dimension `V` and `A$`, and define the eight UDGs. The 48 invader bytes are poked from `USR "d"` in one loop.
- **940–962** put the base and the block at their starting places, build both frames of each row string, and print the block in frame 1 at `BX=7`, `BY=1`.
- **964–970** set `F=1`, `DX=1` (march right first), `M=0`, `W=8`, `L=0`, `S=0` and `E=0`, draw the base, and jump into the loop.
- **990–997** hold the base and the shot, as in step 2.
- **1000–1055** hold D, E, F, G, H and I, eight bytes each, in that order, written with `BIN`.
- **9000–9280** name the variables. The new ones are **F** (the animation frame), **DX** (the direction), **M** and **W** (the march timer), **L** (landed or not), **S** (rows still to draw in this step), **E** (1 if this step is a down), **LM** and **RM** (the living edges), **P** (the print row), **J** (the frame while the strings are built), and **A** (a column total in the edge scan).

In Fuse, with the official `W=8`, the block waited, then rippled right one column, flipping to frame 2, then waited and rippled again. After nine steps it reached the right edge (last invader in column 31), stepped down one row, reversed, and marched left. The same happened at the left edge, with the first invader in column 0. A shot fired through the moving block, including during a ripple and at the right-hand edge after a landing, left all 32 invaders in place once it had passed. The base could be steered the whole time.

## Limitations you will notice

A march step still takes the better part of a second, even when it is spread over four passes, and those passes are slower than an idle pass (about 11 frames a row-pass, against 4.3). The base and the shot hitch a little as each row ripples. Machine code can move the whole formation on a steady frame beat and keep the player smooth in between.

Shots still pass through the invaders. Killing one is step 5, and will use `V`, the same `Q` arithmetic, and the living-edge scan already in this program.

`INKEY$` still reads one key at a time, and Caps Shift and Space is still Break, as in step 2. If you hold a direction and Space together, the fire can be missed.

The landing message sits on row 0. A shot that later flies through one of those columns can rub a letter out. A proper game over in step 8 can take the screen over.

## Running it

A screenshot of the block after three march steps, in the second animation frame, with the base moved right and a shot in flight, is in `step4-march.png`.

To build the tape and open it in Fuse, from the course folder, on Windows:

```
windows-tools\build.bat chapter-04-invaders-basic\step4-march.bas march 10
```

On Linux:

```
tools/build.sh chapter-04-invaders-basic/step4-march.bas march 10
```

`march` is the name stored on the tape, which `LOAD` shows as `Program: march`, and `10` is the line the program runs from after it loads. Fuse opens with the tape loading by itself. Hold O and P to move, and press Space to fire. The block will march, walk, and step down at each edge. The shot will still pass through. Break the program with Caps Shift and Space (in Fuse, Shift and Space).

You can also load the ready-made `step4-march.tap` in any 48K emulator and type `LOAD ""`. The helper script `tools/run-tap.sh chapter-04-invaders-basic/step4-march.bas` builds the tape and runs it in Fuse under Xvfb; see [tools/README.md](../tools/README.md). Set `TAP_NAME=march` if you want the name on the tape to match the ready-made file.

## Try this

Change `W` on line 964. `LET W=1` starts the next step as soon as the previous ripple has finished, so the block is almost always on the move. `LET W=16` gives a longer pause between steps, and is easier to steer in. In Fuse, `W=1` still rippled from the bottom up, and still reversed cleanly at both edges.

To see a landing without waiting for thirteen downs, change line 942 to `LET BX=16: LET BY=14` and, if you like, `LET W=1` on line 964. The bottom invaders start on row 20, already at the right edge, and the first edge-hit prints `THEY HAVE LANDED`. The base and the shot still work afterwards.
