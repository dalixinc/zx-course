# Chapter 3, step 4 — The Z80 in small pieces, and a first routine

Steps 2 and 3 filled the screen from BASIC, and it was slow: 325 frames, six and a half seconds, just to fill the 768 attribute bytes. This step writes the first machine code of the course and runs it. By the end, the same attribute fill takes half a frame.

Machine code is the Z80's own language: numbers in memory, which the processor reads and obeys directly, with no interpreter in between. To get there, this step explains what the processor does with those numbers, introduces a few of its registers, and uses ten instructions. It puts three tiny routines into memory at 50000, 27 bytes in all, and calls them from BASIC:

1. A 4-byte routine that hands the number 42 back to BASIC. `PRINT USR 50000` prints 42. It is the first proof that the round trip works: BASIC calls the code, the code runs, and BASIC gets control back.
2. An 8-byte routine that turns the border red, then hands the colour number back to BASIC.
3. A 15-byte routine that fills every attribute byte with yellow paper and black ink, using a loop. The program times it with `FRAMES`.

There is no assembler yet. We work out the bytes by hand, from a table, and the BASIC program `POKE`s them into memory from `DATA`, the same way Chapter 2 poked the UDG ball. Doing it by hand once shows you exactly what an assembler does for you. pasmo, in step 5, does this part for us from then on.

Every program is tested in a 48K emulator before it is shown. The bytes in this lesson were also checked by assembling the same routines with pasmo and comparing them byte for byte.

## What the processor does with bytes

The Z80 in the Spectrum is a small machine that does one job, over and over, about three and a half million clock ticks a second:

1. **Fetch.** Read the byte at the address in the *program counter*, and add one to the program counter.
2. **Decode.** Work out which instruction that byte means. Some instructions need more bytes, a number or an address. If so, fetch those too, adding one to the program counter each time.
3. **Execute.** Do it. Then go back to 1.

The *program counter*, PC for short, is a 16-bit register inside the Z80 that holds the address of the next byte to fetch. Normally it just counts up, so the instructions run in the order they sit in memory. A *jump* instruction puts a new address into PC, and the next fetch comes from there. That is how a loop is made.

The Z80 has no idea which bytes are meant to be code. Whatever is at the address in PC gets fetched and obeyed. BASIC is no help here: when PC points at our code, the BASIC interpreter is not running at all. That is why machine code is fast, and also why a mistake can crash the machine (see "Why a wrong byte can crash the machine" below).

For example, the bytes 1, 42, 0, 201 at 50000 to 50003 are two instructions. The Z80 fetches 1 from 50000 and decodes it as "load the register pair BC with the next two bytes". It fetches 42 and 0 from 50001 and 50002, puts 42 in BC, and PC is now 50003. It fetches 201, which is "return", and that takes it back to BASIC.

## The registers we use

A register is a storage place inside the processor itself. The Z80 can work on registers much faster than on memory, and most instructions use them. This step uses five 8-bit registers, each holding one byte, 0 to 255:

| Register | What we use it for here |
|----------|-------------------------|
| A | The *accumulator*. Arithmetic and logic results go here, and `OUT` sends the byte in A. |
| B, C | General use. Together, BC is our loop counter, and the number that goes back to BASIC. |
| H, L | General use. Together, HL holds an address. |

Some registers work in pairs, as one 16-bit register that holds 0 to 65535: **BC** is B and C, and **HL** is H and L. The first letter is the high byte. So when BC holds 768, B holds 3 and C holds 0, because 768 = 3*256 + 0. There is a third pair, **DE**, which we will meet in step 5.

There is one more register, **F**, the *flags*. Its bits are set or cleared by many instructions to record something about the result. This step needs only one of them:

- **Z**, the zero flag, is set when the result of an instruction was zero, and cleared when it was not.

Later steps will use **C**, the carry flag, which records that an addition went past 255 or a subtraction below 0. (The carry flag C and the register C have the same letter. They are not the same thing.)

The Z80 has more registers than these: DE, IX, IY, SP (the stack pointer), a second set of A to L, and a few others. We will meet them when we need them. One matters already: the ROM keeps IY pointing at the system variables, and its interrupt routine uses IY fifty times a second, so a routine called from BASIC must leave IY alone. None of ours touch it.

## Numbers in decimal and hex

