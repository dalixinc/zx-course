# Chapter 3, step 6 — The system variables, from machine code

Step 1 was a memory map explorer in BASIC. It `PEEK`ed the system variables and printed where BASIC had put things. This step does the same job in machine code. It is the first of the twins: from here to step 9, each BASIC program from steps 1 to 3 is written again in Z80, in the same order, so the two can be set side by side.

The program reads the same twelve system variables as step 1: `PROG`, `VARS`, `E LINE`, `STKEND`, `RAMTOP`, `UDG`, `P RAMT`, `CHARS`, `ATTR P`, `BORDCR`, `FRAMES` and `LAST K`. It prints them with the ROM's own print routine, in the same places on the screen as step 1. It works out the free memory, and then shows `FRAMES` ticking and `LAST K` changing until you press ENTER.

It also times itself. It reads `FRAMES` at the start and again when the table is done, and prints the difference. A BASIC version that prints exactly the same screen, `step6-basic.bas`, times itself the same way, so the two figures can be compared.

There are three things to compare:

1. **The output.** It is the same. The figures that do not depend on the program, such as `PROG`, `RAMTOP`, `UDG` and `CHARS`, are the same as step 1's. The ones that do depend on it, such as `VARS` and `STKEND`, move, and the lesson explains why.
2. **How it is put together.** BASIC has line numbers, `READ` and `DATA`, and `PRINT` with `AT` and `TAB`. The machine code has labels, a table of addresses in memory, a loop that walks along the table, and two small subroutines: one prints a string and one prints a number.
3. **The time.** The machine code took 12 frames and the BASIC took 35, so it is about three times as fast. That is a long way short of step 4's 650 times, and the reason is worth knowing: both versions spend most of their time in the same ROM routine, drawing characters.

The new instructions are few: `LD rr,(nn)`, `LD (nn),HL`, `LD A,(DE)`, `RST 16`, `SBC HL,DE`, `ADD HL,DE`, `AND A` to clear the carry, and `CALL` to an address in the ROM. Everything else was in step 5.

Every program here was assembled with pasmo, cross-checked against a second assembler, z80asm, and run in a 48K emulator before it was shown.

## The ROM routines we borrow

The ROM is 16K of machine code: the BASIC interpreter and everything it needs, including the routines that print characters and numbers and clear the screen. They sit at fixed addresses, and a routine of ours can `CALL` them as BASIC does.

The addresses and what the routines do were checked in *The Complete Spectrum ROM Disassembly* by Ian Logan and Frank O'Hara (Melbourne House, 1983), using the SkoolKit edition online at speccy.xyz/rom. They were also checked against the bytes of the 48K ROM file that Fuse runs: the first bytes at each address are the instructions the disassembly lists there.

| Call | Hex | Name in the disassembly | What it does | What it needs |
|------|-----|------------------------|--------------|---------------|
| `rst 16` | `$0010` | PRINT-A-1 | Prints the character in A on the current channel. | A = the character code. |
| `call 5633` | `$1601` | CHAN-OPEN | Makes a stream's channel the current one. | A = the stream. 2 is the upper screen. |
| `call 3435` | `$0D6B` | CLS | Clears the screen in the `ATTR P` colours, and the bottom two lines in the `BORDCR` colours. | Nothing. It leaves channel K (the lower screen) open. |
| `call 11563` | `$2D2B` | STACK-BC | Puts the number in BC on the calculator stack. | BC = 0 to 65535. |
| `call 11747` | `$2DE3` | PRINT-FP | Prints the number on top of the calculator stack, the way `PRINT` does, and takes it off. | A number on the calculator stack. |
| `call 6683` | `$1A1B` | OUT-NUM-1 | Prints BC. It is the routine that prints line numbers in reports such as `0 OK, 40:1`. | BC = 0 to 9999 only. |

Two of these need care:

- **`rst 16` keeps BC, DE and HL.** In the disassembly, PRINT-A-2 at `$15F2`, where `rst 16` goes, starts with `EXX` and ends with `EXX`. `EXX` swaps BC, DE and HL with a second set of registers, so the printing works in the second set and ours are not touched. A and the flags are changed. So a loop can print with `rst 16` and keep its counter in B.
- **`CLS` leaves the wrong channel open.** The last thing CLS does is open channel K, the two lines at the bottom. So we call CLS first, then open channel 2.

The ROM's other routines use IY to find the system variables, so IY must still hold 23610 when we call them. As in step 5, we leave IY alone.

## The new instructions and ideas

In the syntax lines, `rr` is a register pair, `n` a one-byte number, and `nn` a two-byte number or address. The examples are in `step6-examples.asm`, example n at 50000+100*n as in step 5, and `step6-examples.bas` calls them all. What each one showed in Fuse is given with it.

### LD rr,(nn) — read a two-byte system variable

Step 5 showed `ld hl,(nn)` in a table. It reads two bytes: L from the address `nn`, and H from the address after it. It is the Z80's `PEEK nn+256*PEEK (nn+1)`, low byte first, done in one instruction.

| Form | Bytes | Like BASIC |
|------|-------|------------|
| `ld hl,(nn)` | `2A` low high | `LET HL=PEEK nn+256*PEEK (nn+1)` |
| `ld de,(nn)` | `ED 5B` low high | the same, into DE |
| `ld bc,(nn)` | `ED 4B` low high | the same, into BC |

All three do the same job. The HL form is one byte shorter and a little quicker, because HL is the Z80's main address register; the others need the extra `ED` byte in front. No flags change.

Example 1, at 50100:

