# Chapter 3, step 8 — The bitmap fill in machine code, timed

Step 2 filled the 6144 bytes of the bitmap from BASIC, one `POKE` at a time, with the pattern 170 (`10101010`, a pixel on, a pixel off). It took **2468 frames**, nearly 50 seconds. This step is its twin. It does the same job, the same 6144 bytes with the same pattern, in machine code, and times it the same way, with `FRAMES`.

Step 7 did this for the 768 attribute bytes, with a loop and with `LDIR`. The bitmap is eight times bigger, and it has a twist. As step 2 showed, it is not stored in the order you see it. Filling it from the first byte to the last lays down thin stripes across the top third, then fills in between them, then moves on to the middle third. So this step fills it four ways:

1. **A loop.** Step 7's loop, with 6144 bytes instead of 768.
2. **`LDIR`.** Step 7's `LDIR` fill, with 6143 bytes copied instead of 767.
3. **Rows.** 192 lines of 32 bytes, in memory order, counted with `DJNZ`. It fills in the same order as the loop. It is here to be slowed down, so you can watch the stripes, and as a fair comparison for the next one.
4. **Down the screen.** The same 192 lines of 32 bytes, but in *screen order*: the top pixel line of the screen, then the one below it, then the one below that, down to the bottom. To get from one line to the next it uses the classic *next line down* routine, which works out the address of the line below from the address bits. Slowed down, it paints the screen from top to bottom, like a blind being pulled down.

There are three things to compare with step 2:

1. **The speed.** One fill took between 2.4 and 3.56 frames, against BASIC's 2468: between about 690 and 1030 times as fast.
2. **How it is put together.** Step 2's `FOR A=16384 TO 22527: POKE A,170: NEXT A` becomes six instructions in a loop, or an `LDIR`, or two loops one inside the other.
3. **The arithmetic.** The T-state counts agree with Fuse to within a few frames, once contended memory is counted. And contended memory has a surprise in it this time: the fill that goes down the screen in screen order does not wait for the ULA at all.

The new instructions are `INC L` and `INC H` (one half of HL at a time), `AND n` and `OR n`, the conditional returns `RET NZ`, `RET C` and `RET Z`, and `HALT`. The rest was in steps 4 to 7.

The section "For info: why the screen is in thirds, and interleaved" explains the strange layout of the bitmap: what each bit of a screen address means, how one instruction moves across or down, and why Sinclair's designers laid it out like that. A second short program, `step8-examples.bas`, tries each worked example from that section in Fuse.

Every program here was assembled with pasmo, cross-checked against a second assembler, z80asm, and run in a 48K emulator before it was shown.

## The new instructions and ideas

### Passing values in from BASIC: four parameters this time

As in step 7, BASIC passes its choices in through bytes at the start of the code:

```
pattern: db 170         ; 50000: the pattern, POKEd by BASIC
times:  db 1            ; 50001: how many fills
where:  dw 16384        ; 50002-50003: where to start
slow:   db 0            ; 50004: HALTs per line in rows and sdown
```

| In the code | Reads | In BASIC, to change it |
|-------------|-------|------------------------|
| `ld a,(pattern)` | 50000 | `POKE 50000,170` |
| `ld a,(times)` | 50001 | `POKE 50001,50` |
| `ld hl,(where)` | 50002 and 50003, low byte first | `POKE 50002,0: POKE 50003,64` for 16384; `POKE 50002,0: POKE 50003,128` for 32768 |
| `ld a,(slow)` | 50004 | `POKE 50004,2` for two `HALT`s after each line, `POKE 50004,0` for full speed |

16384 is 64*256+0, and 32768 is 128*256+0. The code starts at 50005.

32768 is the control experiment, like step 7's 60000. It is the first byte of the top 32K, which the ULA never touches, so nothing there is contended. (Step 7's 60000 will not do for the bitmap: 60000 plus 6144 is past the end of memory.) After `CLEAR 49999`, 32768 to 38911 is free: the BASIC program and its variables end a long way below it, and the machine stack is just under 49999, a long way above.

### The loop and LDIR, over 6144 bytes

The first two routines are step 7's, with bigger numbers. The loop loads BC with 6144 and goes round until BC is zero. `LDIR` fills the first byte by hand and copies it along 6143 times, with HL one byte behind DE. Nothing else changes. Step 7 explains both.

The loop is the slowest of the four. Counting to 6144 needs a register pair, and the Z80 has no single instruction that takes one from a pair and tests it for zero, so every byte pays for `dec bc`, `ld a,b`, `or c` and `jr nz`: 39 T-states a byte. The next idea fixes that.

### Two loops, one inside the other: 192 lines of 32

`DJNZ` (step 5) counts B down and loops, in one two-byte instruction, 13 T-states. But B only goes up to 255. So `rows` splits the 6144 bytes into 192 lines of 32: an inner loop of 32 bytes counted by B, and an outer loop of 192 lines counted by C.

```
        ld c,192        ; C = 192 lines to fill
rline:  ld a,(pattern)  ; A = the pattern
        ld b,32         ; B = 32 bytes in a line
rbyte:  ld (hl),a       ; fill one byte
        inc hl          ; next address
        djnz rbyte      ; B-1; not zero: next byte
        call wait       ; HALT if BASIC asked for it
        dec c           ; one fewer line to do
        jr nz,rline     ; not zero: next line
```

It is the same as this BASIC:

```
FOR L=1 TO 192: FOR X=1 TO 32: POKE A,170: LET A=A+1: NEXT X: NEXT L
```

The inner loop is three instructions, 26 T-states a byte, against the plain loop's 39. The outer loop costs a little at the end of each line, but only 192 times.

There is a second reason for working in lines of 32: a line of 32 bytes is one pixel line across the screen. Between lines, the routine can do something else: wait, so we can watch, or work out where the next line is. That is what the fourth routine does.

### INC L and INC H — one half of HL at a time

`inc hl` adds one to the pair HL, 6 T-states. `inc l` adds one to L alone, and `inc h` to H alone, 4 T-states each. They are the same as step 5's `inc a`, on another register.

| Instruction | Bytes (hex) | Bytes (decimal) | T-states |
|-------------|-------------|-----------------|----------|
| `INC L` | `2C` | 44 | 4 |
| `INC H` | `24` | 36 | 4 |
| `INC HL` (step 4) | `23` | 35 | 6 |

The difference is the carry between the halves. `inc hl` on 16639 (`$40FF`) gives 16640 (`$4100`): L goes from 255 to 0 and the one is carried into H. `inc l` on `$40FF` gives `$4000`: L goes round to 0 and H is left alone. `inc h` adds one to H, which adds 256 to HL.

On the screen these are the two moves that matter most. `inc l` goes one byte, eight pixels, to the right. `inc h` goes one pixel line *down*, inside the same character cell. The aside below explains why, and `step8-examples.bas` shows both in Fuse.

