# Chapter 4, step 1 — The player's base

This is the first step of the Invaders-style game that Chapter 4 builds in pure Sinclair BASIC. The [chapter index](README.md) lists the steps, and the [plan](PLAN.md) gives the shape of the whole chapter. By the end there will be a block of 32 marching, animated invaders, bombs, shields, a score and lives. Chapter 5 then rebuilds the same game in machine code, step by step, so the two can be compared.

This step has one job: put the player's base, a laser cannon drawn as a user-defined graphic, on the bottom row of the screen, and move it left and right with **O** and **P**, stopping at the edges. Lowercase and capitals both work. Hold the key down to keep moving, as with the bat in Chapter 2.

Almost all the keywords are ones Chapter 2 used. What is new is the way the program is laid out. Chapter 3 measured how `GO TO` and `NEXT` search for their line from the top of the program, and how every `REM` above a loop slows it down. So this program puts its main loop at the very top, jumps over it once to a set-up routine at line 900, and keeps all its `REM` lines at the end, where the loop never has to walk past them. Every step of this chapter will be built the same way.

Every program is tested in a 48K emulator before it is shown.

## The base's bit pattern

The base is UDG A, the first of the 21 user-defined graphics, `CHR$ 144`. The [plan](PLAN.md#the-udgs) fixes a letter for every graphic the game will need, so later steps can add theirs without moving this one.

Each row of the graphic is one byte. Bit 7 is the leftmost pixel and bit 0 the rightmost. `#` is ink (a 1) and `.` is paper (a 0).

```
        bit  7 6 5 4 3 2 1 0      BIN         decimal
row 0        0 0 0 1 1 0 0 0      00011000      24
row 1        0 0 0 1 1 0 0 0      00011000      24
row 2        0 0 0 1 1 0 0 0      00011000      24
row 3        0 1 1 1 1 1 1 0      01111110     126
row 4        1 1 1 1 1 1 1 1      11111111     255
row 5        1 1 1 1 1 1 1 1      11111111     255
row 6        1 1 1 1 1 1 1 1      11111111     255
row 7        1 1 1 1 1 1 1 1      11111111     255

        ...##...
        ...##...
        ...##...
        .######.
        ########
        ########
        ########
        ########
```

The barrel is the middle two pixels, bits 4 and 3, three rows tall. It sits exactly in the centre of the cell, so in step 2 a shot fired straight up from the base's column will look as if it leaves the barrel. Row 3 gives the body rounded shoulders, and the bottom four rows are a solid hull. 24 is `16+8`, bits 4 and 3. 126 is bits 6 to 1. 255 is all eight bits on.

The arcade cannon is wider than one character, but a one-cell base keeps the edge tests and the rub-out simple. A wider base is in "Try this" below.

## The BASIC keywords used here

All of these appeared in [Chapter 2](../chapter-02-bat-and-ball/README.md), so each one is a short recap with a one-line example. Each example was run on its own in Fuse, and what it shows is given underneath.

### REM

`REM` makes the rest of the line a remark, which the computer skips. This chapter keeps the `REM` lines for its variables at the end of the program, at line 9000 and above. A `REM` line still has to be stepped over when a `GO TO` or `NEXT` searches for its line, so a `REM` above the loop costs time on every pass. At the end, it costs nothing.

```
9010 REM X=base column 0-31, on row 21
```

Run on its own, this does nothing and stops with `0 OK, 9010:1`.

### BORDER, PAPER, INK and CLS

`BORDER colour` sets the border. `PAPER colour` and `INK colour`, as statements, set the permanent paper and ink. `colour` is 0 to 7 (black, blue, red, magenta, green, cyan, yellow, white), or 8 (transparent) or 9 (contrast) for `INK` and `PAPER`. `CLS` clears the screen to the current paper and moves the print position to the top left.

```
10 BORDER 0: PAPER 0: INK 7: CLS
```

This turns the border and the screen black.

### LET

`LET variable=expression` stores a number in a variable, or a string if the name ends in `$`. On the 48K Spectrum the `LET` cannot be left out.

```
10 LET X=15: PRINT X
```

This prints `15`.

### GO TO

`GO TO line` jumps to that line. If there is no line with that number, it goes to the next line after it. To find the line, BASIC starts at the top of the program and steps through every line until it gets there, so a jump to a low line number is quick and a jump to a high one is slow. Chapter 3 measured this: the same fill took 74 seconds with its loop at line 40 and 101 seconds with it at line 1000.

This program uses that in two ways. The loop's own `GO TO 20` is a jump to the second line of the program, so the search is a single step. And line 10 is a jump forward, over the loop, to the set-up at line 900, which runs only once and then jumps back.

```
10 GO TO 100
20 PRINT "back at line 20"
30 STOP
100 PRINT "setting up at line 100"
110 GO TO 20
```

This prints `setting up at line 100` and then `back at line 20`, and stops with `9 STOP statement, 30:1`.

### INKEY$

`INKEY$` returns the key being held down at that moment, as a one-character string, or `""` if no key is down. It does not wait. Letter keys come back in lowercase, unless Caps Lock is on or Caps Shift is held, in which case they come back as capitals. That is why the program tests for both `"o"` and `"O"`.

`INKEY$` sees one key at a time. If two letter keys are held together, it returns `""`. That will matter in step 2, when Space fires.

```
10 LET K$=INKEY$
20 PRINT AT 0,0;"key: ";K$;" "
30 GO TO 10
```

This shows `key: ` followed by the key held. With P held down, it showed `key: p`. The space at the end of line 20 rubs out the old letter when the key is let go.

### IF, THEN, AND and OR

`IF condition THEN statements` runs the rest of the line only if the condition is true. There is no `ELSE`. `AND` needs both sides true, and `OR` either side. Brackets make the key test come first: "the key is p or P, and the base is not at the edge".

```
10 LET K$="P": LET X=30
20 IF (K$="p" OR K$="P") AND X<31 THEN LET X=X+1
30 PRINT X
40 IF (K$="p" OR K$="P") AND X<31 THEN LET X=X+1
50 PRINT X
```

This prints `31` twice. The first test moves `X` from 30 to 31. The second finds `X` already at 31, so it leaves it alone, which is exactly how the base stops at the right edge.

### PRINT AT, with INK

`PRINT AT line,column;item` prints at that place. `line` is 0 to 21 and `column` 0 to 31. Lines 22 and 23 belong to `INPUT` and the error messages. An `INK` item in the list changes the ink for that `PRINT` only, and leaves the permanent `INK` alone.

```
10 PRINT AT 21,15; INK 4;"A"
```

This prints a green `A` on the bottom line of the main screen, column 15, which is where the base starts.

### USR "a"

`USR "a"` returns the address of the first of UDG A's eight bytes. The letter must be lowercase. On a 48K Spectrum the answer is normally 65368. Using `USR "a"` means you do not need to remember that number.

```
10 PRINT USR "a"
```

This prints `65368`.

### POKE and BIN

`POKE address,value` writes one byte, 0 to 255, into memory. `BIN` writes a number in binary, so a pixel row can be typed as the shape it draws. `BIN 11111111` is 255.

```
10 POKE USR "a",BIN 11111111
20 PRINT CHR$ 144
```

UDG A starts out as a copy of the letter A. This example replaces only its top row, so it prints an A with a solid bar across the top.

### CHR$

`CHR$ n` gives the character with code `n`. The UDGs are codes 144 to 164, so `CHR$ 144` is UDG A.

```
10 PRINT CHR$ 65;CHR$ 144
```

With nothing poked into UDG A, this prints `AA`: the ordinary letter A, code 65, and UDG A, which looks the same until it is redefined.

### DATA, READ, RESTORE, FOR and NEXT

`DATA` holds a list of values in the program. `READ variable` takes the next one. `RESTORE line` starts the list again from the first `DATA` at or after that line. `FOR N=0 TO 7: ... : NEXT N` repeats the statements in between, once for each value of `N`.

Together they define a UDG: read eight bytes and poke them into the eight rows.

```
10 RESTORE 100
20 FOR N=0 TO 7: READ D: POKE USR "a"+N,D: NEXT N
30 PRINT CHR$ 144
100 DATA BIN 00011000,BIN 00011000,BIN 00011000,BIN 01111110
110 DATA 255,255,255,255
```

This prints the base at the left of the screen. The second `DATA` line gives the same bytes in decimal, to show that `BIN 11111111` and 255 are the same number.

## The listing

Line 10 jumps over the loop to the set-up at line 900. That clears the screen, defines UDG A from the `DATA` at line 990, puts the base in the middle of row 21 and jumps into the loop at line 20. The loop reads the keyboard and, if O or P is held and the base is not at that edge, rubs the base out with a space, moves it one column and prints it again.

```
10 GO TO 900
20 LET K$=INKEY$
30 IF (K$="o" OR K$="O") AND X>0 THEN PRINT AT 21,X;" ": LET X=X-1: PRINT AT 21,X; INK 4;CHR$ 144
40 IF (K$="p" OR K$="P") AND X<31 THEN PRINT AT 21,X;" ": LET X=X+1: PRINT AT 21,X; INK 4;CHR$ 144
50 GO TO 20
900 BORDER 0: PAPER 0: INK 7: CLS
910 RESTORE 990
920 FOR N=0 TO 7: READ D: POKE USR "a"+N,D: NEXT N
930 LET X=15
940 PRINT AT 21,X; INK 4;CHR$ 144
950 GO TO 20
990 DATA BIN 00011000,BIN 00011000,BIN 00011000,BIN 01111110
995 DATA BIN 11111111,BIN 11111111,BIN 11111111,BIN 11111111
9000 REM Variables, kept at the end so GO TO 20 does not walk past them
9010 REM X=base column 0-31, on row 21
9020 REM K$=key read by INKEY$, or ""
9030 REM N=UDG byte 0-7 being poked
9040 REM D=one byte of the base UDG
```

The source is `step1-base.bas`. A tape image ready to load is `step1-base.tap`, with the program name `base`.

## Line by line

- **10** jumps over the loop to the set-up at line 900. It runs only once. Because it is the only line above the loop, the loop's `GO TO 20` finds its line after a single step.
- **20** reads the key being held, or `""` if none, into `K$`.
- **30** if the key is O or o and the base is not already at column 0: prints a space over the base to rub it out, moves `X` one column left, and prints the base, in green, in its new place. If the base is at column 0, nothing happens, so it stops at the left edge.
- **40** does the same for P or p, moving right, and stops at column 31, the last column.
- **50** goes back to read the keyboard again.
- **900** sets a black border and paper and white ink, and clears the screen.
- **910** points `READ` at the base's `DATA` on line 990.
- **920** reads the eight bytes and pokes them into rows 0 to 7 of UDG A. From now on `CHR$ 144` draws the base.
- **930** puts the base in column 15, near the middle of the 32 columns.
- **940** draws the base there, on row 21, in green ink (`INK 4`). The `INK` lasts for this `PRINT` only.
- **950** jumps into the loop.
- **990–995** hold the eight rows of the base, written with `BIN` so the shape can be seen in the listing.
- **9000–9040** name the variables. **X** is the base's column, 0 to 31; the base is always on row 21. **K$** is the key just read, or empty. **N** counts the UDG's rows 0 to 7, and **D** is the byte read for one row. They are at the end of the program so the loop never searches past them, which is the Chapter 3 finding put to use.

The base is drawn only when it moves, so it does not flicker while it stands still. The rub-out and reprint happen one straight after the other, so the base looks solid as it moves.

## How fast is it?

As in Chapters 2 and 3, `FRAMES` is the stopwatch. It counts 50 times a second, and its low two bytes are at 23672 and 23673. To time the base, this copy of the program pretends P is always held (`LET K$="p"` instead of `INKEY$`), starts the base at column 0, and stops when it reaches column 31.

```
10 GO TO 900
20 LET K$="p"
30 IF (K$="o" OR K$="O") AND X>0 THEN PRINT AT 21,X;" ": LET X=X-1: PRINT AT 21,X; INK 4;CHR$ 144
40 IF (K$="p" OR K$="P") AND X<31 THEN PRINT AT 21,X;" ": LET X=X+1: PRINT AT 21,X; INK 4;CHR$ 144
45 IF X=31 THEN GO TO 960
50 GO TO 20
900 BORDER 0: PAPER 0: INK 7: CLS
910 RESTORE 990
920 FOR N=0 TO 7: READ D: POKE USR "a"+N,D: NEXT N
930 LET X=0
940 PRINT AT 21,X; INK 4;CHR$ 144
945 LET T=PEEK 23672+256*PEEK 23673
950 GO TO 20
960 LET T=PEEK 23672+256*PEEK 23673-T
970 PRINT AT 0,0;"31 STEPS: ";T;" FRAMES"''"ONE STEP: ";T/31;" FRAMES"
980 STOP
990 DATA BIN 00011000,BIN 00011000,BIN 00011000,BIN 01111110
995 DATA BIN 11111111,BIN 11111111,BIN 11111111,BIN 11111111
```

In Fuse it printed `31 STEPS: 74 FRAMES` and `ONE STEP: 2.3870968 FRAMES`. Each step of the base, one pass of the loop with a move in it, takes about 2.4 frames, a little under a twentieth of a second. The base crosses the whole screen in about a second and a half.

That is brisk, and on its own the base may feel slightly too quick to stop exactly where you want. The plan allowed for a delay here, but this step leaves it out. Every later step adds work to the same loop: the shot, the march, the bombs. The base will slow down by itself, and a delay added now would only have to be taken out again. If you want it slower for now, see "Try this".

This is the first number for Chapter 5 to beat: 2.4 frames for one move of the base.

## Limitations you will notice

The base moves a whole character, eight pixels, at a time, so it jumps rather than glides. Moving a pixel at a time needs machine code, which comes in Chapter 5.

Its speed is just however long the loop takes. Here that is about 2.4 frames a step, but it will change with every step that adds work to the loop, and it is not tied to the 50 Hz frame. In Chapter 5 the machine-code loop waits for each frame with `HALT`, so the speed stays the same however much else is going on.

`INKEY$` reads one key at a time. That is fine for O and P, but in step 2 it means that holding a direction key and pressing Space at the same time will not fire. Chapter 5 reads the keyboard directly and can see several keys at once.

A very short tap of O or P may be missed, or may move the base two or three columns, because the keyboard is only read once per pass and a tap lasts several passes. Hold the key to steer.

If you break the program, the base stays in UDG A until it is redefined or the machine is reset, so typing `PRINT CHR$ 144` will still show it.

## Running it

A screenshot of the base in mid-screen, after moving with O and P, is in `step1-base.png`.

To build the tape and open it in Fuse, from the course folder, on Windows:

```
windows-tools\build.bat chapter-04-invaders-basic\step1-base.bas base 10
```

On Linux:

```
tools/build.sh chapter-04-invaders-basic/step1-base.bas base 10
```

`base` is the name stored on the tape, which `LOAD` shows as `Program: base`, and `10` is the line the program runs from after it loads. Fuse opens with the tape loading by itself. Hold O to move left and P to move right. Break the program with Caps Shift and Space (in Fuse, Shift and Space).

You can also load the ready-made `step1-base.tap` in any 48K emulator and type `LOAD ""`. The helper script `tools/run-tap.sh chapter-04-invaders-basic/step1-base.bas` builds the tape and runs it in Fuse under Xvfb, and `KEY_HOLD=p` holds P while it captures; see [tools/README.md](../tools/README.md).

## Try this

Slow the base down by adding a short delay to the loop:

```
45 FOR I=1 TO 5: NEXT I
```

In Fuse, this took each step from 2.4 frames to 3.8, so the base crosses the screen in about two and a half seconds instead of one and a half. Try other numbers in place of 5. A `FOR` loop is used instead of `PAUSE`, as in Chapter 2, because a held key cuts a `PAUSE` short.

Redesign the base. Change the bytes in lines 990 and 995 and run the program again. For a flatter cannon with a short barrel, try `BIN 00000000, BIN 00011000, BIN 00011000, BIN 01111110` for the first line. Keep the barrel in bits 4 and 3 so the shot in step 2 still lines up.

