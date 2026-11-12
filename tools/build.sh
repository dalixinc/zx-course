#!/bin/bash
# build.sh - build a ZX Spectrum tape and open it in Fuse.
#
# This is the Linux counterpart of windows-tools/build.bat. The
# usage is the same. It uses pasmo, zmakebas and fuse from PATH
# (the packages you would install with apt), rather than copies
# in the repository.
#
#   tools/build.sh file.asm
#   tools/build.sh file.bas [NAME] [LINE]
#   tools/build.sh driver.bas code.asm [NAME] [LINE]
#
# The tape is written next to the source file.
#
# An optional -n or nofuse anywhere on the line builds the
# tape but does not start Fuse.

# ------------------------------------------------------------
# Usage text, printed when there are no arguments, or when the
# arguments do not make sense.
# ------------------------------------------------------------
usage() {
  cat <<'USAGE'
Build a ZX Spectrum tape and optionally open it in Fuse.

Usage:
  tools/build.sh file.asm
      Assemble with pasmo --tapbas to file.tap, then open it in Fuse.
      The tape has a short BASIC loader around the code.

  tools/build.sh file.bas [NAME] [LINE]
      Convert with zmakebas to file.tap, then open it in Fuse.
      NAME is the program name stored on the tape, which LOAD shows
      as "Program: NAME". It can be at most 10 characters. If you
      leave it out, it defaults to the file's name, also cut to 10
      characters.
      LINE is the auto-run line, the same idea as SAVE "x" LINE 10.
      After LOAD, the program RUNs from that line. Default: 10.

  tools/build.sh driver.bas code.asm [NAME] [LINE]
      Build a BASIC driver with zmakebas, assemble the code with
      pasmo --tap (code only, no loader), and join them with cat
      into driver.tap (driver first, then code). The two halves
      are kept as driver-driver.tap and code-code.tap. Then open
      the combined tape in Fuse. NAME and LINE apply to the BASIC
      driver, as above.

  Add -n or nofuse anywhere on the line to build without opening Fuse.

The tape is written next to the source file. Fuse is started at
three times normal size (--graphics-filter 3x). Set FUSE_FLAGS for
extra Fuse options, for example FUSE_FLAGS=--no-sound.

pasmo, zmakebas and fuse are found on PATH. If one is missing, the
script names the apt package that provides it.
USAGE
}

# Print a missing-tool message and the apt package to install.
need_tool() {
  # $1 = command name, $2 = apt package(s) to suggest
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "$1 is not installed (or not on PATH)."
    echo "Install it with:  sudo apt install $2"
    return 1
  fi
  return 0
}

need_fuse() {
  # Debian packages the emulator as fuse-emulator-gtk or
  # fuse-emulator-sdl. Either may install the command as "fuse"
  # (via alternatives), "fuse-gtk" or "fuse-sdl". The 48K ROM
  # comes from the spectrum-roms package.
  if command -v fuse >/dev/null 2>&1; then
    FUSE_CMD=fuse
    return 0
  fi
  if command -v fuse-gtk >/dev/null 2>&1; then
    FUSE_CMD=fuse-gtk
    return 0
  fi
  if command -v fuse-sdl >/dev/null 2>&1; then
    FUSE_CMD=fuse-sdl
    return 0
  fi
  echo "fuse is not installed (or not on PATH)."
  echo "Install it with:  sudo apt install fuse-emulator-gtk"
  echo "  or:             sudo apt install fuse-emulator-sdl"
  echo "and:              sudo apt install spectrum-roms"
  return 1
}

# Lower-case extension of a file name, without the dot.
# "File.ASM" becomes "asm".
ext_of() {
  _base=$(basename "$1")
  _ext=${_base##*.}
  if [ "$_ext" = "$_base" ]; then
    echo ""
    return
  fi
  printf '%s' "$_ext" | tr 'A-Z' 'a-z'
}

# Cut a tape name to the Spectrum's 10-character limit.
cut_name() {
  printf '%s' "$1" | cut -c1-10
}

# ------------------------------------------------------------
# Read the command line. Pull out -n / nofuse, and keep the
# remaining arguments in order.
# ------------------------------------------------------------
NOFUSE=0
ARGS=()
for arg in "$@"; do
  case "$arg" in
    -n|nofuse|NOFUSE|-N)
      NOFUSE=1
      ;;
    *)
      ARGS+=("$arg")
      ;;
  esac