```
ex1:    ld hl,(23730)   ; HL = RAMTOP, low byte from 23730, high from 23731
        ld b,h
        ld c,l          ; BC = HL, for USR
        ret
```

`PRINT USR 50100` printed **49999**, the `RAMTOP` that the loader's `CLEAR 49999` set.

There is a small bonus here. Step 1 said that reading `FRAMES` with separate `PEEK`s is not quite safe, because the counter can tick between one `PEEK` and the next. The Z80 only takes an interrupt between instructions, never in the middle of one. So `ld hl,(23672)` gets both low bytes of `FRAMES` from the same moment.

### LD (nn),HL — keep a two-byte number in memory

`ld (nn),hl` is the other way round: L goes to `nn`, H to `nn+1`. It is how the program keeps the start time until the end:

```
start:  ld hl,(23672)   ; HL = FRAMES, the low two bytes
        ld (t0),hl      ; keep it: the start time
        ...
t0:     dw 0            ; FRAMES at the start
```

`dw` (*define word*) is like `db`, but each number takes two bytes, low byte first. `dw 0` makes room for one two-byte number, and `dw 23635,23730` puts two addresses into memory.

### LD A,(nn) — read a one-byte system variable

Step 5 had `ld a,(nn)` too. Only A can be loaded from a fixed address like this.

Example 2, at 50200:

```
ex2:    ld a,(23693)    ; A = ATTR P
        ld c,a
        ld b,0          ; BC = A
        ret
```

`PRINT USR 50200` printed **7**, the driver's `PAPER 0: INK 7`.

`ld (nn),a` writes a byte the same way. The program uses it on three system variables that the manual says are safe to change: `ATTR P` and `BORDCR`, to set the colours as step 1's `BORDER 0: PAPER 0: INK 7` does, and `LAST K`, to clear it.

### LD A,(DE), and walking a table with LD E,(HL) / INC HL

Step 1 kept its names and addresses in `DATA`, and read them with `READ N$,A` in a `FOR` loop. The machine-code version keeps them in a table in memory, and walks along it with HL, a byte at a time.

| Form | Like BASIC |
|------|------------|
| `ld e,(hl)` | `LET E=PEEK HL` |
| `ld d,(hl)` | `LET D=PEEK HL` |
| `ld a,(de)` | `LET A=PEEK DE` |
| `inc hl` | `LET HL=HL+1` |

Any register can be loaded from `(HL)`, as step 5 showed. Only A can be loaded from `(DE)` or `(BC)`.

Example 9, at 50900, has a table of three addresses and prints the value at each:

```
ex9:    ld a,2
        call 5633
        ld hl,tab9      ; HL = the start of the table
        ld b,3          ; B = 3 entries
loop9:  ld e,(hl)       ; E = the low byte of an address
        inc hl
        ld d,(hl)       ; DE = the address of a system variable
        inc hl          ; HL = the next entry
        push hl         ; keep the place in the table
        ld a,(de)       ; A = PEEK DE
        ld l,a
        inc de
        ld a,(de)       ; A = PEEK (DE+1)
        ld h,a          ; HL = the value
        call pnum
        ld a,' '
        rst 16
        pop hl
        djnz loop9
        ret
tab9:   dw 23635,23730,23675    ; PROG, RAMTOP, UDG
```

It printed **23755 49999 65368**: `PROG`, `RAMTOP` and `UDG`.

Why not `ld hl,(nn)` here? Because the address changes each time round the loop. `ld hl,(23635)` has the address built into the instruction. When the address comes from a table, it has to be in a register first, here DE, and read with `ld a,(de)`, one byte at a time. That is the price of a loop. The main program uses both: the loop for the table, and `ld hl,(nn)` and `ld a,(nn)` for the variables it reads only once.

HL is needed for two things at once here: the place in the table, and the number to print. `push hl` keeps the first one while HL does the second, and `pop hl` brings it back for the next time round.

### RST 16 and channel 2 — print a character

`rst 16` prints the character whose code is in A. `RST` (*restart*) is a one-byte `CALL` to one of eight fixed addresses near the start of the ROM: 0, 8, 16, 24 and so on up to 56. The ROM's designers put the routines BASIC uses most often there, so that each call takes one byte instead of three.

The ROM prints on the *current channel*. Channel 2 is the upper screen, where `PRINT` goes. When our code starts, we cannot be sure which channel is open: the ROM's CLS, for one, leaves channel K, the lower screen, open. So every routine that prints opens channel 2 first:

```
        ld a,2
        call 5633       ; CHAN-OPEN: channel 2, the upper screen
```

This is the Z80's `PRINT #2;`.

Example 3, at 50300:

```
ex3:    ld a,2
        call 5633       ; CHAN-OPEN: channel 2, the upper screen
        ld a,'H'
        rst 16          ; print the character in A
        ld a,'I'
        rst 16
        ret
```

The driver ran `PRINT "3 RST 16    ";: RANDOMIZE USR 50300` and the screen showed **HI** straight after the label. The print position is a system variable too, so our code carried on where BASIC's `PRINT` had stopped.

`'H'` in quotes is the character code of H, 72. pasmo works it out, the same as `CODE "H"` in BASIC.

### Control codes: AT, TAB and INVERSE are just characters

In BASIC, `AT`, `TAB` and `INVERSE` are part of the `PRINT` statement. Inside the ROM they are characters with codes below 32, sent to the print routine like any other:

| Codes | Means |
|-------|-------|
| 22, row, column | `AT row,column` |
| 23, column, 0 | `TAB column` (two bytes: the column, then 0) |
| 20, 1 and 20, 0 | `INVERSE 1` and `INVERSE 0` |
| 16, n and 17, n | `INK n` and `PAPER n` |

