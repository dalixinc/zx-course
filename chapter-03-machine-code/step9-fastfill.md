# Chapter 3, step 9 — The interactive fill, now fast

Step 3 asked you for an ink, a paper, bright on or off and an eight-digit bit pattern. It showed you the attribute byte and the pattern byte it built from them, then filled the screen with them in BASIC. The bitmap fill took **3699 frames** (74 seconds) and the attribute fill **489 frames** (nearly 10 seconds). This step is its twin, and the last step of the chapter. It is the same program, with the same questions, the same checks and the same breakdown. Only the two fill subroutines have changed. Each one is now a `RANDOMIZE USR` call to machine code: steps 7 and 8's `LDIR` fill, and step 8's fill down the screen.

BASIC asks the questions and machine code does the filling. That is the shape the plan promised at the start of the chapter.

There are three things to compare with step 3:

1. **The speed.** One bitmap fill took 2.42 frames and one attribute fill 0.308 frames, against step 3's 3699 and 489. That is about 1530 and 1590 times as fast. You press a key and the pattern is on the screen in a twentieth of a second.
2. **How it is put together.** Step 3's eight lines of `FOR`, `POKE` and `NEXT` become three lines that `POKE` two parameter bytes and call the code. Of step 3's 73 program lines, not counting the `REM`s, 61 are unchanged. The section "Side by side" goes through what disappeared and what stayed.
3. **Who does what.** BASIC is good at the parts that happen once: asking, checking, working out the two bytes and printing the breakdown. Machine code is good at the part that happens 6912 times. The section "Side by side" sets the two jobs out.

There is one new question, the fill order. You can choose memory order, the `LDIR` fill, which is the fastest, or screen order, step 8's fill that goes down the screen from top to bottom. At full speed you cannot see the difference: the timing table is where it shows.

The new instructions are `LD D,H` and `LD E,L`, which copy one register pair into another a half at a time, and `PUSH` and `POP` of HL and BC to keep values safe while `LDIR` uses them. The new idea is one routine shared by two jobs, with its inputs in registers instead of in memory. The rest was in steps 4 to 8.

Every program here was assembled with pasmo, cross-checked against a second assembler, z80asm, and run in a 48K emulator before it was shown.

## The new instructions and ideas

### Four parameter bytes, two of them your answers

As in steps 7 and 8, BASIC passes values in through bytes at the start of the code:

```
pattern: db 170         ; 50000: the pattern, POKEd by BASIC
colour: db 56           ; 50001: the attribute, POKEd by BASIC
times:  db 1            ; 50002: how many fills
slow:   db 0            ; 50003: HALTs per line in sdown
```

| In the code | Reads | In BASIC, to change it |
|-------------|-------|------------------------|
| `ld a,(pattern)` | 50000 | `POKE 50000,N`, the pattern you typed, 0 to 255 |
| `ld a,(colour)` | 50001 | `POKE 50001,T`, the attribute, `64*B+8*P+I` |
| `ld a,(times)` | 50002 | `POKE 50002,50` before the bitmap, `POKE 50002,250` before the attributes |
| `ld a,(slow)` | 50003 | the program leaves it at 0; "Try this" uses it |

Step 3's subroutines read `N` and `T` from BASIC's variables every time round the loop, 6144 and 768 times. Here BASIC hands each byte over once, with one `POKE`, and the machine code keeps it in a register.

There is no `where` byte this time. Steps 7 and 8 could fill anywhere, which was useful for the timing tests at 32768 and 60000, and dangerous if `where` was wrong. This program only ever fills the screen, so the two addresses, 16384 and 22528, are written into the code. One way to go wrong has gone.

The code starts at 50004, after the four parameters.

### One routine, two jobs: inputs in registers

Steps 7 and 8 each had an `LDIR` fill, and they were nearly the same routine. Step 7's filled 768 bytes from `where` with `colour`; step 8's filled 6144 bytes from `where` with `pattern`. The only differences were the byte, the start, and the count.

So this step has one fill, `ldfill`, and the three things that differ are handed to it in registers:

| Register | Holds, on the way into `ldfill` | Bitmap | Attributes |
|----------|---------------------------------|--------|------------|
| A | the byte to fill with | `ld a,(pattern)` | `ld a,(colour)` |
| HL | the first address | `ld hl,16384` | `ld hl,22528` |
| BC | the number of bytes `LDIR` copies, one fewer than the length | `ld bc,6143` | `ld bc,767` |

Each entry point is three loads, then the shared code:

```
bitmap: ld a,(pattern)  ; A = the pattern BASIC POKEd
        ld hl,16384     ; HL = the first byte of the bitmap
        ld bc,6143      ; BC = the other 6143 bytes
        jr ldfill       ; fill them

attrs:  ld a,(colour)   ; A = the colour BASIC POKEd
        ld hl,22528     ; HL = the first attribute
        ld bc,767       ; BC = the other 767 cells
                        ; and on into ldfill

ldfill: ld (hl),a       ; the first byte, by hand, once
```

`bitmap` jumps to `ldfill` with `jr`. `attrs` does not need to jump at all, because `ldfill` is the very next instruction: the Z80 simply runs on into it. That is called *falling through*. It saves two bytes, but it only works for one of the two entry points, and only while nothing is put between `attrs` and `ldfill`. The comment `and on into ldfill` is there so nobody does.

This is the same idea as a BASIC subroutine that takes its values in variables: step 3's line 40 took the pattern in `N`. The difference is that registers are faster to reach than memory, and that the caller sets them just before the jump, so there is no doubt what they hold.

Why not `call ldfill` and `ret`? It would work, and it would be one instruction longer. With `jr`, the `ret` at the end of `ldfill` goes straight back to BASIC, the `USR` that called `bitmap`. With `call`, it would go back to `bitmap`, which would then need its own `ret`.

### LD D,H and LD E,L — copying a register pair

`LDIR` copies from HL to DE. To fill, DE must be one byte ahead of HL. Steps 7 and 8 loaded DE from memory, `ld de,(where)`, then `inc de`. Here the start is already in HL, so it is copied across one half at a time:

```
        ld d,h
        ld e,l          ; DE = HL
        inc de          ; DE = the next address, HL+1
```

| Instruction | Bytes (hex) | Bytes (decimal) | T-states |
|-------------|-------------|-----------------|----------|
| `LD D,H` | `54` | 84 | 4 |
| `LD E,L` | `5D` | 93 | 4 |
| `LD DE,(nn)` (step 7) | `ED 5B` n n | 237, 91, n, n | 20 |

The Z80 has no single `LD DE,HL`. Two one-byte loads do the job in 8 T-states. Step 6 used the same kind of load, `ld b,h` / `ld c,l`, to copy HL into BC, the pair `USR` hands back to BASIC.

### PUSH HL and PUSH BC — keeping values while LDIR uses them

`LDIR` counts BC down to 0 and moves HL and DE on to the end of the block. For one fill that does not matter. To fill again, for the stopwatch, `ldfill` needs the start and the count back. So it keeps them on the stack, with the count of fills:

```
lrep:   push af         ; keep the count
        push hl         ; keep the start
        push bc         ; keep the length
        ...
        ldir
        pop bc          ; BC = the length again
        pop hl          ; HL = the start again
        pop af          ; A = the count again
```

| Instruction | Bytes (hex) | Bytes (decimal) | T-states |
|-------------|-------------|-----------------|----------|
| `PUSH HL` | `E5` | 229 | 11 |
| `PUSH BC` | `C5` | 197 | 11 |
| `POP BC` | `C1` | 193 | 10 |
| `POP HL` | `E1` | 225 | 10 |

Step 5 introduced `PUSH` and `POP` with BC, and step 6 used `push hl`. The new point is the order. The stack is last in, first out, like a pile of plates. The three values go on as AF, HL, BC, so they must come off as BC, HL, AF. Pop them in the same order as they were pushed, and the start would land in BC and the length in HL.

The first byte is only written once, before the loop: `ld (hl),a`. After the first fill it is still there, so the later `LDIR`s copy it along as before. That leaves A free to hold the count of fills, as it did in steps 7 and 8.

Each extra fill costs 93 T-states besides the `LDIR` itself. Step 8's `fldir` spent 109, because it read `pattern` and `where` from memory again every time. It makes no difference you could measure: 16 T-states is a two-hundred-thousandth of a second.

### Repeating for the stopwatch

One bitmap fill takes about 2.4 frames, and one attribute fill about a third of a frame. `FRAMES` counts whole frames, so one fill would read 2 or 3, or 0 or 1, and most of that would be BASIC. As in steps 7 and 8, the code repeats each fill for the stopwatch: 50 times for the bitmap and 250 for the attributes, the same counts as steps 8 and 7, so the figures can be set beside theirs.

You see the first fill straight away. The other 49 write the same bytes over the same bytes, so nothing changes on the screen while they run. `step9-fastfill-first.png` was taken about half a second after the key: the pattern is already there, in white on black, and the colours have not arrived yet, because the attribute fill only starts when the 50 bitmap fills are done. About four seconds after the key, both are done and the table is printed.