`INC L` sets the Z flag when L goes round to 0, like `inc a`. It does not touch the carry.

### AND n and OR n — picking bits out, and putting bits in

`and n` keeps the bits of A that are 1 in n, and clears the rest. `or n` sets the bits of A that are 1 in n, and leaves the rest. Step 7's `or c` was the register form. Both clear the carry and set Z if the answer is 0.

| Instruction | Bytes (hex) | T-states |
|-------------|-------------|----------|
| `AND n` | `E6` n | 7 |
| `OR n` | `F6` n | 7 |
| `ADD A,n` (step 5) | `C6` n | 7 |
| `SUB n` (step 5) | `D6` n | 7 |

Example: `and 7` with A = `01000111` keeps the bottom three bits, `00000111`, which is 7. With A = `01001000` it gives `00000000`, so Z is set. That is how the next-line-down routine asks "which pixel row of the cell am I on?". `or 88` with A = `00000001` sets the bits of 88, `01011000`, and gives `01011001`, 89.

`and a`, which keeps every bit of A, is a quick way to set Z if A is 0. The `wait` routine uses it.

### Conditional returns: RET Z, RET NZ, RET C

Step 5 named them: `ret z` returns only if Z is set, `ret nz` only if it is not, `ret c` only if the carry is set. If the condition is false, the Z80 carries on with the next instruction. They are `IF ... THEN RETURN` in one byte.

| Instruction | Bytes (hex) | T-states |
|-------------|-------------|----------|
| `RET NZ` | `C0` | 11 if it returns, 5 if not |
| `RET Z` | `C8` | 11 if it returns, 5 if not |
| `RET C` | `D8` | 11 if it returns, 5 if not |
| `RET` | `C9` | 10 |

They let a routine finish early on the common case, which keeps it quick. The next-line-down routine returns after four instructions on seven lines out of eight.

### HALT — wait for the next frame

`halt` stops the Z80 until the next interrupt. On the Spectrum the ULA sends one at the start of every frame, 50 times a second, and BASIC leaves the interrupts on, so `halt` waits until the start of the next frame. The ROM's interrupt routine runs (it adds one to `FRAMES` and reads the keyboard), and then the Z80 carries on after the `halt`.

| Instruction | Bytes (hex) | T-states |
|-------------|-------------|----------|
| `HALT` | `76` | 4, then repeated until the interrupt |

That makes it a good way to slow a routine down to a speed we can watch: one `halt` per line is one line a frame. It is also, in Chapter 4, how a game keeps in time with the TV picture.

The `wait` routine does `slow` of them after each line, and none if `slow` is 0:

```
wait:   ld a,(slow)     ; A = HALTs to do
        and a           ; is it 0?
        ret z           ; yes: no waiting
        ld d,a          ; D = HALTs still to do
whalt:  halt            ; wait for the next interrupt
        dec d
        jr nz,whalt
        ret
```

With the interrupts off (the instruction `DI`, which we have not used), `halt` would wait for ever. Our routines never turn them off.

### Going down the screen in screen order

The fourth routine, `sdown`, has the same two loops as `rows`, with two changes:

```
sline:  ld a,(pattern)  ; A = the pattern
        ld b,32         ; B = 32 bytes in a line
        ld e,l          ; E = L at the start of the line
sbyte:  ld (hl),a       ; fill one byte
        inc l           ; one column to the right
        djnz sbyte      ; B-1; not zero: next byte
        ld l,e          ; back to the start of the line
        call nxtdn      ; HL = the start of the line below
```

1. Across the line it uses `inc l`, not `inc hl`. A line of 32 bytes never needs to carry into H, so the cheaper instruction will do: 24 T-states a byte. (On the last line of a character row, L goes from 224 up to 255 and then round to 0 at the end. That does no harm, because the next instruction puts the start of the line back.)
2. At the end of the line, `ld l,e` goes back to the start of the line, and `call nxtdn` moves HL down one pixel line. `nxtdn` is the classic "next line down" routine, explained in the aside below. After 192 lines, the routine has filled every line of the bitmap, from the top of the screen to the bottom.

## For info: why the screen is in thirds, and interleaved