Assemblers and Z80 references usually write bytes in hexadecimal, base 16, with the digits 0 to 9 and A to F. One hex digit is four bits, so one byte is always two hex digits, 00 to FF. In this course a hex number is written with a `$` in front, so `$C9` is 12*16 + 9 = 201. BASIC only understands decimal, so the `DATA` lines are in decimal. The tables below give both.

Two-byte numbers in an instruction go low byte first, the same order as the two-byte system variables in step 1. `LD BC,42` is the bytes `$01 $2A $00`: the instruction, then 42, then 0. `LD HL,22528` is `$21 $00 $58`, because 22528 = `$5800` = 88*256 + 0.

## The new BASIC keywords used here

`CLEAR`, `POKE`, `PEEK`, `FRAMES` and the `FRAMES` subroutines are as in steps 1 and 2, and `READ` and `DATA` are as in Chapter 2. Two things are new: the number form of `USR`, and `RANDOMIZE USR`.

### USR address

`USR address` is a function. It sets PC to `address`, so the Z80 starts running whatever is there. When the routine ends with `RET`, BASIC carries on, and the value of the function is **the number left in the BC register pair**, 0 to 65535. Not A: BC.

Chapter 2 used the other form, `USR "a"`, which only gives the address of a UDG and runs nothing. With a number instead of a letter in quotes, `USR` runs code.

`USR` is a function, so it has to be used inside a statement: `PRINT USR 50000`, `LET X=USR 50000`, and so on. A line that is just `USR 50000` is a syntax error.

```
10 CLEAR 49999
20 POKE 50000,1: POKE 50001,42: POKE 50002,0: POKE 50003,201
30 PRINT USR 50000
40 POKE 50001,210: POKE 50002,4
50 PRINT USR 50000
```

This prints 42, then 1234. Line 20 pokes the four bytes of `LD BC,42` and `RET`. Line 40 changes the number in the instruction to 1234, which is `$04D2`, so the low byte is `$D2` (210) and the high byte is 4.

### RANDOMIZE USR

When a routine does something useful and its answer does not matter, it is usual to call it with `RANDOMIZE USR address`. `RANDOMIZE` runs the routine, and uses the BC it gets back as a seed for `RND`, as in Chapter 2 step 5, which is harmless. Nothing is printed. The fill routine in this program ends with 0 in BC, so `PRINT USR` would print a 0 we do not want.

```
10 CLEAR 49999
20 FOR A=50000 TO 50007: READ B: POKE A,B: NEXT A
30 RANDOMIZE USR 50000
40 DATA 62,2,211,254,6,0,79,201
```

This turns the border red and prints nothing but `0 OK`. The bytes are the border routine from the listing, described below.

## The instructions

Each instruction has a short name, a *mnemonic*, which is what you write, and one or more bytes, which is what the Z80 reads. In the syntax below, `n` is a one-byte number, 0 to 255, and `nn` is a two-byte number, 0 to 65535, written low byte first. `r` means one of the 8-bit registers.

### LD rr,nn — load a register pair with a number

`LD` means *load*: copy a value into a register (or into memory). `LD BC,nn` puts the number `nn` into BC. `LD HL,nn` does the same for HL.

| Instruction | Bytes (hex) | Bytes (decimal) |
|-------------|-------------|-----------------|
| `LD BC,nn` | `01` lo hi | 1, lo, hi |
| `LD HL,nn` | `21` lo hi | 33, lo, hi |

Example: `LD BC,42` is `01 2A 00`, decimal 1, 42, 0. `LD HL,22528` is `21 00 58`, decimal 33, 0, 88.

### LD r,n — load a register with a number

`LD A,n` puts the one-byte number `n` into A. `LD B,n` puts it into B. The same works for C, D, E, H and L, each with its own first byte.

| Instruction | Bytes (hex) | Bytes (decimal) |
|-------------|-------------|-----------------|
| `LD A,n` | `3E` n | 62, n |
| `LD B,n` | `06` n | 6, n |

Example: `LD A,2` is `3E 02`, decimal 62, 2.

### LD r,r — copy one register into another

`LD C,A` copies A into C. A keeps its value. The first register named is always the one that changes. Any of A, B, C, D, E, H and L can be copied into any other, and each combination is one byte.

| Instruction | Bytes (hex) | Bytes (decimal) |
|-------------|-------------|-----------------|
| `LD C,A` | `4F` | 79 |
| `LD A,B` | `78` | 120 |

### LD (HL),n — store a number in memory

Brackets mean "the memory at this address". `LD (HL),n` writes the byte `n` into memory at the address in HL. It is the machine-code `POKE`: `LD HL,22528` then `LD (HL),48` does the same as `POKE 22528,48`.

