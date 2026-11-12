# Chapter 3 — Z80 machine code, the memory map, and the system variables

The memory map first, then screen fills in BASIC, then the same fills in Z80 machine code, with timings. Each step is tested in a 48K emulator. The programs live in this folder. The shape of the chapter is in [PLAN.md](PLAN.md).

1. [The memory map and the system variables](step1-memory-map.md) — `step1-memory-map.bas` / `step1-memory-map.tap`
2. [Screen fills in BASIC, timed](step2-fills.md) — `step2-fills.bas` / `step2-fills.tap`
3. [An interactive fill in BASIC](step3-interactive-fill.md) — `step3-interactive-fill.bas` / `step3-interactive-fill.tap`
4. [The Z80 in small pieces, and a first routine](step4-first-routine.md) — `step4-first-routine.bas` / `step4-first-routine.tap`
5. [pasmo, and the Z80 basics](step5-pasmo-and-z80.md) — `step5-routines.asm` / `step5-routines.tap`, `step5-examples.asm` + `step5-examples.bas` / `step5-examples.tap`
6. [The system variables, from machine code](step6-sysvars.md) (twin of step 1) — `step6-sysvars.asm` / `step6-sysvars.tap`, the BASIC twin `step6-basic.bas` / `step6-basic.tap`, `step6-examples.asm` + `step6-examples.bas` / `step6-examples.tap`
7. [The attribute fill in machine code, timed](step7-attrfill.md) (twin of step 2) — `step7-attrfill.asm` + `step7-attrfill.bas` / `step7-attrfill.tap` (the code alone: `step7-attrcode.tap`); `step7-contention.py`, an optional T-state count with contended memory
8. [The bitmap fill in machine code, timed](step8-bitmap.md) (twin of step 2), with the "For info" aside on why the screen is in thirds — `step8-bitmap.asm` + `step8-bitmap.bas` / `step8-bitmap.tap` (the code alone: `step8-bitcode.tap`), `step8-examples.bas` / `step8-examples.tap` (the aside's worked examples, with the same code); `step8-contention.py`, an optional T-state count with contended memory

9. [The interactive fill, now fast](step9-fastfill.md) (twin of step 3) — `step9-fastfill.asm` + `step9-fastfill.bas` / `step9-fastfill.tap` (the code alone: `step9-fastcode.tap`)

From step 6 on, each machine-code step is the twin of a BASIC step, in the same order, so the two can be compared for speed and for how the program is put together.

[Chapter 3 wrap-up: what we learned, and BASIC against machine code](summary.md), with the open decisions for Chapter 4.

The details are in [PLAN.md](PLAN.md).

The colour numbers are in the [colour reference](../colour-reference.md). The screen layout and attributes are in [Chapter 1](../chapter-01-the-machine/). To build a tape and run it in Fuse, see [tools/README.md](../tools/README.md).
