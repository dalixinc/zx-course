# Chapter 5 — The same games in machine code

Bat and ball from Chapter 2, then Invaders from Chapter 4, rebuilt in Z80 machine code in the same order, each step tested in a 48K emulator and timed against its BASIC twin. The programs live in this folder. The shape of the chapter and the decisions made for it are in [PLAN.md](PLAN.md).

Each step is a BASIC driver (`.bas`) and the machine code (`.asm`), joined on one tape (`.tap`).

Part A, bat and ball (twins of Chapter 2):

1. [A bouncing ball in machine code](step1-ball.md) (twin of Chapter 2, step 1) — `step1-ball.asm` + `step1-ball.bas` / `step1-ball.tap`; the lesson's small examples, `step1-examples.asm` + `step1-examples.bas` / `step1-examples.tap`
2. [The bat, read with IN](step2-bat.md) (twin of Chapter 2, step 2) — `step2-bat.asm` + `step2-bat.bas` / `step2-bat.tap`; the keyboard viewer, `step2-examples.asm` + `step2-examples.bas` / `step2-examples.tap`
3. [The bricks](step3-bricks.md) (twin of Chapter 2, step 3) — `step3-bricks.asm` + `step3-bricks.bas` / `step3-bricks.tap`; the attribute examples, `step3-examples.asm` + `step3-examples.bas` / `step3-examples.tap`

The colour numbers are in the [colour reference](../colour-reference.md). To build a tape and run it in Fuse, see [tools/README.md](../tools/README.md) and [windows-tools/README.md](../windows-tools/README.md).
