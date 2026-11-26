; step5-examples.asm - Chapter 5, step 5
; The speaker, in small pieces. Example n starts at 50000+100*n.
; Driver: step5-examples.bas
;
; BASIC POKEs the inputs first:
;   50000-50001  delay   the pitch: a count, low byte first
;   50002        cycles  the length: whole cycles of the note
;   50003        note    a note number, 0 to 3, for example 2
;
; Example 1, 50100: one note from delay and cycles, border colour kept
; Example 2, 50200: note number 'note' from the table, as step5-sound.asm
; Example 3, 50300: one note, but with the border bits left at 0
; Example 4, 50400: BC = the border colour, from BORDCR
;
; Build:  tools/build.sh chapter-05-machine-code-games/step5-examples.bas chapter-05-machine-code-games/step5-examples.asm examples 10

bordcr: equ 23624

        org 50000

delay:  dw 255          ; 50000
cycles: db 3            ; 50002
note:   db 0            ; 50003

; Example 1: one note from the parameters.

        org 50100
        ld de,(delay)   ; DE = the delay count
        ld a,(cycles)
        ld b,a          ; B = the number of cycles
        ld a,(bordcr)
        rrca
        rrca
        rrca
        and 7
        ld c,a          ; C = the border colour
e1:     ld a,c
        or 16           ; speaker on
        out (254),a
        call dly
        ld a,c          ; speaker off
        out (254),a
        call dly
        djnz e1
        ret

; Example 2: the same, with the length and pitch from a table.

        org 50200
        ld a,(note)
        ld c,a
        add a,a
        add a,c         ; A = 3 * note
        ld e,a
        ld d,0
        ld hl,table
        add hl,de       ; HL = this note's entry
        ld e,(hl)
        inc hl
        ld d,(hl)       ; DE = delay
        inc hl
        ld b,(hl)       ; B = cycles
        ld a,(bordcr)
        rrca
        rrca
        rrca
        and 7
        ld c,a
e2:     ld a,c
        or 16
        out (254),a
        call dly
        ld a,c
        out (254),a
        call dly
        djnz e2
        ret

; Example 3: the same note as example 1, but the border bits are 0.

        org 50300
        ld de,(delay)
        ld a,(cycles)
        ld b,a
e3:     ld a,16         ; speaker on, border black
        out (254),a
        call dly
        xor a           ; speaker off, border black
        out (254),a
        call dly
        djnz e3
        ret

; Example 4: the border colour, 0 to 7.

        org 50400
        ld a,(bordcr)
        rrca
        rrca
        rrca
        and 7
        ld c,a
        ld b,0
        ret

        org 50500
dly:    ld h,d
        ld l,e
dl1:    dec hl
        ld a,h
        or l
        jr nz,dl1
        ret

table:  dw 255
        db 3
        dw 62
        db 10
        dw 126
        db 5
        dw 512
        db 1

        end