Step 3 timed one fill each. Its "one fill" figure is the time for that fill; this step's is the time for 50 or 250, divided by 50 or 250. Both are fair figures for one fill, and both include a little BASIC: step 3's in every `NEXT`, this step's once at each end of the run.

### A choice of order: memory or screen

The new question, `ORDER (0 MEMORY, 1 SCREEN)?`, picks the bitmap fill:

- **0, memory order:** `bitmap`, the `LDIR` fill, from 16384 to 22527 in address order. That is the fastest fill in the course: step 8 measured 2.4 frames.
- **1, screen order:** `sdown`, step 8's fill down the screen, one pixel line at a time from the top, with `nxtdn` working out the line below. Step 8 measured 2.52 frames.

The attributes are filled with `attrs`, the `LDIR` fill, either way. They are stored in screen order already, so there is nothing to choose.

At full speed both bitmap fills are over in less than a tenth of a second, and they look the same. The choice is there so you can see, in the table, what screen order costs: about one twentieth more time. "Try this" slows `sdown` down so you can watch it come down the screen.

`sdown`, `wait` and `nxtdn` are step 8's, line for line. The only change is that `sdown` starts with `ld hl,16384` where step 8 had `ld hl,(where)`. `wait` is kept, with `slow` at 0, so the routine is exactly the one step 8 timed.

### In BASIC: a string AND a number

Line 445 prints the order you chose:

```
445 PRINT AT 15,0;"ORDER";TAB 7;("MEMORY, LDIR" AND NOT R);("SCREEN, TOP DOWN" AND R)
```

In Sinclair BASIC, `a$ AND n` gives `a$` if `n` is not zero, and the empty string if it is. `NOT R` is 1 when `R` is 0. So when `R` is 0, the first bracket is `"MEMORY, LDIR"` and the second is empty; when `R` is 1, it is the other way round. It is a way to choose between two strings in the middle of a `PRINT`, without an `IF` and two `PRINT`s. The string comes first, then the number.

## The listing

The machine code, `step9-fastfill.asm`:

```
; step9-fastfill.asm - Chapter 3, step 9
; The fast interactive fill: the machine code under step 3's questions.
; Three entry points that fill the screen, called from step9-fastfill.bas.
; The LDIR fill is steps 7 and 8's, made into one routine for both jobs;
; sdown, nxtdn and wait are step 8's, unchanged except that sdown always
; starts at 16384.
;
; BASIC passes its choices in through four parameter bytes at the start:
;   50000  pattern  the bitmap byte, built from the 8 digits you type
;   50001  colour   the attribute byte, 64*bright + 8*paper + ink
;   50002  times    how many fills to do, 1 to 255 (0 means 256)
;   50003  slow     HALTs after each line in sdown, 0 for full speed
;
; Entry points:
;   RANDOMIZE USR 50004  bitmap  the bitmap, LDIR, in memory order
;   RANDOMIZE USR 50015  attrs   the attributes, LDIR
;   RANDOMIZE USR 50043  sdown   the bitmap, in screen order, top down
;
; Registers in bitmap and attrs, on the way into ldfill:
;   A  = the byte to fill with
;   HL = the first address to fill
;   BC = how many bytes LDIR copies, one fewer than the length
;
; Registers in ldfill:
;   HL = the address LDIR copies from (one byte behind DE)
;   DE = the address LDIR copies to
;   BC = bytes still to copy, down to 0
;   A  = the count of fills
;   HL, BC and the count are kept on the stack while LDIR runs
;
; Registers in sdown:
;   HL = the address being filled
;   B  = bytes still to fill in this line, 32 down to 0
;   C  = lines still to fill, 192 down to 0
;   D  = HALTs still to do after this line
;   E  = L at the start of the line
;   A  = the pattern, then scratch
;   the count of fills is kept on the stack
;
; Build:  pasmo --tap --name fastcode step9-fastfill.asm step9-fastcode.tap
; It is loaded by the driver, step9-fastfill.bas, with LOAD ""CODE.

        org 50000

pattern: db 170         ; 50000: the pattern, POKEd by BASIC
colour: db 56           ; 50001: the attribute, POKEd by BASIC
times:  db 1            ; 50002: how many fills
slow:   db 0            ; 50003: HALTs per line in sdown

; The bitmap: 6144 bytes from 16384, with the pattern.

bitmap: ld a,(pattern)  ; A = the pattern BASIC POKEd
        ld hl,16384     ; HL = the first byte of the bitmap
        ld bc,6143      ; BC = the other 6143 bytes
        jr ldfill       ; fill them

; The attributes: 768 bytes from 22528, with the colour.

attrs:  ld a,(colour)   ; A = the colour BASIC POKEd
        ld hl,22528     ; HL = the first attribute
        ld bc,767       ; BC = the other 767 cells
                        ; and on into ldfill

; ldfill: put A in the first byte at HL, then copy it along BC more
; bytes with LDIR, and do that (times) times. Changes A, BC, DE, HL.

ldfill: ld (hl),a       ; the first byte, by hand, once
        ld a,(times)    ; A = how many fills
lrep:   push af         ; keep the count
        push hl         ; keep the start
        push bc         ; keep the length
        ld d,h
        ld e,l          ; DE = HL
        inc de          ; DE = the next address, HL+1
        ldir            ; copy (HL) to (DE), HL+1, DE+1, BC-1, until BC = 0
        pop bc          ; BC = the length again
        pop hl          ; HL = the start again
        pop af          ; A = the count again
        dec a           ; one fewer fill to do
        jr nz,lrep      ; not zero: fill again
        ret

; sdown: step 8's fill in screen order, top to bottom.

sdown:  ld a,(times)    ; A = how many fills
srep:   push af         ; keep the count on the stack
        ld hl,16384     ; HL = the top line of the screen
        ld c,192        ; C = 192 lines to fill
sline:  ld a,(pattern)  ; A = the pattern
        ld b,32         ; B = 32 bytes in a line
        ld e,l          ; E = L at the start of the line
sbyte:  ld (hl),a       ; fill one byte
        inc l           ; one column to the right
        djnz sbyte      ; B-1; not zero: next byte
        ld l,e          ; back to the start of the line
        call nxtdn      ; HL = the start of the line below
        call wait       ; HALT if BASIC asked for it
        dec c           ; one fewer line to do
        jr nz,sline     ; not zero: next line
        pop af          ; A = the count again
        dec a           ; one fewer fill to do
        jr nz,srep      ; not zero: fill again
        ret

; wait: HALT slow times (none if slow is 0). Changes A and D.

wait:   ld a,(slow)     ; A = HALTs to do
        and a           ; is it 0?
        ret z           ; yes: no waiting
        ld d,a          ; D = HALTs still to do
whalt:  halt            ; wait for the next interrupt
        dec d
        jr nz,whalt
        ret

; nxtdn: the next pixel line down. In: HL in the bitmap. Out: HL one
; pixel line lower. Changes A.

nxtdn:  inc h           ; down one pixel line (RRR + 1)
        ld a,h
        and 7           ; still inside the same cell?
        ret nz          ; yes: done
        ld a,l
        add a,32        ; next character row (CCC + 1)
        ld l,a
        ret c           ; carry: crossed into the next third, H is right
        ld a,h
        sub 8           ; same third: undo the carry into TT
        ld h,a
        ret

        end
```

pasmo's listing (`pasmo -d`) shows where everything landed. These are lines from it, with the addresses in hex:

```
C350:AA		DEFB of 1 bytes
C351:38		DEFB of 1 bytes
C352:01		DEFB of 1 bytes
C353:00		DEFB of 1 bytes
C354:		label bitmap
C354:3A50C3	LD A, (C350)
C357:210040	LD HL, 4000
C35A:01FF17	LD BC, 17FF
C35D:1809	JR C368
C35F:		label attrs
C35F:3A51C3	LD A, (C351)
C362:210058	LD HL, 5800
C365:01FF02	LD BC, 02FF
C368:		label ldfill
C368:77		LD (HL), A
...
C36F:54		LD D, H
C370:5D		LD E, L
C371:13		INC DE
C372:EDB0	LDIR
...
C37A:C9		RET
C37B:		label sdown
...
C3A8:		label nxtdn
...
C3B6:C9		RET
```

`$C354` is 50004, `$C35F` is 50015 and `$C37B` is 50043: the three numbers the BASIC calls. `$C3B6` is 50102, so the whole thing is 103 bytes, 50000 to 50102. `$4000` is 16384 and `$5800` is 22528; `$17FF` is 6143 and `$02FF` is 767. The `JR` is `18 09`: jump 9 bytes on from the next instruction, `$C35F`, to `$C368`.