| Instruction | Bytes (hex) | Bytes (decimal) |
|-------------|-------------|-----------------|
| `LD (HL),n` | `36` n | 54, n |

Example: `LD (HL),48` is `36 30`, decimal 54, 48.

### INC and DEC on a pair

`INC HL` adds one to HL. `DEC BC` takes one from BC. Both work on the full 16 bits, so 255 in L rolls over into H: 22783 (`$58FF`) plus one is 22784 (`$5900`).

| Instruction | Bytes (hex) | Bytes (decimal) |
|-------------|-------------|-----------------|
| `INC HL` | `23` | 35 |
| `DEC BC` | `0B` | 11 |

One trap: `INC` and `DEC` on a register *pair* do not change the flags. When `DEC BC` takes BC down to zero, the zero flag is not set. This catches out everyone once. The next instruction is the usual way round it.

### OR r — combine A with a register, and set the flags

`OR C` combines A with C bit by bit: each bit of the result is 1 if that bit is 1 in A or in C (or both). The result goes back into A, and the flags are set from it. The result is zero only if both A and C were zero.

| Instruction | Bytes (hex) | Bytes (decimal) |
|-------------|-------------|-----------------|
| `OR C` | `B1` | 177 |

This is how we test whether BC has reached zero: `LD A,B` then `OR C`. The zero flag is set if, and only if, B and C are both zero.

### JR NZ,e — jump back if not zero

`JR` is *jump relative*. `JR NZ,e` means: if the zero flag is not set ("not zero"), jump; if it is set, carry on with the next instruction. There is also `JR Z,e`, jump if zero, and a plain `JR e`, which always jumps.

| Instruction | Bytes (hex) | Bytes (decimal) |
|-------------|-------------|-----------------|
| `JR NZ,e` | `20` e | 32, e |
| `JR Z,e` | `28` e | 40, e |
| `JR e` | `18` e | 24, e |

The second byte, `e`, is not an address. It is a distance: how far to move PC, forwards or backwards, from **the address just after the `JR` instruction**. By the time the Z80 has fetched both bytes of the `JR`, PC already points at the next instruction, and the jump is measured from there.

The distance is a signed byte, from -128 to +127. A forward jump of 5 is just 5. A backward jump is written as 256 minus the distance, so a jump back of 8 is 256-8 = 248, `$F8`. Bytes 128 to 255 mean backwards; 0 to 127 mean forwards.

Worked out for the loop in this program: the loop starts at 50018. The `JR NZ` is at 50024 and 50025, so the next instruction is at 50026. The distance is 50018 - 50026 = -8, and the byte is 256-8 = 248.

A routine with relative jumps works wherever you put it in memory, because nothing in it is an address. That will matter later.

### OUT (n),A — send a byte to the hardware

`OUT (n),A` sends the byte in A to the hardware *port* `n`, rather than to memory. On the Spectrum, port 254 is the ULA, the chip that draws the screen and drives the speaker. Bits 0 to 2 of the byte set the border colour, using the usual colour numbers. (Bit 3 is the tape output and bit 4 is the speaker. Our value, 2, has both at 0.)

| Instruction | Bytes (hex) | Bytes (decimal) |
|-------------|-------------|-----------------|
| `OUT (n),A` | `D3` n | 211, n |

Example: `LD A,2` then `OUT (254),A` is `3E 02 D3 FE` and turns the border red.

The border changes, but BASIC is not told. The `BORDER` statement stores its colour in the system variable `BORDCR` (step 1 showed it), and the ROM puts that colour back on the border whenever it next makes a sound on the speaker. In Fuse, the border stayed red until a key was pressed in the editor: the key click put the old colour back.

### RET — return

`RET` takes the address it came from off the machine stack and puts it back in PC. For a routine called by `USR`, that address is in the ROM, so `RET` goes back to BASIC, which then reads BC.

| Instruction | Bytes (hex) | Bytes (decimal) |
|-------------|-------------|-----------------|
| `RET` | `C9` | 201 |

Every routine called from BASIC must end with `RET`. Without one, the Z80 runs straight on into whatever bytes come next.

## Why the code is at 50000

Step 1 explained this. `CLEAR 49999` moves `RAMTOP` down to 49999, so BASIC stays below 50000 and nothing it does, a longer program, more variables, the machine stack, can grow into our bytes. `CLEAR` is the first line of the program, because it also wipes all the variables, so it has to come before anything else happens.

