# Chapter 2, step 4 — A user-defined graphic for the ball

This step takes the coloured-brick game from [step 3](step3-bricks.md) and replaces the letter `O` with a round ball that you design yourself. The play is the same: O and P move the bat, the ball bounces off the bat and the walls, a miss restarts at the top, and `ATTR` still detects a brick. The only change you should notice on the screen is the shape of the ball.

A user-defined graphic (UDG) is an 8×8 character whose pixel pattern you write into RAM. The Spectrum has 21 of them, named A to U. This program defines UDG A as a filled circle, eight bytes long, one byte per pixel row. Those bytes are the same kind of bitmap data that Lesson 1 and [the colour reference](../colour-reference.md) prepared you to read — eight bits, left to right, 1 for ink and 0 for paper — and the same kind you will later `POKE` into the display file itself.

`BEEP` sounds and a little random deflection are still to come. Score and lives can come after that.

Every program is tested in a 48K emulator before it is shown.

## The ball's bit pattern

Each row of the graphic is one byte. Bit 7 is the leftmost pixel, bit 0 the rightmost. The eight rows below are the ball used in the listing. `#` is ink (a 1), `.` is paper (a 0).

```
        bit  7 6 5 4 3 2 1 0      BIN         decimal
row 0        0 0 1 1 1 1 0 0      00111100      60
row 1        0 1 1 1 1 1 1 0      01111110     126
row 2        1 1 1 1 1 1 1 1      11111111     255
row 3        1 1 1 1 1 1 1 1      11111111     255
row 4        1 1 1 1 1 1 1 1      11111111     255
row 5        1 1 1 1 1 1 1 1      11111111     255
row 6        0 1 1 1 1 1 1 0      01111110     126
row 7        0 0 1 1 1 1 0 0      00111100      60

        ..####..
        .######.
        ########
        ########
        ########
        ########
        .######.
        ..####..
```

60 is `32+16+8+4`, or bits 5 to 2. 126 is 60 with the two outer bits also set (`64+2`). 255 is all eight bits on. You can change any row and the ball's outline will change with it.

## The new BASIC keywords used here

The keywords from steps 1 to 3 are used again and are not repeated below. These are the new ones.

### USR (the string form, for a UDG address)

`USR "a"` is a function. Given a single lowercase letter in quotes, from `"a"` to `"u"`, it returns the address of that UDG's first byte in RAM. UDG A is `"a"`, UDG B is `"b"`, and so on. The letter must be lowercase; `USR "A"` is not the same thing and will not do what you want here.

The eight bytes of the graphic then sit at `USR "a"` to `USR "a"+7`. Using `USR` means you do not have to remember the actual address (on a 48K machine the UDG area usually starts at 65368).

`USR` has another form, `USR address`, which calls a machine-code routine. That is not used here; it will appear when the course reaches machine code.

```
10 PRINT USR "a"
```

### POKE

`POKE address,value` writes a single byte, 0 to 255, into RAM at that address. Here it is used to plant one row of the ball: `POKE USR "a"+N,D` puts byte `D` into row `N` of UDG A.

`POKE` will write anywhere in RAM, so an address that is even slightly wrong can corrupt the program or the system variables. For this step, stay with `USR "a"+N` and `N` in 0 to 7.

```
10 POKE USR "a",60
```

### PEEK

`PEEK address` is the counterpart of `POKE`: it returns the byte stored at that address, 0 to 255. The program does not need it, because the pattern is in `DATA` rather than being read back from the UDG. It is useful if you want to check what you have just written:

```
10 PRINT PEEK (USR "a")
```

You will use `PEEK` and `POKE` together more heavily in the next part of the course, when the same kind of bytes are written into the display file.

### BIN

`BIN` writes a number in binary, as a row of 0s and 1s. Only those two digits are allowed. For a pixel row it is natural to give all eight bits, including leading zeros, so `BIN 00111100` is the same number as 60, but you can see the shape.

```
10 LET D=BIN 00111100
```

### DATA, READ and RESTORE

`DATA` lists values in the program — numbers or strings, separated by commas. The computer does not run a `DATA` line as a statement; it only holds the values for `READ`.

`READ variable` takes the next item from the `DATA` list and stores it. If you `READ` past the last item you get the error `E Out of DATA`.

`RESTORE` starts the list again from the first `DATA` in the program. `RESTORE line` starts from the first `DATA` on or after that line. This program uses `RESTORE 500` so it is obvious which `DATA` is being read, even if you later add more `DATA` elsewhere.

```
10 RESTORE 500
20 READ D
30 DATA 60,126
```

### CHR$