So a string in memory can hold its own position and colours:

```
fixed:  db 22,0,0,20,1," 48K MEMORY MAP EXPLORER        ",20,0
```

is step 1's `PRINT AT 0,0; INVERSE 1;" 48K MEMORY MAP EXPLORER        "`, and the `20,0` at the end turns `INVERSE` off again. In BASIC that happens by itself at the end of the `PRINT`; in machine code we do it.

Our strings end with the byte 255. Many programs use 0 as the end marker, but 0 turns up inside our strings: `AT 7,0` is 22,7,0 and `TAB 7` is 23,7,0. 255 is the code of the keyword `COPY`, which we never print.

The routine that prints a string is short:

```
pstr:   ld a,(hl)       ; A = the next byte of the string
        inc hl
        cp 255          ; the end marker?
        ret z           ; yes: done
        rst 16          ; no: print it
        jr pstr
```

When it returns, HL points just past the 255. The main loop uses that: after it prints a row's name, HL is pointing at the address that follows it in the table.

Example 7, at 50700, prints `db 20,1,"INVERSE",20,0," NORMAL",255`. The screen showed **INVERSE** in black on white, then **NORMAL** in white on black.

### CALL to the ROM

`call nn` was in step 5, calling our own subroutines. Calling the ROM is the same instruction, with a ROM address. The routine runs and its `ret` comes back to us. The only difference is that we did not write it, so we need to know what it expects and what it changes, and the disassembly is where that is written down. The table at the top of this lesson has the six we use.

### Printing a number: three ways

`rst 16` prints one character. A number such as 23755 has to be turned into five characters first. There are three ways to do it, and the examples try all three.

**OUT-NUM-1, at 6683.** It prints BC. Example 5 printed 1234, then 12345, then 49999, and the screen showed **1234 <345 0**. The disassembly says why: "Any value over 9,999 will not however be printed correctly." It counts thousands with a single digit, so twelve thousands become the character after 9, which is `<`. And if bit 7 of B is set, as it is for 49999, it prints 0, which is how a report shows the line number of a command typed in directly. It is no good for addresses.

**STACK-BC and PRINT-FP, at 11563 and 11747.** STACK-BC turns BC into a number on the calculator stack, and PRINT-FP prints it as `PRINT` would:

```
ex4:    ld a,2
        call 5633
        ld bc,(23730)   ; BC = RAMTOP
        call 11563      ; STACK-BC: put BC on the calculator stack
        call 11747      ; PRINT-FP: print the number on top of it
        ret
```

It printed **49999**. It works for every number 0 to 65535, and it is two lines. But it changes all the registers, and it goes through the ROM's floating-point calculator, which is built for numbers like 3.14159 and is slow for whole numbers.

**Our own routine, `pnum`.** About 30 lines, and it prints HL. Example 8 printed **65367 0 7**: a big number, a zero, and a small number with no leading zeros.

The examples timed the two that work. Each printed 65367 a hundred times at `AT 21,26`, and example 12 did the `AT` alone a hundred times, to take away:

| Example | 100 times | Frames |
|---------|-----------|-------:|
| 10 | `AT` and `pnum` | 17 |
| 11 | `AT`, STACK-BC and PRINT-FP | 52 |
| 12 | `AT` only | 3 |

Take away the 3, and `pnum` took 14 frames for 100 numbers, about 2.8 ms each. The ROM took 49, about 9.8 ms each. `pnum` is three and a half times as fast, it keeps BC and DE, and you can see how it works. That is why the program uses it. BASIC's `PRINT` of a number goes through PRINT-FP, which is part of why the BASIC twin is slower.

### SBC HL,DE and ADD HL,DE — 16-bit arithmetic

Step 5's `add a,b` and `sub b` work on one byte. HL has its own add and subtract for two-byte numbers:

| Form | Bytes | Does |
|------|-------|------|
| `add hl,de` | `19` | HL = HL+DE. Carry is set if the answer went over 65535. |
| `sbc hl,de` | `ED 52` | HL = HL-DE-carry. Carry is set if the answer went below 0. Z is set if it is 0. |

The Z80 has no plain 16-bit `sub`. `sbc` is *subtract with carry*: it also takes away the carry flag, 0 or 1, which is how bigger numbers are subtracted in pieces. For a plain subtraction, the carry has to be 0 first. `and a` does that: it ANDs A with itself, which leaves A as it was and always clears the carry. (`AND` itself, as a way to pick out bits, comes in a later step.)

Example 6, at 50600, works out the free memory, as step 1's `T-S` did:

```
ex6:    ld hl,(23730)   ; HL = RAMTOP
        ld de,(23653)   ; DE = STKEND
        and a           ; clear the carry flag first
        sbc hl,de       ; HL = HL-DE
        ld b,h
        ld c,l
        ret
```

`PRINT USR 50600` printed 25039 on the run in the screenshot, and 25057 on an earlier run. The figure depends on how much the driver has on the go when it calls. That is the same point step 1 made: `STKEND` moves with every number BASIC is working on.

### How pnum works

`pnum` prints HL in decimal. It finds the digits the way you would with a pile of coins and no division: take away 10000 as many times as you can, and count how many times. That count is the first digit. Then do the same with 1000, 100 and 10. What is left is the units.

```
digit:  ld a,'0'-1      ; A = one less than the code for "0"
dloop:  inc a           ; one more DE goes in
        and a           ; clear the carry flag
        sbc hl,de       ; HL = HL-DE; carry set if it went below 0
        jr nc,dloop     ; no carry: try again
        add hl,de       ; one too many: put it back
```

