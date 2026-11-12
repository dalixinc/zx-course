# Chapter 3, step 3 — An interactive fill in BASIC

Step 2 filled the screen with a pattern and a colour that were fixed in the listing. This step asks the user for them. You type an ink, a paper, bright on or off, and a bit pattern as eight binary digits. The program checks each answer, shows you the attribute byte and the pattern byte it has built from them, bit by bit, and then fills the screen with your choice, timing both fills with `FRAMES` as step 2 did. Then it asks if you want to go again.

It is slow, slower even than step 2, and the section "What it showed in Fuse" explains why. That is the point. Later in the chapter the two fill loops are replaced by machine code, and this program becomes the fast interactive fill. For that reason the two loops are kept apart from everything else, as two small subroutines near the top of the listing, so that each one can later be swapped for a single `USR` call.

No machine code yet. This step is BASIC only.

Every program is tested in a 48K emulator before it is shown.

## The new BASIC keywords used here

`PEEK`, `POKE`, `FOR`, `GO SUB`, `TAB`, `INVERSE` and `INKEY$` are as in the earlier steps and Chapter 2, and `STR$` and joining strings with `+` are as in Chapter 2 step 7. Four things are new: `INPUT`, `LEN`, `VAL`, and taking characters out of a string. Using a number as the condition of an `IF` is new too.

### INPUT

`INPUT` stops the program and waits for the user to type something and press ENTER. The typing happens in the bottom two lines of the screen, the lower screen, so it does not disturb a picture in the upper part. A prompt in quotes is printed first, with a `;` after it, then comes the variable that gets the answer:

```
10 INPUT "YOUR NAME? ";N$
20 PRINT "HELLO ";N$
```

Typing DALE and ENTER prints `HELLO DALE`.

With a number variable, the Spectrum works out whatever you type as an expression:

```
10 INPUT "A NUMBER? ";N
20 PRINT N
```

Typing `2*3` prints 6. That is handy, but it is also why a number `INPUT` is hard to make safe: whatever the user types is treated as BASIC. Type `X` and the program stops with `2 Variable not found`. So this program reads every answer into a string, checks it, and only then turns it into a number.

### INPUT LINE

With a string variable, `INPUT` puts a pair of quotes in the input line for you, and you type between them. The quotes can be rubbed out like anything else in the line. `INPUT LINE` reads a string with no quotes at all, so whatever is typed is taken exactly as text:

```
10 INPUT LINE A$
20 PRINT A$
```

Typing `HELLO` prints `HELLO`. A prompt can go first, as usual: `INPUT "INK (0-7)? "; LINE A$`. `LINE` only works with a string variable.

### LEN

`LEN` gives the number of characters in a string.

```
PRINT LEN "SPECTRUM"
```

This prints 8. The program uses it to check that an answer is one character long, or eight.

### VAL

`VAL` takes a string and works it out as a number. It is the opposite of `STR$`.

```
PRINT VAL "12"+1
```

This prints 13. Like a number `INPUT`, `VAL` evaluates an expression, so `PRINT VAL "2*3"` prints 6, and a string that is not good BASIC, such as `VAL "X?"`, stops the program with an error. The program only uses `VAL` on strings it has already checked are made of digits.

### Taking characters out of a string

`A$(n)` is character `n` of `A$`, counting from 1. `A$(m TO n)` is characters `m` to `n`. Leave out the end and it runs to the end of the string.

```
10 LET A$="SPECTRUM"
20 PRINT A$(1)
30 PRINT A$(3 TO 5)
40 PRINT A$(5 TO )
```

This prints `S`, `ECT` and `TRUM`. The program reads the pattern one digit at a time with `A$(K)`, and uses `S$(2 TO )` to drop the first character of a string.

### A number as a condition

`IF` takes a number as well as a comparison. Zero counts as false and anything else as true. A comparison is itself a number on the Spectrum: 1 if it is true, 0 if not.

```
10 LET E=1
20 IF E THEN PRINT "BAD ANSWER"
30 LET E=0
40 IF E THEN PRINT "NOT PRINTED"
```

This prints `BAD ANSWER` once. `PRINT (2>1);" ";(2<1)` prints `1 0`. The program's checking subroutines set `E` to 1 for a bad answer and 0 for a good one, and each question is `IF E THEN GO TO` itself, so it is asked again until the answer is good.

## The two bytes you choose

### The attribute byte

Chapter 1 and step 2 built attributes as `8*paper+ink`. The whole byte has four fields:

```
bit     7      6       5 4 3   2 1 0
       FLASH  BRIGHT   PAPER    INK
```

