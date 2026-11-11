# Lesson 2 — A bouncing ball (bat-and-ball, step 1)

This is the first step of the tiny bat-and-ball game in Part 2 of the course. The rest of this chapter builds the game in six steps: the ball, a bat you move, a wall of bricks, a user-defined graphic for the ball, a little random deflection on the bounce, and `BEEP` sounds. Score and lives can come later. The [chapter index](README.md) lists the steps. We test each one before going on.

In this step there is no bat and no bricks. The only job is to get a ball moving diagonally with `PRINT AT`, to bounce it off all four edges of the main screen, and to rub out its old position as it goes. The later steps add a bat moved with `INKEY$`, a wall of bricks, a user-defined graphic for the ball, a little randomness in the bounce, and `BEEP` sounds.

Every program is tested in a 48K emulator before it is shown.

## The BASIC keywords used here

These are the keywords in the listing, in the form the 48K Spectrum uses them. A one-line example is given for each.

### REM

`REM` makes the rest of that line a remark. The computer skips it. Use it to name variables or to leave a short note for the reader.

```
1 REM R=ball row 0-21
```

### BORDER

`BORDER colour` sets the border around the screen. `colour` is 0 to 7: black, blue, red, magenta, green, cyan, yellow, white. It takes effect at once and is not stored in the attribute file.

```
10 BORDER 0
```

### INK and PAPER (as statements)

`INK colour` and `PAPER colour` set the permanent ink and paper. `colour` is 0 to 7, or 8 (transparent: do not change) or 9 (contrasting). These stay in force until you change them. `CLS` fills the screen with the current paper colour.

They can also appear inside a `PRINT` statement, where they last only for that statement — see PRINT, below.

```
10 INK 7: PAPER 0
```

### CLS

`CLS` clears the main screen to the current paper colour, and puts the print position back at the top left (line 0, column 0).

```
10 CLS
```

### LET

`LET variable=expression` stores a number (or a string, if the name ends in `$`) in a variable. On the 48K Spectrum you must write `LET`; `R=5` on its own is a syntax error.

Numeric names can be more than one letter, as in `DR` and `DX`. They must start with a letter.

```
10 LET R=5
```

### PRINT

`PRINT` writes text and numbers on the screen. Items in the list can be strings in quotes, numbers, or the extra items below.

Separators between items:

- `;` — put the next item immediately after the last one.
- `,` — move to the next print zone. The zones are 16 characters wide, so the comma jumps to column 16, or to column 0 of the next line if you are already in the right-hand zone.
- `'` (apostrophe) — move to the start of the next line, as if you had pressed ENTER.

```
10 PRINT "A"; "B", "C"
```

`AT line,column` is an item, not a separate command, so it sits inside `PRINT`. `line` is 0 to 21, with 0 at the top. `column` is 0 to 31, with 0 at the left. The two lines at the bottom of the display (22 and 23) are reserved for `INPUT` and error messages; a ball that used them would clash with that, or give the error `B Integer out of range`. This is why the program keeps `R` in 0 to 21, not 0 to 23 as in the attribute rows of Lesson 1.

```
10 PRINT AT 5,10;"O"
```

`TAB column` moves to that column on the current line, or to that column on the next line if the print position has already gone past it. Columns 0 to 31 are the useful range; 32 and above wrap around (`TAB 33` is the same as `TAB 1`).

```
10 PRINT TAB 8;"here"
```

These items can also appear in a `PRINT` list, and last only until the end of that statement (or until another such item in the same statement):

- `INK n` and `PAPER n` — 0 to 7, or 8 (transparent) or 9 (contrast).
- `BRIGHT n` — 0 off, 1 on, 8 transparent.
- `FLASH n` — 0 off, 1 on, 8 transparent.
- `INVERSE n` — 0 off, 1 on (the character is printed with ink and paper swapped).
- `OVER n` — 0 off, 1 on (the new character is mixed with whatever is already on the screen, rather than replacing it).