> **For info.** This section is not needed for the fills, which write every byte and do not care about the order. It is what makes drawing in machine code easy, from Chapter 4 on. Every worked example here was checked in Fuse with `step8-examples.bas` (see "Trying the worked examples in Fuse" below).
>
> **The address bits.** Write a bitmap address in binary, as its high byte H and its low byte L:
>
> ```
> H = 0 1 0 T T R R R      L = C C C X X X X X
> ```
>
> - `010` is fixed. It puts the bitmap at `$4000` to `$57FF`, 16384 to 22527.
> - `TT` is the third of the screen: 0 for the top, 1 for the middle, 2 for the bottom.
> - `RRR` is the pixel row inside the character cell, 0 to 7.
> - `CCC` is the character row inside the third, 0 to 7.
> - `XXXXX` is the column, 0 to 31.
>
> So H holds the third and the pixel row, and L holds the character row and the column. Counting up through the addresses changes X fastest, then C, then R, then T. That is the order in which step 2's fill, and this step's loop, `LDIR` and `rows`, visit the screen: across a line, then down a *character* row, eight times, and only then down a pixel row. That is the stripes.
>
> Example: 18501, the address step 2 worked out for the top line of the cell at character row 10, column 5, is `$4845`, `01001000 01000101`. `TT` is 01, the middle third. `RRR` is 000, the top pixel row. `CCC` is 010, row 2 of the middle third, which is row 10 of the screen. `XXXXX` is 00101, column 5.
>
> **Moving across and down with one instruction.**
>
> - `INC L` moves one column to the right: `$4000` (16384) becomes `$4001` (16385).
> - `INC H` moves down one pixel line inside the same cell: `$4000` (16384) becomes `$4100` (16640). Seven `INC H`s from `$4000` reach `$4700` (18176), the bottom line of the top-left cell. That is step 2's `STEP 256` loop, now one instruction per line.
>
> **Crossing into the next character row.** From the bottom line of a cell, `INC H` does not reach the cell below. `$4700` plus one in H is `$4800` (18432), the top of the *middle third*. To go from pixel row 7 of character row 0 to pixel row 0 of character row 1, `RRR` must go back to 0 and `CCC` must go up by one. After the `INC H`, that is: subtract 8 from H (the `INC H` carried out of `RRR` into `TT`; this takes it back) and add 32 to L (one more `CCC`). `$4700` (18176) becomes `$4020` (16416), the top line of character row 1, the address step 2's "Try this" filled.
>
> **Crossing into the next third.** At character row 7 of a third, `CCC` is 111 and L is 224 (`$E0`) or more. Adding 32 to L goes past 255, and the Z80 sets the carry. That carry is the sign that we have left the third. Now the carry that `INC H` made into `TT` is exactly right: `TT` should go up by one, and `RRR` is already 0. So we leave H alone. From the bottom line of row 7, `$47E0` (18400), the next line down is `$4800` (18432), the top of row 8.
>
> **The next-line-down routine.** These three cases together are the classic routine. In: HL is a bitmap address. Out: HL is the address one pixel line lower, in the same column.
>
> ```
> nxtdn:  inc h           ; down one pixel line (RRR + 1)
>         ld a,h
>         and 7           ; still inside the same cell?
>         ret nz          ; yes: done
>         ld a,l
>         add a,32        ; next character row (CCC + 1)
>         ld l,a
>         ret c           ; carry: crossed into the next third, H is right
>         ld a,h
>         sub 8           ; same third: undo the carry into TT
>         ld h,a
>         ret
> ```
>
> `and 7` keeps `RRR`. If it is not 0, the `INC H` stayed inside the cell, which happens on seven lines out of eight, and the routine returns after four instructions, 26 T-states (17 more for the `call`). Otherwise, it adds 32 to L. If that carries, we are in a new third and H is already right. If not, H takes back the 8 that `INC H` carried into `TT`.
>
> Worked through, in Fuse:
>
> | HL in | Case | HL out |
> |-------|------|--------|
> | `$4000` (16384) | inside the cell | `$4100` (16640) |
> | `$4700` (18176) | next character row | `$4020` (16416) |
> | `$47E0` (18400) | next third | `$4800` (18432) |
> | `$4FE0` (20448) | next third | `$5000` (20480), the top of the bottom third |
>
> Called 191 times from 16384, it reaches 22496 (`$57E0`), the bottom line of the screen, the start of the last line `sdown` fills. Once more, and it gives 22528 (`$5800`): the attributes. There is no line below the bottom one, and `nxtdn` does not check.
>
> **The attribute for a bitmap address.** The attribute of a cell is at `22528 + 32 * (character row on the whole screen) + column`. In binary that is:
>
> ```
> attribute:  0 1 0 1 1 0 T T    C C C X X X X X
> bitmap:     0 1 0 T T R R R    C C C X X X X X
> ```
>
> The low byte is the same `CCCXXXXX` as the bitmap's, and the high byte is `$58` (88) plus `TT`. So from any bitmap address in HL, three rotates (step 5's `rrca`) move `TT` down to the bottom two bits, `and 3` keeps them, and `or 88` puts `01011000` on top:
>
> ```
> attr:   ld a,h
>         rrca
>         rrca
>         rrca            ; TT is now in bits 0 and 1
>         and 3           ; keep TT
>         or 88           ; 88 is $58, the attributes' high byte
>         ld h,a          ; L is already CCCXXXXX
>         ret
> ```
>
> Worked through, in Fuse: `$4000` (16384) gives `$5800` (22528); `$4020` (16416) gives `$5820` (22560); `$4800` (18432) gives `$5900` (22784). And step 2's 18501 gives 22853, which is 22528+32*10+5, the attribute of row 10, column 5.
>
> The pixel row does not matter. Any of the eight lines of a cell gives the same attribute, because `rrca` moves `RRR` into the top of A, where `and 3` throws it away.
>
> **Why it is laid out like this: the hardware.** The ULA draws the picture one TV line at a time. For every eight pixels across, it needs two bytes: the bitmap byte and the attribute byte for that cell. The 16K of RAM from 16384 is *dynamic* RAM, and Chris Smith, who reverse-engineered the ULA from the chip itself, describes how the ULA reads it ("The ZX Spectrum Dynamic Memory Control", on his Spectrum Clone Design Blog, zxdesign.info, January 2008). A dynamic RAM chip takes its address in two halves on the same pins: first a *row address*, from the lower address lines, then a *column address*, from the upper ones. The ULA reads in "paged mode": it gives one row address, then two column addresses, one for the bitmap byte and one for its attribute. In his words: "the display byte and its corresponding attribute are stored in different columns of the same row (i.e. the lower address lines (row address) are the same for the display byte and its attribute byte). When the address changes to access the attribute byte, it is only the column address that needs to change." Two bytes for the price of one row address.
>
> So the bitmap byte and the attribute byte of a cell must have the same low address bits. The layout follows from that:
>
> - The attributes are 32 bytes to a row, in order, so the low byte of an attribute address is three bits of character row and five of column, `CCCXXXXX`. Eight character rows fill 256 bytes, and the 24 rows need three lots of 256. That is the three thirds, `TT`.
> - The bitmap byte must have the same low byte, `CCCXXXXX`. So the pixel row, `RRR`, and the third, `TT`, have to go in the high byte. Moving down a pixel line is then adding 256.
> - With a plain top-to-bottom bitmap, 32 bytes to a pixel line, the low byte of line 1 of a cell would be 32 more than line 0's, and only one line in eight could match its attribute's low byte. The page-mode read would not work.
>
> Chris Smith's book *The ZX Spectrum ULA: How to Design a Microcomputer* (2010) gives the full design.
>
> **Why it is laid out like this: the code.** Whatever the designers had in mind, the layout suits the Z80 too. The commonest moves are one-byte, 4 T-state instructions: `INC L` across, `INC H` down a pixel line. Drawing a character, eight bytes one under the other, is eight `INC H`s, with no 16-bit add. Only the move into the next character row or third costs more, once every eight lines. And a bitmap address turns into its attribute address in six instructions, because the two share a low byte. It is often said that this was planned, to make printing characters quick; we have not found that in a reliable source, so take it as a happy result rather than the reason.

### Trying the worked examples in Fuse

`step8-examples.bas` is a small BASIC program that calls the routines with each worked address and prints what comes back, in hex, in binary and in decimal. It uses four short test entry points at the end of the code. Each one reads `where`, does one thing to it, and hands the answer back to `USR` in BC:

| Entry | Does | So `PRINT USR` gives |
|-------|------|----------------------|
| 50155 `tdown` | `call nxtdn` | the address one line down |
| 50164 `tattr` | `call attr` | the attribute address |
| 50173 `tincl` | `inc l` | the address one column right |
| 50180 `tinch` | `inc h` | the address one pixel line down, without the checks |

For example, in BASIC, after the code has loaded:

```
POKE 50002,0: POKE 50003,71: PRINT USR 50155
```

18176 is 71*256+0, `$4700`, and this prints 16416, `$4020`.

The program shows three pages, and you press a key to go from one to the next. The screenshots are `step8-examples-inc.png`, `step8-examples-nxtdn.png` and `step8-examples-attr.png`. On each pair of lines, the first is the address in and the second, marked `>`, is the address out:

