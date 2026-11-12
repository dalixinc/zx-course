# Chapter 3, step 1 — The memory map and the system variables

Before we put any machine code into the Spectrum, we need to know where it can go. Put it in the wrong place and BASIC will overwrite it, or it will overwrite BASIC, and the machine crashes. This step walks the 48K memory map from the ROM at address 0 up to the top of RAM at 65535, and reads the live values of the system variables that tell you where BASIC has put things.

The program is a memory map explorer. It prints the fixed parts of the map, then `PEEK`s seven system variables and prints where the BASIC program starts, where its variables are, where its working space ends, where `RAMTOP` is, and how much free memory is left. It draws the whole 64K as a coloured bar. Then, after a key press, it does `CLEAR 49999` and prints everything again beside the first set of figures, so you can see what moved and what did not. It finishes by showing three more system variables and the `FRAMES` counter ticking.

That `CLEAR 49999` is the one line in this chapter that matters most. From step 5 onwards our machine code lives at 50000, and this step shows why it is safe there. We may move it lower later if we need more room.

No assembler yet. pasmo comes in step 6. This step is BASIC only.

Every program is tested in a 48K emulator before it is shown.

## The 48K memory map

These are the standard 48K figures from the system variables chapter (Chapter 25) of the ZX Spectrum BASIC manual. The live figures were read in Fuse with this step's program.

| Addresses | Hex | What is there |
|-----------|-----|---------------|
| 0–16383 | `$0000–$3FFF` | ROM: the BASIC interpreter and the operating system. You can read it, but a `POKE` there does nothing. |
| 16384–22527 | `$4000–$57FF` | Screen bitmap, 6144 bytes, one bit per pixel (Chapter 1). |
| 22528–23295 | `$5800–$5AFF` | Attributes, 768 bytes, one per character cell (Chapter 1). |
| 23296–23551 | `$5B00–$5BFF` | Printer buffer, 256 bytes. |
| 23552–23733 | `$5C00–$5CB5` | System variables. |
| 23734 up | `$5CB6` up | Channel information, then the BASIC program (from `PROG`), its variables (from `VARS`), the line being edited (`E LINE`), and the calculator stack, which ends at `STKEND`. |
| `STKEND` to `RAMTOP` | | Free memory. The machine stack and the `GO SUB` stack sit at the top of it, just under `RAMTOP`. |
| `RAMTOP`+1 to 65535 | | Above `RAMTOP`: BASIC does not use this. The user-defined graphics are here by default, from `UDG` (65368) to 65535. |

The bottom of the map is fixed by the hardware. The middle moves as you type and run programs: everything from `PROG` to `STKEND` grows and shrinks. The top is set by `RAMTOP`, which you move with `CLEAR`.

## The system variables we read

The system variables are bytes in RAM that the ROM uses to keep track of the machine. The names are the manual's labels. BASIC does not know them; you use the address. The manual marks some of them as unsafe to `POKE`. In this step we only read them.

| Address | Name | Bytes | What it holds |
|---------|------|------:|---------------|
| 23560 | `LAST K` | 1 | The code of the last key pressed. |
| 23606 | `CHARS` | 2 | 256 less than the address of the character set. In the ROM, so 15360 on every 48K. |
| 23624 | `BORDCR` | 1 | The border colour times 8, plus the attribute of the lower screen. |
| 23627 | `VARS` | 2 | Where the BASIC variables start. |
| 23635 | `PROG` | 2 | Where the BASIC program starts. |
| 23641 | `E LINE` | 2 | Where the line being edited starts. It sits just after the variables. |
| 23653 | `STKEND` | 2 | The end of the calculator stack, and the start of free memory. |
| 23672 | `FRAMES` | 3 | A counter that goes up by one every 20 ms, so 50 a second. |
| 23675 | `UDG` | 2 | The address of the first user-defined graphic, the same number `USR "a"` gives. |
| 23693 | `ATTR P` | 1 | The permanent colours, as set by `PAPER`, `INK`, `BRIGHT` and `FLASH`. |
| 23730 | `RAMTOP` | 2 | The last byte BASIC may use. |
| 23732 | `P RAMT` | 2 | The last byte of RAM. |

## The new BASIC keywords used here

`POKE` was used in Chapter 1 and in Chapter 2 step 4. `PEEK` was shown in step 4, but this is the first program to depend on it. `READ`, `DATA`, `RESTORE`, `GO SUB` and `INKEY$` are as in Chapter 2.

### PEEK, and reading a two-byte value

`PEEK address` returns the byte at that address, 0 to 255.

