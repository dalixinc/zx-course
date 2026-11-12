#!/usr/bin/env python3
# step8-contention.py - Chapter 3, step 8 (optional extra)
#
# Adds up the T-states of 50 fills by each of step 8's four routines,
# without contention (the fill at 32768) and with it (the fill at 16384),
# by the same Sinclair Wiki rules as step7-contention.py. Only the writes
# to the screen can wait: the code is at 50000, and INC HL and DJNZ put
# uncontended addresses on the bus. Leaves out the ROM's interrupt routine
# and the BASIC around the call, so Fuse should be 2 to 4 frames over.
#
# Run:  python3 step8-contention.py

FRAME = 69888


def delay(t):
    t %= FRAME
    if t < 14335 or t >= 14335 + 192 * 224 or (t - 14335) % 224 >= 128:
        return 0
    return [6, 5, 4, 3, 2, 1, 0, 0][(t - 14335) % 8]


def run(steps, screen):
    # steps: a list of numbers; a number n is n T-states that never wait,
    # and ("w", n) is n T-states whose first one may wait (a screen access)
    t = waits = 0
    for s in steps:
        if isinstance(s, tuple):
            d = delay(t) if screen else 0
            t, waits = t + d, waits + d
            s = s[1]
        t += s
    return t, waits


def nxtdn(line):                        # T-states for the call, by line
    return 26 if (line + 1) % 8 else (65 if (line + 1) % 64 else 46)


def loop():
    s = [43]                            # ld a,(nn) / ld e,a / ld hl,(nn) / ld bc,nn
    for i in range(6144):               # ld (hl),e / inc hl / dec bc / ld a,b / or c / jr nz
        s += [4, ("w", 3), 20, 12 if i < 6143 else 7]
    return s + [16]                     # dec d / jr nz,frep


def ldir():
    s = [44, ("w", 3), 36]              # set-up, with ld (hl),a
    for i in range(6143):               # fetch, read, write, 2 (+5) with DE on the bus
        s += [8, ("w", 3), ("w", 3)] + [("w", 1)] * (2 if i == 6142 else 7)
    return s + [26]                     # pop af / dec a / jr nz,lrep


def lines(step, extra):                 # rows (step 6, inc hl) or sdown (step 4, inc l)
    s = [34]                            # push af / ld hl,(nn) / ld c,n
    for line in range(192):
        s += [20 + extra(0)]            # ld a,(nn) / ld b,n (and ld e,l in sdown)
        for i in range(32):             # ld (hl),a / inc / djnz
            s += [4, ("w", 3), step, 13 if i < 31 else 8]
        s += [extra(line + 1) + 45 + 4 + (12 if line < 191 else 7)]
    return s + [26]                     # pop af / dec a / jr nz


ROUTINES = (("LOOP", loop()), ("LDIR", ldir()),
            ("ROWS", lines(6, lambda n: 0)),
            ("DOWN", lines(4, lambda n: 4 if n == 0 else 4 + 17 + nxtdn(n - 1))))

for name, steps in ROUTINES:
    for screen in (False, True):
        t, w = run(steps * 50, screen)
        where = "SCREEN" if screen else "32768 "
        print(f"{name}  {where}  {t / FRAME:6.1f} frames  waiting {w / FRAME:5.1f}")