The BASIC driver, `step9-fastfill.bas`:

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
15 REM R=fill order, 0 memory, 1 screen
16 REM H=FRAMES high byte
17 REM L=FRAMES low byte
18 REM F=frames since FRAMES was zeroed
19 REM G=frames for 50 bitmap fills
20 REM C=frames for 250 attribute fills
22 CLEAR 49999
24 BORDER 0: PAPER 0: INK 7: CLS : PRINT "LOADING THE CODE"
26 LOAD ""CODE
30 GO TO 200
40 POKE 50000,N: POKE 50002,50: IF R THEN RANDOMIZE USR 50043: RETURN
50 RANDOMIZE USR 50004: RETURN
80 POKE 50001,T: POKE 50002,250: RANDOMIZE USR 50015: RETURN
200 BORDER 0: PAPER 0: INK 7: CLS
210 PRINT AT 0,0; INVERSE 1;" INTERACTIVE FILL (FAST)        "
220 INPUT "INK (0-7)? "; LINE A$: LET M=7: GO SUB 660: IF E THEN GO TO 220
230 LET I=VAL A$
240 INPUT "PAPER (0-7)? "; LINE A$: LET M=7: GO SUB 660: IF E THEN GO TO 240
250 LET P=VAL A$
260 INPUT "BRIGHT (0-1)? "; LINE A$: LET M=1: GO SUB 660: IF E THEN GO TO 260
270 LET B=VAL A$
272 INPUT "ORDER (0 MEMORY, 1 SCREEN)? "; LINE A$: LET M=1: GO SUB 660: IF E THEN GO TO 272
274 LET R=VAL A$
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
445 PRINT AT 15,0;"ORDER";TAB 7;("MEMORY, LDIR" AND NOT R);("SCREEN, TOP DOWN" AND R)
450 PRINT AT 17,0;"PRESS A KEY TO FILL THE SCREEN"
460 IF INKEY$<>"" THEN GO TO 460
470 IF INKEY$="" THEN GO TO 470
480 CLS
490 GO SUB 800: GO SUB 40: GO SUB 900: LET G=F
500 GO SUB 800: GO SUB 80: GO SUB 900: LET C=F
510 PRINT AT 15,0;"MACHINE CODE  FILLS FRAMES ONE  "
512 PRINT AT 16,0;"BITMAP  ";N;TAB 14;50;TAB 20;G;TAB 27;G/50;TAB 31;" "
514 PRINT AT 17,0;"ATTRS   ";T;TAB 14;250;TAB 20;C;TAB 27;C/250
516 PRINT AT 18,0;"STEP 3, BASIC: 3699 AND 489     "
518 PRINT AT 19,0;"BITMAP ";INT (3699*50/G+.5);" TIMES AS FAST        "
520 PRINT AT 20,0;"ATTRS  ";INT (489*250/C+.5);" TIMES AS FAST        "
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

Lines 200 to 930 are step 3's, apart from the title in line 210, the new question in lines 272 and 274, line 445, and the table in lines 510 to 520.

## Side by side

### What disappeared

Step 3's two fills were eight lines:

```
40 FOR A=16384 TO 22527
50 POKE A,N
60 NEXT A
70 RETURN
80 FOR A=22528 TO 23295
90 POKE A,T
100 NEXT A
110 RETURN
```

Step 9's are three:

```
40 POKE 50000,N: POKE 50002,50: IF R THEN RANDOMIZE USR 50043: RETURN
50 RANDOMIZE USR 50004: RETURN
80 POKE 50001,T: POKE 50002,250: RANDOMIZE USR 50015: RETURN
```

The `FOR`, the `POKE` and the `NEXT` have gone from the BASIC, and so has the variable `A`, the screen address. In step 3, `A` was a five-byte floating-point number, counted up 6912 times. In step 9, the address is in HL, and BASIC never sees it. Line 15, which named `A`, now names `R`, the fill order.

The rest of the program calls the fills exactly as before. Lines 490 and 500 are unchanged:

```
490 GO SUB 800: GO SUB 40: GO SUB 900: LET G=F
500 GO SUB 800: GO SUB 80: GO SUB 900: LET C=F
```

That was the reason step 3 kept its fills in two small subroutines that took their values in `N` and `T`: each could be swapped for machine code without touching anything that calls it.

Three lines were added at the start: `CLEAR 49999` to keep BASIC below the code, and `LOAD ""CODE` to load it, as in steps 7 and 8.

### Who does what

| Job | Step 3 | Step 9 |
|-----|--------|--------|
| Ask for ink, paper, bright and the pattern | BASIC, `INPUT ... LINE A$` | the same |
| Ask for the order | (no such question) | BASIC, the same way |
| Check each answer | BASIC, the subroutines at 660 and 700 | the same |
| Work out the attribute byte | BASIC, `LET T=64*B+8*P+I` | the same |
| Work out the pattern byte | BASIC, line 740, `LET N=2*N+VAL A$(K)` | the same |
| Show the breakdown in binary | BASIC, lines 300 to 440 | the same, and the order at line 445 |
| Hand over the bytes | (no handing over: the loop reads `N` and `T` itself) | BASIC, `POKE 50000,N` and `POKE 50001,T`, once each |
| Fill 6144 bitmap bytes | BASIC, `FOR A=16384 TO 22527: POKE A,N: NEXT A` | machine code, `LDIR` or `sdown` |
| Fill 768 attribute bytes | BASIC, `FOR A=22528 TO 23295: POKE A,T: NEXT A` | machine code, `LDIR` |
| Time the fills | BASIC, the stopwatch at 800 and 900 | the same, round 50 or 250 fills |
| Print the table, and ask again | BASIC | the same |

