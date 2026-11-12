# Chapter 3, step 5 — pasmo, and the Z80 basics

Step 4 worked out 27 bytes by hand: look up each instruction, split every number into a low and a high byte, count out the jump distance. It is worth doing once. From now on, an assembler does it for us.

An *assembler* is a program that reads a text file of instructions, the *source*, and writes the bytes. The course uses **pasmo**. It runs on a PC, not on the Spectrum, and with one option it writes a `.tap` file with a BASIC loader already on it, ready for `LOAD ""` in Fuse.

This step does two things:

1. **pasmo.** Step 4's three routines are typed in as source, assembled, and loaded. The same 27 bytes come out. We read pasmo's listing, look at the loader it writes, and see how tapes are joined.
2. **The Z80 basics.** A short tour of the registers and the instructions the rest of the chapter needs. Each idea has one tiny routine, at most six instructions. All sixteen are in one source file, and a BASIC program calls each one and prints what came back, so every result in this lesson can be checked on the screen.

This is not the whole instruction set. It is enough to read and write the fills in steps 7 to 9, and nothing is used later that is not explained first.

Every program here was assembled with pasmo, cross-checked against a second assembler, z80asm, and run in a 48K emulator before it was shown.

## Where pasmo is, and how to run it

The Windows build is in the repository, in `windows-tools\pasmo\pasmo.exe`. Open a Command Prompt in the folder you cloned the course into (the one with `README.md` in it). Every command in this lesson is run from there.

```
windows-tools\pasmo\pasmo.exe
```

With no file names, it prints its version and a usage line. The Windows build is version 0.5.4 beta 2. The tapes in this lesson were built with 0.5.3 on Linux, and checked again with 0.5.4 beta 2 built from its official source: both versions wrote exactly the same tapes, loader and all.

On Linux, the same commands work without the folder and the `.exe`: `pasmo --tapbas ...`.

## A source file

This is step 4's three routines, as pasmo source. It is `step5-routines.asm`.

```
; step5-routines.asm - Chapter 3, step 5
; Step 4's three routines, written for pasmo instead of by hand.
;
; Registers:
;   A  = border colour (border); a scratch copy of B (fill)
;   BC = the number handed back to BASIC (ret42, border);
;        bytes still to fill (fill)
;   HL = the attribute address being filled (fill)
;
; Build:  pasmo --tapbas --name routines step5-routines.asm step5-routines.tap
; Then in BASIC: PRINT USR 50000 gives 42, PRINT USR 50004 gives 2,
; RANDOMIZE USR 50012 fills the attributes yellow.

        org 50000

ret42:  ld bc,42        ; BC = 42, the answer
        ret             ; back to BASIC, which reads BC

border: ld a,2          ; A = 2, red
        out (254),a     ; the border turns red
        ld b,0          ; B = 0
        ld c,a          ; C = A, so BC = 2
        ret

fill:   ld hl,22528     ; HL = first attribute byte, $5800
        ld bc,768       ; BC = 768 bytes to fill
loop:   ld (hl),48      ; yellow paper, black ink
        inc hl          ; next address
        dec bc          ; one fewer to do
        ld a,b
        or c            ; Z is set only when BC = 0
        jr nz,loop      ; not zero: go round again
        ret

        end border      ; the loader calls this one: RANDOMIZE USR 50004
```

Each line has up to three parts, and all of them are optional:

- A **label** at the start of the line, ending in a colon: `ret42:`, `loop:`. It names the address of the instruction on that line. You never work the address out; pasmo does.
- An **instruction** or a **directive**, indented. Instructions are the Z80's own (`ld`, `ret`). Directives are orders to pasmo (`org`, `end`) and make no bytes of their own.
- A **comment**, from a semicolon to the end of the line. pasmo ignores it. This is where the explanation goes, in the source, not in a separate table.

pasmo does not care about capitals: `LD BC,42` and `ld bc,42` are the same. Numbers are decimal unless marked: `$C9` or `0C9h` is hex, and `%11001001` is binary. Like the BASIC programs, every source file in the course starts with comments saying what each register is used for.

### org

`org address` sets the address that the next byte will be assembled for. Everything after it follows on, byte by byte. A file can have more than one `org`; the second one jumps forward to a new address (the examples file below uses that).