```
PRINT PEEK 23693
```

One byte cannot hold an address. Addresses run from 0 to 65535, so the system variables that hold one use two bytes. The Z80 stores the low byte first, at the lower address, and the high byte next. The value is the low byte plus 256 times the high byte:

```
PRINT PEEK 23730+256*PEEK 23731
```

The general form for a two-byte variable at address `a` is `PEEK a+256*PEEK (a+1)`. The brackets in `PEEK (a+1)` matter: `PEEK a+1` is `(PEEK a)+1`, because `PEEK` is a function and binds more tightly than `+`. You will see this "low byte first" order again in every Z80 instruction that holds an address.

`FRAMES` has three bytes, so it needs a third term:

```
PRINT PEEK 23672+256*PEEK 23673+65536*PEEK 23674
```

### POKE, and writing a two-byte value

`POKE address,value` writes one byte, 0 to 255. To store a number from 0 to 65535 you split it into a low byte and a high byte, and write them low byte first:

```
10 LET V=50000
20 POKE 60000,V-256*INT (V/256)
30 POKE 60001,INT (V/256)
40 PRINT PEEK 60000+256*PEEK 60001
```

`INT (V/256)` is the high byte, and `V-256*INT (V/256)` is what is left over, the low byte. Line 40 reads it back and prints 50000. The program uses this to save its first set of figures where `CLEAR` cannot reach them.

### CLEAR

`CLEAR` deletes all the variables, does a `RESTORE` and a `CLS`, and empties the `GO SUB` stack.

`CLEAR n` does all that and also sets `RAMTOP` to `n`. BASIC then keeps everything it owns below `n`: the program, the variables, the calculator stack, the `GO SUB` stack and the machine stack. The bytes above `n` are left alone, by `CLEAR`, by `NEW`, and by a program that grows or runs out of memory.

```
CLEAR 49999
PRINT PEEK 23730+256*PEEK 23731
```

The second line prints 49999. Three things to know when you use it in a program:

- The variables are gone afterwards, so set them again.
- The screen is cleared, so print anything you want to keep after the `CLEAR`.
- Do not put `CLEAR` inside a subroutine: it empties the `GO SUB` stack, so the `RETURN` has nowhere to go.

### TAB

`TAB n` in a `PRINT` moves the print position on to column `n` of the current line. It is a simple way to line figures up in columns.

```
PRINT "PROG";TAB 7;23635;TAB 14;23755
```

### Strings in DATA

`DATA` can hold strings as well as numbers, in quotes. `READ` puts them into a string variable. Numbers and strings can be mixed, as long as each `READ` asks for the right kind:

```
10 READ N$,A
20 PRINT N$;" ";A
30 DATA "RAMTOP",23730
```

## Why CLEAR 49999 and code at 50000

`RAMTOP` is the fence between BASIC and the rest of memory. On a fresh 48K it is at 65367, so BASIC may use everything up to there. The UDGs, at 65368 to 65535, are above it, which is why a `NEW` does not wipe them.

Machine code needs the same protection. If you `POKE` a routine into free memory under `RAMTOP`, it is not safe: a longer program, more variables or a deep calculation can grow up into it, and the machine stack, which grows down from `RAMTOP`, can grow down into it.

`CLEAR 49999` moves the fence down. From then on BASIC stays below 50000, and the 15368 bytes from 50000 to 65367 belong to us. The UDG area stays where it was, still above `RAMTOP`. The program shows that the area is left alone: it saves its first set of figures at 50000 to 50013 before the `CLEAR`, and reads them back afterwards.

The printer buffer, at 23296, is sometimes used for a few bytes of code. It is only 256 bytes long, `LPRINT` and `COPY` write over it, and on the 128K machines the system uses it. We will not use it for code.

## The listing