BASIC kept every job that happens once per answer: the `INPUT`s, the checks, the arithmetic and the `PRINT`s. They take a few seconds at most, once, and they are far easier to write in BASIC than in machine code. Machine code took the job that happens once per byte. In step 3 that job was nearly all the time. Step 6 showed the other side of this: when the work is printing through the ROM, machine code was only three times as fast, so there was no great reason to move it. Here the work is writing memory, and machine code wins by a factor of about 1500.

### Where a line sits no longer matters

Step 3's note showed that the speed of its fill depended on where the loop was in the program and how many variables there were: with the fills at line 1000, the bitmap took 5071 frames instead of 3699. Every `NEXT` searched the program for its line, and every `A`, `N` and `T` searched the variables.

The machine code does not search for anything. It runs from the address `USR` gives it, and keeps its values in registers. To check, the three fill lines were moved to 1000, 1010 and 1100, with the two `GO SUB`s changed to match. The table read 121, 77 and 128 frames, the same as with the fills at line 40 (see "What it showed in Fuse"). Where the BASIC is still slow, in the questions and the breakdown, it is still slow; but it now does nothing 6912 times.

### Size

| | Step 3 | Step 9 |
|---|--------|--------|
| BASIC lines | 93 (20 `REM`s) | 97 (20 `REM`s) |
| Lines that fill | 8 (40 to 110) | 3 (40, 50, 80) |
| Machine code | none | 103 bytes at 50000; the two `LDIR` fills share 39 of them |
| Steps 7 and 8, for comparison | | 55 and 187 bytes, with a fill each that did one job |

## Building and running

On Windows, from the course folder:

```
windows-tools\pasmo\pasmo.exe --tap --name fastcode chapter-03-machine-code\step9-fastfill.asm chapter-03-machine-code\step9-fastcode.tap
windows-tools\zmakebas\zmakebas.exe -a 10 -n fastfill -o step9-driver.tap chapter-03-machine-code\step9-fastfill.bas
copy /b step9-driver.tap+chapter-03-machine-code\step9-fastcode.tap chapter-03-machine-code\step9-fastfill.tap
```

On Linux, the same commands without the folder and the `.exe`, and `cat step9-driver.tap chapter-03-machine-code/step9-fastcode.tap > chapter-03-machine-code/step9-fastfill.tap` for the last one. Add `-d` to the pasmo line to see the listing.

Or let the build script do it, and open Fuse as well:

```
windows-tools\build.bat chapter-03-machine-code\step9-fastfill.bas chapter-03-machine-code\step9-fastfill.asm fastfill 10
```

On Linux:

```
tools/build.sh chapter-03-machine-code/step9-fastfill.bas chapter-03-machine-code/step9-fastfill.asm fastfill 10
```

The build scripts name the code on the tape after the file (`step9-fast`) instead of `fastcode`, and leave the two halves next to the source as `step9-fastfill-driver.tap` and `step9-fastfill-code.tap`. The code is the same, byte for byte.

When the tape has loaded, the program runs by itself and asks the questions at the bottom of the screen, as step 3 did. Type each answer and press ENTER:

1. `INK (0-7)?` one digit.
2. `PAPER (0-7)?` one digit.
3. `BRIGHT (0-1)?` 0 or 1.
4. `ORDER (0 MEMORY, 1 SCREEN)?` 0 for the `LDIR` fill, 1 for the fill down the screen.
5. `PATTERN (8 DIGITS)?` eight 0s and 1s, for example `11001100`.

The breakdown appears. Press a key, and the pattern fills the screen at once; the colours follow about two and a half seconds later, when the stopwatch's 50 bitmap fills are done. The table appears about four seconds after the key. Answer `Y` to go again, or `N` to stop.

## What it showed in Fuse

The tape was loaded in a 48K Fuse at normal speed, and the answers were typed in as a user would, one key at a time.

The checks work, as in step 3. Typing 9 for the ink printed `TYPE ONE DIGIT, 0 TO 7` and asked again. Typing 5 for the order printed `TYPE ONE DIGIT, 0 TO 1` and asked again. For the pattern, `1100` and then `11021100` each printed `TYPE 8 DIGITS, EACH 0 OR 1` and asked again.