## The routines, hand-assembled

This is the job an assembler does. Each line has the address, the bytes in hex and in decimal, the instruction, and what it does. The addresses follow from the byte counts: each instruction starts where the last one ended.

**Routine 1, at 50000: hand 42 back to BASIC.** 4 bytes.

| Address | Hex | Decimal | Instruction | What it does |
|--------:|-----|---------|-------------|--------------|
| 50000 | `01 2A 00` | 1, 42, 0 | `LD BC,42` | BC = 42 |
| 50003 | `C9` | 201 | `RET` | back to BASIC, which reads BC |

**Routine 2, at 50004: red border, and hand the colour back.** 8 bytes.

| Address | Hex | Decimal | Instruction | What it does |
|--------:|-----|---------|-------------|--------------|
| 50004 | `3E 02` | 62, 2 | `LD A,2` | A = 2, red |
| 50006 | `D3 FE` | 211, 254 | `OUT (254),A` | the border turns red |
| 50008 | `06 00` | 6, 0 | `LD B,0` | B = 0 |
| 50010 | `4F` | 79 | `LD C,A` | C = A, so BC = 2 |
| 50011 | `C9` | 201 | `RET` | back to BASIC |

`LD B,0` and `LD C,A` are there because `USR` hands back BC, not A. Without them, BASIC would print whatever happened to be in BC.

**Routine 3, at 50012: fill the attributes.** 15 bytes.

| Address | Hex | Decimal | Instruction | What it does |
|--------:|-----|---------|-------------|--------------|
| 50012 | `21 00 58` | 33, 0, 88 | `LD HL,22528` | HL = first attribute byte |
| 50015 | `01 00 03` | 1, 0, 3 | `LD BC,768` | BC = how many bytes to fill |
| 50018 | `36 30` | 54, 48 | `LD (HL),48` | loop: poke 48 at HL |
| 50020 | `23` | 35 | `INC HL` | next address |
| 50021 | `0B` | 11 | `DEC BC` | one fewer to do |
| 50022 | `78` | 120 | `LD A,B` | A = B |
| 50023 | `B1` | 177 | `OR C` | A = B or C; Z set if BC = 0 |
| 50024 | `20 F8` | 32, 248 | `JR NZ,-8` | not zero: back to 50018 |
| 50026 | `C9` | 201 | `RET` | back to BASIC |

48 is `8*6+0`: paper 6 (yellow), ink 0 (black), not bright, not flashing. It is the same loop as step 2's `FOR A=22528 TO 23295: POKE A,14: NEXT A`, written out in the Z80's own steps: HL is `A`, BC counts the bytes left, and the `JR NZ` is the `NEXT`.

The `RET` at 50026, on its own, is also useful: `RANDOMIZE USR 50026` calls a routine that does nothing at all. The program uses it to measure how long BASIC takes just to make a call.

The same three routines in assembler source, the way step 5 will write them for pasmo:

```
        org 50000
ret42:  ld bc,42
        ret
border: ld a,2
        out (254),a
        ld b,0
        ld c,a
        ret
fill:   ld hl,22528
        ld bc,768
loop:   ld (hl),48
        inc hl
        dec bc
        ld a,b
        or c
        jr nz,loop
        ret
```

Assembled with pasmo, this gives the same 27 bytes as the tables above: `01 2A 00 C9 3E 02 D3 FE 06 00 4F C9 21 00 58 01 00 03 36 30 23 0B 78 B1 20 F8 C9`. pasmo worked out the -8 in the `JR` from the label `loop`, which is one of the jobs an assembler takes off you.

## A checksum before we jump

Typing 27 numbers into `DATA` lines is easy to get wrong, and a wrong byte in machine code is not a polite error message. So the program adds up the bytes as it pokes them, and compares the total with the right answer, 2110, before it calls anything. If the total is different, it says so and stops, and the routines are never run.

With the 248 in line 1020 mistyped as 247, the program printed `SUM IS 2109, NOT 2110` and `CHECK THE DATA LINES`, and stopped.

A simple sum catches any single wrong byte. It does not catch two bytes typed the wrong way round, or two mistakes that happen to cancel out. That is good enough for 27 bytes.

## Why a wrong byte can crash the machine

BASIC checks everything: a bad `POKE` address gives an error report, and the BREAK key stops a program. Machine code has none of that. The Z80 obeys whatever bytes it is given, and BASIC is not running while it does.

Some examples, for the fill routine:

