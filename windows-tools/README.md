# Windows tools

Windows builds of the tools used in this course, so you can `git pull` and use them locally. Linux setup will be revisited later. On Linux, `tools/build.sh` is the counterpart of the script below; it uses the packages you install with apt. See `tools/README.md`.

## Building a tape: build.bat

From the course folder (the one with `README.md` in it):

```
windows-tools\build.bat file.asm
windows-tools\build.bat file.bas
windows-tools\build.bat file.bas NAME 10
windows-tools\build.bat driver.bas code.asm
windows-tools\build.bat file.asm nofuse
```

- A `.asm` file is assembled with `pasmo --tapbas` to `file.tap`.
- A `.bas` file is converted with zmakebas to `file.tap`. `NAME` is the name shown on the tape (default: the file's name, cut to 10 characters). The optional `LINE` is the auto-start line (default: 10).
- A `.bas` driver followed by a `.asm` file is how Chapter 3 step 5 builds `step5-examples.tap`: zmakebas writes the driver, pasmo `--tap` writes the code with no loader, and `copy /b` joins them, driver first. The combined tape is `driver.tap`. The two halves are kept as `driver-driver.tap` and `code-code.tap` so you can inspect them.
- Add `-n` or `nofuse` anywhere on the line to build the tape without opening Fuse.

The script finds pasmo, zmakebas and Fuse next to itself, so it also works if you run it from another folder, or by a full path. The tape is written next to the source file.

Fuse 1.6.0 treats a `.tap` on the command line the same way as File, Open. Auto-load is on by default, so the emulator's "phantom typist" types `LOAD ""` (or `LOAD "" CODE` if the first block is a CODE file) and the program starts. The script also passes `--machine 48`, so you get a 48K Spectrum even if Fuse last ran as a 128K. If Fuse cannot open an audio device, set `FUSE_FLAGS=--no-sound`. You can still type `LOAD ""` yourself if auto-load has been turned off in Fuse's options.

Examples, from the course folder:

```
windows-tools\build.bat chapter-03-machine-code\step5-routines.asm
windows-tools\build.bat chapter-01-the-machine\01-fill.bas fill 10
windows-tools\build.bat chapter-03-machine-code\step5-examples.bas chapter-03-machine-code\step5-examples.asm examples 10
```

Each tool is in its own folder. The binaries are unzipped and ready to run. Licences are included next to them. The SHA-256 hashes below are of the official archives we downloaded, not of the unpacked files.

## pasmo 0.5.4.beta2

Z80 assembler. This is the official Windows build from the Pasmo site. It is the latest version that ships a Windows executable. Version 0.5.5 (5 March 2022) is newer, but that release is source only.

- Official site: https://pasmo.speccy.org/
- Windows binary: https://pasmo.speccy.org/bin/pasmo-0.5.4.beta2.zip
- SHA-256: `bf3adb2cf374c1c16dc651d8b0ec2eba8d7b475f6bed2ee1b30a89e34e20678a`
- Source (same version): https://pasmo.speccy.org/bin/pasmo-0.5.4.beta2.tgz
- Licence: GPL (see `pasmo/COPYING`)

Example:

```
windows-tools\pasmo\pasmo.exe --tapbas fill.asm fill.tap
```

`--tapbas` writes a `.tap` with a short BASIC loader around the code. That is the form the course uses.

## zmakebas 1.2b

Converts a text BASIC listing into a `.tap`. There is no official Windows executable for this version, so the copy here was cross-compiled from the official 1.2b source with mingw-w64 (`i686-w64-mingw32-gcc -O -Wall -Wno-pointer-sign -DHAVE_GETOPT`, then stripped). That is the same 1.2b used on the Linux machine that builds the course tapes.

- Source tarball (Debian orig, Russell Marks 1.2b): https://deb.debian.org/debian/pool/main/z/zmakebas/zmakebas_1.2b.orig.tar.gz
- SHA-256: `d03526010093ea99aed672210e642be7e431b7eafd2bfff4f2c1f03d06b1ba34`
- Licence: public domain, by Russell Marks (see `zmakebas/README`)

Example:

```
windows-tools\zmakebas\zmakebas.exe -a 10 -n FILL -o fill.tap fill.bas
```

`-a 10` makes the tape auto-start at line 10 once it has loaded. `-n FILL` is the name the Spectrum sees on the tape.

## Fuse 1.6.0

The 48K Spectrum emulator used to test every program in the course. This is the official Windows zip from SourceForge, version 1.6.0, which matches the Linux build used to test the lessons.

- Official site: https://fuse-emulator.sourceforge.net/
- Windows zip: https://sourceforge.net/projects/fuse-emulator/files/fuse/1.6.0/fuse-1.6.0-win32.zip
- SHA-256: `e31a12104fd5ad40b5dc2b8072a76c879cc9689e159694070ebabb754ea0e1b1`
- Source: https://sourceforge.net/projects/fuse-emulator/files/fuse/1.6.0/fuse-1.6.0.tar.gz
- Licence: GPL (see `fuse/COPYING.txt`). Third-party library licences are in `fuse/3rd-party/` and `fuse/LICENSES.txt`.

The build script starts Fuse with the tape it wrote. You can also run `windows-tools\fuse\fuse.exe file.tap`, or open the `.tap` from File, Open, or drag it onto the window. On a 48K machine, type `LOAD ""` if it does not auto-load.

The unpacked Fuse folder is about 6 MB of the 7 MB in `windows-tools/`. The zip it came from is 2.5 MB.