```
1 REM N$=name of a system variable
2 REM A=address of the system variable
3 REM I=table row 0-6
4 REM V=two-byte value read with PEEK
5 REM B=value saved before CLEAR
6 REM S=STKEND, end of BASIC's data
7 REM T=RAMTOP, top of BASIC's area
8 REM Y=screen row for a memory bar
9 REM C=bar cell 0-31, 2048 bytes each
10 REM M=first address of a bar cell
11 REM P=PAPER colour of a bar cell
12 REM G=FRAMES, 50 counts a second
20 BORDER 0: PAPER 0: INK 7: CLS
30 GO SUB 800
40 RESTORE 900
50 FOR I=0 TO 6
60 READ N$,A
70 LET V=PEEK A+256*PEEK (A+1)
80 PRINT AT 7+I,0;N$;TAB 7;A;TAB 14;V
90 POKE 50000+2*I,V-256*INT (V/256)
100 POKE 50001+2*I,INT (V/256)
110 IF I=3 THEN LET S=V
120 IF I=4 THEN LET T=V
130 NEXT I
140 PRINT AT 14,0;"FREE";TAB 14;T-S
150 PRINT AT 15,0;"BEFORE CLEAR"
160 LET Y=16: GO SUB 700
170 PRINT AT 21,0;"PRESS A KEY FOR CLEAR 49999"
180 IF INKEY$<>"" THEN GO TO 180
190 IF INKEY$="" THEN GO TO 190
200 CLEAR 49999
210 GO SUB 800
220 LET S=PEEK 50006+256*PEEK 50007
230 LET T=PEEK 50008+256*PEEK 50009
240 PRINT AT 14,0;"FREE";TAB 14;T-S
250 PRINT AT 15,0;"BEFORE CLEAR"
260 LET Y=16: GO SUB 700
270 RESTORE 900
280 FOR I=0 TO 6
290 READ N$,A
300 LET B=PEEK (50000+2*I)+256*PEEK (50001+2*I)
310 LET V=PEEK A+256*PEEK (A+1)
320 PRINT AT 7+I,0;N$;TAB 7;A;TAB 14;B;TAB 21;V
330 IF I=3 THEN LET S=V
340 IF I=4 THEN LET T=V
350 NEXT I
360 PRINT AT 14,21;T-S
370 PRINT AT 17,0;"AFTER CLEAR 49999"
380 LET Y=18: GO SUB 700
390 PRINT AT 20,0;"CHARS ";PEEK 23606+256*PEEK 23607;"  ATTR P ";PEEK 23693;"  BORDCR ";PEEK 23624
400 LET G=PEEK 23672+256*PEEK 23673+65536*PEEK 23674
410 PRINT AT 21,0;"FRAMES ";G;"  LAST K ";PEEK 23560;"   "
420 GO TO 400
700 FOR C=0 TO 31
710 LET M=C*2048
720 LET P=5
730 IF M>T THEN LET P=2
740 IF M<S THEN LET P=6
750 IF M<23296 THEN LET P=4
760 IF M<16384 THEN LET P=1
770 PRINT AT Y,C; PAPER P;" "
780 NEXT C
790 RETURN
800 PRINT AT 0,0; INVERSE 1;" 48K MEMORY MAP EXPLORER        "
810 PRINT AT 1,0;"0-16383     ROM"
820 PRINT AT 2,0;"16384-22527 SCREEN BITMAP"
830 PRINT AT 3,0;"22528-23295 ATTRIBUTES"
840 PRINT AT 4,0;"23296-23551 PRINTER BUFFER"
850 PRINT AT 5,0;"23552-23733 SYSTEM VARIABLES"
860 PRINT AT 6,0; INVERSE 1;"NAME   AT     BEFORE AFTER     "
870 PRINT AT 19,0; PAPER 1;"ROM"; PAPER 0;" "; PAPER 4; INK 0;"SCREEN"; PAPER 0;" "; PAPER 6; INK 0;"BASIC"; PAPER 0;" "; PAPER 5; INK 0;"FREE"; PAPER 0;" "; PAPER 2;"RESERVED"
890 RETURN
900 DATA "PROG",23635,"VARS",23627,"E LINE",23641
910 DATA "STKEND",23653,"RAMTOP",23730,"UDG",23675
920 DATA "P RAMT",23732
```

The source is `step1-memory-map.bas`. A tape image ready to load is `step1-memory-map.tap`.

## What it showed in Fuse

The screenshot is `step1-memory-map.png`. These are the figures from a 48K Fuse, with the program loaded from tape. They depend on the length of the program and on which variables exist, so if you type the program in yourself, `VARS`, `E LINE`, `STKEND` and `FREE` will be a little different.

| Name | Before `CLEAR` | After `CLEAR 49999` |
|------|---------------:|--------------------:|
| `PROG` | 23755 | 23755 |
| `VARS` | 26448 | 26448 |
| `E LINE` | 26489 | 26544 |
| `STKEND` | 26494 | 26549 |
| `RAMTOP` | 65367 | 49999 |
| `UDG` | 65368 | 65368 |
| `P RAMT` | 65535 | 65535 |
| Free (`RAMTOP`−`STKEND`) | 38873 | 23450 |

What to notice:

- `PROG` is 23755. That is 21 bytes past the end of the system variables, for the channel information.
- The program itself is `VARS`−`PROG` = 2693 bytes. The `REM` lines are part of that.
- `RAMTOP` drops from 65367 to 49999. `UDG` does not move: the graphics are still above `RAMTOP`.
- `E LINE` and `STKEND` are 55 bytes higher after the `CLEAR`. That is not the `CLEAR`. By the time the second table is read, the program has made more variables (`B`, `S`, `T`, `Y`, `C`, `M`, `P`) than it had when the first table was read, and each one takes room between `VARS` and `E LINE`.
- Free memory falls by 15423 bytes: 15368 handed over to our code, plus those 55.

The last two lines showed `CHARS` 15360, `ATTR P` 7 (paper 0, ink 7, which is 8×0+7), `BORDCR` 7 (border 0, and the lower screen in ink 7), and `LAST K` 99, the code for `c`, the key that was pressed to go on. `FRAMES` went up by 589 in 11.79 seconds by the screenshot clock, which is 50 a second.

## Line by line

- **1–12** name the variables.
- **20** sets black border and paper, white ink, and clears the screen.
- **30** prints the title, the fixed part of the map, the table heading and the colour key (the subroutine at 800).
- **40–130** read seven names and addresses from `DATA`. For each one, `PEEK` the two-byte value, print the name, the address and the value, and save the value at 50000 onwards, two bytes each, low byte first. `STKEND` (the fourth, `I=3`) is kept in `S` and `RAMTOP` (the fifth, `I=4`) in `T`.
- **140** prints the free memory, `T-S`.
- **150–160** label and draw the "before" bar on row 16.
- **170–190** ask for a key, wait for all keys to be up, then wait for a press.
- **200** `CLEAR 49999`. `RAMTOP` is now 49999, the variables are gone, and the screen is clear.
- **210** prints the fixed text again.
- **220–260** read the saved `STKEND` and `RAMTOP` back from 50006 and 50008, and print the "before" free memory and bar again. They survived the `CLEAR` because they are above the new `RAMTOP`.
- **270–350** read the table again, now with two columns: the saved value and the live value. `S` and `T` take the live `STKEND` and `RAMTOP`.
- **360** prints the free memory after the `CLEAR`.
- **370–380** label and draw the "after" bar on row 18.
- **390** prints `CHARS`, `ATTR P` and `BORDCR`.
- **400–420** read the three bytes of `FRAMES` and print them with `LAST K`, over and over. Press a key and watch `LAST K` change. Press BREAK to stop.
- **700–790** draw a memory bar. Each of the 32 cells stands for 2048 bytes, so the bar is the whole 64K. `M` is the first address of the cell. A cell is blue if it starts in the ROM, green if it starts in the screen, yellow if it starts below `STKEND`, cyan if it is free, and red if it starts above `RAMTOP`.
- **800–890** print the title, the fixed map, the table heading and the colour key.
- **900–920** the names and addresses of the seven system variables.

## Limitations you will notice

The bar is coarse: one cell is 2048 bytes, and a cell takes its colour from its first byte only. The yellow cell at 24576 also holds the start of the free memory, and the attributes, the printer buffer, the system variables and the start of the program are all hidden inside the last green cell. It shows the proportions, not the detail. The UDGs, 168 bytes, are too small to show.

The figures are a snapshot. Every new variable, and every number the calculator works on, moves `E LINE` and `STKEND`. Free memory is approximate in the same way: some of it, just under `RAMTOP`, is the machine stack and the `GO SUB` stack.

Reading `FRAMES` with three `PEEK`s is not quite safe. The counter can change between one `PEEK` and the next, and if the low byte wraps from 255 to 0 between them, the figure is out by 256 for that one reading. The Chapter 2 timings read it twice to avoid that. For a display that updates all the time, it does not matter.

Saving the "before" figures at 50000 works because nothing else is using that memory at the time. Before the `CLEAR` it is ordinary free memory, and a bigger program could have grown into it. That is the point of the `CLEAR`.

The program only reads system variables. Step 2 changes some of them on purpose and watches what happens.

## Try this

- Add a line or two to the program, or a long `REM`, and run it again. `PROG` stays the same; `VARS`, `E LINE` and `STKEND` move up.
- Change 49999 in line 200 to 39999, and watch the red part of the second bar grow.
- After the program has run, type `PRINT PEEK 50000+256*PEEK 50001`. It prints 23755, the saved `PROG`. The manual says `NEW` only clears memory up to `RAMTOP`, and keeps `RAMTOP` where `CLEAR` put it, so type `NEW` and try the `PRINT` again.