- **A wrong number in an instruction.** `LD HL,2528` instead of 22528 writes 768 bytes into the ROM area, which does nothing, because the ROM cannot be written. But `LD HL,23552`, a slip of one digit, writes 48 over the system variables and the start of the BASIC program, and the Spectrum is likely to crash, or behave very strangely afterwards.
- **A wrong opcode.** Every byte from 0 to 255 means something to the Z80. A mistyped instruction byte is not rejected; it runs as a different instruction, and the bytes after it may then be taken for instructions too.
- **A wrong jump distance.** If the 248 were 247, the jump would land one byte early, in the middle of an instruction, and the Z80 would carry on from there, decoding the bytes in a way they were never meant to be read.
- **A missing `RET`, or a loop that never ends.** If BC never reached zero, the loop would run for ever. BREAK does nothing, because it is BASIC that checks for it. The only way out is to reset the machine, and the program in memory is lost.

On a real Spectrum a crash means pulling the plug. In Fuse it means Machine, Reset (or F5), and loading the tape again. Either way, the program you typed is gone, which is the best reason to `SAVE` it before you try it.

## The listing

```
1 REM A=address being poked
2 REM B=byte read from DATA
3 REM S=sum of the bytes, the checksum
4 REM K=loop counter
5 REM H=FRAMES high byte
6 REM L=FRAMES low byte
7 REM F=frames since FRAMES was zeroed
8 REM G=frames for 100 fills
9 REM E=frames for 100 empty calls
10 CLEAR 49999
20 BORDER 0: PAPER 0: INK 7: CLS
30 LET S=0
40 FOR A=50000 TO 50026
50 READ B: POKE A,B: LET S=S+B
60 NEXT A
70 IF S<>2110 THEN PRINT "SUM IS ";S;", NOT 2110": PRINT "CHECK THE DATA LINES": STOP
80 PRINT "27 BYTES AT 50000, SUM ";S
90 PRINT : PRINT "USR 50000 GIVES ";USR 50000
100 PRINT "USR 50004 GIVES ";USR 50004
110 PRINT : PRINT "PRESS A KEY TO FILL": PAUSE 0
120 RANDOMIZE USR 50012
130 GO SUB 800: FOR K=1 TO 100: RANDOMIZE USR 50012: NEXT K: GO SUB 900: LET G=F
140 GO SUB 800: FOR K=1 TO 100: RANDOMIZE USR 50026: NEXT K: GO SUB 900: LET E=F
150 PRINT AT 8,0;"100 FILLS       ";G;" FRAMES"
160 PRINT "100 EMPTY CALLS ";E;" FRAMES"
170 PRINT "ONE FILL        ";(G-E)/100;" FRAMES"
180 PAUSE 0
190 STOP
800 POKE 23672,0: POKE 23673,0: POKE 23674,0
810 RETURN
900 LET H=PEEK 23673: LET L=PEEK 23672
910 IF PEEK 23673<>H THEN GO TO 900
920 LET F=L+256*H
930 RETURN
1000 DATA 1,42,0,201
1010 DATA 62,2,211,254,6,0,79,201
1020 DATA 33,0,88,1,0,3,54,48,35,11,120,177,32,248,201
```

The source is `step4-first-routine.bas`. A tape image ready to load is `step4-first-routine.tap`.

## What it showed in Fuse

The program was run four times in a 48K Fuse at normal speed, loaded from the tape above. The 100 fills took 96 frames every time. The 100 empty calls took 46 frames three times and 47 once, so one fill came out at 0.5 frames three times and 0.49 once.

`step4-first-routine.png` is the screen before the fill. The checksum came out at 2110, `USR 50000` gave 42, `USR 50004` gave 2, and the border was red.

`step4-first-routine-result.png` is the end. The whole screen turned yellow at once, the moment the key was pressed, with the earlier text now black on yellow. The times are printed in white on black, because `PRINT` uses the colours set in line 20.

| What | Frames |
|------|-------:|
| 100 calls of the fill, `RANDOMIZE USR 50012` | 96 |
| 100 calls of the empty routine, `RANDOMIZE USR 50026` | 46 |
| One fill, (96-46)/100 | 0.5 |

Half a frame is 10 milliseconds. Step 2 filled the same 768 bytes from BASIC in 325 frames, so the machine code is about 650 times as fast. Against step 3's 489 frames, it is nearly a thousand times.

