# Course tools

Installed on this machine (Debian packages, 48K Spectrum):

- **Fuse 1.6.0** (`fuse`, SDL UI) with `fuse-emulator-utils` (`listbasic`, `tzxlist`, …)
- Official 48K ROM: `/usr/share/spectrum-roms/48.rom`
- **zmakebas** — text listing to `.tap`
- **pasmo** and **z80asm** — Z80 assemblers

## BASIC to tape, and a test run

```
zmakebas -a 10 -n fill -o 01-fill.tap 01-fill.bas
listbasic 01-fill.tap
```

`-a 10` makes the tape auto-start at line 10 once it has loaded.

To load and run it headless in Fuse under Xvfb, and take screenshots:

```
tools/run-tap.sh 01-fill.bas
```

Fuse's `--auto-load` does not type `LOAD ""` on this SDL build when started from a script, so the helper sends the keys: Enter (leave the copyright screen), `j` (the `LOAD` keyword), Alt+P twice (Symbol Shift+P, the quotes), and Enter. It then captures one screenshot a second into `/tmp/zx-course-shots`.

To start Fuse yourself on a desktop display:

```
fuse --no-sound --machine 48 --rom-48 /usr/share/spectrum-roms/48.rom 01-fill.tap
```

Then type `LOAD ""`.

## Assembler smoke test

```
printf '    org 32768\n    ld a,255\n    ret\n' > /tmp/t.asm
pasmo /tmp/t.asm /tmp/t-pasmo.bin
z80asm -o /tmp/t-z80asm.bin /tmp/t.asm
```

Both should write the three bytes `3E FF C9`.
