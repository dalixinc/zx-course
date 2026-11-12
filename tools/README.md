# Course tools

Installed on this machine (Debian packages, 48K Spectrum):

- **Fuse 1.6.0** (`fuse`, SDL UI) with `fuse-emulator-utils` (`listbasic`, `tzxlist`, …)
- Official 48K ROM: `/usr/share/spectrum-roms/48.rom`
- **zmakebas** — text listing to `.tap`
- **pasmo** and **z80asm** — Z80 assemblers

## Building a tape: build.sh

`tools/build.sh` is the Linux counterpart of `windows-tools/build.bat`. The usage is the same. It uses `pasmo`, `zmakebas` and `fuse` from PATH. If one is missing, it names the apt package to install (`pasmo`, `zmakebas`, `fuse-emulator-gtk` or `fuse-emulator-sdl`, and `spectrum-roms`).

From the course folder:

```
tools/build.sh file.asm
tools/build.sh file.bas
tools/build.sh file.bas NAME 10
tools/build.sh driver.bas code.asm
tools/build.sh file.asm nofuse
```

- A `.asm` file is assembled with `pasmo --tapbas` to `file.tap`.
- A `.bas` file is converted with zmakebas to `file.tap`. `NAME` is the name shown on the tape (default: the file's name, cut to 10 characters). The optional `LINE` is the auto-start line (default: 10).
- A `.bas` driver followed by a `.asm` file is how Chapter 3 step 5 builds `step5-examples.tap`: zmakebas writes the driver, pasmo `--tap` writes the code with no loader, and `cat` joins them, driver first. The combined tape is `driver.tap`. The two halves are kept as `driver-driver.tap` and `code-code.tap` so you can inspect them.
- Add `-n` or `nofuse` anywhere on the line to build the tape without opening Fuse.

The tape is written next to the source file.

Fuse 1.6.0 treats a `.tap` on the command line the same way as File, Open. Auto-load is on by default, so the emulator's "phantom typist" types `LOAD ""` (or `LOAD "" CODE` if the first block is a CODE file) and the program starts. The script does not pass a custom ROM, because Fuse will not auto-load when one is set. It also passes `--machine 48`, so you get a 48K Spectrum even if Fuse last ran as a 128K.

If Fuse cannot open an audio device (for example on a headless machine), set `FUSE_FLAGS=--no-sound`.

Examples:

```
tools/build.sh chapter-03-machine-code/step5-routines.asm
tools/build.sh chapter-01-the-machine/01-fill.bas fill 10
tools/build.sh chapter-03-machine-code/step5-examples.bas chapter-03-machine-code/step5-examples.asm examples 10
```

On Windows, use `windows-tools\build.bat`. See `windows-tools/README.md`.

## BASIC to tape, and a test run

```
zmakebas -a 10 -n fill -o chapter-01-the-machine/01-fill.tap chapter-01-the-machine/01-fill.bas
listbasic chapter-01-the-machine/01-fill.tap
```

`-a 10` makes the tape auto-start at line 10 once it has loaded.

To load and run it headless in Fuse under Xvfb, and take screenshots:

```
tools/run-tap.sh chapter-01-the-machine/01-fill.bas
```

`run-tap.sh` also passes `--rom-48`, and Fuse 1.6.0 will not auto-load when a custom ROM is set (`tape_can_autoload()` in the source returns false). So the helper types the keys itself: Enter (leave the copyright screen), `j` (the `LOAD` keyword), Alt+P twice (Symbol Shift+P, the quotes), and Enter. (`tools/build.sh` does not pass a custom ROM, and lets Fuse's phantom typist do the typing.) It then captures one screenshot a second of the Fuse window into `/tmp/zx-course-shots`.

The helper also takes a `.tap` instead of a `.bas`, and loads it as it is. That is how the pasmo tapes from Chapter 3 step 5 on are tested:

```
tools/run-tap.sh chapter-03-machine-code/step5-routines.tap
```

Optional environment variables:

- `CAPTURE_SECS` — how long to capture after `LOAD`, in seconds (default 30).
- `SHOT_DIR` — where to write the screenshots (default `/tmp/zx-course-shots`).
- `TAP_NAME` — program name written on the tape (default: the listing's basename). For Chapter 2 step 2, `TAP_NAME=bat` matches the program name on `chapter-02-bat-and-ball/step2-bat.tap`.
- `KEYS` — a space-separated list of xdotool key names to tap while capturing, for example `KEYS="p p p p"`. O is left, P is right.
- `KEY_START` — second in the capture loop at which to send the first key or to start a hold (default 4).
- `KEY_EVERY` — seconds between the keys in `KEYS` (default 1).
- `KEY_HOLD` — hold this key down from `KEY_START` until `KEY_HOLD_UNTIL` (or until the end of the capture). This is the more reliable way to steer the bat: `INKEY$` is only read once per loop, so a short tap can be missed.
- `KEY_HOLD_UNTIL` — second at which to release `KEY_HOLD`.

Example, holding P long enough to catch the first ball in `chapter-02-bat-and-ball/step2-bat.bas`:

```
TAP_NAME=bat KEY_HOLD=p KEY_START=1 KEY_HOLD_UNTIL=4 CAPTURE_SECS=20 tools/run-tap.sh chapter-02-bat-and-ball/step2-bat.bas
```

To start Fuse yourself on a desktop display:

```
fuse --no-sound --machine 48 --rom-48 /usr/share/spectrum-roms/48.rom chapter-01-the-machine/01-fill.tap
```

Then type `LOAD ""`.

## Assembler smoke test

```
printf '    org 32768\n    ld a,255\n    ret\n' > /tmp/t.asm
pasmo /tmp/t.asm /tmp/t-pasmo.bin
z80asm -o /tmp/t-z80asm.bin /tmp/t.asm
```

Both should write the three bytes `3E FF C9`.

## pasmo tapes

```
pasmo --tapbas --name routines chapter-03-machine-code/step5-routines.asm chapter-03-machine-code/step5-routines.tap
pasmo -d --bin chapter-03-machine-code/step5-routines.asm /tmp/r.bin   # -d prints the listing
```

`--tapbas` writes a BASIC loader (`CLEAR`, `POKE 23610,255`, `LOAD ""CODE`, and `RANDOMIZE USR` to the `end` address) followed by the code. `--tap` writes the code alone; join it after a zmakebas loader with `cat` (on Windows, `copy /b a.tap+b.tap c.tap`).