```
NEXT LINE DOWN, NXTDN

  $4000 01000000 00000000 16384
> $4100 01000001 00000000 16640

  $4700 01000111 00000000 18176
> $4020 01000000 00100000 16416

  $47E0 01000111 11100000 18400
> $4800 01001000 00000000 18432

  $4FE0 01001111 11100000 20448
> $5000 01010000 00000000 20480
```

Read the binary for the three cases: in the first, only the last bit of H changes. In the second, H goes back to `01000000` and the 1 appears in the top three bits of L. In the third, L goes to 0 and the 1 appears in `TT`.

## Counting time: T-states and frames

The method is step 7's. Each instruction has a T-state count in Zilog's *Z80 CPU User Manual*, a frame is 69888 T-states, and we add up one fill and multiply by 50.

| Routine | Each byte | One fill | 50 fills |
|---------|-----------|----------|----------|
| Loop | `ld (hl),e` 7, `inc hl` 6, `dec bc` 6, `ld a,b` 4, `or c` 4, `jr nz` 12: **39** | 6144×39−5, plus 59 of set-up and outer loop: 239670 | 171.5 frames |
| `LDIR` | **21** | 6143×21−5, plus 109: 129107 | 92.4 frames |
| Rows | `ld (hl),a` 7, `inc hl` 6, `djnz` 13: **26** | 192 lines of 32×26−5, plus 81 a line (`ld a,(pattern)`, `ld b,32`, the `wait` call with `slow` at 0, `dec c`, `jr nz`), plus 60 for the fill: 174391 | 124.8 frames |
| Down | `ld (hl),a` 7, `inc l` 4, `djnz` 13: **24** | 192 lines of 32×24−5, plus 106 a line and `nxtdn`'s 26, 65 or 46, plus 60: 172774 | 123.6 frames |

`nxtdn` takes 26 T-states on the 168 lines where it stays in the cell, 65 on the 21 where it crosses a character row, and 46 on the 3 where it crosses a third (the last of them is the step past the bottom line), plus 17 each time for the `call`, which is in the 106. That is 5871 for a whole screen, about 3 percent of the fill.

For comparison, step 2's BASIC took 2468 frames for 6144 `POKE`s: 2468×69888/6144, about **28000 T-states for each byte**.

The counts already say two things. The loop is the slowest, because of its 16-bit count. And going down the screen in screen order is not slower than going through memory in order. `nxtdn` costs a little at the end of each line, but `inc l` saves 2 T-states on every byte, 64 a line.

### Contended memory again

Step 7 found that the ULA holds the Z80 up when it touches the screen while the picture is being drawn. The wait is 6, 5, 4, 3, 2, 1, 0 or 0 T-states, depending on exactly when the Z80 asks, and the pattern repeats every 8 T-states.

Here only the writes touch the screen (the code is at 50000, and `inc hl` and `djnz` put addresses outside 16384 to 32767 on the bus), except in `LDIR`, which reads and writes the screen and holds a screen address on the bus for another seven T-states. So `LDIR` will wait the most, as in step 7.

The surprise is the fourth routine. Its inner loop is 24 T-states a byte, and 24 is 3 times 8. If one write lands at a point in the pattern where it waits, it is held until a point where the wait is 0. 24 T-states later, the next write lands at the same point in the pattern, and does not wait either. Nor does the one after. The loop has fallen into step with the ULA, so only the first write of a line can wait. The `rows` loop, at 26 T-states, drifts through the pattern, two T-states further on each time, so it keeps landing on the waits, and so does the plain loop, at 39.

`step8-contention.py`, an optional short Python script in this folder, does the count again with the waits put in, by step 7's rules. You do not need it to follow the lesson. It printed:

```
LOOP  32768    171.5 frames  waiting   0.0
LOOP  SCREEN   174.1 frames  waiting   2.7
LDIR  32768     92.4 frames  waiting   0.0
LDIR  SCREEN   117.1 frames  waiting  24.7
ROWS  32768    124.8 frames  waiting   0.0
ROWS  SCREEN   132.2 frames  waiting   7.4
DOWN  32768    123.6 frames  waiting   0.0
DOWN  SCREEN   123.7 frames  waiting   0.1
```

The section "What it showed in Fuse" sets these beside the measurements.

## The listing

The machine code, `step8-bitmap.asm`:

```
; step8-bitmap.asm - Chapter 3, step 8
; The bitmap fill in machine code: the twin of step 2's bitmap fill.
; Four routines that fill 6144 bytes, called from BASIC, and two small
; screen-address routines (next line down, attribute address) with test
; entry points so BASIC can try them.
;
; BASIC passes its choices in through five parameter bytes at the start:
;   50000  pattern  the byte to fill with (step 2 used 170, 10101010)
;   50001  times    how many fills to do, 1 to 255 (0 means 256)
;   50002  where    two bytes, the first address, low byte first
;                   (16384, the bitmap; 6144 bytes from here are filled)
;   50004  slow     HALTs after each line of 32 bytes in rows and sdown,
;                   0 for none (full speed), 1 or more to slow them down
;
; Entry points:
;   RANDOMIZE USR 50005  fill   loop over 6144 bytes, in memory order
;   RANDOMIZE USR 50030  fldir  LDIR, in memory order
;   RANDOMIZE USR 50056  rows   192 lines of 32 bytes, in memory order
;   RANDOMIZE USR 50085  sdown  192 lines of 32 bytes, in screen order,
;                               top to bottom, using nxtdn
;   PRINT USR 50155      tdown  next line down from where, in BC
;   PRINT USR 50164      tattr  attribute address for where, in BC
;   PRINT USR 50173      tincl  where after INC L, in BC
;   PRINT USR 50180      tinch  where after INC H, in BC
;
; Registers in fill:
;   HL = the address being filled
;   BC = bytes still to fill, 6144 down to 0
;   D  = fills still to do
;   E  = the pattern
;   A  = a scratch copy of B, for the zero test
;
; Registers in fldir:
;   HL = the address LDIR copies from (one byte behind DE)
;   DE = the address LDIR copies to
;   BC = bytes still to copy, 6143 down to 0
;   A  = the pattern, then the count of fills (kept on the stack)
;
; Registers in rows and sdown:
;   HL = the address being filled
;   B  = bytes still to fill in this line, 32 down to 0
;   C  = lines still to fill, 192 down to 0
;   D  = HALTs still to do after this line
;   E  = (sdown only) L at the start of the line
;   A  = the pattern, then scratch
;   the count of fills is kept on the stack
;
; nxtdn: in HL = a bitmap address; out HL = the address one pixel line
;   down. A is changed. attr: in HL = a bitmap address; out HL = the
;   address of the attribute for that cell. A is changed.
;
; Build:  pasmo --tap --name bitcode step8-bitmap.asm step8-bitcode.tap
; It is loaded by the drivers, step8-bitmap.bas and step8-examples.bas,
; with LOAD ""CODE.

        org 50000

pattern: db 170         ; 50000: the pattern, POKEd by BASIC
times:  db 1            ; 50001: how many fills
where:  dw 16384        ; 50002-50003: where to start
slow:   db 0            ; 50004: HALTs per line in rows and sdown

; 1. The loop: step 7's loop, with 6144 bytes instead of 768.

fill:   ld a,(times)    ; A = how many fills
        ld d,a          ; D = fills still to do
frep:   ld a,(pattern)  ; A = the pattern BASIC POKEd
        ld e,a          ; E = the pattern, because the loop needs A
        ld hl,(where)   ; HL = first address to fill
        ld bc,6144      ; BC = 6144 bytes to fill
floop:  ld (hl),e       ; fill one byte
        inc hl          ; next address
        dec bc          ; one fewer to do
        ld a,b
        or c            ; Z is set only when BC = 0
        jr nz,floop     ; not zero: next byte
        dec d           ; one fewer fill to do
        jr nz,frep      ; not zero: fill again
        ret

; 2. LDIR: fill the first byte, then copy it along 6143 times.

fldir:  ld a,(times)    ; A = how many fills
lrep:   push af         ; keep the count on the stack
        ld a,(pattern)  ; A = the pattern BASIC POKEd
        ld hl,(where)   ; HL = first address
        ld (hl),a       ; fill the first byte by hand
        ld de,(where)
        inc de          ; DE = the next address, HL+1
        ld bc,6143      ; BC = the other 6143 bytes
        ldir            ; copy (HL) to (DE), HL+1, DE+1, BC-1, until BC = 0
        pop af          ; A = the count again
        dec a           ; one fewer fill to do
        jr nz,lrep      ; not zero: fill again
        ret

; 3. rows: 192 lines of 32 bytes, in memory order. The next line is
;    simply the next address, so this fills in the same order as fill.

rows:   ld a,(times)    ; A = how many fills
rrep:   push af         ; keep the count on the stack
        ld hl,(where)   ; HL = first address
        ld c,192        ; C = 192 lines to fill
rline:  ld a,(pattern)  ; A = the pattern
        ld b,32         ; B = 32 bytes in a line
rbyte:  ld (hl),a       ; fill one byte
        inc hl          ; next address
        djnz rbyte      ; B-1; not zero: next byte
        call wait       ; HALT if BASIC asked for it
        dec c           ; one fewer line to do
        jr nz,rline     ; not zero: next line
        pop af          ; A = the count again
        dec a           ; one fewer fill to do
        jr nz,rrep      ; not zero: fill again
        ret

; 4. sdown: 192 lines of 32 bytes, in screen order, top to bottom.
;    The same as rows, except for how it gets to the next line.

sdown:  ld a,(times)    ; A = how many fills
srep:   push af         ; keep the count on the stack
        ld hl,(where)   ; HL = first address, the top line
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

; wait: HALT slow times (none if slow is 0). Each HALT waits for the
; next interrupt, a fiftieth of a second. Changes A and D.

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

; attr: the attribute address for a bitmap address. In: HL in the
; bitmap. Out: HL = 22528 + 32 * character row + column. Changes A.

attr:   ld a,h
        rrca
        rrca
        rrca            ; TT is now in bits 0 and 1
        and 3           ; keep TT
        or 88           ; 88 is $58, the attributes' high byte
        ld h,a          ; L is already CCCXXXXX
        ret

; Test entries for BASIC: PRINT USR gives back BC.

tdown:  ld hl,(where)   ; HL = the address BASIC POKEd
        call nxtdn
        ld b,h
        ld c,l          ; BC = the answer, for USR
        ret

tattr:  ld hl,(where)   ; HL = the address BASIC POKEd
        call attr
        ld b,h
        ld c,l          ; BC = the answer, for USR
        ret

tincl:  ld hl,(where)   ; HL = the address BASIC POKEd
        inc l           ; one column to the right
        ld b,h
        ld c,l          ; BC = the answer, for USR
        ret

tinch:  ld hl,(where)   ; HL = the address BASIC POKEd
        inc h           ; one pixel line down
        ld b,h
        ld c,l          ; BC = the answer, for USR
        ret

        end
```

pasmo's listing (`pasmo -d`) shows where everything landed. These are lines from it, with the addresses in hex:

```
C350:AA		DEFB of 1 bytes
C351:01		DEFB of 1 bytes
C352:0040	DEFW of 1 words
C354:00		DEFB of 1 bytes
C355:		label fill
C36E:		label fldir
C381:EDB0	LDIR
C388:		label rows
C3A5:		label sdown
C3C7:		label wait
C3D2:		label nxtdn
C3D2:24		INC H
C3D3:7C		LD A, H
C3D4:E607	AND 07
C3D6:C0		RET NZ
C3D7:7D		LD A, L
C3D8:C620	ADD A, 20
C3DA:6F		LD L, A
C3DB:D8		RET C
C3DC:7C		LD A, H
C3DD:D608	SUB 08
C3DF:67		LD H, A
C3E0:C9		RET
C3E1:		label attr
C3EB:		label tdown
C3F4:		label tattr
C3FD:		label tincl
C404:		label tinch
C40A:C9		RET
```

| Label | Hex | Decimal | Called from BASIC as |
|-------|-----|---------|----------------------|
| `fill` | `$C355` | 50005 | `RANDOMIZE USR 50005` |
| `fldir` | `$C36E` | 50030 | `RANDOMIZE USR 50030` |
| `rows` | `$C388` | 50056 | `RANDOMIZE USR 50056` |
| `sdown` | `$C3A5` | 50085 | `RANDOMIZE USR 50085` |
| `nxtdn` | `$C3D2` | 50130 | (called by `sdown` and `tdown`) |
| `attr` | `$C3E1` | 50145 | (called by `tattr`) |
| `tdown` | `$C3EB` | 50155 | `PRINT USR 50155` |
| `tattr` | `$C3F4` | 50164 | `PRINT USR 50164` |
| `tincl` | `$C3FD` | 50173 | `PRINT USR 50173` |
| `tinch` | `$C404` | 50180 | `PRINT USR 50180` |

The whole thing is 187 bytes, 50000 to 50186. `nxtdn` is 15 bytes and `attr` 10. As in step 7, if you add an instruction, everything after it moves, and the BASIC must change to match.

The BASIC driver, `step8-bitmap.bas`:

```
1 REM N=fills in each timed run
2 REM H=FRAMES high byte
3 REM L=FRAMES low byte
4 REM F=frames since FRAMES was zeroed
5 REM A=frames for N loop fills, screen
6 REM B=frames for N LDIR fills, screen
7 REM C=frames for N rows fills, screen
8 REM D=frames for N sdown fills, screen
9 REM P,Q,R,S=the same four, at 32768
10 CLEAR 49999
20 BORDER 0: PAPER 0: INK 7: CLS
30 PRINT "LOADING THE CODE"
40 LOAD ""CODE
50 LET N=50
60 CLS : PRINT "STEP 8: THE BITMAP FILL"
70 PRINT : PRINT "PRESS A KEY FOR EACH FILL": PAUSE 0
80 CLS : POKE 50000,170: POKE 50001,1: POKE 50004,2: RANDOMIZE USR 50056: PAUSE 0
90 CLS : RANDOMIZE USR 50085: PAUSE 0
100 POKE 50004,0: CLS : RANDOMIZE USR 50005: PAUSE 0
110 POKE 50000,85: RANDOMIZE USR 50030: PAUSE 0
120 POKE 50000,170: POKE 50001,N
130 GO SUB 800: RANDOMIZE USR 50005: GO SUB 900: LET A=F
140 GO SUB 800: RANDOMIZE USR 50030: GO SUB 900: LET B=F
150 GO SUB 800: RANDOMIZE USR 50056: GO SUB 900: LET C=F
160 GO SUB 800: RANDOMIZE USR 50085: GO SUB 900: LET D=F
170 POKE 50002,0: POKE 50003,128
180 GO SUB 800: RANDOMIZE USR 50005: GO SUB 900: LET P=F
190 GO SUB 800: RANDOMIZE USR 50030: GO SUB 900: LET Q=F
200 GO SUB 800: RANDOMIZE USR 50056: GO SUB 900: LET R=F
210 GO SUB 800: RANDOMIZE USR 50085: GO SUB 900: LET S=F
220 POKE 50002,0: POKE 50003,64: POKE 50001,1
230 CLS : PRINT N;" FILLS OF 6144 BYTES"
240 PRINT : PRINT "HOW   SCREEN  32768  ONE FILL"
250 PRINT "LOOP  ";A;TAB 14;P;TAB 21;A/N
260 PRINT "LDIR  ";B;TAB 14;Q;TAB 21;B/N
270 PRINT "ROWS  ";C;TAB 14;R;TAB 21;C/N
280 PRINT "DOWN  ";D;TAB 14;S;TAB 21;D/N
290 PRINT : PRINT "STEP 2, BASIC: 2468 FRAMES"
300 PRINT "LOOP IS ";INT (2468*N/A+.5);" TIMES AS FAST"
310 PRINT "LDIR IS ";INT (2468*N/B+.5);" TIMES AS FAST"
320 PRINT "ROWS IS ";INT (2468*N/C+.5);" TIMES AS FAST"
330 PRINT "DOWN IS ";INT (2468*N/D+.5);" TIMES AS FAST"
340 PAUSE 0
350 STOP
800 POKE 23672,0: POKE 23673,0: POKE 23674,0
810 RETURN
900 LET H=PEEK 23673: LET L=PEEK 23672
910 IF PEEK 23673<>H THEN GO TO 900
920 LET F=L+256*H
930 RETURN
```

Lines 800 to 930 are step 2's stopwatch, unchanged.

The examples driver, `step8-examples.bas`:

```
1 REM A=address given to a routine
2 REM R=address the routine gave back
3 REM U=the routine's entry point
4 REM V=number to print, in subroutine 700
5 REM Q=one byte of V, in subroutine 700
6 REM P=place value, 128 down to 1
7 REM D=one binary digit
8 REM I,J=counters
9 REM H$=the hex digits
10 CLEAR 49999
20 BORDER 0: PAPER 0: INK 7: CLS
30 PRINT "LOADING THE CODE"
40 LOAD ""CODE
50 LET H$="0123456789ABCDEF"
60 CLS : PRINT "ONE INSTRUCTION"
70 PRINT : PRINT "INC L, ACROSS ONE COLUMN"
80 LET A=16384: LET U=50173: GO SUB 600
90 PRINT : PRINT "INC H, DOWN ONE PIXEL LINE"
100 LET A=16384: LET U=50180: GO SUB 600
110 PRINT : PRINT "SEVEN INC H"
120 LET A=16384: FOR I=1 TO 7
130 POKE 50002,A-256*INT (A/256): POKE 50003,INT (A/256)
140 LET A=USR 50180: NEXT I
150 PRINT "  ";: LET V=16384: GO SUB 700
160 PRINT "> ";: LET V=A: GO SUB 700
170 PAUSE 0
200 CLS : PRINT "NEXT LINE DOWN, NXTDN"
210 FOR I=1 TO 4: READ A
220 PRINT : LET U=50155: GO SUB 600
230 NEXT I
240 DATA 16384,18176,18400,20448
250 PAUSE 0
300 CLS : PRINT "ATTRIBUTE ADDRESS, ATTR"
310 FOR I=1 TO 3: READ A
320 PRINT : LET U=50164: GO SUB 600
330 NEXT I
340 DATA 16384,16416,18432
350 PRINT : PRINT "191 LINES DOWN FROM 16384"
360 LET A=16384: LET U=50155
370 FOR J=1 TO 191
380 POKE 50002,A-256*INT (A/256): POKE 50003,INT (A/256)
390 LET A=USR U: NEXT J
400 PRINT "> ";: LET V=A: GO SUB 700
410 PRINT : PRINT "AND ONE MORE"
420 GO SUB 600
430 PAUSE 0
440 STOP
600 POKE 50002,A-256*INT (A/256): POKE 50003,INT (A/256)
610 LET R=USR U
620 PRINT "  ";: LET V=A: GO SUB 700
630 PRINT "> ";: LET V=R: GO SUB 700
640 RETURN
700 LET Q=INT (V/256): PRINT "$";H$(INT (Q/16)+1);H$(Q-16*INT (Q/16)+1);
710 LET Q=V-256*INT (V/256): PRINT H$(INT (Q/16)+1);H$(Q-16*INT (Q/16)+1);" ";
720 LET Q=INT (V/256): GO SUB 780: PRINT " ";
730 LET Q=V-256*INT (V/256): GO SUB 780
740 PRINT " ";V
750 RETURN
780 LET P=128
790 FOR J=1 TO 8
800 LET D=INT (Q/P): PRINT D;: LET Q=Q-D*P: LET P=P/2
810 NEXT J
820 RETURN
```

## Side by side

Step 2's bitmap fill was lines 20 to 60:

```
20 GO SUB 800
30 FOR A=16384 TO 22527
40 POKE A,170
50 NEXT A
60 GO SUB 900: LET B=F
```