`step9-fastfill.png` is the breakdown for step 3's first choice: ink 2, paper 6, bright 1, order 0 and the pattern `11001100`. It is step 3's breakdown, line for line: `0 1 110 010`, `64*1+8*6+2 = 114`, `01110010`, and `SUM 128+64+8+4 = 204`, with one more line, `ORDER  MEMORY, LDIR`.

`step9-fastfill-first.png` is the screen about half a second after the key, on a later run with the same answers: the stripes are there, in white on black, while the stopwatch's other bitmap fills run.

`step9-fastfill-result.png` is the end of that fill: red and yellow vertical stripes, two pixels wide, in bright, with the table over the bottom of the picture:

```
MACHINE CODE  FILLS FRAMES ONE
BITMAP  204   50    121    2.42
ATTRS   114   250   77     0.308
STEP 3, BASIC: 3699 AND 489
BITMAP 1529 TIMES AS FAST
ATTRS  1588 TIMES AS FAST
```

Answering Y went back to the questions. The second go used step 3's second choice, ink 7, paper 1, bright 0, and `10000001`, this time with order 1. `step9-fastfill-screen.png` is the result: thin white lines on blue, with `BITMAP 129 50 128 2.56` and `BITMAP 1445 TIMES AS FAST`. The attributes read 77 again. Answering N stopped the program with `9 STOP statement, 570:1`.

Three runs, each with two goes (the second and third used ink 3, paper 5, bright 1 and `11110000` for the screen-order go), gave the same figures every time: 121 frames for memory order, 128 for screen order, 77 for the attributes. A last check of the finished tape, with ink 4, paper 0, bright 1 and `10101010`, read 122 for memory order (2.44 a fill, 1516 times as fast) and 77 again. A frame either way is as fine as `FRAMES` can measure: it depends on where in a frame the stopwatch happens to start.

### Against step 3

| Fill | Step 3, BASIC, one fill | Step 9, machine code, one fill | Times as fast |
|------|------------------------:|-------------------------------:|--------------:|
| Bitmap, memory order | 3699 frames, 73.98 s | 2.42 frames, 0.048 s | 1529 |
| Bitmap, screen order | (step 3 only had memory order) | 2.56 frames, 0.051 s | 1445 |
| Attributes | 489 frames, 9.78 s | 0.308 frames, 0.006 s | 1588 |

Against step 3, the machine code gains more than steps 7 and 8 did against step 2 (1069 and 1028 times for `LDIR`). The machine code is the same speed; step 3's BASIC was slower than step 2's, because of its bigger program and its twenty variables.

### Against steps 7 and 8

| Fill | Steps 7 and 8 | Step 9 |
|------|--------------:|-------:|
| 50 bitmap fills, `LDIR` | 120 | 121 |
| 50 bitmap fills, down the screen | 126 | 128 |
| 250 attribute fills, `LDIR` | 76 | 77 |

The code is the same, so the one or two frames more are not in the machine code. To check, a five-line test program loaded the same code and timed the same three calls, with the `POKE`s before the stopwatch: 120, 76 and 126 frames, twice over, exactly the figures from steps 7 and 8. A second version, with the two `POKE`s inside the stopwatch as in step 9's line 40, gave 120 for the bitmap too. So the extra frame or two is the BASIC around the call in a bigger program, spread over 50 or 250 fills: under 2 percent.

The bytes were checked with a second assembler: z80asm built `step9-fastfill.asm` to the same 103 bytes as pasmo's `--bin`.

## Line by line

The machine code:

- **pattern, colour, times, slow** are the four parameter bytes at 50000 to 50003. Each has a starting value, so the code works even if BASIC pokes nothing.
- **bitmap** (50004) loads A with the pattern, HL with 16384 and BC with 6143, and jumps to `ldfill`.
- **attrs** (50015) loads A with the colour, HL with 22528 and BC with 767, and falls through into `ldfill`.
- **ldfill** writes A into the first byte, once. Then, `times` times: it keeps the count, the start and the length on the stack, copies HL to DE and adds one, so DE is one byte ahead, lets `LDIR` copy the first byte along the rest, takes the three values back in the opposite order, and counts down. `ret` goes back to BASIC.
- **sdown** (50043) is step 8's: `times` fills of 192 lines of 32 bytes, from 16384, top to bottom. Each line is filled with `inc l` and `djnz`, then `ld l,e` goes back to the start of the line, `nxtdn` moves down one pixel line, and `wait` does nothing while `slow` is 0.
- **wait** does `slow` `HALT`s, or none if `slow` is 0.
- **nxtdn** works out the address one pixel line down, as in step 8's aside.

