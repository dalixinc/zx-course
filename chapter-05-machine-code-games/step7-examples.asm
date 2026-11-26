; step7-examples.asm - Chapter 5, step 7
; Reading more than one half-row of the keyboard.
; The driver, step7-examples.bas, calls examples 1 and 2 over and over
; while you hold keys, and then times example 3.
;
; BASIC POKEs the half-rows first:
;   50000  half  the high byte of the port; every 0 bit chooses a
;                half-row, so 0 chooses all eight
;
; Example 1 at 50100: BC = the five key bits of the half-rows in half,
;                     1 = held in any of them
; Example 2 at 50200: BC = the game's key mask: bit 0 P, bit 1 O,
;                     bit 2 Space, bit 3 Q
; Example 3 at 50300: calls the mask routine 10000 times, for timing
;
; Build:  tools/build.sh chapter-05-machine-code-games/step7-examples.bas chapter-05-machine-code-games/step7-examples.asm examples 10

        org 50000

half:   db 0            ; 50000: the half-rows to read

        org 50100
        ld a,(half)     ; A = the half-rows: one 0 bit for each
        in a,(254)      ; every chosen half-row answers at once
        cpl             ; 1 = held
        and 31          ; keep the five key bits
        ld c,a
        ld b,0
        ret

        org 50200
        call rkeys      ; A = the key mask
        ld c,a
        ld b,0
        ret

        org 50300
        halt            ; start just after a frame begins
        ld de,10000     ; 10000 times
tloop:  call rkeys
        dec de
        ld a,d
        or e            ; DE = 0?
        jr nz,tloop
        ld bc,0
        ret

; rkeys: read every key the game uses, in one go, and give back one
; bit for each that is held: bit 0 P, bit 1 O, bit 2 Space, bit 3 Q.
; It is the routine in step7-base.asm. Changes A and C.

rkeys:  ld a,223        ; half-row P, O, I, U, Y
        in a,(254)      ; bit 0 is P, bit 1 is O; 0 means held
        cpl             ; now 1 means held
        and 3           ; keep P and O: bits 0 and 1 already
        ld c,a
        ld a,127        ; half-row Space, Sym Shift, M, N, B
        in a,(254)
        cpl
        and 1           ; Space is bit 0
        add a,a
        add a,a         ; move it to bit 2
        or c
        ld c,a
        ld a,251        ; half-row Q, W, E, R, T
        in a,(254)
        cpl
        and 1           ; Q is bit 0
        rlca
        rlca
        rlca            ; move it to bit 3
        or c
        ret

        end