| Job | Step 2's BASIC | Loop | `LDIR` | Down the screen |
|-----|----------------|------|--------|-----------------|
| The pattern | `170`, written in line 40 | `POKE 50000,170`, read with `ld a,(pattern)`, kept in E | the same, kept in A | the same, read again at the start of each line, kept in A |
| Where to start | `16384` in line 30 | `ld hl,(where)` | `ld hl,(where)`, and `ld de,(where)` / `inc de` | `ld hl,(where)` |
| How many | `TO 22527` | `ld bc,6144` | `ld bc,6143`, after one byte by hand | `ld c,192` lines, `ld b,32` bytes a line |
| Write one byte | `POKE A,170` | `ld (hl),e` | inside `ldir` | `ld (hl),a` |
| Next byte | `NEXT A` adds 1 | `inc hl` | inside `ldir` | `inc l` |
| Next line | (no lines: just the next address) | (the same) | (the same) | `ld l,e` / `call nxtdn` |
| Finished yet? | `NEXT A` compares with 22527 | `dec bc` / `ld a,b` / `or c` / `jr nz` | inside `ldir` | `djnz` for the bytes, `dec c` / `jr nz` for the lines |
| Order on the screen | stripes, a third at a time | stripes | stripes | top to bottom |
| One fill | 2468 frames | 3.56 frames | 2.4 frames | 2.52 frames |

The first three all do what BASIC did: start at 16384 and go up by one until 22527. Only the fourth knows anything about the screen. It is also the first routine in the course that is made of two routines, one calling the other: `sdown` does the filling, and `nxtdn` knows the layout. Chapter 4 can reuse `nxtdn` for drawing as it is.

## Building and running

On Windows, from the course folder:

```
windows-tools\pasmo\pasmo.exe --tap --name bitcode chapter-03-machine-code\step8-bitmap.asm chapter-03-machine-code\step8-bitcode.tap
windows-tools\zmakebas\zmakebas.exe -a 10 -n bitmap -o step8-driver.tap chapter-03-machine-code\step8-bitmap.bas
copy /b step8-driver.tap+chapter-03-machine-code\step8-bitcode.tap chapter-03-machine-code\step8-bitmap.tap
```

And for the examples, with the same code:

```
windows-tools\zmakebas\zmakebas.exe -a 10 -n examples -o step8-exdriver.tap chapter-03-machine-code\step8-examples.bas
copy /b step8-exdriver.tap+chapter-03-machine-code\step8-bitcode.tap chapter-03-machine-code\step8-examples.tap
```

On Linux, the same commands without the folder and the `.exe`, with `cat step8-driver.tap chapter-03-machine-code/step8-bitcode.tap > chapter-03-machine-code/step8-bitmap.tap` (and the same for the examples) to join the tapes. Add `-d` to the pasmo line to see the listing.

Or let the build script do it, and open Fuse as well:

```
windows-tools\build.bat chapter-03-machine-code\step8-bitmap.bas chapter-03-machine-code\step8-bitmap.asm bitmap 10
```

```
windows-tools\build.bat chapter-03-machine-code\step8-examples.bas chapter-03-machine-code\step8-bitmap.asm examples 10
```

On Linux:

```
tools/build.sh chapter-03-machine-code/step8-bitmap.bas chapter-03-machine-code/step8-bitmap.asm bitmap 10
```

```
tools/build.sh chapter-03-machine-code/step8-examples.bas chapter-03-machine-code/step8-bitmap.asm examples 10
```

The build scripts name the code on the tape after the file (`step8-bitm`) instead of `bitcode`, and leave the halves next to the source as `step8-bitmap-driver.tap`, `step8-examples-driver.tap` and `step8-bitmap-code.tap`. The code is the same, byte for byte.

When `step8-bitmap.tap` has loaded, the program runs by itself and waits for a key before each fill:

1. **Rows, slowed down.** Two `HALT`s after each line. The stripes appear as in step 2, but in under 8 seconds instead of 50.
2. **Down the screen, slowed down.** The screen is cleared, and the same pattern comes down from the top, one pixel line at a time, in the same 8 seconds.
3. **The loop, full speed.** The screen is cleared, then filled, too quickly to see.
4. **`LDIR`, full speed,** with 85 (`01010101`). Every pixel swaps.
5. **The timing.** About 22 seconds: 50 fills of each kind on the screen, then 50 of each at 32768, where you cannot see them. Then the table. Press a key to finish.

## What it showed in Fuse

The tapes were loaded in a 48K Fuse.

`step8-bitmap-rows.png` is the slowed `rows` fill, a little over a second in. Only the top third has anything in it: the top four or five pixel lines of each of its eight character rows, with gaps between them, and the middle and bottom thirds are still empty. It is step 2's stripes, faster. A few seconds later the top third is solid and the stripes start again in the middle third.

`step8-bitmap-down.png` is the slowed `sdown` fill, about two and a half seconds in. Everything above a straight edge is filled, everything below is empty, and the edge has just passed the bottom of the top third. No stripes: `nxtdn` takes the lines in the order you see them.

Both slowed fills took **384 frames**, 7.68 seconds, measured with `FRAMES` round one call each. That is 192 lines with two `HALT`s each: nearly all of it is waiting. With `slow` at 1, `sdown` took 192 frames.

`step8-bitmap-result.png` is the table. Three runs gave exactly the same numbers:

```
50 FILLS OF 6144 BYTES

HOW   SCREEN  32768  ONE FILL
LOOP  178     175    3.56
LDIR  120     95     2.4
ROWS  136     127    2.72
DOWN  126     126    2.52

STEP 2, BASIC: 2468 FRAMES
LOOP IS 693 TIMES AS FAST
LDIR IS 1028 TIMES AS FAST
ROWS IS 907 TIMES AS FAST
DOWN IS 979 TIMES AS FAST
```

Set beside the counts, in frames for 50 fills:

| Routine | Count | With contended memory | Fuse |
|---------|------:|----------------------:|-----:|
| Loop, at 32768 | 171.5 | 171.5 | 175 |
| `LDIR`, at 32768 | 92.4 | 92.4 | 95 |
| Rows, at 32768 | 124.8 | 124.8 | 127 |
| Down, at 32768 | 123.6 | 123.6 | 126 |
| Loop, on the screen | 171.5 | 174.1 | 178 |
| `LDIR`, on the screen | 92.4 | 117.1 | 120 |
| Rows, on the screen | 124.8 | 132.2 | 136 |
| Down, on the screen | 123.6 | 123.7 | 126 |

What to notice:

- **At 32768, the count is right.** Fuse is 2 to 4 frames over, as in step 7: the BASIC around the call, and the ROM's interrupt routine, which runs every frame and takes its time out of ours.
- **`LDIR` is still the fastest, and still the one that loses most to the ULA.** 95 frames off the screen, 120 on it: 25 frames of waiting, which the script put at 24.7. In plain memory it is 1.84 times as fast as the loop (175 against 95); on the screen only 1.48 times (178 against 120). Step 7 found the same, 1.83 and 1.47.
- **The fill that goes down the screen in screen order did not wait at all.** 126 frames at 32768 and 126 on the screen. `rows`, which does the same work in memory order with `inc hl`, lost 9 frames (the script said 7.4) and the loop 3 (the script said 2.7). That is the 24 T-states, 3 times 8, keeping `sdown` in step with the ULA.
- **So on the screen, going down in screen order beat going through memory in order.** 126 frames against 136, though it does more work: the screen order costs nothing extra.
- **Against BASIC, between 693 and 1028 times as fast.** One `LDIR` fill takes 2.4 frames, about a twentieth of a second, against step 2's 49.36 seconds.

The examples program printed every value in the aside: the `INC L`, `INC H` and seven-`INC H` results (16385, 16640, 18176), the four `nxtdn` cases (16640, 16416, 18432, 20480), the three attribute addresses (22528, 22560, 22784), 22496 after 191 lines down from 16384, and 22528 after one more.

The bytes were checked with a second assembler: z80asm built `step8-bitmap.asm` to the same 187 bytes as pasmo's `--bin`.

## Line by line

The machine code, `step8-bitmap.asm`, by label:

- **Header.** What the four parameters are, the entry points, what each register holds in each routine, what `nxtdn` and `attr` take and give back, and how to build it.
- **`pattern`, `times`, `where`, `slow`.** The parameter bytes at 50000 to 50004, with starting values 170, 1, 16384 and 0.
- **`fill`, `frep`, `floop`.** Step 7's loop. The only change is `ld bc,6144`.
- **`fldir`, `lrep`.** Step 7's `LDIR` fill. The only change is `ld bc,6143`.
- **`rows`, `rrep`.** Read how many fills, and keep the count on the stack. Load HL with the start, and C with 192 lines.
- **`rline`.** Read the pattern into A and set B to 32 for the bytes of one line.
- **`rbyte`.** Fill a byte, step HL on, and go round 32 times with `djnz`.
- **`call wait` / `dec c` / `jr nz,rline`.** Wait if BASIC asked, then do the next line, 192 times. `pop af` / `dec a` / `jr nz,rrep` repeat the fill.
- **`sdown`, `srep`.** The same start as `rows`.
- **`sline`.** Read the pattern, set B to 32, and keep L in E, to come back to the start of the line.
- **`sbyte`.** Fill a byte, move right with `inc l`, and go round 32 times.
- **`ld l,e` / `call nxtdn`.** Back to the start of the line, then down one pixel line. Then the same `wait`, line count and fill count as `rows`.
- **`wait`, `whalt`.** If `slow` is 0, return at once. Otherwise `halt` `slow` times, counting with D.
- **`nxtdn`.** The next-line-down routine from the aside.
- **`attr`.** The attribute address from the aside.
- **`tdown`, `tattr`, `tincl`, `tinch`.** Load HL from `where`, do one thing, copy HL to BC for `USR`, and return.

The driver, `step8-bitmap.bas`:

- **1–9** name the variables.
- **10–40** move `RAMTOP` to 49999, set the colours, and load the code.
- **50** sets how many fills to time.
- **60–70** print the title and wait for a key.
- **80** clears the screen, pokes the pattern, one fill, and two `HALT`s a line, and calls `rows`.
- **90** clears the screen and calls `sdown`, still slowed.
- **100** sets `slow` back to 0, clears the screen, and calls the loop.
- **110** pokes 85 and calls `LDIR`.
- **120** pokes 170 again, and N into `times`.
- **130–160** time N fills of each kind on the screen, with step 2's stopwatch.
- **170** points `where` at 32768, low byte 0, high byte 128.
- **180–210** time the same four at 32768.
- **220** puts `where` back to 16384 and `times` back to 1.
- **230–280** clear the screen and print the eight times, and the time for one fill on the screen.
- **290–330** set them beside step 2's 2468 frames.
- **340–350** wait for a key, then stop.
- **800–930** step 2's stopwatch subroutines.

The examples, `step8-examples.bas`:

- **1–9** name the variables.
- **10–50** move `RAMTOP`, load the code, and set up the hex digits.
- **60–170** page 1: `tincl` and `tinch` on 16384, then `tinch` seven times, each answer fed back in as the next `where`.
- **200–250** page 2: `tdown` on the four addresses in the `DATA` line.
- **300–340** page 3: `tattr` on the three addresses in the `DATA` line.
- **350–430** `tdown` 191 times from 16384, then once more.
- **600–640** poke A into `where`, call the routine at U, and print the address in and the address out.
- **700–750** print V as `$` and four hex digits, the two bytes in binary, and the decimal.
- **780–820** print the byte Q as eight binary digits, using place values 128, 64, ... 1. Halving is exact on the Spectrum, where `2^J` might not be.

## Limitations you will notice

- **`where` must point somewhere safe.** The loop, `LDIR` and `rows` fill 6144 bytes from `where`, whatever is there. 16384 is the bitmap and 32768 is free memory below the stack.
- **`sdown` and `nxtdn` only understand the screen layout.** `sdown` always fills 192 lines down from `where`, so it only fits the screen if `where` is 16384. `nxtdn` does not check for the bottom: one line below 22496 it gives 22528, and the next `sdown` line would land in the attributes. Started lower, say at 18432, `sdown` would carry on down through the attributes and the system variables, and the machine would probably crash.
- **`nxtdn` works for one address.** It does not care which column it is in, but it moves one line at a time. To draw at pixel row y, you either call it y times from the top, or work out the address from the bits. Chapter 4 will need the second, or a table of the 192 line addresses.
- **One pattern for the whole screen.** Every byte is the same. Step 9 will let you choose it.
- **The timing includes some BASIC,** 2 to 4 frames in each measurement, as in step 7. Over 50 fills that is under 3 percent.
- **`times` goes up to 256** (0 means 256), as in step 7.

## Try this

- Draw a letter with step 2's `STEP 256` idea. Type `FOR P=0 TO 7: POKE 16453+256*P,PEEK (15880+P): NEXT P`. A letter A appears at `AT 2,5`. 15880 is where the ROM keeps the eight bytes of the A (15616, the start of the character set at space, plus 8*33), and 16453 is the top line of the cell at row 2, column 5. Each `+256` is one `INC H`.
- Ask `attr` for step 2's cell. After the program has run, type `POKE 50002,69: POKE 50003,72: PRINT USR 50164`. 18501 is 72*256+69, and the answer is 22853, the attribute of row 10, column 5.
- Speed up the slow fills. Change the 2 in line 80 to 1. The two slowed fills now take about four seconds each instead of eight: one line a frame. Timed with `FRAMES`, `sdown` took 192 frames with 1, and 384 with 2.
- If you have Python, run `python3 step8-contention.py` in this folder. It prints the counted times with and without the waits, the eight lines shown in "Contended memory again".