So the value is `128*flash+64*bright+8*paper+ink`. The program leaves `FLASH` at 0 and asks for the other three. With ink 2 (red), paper 6 (yellow) and bright 1, it is `64*1+8*6+2`, which is 114, or `01110010` in binary: 0 for flash, 1 for bright, `110` for paper 6, and `010` for ink 2. The program prints this breakdown before it fills.

### The pattern byte

Each byte of the bitmap is eight pixels in a row, with bit 7 on the left. A 1 is an ink pixel and a 0 is a paper pixel. The place values, from left to right, are 128, 64, 32, 16, 8, 4, 2 and 1, so `11001100` is `128+64+8+4`, which is 204: two ink pixels, two paper, two ink, two paper. The program reads the digits from left to right, and for each one doubles what it has so far and adds the digit. That gives the same 204 without needing the place values, and it is how a machine-code routine would do it too.

## The listing

```
1 REM I=ink, 0 to 7
2 REM P=paper, 0 to 7
3 REM B=bright, 0 or 1
4 REM T=attribute byte to fill with
5 REM N=pattern byte to fill with
6 REM A$=what the user typed
7 REM M=highest digit allowed
8 REM E=1 if the answer was bad
9 REM K=loop counter
10 REM W=place value of a bit
11 REM S$=sum of place values
12 REM V=number to show in binary
13 REM D=how many binary digits
14 REM Z$=the binary digits of V
15 REM A=screen address being filled
16 REM H=FRAMES high byte
17 REM L=FRAMES low byte
18 REM F=frames since FRAMES was zeroed
19 REM G=frames for the bitmap fill
20 REM C=frames for the attribute fill
30 GO TO 200
40 FOR A=16384 TO 22527
50 POKE A,N
60 NEXT A
70 RETURN
80 FOR A=22528 TO 23295
90 POKE A,T
100 NEXT A
110 RETURN
200 BORDER 0: PAPER 0: INK 7: CLS
210 PRINT AT 0,0; INVERSE 1;" INTERACTIVE FILL (BASIC)       "
220 INPUT "INK (0-7)? "; LINE A$: LET M=7: GO SUB 660: IF E THEN GO TO 220
230 LET I=VAL A$
240 INPUT "PAPER (0-7)? "; LINE A$: LET M=7: GO SUB 660: IF E THEN GO TO 240
250 LET P=VAL A$
260 INPUT "BRIGHT (0-1)? "; LINE A$: LET M=1: GO SUB 660: IF E THEN GO TO 260
270 LET B=VAL A$
280 INPUT "PATTERN (8 DIGITS)? "; LINE A$: GO SUB 700: IF E THEN GO TO 280
290 LET T=64*B+8*P+I
300 PRINT AT 2,0;"ATTRIBUTE BYTE"
310 PRINT AT 3,0;"BIT";TAB 7;"7";TAB 13;"6";TAB 20;"5-3";TAB 26;"2-0"
320 PRINT AT 4,0;"FIELD";TAB 7;"FLASH BRIGHT PAPER INK"
330 PRINT AT 5,0;"NUMBER";TAB 7;0;TAB 13;B;TAB 20;P;TAB 26;I
340 PRINT AT 6,0;"BINARY";TAB 7;0;TAB 13;B;
350 LET V=P: LET D=3: GO SUB 600: PRINT TAB 20;Z$;
360 LET V=I: LET D=3: GO SUB 600: PRINT TAB 26;Z$
370 PRINT AT 7,0;"BYTE";TAB 7;"64*";B;"+8*";P;"+";I;" = ";T
380 LET V=T: LET D=8: GO SUB 600: PRINT AT 8,0;"BITS";TAB 7;Z$
390 PRINT AT 10,0;"PATTERN BYTE"
400 PRINT AT 11,0;"BIT     7  6  5  4  3  2  1  0"
410 PRINT AT 12,0;"VALUE 128 64 32 16  8  4  2  1"
420 PRINT AT 13,0;"DIGIT"
430 FOR K=1 TO 8: PRINT AT 13,5+3*K;A$(K): NEXT K
440 PRINT AT 14,0;"SUM";TAB 7;S$;" = ";N
450 PRINT AT 17,0;"PRESS A KEY TO FILL THE SCREEN"
460 IF INKEY$<>"" THEN GO TO 460
470 IF INKEY$="" THEN GO TO 470
480 CLS
490 GO SUB 800: GO SUB 40: GO SUB 900: LET G=F
500 GO SUB 800: GO SUB 80: GO SUB 900: LET C=F
510 PRINT AT 18,0;"BASIC FILLS     FRAMES  SECONDS "
520 PRINT AT 19,0;"BITMAP  ";N;TAB 16;G;TAB 24;G/50;TAB 31;" "
530 PRINT AT 20,0;"ATTRS   ";T;TAB 16;C;TAB 24;C/50;TAB 31;" "
540 PRINT AT 21,0;"                                "
550 INPUT "AGAIN (Y/N)? "; LINE A$
560 IF A$="Y" OR A$="y" THEN GO TO 200
570 STOP
600 LET Z$=""
610 FOR K=1 TO D
620 LET Z$=STR$ (V-2*INT (V/2))+Z$
630 LET V=INT (V/2)
640 NEXT K
650 RETURN
660 LET E=1
670 IF LEN A$=1 AND A$>="0" AND A$<=STR$ M THEN LET E=0
680 IF E THEN PRINT AT 21,0;"TYPE ONE DIGIT, 0 TO ";M;"         ": RETURN
690 PRINT AT 21,0;"                                ": RETURN
700 LET E=1: LET N=0: LET W=128: LET S$=""
710 IF LEN A$<>8 THEN GO TO 790
720 FOR K=1 TO 8
730 IF A$(K)<>"0" AND A$(K)<>"1" THEN GO TO 790
740 LET N=2*N+VAL A$(K)
750 IF A$(K)="1" THEN LET S$=S$+"+"+STR$ W
760 LET W=W/2: NEXT K
770 LET E=0: IF S$="" THEN LET S$="+0"
780 LET S$=S$(2 TO ): PRINT AT 21,0;"                                ": RETURN
790 PRINT AT 21,0;"TYPE 8 DIGITS, EACH 0 OR 1      ": RETURN
800 POKE 23672,0: POKE 23673,0: POKE 23674,0
810 RETURN
900 LET H=PEEK 23673: LET L=PEEK 23672
910 IF PEEK 23673<>H THEN GO TO 900
920 LET F=L+256*H
930 RETURN
```