`org 50000` is the assembler's side of step 4's `CLEAR 49999`: the code is built to sit at 50000, and BASIC is kept below it.

### end

`end address` marks the end of the source. Anything after it is ignored. The address is optional. With `--tapbas`, it is the address the loader calls when it has loaded the code. Here it is `border`, so loading the tape turns the border red, which shows at once that the code arrived and ran.

### db

`db` (*define byte*) puts bytes straight into the output, with no instruction. `db 0` is one zero byte. `db 1,2,3` is three. It is how a routine keeps a number in memory. The examples file uses it.

### Labels as numbers

A label can be used anywhere a number can. `jr nz,loop` jumps to the label `loop`, and pasmo works out the -8 that step 4 counted by hand. `ld hl,outbox` puts the address of `outbox` in HL. Change the code above a label, and every use of it is right the next time you assemble.

## Building a tape: pasmo --tapbas

```
windows-tools\pasmo\pasmo.exe --tapbas --name routines chapter-03-machine-code\step5-routines.asm chapter-03-machine-code\step5-routines.tap
```

On Linux:

```
pasmo --tapbas --name routines chapter-03-machine-code/step5-routines.asm chapter-03-machine-code/step5-routines.tap
```

The general form is `pasmo [options] source output [symbols]`.

| Option | What it does |
|--------|--------------|
| `--tapbas` | Writes a `.tap` with a BASIC loader followed by the code. The course uses this. |
| `--tap` | Writes a `.tap` with only the code, no loader. For when you write your own loader (below). |
| `--bin` | Writes the bare bytes, nothing else. Handy for checking them. |
| `--name n` | The name of the code on the tape. Without it, pasmo uses the output file name. |
| `-d` | Prints the listing, the address and bytes of every line (below). |
| `symbols` | A third file name: pasmo writes every label and its address into it. |

No messages means no errors. Most mistakes stop pasmo with the line number, and no tape is written. For example, `jr nowhere`, with no label `nowhere`, gives:

```
ERROR on line 2 of file test.asm
ERROR: Symbol 'nowhere' is undefined
```

One mistake gets through, and it is worth knowing. A misspelt instruction on a line of its own, such as `rett` for `ret`, is not an error: pasmo takes a word on its own as a label, even without a colon. The tape is written, the `ret` is missing, and the code runs on into whatever follows. The listing gives it away, with `label rett` where an instruction should be.

Load the tape in Fuse (`windows-tools\fuse\fuse.exe`, then File, Open, and choose the `.tap`). As the code loads, the border turns red: the loader has run `border`. Then try:

```
PRINT USR 50000;" ";USR 50004
```

It prints `42 2`. And `RANDOMIZE USR 50012` turns the screen yellow, as in step 4.

## What the loader does

The tape that `--tapbas` writes has two files on it, one after the other: a BASIC program called `loader`, which starts itself at line 10, and the code, called `routines`. Press a key after the loader has finished, and BASIC lists it:

```
10 CLEAR 49999
20 POKE 23610,255
30 LOAD ""CODE
40 RANDOMIZE USR 50004
```

- **10** keeps BASIC below the code. pasmo takes the 49999 from the `org`: one less than the lowest address in the code.
- **20** writes 255 into the system variable `ERR NR` (23610), which holds the number of the last error, less one. 255 means "no error". The comment in pasmo's own source says it is there to avoid an error message with the +3's loader. On a 48K it does no harm.
- **30** loads the next file on the tape. `LOAD ""CODE` with no address puts the code back where it was saved from, 50000, which is in the header pasmo wrote.
- **40** calls the address given by `end`. If there is no address after `end`, or no `end` at all, pasmo leaves line 40 out, and the loader just loads the code and stops with `0 OK`.

So it is step 4's `CLEAR`, `POKE` and `RANDOMIZE USR`, with the `POKE`s done by the tape loader instead of a `FOR` loop, and no checksum to type, because the tape has its own.

## Reading pasmo's listing

The `-d` option prints the listing. Add `> name.lst 2>&1` to keep it in a file:

```
windows-tools\pasmo\pasmo.exe -d --tapbas --name routines chapter-03-machine-code\step5-routines.asm chapter-03-machine-code\step5-routines.tap > step5-routines.lst 2>&1
```

This is what it printed:

```
		ORG C350
C350:		label ret42
C350:012A00	LD BC, 002A
C353:C9		RET
C354:		label border
C354:3E02	LD A, 02
C356:D3FE	OUT (FE), A
C358:0600	LD B, 00
C35A:4F		LD C, A
C35B:C9		RET
C35C:		label fill
C35C:210058	LD HL, 5800
C35F:010003	LD BC, 0300
C362:		label loop
C362:3630	LD (HL), 30
C364:23		INC HL
C365:0B		DEC BC
C366:78		LD A, B
C367:B1		OR C
C368:20F8	JR NZ, C362
C36A:C9		RET
C36B:		END C354
Emiting TAP basic loader
Emiting TAP from C350 to C36A
```

It is in hex throughout. Each line is:

- **The address**, before the colon. `C350` is 50000.
- **The bytes**, run together. `012A00` is the three bytes `01 2A 00`, which is step 4's 1, 42, 0.
- **The instruction**, with its numbers in hex. `LD BC, 002A` is `ld bc,42`.

The labels have lines of their own, with no bytes. Look at `JR NZ, C362`: the byte pasmo worked out is `F8`, 248, the same distance step 4 counted by hand. It is step 4's table, written by the assembler.

The 27 bytes are `01 2A 00 C9 3E 02 D3 FE 06 00 4F C9 21 00 58 01 00 03 36 30 23 0B 78 B1 20 F8 C9`, byte for byte the same as step 4's `DATA`, and they add up to the same checksum, 2110. z80asm, a second assembler, gave the same bytes from the same source.

The symbol file is the short version. With a third file name, `step5-routines.sym`, pasmo writes:

```
border		EQU 0C354H
fill		EQU 0C35CH
loop		EQU 0C362H
ret42		EQU 0C350H
```

`0C354H` is hex C354, 50004. So when you need the address of a routine for `USR`, look it up here. (In BASIC, `PRINT 12*4096+3*256+5*16+4` turns C354 into 50004, if you have no hex calculator.)

## Joining tapes

A `.tap` file is just its blocks, one after another, so two tapes joined end to end are one tape. That lets us write our own BASIC loader with zmakebas, and add pasmo's code after it. The examples below are built like that:

```
windows-tools\pasmo\pasmo.exe --tap --name excode chapter-03-machine-code\step5-examples.asm chapter-03-machine-code\step5-excode.tap
windows-tools\zmakebas\zmakebas.exe -a 10 -n examples -o step5-driver.tap chapter-03-machine-code\step5-examples.bas
copy /b step5-driver.tap+chapter-03-machine-code\step5-excode.tap chapter-03-machine-code\step5-examples.tap
```

On Linux the last line is `cat step5-driver.tap chapter-03-machine-code/step5-excode.tap > chapter-03-machine-code/step5-examples.tap`.

`copy /b` means a binary copy; without the `/b`, Windows may treat the files as text and spoil them. The BASIC program runs first, and its `LOAD ""CODE` loads the block after it.

## The registers

Step 4 used A, B, C, H and L. Here is the full set this chapter uses:

| Register | Bits | What it is for |
|----------|-----:|----------------|
| A | 8 | The *accumulator*. Arithmetic, logic, compares and most memory loads go through A. |
| F | 8 | The *flags*. Bits set by instructions to record what the result was like. |
| B, C | 8 each | General use. As the pair **BC**, a counter, and what `USR` hands back. B on its own is `DJNZ`'s counter. |
| D, E | 8 each | General use. As the pair **DE**, a second address or number. |
| H, L | 8 each | General use. As the pair **HL**, the main address register: `(HL)` means the memory at HL. |

In a pair, the first letter is the high byte: if BC is 258, B is 1 and C is 2, because 1*256+2 = 258.

F has eight bits, but this chapter only reads two:

- **Z**, bit 6, the *zero* flag: set when a result was zero.
- **C**, bit 0, the *carry* flag: set when an addition went over 255, or a subtraction went below 0. Rotates and shifts also put a bit into it.

As step 4 said, the ROM uses IY to find the system variables, so routines called from BASIC leave IY alone. The stack pointer, SP, comes up under `PUSH` and `POP`.

## How the examples work