One fill is too quick to time on its own: `FRAMES` only counts whole fiftieths of a second, and a single fill would read 0 or 1. So the program times 100 fills, and takes off the time of 100 calls that do nothing, which is BASIC's own cost of the `FOR` loop and the `RANDOMIZE USR`. That cost is about 0.46 of a frame a call, almost as long as the fill itself. Once the code is fast, BASIC calling it becomes the slow part.

Pressing a key after the times appeared stopped the program with `9 STOP statement, 190:1`. The border was still red. It went back to black, the colour from `BORDER 0` in line 20, only when a key was pressed in the editor, as described under `OUT` above. In the short `RANDOMIZE USR` example, which never sets a border, it went back to white.

## Line by line

- **1–9** name the variables.
- **10** moves `RAMTOP` to 49999, so 50000 upwards is ours. It comes first because `CLEAR` wipes the variables.
- **20** sets black border and paper, white ink, and clears the screen.
- **30–60** read the 27 bytes from the `DATA` at 1000 to 1020, poke them into 50000 to 50026, and add each one to `S`.
- **70** checks the sum. If it is not 2110, a byte is wrong, so the program says so and stops before any machine code runs.
- **80** prints the sum.
- **90** calls routine 1. `USR 50000` runs `LD BC,42` and `RET`, and `PRINT` shows the 42 that came back in BC.
- **100** calls routine 2. The border turns red, and `PRINT` shows the 2 that came back in BC.
- **110** waits for a key.
- **120** calls routine 3, the fill, once, so you see the screen change. `RANDOMIZE` throws the result away.
- **130** zeroes `FRAMES`, calls the fill 100 times, and keeps the time in `G`.
- **140** does the same with the empty routine at 50026, the single `RET`, and keeps the time in `E`.
- **150–170** print the two times, and the time of one fill. The fill also coloured the bottom two rows, but these lines print higher up, from row 8.
- **180** waits for a key, so the report does not clear the bottom of the screen at once.
- **190** stops, so the program does not run on into the subroutines.
- **800–810** set `FRAMES` to zero, low byte first, as in step 2.
- **900–930** read `FRAMES` safely into `F`, as in step 2.
- **1000** routine 1: `LD BC,42`, `RET`.
- **1010** routine 2: `LD A,2`, `OUT (254),A`, `LD B,0`, `LD C,A`, `RET`.
- **1020** routine 3: `LD HL,22528`, `LD BC,768`, then the loop `LD (HL),48`, `INC HL`, `DEC BC`, `LD A,B`, `OR C`, `JR NZ,-8`, and `RET`.

## Limitations you will notice

Hand assembly is slow and easy to get wrong. Every instruction has to be looked up in a table, every two-byte number split into a low and a high byte, and every jump distance counted out by hand. Add one instruction inside the loop, and the jump distance changes, and so does the address of every routine after it, and every `USR` that calls them. Twenty-seven bytes are manageable. The routines in Chapter 4 will be hundreds of bytes long.

The numbers in `DATA` say nothing about what they do. `33,0,88` means `LD HL,22528` only if you have the table beside you. The comments are in this lesson, not in the program.

The colour, 48, and the border colour, 2, are fixed inside the code. To change them you have to poke a different byte into the right address (50019 for the fill colour, 50005 for the border). Step 7 passes the colour in from BASIC instead.

The fill loop is the slow way to do it in machine code. Six instructions go round 768 times. The Z80 has a single instruction, `LDIR`, that copies a block of memory, and step 7 uses it.

Step 5 introduces pasmo, which takes the assembler source shown above, works out the bytes, the addresses and the jump distances for us, and writes a tape that loads them. It does the same 27 bytes, with the comments kept in the source where they belong.

## Try this

- Change the 42 in line 1000 to another number up to 255, and change 2110 in line 70 by the same amount. Then try a number over 255: split it into a low byte and a high byte, and put both in.
- Change the 2 in line 1010 to another colour, 0 to 7. The border changes colour, and `USR 50004` prints the new number. Remember to change the checksum.
- Change the 48 in line 1020 to another attribute, `8*paper+ink`, plus 64 for bright. Then change the 3 in `LD BC,768` (the high byte) to 2: BC is 512, and only the top two-thirds of the screen is filled. In Fuse, with the checksum changed to 2109, one fill then measured 0.33 frames.
- After the program has stopped, type `PRINT PEEK 50024, PEEK 50025` and see the `JR NZ` and its distance, 32 and 248.
- Change the 248 in line 1020 to 247 and run it. The checksum stops the program before the bad code runs.
