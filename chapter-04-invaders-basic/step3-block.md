# Chapter 4, step 3 — A block of invaders

This is the third step of the Invaders-style game that Chapter 4 builds in pure Sinclair BASIC. [Step 1](step1-base.md) put the player's base on the bottom row. [Step 2](step2-shot.md) added a shot, fired with Space. This step puts a still block of invaders above the player, drawn as user-defined graphics from `DATA`. The base and the shot still work. The block does not march yet; that is step 4. Shots pass through the invaders until step 5, when a hit will kill one.

The block is four rows of eight (32 invaders), as decided in the [plan](PLAN.md). There are three types, as in the arcade game: the top row is one type, the middle two rows a second, and the bottom row a third. Only the first frame of each type is shown in this step. Their second frames, UDGs E, G and I, are reserved for the walk cycle in step 4.

Each row is kept as a 17-character string and printed with one `PRINT AT`, rather than 32 separate prints. A test of the two ways of drawing the same 32 UDGs is in the lesson below. The living/dead array `DIM V(4,8)` is filled in this step so that later steps have a record of who is still there; the strings are what actually go on the screen.

The program is laid out in the same way as steps 1 and 2. Line 10 jumps over the loop to the set-up at line 900. The loop sits at the top, and the `REM` lines for the variables stay at the end.

Every program is tested in a 48K emulator before it is shown.

## The invaders' bit patterns

The three types are UDGs D, F and H, codes 147, 149 and 151. As in steps 1 and 2, each row of a graphic is one byte. Bit 7 is the leftmost pixel and bit 0 the rightmost. `#` is ink (a 1) and `.` is paper (a 0).

**UDG D**, the top-row invader, is printed in magenta (`INK 3`):

```
        bit  7 6 5 4 3 2 1 0      BIN         decimal
row 0        0 0 1 1 1 1 0 0      00111100      60
row 1        0 1 1 1 1 1 1 0      01111110     126
row 2        1 1 1 1 1 1 1 1      11111111     255
row 3        1 1 0 1 1 0 1 1      11011011     219
row 4        1 1 1 1 1 1 1 1      11111111     255
row 5        0 1 0 1 1 0 1 0      01011010      90
row 6        1 0 1 0 0 1 0 1      10100101     165
row 7        0 1 0 0 0 0 1 0      01000010      66

        ..####..
        .######.
        ########
        ##.##.##
        ########
        .#.##.#.
        #.#..#.#
        .#....#.
```

**UDG F**, the middle-rows invader, is printed in cyan (`INK 5`):

```
        bit  7 6 5 4 3 2 1 0      BIN         decimal
row 0        0 1 0 0 0 0 1 0      01000010      66
row 1        0 0 1 0 0 1 0 0      00100100      36
row 2        0 1 1 1 1 1 1 0      01111110     126
row 3        1 1 0 1 1 0 1 1      11011011     219
row 4        1 1 1 1 1 1 1 1      11111111     255
row 5        1 0 1 1 1 1 0 1      10111101     189
row 6        1 0 1 0 0 1 0 1      10100101     165
row 7        0 0 1 0 0 1 0 0      00100100      36

        .#....#.
        ..#..#..
        .######.
        ##.##.##
        ########
        #.####.#
        #.#..#.#
        ..#..#..
```

**UDG H**, the bottom-row invader, is printed in white (`INK 7`):

```
        bit  7 6 5 4 3 2 1 0      BIN         decimal
row 0        0 0 1 1 1 1 0 0      00111100      60
row 1        1 1 1 1 1 1 1 1      11111111     255
row 2        1 1 1 1 1 1 1 1      11111111     255
row 3        1 1 1 0 0 1 1 1      11100111     231
row 4        1 1 1 1 1 1 1 1      11111111     255
row 5        0 1 0 1 1 0 1 0      01011010      90
row 6        1 0 1 0 0 1 0 1      10100101     165
row 7        1 0 0 0 0 0 0 1      10000001     129

        ..####..
        ########
        ########
        ###..###
        ########
        .#.##.#.
        #.#..#.#
        #......#
```

The three shapes are meant to be told apart at a glance: a small compact invader on the top row, a broader one with raised arms in the middle, and a heavier one with a wide body at the bottom. The colours are not the same as the green base or the yellow shot, so each thing on the screen has its own ink.

UDGs A and B, the base and the shot, are defined exactly as in step 2. UDG C is left for the invaders' bombs in step 6. UDGs E, G and I, the second frames, are left as the letters E, G and I until step 4.

## The shape of the block