`step5-examples.asm` holds sixteen tiny routines. Example 1 is at 50100, example 2 at 50200, and so on: example n is at 50000+100*n. Each starts with its own `org`, so the address stays the same if you change another example. The gaps in between are filled with zeros, and nothing runs there.

Two bytes at the start pass numbers in and out:

```
        org 50000
inbox:  db 0            ; 50000: BASIC POKEs a number here first
outbox: db 0            ; 50001: a routine leaves an answer here
```

Every routine hands its answer back in BC. When the point of an example is what happened to A and the flags, it ends:

```
        push af
        pop bc          ; B = A, C = F
        ret
```

which copies A into B and F into C (how, is under `PUSH` and `POP` below). `USR` then gives 256*A+F. The BASIC driver splits that up and prints A in decimal and binary, then Z and C.

Load `step5-examples.tap` and it runs all sixteen, and prints this:

```
STEP 5: EXAMPLE, USR, A, FLAGS
1  LD B,C   258
2  COPY 77  77
3  200+100  44  00101100 Z0 C1
4  5-7      254 11111110 Z0 C1
5  INC 255  0   00000000 Z1 C1
6  DEC 1    0   00000000 Z1 C1
7  CP 42    1
7  CP 100   0
7  CP 150   2
8  DJNZ SUM 55
9  CALL X2  20
10 PUSH/POP 5678
11 RLCA     45  00101101 Z1 C1
12 RRCA     75  01001011 Z1 C0
13 RLA      44  00101100 Z0 C1
14 RRA      203 11001011 Z1 C0
15 SLA 75   150 10010110 Z0 C0
16 SRL 75   37  00100101 Z0 C1

PEEK 50001 GIVES 77
```

You can also call any one of them yourself after the program stops: `PRINT USR 50100` prints 258, and `POKE 50000,150: PRINT USR 50700` prints 2.

The instructions follow, one subsection each, with the example that shows it.

## The instructions

In the syntax lines, `r` is any of A, B, C, D, E, H, L; `n` is a one-byte number; `nn` is a two-byte number or address; `e` is a label within jumping distance.

### LD r,n and LD r,r — registers and numbers

Already met in step 4. `ld r,n` puts a number in a register; `ld r,r` copies one register into another, and the first one named is the one that changes. `ld rr,nn` loads a pair. None of them change the flags.

Example 1, at 50100:

```
ex1:    ld b,1
        ld c,2
        ret
```

`USR 50100` gives **258**: B is the high byte, so BC is 1*256+2.

### LD with memory — (HL) and (nn)

Brackets mean "the memory at this address".

| Form | Like BASIC | Notes |
|------|------------|-------|
| `ld a,(nn)` | `LET A=PEEK nn` | Only A, for a single byte at a fixed address. |
| `ld (nn),a` | `POKE nn,A` | Only A. |
| `ld r,(hl)` | `LET r=PEEK HL` | Any register. The address can change as the program runs. |
| `ld (hl),r` | `POKE HL,r` | Any register. `ld (hl),n` stores a number. |
| `ld hl,(nn)` | `LET HL=PEEK nn+256*PEEK (nn+1)` | Two bytes, low byte first. Step 6 uses this to read system variables. |

Example 2, at 50200, copies the inbox to the outbox:

```
ex2:    ld a,(inbox)    ; A = the byte at 50000, like PEEK
        ld hl,outbox    ; HL = 50001
        ld (hl),a       ; store A at the address in HL, like POKE
        ld c,a
        ld b,0          ; BC = A
        ret
```

The driver does `POKE 50000,77` first. `USR 50200` gives **77**, and afterwards `PEEK 50001` gives **77** too.

### ADD and SUB

`add a,n` adds a number to A; `add a,r` adds a register. `sub n` and `sub r` take one away from A (there is no `a,` in `sub`). The answer goes into A, and the flags are set: Z if the answer is 0, C if it went past 255 or below 0.

A only holds 0 to 255, so an answer that does not fit wraps round, and the carry flag says it did. Example 3, at 50300:

```
ex3:    ld a,200
        add a,100
        push af
        pop bc          ; B = A, C = F
        ret
```

A is **44** (300-256), and **C is 1**. Example 4, at 50400, does `ld a,5` and `sub 7`: A is **254** (5-7+256), **C is 1**, a *borrow*.

