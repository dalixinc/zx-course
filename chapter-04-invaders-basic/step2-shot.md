# Chapter 4, step 2 — One shot

This is the second step of the Invaders-style game that Chapter 4 builds in pure Sinclair BASIC. [Step 1](step1-base.md) put the player's base on the bottom row and moved it with **O** and **P**. This step adds a shot. Press **Space** and a slim bolt, drawn as UDG B, leaves the barrel and travels straight up the screen. Only one shot can be in flight at a time. If a shot is already on the screen, a further press of Space does nothing until that shot has gone off the top. The base can still move while the shot is flying. Lowercase and capitals still both work for O and P.

The fire key is Space, as decided in the [plan](PLAN.md). `INKEY$` returns a single space, `" "`, while Space is held. Because `INKEY$` reads only one key at a time, holding O or P and pressing Space together will usually give `""`, and nothing happens: you have to let go of the direction key to fire. That limit is shown honestly here. Chapter 5 will read the keyboard ports with `IN`, which can see several keys at once.

The program is laid out in the same way as step 1. Line 10 jumps over the loop to the set-up at line 900. The loop sits at the top, and the `REM` lines for the variables stay at the end, where `GO TO 20` never has to walk past them.

Every program is tested in a 48K emulator before it is shown.

## The shot's bit pattern