Each invader takes two columns: the graphic and a gap. A row is therefore a 17-character string: a leading space, then eight pairs of an invader and a gap. The eight invaders themselves span 15 columns, from the first graphic to the last. The leading and trailing spaces are there so that, in step 4, the string can rub out the column the row has just left, whichever way the block is marching.

A blank row separates the four invader rows, so the block is 7 rows deep. Printed from column 7, the 17-character strings occupy columns 7 to 23, and the invaders sit in columns 8, 10, 12, 14, 16, 18, 20 and 22, which puts the middle of the formation over the base's starting column, 15. The top of the block is row 1, so row 0 stays clear for the score in a later step. That leaves 17 columns of room for the 15-column formation to march across a 32-column screen in step 4, and plenty of space between the bottom of the block (row 7) and the base (row 21).

```
row 1   .D.D.D.D.D.D.D.D.     UDG D, magenta
row 2
row 3   .F.F.F.F.F.F.F.F.     UDG F, cyan
row 4
row 5   .F.F.F.F.F.F.F.F.     UDG F, cyan
row 6
row 7   .H.H.H.H.H.H.H.H.     UDG H, white
```

The dots are the gaps and the two padding spaces. The letters stand for the three UDGs.

## The new BASIC used here

The keywords from steps 1 and 2 are used again and are not all repeated below. These are the new ones, each with a short example that was run in Fuse.

### DIM, for a numeric array

`DIM name(size)` reserves an array of numbers and sets every element to 0. The name must be a single letter. `DIM V(4,8)` is a two-dimensional array with 4 rows and 8 columns. Subscripts start at 1, so the elements are `V(1,1)` to `V(4,8)`. `V(0,1)` stops with `3 Subscript wrong`. `DIM` also deletes any earlier array of the same name. A simple variable called `V` can exist at the same time; the brackets mark the array.

```
10 DIM V(4,8)
20 LET V(1,1)=1: LET V(4,8)=1
30 PRINT V(1,1);V(1,2);V(4,8)
```

This printed `101`: that is 1, then 0, then 1, with no spaces between them. `V(1,2)` was still 0, because `DIM` had cleared the array and nothing had written to that slot.

The program uses `V(R,K)=1` to mark invader `K` of row `R` as alive. In this step every slot is set alive and then left alone. From step 5 a hit will set the slot to 0.

### DIM, for a string array

A string array has one extra number in the `DIM`, which is the length of each string. `DIM A$(4,17)` reserves four strings, `A$(1)` to `A$(4)`, each exactly 17 characters, filled with spaces. Assignment to a string in the array is always cut or padded on the right to that length (the Spectrum manual calls this Procrustean). A simple string `A$` cannot have the same name.

If you try to build a row by concatenating onto `A$(R)` itself, the new characters fall off the end: `A$(R)` is already 17 spaces long, and the result is trimmed back to 17. The program therefore builds each row in an ordinary string `S$`, whose length can grow, and only then copies it into `A$(R)`.

```
10 DIM A$(2,17)
20 LET S$=" "
30 FOR K=1 TO 8: LET S$=S$+CHR$ 65+" ": NEXT K
40 LET A$(1)=S$
50 PRINT "{";A$(1);"}"
60 PRINT "LEN A$(1)=";LEN A$(1);" LEN S$=";LEN S$
70 LET A$(2)="X"
80 PRINT "{";A$(2);"}"
```

This printed `{ A A A A A A A A }` with `LEN A$(1)=17` and `LEN S$=17`, which is a leading space, eight letters A with a gap after each, and a trailing space. It then printed `{X` followed by 16 spaces and `}`: assigning `"X"` to `A$(2)` padded it to 17 characters.

`A$(R)` in the program is one row of the block, ready to print.

### INT, and a comparison that is 1 or 0

`INT n` is the integer part of `n`, towards minus infinity: `INT 3.7` is 3. The test `Q/2=INT (Q/2)` is true when `Q` is even, and false when it is odd. On the Spectrum a true comparison has the value 1 and a false one has the value 0, so the same idea can be used in an expression.

The program uses both. The even test decides whether the shot is on an invader row (the four rows are 0, 2, 4 and 6 below the top of the block). The 1-or-0 values pick the UDG and the ink for each row: `147+2*(R>1)+2*(R=4)` is 147, 149, 149 or 151, and `3+2*(R>1)+2*(R=4)` is 3, 5, 5 or 7.

```
10 FOR Q=0 TO 7
20 PRINT Q;" even? ";Q/2=INT (Q/2)
30 NEXT Q
```

This printed `0 even? 1`, `1 even? 0`, `2 even? 1`, and so on up to `7 even? 0`.