A counts in character codes, so that it is ready to print: `'0'-1` is 47, and the first `inc a` makes it 48, the code for 0. For 49999 and DE = 10000, the subtraction works four times (39999, 29999, 19999, 9999), and A goes up to `'4'`. The fifth time it goes below 0 and sets the carry, so the loop stops with A still `'4'`, and `add hl,de` puts the last 10000 back: HL is 9999. The next three calls give `'9'` each, and the units are 9.

The rest of `digit` leaves out leading zeros:

```
        cp '0'          ; is the digit 0?
        jr nz,show      ; no: print it
        inc b
        dec b           ; Z is set if B is 0
        ret z           ; a leading zero: print nothing
show:   ld b,1          ; from now on, print every digit
        rst 16
        ret
```

B starts at 0 and becomes 1 at the first digit printed. A 0 is printed only once B is 1, so 1005 comes out as 1005 and 7 as 7, not 00007. `inc b` then `dec b` leaves B as it was, but `dec` sets Z if the result is 0, as step 5 showed, so it is a quick way to ask "is B 0?" without touching A. The units are always printed, so 0 comes out as 0.

`pnum` starts with `push bc` and `push de` and ends with `pop de` and `pop bc`, so the caller gets BC and DE back unchanged. The main loop depends on that: B is its row counter and DE holds the address it is reading.

## The listing

The source is `step6-sysvars.asm`.

```
; step6-sysvars.asm - Chapter 3, step 6
; The system variables, read from machine code: the twin of step 1.
; It prints the same table as step 1 (after CLEAR 49999), with the
; ROM's print routine, and times itself with FRAMES.
;
; Registers:
;   A  = the character to print (RST 16); a one-byte system variable
;   B  = rows of the table still to print (row loop, with DJNZ);
;        in pnum, 0 until the first digit has been printed
;   DE = the address of a system variable (row loop);
;        a power of ten, 10000 down to 10 (pnum);
;        STKEND, or the start time (for the subtractions)
;   HL = where we are in a string or in the table (pstr, row loop);
;        the number to print (pnum)
;   IY is left alone: the ROM needs it, and so does BASIC.
;
; Build:  pasmo --tapbas --name sysvars step6-sysvars.asm step6-sysvars.tap
; The loader does CLEAR 49999, loads the code to 50000 and runs it.
; Press ENTER to go back to BASIC.

        org 50000

start:  ld hl,(23672)   ; HL = FRAMES, the low two bytes
        ld (t0),hl      ; keep it: the start time

        ld a,0
        out (254),a     ; BORDER 0
        ld a,7
        ld (23693),a    ; ATTR P = 7: PAPER 0, INK 7
        ld (23624),a    ; BORDCR = 7: border 0, lower screen ink 7
        call 3435       ; the ROM's CLS
        ld a,2
        call 5633       ; open channel 2, the upper screen

        ld hl,fixed     ; the title, the fixed map, the heading
        call pstr

        ld hl,table     ; HL = the first row of the table
        ld b,7          ; B = 7 rows
row:    call pstr       ; AT row,0; name; TAB 7 - HL moves past it
        ld e,(hl)       ; E = low byte of the address
        inc hl
        ld d,(hl)       ; D = high byte: DE = the system variable
        inc hl          ; HL = the next row of the table
        push hl         ; keep the place in the table
        ld h,d
        ld l,e          ; HL = DE, the address
        call pnum       ; print the address
        ld hl,tab14
        call pstr       ; TAB 14
        ld a,(de)       ; A = PEEK DE, the low byte
        ld l,a
        inc de
        ld a,(de)       ; A = PEEK (DE+1), the high byte
        ld h,a          ; HL = the two-byte value
        call pnum       ; print the value
        pop hl          ; HL = the next row of the table
        djnz row        ; B = B-1; round again until all 7 are done

        ld hl,free
        call pstr       ; AT 14,0;"FREE";TAB 14
        ld hl,(23730)   ; HL = RAMTOP
        ld de,(23653)   ; DE = STKEND
        and a           ; clear the carry flag
        sbc hl,de       ; HL = RAMTOP-STKEND
        call pnum

        ld hl,chars
        call pstr       ; AT 20,0;"CHARS "
        ld hl,(23606)   ; HL = CHARS, two bytes
        call pnum
        ld hl,attrp
        call pstr       ; "  ATTR P "
        ld a,(23693)    ; A = ATTR P, one byte
        ld l,a
        ld h,0          ; HL = A
        call pnum
        ld hl,bordcr
        call pstr       ; "  BORDCR "
        ld a,(23624)    ; A = BORDCR, one byte
        ld l,a
        ld h,0
        call pnum

        ld hl,(23672)   ; HL = FRAMES now
        ld de,(t0)      ; DE = FRAMES at the start
        and a
        sbc hl,de       ; HL = frames taken so far
        push hl         ; pstr needs HL
        ld hl,took
        call pstr       ; AT 16,0;"TABLE TOOK "
        pop hl
        call pnum
        ld hl,frms
        call pstr       ; " FRAMES"

        ld a,0
        ld (23560),a    ; LAST K = 0, so the ENTER that started us is gone
live:   ld hl,frames
        call pstr       ; AT 21,0;"FRAMES "
        ld hl,(23672)   ; FRAMES, read in one instruction
        call pnum
        ld hl,lastk
        call pstr       ; "  LAST K "
        ld a,(23560)    ; A = LAST K
        ld l,a
        ld h,0
        call pnum
        ld hl,spaces
        call pstr       ; "   ", to wipe out old digits
        ld a,(23560)
        cp 13           ; was the last key ENTER?
        jr nz,live      ; no: go round again
        ret             ; yes: back to BASIC

; pstr - print a string, ending with the byte 255
; In:  HL = the address of the string
; Out: HL = the address just after the 255
; Uses A. The string can hold control codes: 22,row,col is AT,
; 23,col,0 is TAB, 20,1 and 20,0 are INVERSE 1 and INVERSE 0.
pstr:   ld a,(hl)       ; A = the next byte of the string
        inc hl
        cp 255          ; the end marker?
        ret z           ; yes: done
        rst 16          ; no: print it
        jr pstr

; pnum - print HL in decimal, with no leading zeros
; In:  HL = the number, 0 to 65535
; Uses A and HL. BC and DE are saved and given back.
pnum:   push bc
        push de
        ld b,0          ; B = 0: no digit printed yet
        ld de,10000
        call digit      ; the ten thousands
        ld de,1000
        call digit      ; the thousands
        ld de,100
        call digit      ; the hundreds
        ld de,10
        call digit      ; the tens
        ld a,l          ; what is left is 0 to 9, the units
        add a,'0'       ; turn it into a character code
        rst 16          ; always print the units, even 0
        pop de
        pop bc
        ret

; digit - print how many times DE goes into HL, and leave the rest in HL
; In:  HL = the number, DE = a power of ten, B = 0 if no digit yet
; Out: HL = HL minus that many DE, B = 1 if a digit was printed
digit:  ld a,'0'-1      ; A = one less than the code for "0"
dloop:  inc a           ; one more DE goes in
        and a           ; clear the carry flag
        sbc hl,de       ; HL = HL-DE; carry set if it went below 0
        jr nc,dloop     ; no carry: try again
        add hl,de       ; one too many: put it back
        cp '0'          ; is the digit 0?
        jr nz,show      ; no: print it
        inc b
        dec b           ; Z is set if B is 0
        ret z           ; a leading zero: print nothing
show:   ld b,1          ; from now on, print every digit
        rst 16
        ret

; The data. 22 = AT, 23 = TAB, 20 = INVERSE, 255 = the end.

t0:     dw 0            ; FRAMES at the start

fixed:  db 22,0,0,20,1," 48K MEMORY MAP EXPLORER        ",20,0
        db 22,1,0,"0-16383     ROM"
        db 22,2,0,"16384-22527 SCREEN BITMAP"
        db 22,3,0,"22528-23295 ATTRIBUTES"
        db 22,4,0,"23296-23551 PRINTER BUFFER"
        db 22,5,0,"23552-23733 SYSTEM VARIABLES"
        db 22,6,0,20,1,"NAME   AT     VALUE             ",20,0,255

; One row: AT row,0; the name; TAB 7; then the address of the variable.
table:  db 22,7,0,"PROG",23,7,0,255
        dw 23635
        db 22,8,0,"VARS",23,7,0,255
        dw 23627
        db 22,9,0,"E LINE",23,7,0,255
        dw 23641
        db 22,10,0,"STKEND",23,7,0,255
        dw 23653
        db 22,11,0,"RAMTOP",23,7,0,255
        dw 23730
        db 22,12,0,"UDG",23,7,0,255
        dw 23675
        db 22,13,0,"P RAMT",23,7,0,255
        dw 23732

tab14:  db 23,14,0,255
free:   db 22,14,0,"FREE",23,14,0,255
chars:  db 22,20,0,"CHARS ",255
attrp:  db "  ATTR P ",255
bordcr: db "  BORDCR ",255
took:   db 22,16,0,"TABLE TOOK ",255
frms:   db " FRAMES",255
frames: db 22,21,0,"FRAMES ",255
lastk:  db "  LAST K ",255
spaces: db "   ",255

        end start
```