The source is `step3-interactive-fill.bas`. A tape image ready to load is `step3-interactive-fill.tap`.

## What it showed in Fuse

The program was run in a 48K Fuse at normal speed, loaded from the tape above, with the keys typed in as a user would.

The checks work. Typing 9 for the ink printed `TYPE ONE DIGIT, 0 TO 7` above the input line and asked again. For the pattern, `1100` (too short) and `11021100` (a 2 in it) each printed `TYPE 8 DIGITS, EACH 0 OR 1` and asked again.

`step3-interactive-fill.png` is the breakdown for ink 2, paper 6, bright 1 and the pattern `11001100`. The attribute is shown as `0 1 110 010`, `64*1+8*6+2 = 114`, and `01110010`. The pattern is shown under its place values, with `SUM 128+64+8+4 = 204`.

`step3-interactive-fill-result.png` is the end of that fill: red and yellow vertical stripes, two pixels wide, in bright, over the whole screen, with the times printed over it. Answering Y to `AGAIN (Y/N)?` went back to the questions. A second fill with ink 7, paper 1, bright 0 and `10000001` gave 15 (`00001111`) and 129 (`128+1`): thin white lines on blue. Answering N stopped the program with `9 STOP statement`.

| Fill | Bytes | Frames | Seconds |
|------|------:|-------:|--------:|
| Bitmap, first go (`11001100`) | 6144 | 3699 | 73.98 |
| Attributes, first go (114) | 768 | 489 | 9.78 |
| Bitmap, second go (`10000001`) | 6144 | 3539 | 70.78 |
| Attributes, second go (15) | 768 | 466 | 9.32 |

These are half as slow again as step 2, which took 2468 and 325 frames for the same loops. The loops are the same: one `POKE` and one `NEXT` for each byte. What is different is the program around them.

> **Note: where a loop sits, and how many variables there are, changes its speed.** Two searches happen every time round the loop. `NEXT` finds the line to go back to by searching from the start of the program, as step 2 showed. And every time BASIC meets a variable name, `A` or `N` or `T`, it finds the variable by searching the variables area from the start, one variable at a time. This program has more lines than step 2 and twenty variables, so both searches take longer.
>
> Both were measured. In the first draft of this program the two fill subroutines were at lines 1000 and 1100, at the end. The first fill then took 5071 frames (101.42 seconds) for the bitmap and 659 (13.18 seconds) for the attributes. Moving them to lines 40 to 110, so that `NEXT` finds them sooner, brought that down to the 3699 and 489 in the table. For the variables, a short test program filled the attributes the same way, once as it was, and once with sixteen extra variables made before the loop and nothing else changed. It took 308 frames, then 461.
>
> That is also why the second go is a little faster than the first. Each time a string variable gets a new value, the Spectrum moves it to the end of the variables area. On the second go, `A$`, `S$` and `Z$` have moved past `A`, so there are fewer variables in front of it to search through.