`CHR$ n` is a function that returns the character whose code is `n`. `CHR$ 65` is `"A"`. The UDGs occupy codes 144 to 164: `CHR$ 144` is UDG A, `CHR$ 145` is UDG B, and so on up to `CHR$ 164` for UDG U.

The program prints the ball with `PRINT AT R,X;CHR$ 144`. That is the form used in the listing because it is readable as plain text and is easy to type.

There are two other ways to get the same character, and they are worth knowing:

- On the Spectrum keyboard, Caps Shift and 9 enter Graphics mode. Then the A key types UDG A (character 144) directly. Caps Shift and 9 again leave Graphics mode. A listing on the machine would then show the graphic in the quotes, not `CHR$ 144`.
- In a `zmakebas` text file you can write `"\a"` inside a string, which becomes that same character 144. `"\b"` is UDG B, up to `"\u"`. This program uses `CHR$ 144` instead, so the source you type and the source you read are the same.

```
10 PRINT AT 5,5;CHR$ 144
```

## The listing

After `CLS`, the program reads the eight bytes from `DATA` and pokes them into UDG A. From then on, every `PRINT` of `CHR$ 144` draws the ball. The rest of the game is the step 3 program, with `"O"` replaced by `CHR$ 144`.

```
1 REM R=ball row 0-20
2 REM X=ball column 0-31
3 REM DR=row step +1 or -1
4 REM DX=column step +1 or -1
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
20 BORDER 0: PAPER 0: INK 7: CLS
30 LET R=5: LET X=5
40 LET DR=1: LET DX=1
50 LET W=4: LET B=14
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
310 IF X=B THEN LET DX=-1
320 IF X=B+W-1 THEN LET DX=1
330 LET DR=-DR
340 GO TO 210
360 LET R=5: LET X=5: LET DR=1: LET DX=1
370 GO TO 130
400 PRINT AT R+DR,X+DX; PAPER 0;" "
410 LET DR=-DR
420 GO TO 210
500 DATA BIN 00111100, BIN 01111110, BIN 11111111, BIN 11111111
510 DATA BIN 11111111, BIN 11111111, BIN 01111110, BIN 00111100
```

The source is `step4-udg-ball.bas`. A tape image ready to load is `step4-udg-ball.tap`.

## Line by line

- **1–14** name the variables. **1–12** are the same as in step 3. **N** is the row of the UDG being written, 0 at the top to 7 at the bottom. **D** is that row's byte, read from `DATA`.
- **20–50** set the colours, place the ball and the bat, as in step 3.
- **52** points `READ` at the `DATA` on line 500.
- **54–59** do this eight times: read one number into `D`, and `POKE` it into the next byte of UDG A. After this loop, `CHR$ 144` will draw the ball.
- **60–120** draw the coloured wall and the bat, as in step 3.
- **130** prints the ball, now as `CHR$ 144` rather than `"O"`.
- **140–420** are the game loop from step 3: the delay, rubbing the ball out with a space, reading O and P, bouncing off the edges, the bat and the bricks. A miss still restarts at row 5, column 5.
- **500–510** hold the eight bytes of the graphic, in the order they are poked, written with `BIN` so the shape is visible in the listing.

## Limitations you will notice

The ball is still one character cell, and it still moves a whole cell at a time, so the motion is no smoother than it was with the letter `O`. A later part of the course looks at moving things by pixels, which needs machine code.

There are only 21 UDGs. Redefining A changes every `CHR$ 144` on the screen and any you print afterwards. If you break the program, the ball graphic stays in RAM until you define it again or use `NEW`, which puts the default shapes back.

The hit test, the flicker, and the need to hold O or P are unchanged from step 3.

A screenshot taken just after a yellow brick was cleared, with the new ball bouncing off it, is in `step4-udg-ball.png`.

To run it yourself: start a 48K emulator, load `step4-udg-ball.tap`, and type `LOAD ""`. The program auto-starts at line 10 (the last of the remarks; the first statement is line 20) and runs until you break it (on a real machine, Caps Shift and Space; in Fuse, often F4 or the menu). The helper script `tools/run-tap.sh chapter-02-bat-and-ball/step4-udg-ball.bas` (from the course root) builds the tape and runs it in Fuse under Xvfb. To send keys while it captures, see [tools/README.md](../tools/README.md).

## Try this

Change a row of the `DATA` and run the program again. For a hollow ring, try `BIN 00111100` for rows 0 and 7, `BIN 01100110` for rows 1 and 6, and `BIN 11000011` for the four middle rows. Or punch a single highlight pixel out of row 1 by using `BIN 01011110` instead of `BIN 01111110`.

If you would rather type the graphic itself in a `PRINT` string, replace `CHR$ 144` on line 130 with `"\a"` in a `zmakebas` listing, or with the Graphics-mode A character on the machine. The byte that is printed is the same.
