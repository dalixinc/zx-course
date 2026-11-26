; step2-examples.asm - Chapter 5, step 2
; Two small routines that read one half-row of the keyboard with IN.
; The driver, step2-examples.bas, calls them for all eight half-rows,
; over and over, so you can hold keys down and watch the bits change.
;
; BASIC POKEs the half-row first:
;   50000  half  the high byte of the port: 254, 253, 251, 247, 239,
;                223, 191 or 127
;
; Example 1 at 50100: BC = the five key bits as IN reads them (0 = held)
; Example 2 at 50200: BC = the same bits turned over with CPL (1 = held)
;
; Build:  tools/build.sh chapter-05-machine-code-games/step2-examples.bas chapter-05-machine-code-games/step2-examples.asm examples 10

        org 50000

half:   db 254          ; 50000: the half-row to read

        org 50100
        ld a,(half)     ; A = the half-row, the top half of the port
        in a,(254)      ; read port A*256+254
        and 31          ; keep bits 0 to 4, the five keys
        ld c,a
        ld b,0
        ret

        org 50200
        ld a,(half)
        in a,(254)
        cpl             ; turn every bit over: 1 = held
        and 31
        ld c,a
        ld b,0
        ret

        end
