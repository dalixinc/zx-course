#!/bin/bash
# Build a .tap from a Sinclair BASIC listing and run it in Fuse (48K),
# headless, under Xvfb. Types LOAD "" for you (Return, j, Alt+P, Alt+P, Return).
#
# Usage:
#   tools/run-tap.sh [listing.bas]
# Default listing: 01-fill.bas in the course root.
#
# Environment:
#   DISPLAY_NUM  X display to use (default 99). An Xvfb is started if needed.
#   ROM          48K ROM file (default /usr/share/spectrum-roms/48.rom)
#   SHOT_DIR     directory for timestamped screenshots (default /tmp/zx-course-shots)
#   SECONDS      how long to capture after LOAD (default 30)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:-$ROOT/01-fill.bas}"
TAP="${SRC%.bas}.tap"
ROM="${ROM:-/usr/share/spectrum-roms/48.rom}"
DISPLAY_NUM="${DISPLAY_NUM:-99}"
SHOT_DIR="${SHOT_DIR:-/tmp/zx-course-shots}"
SECONDS="${SECONDS:-30}"

command -v zmakebas >/dev/null
command -v fuse >/dev/null
command -v xdotool >/dev/null
command -v scrot >/dev/null

zmakebas -a 10 -n "$(basename "${SRC%.bas}")" -o "$TAP" "$SRC"
echo "Wrote $TAP"

if ! xdpyinfo -display ":$DISPLAY_NUM" >/dev/null 2>&1; then
  Xvfb ":$DISPLAY_NUM" -screen 0 800x600x24 >/tmp/zx-course-xvfb.log 2>&1 &
  echo $! > /tmp/zx-course-xvfb.pid
  sleep 0.4
fi
export DISPLAY=":$DISPLAY_NUM"
export SDL_AUDIODRIVER=dummy
export LIBGL_ALWAYS_SOFTWARE=1

# Drop any previous Fuse emulator (not other processes named similarly).
for p in $(ps -eo pid,comm | awk '$2=="fuse"{print $1}'); do kill -9 "$p" 2>/dev/null || true; done

fuse --no-sound --machine 48 --rom-48 "$ROM" --auto-load --traps "$TAP" \
  >/tmp/zx-course-fuse.log 2>&1 &
echo $! > /tmp/zx-course-fuse.pid
sleep 2

WID="$(xdotool search --name Fuse | head -1)"
if [ -z "$WID" ]; then
  echo "Fuse window not found" >&2
  exit 1
fi
xdotool windowfocus --sync "$WID" 2>/dev/null || true
# Leave the copyright screen, then type LOAD "" and Enter.
# Alt is Symbol Shift in Fuse, so Alt+P is the Spectrum double-quote.
xdotool key --window "$WID" --delay 150 Return
sleep 0.6
xdotool key --window "$WID" --delay 150 j
sleep 0.5
xdotool key --window "$WID" --delay 150 alt+p alt+p
sleep 0.5
xdotool key --window "$WID" --delay 150 Return

mkdir -p "$SHOT_DIR"
echo "Capturing $SECONDS seconds of screenshots to $SHOT_DIR"
for i in $(seq -w 0 "$SECONDS"); do
  sleep 1
  if ! ps -p "$(cat /tmp/zx-course-fuse.pid)" >/dev/null; then
    echo "Fuse exited at t=$i"
    cat /tmp/zx-course-fuse.log >&2 || true
    break
  fi
  scrot "$SHOT_DIR/t$i.png"
done

echo "Fuse is still running (pid $(cat /tmp/zx-course-fuse.pid)). Kill it with:"
echo "  kill -9 \$(cat /tmp/zx-course-fuse.pid)"
