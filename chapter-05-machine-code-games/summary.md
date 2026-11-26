# Chapter 5 — Machine code games: summary

Chapter 5 took the course's games from BASIC into machine code in three stages: bat and ball (Part A, steps 1 to 6), Invaders (Part B, steps 7 to 14), and two extras on the finished game (steps 15 and 16). Every program was assembled with pasmo, cross-checked against z80asm, and run in a 48K Fuse before it was shown. Every timing is in frames, measured with `FRAMES` in Fuse. The detail is in the lessons. This page is the short version.

Part A has its own summary, [summary-part-a.md](summary-part-a.md), and Part B has [summary-part-b.md](summary-part-b.md), each with a job-by-job table against the BASIC twin. They are not repeated here.

## The sixteen steps

| Part | Steps | What it built | Summary |
|------|------:|---------------|---------|
| A | 1 to 6 | Bat and ball: a ball on `HALT`, a bat read with `IN`, bricks through the attributes, an LFSR, speaker notes, score and lives | [summary-part-a.md](summary-part-a.md) |
| B | 7 to 14 | Invaders: the base, the shot, the block, the march, hits, bombs, shields, score, lives, waves and sound | [summary-part-b.md](summary-part-b.md) |
| Extra | 15 | The base, the shot and the bombs moved by pixels, drawn with XOR | [step15-pixels.md](step15-pixels.md) |
| Extra | 16 | A Kempston joystick read beside the keys | [step16-joystick.md](step16-joystick.md) |

## The numbers that matter

| Job | BASIC | Machine code, no `halt` | About |
|-----|------:|------------------------:|------:|
| The ball, one pass (step 1 against Chapter 2) | 2.4 | 0.0166 | 145 × |
| An idle Invaders pass (step 14 against Chapter 4) | 6.5 | 0.0075 | 870 × |
| A march step (step 10 against Chapter 4) | 45 | 0.785 | 57 × |
| A sound in play (step 14) | 1.2 for `BEEP 0.02` | 0.06 to 0.07 for a click | 18 × |
| Reading the input (step 16 against Chapter 4's `INKEY$`) | 0.232, one key | 0.0043, four keys and five stick bits | 54 × |

As shipped, every machine-code pass is one frame, kept there by `HALT`, so the game runs at the same speed whatever the code does inside the frame. The "no `halt`" figures show how much of that frame is left. In the heaviest case, a march step with a hit, a bomb and a shot on every pass, step 15 used a pass of 973 for 973 frames from row 1 and 181 for 181 on the shield rows, with none over. Step 16 left that unchanged.

## What the chapter showed

- **The output is the cost.** In BASIC the loop's logic costs frames; in machine code the logic is nearly free, and what takes time is drawing: a march step rubs out and draws 32 invaders, and was most of a frame until the ripple split it.
- **The design carries over, and gets cheaper.** The alive table, the damage map, the hit test by arithmetic and the beats are Chapter 4's ideas, each at a hundredth of the cost or less.
- **One input byte for every device.** Step 7's `rkeys` gave the loop a byte with a bit for each key, and step 16 added a joystick by ORing more bits into it. Nothing else changed.
- **XOR makes moving easy and hides a rule.** Step 15 moved three things by pixels with XOR, with no need to know what was under them, as long as nothing else draws there while they are on. `put` became a wrapper that lifts them off. That rule is what a sprite engine has to keep, for many more objects.
- **Cell-based drawing was the right first step.** It let the game be finished and tested before pixels were involved, and the pixel step was a change to a working game that a stray-cell test could check.
- **Tests that look at the screen found bugs the counts did not.** The stray-cell check counted any cell that should be empty and was not, and the first version of that check itself skewed the frame budget it was meant to confirm. Both were found and corrected in step 15.
- **Hardware is not always there.** A port with no device on it answers 255 in Fuse. Step 16 had to ignore that, or a game without a joystick would fire by itself.

## What is not done

- **The block, the shields and the explosions are still cells.** Pixel invaders need pre-shifted copies of every frame, with masks, and a routine that draws a sprite anywhere. Step 15's examples show one graphic done both ways, and nothing more.
- **Only one bomb, and one shot, at a time.** Each is a pair of bytes in the code, not an object in a table.
- **A short pause between waves**, about a seventh of a second.
- **The game's font is the ROM's.**
- **No real joystick was tried.** Step 16 was tested with Fuse's keyboard-as-joystick option only.
- **Sinclair and cursor joysticks** are not supported.
- **The Windows copy of Fuse** was not used to run any test in this chapter; the box has Fuse for Linux only.

## Open questions for Chapter 6

Chapter 6 is the parameter-driven sprite engine. These are the questions for Dalix, with a default for each, so none of them blocks the start.

1. **What does a sprite look like in memory?** Default: a width in bytes, a height in lines, and the pixel data and mask interleaved, with eight shifted copies made at start-up as step 15's Example 5 does. The alternative is shifting at run time, which uses less memory and is slower (11 against 25 frames for 510 draws of the base in step 15).
2. **Masked or XOR?** Default: masks for anything that crosses a background (the invaders, over shields), and XOR kept for things that are always over black, such as the shot. The cost of masks is that taking one off needs the background redrawn.
3. **Where do the shifted copies go?** Default: after the code, built once at start-up. By arithmetic, three invader types in two frames at eight shifts, 16 bytes each, is 768 bytes, and the same again for masks, so about 1.5 KB; the lesson would count them properly.
4. **What does the engine take as parameters?** Default: a table of sprites, each with a position in pixels, a frame and an on/off flag, drawn from the table every pass, so the game stops calling `put` and only changes the table.
5. **Do the invaders go to pixels in Chapter 6?** Default: yes, as the engine's first user, moving a pixel a step instead of eight. The block's hit test would then be by pixel overlap, as step 15 did for the base.
6. **Flicker.** Redrawing 32 sprites a pass will show tearing if it runs past the frame's raster. Default: draw from the table in a fixed order and measure it, as every chapter has done, and say plainly if it flickers.
7. **Does the code move?** The code is at 50000 behind a small BASIC loader. Chapter 6's tables will need room. The default is to leave it at 50000 and see.
8. **Joysticks.** Should Chapter 6 add Sinclair and cursor joysticks to the input byte? Default: no, unless asked.
9. **A real joystick.** If Dalix has a Kempston interface, step 16 could be tried on hardware. If it does not work, the 255 rule in `rkeys` is the first thing to look at.
