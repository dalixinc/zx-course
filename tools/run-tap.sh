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
#   CAPTURE_SECS  how long to capture after LOAD, in seconds (default 30)
#   TAP_NAME     program name written on the tape (default: the listing's basename)
#   KEYS         space-separated xdotool key names to send while capturing,
#                for example KEYS="p p p p" to tap P four times (bat right).
#                O is left, P is right, the usual Spectrum game keys.
#   KEY_START    second in the capture loop at which to send the first key
#                (default 4, once the program has had time to start).
#   KEY_EVERY    seconds to wait between keys in KEYS (default 1)
#   KEY_HOLD     if set, hold this key down from KEY_START until KEY_HOLD_UNTIL
#                (for example KEY_HOLD=p). Sent in addition to KEYS, if both
#                are set. xdotool keyup is used at the end.
#   KEY_HOLD_UNTIL  second at which to release KEY_HOLD (default: end of capture).
# Screenshots are of the Fuse window, not the whole X display.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:-$ROOT/01-fill.bas}"
TAP="${SRC%.bas}.tap"
ROM="${ROM:-/usr/share/spectrum-roms/48.rom}"
DISPLAY_NUM="${DISPLAY_NUM:-99}"
SHOT_DIR="${SHOT_DIR:-/tmp/zx-course-shots}"
CAPTURE_SECS="${CAPTURE_SECS:-30}"
TAP_NAME="${TAP_NAME:-$(basename "${SRC%.bas}")}"
KEYS="${KEYS:-}"
KEY_START="${KEY_START:-4}"
KEY_EVERY="${KEY_EVERY:-1}"
KEY_HOLD="${KEY_HOLD:-}"
KEY_HOLD_UNTIL="${KEY_HOLD_UNTIL:-}"

command -v zmakebas >/dev/null
command -v fuse >/dev/null
command -v xdotool >/dev/null
command -v scrot >/dev/null

zmakebas -a 10 -n "$TAP_NAME" -o "$TAP" "$SRC"
echo "Wrote $TAP (name: $TAP_NAME)"

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
echo "Capturing $CAPTURE_SECS seconds of screenshots to $SHOT_DIR"
if [ -n "$KEYS" ]; then
  echo "Will send keys: $KEYS (from t=$KEY_START, every $KEY_EVERY s)"
fi
if [ -n "$KEY_HOLD" ]; then
  echo "Will hold key: $KEY_HOLD (from t=$KEY_START until ${KEY_HOLD_UNTIL:-end})"
fi

# KEYS is a space-separated list; an empty value must not trip set -u.
KEY_LIST=()
if [ -n "$KEYS" ]; then
  # shellcheck disable=SC2206
  KEY_LIST=($KEYS)
fi
key_idx=0
next_key_at="$KEY_START"
hold_down=0
hold_done=0

for i in $(seq -w 0 "$CAPTURE_SECS"); do
  sleep 1
  if ! ps -p "$(cat /tmp/zx-course-fuse.pid)" >/dev/null; then
    echo "Fuse exited at t=$i"
    cat /tmp/zx-course-fuse.log >&2 || true
    break
  fi
  i_num=$((10#$i))
  if [ -n "$KEY_HOLD" ] && [ "$hold_done" -eq 0 ] && [ "$hold_down" -eq 0 ] && [ "$i_num" -ge "$KEY_START" ]; then
    xdotool windowfocus --sync "$WID" 2>/dev/null || true
    xdotool keydown --window "$WID" "$KEY_HOLD"
    echo "Held key $KEY_HOLD at t=$i"
    hold_down=1
  fi
  if [ "$hold_down" -eq 1 ] && [ -n "$KEY_HOLD_UNTIL" ] && [ "$i_num" -ge "$KEY_HOLD_UNTIL" ]; then
    xdotool keyup --window "$WID" "$KEY_HOLD" 2>/dev/null || true
    echo "Released key $KEY_HOLD at t=$i"
    hold_down=0
    hold_done=1
  fi
  if [ "$key_idx" -lt "${#KEY_LIST[@]}" ] && [ "$i_num" -ge "$next_key_at" ]; then
    k="${KEY_LIST[$key_idx]}"
    xdotool windowfocus --sync "$WID" 2>/dev/null || true
    xdotool key --window "$WID" "$k"
    echo "Sent key $k at t=$i"
    key_idx=$((key_idx+1))
    next_key_at=$((i_num + KEY_EVERY))
  fi
  scrot -w "$WID" "$SHOT_DIR/t$i.png"
done

if [ "$hold_down" -eq 1 ]; then
  xdotool keyup --window "$WID" "$KEY_HOLD" 2>/dev/null || true
  echo "Released key $KEY_HOLD"
fi

echo "Fuse is still running (pid $(cat /tmp/zx-course-fuse.pid)). Kill it with:"
echo "  kill -9 \$(cat /tmp/zx-course-fuse.pid)"
