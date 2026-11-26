# Chapter 5 — The same games in machine code

Bat and ball from Chapter 2, then Invaders from Chapter 4, rebuilt in Z80 machine code in the same order, each step tested in a 48K emulator and timed against its BASIC twin. The programs live in this folder. The shape of the chapter and the decisions made for it are in [PLAN.md](PLAN.md).

Each step is a BASIC driver (`.bas`) and the machine code (`.asm`), joined on one tape (`.tap`).

Part A, bat and ball (twins of Chapter 2):

1. [A bouncing ball in machine code](step1-ball.md) (twin of Chapter 2, step 1) — `step1-ball.asm` + `step1-ball.bas` / `step1-ball.tap`; the lesson's small examples, `step1-examples.asm` + `step1-examples.bas` / `step1-examples.tap`
2. [The bat, read with IN](step2-bat.md) (twin of Chapter 2, step 2) — `step2-bat.asm` + `step2-bat.bas` / `step2-bat.tap`; the keyboard viewer, `step2-examples.asm` + `step2-examples.bas` / `step2-examples.tap`
3. [The bricks](step3-bricks.md) (twin of Chapter 2, step 3) — `step3-bricks.asm` + `step3-bricks.bas` / `step3-bricks.tap`; the attribute examples, `step3-examples.asm` + `step3-examples.bas` / `step3-examples.tap`
4. [A little randomness](step4-random.md) (twin of Chapter 2, step 5) — `step4-random.asm` + `step4-random.bas` / `step4-random.tap`; the random number sources compared, `step4-examples.asm` + `step4-examples.bas` / `step4-examples.tap`
5. [Sound from the speaker](step5-sound.md) (twin of Chapter 2, step 6) — `step5-sound.asm` + `step5-sound.bas` / `step5-sound.tap`; the speaker and border examples, `step5-examples.asm` + `step5-examples.bas` / `step5-examples.tap`
6. [Score, lives and an ending](step6-score.md) (twin of Chapter 2, step 7) — `step6-score.asm` + `step6-score.bas` / `step6-score.tap`; printing from machine code, `step6-examples.asm` + `step6-examples.bas` / `step6-examples.tap`. Step 6b, a nudge at the ceiling so that the whole wall can be cleared, is in the same lesson.

A summary of Part A, with the timings of all six steps set beside their BASIC twins, is in [summary-part-a.md](summary-part-a.md).

Part B, Invaders in machine code (twins of Chapter 4):

7. [The Invaders base](step7-base.md) (twin of Chapter 4, step 1) — `step7-base.asm` + `step7-base.bas` / `step7-base.tap`; reading several half-rows into one key byte, `step7-examples.asm` + `step7-examples.bas` / `step7-examples.tap`
8. [One shot](step8-shot.md) (twin of Chapter 4, step 2) — `step8-shot.asm` + `step8-shot.bas` / `step8-shot.tap`; `INC A` as a test for 255 and `CALL NZ`, `step8-examples.asm` + `step8-examples.bas` / `step8-examples.tap`
9. [The block of invaders](step9-block.md) (twin of Chapter 4, step 3) — `step9-block.asm` + `step9-block.bas` / `step9-block.tap`; the two lookups, `step9-examples.asm` + `step9-examples.bas` / `step9-examples.tap`

The colour numbers are in the [colour reference](../colour-reference.md). To build a tape and run it in Fuse, see [tools/README.md](../tools/README.md) and [windows-tools/README.md](../windows-tools/README.md).
