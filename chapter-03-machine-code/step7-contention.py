#!/usr/bin/env python3
# step7-contention.py - Chapter 3, step 7 (optional extra)
#
# Adds up the T-states of 250 fills by each of step 7's routines, the way
# a 48K Spectrum runs them: first with no contention (the fill at 60000),
# then with the ULA's contended-memory delays (the fill at 22528).
#
# The contention rules are the ones on the Sinclair Wiki page
# "Contended memory" (16K and 48K section and the instruction breakdown):
#   - 69888 T-states in a frame, 224 in a line.
#   - Memory from 16384 to 32767 is contended. 14335 T-states after the
#     interrupt, and for 128 T-states of each of the 192 screen lines,
#     an access there waits 6,5,4,3,2,1,0,0 T-states, repeating every 8.
#   - Our code is at 50000, so instruction fetches are never delayed.
#     Only the accesses that put a screen address on the bus are.
# It leaves out the ROM's interrupt routine and the BASIC around the call,
# so it should come out a little under what Fuse measures.
#
# Run:  python3 step7-contention.py

FRAME = 69888


def delay(t):
    t %= FRAME
    if t < 14335 or t >= 14335 + 192 * 224:
        return 0
    off = (t - 14335) % 224
    if off >= 128:
        return 0
    return [6, 5, 4, 3, 2, 1, 0, 0][off % 8]


class Clock:
    def __init__(self):
        self.t = 0

    def free(self, n):                  # n T-states with no screen access
        self.t += n

    def access(self, n, screen):        # n T-states, first one may wait
        if screen:
            self.t += delay(self.t)
        self.t += n


def loop_fill(c, screen):
    c.free(13 + 4 + 16 + 10)            # ld a,(nn) / ld e,a / ld hl,(nn) / ld bc,nn
    for i in range(768):
        c.free(4)
        c.access(3, screen)             # ld (hl),e: fetch 4, write 3
        c.free(6 + 6 + 4 + 4)           # inc hl / dec bc / ld a,b / or c
        c.free(12 if i < 767 else 7)    # jr nz: 12 if it jumps, 7 if not
    c.free(4 + 12)                      # dec d / jr nz,frep


def ldir_fill(c, screen):
    c.free(11 + 13 + 16 + 4)            # push af / ld a,(nn) / ld hl,(nn) / fetch
    c.access(3, screen)                 # ld (hl),a: write 3
    c.free(20 + 6 + 10)                 # ld de,(nn) / inc de / ld bc,nn
    for i in range(767):                # ldir, one byte at a time
        c.free(8)                       # fetch ED B0
        c.access(3, screen)             # read (HL)
        c.access(3, screen)             # write (DE)
        for _ in range(2):              # 2 T-states with DE on the bus
            c.access(1, screen)
        if i < 766:                     # 5 more, only when it repeats
            for _ in range(5):
                c.access(1, screen)
    c.free(10 + 4 + 12)                 # pop af / dec a / jr nz,lrep


for name, routine in (("LOOP", loop_fill), ("LDIR", ldir_fill)):
    for screen in (True, False):
        c = Clock()
        for _ in range(250):
            routine(c, screen)
        where = "SCREEN" if screen else "60000 "
        print(f"{where}  {name}  {c.t:8d} T-states  {c.t / FRAME:6.1f} frames"
              f"  {c.t // 250:6d} per fill")
