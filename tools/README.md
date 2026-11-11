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

Fuse's `--auto-load` does not type `LOAD ""` on this SDL build when started from a script, so the helper sends the keys: Enter (leave the copyright screen), `j` (the `LOAD` keyword), Alt+P twice (Symbol Shift+P, the quotes), and Enter. It then captures one screenshot a second of the Fuse window into `/tmp/zx-course-shots`.

Optional environment variables:

- `CAPTURE_SECS` — how long to capture after `LOAD`, in seconds (default 30).
- `SHOT_DIR` — where to write the screenshots (default `/tmp/zx-course-shots`).
- `TAP_NAME` — program name written on the tape (default: the listing's basename). For this lesson, `TAP_NAME=bat` matches the program name on `02-bat.tap`.
- `KEYS` — a space-separated list of xdotool key names to tap while capturing, for example `KEYS="p p p p"`. O is left, P is right.
- `KEY_START` — second in the capture loop at which to send the first key or to start a hold (default 4).
- `KEY_EVERY` — seconds between the keys in `KEYS` (default 1).
- `KEY_HOLD` — hold this key down from `KEY_START` until `KEY_HOLD_UNTIL` (or until the end of the capture). This is the more reliable way to steer the bat: `INKEY$` is only read once per loop, so a short tap can be missed.
- `KEY_HOLD_UNTIL` — second at which to release `KEY_HOLD`.

Example, holding P long enough to catch the first ball in `02-bat.bas`:

```
TAP_NAME=bat KEY_HOLD=p KEY_START=1 KEY_HOLD_UNTIL=4 CAPTURE_SECS=20 tools/run-tap.sh 02-bat.bas
```

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