## Line by line

- **1–20** name the variables.
- **30** jumps over the two fill subroutines to the start of the program.
- **40–70** the bitmap fill, a subroutine. It pokes the pattern `N` into every bitmap byte, as in step 2. It is near the top so that `NEXT` finds line 40 quickly (see the note above).
- **80–110** the attribute fill, a subroutine. It pokes the attribute `T` into every attribute byte.
- **200** sets black border and paper, white ink, and clears the screen. "Again" comes back here.
- **210** prints the title in inverse.
- **220–230** ask for the ink, as a string, and check it with the subroutine at 660, which allows one digit from 0 to `M`. If the answer is bad (`E` is 1), line 220 asks again. Once it is good, `VAL` turns it into the number `I`.
- **240–250** the same for the paper, `P`.
- **260–270** the same for bright, `B`, with `M` set to 1.
- **280** asks for the pattern and checks it with the subroutine at 700, which also works out its value, `N`, and the sum `S$`.
- **290** builds the attribute byte, `T`. Flash is always 0, so `128*flash` is left out.
- **300–380** print the attribute byte as fields, as numbers, and in binary. The subroutine at 600 turns `V` into `D` binary digits in `Z$`: 3 for the paper and the ink, 8 for the whole byte. Bright is one bit, so it is printed as it is.
- **390–440** print the pattern byte: the bit numbers, the place values, the digits typed (`A$(K)`, one at a time, under their place values), and the sum.
- **450–470** ask for a key, wait for all keys to be up (the ENTER from the last answer may still be down), then wait for a press.
- **480** clears the screen.
- **490** zeroes `FRAMES`, fills the bitmap, reads `FRAMES` into `G`.
- **500** the same for the attributes, into `C`.
- **510–540** print the table over the bottom of the picture, as in step 2, with the pattern and attribute values beside their fills.
- **550–560** ask whether to go again, and go back to line 200 for Y or y.
- **570** stops.
- **600–650** build `Z$`, the last `D` binary digits of `V`. Each time round, `V-2*INT (V/2)` is the lowest bit, 0 or 1, and it goes on the front of `Z$`. Then `V` is halved, dropping that bit.
- **660–690** check a one-digit answer: one character, from "0" to `STR$ M`. Comparing strings this way works because the digits 0 to 9 have codes in order. A bad answer prints a message on row 21; a good one clears it.
- **700–790** check the pattern: eight characters, each "0" or "1". As it goes, `N` is doubled and the digit added, and `S$` collects `+128`, `+64` and so on for each 1. Line 780 drops the first `+`. If the pattern is all 0s, `S$` is set to `+0` first, so the sum shows as 0.
- **800–810** set `FRAMES` to zero, low byte first, as in step 2.
- **900–930** read `FRAMES` safely into `F`, as in step 2.

## Limitations you will notice

It is slow, slower than step 2: well over a minute for the bitmap and nearly ten seconds for the attributes. Most of that is not the `POKE`. It is the interpreter finding the line for `NEXT` and the variables for `A`, `N` and `T`, every time round, as the note above shows. A bigger program, or more variables, makes the same loop slower.

Even printing the breakdown takes a few seconds; you can watch the lines appear.

Flash is always off. The program asks for three of the four fields of the attribute byte.

The whole screen gets one attribute and one pattern. Mixing them, or drawing a picture, needs a program that works out an address for each cell, as in step 2's "Why the bitmap fills in stripes".

The lower screen, rows 22 and 23, is filled too, but the next `INPUT` clears it back to the normal colours, so the bottom two rows of the picture disappear when the program asks "AGAIN".

The fills are the two subroutines at lines 40 and 80, and each takes its value in a variable, `N` or `T`. Later in the chapter each one becomes a single `USR` call to a machine-code routine, and the rest of the program stays as it is.

## Try this

- Answer the questions with bad values on purpose: an empty answer, two digits, a letter, nine binary digits.
- Try the patterns `11111111`, `00000000`, `10101010` (step 2's 170) and `11110000`.
- Add a question for flash, and add `128*F` to line 290.
- Move the subroutines at 40 and 80 to the end of the program, at 1000 and 1100, change the two `GO SUB`s at 490 and 500, and time it again.
