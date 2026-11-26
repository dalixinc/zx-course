; step16-examples.asm - Chapter 5, step 16
; The joystick byte, turned into the keys' bits. The routine at 50100 is
; the part of rkeys that reads port 31, with the IN taken out: it works on
; the byte BASIC pokes into raw, so every case can be tried without a
; joystick, and gives back the bits to OR into the keys, or 0 if the
; byte cannot be from a Kempston.
;
;   50000  raw   a byte, as port 31 would give it
;
; Example 1 at 50100: BC = the keys' bits for raw: 1 right, 2 left,
;                     4 fire (the bit Space has), or 0
; Example 2 at 50200: BC = what port 31 gives now, in the same way as
;                     rkeys, with the IN
;
; Build:  tools/build.sh chapter-05-machine-code-games/step16-examples.bas chapter-05-machine-code-games/step16-examples.asm examples 20

kport:  equ 31          ; the Kempston joystick's port

        org 50000

raw:    db 0            ; 50000

        org 50100

; Example 1: a byte in raw to the keys' bits.

        ld a,(raw)
        call conv
        ld b,0
        ld c,a
        ret

        org 50200

; Example 2: the live port.

        in a,(kport)
        call conv
        ld b,0
        ld c,a
        ret

        org 50300

; conv: A = a Kempston byte, 000FUDLR with 1 for pressed. Out: A = bit 0
; right, bit 1 left, bit 2 fire; 0 for a byte with any of its top three
; bits set. Changes C.

conv:   cp 32           ; any of the top three bits set?
        jr nc,nok       ; then it is not a Kempston: ignore it
        ld c,0          ; C will be the keys' bits
        bit 4,a         ; fire?
        jr z,c1
        set 2,c         ; yes: as if Space were held
c1:     and 3           ; right and left are bits 0 and 1, like P and O
        or c
        ret
nok:    xor a
        ret

        end