It is 665 bytes, from 50000 to 50664: 264 bytes of instructions, and 401 of strings and table. The BASIC twin below is 1438 bytes of program.

## The BASIC twin

`step6-basic.bas` prints the same screen with step 1's own statements: lines 40 to 160 here are step 1's lines 800 to 860 and 40 to 130 (with one heading, `VALUE`, instead of `BEFORE` and `AFTER`), and line 180 is step 1's line 390. The bars, the "before" column and the second `CLEAR` are left out, because the machine code does not draw them. It starts with `CLEAR 49999`, as the machine code's loader does, so `RAMTOP` is the same in both.

```
1 REM N$=name of a system variable
2 REM A=address of the system variable
3 REM I=table row 0-6
4 REM V=two-byte value read with PEEK
5 REM S=FRAMES at the start
6 REM E=frames the table took
10 CLEAR 49999
20 LET S=PEEK 23672+256*PEEK 23673
30 BORDER 0: PAPER 0: INK 7: CLS
40 PRINT AT 0,0; INVERSE 1;" 48K MEMORY MAP EXPLORER        "
50 PRINT AT 1,0;"0-16383     ROM"
60 PRINT AT 2,0;"16384-22527 SCREEN BITMAP"
70 PRINT AT 3,0;"22528-23295 ATTRIBUTES"
80 PRINT AT 4,0;"23296-23551 PRINTER BUFFER"
90 PRINT AT 5,0;"23552-23733 SYSTEM VARIABLES"
100 PRINT AT 6,0; INVERSE 1;"NAME   AT     VALUE             "
110 RESTORE 900
120 FOR I=0 TO 6
130 READ N$,A
140 LET V=PEEK A+256*PEEK (A+1)
150 PRINT AT 7+I,0;N$;TAB 7;A;TAB 14;V
160 NEXT I
170 PRINT AT 14,0;"FREE";TAB 14;PEEK 23730+256*PEEK 23731-PEEK 23653-256*PEEK 23654
180 PRINT AT 20,0;"CHARS ";PEEK 23606+256*PEEK 23607;"  ATTR P ";PEEK 23693;"  BORDCR ";PEEK 23624
190 LET E=PEEK 23672+256*PEEK 23673-S
200 PRINT AT 16,0;"TABLE TOOK ";E;" FRAMES"
210 POKE 23560,0
220 PRINT AT 21,0;"FRAMES ";PEEK 23672+256*PEEK 23673;"  LAST K ";PEEK 23560;"   "
230 IF PEEK 23560<>13 THEN GO TO 220
240 STOP
900 DATA "PROG",23635,"VARS",23627,"E LINE",23641
910 DATA "STKEND",23653,"RAMTOP",23730,"UDG",23675
920 DATA "P RAMT",23732
```