```
10 FOR R=1 TO 4
20 PRINT R;" UDG ";147+2*(R>1)+2*(R=4);" INK ";3+2*(R>1)+2*(R=4)
30 NEXT R
```

This printed `1 UDG 147 INK 3`, `2 UDG 149 INK 5`, `3 UDG 149 INK 5` and `4 UDG 151 INK 7`, which are D in magenta, F in cyan, F in cyan, and H in white.

Those expressions are used because a second `IF` on the same line is skipped when the first is false, as step 2 showed. A chain such as `IF R=2 OR R=3 THEN LET U=149: IF R=4 THEN LET U=151` would never set `U` for row 4, because the first condition is false and the rest of the line is not run. The arithmetic does not have that problem.

### USR "d", USR "f" and USR "h"

These work exactly as `USR "a"` and `USR "b"` did. The letter must be lowercase. Each call returns the address of the first of that UDG's eight bytes, and `CHR$ 147`, `CHR$ 149` and `CHR$ 151` are the three characters. The set-up points `READ` at the invader `DATA` with `RESTORE 1000` and then pokes eight bytes into D, eight into F and eight into H, in that order.

## Why not 32 PRINT ATs?

The obvious first idea is to walk `V` with two `FOR` loops and print each living invader as its own `PRINT AT`. That works, and it is what a loop over an array looks like, but it is too slow to use once the block starts to march. Printing each of the four rows as one string is the replacement the [plan](PLAN.md#keeping-basic-fast-enough) picked, and these timings, measured in Fuse with the same 32 UDGs, are why.

| Drawing the block of 32 | Frames per redraw | Seconds |
|---|---:|---:|
| Four `PRINT AT`s, one 17-character string per row | 3.8 | 0.08 |
| 32 `PRINT AT`s, one per invader, from a 4-by-8 loop | 68 | 1.36 |

Ten string redraws took 38 frames, so one is 3.8. Ten cell redraws took 680 frames, so one is 68. A whole-block step with strings is under a tenth of a second, which the player will feel as a short hitch in step 4, but not a stall. Printing invader by invader would freeze the base for more than a second on every march step, which is not playable.

This step draws the block only once, at set-up, so the loop does not pay that cost on every pass. The strings are already in place for step 4, when the block will have to be reprinted as it moves.

## The listing

Line 10 jumps over the loop to the set-up at line 900. That clears the screen, dimensions the two arrays, defines the five UDGs from the `DATA`, builds the four row strings, prints the block and the base, and jumps into the loop at line 20. The loop is the step 2 loop, with one addition: when a live shot is rubbed out, if it was sitting on an invader row, that whole row string is printed again, so the invader the shot just covered is put back.

```
10 GO TO 900
20 LET K$=INKEY$
30 IF (K$="o" OR K$="O") AND X>0 THEN PRINT AT 21,X;" ": LET X=X-1: PRINT AT 21,X; INK 4;CHR$ 144
40 IF (K$="p" OR K$="P") AND X<31 THEN PRINT AT 21,X;" ": LET X=X+1: PRINT AT 21,X; INK 4;CHR$ 144
50 IF Y>=0 THEN PRINT AT Y,C;" ": LET Q=Y-BY: IF Q>=0 AND Q<=6 AND Q/2=INT (Q/2) THEN PRINT AT Y,BX; INK 3+2*(Q>=2)+2*(Q=6);A$(Q/2+1)
52 IF Y>=0 THEN LET Y=Y-1: IF Y>=0 THEN PRINT AT Y,C; INK 6;CHR$ 145
60 IF Y<0 AND K$=" " THEN LET C=X: LET Y=20: PRINT AT Y,C; INK 6;CHR$ 145
70 GO TO 20
900 BORDER 0: PAPER 0: INK 7: CLS
905 DIM V(4,8): DIM A$(4,17)
910 RESTORE 990
920 FOR N=0 TO 7: READ D: POKE USR "a"+N,D: NEXT N
930 FOR N=0 TO 7: READ D: POKE USR "b"+N,D: NEXT N
932 RESTORE 1000
934 FOR N=0 TO 7: READ D: POKE USR "d"+N,D: NEXT N
936 FOR N=0 TO 7: READ D: POKE USR "f"+N,D: NEXT N
938 FOR N=0 TO 7: READ D: POKE USR "h"+N,D: NEXT N
940 LET X=15: LET Y=-1
942 LET BX=7: LET BY=1
944 FOR R=1 TO 4
946 LET U=147+2*(R>1)+2*(R=4)
948 LET I=3+2*(R>1)+2*(R=4)
950 LET S$=" "
952 FOR K=1 TO 8: LET V(R,K)=1: LET S$=S$+CHR$ U+" ": NEXT K
954 LET A$(R)=S$
956 PRINT AT BY+2*(R-1),BX; INK I;A$(R)
958 NEXT R
960 PRINT AT 21,X; INK 4;CHR$ 144
970 GO TO 20
990 DATA BIN 00011000,BIN 00011000,BIN 00011000,BIN 01111110
995 DATA BIN 11111111,BIN 11111111,BIN 11111111,BIN 11111111
996 DATA BIN 00000000,BIN 00011000,BIN 00011000,BIN 00011000
997 DATA BIN 00011000,BIN 00011000,BIN 00011000,BIN 00000000
1000 DATA BIN 00111100,BIN 01111110,BIN 11111111,BIN 11011011
1005 DATA BIN 11111111,BIN 01011010,BIN 10100101,BIN 01000010
1010 DATA BIN 01000010,BIN 00100100,BIN 01111110,BIN 11011011
1015 DATA BIN 11111111,BIN 10111101,BIN 10100101,BIN 00100100
1020 DATA BIN 00111100,BIN 11111111,BIN 11111111,BIN 11100111
1025 DATA BIN 11111111,BIN 01011010,BIN 10100101,BIN 10000001
9000 REM Variables, kept at the end so GO TO 20 does not walk past them
9010 REM X=base column 0-31, on row 21
9020 REM K$=key read by INKEY$, or ""
9030 REM Y=shot row, or -1 if no shot is in flight
9040 REM C=shot column, set when the shot is fired
9050 REM BX=left column of the 17-character row strings
9060 REM BY=top row of the block
9070 REM V(4,8)=1 if that invader is alive, 0 if not
9080 REM A$(4,17)=the four row strings, each 17 characters
9090 REM Q=shot row relative to BY, used to restore a row
9100 REM I=ink for an invader row: 3, 5, 5 or 7
9110 REM R=block row 1-4 being built
9120 REM K=invader column 1-8 being built
9130 REM U=UDG code 147, 149 or 151
9140 REM S$=a row string built up, then copied into A$
9150 REM N=UDG byte 0-7 being poked
9160 REM D=one byte of a UDG
```

The source is `step3-block.bas`. A tape image ready to load is `step3-block.tap`, with the program name `block`.

## Line by line

- **10** jumps over the loop to the set-up at line 900, as in steps 1 and 2.
- **20–40** read the key and move the base with O and P, exactly as before.
- **50** if a shot is in flight: prints a space over it, then sets `Q` to the shot's row relative to the top of the block. If `Q` is 0, 2, 4 or 6, that row is an invader row, and the whole 17-character string is printed again, in the right ink, which puts back any invader the shot was sitting on. If the shot was on a gap or a blank separator row, the space is enough.
- **52** then moves the shot up one row and reprints it, or leaves `Y` at `-1` if it has gone off the top, as in step 2. This is a line of its own so that the move always happens when `Y>=0`, even if the restore `IF` on line 50 was false.
- **60–70** fire with Space if no shot is in flight, and go back to the top of the loop.
- **900** sets a black border and paper and white ink, and clears the screen.
- **905** reserves `V` and `A$`. This has to happen before the arrays are used, and `RUN` (or loading the tape) clears the variables so `DIM` is safe.
- **910–930** define the base and the shot from the `DATA` at line 990, as in step 2.
- **932–938** point `READ` at the invader `DATA` at line 1000 and define UDGs D, F and H, eight bytes each, in that order.
- **940** puts the base in column 15 and sets `Y` to `-1`.
- **942** puts the top-left of the 17-character strings at column 7, row 1.
- **944–958** build the four rows. For each row `R`, `U` and `I` are the UDG code and the ink. `S$` starts as a single space; the inner loop marks each of the eight invaders alive in `V` and appends the graphic and a gap to `S$`. `A$(R)` is then that 17-character string, and one `PRINT AT` draws the whole row at `BY+2*(R-1)`, which is rows 1, 3, 5 and 7.
- **960–970** draw the base and jump into the loop.
- **990–997** hold the eight rows of the base and of the shot, as in step 2.
- **1000–1025** hold the eight rows of D, then F, then H, written with `BIN` so the shapes can be seen in the listing.
- **9000–9160** name the variables. **X**, **K$**, **Y** and **C** are the base and the shot, as in step 2. **BX** and **BY** are the left column and the top row of the block. **V** and **A$** are the two arrays. **Q** is the shot's row relative to `BY`, used on line 50. **I**, **R**, **K**, **U** and **S$** are used while the block is built at set-up. **N** and **D** are the UDG poke, as before.

The block is drawn only once, so it does not flicker. The shot is the only thing that reprints a row, and only when it is leaving an invader row, so a shot can pass through the formation without leaving holes. In Fuse, a shot fired up an invader's column briefly covered that invader, and the invader was back once the shot had moved on. All 32 were still there after the shot had left the top. The same was true of a shot fired up a gap.

## How fast is it?

The block is drawn only at set-up, so an idle pass of the loop is the step 2 loop plus the longer test on line 50, and plus the new variables, including the two arrays. A copy of the program that counts 100 idle passes (no key, no shot, with a counter `P` added at line 65 and started at 0 next to `LET Y=-1`) printed `100 PASSES: 263 FRAMES` and `ONE PASS: 2.63 FRAMES`. One idle pass therefore takes about 2.6 frames. The counter itself adds a little to each pass.

The same loop, with a shot placed at row 20 and the clock stopped when it was erased at the top, printed `21 STEPS: 116 FRAMES` and `ONE STEP: 5.5238095 FRAMES`. A step of the shot now takes about 5.5 frames, so the flight lasts 2.3 seconds. In step 2 it was 2.9 frames and 1.2 seconds. Four of the 21 steps also reprint a 17-character row, and every step has to work out `Q` and the even test. The time was the same for a shot up an invader's column and for a shot up a gap, because a gap that sits on an invader row still reprints that row.

With no shot in flight and the base pretending P is always held, the base crossed the screen in 104 frames, 3.4 frames a step (31 steps). In step 2 that was 2.9 frames. The extra tests and the extra variables have slowed the base a little even when the shot is not flying.

These are the numbers for Chapter 5 to beat: 2.6 frames for an idle pass, 3.4 frames for one move of the base, and 5.5 frames for one step of the shot through the still block.

## Limitations you will notice

The block does not move. Marching, and the two-frame walk, belong in step 4.

Shots pass through the invaders. A shot that lands on an invader briefly covers it, and the invader is put back when the shot moves on. Killing an invader is step 5, and will use the same `Q` arithmetic and the array `V`.

The shot is slower than it was in step 2, because the loop has more to do. Once the block starts to march, both the base and the shot will hitch on a march step. Machine code can draw the same UDGs, or later pixel sprites, in a fraction of a frame, and can update the shot every frame without slowing the player.

`INKEY$` still reads one key at a time, and Caps Shift and Space is still Break, as in step 2.

Only the first frame of each invader is shown. The second frames are already reserved in the UDG table, and will appear in step 4.

## Running it

A screenshot of the block, with a shot in flight between the base and the invaders, is in `step3-block.png`.

To build the tape and open it in Fuse, from the course folder, on Windows:

```
windows-tools\build.bat chapter-04-invaders-basic\step3-block.bas block 10
```

On Linux:

```
tools/build.sh chapter-04-invaders-basic/step3-block.bas block 10
```

`block` is the name stored on the tape, which `LOAD` shows as `Program: block`, and `10` is the line the program runs from after it loads. Fuse opens with the tape loading by itself. Hold O and P to move, and press Space to fire. The shot will pass through the block. Break the program with Caps Shift and Space (in Fuse, Shift and Space).

You can also load the ready-made `step3-block.tap` in any 48K emulator and type `LOAD ""`. The helper script `tools/run-tap.sh chapter-04-invaders-basic/step3-block.bas` builds the tape and runs it in Fuse under Xvfb; see [tools/README.md](../tools/README.md). Set `TAP_NAME=block` if you want the name on the tape to match the ready-made file.

## Try this

Shrink the block to three rows of six (18 invaders), as a smaller formation that will be cheaper to march in step 4. In this step the block is drawn only once, so shrinking it does not speed the loop; the change is so you can see a smaller block, and so the same edits are ready for later.

Change the arrays to `DIM V(3,6): DIM A$(3,13)`, because a row of six is a leading space plus six pairs, 13 characters. Change `FOR R=1 TO 4` to `FOR R=1 TO 3`, and `FOR K=1 TO 8` to `FOR K=1 TO 6`. In the two expressions that pick the UDG and the ink, and in the restore on line 50, use `R=3` or `Q=4` in place of `R=4` or `Q=6`, so the bottom row of a three-row block still comes out as UDG H in white.

In Fuse this printed 18 invaders, six of each type, on rows 1, 3 and 5, and a shot still flew through them without leaving a hole.

Redesign one of the types. Change the bytes for D, F or H in the `DATA` at lines 1000 to 1025 and run the program again. Keep each type on its own UDG so the three rows stay distinct.