```
10 PRINT AT 0,0; INK 2; BRIGHT 1; "red"
```

They do not change the permanent `INK` and `PAPER` set by the statements above.

### PAUSE

`PAUSE n` waits. If `n` is 0, it waits until a key is pressed. If `n` is 1 to 65535, it waits `n` frames, at 50 frames a second on a 48K Spectrum, so `PAUSE 50` is one second. A key press cuts the pause short.

```
10 PAUSE 5
```

### IF and THEN

`IF condition THEN statement` runs the statement only when the condition is true. There is no `ELSE` in 48K BASIC. Extra statements on the same line, after a colon, also run only when the condition is true.

The comparisons are `=`, `<>`, `<`, `>`, `<=` and `>=`. You can join conditions with `AND`, `OR` and `NOT`.

```
10 IF R+DR>21 THEN LET DR=-DR
```

### GO TO

`GO TO line` jumps to that line and carries on from there. The program uses it to repeat the move-and-draw loop. (On the 48K keyboard it is the two keywords `GO` and `TO`, not a single word.)

```
10 GO TO 40
```

## The listing

The ball is the letter `O`, so there is no need for a user-defined graphic. It starts at row 5, column 5, and steps one character down and one character right each time. Before it moves, the old `O` is replaced with a space. If the next step would take it off an edge, that direction is reversed, and then the step is taken, so it never actually leaves the screen.

```
1 REM R=ball row 0-21
2 REM X=ball column 0-31
3 REM DR=row step +1 or -1
4 REM DX=column step +1 or -1
10 BORDER 0: PAPER 0: INK 7: CLS
20 LET R=5: LET X=5
30 LET DR=1: LET DX=1
40 PRINT AT R,X;"O"
50 PAUSE 5
60 PRINT AT R,X;" "
70 IF R+DR<0 THEN LET DR=-DR
80 IF R+DR>21 THEN LET DR=-DR
90 IF X+DX<0 THEN LET DX=-DX
100 IF X+DX>31 THEN LET DX=-DX
110 LET R=R+DR
120 LET X=X+DX
130 GO TO 40
```

The source is `step1-ball.bas`. A tape image ready to load is `step1-ball.tap`.

## Line by line

- **1–4** name the variables. **R** is the ball's row, 0 to 21. **X** is its column, 0 to 31 (the same letter as the column in Lesson 1). **DR** and **DX** are the steps added to `R` and `X` each time: each is `+1` or `-1`, so the ball moves diagonally.
- **10** sets a black border and paper, white ink, and clears the screen.
- **20–30** place the ball and give it a down-and-right direction.
- **40** prints the `O` at the current row and column.
- **50** waits five frames (a tenth of a second) so you can see it.
- **60** prints a space at the same place, which rubs the `O` out.
- **70–80** look at the next row. If it would be above the top or below line 21, `DR` is reversed.
- **90–100** do the same for the column, against the left edge and column 31.
- **110–120** take the step, now known to be on the screen.
- **130** goes back to print the ball in its new place.

If the ball hits a corner, both `DR` and `DX` reverse, and it comes back the way it came. That is the right thing for a corner.

A screenshot taken while it is running is in `step1-ball.png`.

To run it yourself: start a 48K emulator, load `step1-ball.tap`, and type `LOAD ""`. The program auto-starts at line 10 and runs until you break it (on a real machine, Caps Shift and Space; in Fuse, often F4 or the menu). The helper script `tools/run-tap.sh chapter-02-bat-and-ball/step1-ball.bas` (from the course root) builds the tape and runs it in Fuse under Xvfb.

## Try this

Change `PAUSE 5` on line 50 to `PAUSE 1` to speed the ball up, or to `PAUSE 20` to slow it down. Run it again and see which you prefer.

Or change line 30 so the ball starts up and left instead: `30 LET DR=-1: LET DX=-1`. It will hit a top or left edge first, then bounce in the same way.