The shot is UDG B, the second of the 21 user-defined graphics, `CHR$ 145`. The [plan](PLAN.md#the-udgs) already reserved this letter, so later steps can add theirs without moving this one. UDG A is still the base, and is defined exactly as in step 1.

Each row of the graphic is one byte. Bit 7 is the leftmost pixel and bit 0 the rightmost. `#` is ink (a 1) and `.` is paper (a 0).

```
        bit  7 6 5 4 3 2 1 0      BIN         decimal
row 0        0 0 0 0 0 0 0 0      00000000       0
row 1        0 0 0 1 1 0 0 0      00011000      24
row 2        0 0 0 1 1 0 0 0      00011000      24
row 3        0 0 0 1 1 0 0 0      00011000      24
row 4        0 0 0 1 1 0 0 0      00011000      24
row 5        0 0 0 1 1 0 0 0      00011000      24
row 6        0 0 0 1 1 0 0 0      00011000      24
row 7        0 0 0 0 0 0 0 0      00000000       0

        ........
        ...##...
        ...##...
        ...##...
        ...##...
        ...##...
        ...##...
        ........
```

The ink is in bits 4 and 3, the same two pixels as the base's barrel, so a shot fired in the base's column looks as if it leaves the barrel. A blank row at the top and at the bottom makes it a short bolt rather than a bar that fills the whole cell. 24 is `16+8`, bits 4 and 3, the same number used for the barrel in step 1.

The shot is printed in yellow (`INK 6`), so it reads clearly against the green base and the black paper.

## The new BASIC used here

The keywords from step 1 (`REM`, `BORDER`, `PAPER`, `INK`, `CLS`, `LET`, `GO TO`, `INKEY$`, `IF` / `THEN` / `AND` / `OR`, `PRINT AT`, `USR`, `POKE`, `BIN`, `CHR$`, `DATA` / `READ` / `RESTORE`, `FOR` / `NEXT`) are used again and are not repeated below. These are the new ideas, each with a one-line example. Each example was run on its own in Fuse, and what it shows is given underneath.

### USR "b" and CHR$ 145

`USR "b"` returns the address of the first of UDG B's eight bytes. The letter must be lowercase. On a 48K Spectrum the answer is normally 65376, which is eight bytes after `USR "a"` (65368). `CHR$ 145` is UDG B, the character with code 145. The UDGs run from 144 to 164, so B is the second of them.

```
10 RESTORE 100
20 FOR N=0 TO 7: READ D: POKE USR "b"+N,D: NEXT N
30 PRINT USR "a";TAB 8;USR "b"
40 PRINT CHR$ 144;CHR$ 145
100 DATA BIN 00000000,BIN 00011000,BIN 00011000,BIN 00011000
110 DATA BIN 00011000,BIN 00011000,BIN 00011000,BIN 00000000
```

This printed `65368`, then `65376` further along the same line, and on the next line the letter A and the bolt. UDG A has not been redefined, so `CHR$ 144` still looks like a letter A. UDG B is the shot.

### Space, and INKEY$

`INKEY$` still returns the key being held, or `""` if none is down. While Space is held, that key is a single space, `" "`. The test in the program is therefore `K$=" "`. There is no special keyword for Space.

Caps Shift and Space together is **Break** on the Spectrum, not a capital space. If you hold Caps Shift and press Space, the program stops with `D BREAK - CONT repeats`, rather than firing. To fire, press Space on its own.

```
10 LET K$=INKEY$
20 IF K$=" " THEN PRINT AT 0,0;"space     "
30 IF K$="" THEN PRINT AT 0,0;"no key    "
40 IF K$<>" " AND K$<>"" THEN PRINT AT 0,0;"key: ";K$;"  "
50 GO TO 10
```

With no key held, this showed `no key`. With Space held, it showed `space`. With P held, it showed `key: p`. The spaces at the ends of the strings rub out the longer messages when a shorter one is printed.

### A sentinel for "no shot"

The shot needs a row and a column of its own. The column is `C`, set to the base's column when the shot is fired, and then left alone, so the bolt flies straight up and does not follow the base. The row is `Y`. While the shot is in flight, `Y` is 0 to 20. When no shot is in flight, `Y` is set to `-1`, a value that is not a real screen row. That sentinel is what the fire test looks at: a new shot is only created when `Y<0`.

A separate flag such as `F=0` or `F=1` would also work. A sentinel row keeps the program one variable shorter, and Chapter 3 found that fewer variables make BASIC a little quicker.

```
10 LET Y=-1
20 IF Y<0 THEN PRINT "no shot"
30 LET Y=20
40 IF Y>=0 THEN PRINT "shot at row ";Y
```

This printed `no shot` and then `shot at row 20`.

### Two IFs on one line

The 48K Spectrum has no `ELSE`. A second `IF` on the same line is tested only if the first one was true; if the first is false, the rest of the line is skipped. The shot uses this to rub itself out, step `Y` up the screen, and then either reprint itself or, if `Y` has gone below 0, leave the shot erased.

```
10 LET Y=0
20 IF Y>=0 THEN PRINT "erasing row ";Y: LET Y=Y-1: IF Y>=0 THEN PRINT "still at ";Y
30 PRINT "Y is now ";Y
```

This printed `erasing row 0` and `Y is now -1`. The second `IF` was false, so `still at` was not printed. That is exactly how a shot at row 0 is cleaned off the top of the screen. With `Y` starting at 5 instead of 0, the same program printed `erasing row 5`, `still at 4` and `Y is now 4`.

## The listing

Line 10 jumps over the loop to the set-up at line 900. That clears the screen, defines UDG A and UDG B from the `DATA`, puts the base in the middle of row 21, sets `Y` to `-1` so there is no shot yet, and jumps into the loop at line 20. The loop reads the keyboard, moves the base if O or P is held, moves a live shot up one row, and, if there is no shot and Space is held, fires one from the base's column.

```
10 GO TO 900
20 LET K$=INKEY$
30 IF (K$="o" OR K$="O") AND X>0 THEN PRINT AT 21,X;" ": LET X=X-1: PRINT AT 21,X; INK 4;CHR$ 144
40 IF (K$="p" OR K$="P") AND X<31 THEN PRINT AT 21,X;" ": LET X=X+1: PRINT AT 21,X; INK 4;CHR$ 144
50 IF Y>=0 THEN PRINT AT Y,C;" ": LET Y=Y-1: IF Y>=0 THEN PRINT AT Y,C; INK 6;CHR$ 145
60 IF Y<0 AND K$=" " THEN LET C=X: LET Y=20: PRINT AT Y,C; INK 6;CHR$ 145
70 GO TO 20
900 BORDER 0: PAPER 0: INK 7: CLS
910 RESTORE 990
920 FOR N=0 TO 7: READ D: POKE USR "a"+N,D: NEXT N
930 FOR N=0 TO 7: READ D: POKE USR "b"+N,D: NEXT N
940 LET X=15: LET Y=-1
950 PRINT AT 21,X; INK 4;CHR$ 144
960 GO TO 20
990 DATA BIN 00011000,BIN 00011000,BIN 00011000,BIN 01111110
995 DATA BIN 11111111,BIN 11111111,BIN 11111111,BIN 11111111
996 DATA BIN 00000000,BIN 00011000,BIN 00011000,BIN 00011000
997 DATA BIN 00011000,BIN 00011000,BIN 00011000,BIN 00000000
9000 REM Variables, kept at the end so GO TO 20 does not walk past them
9010 REM X=base column 0-31, on row 21
9020 REM K$=key read by INKEY$, or ""
9030 REM Y=shot row, or -1 if no shot is in flight
9040 REM C=shot column, set when the shot is fired
9050 REM N=UDG byte 0-7 being poked
9060 REM D=one byte of a UDG
```

The source is `step2-shot.bas`. A tape image ready to load is `step2-shot.tap`, with the program name `shot`.

## Line by line

- **10** jumps over the loop to the set-up at line 900, as in step 1.
- **20** reads the key being held, or `""` if none, into `K$`.
- **30–40** move the base with O and P, exactly as in step 1, stopping at columns 0 and 31.
- **50** if a shot is in flight (`Y>=0`): prints a space over it, subtracts 1 from `Y` so the shot moves up one row, and, if it is still on the screen, reprints it in yellow. If `Y` has become `-1`, the second `IF` is false and the shot is left erased at the top.
- **60** if there is no shot in flight and Space is held: records the base's column in `C`, puts the shot on row 20 (the row just above the base) and prints it there, in yellow. If a shot is already flying, `Y>=0` and this line does nothing.
- **70** goes back to read the keyboard again.
- **900** sets a black border and paper and white ink, and clears the screen.
- **910** points `READ` at the `DATA` on line 990.
- **920** defines UDG A, the base, as in step 1.
- **930** then reads the next eight bytes and pokes them into UDG B, the shot. `READ` carries on through the `DATA` from where line 920 left off.
- **940** puts the base in column 15 and sets `Y` to `-1`, so the first pass of the loop will not try to draw a shot.
- **950** draws the base on row 21, in green.
- **960** jumps into the loop.
- **990–995** hold the eight rows of the base, as in step 1.
- **996–997** hold the eight rows of the shot, written with `BIN` so the bolt can be seen in the listing.
- **9000–9060** name the variables. **X** is the base's column, 0 to 31. **K$** is the key just read, or empty. **Y** is the shot's row, or `-1` if no shot is in flight. **C** is the shot's column, set when it is fired. **N** counts a UDG's rows 0 to 7, and **D** is the byte read for one row.

The shot is moved on line 50 before a new one can be fired on line 60. A newly fired shot therefore sits at row 20 for a full pass of the loop before it starts to climb, and a shot that has just left the top can be replaced on the same pass if Space is still held.

The shot is only drawn while it is in flight, and the base is still only redrawn when it moves, so neither of them flickers while it stands still.

## How fast is it?

As in step 1, `FRAMES` is the stopwatch. This copy of the program places a shot at row 20, starts the clock, and stops when the shot has been erased at the top, 21 steps later. The base is not moving.

```
10 GO TO 900
20 LET K$=""
30 IF (K$="o" OR K$="O") AND X>0 THEN PRINT AT 21,X;" ": LET X=X-1: PRINT AT 21,X; INK 4;CHR$ 144
40 IF (K$="p" OR K$="P") AND X<31 THEN PRINT AT 21,X;" ": LET X=X+1: PRINT AT 21,X; INK 4;CHR$ 144
50 IF Y>=0 THEN PRINT AT Y,C;" ": LET Y=Y-1: IF Y>=0 THEN PRINT AT Y,C; INK 6;CHR$ 145
55 IF Y<0 THEN GO TO 970
70 GO TO 20
900 BORDER 0: PAPER 0: INK 7: CLS
910 RESTORE 990
920 FOR N=0 TO 7: READ D: POKE USR "a"+N,D: NEXT N
930 FOR N=0 TO 7: READ D: POKE USR "b"+N,D: NEXT N
940 LET X=15: LET C=15: LET Y=20
950 PRINT AT 21,X; INK 4;CHR$ 144
952 PRINT AT Y,C; INK 6;CHR$ 145
955 LET T=PEEK 23672+256*PEEK 23673
960 GO TO 20
970 LET T=PEEK 23672+256*PEEK 23673-T
980 PRINT AT 0,0;"21 STEPS: ";T;" FRAMES"''"ONE STEP: ";T/21;" FRAMES"
985 STOP
990 DATA BIN 00011000,BIN 00011000,BIN 00011000,BIN 01111110
995 DATA BIN 11111111,BIN 11111111,BIN 11111111,BIN 11111111
996 DATA BIN 00000000,BIN 00011000,BIN 00011000,BIN 00011000
997 DATA BIN 00011000,BIN 00011000,BIN 00011000,BIN 00000000
```

In Fuse it printed `21 STEPS: 60 FRAMES` and `ONE STEP: 2.8571429 FRAMES`. Each upward step of the shot takes about 2.9 frames, a little under a seventeenth of a second. The shot climbs from the row above the base to the top of the screen in 60 frames, 1.2 seconds.

The same loop, with no shot in flight and the base pretending P is always held, crossed the screen in 90 frames, 2.9 frames a step (31 steps, from column 0 to column 31). That is a little slower than step 1's 2.4 frames, because the loop now also tests the shot and the fire key on every pass, even when `Y` is `-1`. The shot and the base therefore move at the same rate, one cell per pass of the loop. The shot only reaches the top before the base reaches the far edge because it has 21 rows to travel, not 31 columns.

When the base is moved on the same passes as a live shot, both slow to about 3.9 frames a step (31 steps of the base in 121 frames). The two objects still take one cell per pass; each pass just takes longer, because it has to rub out and reprint both of them.

The plan noted that the shot should travel faster than the player feels they move, and suggested stepping it more than once per loop. This step leaves it at one row per pass, so the listing stays simple, and puts a second step in "Try this" below, with a measured time.

These are the numbers for Chapter 5 to beat: 2.9 frames for one step of the shot, and 2.9 frames for one step of the base when the shot is not in flight.

## Limitations you will notice

The shot, like the base, moves a whole character, eight pixels, at a time, so it jumps rather than glides. Moving a pixel at a time needs machine code, which comes in Chapter 5.

Its speed is just however long the loop takes. Here that is about 2.9 frames a step, or 3.9 when the base is moving as well, and it is not tied to the 50 Hz frame. Once the invaders are in, both the base and the shot will hitch. Machine code can update the shot every frame without slowing the player, and could allow more than one shot at a time.

`INKEY$` reads one key at a time. Holding O or P and pressing Space together does not fire; in Fuse, the base kept moving and no shot appeared. Let go of the direction key, then press Space. Chapter 5 reads the keyboard directly and can see several keys at once.

Caps Shift and Space is Break, so a "capital Space" stops the program rather than firing.

A very short tap of Space may be missed, as with O and P in step 1, because the keyboard is only read once per pass. Hold Space briefly to fire. If you keep holding Space after the shot has left the top, a new shot is fired at once: that is line 60 running on the same pass as the old shot is erased.

The shot stays in the column it was fired from. Moving the base after firing does not steer the bolt.

## Running it

A screenshot of a shot in mid-flight, lined up with the base's barrel, is in `step2-shot.png`.

To build the tape and open it in Fuse, from the course folder, on Windows:

```
windows-tools\build.bat chapter-04-invaders-basic\step2-shot.bas shot 10
```

On Linux:

```
tools/build.sh chapter-04-invaders-basic/step2-shot.bas shot 10
```

`shot` is the name stored on the tape, which `LOAD` shows as `Program: shot`, and `10` is the line the program runs from after it loads. Fuse opens with the tape loading by itself. Hold O to move left and P to move right, as in step 1, and press Space to fire. Break the program with Caps Shift and Space (in Fuse, Shift and Space).

You can also load the ready-made `step2-shot.tap` in any 48K emulator and type `LOAD ""`. The helper script `tools/run-tap.sh chapter-04-invaders-basic/step2-shot.bas` builds the tape and runs it in Fuse under Xvfb, and `KEYS=space` or `KEY_HOLD=space` will fire while it captures; see [tools/README.md](../tools/README.md). Set `TAP_NAME=shot` if you want the name on the tape to match the ready-made file.

## Try this

Make the shot step twice each pass, so it climbs faster than the base. Add a second copy of line 50 as line 51:

```
51 IF Y>=0 THEN PRINT AT Y,C;" ": LET Y=Y-1: IF Y>=0 THEN PRINT AT Y,C; INK 6;CHR$ 145
```

In Fuse, the same 21-step timing as above then printed `21 STEPS: 45 FRAMES` and `ONE STEP: 2.1428571 FRAMES`. The flight drops from 1.2 seconds to 0.9 seconds. It is not twice as fast, because each pass now has more work to do. This is the plan's suggestion that the shot may step more than once per loop. Later steps will add work to the loop, and you can come back to a second step if the shot then feels too slow.

Redesign the bolt. Change the bytes in lines 996 and 997 and run the program again. For a bar that fills the whole cell, try `BIN 00011000` eight times. Keep the ink in bits 4 and 3 so the shot still lines up with the barrel.