```
   11001000   200
 + 01100100   100
 ----------
 1 00101100   300: the 1 falls off the top into carry, A = 44
```

There is also a 16-bit `add hl,rr`, for addresses. We will use it when we need it.

### INC and DEC on a register

`inc r` adds one, `dec r` takes one away. They set Z, but they **leave carry alone**. Step 4's trap was that `inc` and `dec` on a pair change no flags at all.

Example 5, at 50500, sets carry first with `scf` (*set carry flag*, the one new instruction here), then does `ld a,255` and `inc a`:

```
ex5:    scf             ; carry = 1
        ld a,255
        inc a           ; A = 0, Z = 1, carry unchanged
        push af
        pop bc
        ret
```

A is **0**, **Z is 1**, and **C is still 1**: 255+1 wrapped round, but `inc` did not report it. Example 6, at 50600, does the same with `ld a,1` and `dec a`: A **0**, **Z 1**, **C 1**. That is why a loop that counts a register down to zero tests Z, not C.

### CP, and jumps that depend on the flags

`cp n` (or `cp r`) *compares* A with a number. It works out A-n and sets the flags as `sub` would, then throws the answer away; A does not change. Afterwards:

| After `cp n` | Means |
|--------------|-------|
| Z set | A = n |
| Z clear (NZ) | A is not n |
| C set | A < n |
| C clear (NC) | A >= n |

Then a jump acts on the flags:

| Instruction | Jumps if | Bytes | Reach |
|-------------|----------|------:|-------|
| `jr e`, `jr z,e`, `jr nz,e`, `jr c,e`, `jr nc,e` | always / Z / not Z / C / not C | 2 | -128 to +127 bytes from the next instruction |
| `jp nn`, `jp z,nn`, `jp nz,nn`, `jp c,nn`, `jp nc,nn` | the same | 3 | Anywhere in memory |

`jr` is a byte shorter, and code full of `jr`s still works if it is moved. `jp` can go anywhere, and is a little quicker when the jump is taken. With an assembler you write a label either way. If a `jr` is too far, pasmo stops with `Relative jump out of range`, and you change it to `jp`.

Example 7, at 50700, sorts the inbox into equal to, less than or more than 100:

```
ex7:    ld a,(inbox)
        cp 100          ; work out A-100, set the flags, keep A
        jp z,same       ; Z: A was 100
        jr c,less       ; carry: A was less than 100
        ld bc,2         ; otherwise it was more
        ret
less:   ld bc,1
        ret
same:   ld bc,0
        ret
```

With 42 in the inbox, `USR 50700` gives **1**; with 100, **0**; with 150, **2**. In BASIC it is `IF A=100 THEN ...: IF A<100 THEN ...`. In the listing, `jp z,same` is `CA 1E C6`, an address, and `jr c,less` is `38 04`, a distance of 4.

### DJNZ — count down and loop

`djnz e` means *decrement B and jump if not zero*. It takes one from B; if B is not zero yet, it jumps to `e`. It is the Z80's `FOR B=n TO 1 STEP -1 ... NEXT`, in one instruction of two bytes. It changes no flags. It has `jr`'s reach, and it only ever counts with B, up to 256 times.

Example 8, at 50800, adds 10+9+8+...+1:

```
ex8:    ld b,10         ; B = loop counter
        ld a,0          ; A = running total
add8:   add a,b         ; A = A+B
        djnz add8       ; B = B-1, and go round again if B is not 0
        ld c,a          ; B is already 0, so BC = A
        ret
```

`USR 50800` gives **55**. When the loop ends, B is 0, so only C needs setting. Compare step 4's loop for a 16-bit count, `dec bc` / `ld a,b` / `or c` / `jr nz`: for 256 or fewer, `djnz` does it alone.

### CALL and RET — subroutines

`call nn` is `GO SUB`: it saves the address of the next instruction on the *stack*, then jumps to `nn`. `ret` is `RETURN`: it takes that address back off the stack and carries on from there. `USR` itself works like a `call` from the ROM, which is why our routines end with `ret`. There are conditional forms too, such as `ret z` and `call nc,nn`, with the same flag conditions as `jp`.

Example 9, at 50900:

```
ex9:    ld a,5
        call double
        call double
        ld c,a
        ld b,0
        ret
double: add a,a         ; A = A+A
        ret             ; back to the instruction after the CALL
```