The BASIC:

- **1–20** name the variables. `A` has gone; `R` is new.
- **22–26** move `RAMTOP` below the code, clear the screen, and load the code.
- **30** jumps over the fill subroutines to the start of the program.
- **40–50** the bitmap fill. Line 40 pokes the pattern `N` and 50 fills into the parameter bytes. If `R` is 1, it calls `sdown` and returns. Otherwise line 50 calls `bitmap`, the `LDIR` fill, and returns.
- **80** the attribute fill. It pokes the attribute `T` and 250 fills, and calls `attrs`.
- **200–270** as step 3: the screen, the title, and the questions for ink, paper and bright, each checked by the subroutine at 660.
- **272–274** the order, checked by the same subroutine with `M` at 1, into `R`. It comes before the pattern, because the pattern's digits stay in `A$` for line 430 to print.
- **280–440** as step 3: the pattern, checked and worked out by the subroutine at 700, and the breakdown.
- **445** prints the order you chose, with a string `AND` a number (see above).
- **450–480** as step 3: wait for a fresh key, and clear the screen.
- **490–500** as step 3, unchanged: zero `FRAMES`, call the fill subroutine, read `FRAMES` into `G` or `C`.
- **510–520** print the table: the byte, the number of fills, the frames, and the time for one fill, then step 3's figures and how many times as fast. `INT (...+.5)` rounds to the nearest whole number.
- **540–570** as step 3: clear row 21, ask whether to go again, and stop.
- **600–930** as step 3: the binary digits, the two checks, and the stopwatch.

## Limitations you will notice

- **The stopwatch makes you wait.** The fill takes a twentieth of a second, but the 49 extra bitmap fills and 249 extra attribute fills for the timing take about four seconds. For a program that only fills, change the 50 and the 250 in lines 40 and 80 to 1: by the figures above, the two fills together are under three frames of machine code. The table would then mostly measure BASIC.
- **Screen order looks the same as memory order at full speed.** The difference is only in the table. "Try this" shows it slowed down.
- **Flash is still always off,** as in step 3, and the whole screen still gets one attribute and one pattern.
- **The lower screen** is filled too, and the next `INPUT` clears it back to the normal colours, as in step 3.
- **The printing is still BASIC.** The breakdown still takes a moment to appear, line by line. It is the slowest thing left in the program, and it does not matter: it happens once.
- **Do not `RUN` it again after it stops.** `RUN` starts at line 22, and `LOAD ""CODE` will wait for the tape. Type `GO TO 200` instead: the code is still in memory above `RAMTOP`.
- **The parameter bytes keep their last values.** After a run, 50002 holds 250, the last `times` poked. The program pokes all of them before each fill, so it does not matter to the program, but it matters if you call the routines by hand, as in "Try this".

## Try this

Each of these was run in Fuse with the code loaded. The `USR` lines were run from a short test program with the same code; typed in after the program stops, they do the same.

- Watch the screen-order fill. After the program stops, type `POKE 50002,1: POKE 50003,1: RANDOMIZE USR 50043`. `sdown` does one fill with one `HALT` after each line, and the pattern comes down the screen from the top in about four seconds. Timed with `FRAMES`, it took 192 frames, one line a frame, as in step 8. `step9-fastfill-slow.png` is the screen about a second and a half in. Type `POKE 50003,0` afterwards, or the next screen-order fill from the program will take 50 times as long.
- Time 256 fills. Type `POKE 50002,0: POKE 23672,0: POKE 23673,0: RANDOMIZE USR 50004: PRINT PEEK 23672+256*PEEK 23673`. 0 in `times` means 256, as in steps 7 and 8. It takes about twelve seconds and printed **610**, 2.38 frames a fill. The same with `RANDOMIZE USR 50015` printed **77**.
- Fill by hand. Type `POKE 50000,255: POKE 50001,22: POKE 50002,1: RANDOMIZE USR 50004: RANDOMIZE USR 50015`. 255 sets every pixel, and 22 is 8*2+6, red paper and yellow ink, so the screen turns solid yellow. Then `POKE 50000,0: RANDOMIZE USR 50004` clears every pixel, and the screen turns solid red, the paper. The attributes did not change; only the pixels did.
- Move the fills to the end, as step 3's "Try this" did. Renumber line 40 to 1000, 50 to 1010 and 80 to 1100, and change `GO SUB 40` in line 490 to `GO SUB 1000` and `GO SUB 80` in line 500 to `GO SUB 1100`. In step 3 that made the bitmap fill take 5071 frames instead of 3699. Here the table still read 121, 77 and 128.