## Side by side

| Job | Step 1's BASIC | Step 6's machine code |
|-----|----------------|-----------------------|
| Find a line or a routine | Line numbers. `GO SUB 800`, `GO TO 400`. | Labels. `call pstr`, `jr nz,live`. pasmo turns them into addresses. |
| The colours | `BORDER 0: PAPER 0: INK 7: CLS` | `out (254),a`, `ld (23693),a`, `ld (23624),a`, `call 3435` |
| Text and positions | `PRINT AT 0,0; INVERSE 1;"..."` | One string in memory with its control codes, `db 22,0,0,20,1,"...",20,0`, printed by `pstr`. |
| The list of variables | `DATA "PROG",23635,...`, read with `READ N$,A` | A table, `table:`, with the name, `TAB 7` and the address in each row, walked with HL. |
| The loop | `FOR I=0 TO 6` ... `NEXT I` | `ld b,7` ... `djnz row` |
| Read a two-byte variable | `PEEK A+256*PEEK (A+1)` | `ld a,(de)` / `inc de` / `ld a,(de)` in the loop; `ld hl,(nn)` elsewhere. |
| Read a one-byte variable | `PEEK 23693` | `ld a,(23693)` |
| Free memory | `T-S`, from two variables | `ld hl,(23730)` / `ld de,(23653)` / `and a` / `sbc hl,de` |
| Print a number | `PRINT ...;V` (the ROM's PRINT-FP) | `call pnum`, our own |
| Repeat until a key | `IF PEEK 23560<>13 THEN GO TO 220` | `ld a,(23560)` / `cp 13` / `jr nz,live` |

The shape is the same: set up the screen, print the fixed text, loop over a table, print a few more, then loop on `FRAMES` and `LAST K`. The machine code has to spell out what BASIC does for you: open the channel, turn `INVERSE` off again, turn a number into digits, keep the place in the table while HL is busy.

## Building and running

On Windows, from the course folder:

```
windows-tools\pasmo\pasmo.exe --tapbas --name sysvars chapter-03-machine-code\step6-sysvars.asm chapter-03-machine-code\step6-sysvars.tap
windows-tools\zmakebas\zmakebas.exe -a 10 -n basic6 -o chapter-03-machine-code\step6-basic.tap chapter-03-machine-code\step6-basic.bas
```

The examples are a BASIC driver joined to the code, as in step 5:

```
windows-tools\pasmo\pasmo.exe --tap --name excode chapter-03-machine-code\step6-examples.asm chapter-03-machine-code\step6-excode.tap
windows-tools\zmakebas\zmakebas.exe -a 10 -n examples -o step6-driver.tap chapter-03-machine-code\step6-examples.bas
copy /b step6-driver.tap+chapter-03-machine-code\step6-excode.tap chapter-03-machine-code\step6-examples.tap
```

On Linux, the same commands without the folder and the `.exe`, and `cat step6-driver.tap chapter-03-machine-code/step6-excode.tap > chapter-03-machine-code/step6-examples.tap` for the last one.

Or let the build script do it, and open Fuse as well:

```
windows-tools\build.bat chapter-03-machine-code\step6-sysvars.asm
windows-tools\build.bat chapter-03-machine-code\step6-basic.bas basic6 10
windows-tools\build.bat chapter-03-machine-code\step6-examples.bas chapter-03-machine-code\step6-examples.asm examples 10
```

On Linux, `tools/build.sh` with the same arguments and `/` in the paths. The build scripts name the code on the tape after the file (`step6-sysv`, `step6-exam`) instead of `sysvars` and `excode`. That name, and the header checksum that goes with it, is the only difference from the tapes in the repository; the code is the same, byte for byte.

When `step6-sysvars.tap` has loaded, the program runs by itself. Press keys to watch `LAST K` change, and ENTER to go back to BASIC.

## What it showed in Fuse

Each tape was loaded in a 48K Fuse.

`step6-sysvars.png` is the machine-code screen, after pressing `c`. `step6-basic.png` is the BASIC twin's screen, after the same key. Here are both, beside step 1's figures after its `CLEAR 49999`:

| Name | Step 1, after `CLEAR` | Step 6, machine code | Step 6, BASIC twin |
|------|----------------------:|---------------------:|-------------------:|
| `PROG` | 23755 | 23755 | 23755 |
| `VARS` | 26448 | 23826 | 25193 |
| `E LINE` | 26544 | 23827 | 25240 |
| `STKEND` | 26549 | 23832 | 25245 |
| `RAMTOP` | 49999 | 49999 | 49999 |
| `UDG` | 65368 | 65368 | 65368 |
| `P RAMT` | 65535 | 65535 | 65535 |
| Free | 23450 | 26167 | 24749 |
| `CHARS` | 15360 | 15360 | 15360 |
| `ATTR P` | 7 | 7 | 7 |
| `BORDCR` | 7 | 7 | 7 |
| `LAST K` after `c` | 99 | 99 | 99 |
| Table took | | 12 frames | 35 frames |

What to notice:

- **The fixed figures agree.** `PROG`, `RAMTOP`, `UDG`, `P RAMT`, `CHARS`, `ATTR P`, `BORDCR` and `LAST K` are the same in all three columns.
- **`VARS` is lower, because the BASIC program is shorter.** Under the machine code, the only BASIC program is pasmo's four-line loader. `VARS`−`PROG` is 71 bytes, the length of the loader. In step 1 it was 2693, and in the BASIC twin 1438. The machine code is not in the BASIC program at all; it is above `RAMTOP`.
- **`E LINE` is `VARS`+1.** The loader makes no variables, so the variables area is just its end marker, one byte. The BASIC twin's variables (`S`, `N$`, `A`, `I`, `V`) take 47 bytes.
- **The free memory adds up in the machine code**: 49999−23832 = 26167. In the BASIC twin it is 5 bytes short: 49999−25245 is 24754, but it printed 24749. Line 170 works the sum out in one expression. While it reads `STKEND`, the first half of the sum, `RAMTOP`, is waiting on the calculator stack, and a number there takes five bytes. So `STKEND` is five higher than when line 140 read it. In BASIC, the act of measuring moves what you measure. The machine code keeps its numbers in registers, so nothing moves.
- **`FRAMES` ticked** at 50 a second in both, and `LAST K` showed 0 until a key was pressed, then 99 for `c`, then 13 for ENTER, which ended the program: `0 OK, 40:1` from the machine code (the loader's line 40) and `9 STOP statement, 240:1` from the BASIC.

To check the machine code's figures against BASIC on the same machine, `PRINT PEEK 23627+256*PEEK 23628;" ";PEEK 23641+256*PEEK 23642;" ";PEEK 23653+256*PEEK 23654` was typed after it returned. It printed **23826 23827 23945**: `VARS` and `E LINE` the same, and `STKEND` higher, because the line just typed, and the numbers it was working on, were in the workspace by then.

### The time

The machine code took **12 frames** (0.24 s) to clear the screen and print the table, on each of three separate runs. The BASIC twin took **35 frames** (0.7 s). So machine code is about three times as fast here.

That is a small gain beside step 4's 650 times, and the examples show why. Example 13 timed ten calls of the ROM's CLS: **31 frames**, so one CLS is about 3 frames. Example 10 showed that `pnum` takes about 2.8 ms a number, and by the Z80 manual's instruction timings most of that is `rst 16` drawing five characters, eight bytes each, not the subtractions. So of the 12 frames, about 3 are the CLS and most of the rest is the ROM drawing about 350 characters. Our own work, reading the system variables and finding the digits, is a small part of it: the Z80 manual gives 16 T-states for `ld hl,(nn)`, under 5 millionths of a second.

BASIC uses the same CLS and the same character drawing. It spends the rest of its 35 frames finding its lines, reading the `DATA`, working out each `PEEK` sum in floating point, and turning numbers into digits with PRINT-FP. So the lesson is: machine code is fast at what it does itself, but a call to the ROM is only as fast as the ROM. Steps 7 and 8 write to the screen memory directly, with no ROM in the way, and the difference will be much bigger.

`step6-examples.png` is the examples driver's screen. It showed:

```
STEP 6: EXAMPLE, RESULT
1 RAMTOP    49999
2 ATTR P    7
3 RST 16    HI
4 PRINT-FP  49999
5 OUT-NUM-1 1234 <345 0
6 FREE      25039
7 PSTR      INVERSE NORMAL
8 PNUM      65367 0 7
9 TABLE     23755 49999 65368
10 100 PNUM    17 FRAMES
11 100 ROM     52 FRAMES
12 100 AT ONLY 3 FRAMES
13 10 CLS      31 FRAMES
```

with `INVERSE` in inverse, the last of the hundred 65367s at the bottom right, and `9 STOP statement, 230:1`.

Both source files were assembled with z80asm as well as pasmo, and the bytes were the same. z80asm does not fill the gaps between `org`s the way pasmo's `--bin` does, so for the examples each later `org` was changed to `ds` (which fills with zeros) for the z80asm run; with that, the 1363 bytes were identical.

## Line by line

The machine code, `step6-sysvars.asm`, by label:

- **Header.** What each register holds, how to build it, and how to leave.
- **`start`, the first two lines.** Read the low two bytes of `FRAMES` and keep them in `t0`.
- **The next seven lines.** Step 1's `BORDER 0: PAPER 0: INK 7: CLS`. `out (254),a` with A = 0 makes the border black. `ATTR P` = 7 is paper 0, ink 7, which CLS uses for the screen. `BORDCR` = 7 is border 0, with ink 7 for the lower screen. Then the ROM's CLS, and channel 2 opened again after it.
- **`ld hl,fixed` / `call pstr`.** Print the title, the five lines of the map and the table heading, all from one string.
- **`ld hl,table` / `ld b,7`.** HL points at the first row of the table, and B counts the seven rows.
- **`row`.** Print the row's string: `AT`, the name and `TAB 7`. HL now points at the address in the row. Load it into DE, a byte at a time, and step HL on to the next row. Keep HL on the stack. Copy DE into HL and print it: the address. Print `TAB 14`. Read the two bytes at DE into L and H, and print them: the value. Take the table pointer back off the stack, and `djnz` round again until B is 0.
- **`free`.** `RAMTOP`−`STKEND`, with `and a` / `sbc hl,de`, printed after `AT 14,0;"FREE";TAB 14`.
- **`chars`, `attrp`, `bordcr`.** Step 1's line 390: one two-byte read with `ld hl,(nn)`, two one-byte reads with `ld a,(nn)`. A one-byte value goes into L, with H set to 0, so `pnum` can print it.
- **The time.** Read `FRAMES` again, take away `t0`, and print the difference at `AT 16,0`. `push hl` keeps the answer while HL points at the string.
- **`ld (23560),a` with A = 0.** Clear `LAST K`. The tape loader was started with ENTER, so `LAST K` holds 13, which would end the next loop at once.
- **`live`.** Step 1's lines 400 to 420: print `FRAMES` and `LAST K` at `AT 21,0`, then three spaces to wipe out any old digits when `LAST K` gets shorter. Read `LAST K` again, and go round until it is 13, ENTER. Then `ret` to BASIC.
- **`pstr`.** Print bytes from HL until the 255.
- **`pnum` and `digit`.** Print HL in decimal, as explained above.
- **The data.** `t0`, the fixed text, the seven table rows (each one a string, then a `dw` with the address), and the short strings for the rest. The numbers in the strings are control codes: 22 is `AT`, 23 is `TAB`, 20 is `INVERSE`, and 255 marks the end.
- **`end start`.** The loader calls `start`, at 50000, with `RANDOMIZE USR 50000`.

The BASIC twin, `step6-basic.bas`:

- **1–6** name the variables.
- **10** moves `RAMTOP` to 49999, as the machine code's loader does.
- **20** reads the low two bytes of `FRAMES`: the start time.
- **30** sets the colours and clears the screen.
- **40–100** print the title, the map and the heading.
- **110–160** read the seven names and addresses and print each one with its value, as step 1's lines 40 to 130.
- **170** prints the free memory, `RAMTOP`−`STKEND`, read and worked out in one go.
- **180** prints `CHARS`, `ATTR P` and `BORDCR`, as step 1's line 390.
- **190–200** read `FRAMES` again and print how long the table took.
- **210** clears `LAST K`, for the same reason as the machine code.
- **220–230** print `FRAMES` and `LAST K` until `LAST K` is 13.
- **240** stops, so the program does not run into the `DATA`.
- **900–920** the names and addresses.

The examples driver, `step6-examples.bas`:

- **1–5** name the variables.
- **10–40** move `RAMTOP`, set the colours, and load the code to 50000.
- **50** times example 13, ten CLS, before anything is on the screen to lose.
- **60** clears the screen and prints the heading.
- **70–150** call examples 1 to 9. The ones that hand back a number are called with `PRINT USR`. The ones that print are called with `RANDOMIZE USR` straight after a `PRINT` that ends in `;`, so their output follows the label, and the `PRINT` after them ends the line.
- **160–180** time examples 10, 11 and 12, each with `FRAMES` read before and after.
- **190–220** print the four times. The `AT 10,0` is needed, because the timed examples left the print position on line 21, and printing on from there would scroll the screen.
- **230** stops.

## Limitations you will notice

- **`FRAMES` is shown to two bytes.** Both versions print the low two bytes of `FRAMES`, so the figure goes back to 0 after 65535 frames, 21 minutes and 50 seconds after the Spectrum was switched on. Step 1 added the third byte. The machine code could read it with `ld a,(23674)`, but `pnum` only prints up to 65535, and a 24-bit printer is more than this step needs. The timing uses the difference, which is right as long as the table takes less than 21 minutes.
- **`pnum` prints 0 to 65535 only.** No minus sign and no decimal point. For addresses and system variables, that is all we need.
- **The speed is the ROM's.** Clearing the screen and drawing characters take almost all the time, and they are the same ROM routines BASIC uses. Writing our own character printer would be faster, and is not worth it for a table that is printed once.
- **Our strings cannot hold a 255.** It is the end marker. That rules out printing the keyword `COPY`, which no program in this course prints.
- **The ROM needs its system variables.** `rst 16`, CLS and the rest only work while IY holds 23610 and the system variables are sensible. A routine that changes IY, or writes over the system variables, can no longer print.
- **Some system variables change as you look.** As step 1 said, `E LINE` and `STKEND` move with every variable and every number BASIC is working on. The machine code's figures are BASIC's state at the moment `RANDOMIZE USR` was called.

## Try this

- Add a row for `SEED`, at 23670, the seed for `RND` from Chapter 2 step 5. Add `db 22,15,0,"SEED",23,7,0,255` and `dw 23670` after the `P RAMT` row in the table, and change `ld b,7` to `ld b,8`. Row 15 showed `SEED 23670 0` after a fresh start, because nothing had used `RANDOMIZE` yet, and the table took 13 frames. Then press ENTER to go back to BASIC, type `RANDOMIZE 1234`, and `RANDOMIZE USR 50000`: it showed 1234.
- Run both tapes and press different keys. `LAST K` is the character code: `c` gave 99, `A` (with Caps Shift) gave 65, and ENTER gives 13 and ends the program.
- After the machine code has returned, type `RANDOMIZE USR 50000` to run it again. It still took 12 frames. `PROG`, `VARS` and `E LINE` were the same, but `STKEND` was 10 higher, 23842, and the free memory 10 lower, because now the line you typed is in the edit area, and the 50000 it is working on is on the calculator stack.