done

if [ ${#ARGS[@]} -eq 0 ]; then
  usage
  exit 1
fi

if [ ${#ARGS[@]} -gt 4 ]; then
  echo "Too many arguments."
  echo
  usage
  exit 1
fi

P1=${ARGS[0]}
P2=${ARGS[1]:-}
P3=${ARGS[2]:-}
P4=${ARGS[3]:-}

EXT1=$(ext_of "$P1")
EXT2=""
if [ -n "$P2" ]; then
  EXT2=$(ext_of "$P2")
fi

# Directory, stem (name without extension) and output tape for a source file.
# The tape is written next to the source.
dir_of() {
  _d=$(dirname "$1")
  # If dirname is ., keep it as . so the tape lands in the current folder.
  printf '%s' "$_d"
}

stem_of() {
  _b=$(basename "$1")
  printf '%s' "${_b%.*}"
}

# ------------------------------------------------------------
# Start Fuse with the tape we just wrote, unless nofuse was
# given. Fuse 1.6.0 treats a .tap on the command line as a
# file to open. Auto-load is on by default, so the phantom
# typist types LOAD "" (or LOAD "" CODE) and the program
# starts. We do not pass a custom ROM: Fuse will not auto-load
# when one is set. --machine 48 keeps us on the 48K Spectrum
# the course uses, even if Fuse last ran as a 128K.
# ------------------------------------------------------------
start_fuse() {
  if [ "$NOFUSE" -eq 1 ]; then
    echo "Skipping Fuse (nofuse)."
    return 0
  fi
  if ! need_fuse; then
    echo "The tape was written, but Fuse could not be started."
    return 1
  fi
  if [ ! -f "$TAP" ]; then
    echo "Tape not found: $TAP"
    return 1
  fi

  echo "Starting Fuse:"
  # FUSE_FLAGS is optional extra arguments, for example
  # FUSE_FLAGS=--no-sound on a machine with no audio device.
  # --graphics-filter 3x is three times normal size. Fuse 1.6.0
  # lists Triple size (3x) for the GTK, Win32, Xlib and SDL UIs.
  # The SDL build resizes the window to match. FUSE_FLAGS is
  # passed after it, so extra options still work.
  echo "  $FUSE_CMD --machine 48 --auto-load --graphics-filter 3x ${FUSE_FLAGS:-} \"$TAP\""
  # Start in the background so the prompt comes back, as
  # windows-tools/build.bat does with "start". Redirect
  # Fuse's input and output so this script can exit even
  # if it is run from another script that captures output.
  # shellcheck disable=SC2086
  "$FUSE_CMD" --machine 48 --auto-load --graphics-filter 3x ${FUSE_FLAGS:-} "$TAP" </dev/null >/dev/null 2>&1 &
  FUSE_PID=$!
  disown "$FUSE_PID" 2>/dev/null || true
  echo "Fuse started (pid $FUSE_PID)."
  return 0
}

# ------------------------------------------------------------
# file.asm  -  pasmo --tapbas, then Fuse.
# ------------------------------------------------------------
build_asm() {
  if [ -n "$P2" ]; then
    echo "Unexpected extra argument: $P2"
    echo "For a .asm file, the only optional argument is -n or nofuse."
    echo
    usage
    exit 1
  fi
  if [ ! -f "$P1" ]; then
    echo "File not found: $P1"
    exit 1
  fi
  if ! need_tool pasmo pasmo; then
    exit 1
  fi

  TAP="$(dir_of "$P1")/$(stem_of "$P1").tap"
  # Tape name: the source file's name, up to 10 characters.
  # Without --name, pasmo uses the output path, which can be a
  # long directory name and looks wrong on the Spectrum.
  TAPNAME=$(cut_name "$(stem_of "$P1")")

  echo "Assembling with pasmo --tapbas:"
  echo "  pasmo --tapbas --name $TAPNAME \"$P1\" \"$TAP\""
  if ! pasmo --tapbas --name "$TAPNAME" "$P1" "$TAP"; then
    echo "pasmo failed."
    exit 1
  fi
  echo "Wrote $TAP"
  start_fuse || exit 1
}

# ------------------------------------------------------------
# file.bas [NAME] [LINE]  -  zmakebas, then Fuse.
# NAME is the name on the tape, at most 10 characters.
# LINE is the auto-start line. Defaults: the file's name, 10.
# ------------------------------------------------------------
build_bas() {
  if [ ! -f "$P1" ]; then
    echo "File not found: $P1"
    exit 1
  fi
  if ! need_tool zmakebas zmakebas; then
    exit 1
  fi

  NAME=$(cut_name "$(stem_of "$P1")")
  LINE=10
  if [ -n "$P2" ]; then
    NAME=$(cut_name "$P2")
  fi
  if [ -n "$P3" ]; then
    LINE=$P3
  fi

  TAP="$(dir_of "$P1")/$(stem_of "$P1").tap"

  echo "Converting BASIC with zmakebas:"
  echo "  zmakebas -a $LINE -n $NAME -o \"$TAP\" \"$P1\""
  if ! zmakebas -a "$LINE" -n "$NAME" -o "$TAP" "$P1"; then
    echo "zmakebas failed."
    exit 1
  fi
  echo "Wrote $TAP  (tape name: $NAME, auto-start: $LINE)"
  start_fuse || exit 1
}

# ------------------------------------------------------------
# driver.bas code.asm [NAME] [LINE]
#
# The BASIC driver is built with zmakebas. The machine code
# is assembled with pasmo --tap (code only, no BASIC loader).
# The two tapes are then joined with cat, driver first, which
# is how step 5 of Chapter 3 builds step5-examples.tap: the
# BASIC program runs, and its LOAD ""CODE loads the block
# that follows it on the tape.
#
# Intermediate files, kept so you can inspect them:
#   driver-driver.tap   the BASIC program alone
#   code-code.tap       the machine code alone
# The combined tape is driver.tap, next to the .bas file.
# ------------------------------------------------------------
build_combined() {
  if [ ! -f "$P1" ]; then
    echo "File not found: $P1"
    exit 1
  fi
  if [ ! -f "$P2" ]; then
    echo "File not found: $P2"
    exit 1
  fi
  if ! need_tool zmakebas zmakebas; then
    exit 1
  fi
  if ! need_tool pasmo pasmo; then
    exit 1
  fi

  NAME=$(cut_name "$(stem_of "$P1")")
  LINE=10
  if [ -n "$P3" ]; then
    NAME=$(cut_name "$P3")
  fi
  if [ -n "$P4" ]; then
    LINE=$P4
  fi

  DRIVER_TAP="$(dir_of "$P1")/$(stem_of "$P1")-driver.tap"
  CODE_TAP="$(dir_of "$P2")/$(stem_of "$P2")-code.tap"
  TAP="$(dir_of "$P1")/$(stem_of "$P1").tap"
  # Tape name for the code block: the assembler file's name, up to 10 characters.
  CODENAME=$(cut_name "$(stem_of "$P2")")

  echo "Assembling the machine code with pasmo --tap (no loader):"
  echo "  pasmo --tap --name $CODENAME \"$P2\" \"$CODE_TAP\""
  if ! pasmo --tap --name "$CODENAME" "$P2" "$CODE_TAP"; then
    echo "pasmo failed."
    exit 1
  fi
  echo "Wrote $CODE_TAP"

  echo "Converting the BASIC driver with zmakebas:"
  echo "  zmakebas -a $LINE -n $NAME -o \"$DRIVER_TAP\" \"$P1\""
  if ! zmakebas -a "$LINE" -n "$NAME" -o "$DRIVER_TAP" "$P1"; then
    echo "zmakebas failed."
    exit 1
  fi
  echo "Wrote $DRIVER_TAP  (tape name: $NAME, auto-start: $LINE)"

  echo "Joining the tapes, driver first, then code:"
  echo "  cat \"$DRIVER_TAP\" \"$CODE_TAP\" > \"$TAP\""
  if ! cat "$DRIVER_TAP" "$CODE_TAP" > "$TAP"; then
    echo "cat failed. The combined tape was not written."
    exit 1
  fi
  echo "Wrote $TAP"
  start_fuse || exit 1
}

# ------------------------------------------------------------
# Decide which kind of build this is, from the file extensions.
# ------------------------------------------------------------
if [ "$EXT1" = "asm" ]; then
  build_asm
elif [ "$EXT1" = "bas" ]; then
  if [ "$EXT2" = "asm" ]; then
    build_combined
  else
    build_bas
  fi
else
  echo "I do not know how to build \"$P1\""
  echo "Expected a .asm or .bas file, or a .bas driver followed by a .asm file."
  echo
  usage
  exit 1
fi