`USR 50900` gives **20**: 5 doubled is 10, doubled again is 20. The last `ret` goes back to BASIC; the one in `double` goes back to `ex9`.

### PUSH and POP — the stack

The *stack* is an area of memory where the Z80 keeps return addresses, and where we can park a register pair for a while. The stack pointer, SP, holds the address of the top. On the Spectrum it sits just below `RAMTOP`, so below our code. It grows downwards.

`push rr` puts a pair on top of the stack; `pop rr` takes the top one off into a pair. The pairs are AF, BC, DE and HL (and IX, IY). It is *last in, first out*, like a pile of plates. Example 10, at 51000:

```
ex10:   ld bc,1234
        ld de,5678
        push bc         ; stack: 1234
        push de         ; stack: 5678 on top of 1234
        pop bc          ; BC = 5678, the last one pushed
        pop de          ; DE = 1234
        ret
```

`USR 51000` gives **5678**: the pairs came back the other way round.

`push af` / `pop bc` is the trick the flag examples use. AF is A and F treated as a pair, A high and F low. Pushing it and popping it into BC puts A in B and F in C. That is the only way to see F from BASIC.

Every `push` needs a `pop` before the `ret`. The `ret` takes whatever is on top of the stack as its return address. If that is a number we pushed and forgot, the Z80 jumps there, and the Spectrum crashes.

### Rotates and shifts

These move the bits of a byte one place left or right. The bit that falls off the end goes into the carry flag. They differ in what comes in at the other end.

| Instruction | Moves | Comes in at the other end | Carry gets | Bytes |
|-------------|-------|---------------------------|-----------|------:|
| `rlca` | A left | old bit 7 | old bit 7 | 1 |
| `rrca` | A right | old bit 0 | old bit 0 | 1 |
| `rla` | A left | old carry | old bit 7 | 1 |
| `rra` | A right | old carry | old bit 0 | 1 |
| `sla r` | r left | 0 | old bit 7 | 2 |
| `srl r` | r right | 0 | old bit 0 | 2 |

The first four only work on A, and they leave Z alone. That is why Z shows 1 for some of them in the table above: it is whatever Z happened to be before. `sla` and `srl` work on any register, and set Z from the result. (There are register versions of the first four as well, `rlc r`, `rrc r`, `rl r` and `rr r`.)

Examples 11 to 14 all start with A = 150, `10010110`.

**RLCA**, example 11 at 51100: every bit moves left, bit 7 goes round to bit 0, and a copy goes into carry.

```
before   C ?   1 0 0 1 0 1 1 0   150
after    C 1   0 0 1 0 1 1 0 1    45
```

**RRCA**, example 12 at 51200: every bit moves right, bit 0 goes round to bit 7, and a copy goes into carry.

```
before   1 0 0 1 0 1 1 0   C ?   150
after    0 1 0 0 1 0 1 1   C 0    75
```

