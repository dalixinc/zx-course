; step15-examples.asm - Chapter 5, step 15
; The pieces of moving by pixels: the pixel line address, the base
; shifted into place at run time and drawn with XOR, the same from
; eight copies shifted in advance, and drawing with a mask instead of
; XOR, over a patterned background. pixad and nxtdn are copied from
; step15-pixels.asm, and the base's picture with them.
;
; BASIC POKEs the inputs first:
;   50000  yl     a pixel line, 0 to 191
;   50001  col    a byte column, 0 to 31 (Example 1)
;   50002  xp     a pixel column, 0 to 248 (Examples 2 to 4)
;   50003  times  how many times to draw (Examples 2 and 3), 1 to 255
;
; Example 1 at 50100: BC = the screen address of line yl, column col
; Example 2 at 50200: XOR the base at line yl, pixel xp, shifting it
;                     at run time, times times
; Example 3 at 50300: the same, from the shifted copies, times times
; Example 4 at 50400: draw the base with its mask at line yl, pixel xp
; Example 5 at 50500: make the eight shifted copies and the masks
;                     (BASIC calls it once first)
;
; Build:  tools/build.sh chapter-05-machine-code-games/step15-examples.bas chapter-05-machine-code-games/step15-examples.asm examples 20

        org 50000

yl:     db 0            ; 50000
col:    db 0            ; 50001
xp:     db 0            ; 50002
times:  db 1            ; 50003

; Example 1: the address of a pixel line.

        org 50100
        ld a,(yl)
        ld b,a
        ld a,(col)
        ld c,a
        call pixad      ; HL = the address
        ld b,h
        ld c,l          ; BC, for USR
        ret

; Example 2: shift at run time, and XOR.

        org 50200
        ld a,(times)
        ld b,a
ex2:    push bc
        call drawrt     ; one draw
        pop bc
        djnz ex2
        ret

; Example 3: from the shifted copies, and XOR.

        org 50300
        ld a,(times)
        ld b,a
ex3:    push bc
        call drawps
        pop bc
        djnz ex3
        ret

; Example 4: with a mask.

        org 50400
        jp drawmk

; Example 5: make the shifted copies of the base and of its mask.

        org 50500
        jp mkcopy

        org 50600

; leftad: HL = the address of the byte with the base's left-hand pixel,
; at line yl, pixel xp; A = the shift, xp AND 7. Changes B, C.

leftad: ld a,(xp)
        rrca
        rrca
        rrca
        and 31
        ld c,a          ; the byte column
        ld a,(yl)
        ld b,a
        call pixad
        ld a,(xp)
        and 7           ; the shift
        ret

; drawrt: XOR the base at yl, xp, shifting each line at run time, as
; step15-pixels.asm's basex does, but with nxtdn so any line will do.

drawrt: call leftad
        ld de,base
        ld b,8          ; 8 lines
rt1:    push bc
        ld b,a          ; B = the shift
        push af
        ld a,(de)       ; this line of the base
        ld c,0          ; what spills into the next byte
        inc b
        dec b           ; is the shift 0?
        jr z,rt3
rt2:    srl a           ; one pixel right
        rr c            ; the pixel that falls off, into C
        djnz rt2
rt3:    xor (hl)
        ld (hl),a       ; the left-hand byte
        inc l
        ld a,c
        xor (hl)
        ld (hl),a       ; the right-hand byte
        dec l
        call nxtdn      ; the next line down
        inc de
        pop af          ; the shift again
        pop bc
        djnz rt1
        ret

; drawps: XOR the base at yl, xp from the copy already shifted by
; xp AND 7: 16 bytes, two for each line, left then right.

drawps: call leftad
        add a,a
        add a,a
        add a,a
        add a,a         ; A = 16 * shift
        ld e,a
        ld d,0
        push hl
        ld hl,copies
        add hl,de
        ex de,hl        ; DE = the copy for this shift
        pop hl
        ld b,8
ps1:    ld a,(de)
        xor (hl)
        ld (hl),a       ; the left-hand byte
        inc de
        inc l
        ld a,(de)
        xor (hl)
        ld (hl),a       ; the right-hand byte
        inc de
        dec l
        call nxtdn
        djnz ps1
        ret

; drawmk: draw the base at yl, xp with its mask: on each byte, AND the
; screen with the mask, which clears a border one pixel wide round the
; base and the base itself, then OR the base in. What was under it is
; gone; what is round it is left.

drawmk: call leftad
        add a,a
        add a,a
        add a,a
        add a,a         ; A = 16 * shift
        ld e,a
        ld d,0
        push hl
        ld hl,copies
        add hl,de
        push hl
        ld hl,masks
        add hl,de
        ld b,h
        ld c,l          ; BC = this shift's mask
        pop de          ; DE = this shift's copy
        pop hl
        ld a,8
mk1:    push af
        ld a,(bc)
        and (hl)        ; clear the mask's 0 bits
        ex de,hl
        or (hl)         ; and put the base's 1 bits in
        ex de,hl
        ld (hl),a       ; the left-hand byte
        inc bc
        inc de
        inc l
        ld a,(bc)
        and (hl)
        ex de,hl
        or (hl)
        ex de,hl
        ld (hl),a       ; the right-hand byte
        inc bc
        inc de
        dec l
        call nxtdn
        pop af
        dec a
        jr nz,mk1
        ret

; mkcopy: fill copies with the base shifted 0 to 7 pixels right, two
; bytes a line, and masks with a mask for each: the base's pixels and
; the pixels either side of them, inverted, so that 0 means clear it.

mkcopy: ld hl,copies
        ld ix,masks
        ld c,0          ; C = the shift
mc1:    ld de,base
        ld b,8          ; 8 lines
mc2:    push bc
        ld a,(de)       ; this line
        ld b,c
        ld c,0
        inc b
        dec b
        jr z,mc4
mc3:    srl a
        rr c
        djnz mc3
mc4:    ld (hl),a       ; the left-hand byte
        inc hl
        ld (hl),c       ; the right-hand byte
        ; the mask: OR the pair with itself shifted one pixel each way
        ld b,a          ; B, C = the pair
        push hl
        ld h,b
        ld l,c          ; HL = the pair, 16 pixels
        push hl
        add hl,hl       ; one pixel left
        ld a,h
        or b
        ld b,a
        ld a,l
        or c
        ld c,a
        pop hl
        srl h
        rr l            ; one pixel right
        ld a,h
        or b
        cpl             ; 0 where there is base or a border
        ld (ix+0),a
        ld a,l
        or c
        cpl
        ld (ix+1),a
        inc ix
        inc ix
        pop hl
        inc hl
        inc de
        pop bc
        djnz mc2
        inc c
        ld a,c
        cp 8
        jr nz,mc1
        ret

; pixad: HL = the address of pixel line B, byte column C. Changes A.

pixad:  ld a,b
        and 7
        or 64
        ld h,a
        ld a,b
        rrca
        rrca
        rrca
        and 24
        or h
        ld h,a          ; H = 010 y7 y6 y2 y1 y0
        ld a,b
        rlca
        rlca
        and 224
        or c
        ld l,a          ; L = y5 y4 y3 and the column
        ret

; nxtdn: HL = the address one pixel line below. Changes A.

nxtdn:  inc h
        ld a,h
        and 7
        ret nz
        ld a,l
        add a,32
        ld l,a
        ret c
        ld a,h
        sub 8
        ld h,a
        ret

base:   db 24,24,24,126,255,255,255,255
copies: ds 128          ; 8 shifts, 8 lines, 2 bytes
masks:  ds 128

        end