**RLA**, example 13 at 51300: like `rlca`, but the bit that comes in at bit 0 is the old carry, and bit 7 goes into carry. The example clears carry first with `or a` (step 4's `or`: A OR A is A, and `or` always clears carry).

```
before   C 0   1 0 0 1 0 1 1 0   150
after    C 1   0 0 1 0 1 1 0 0    44
```

So the byte and the carry flag together act as a 9-bit number going round.

**RRA**, example 14 at 51400: the mirror. The example sets carry first with `scf`, and it comes in at bit 7.

```
before   1 0 0 1 0 1 1 0   C 1   150
after    1 1 0 0 1 0 1 1   C 0   203
```

**SLA**, example 15 at 51500: shift left, a 0 comes in at bit 0. It doubles the number, and carry is set if the answer was over 255. A = 75 here.

```
before   C ?   0 1 0 0 1 0 1 1    75
after    C 0   1 0 0 1 0 1 1 0   150
```

**SRL**, example 16 at 51600: shift right, a 0 comes in at bit 7. It halves the number, and the bit that falls out, the remainder, goes into carry.

```
before   0 1 0 0 1 0 1 1   C ?    75
after    0 0 1 0 0 1 0 1   C 1    37   (75/2 = 37, remainder 1)
```

Rotates matter for the screen. Step 2 and the plan for step 8 show that the screen address is made of bit fields, and moving bits about with rotates and shifts, then picking some out with `and`, is how a routine turns a row and column into an address.

## The listing

`step5-examples.asm`, the examples source, is laid out as above: the comments at the top say what each register holds, then the inbox and outbox, then the sixteen examples, each under its own `org`. The full file is in the folder; each example appears in full in its subsection above.

The BASIC driver, `step5-examples.bas`:

```
1 REM N=example number, code at 50000+100*N
2 REM N$=what the example does
3 REM K=kind: 0 print BC, 1 print A and flags
4 REM P=number to POKE in the inbox, or -1
5 REM R=the number USR hands back
6 REM A=the A register, the high byte of R
7 REM F=the flags, the low byte of R
8 REM Z=the zero flag, bit 6 of F
9 REM C=the carry flag, bit 0 of F
10 REM I=bit number, 7 down to 0
11 REM V=what is left of A to print in binary
20 CLEAR 49999
30 BORDER 0: PAPER 0: INK 7: CLS
40 PRINT "LOADING THE EXAMPLES"
50 LOAD ""CODE
60 CLS : PRINT "STEP 5: EXAMPLE, USR, A, FLAGS"
70 READ N,N$,K,P
80 IF N=0 THEN GO TO 200
90 IF P>=0 THEN POKE 50000,P
100 LET R=USR (50000+100*N)
110 PRINT N;TAB 3;N$;TAB 12;
120 IF K=0 THEN PRINT R: GO TO 70
130 LET A=INT (R/256): LET F=R-256*A
140 LET Z=INT (F/64)-2*INT (F/128): LET C=F-2*INT (F/2)
150 PRINT A;TAB 16;: LET V=A
160 FOR I=7 TO 0 STEP -1: PRINT INT (V/2^I);: LET V=V-2^I*INT (V/2^I): NEXT I
170 PRINT " Z";Z;" C";C
180 GO TO 70
200 PRINT : PRINT "PEEK 50001 GIVES ";PEEK 50001
210 STOP
1000 DATA 1,"LD B,C",0,-1
1010 DATA 2,"COPY 77",0,77
1020 DATA 3,"200+100",1,-1
1030 DATA 4,"5-7",1,-1
1040 DATA 5,"INC 255",1,-1
1050 DATA 6,"DEC 1",1,-1
1060 DATA 7,"CP 42",0,42
1070 DATA 7,"CP 100",0,100
1080 DATA 7,"CP 150",0,150
1090 DATA 8,"DJNZ SUM",0,-1
1100 DATA 9,"CALL X2",0,-1
1110 DATA 10,"PUSH/POP",0,-1
1120 DATA 11,"RLCA",1,-1
1130 DATA 12,"RRCA",1,-1
1140 DATA 13,"RLA",1,-1
1150 DATA 14,"RRA",1,-1
1160 DATA 15,"SLA 75",1,-1
1170 DATA 16,"SRL 75",1,-1
1180 DATA 0,"",0,-1
```

The files are:

- `step5-routines.asm` and `step5-routines.tap`, built with `--tapbas` as shown above.
- `step5-examples.asm`, the sixteen examples; `step5-excode.tap`, the code alone, built with `--tap`.
- `step5-examples.bas`, the driver; `step5-examples.tap`, the driver and the code joined, ready to load.

## Line by line

`step5-routines.asm` is explained under "A source file" and "Reading pasmo's listing" above; it is step 4's routines, unchanged.

The driver, `step5-examples.bas`:

- **1–11** name the variables.
- **20** moves `RAMTOP` to 49999, so the code can load at 50000. It comes first, because `CLEAR` wipes the variables.
- **30–40** set the colours, clear the screen and say what is happening.
- **50** loads the next block on the tape, the code, to 50000, where pasmo built it.
- **60** clears the screen and prints the heading.
- **70** reads one example: its number, a short name, which kind of answer to print, and a number for the inbox.
- **80** stops at the end marker, the `DATA` with number 0.
- **90** puts a number in the inbox at 50000, for the examples that read one (2 and 7).
- **100** calls the example at 50000+100*N. The brackets are needed: without them, `USR` would take only the 50000.
- **110** prints the number and the name. The `;` at the end keeps the cursor on the line.
- **120** for an example whose answer is a number, prints BC and goes back for the next one.
- **130** for a flags example, splits BC: A is the high byte, F the low byte.
- **140** picks out bit 6 of F as Z and bit 0 as C. `INT (F/64)` drops the bits below bit 6; taking off twice `INT (F/128)` drops the bit above it. `F-2*INT (F/2)` is what is left after halving, which is bit 0.
- **150–160** print A in decimal, then in binary, bit 7 first. Each time round, `INT (V/2^I)` is the bit, and it is then taken off V.
- **170** prints Z and C and ends the line.
- **180** goes back for the next example.
- **200** shows that example 2 stored its answer in the outbox, 50001.
- **210** stops, so the program does not run into the `DATA`.
- **1000–1180** list the examples. Example 7 appears three times, with three numbers in the inbox.

## What it showed in Fuse

Each tape was loaded in a 48K Fuse.

`step5-routines.png`: as `step5-routines.tap` loaded, the border turned red, with `Bytes: routines` on the screen and `0 OK, 40:1`: the loader's line 40 had called `border` at 50004.

`step5-routines-loader.png`: a key pressed after that listed the loader, the four lines shown above. The border went back to white with the key click, as step 4 described.

`step5-routines-usr.png`: `PRINT USR 50000;" ";USR 50004` printed `42 2`, and the border was red again. `RANDOMIZE USR 50012` then turned the whole screen yellow, the same as step 4.

`step5-examples.png`: the driver's screen, the table shown under "How the examples work", ending `PEEK 50001 GIVES 77` and `9 STOP statement, 210:1`. Every number matched the results worked out in this lesson.

pasmo 0.5.4 beta 2, built from the official source, wrote byte-identical tapes to 0.5.3 for both files, and its `-d` listing was the same. Both source files were also assembled with z80asm, as a second opinion. z80asm has no `--tapbas`, so the bare bytes were compared, and they were the same as pasmo's. For `step5-routines.asm`, they are the same 27 bytes as step 4's hand assembly.

## Limitations you will notice

- **pasmo checks spelling, not sense.** It catches most misspellings (but not a lone word, which it takes for a label), a label that does not exist, or a `jr` that is too far. It does not catch `ld hl,23552` when you meant 22528, a loop that never ends, or a `push` with no `pop`. The program still crashes the same way as in step 4, and the reset is still the only way out.
- **The listing is in hex.** pasmo prints addresses and bytes in hex only. The symbol file is in hex too. Hex is the usual language of Z80 listings, so it is worth getting used to; the BASIC conversion above helps at first.
- **Old software.** pasmo has not had a Windows release since 0.5.4 beta 2. It does what this course needs, and its error messages are short. It has no idea of the Spectrum's memory beyond what `--tapbas` writes.
- **Still no way to see inside.** We see results only through BC and `PEEK`, which is why the examples bend everything into BC with `push af` / `pop bc`. Fuse's debugger (Machine, Debugger) can stop a routine and show every register, and is worth exploring.
- **The driver is slow.** The driver took about twenty seconds to print the table in Fuse, almost all of it in the BASIC that prints the binary. Each routine is a handful of instructions and is over in a few millionths of a second.
- **Not the whole Z80.** `AND`, `XOR`, `LDIR`, IX and IY, the second register set and much more are still to come, each when a step needs it.

## Try this

- In example 3, change `add a,100` to `add a,50`. Assemble, join and load again: A is 250 and C is 0, because it fitted.
- In example 8, change `ld b,10` to `ld b,22`. The total is 253. Then try 23: 276 does not fit in A, and you get 20 (276-256), with no warning. `add` set the carry, but nobody looked.
- After the driver stops, type `POKE 50000,99: PRINT USR 50700`. 99 is less than 100, so it prints 1.
- Delete the `pop de` in example 10, assemble and run. The `ret` takes 1234 as its return address and the Spectrum crashes: in Fuse, the table stopped after example 9 and the border filled with flickering stripes. Reset Fuse (F5) and load again.
- Remove the `end border` line from `step5-routines.asm`, build it with `--tapbas`, and list the loader: line 40 has gone.
- Build `step5-routines.asm` with `--bin` instead, and look at the file size: 27 bytes, with no loader and no tape headers.
