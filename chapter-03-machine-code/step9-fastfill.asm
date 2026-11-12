; step9-fastfill.asm - Chapter 3, step 9
; The fast interactive fill: the machine code under step 3's questions.
; Three entry points that fill the screen, called from step9-fastfill.bas.
; The LDIR fill is steps 7 and 8's, made into one routine for both jobs;
; sdown, nxtdn and wait are step 8's, unchanged except that sdown always
; starts at 16384.
;
; BASIC passes its choices in through four parameter bytes at the start:
;   50000  pattern  the bitmap byte, built from the 8 digits you type
;   50001  colour   the attribute byte, 64*bright + 8*paper + ink
;   50002  times    how many fills to do, 1 to 255 (0 means 256)
;   50003  slow     HALTs after each line in sdown, 0 for full speed
;
; Entry points:
;   RANDOMIZE USR 50004  bitmap  the bitmap, LDIR, in memory order
;   RANDOMIZE USR 50015  attrs   the attributes, LDIR
;   RANDOMIZE USR 50043  sdown   the bitmap, in screen order, top down
;
; Registers in bitmap and attrs, on the way into ldfill:
;   A  = the byte to fill with
;   HL = the first address to fill
;   BC = how many bytes LDIR copies, one fewer than the length
;
; Registers in ldfill:
;   HL = the address LDIR copies from (one byte behind DE)
;   DE = the address LDIR copies to
;   BC = bytes still to copy, down to 0
;   A  = the count of fills
;   HL, BC and the count are kept on the stack while LDIR runs
;
; Registers in sdown:
;   HL = the address being filled
;   B  = bytes still to fill in this line, 32 down to 0
;   C  = lines still to fill, 192 down to 0
;   D  = HALTs still to do after this line
;   E  = L at the start of the line
;   A  = the pattern, then scratch
;   the count of fills is kept on the stack
;
; Build:  pasmo --tap --name fastcode step9-fastfill.asm step9-fastcode.tap
; It is loaded by the driver, step9-fastfill.bas, with LOAD ""CODE.

        org 50000

pattern: db 170         ; 50000: the pattern, POKEd by BASIC
colour: db 56           ; 50001: the attribute, POKEd by BASIC
times:  db 1            ; 50002: how many fills
slow:   db 0            ; 50003: HALTs per line in sdown

; The bitmap: 6144 bytes from 16384, with the pattern.

bitmap: ld a,(pattern)  ; A = the pattern BASIC POKEd
        ld hl,16384     ; HL = the first byte of the bitmap
        ld bc,6143      ; BC = the other 6143 bytes
        jr ldfill       ; fill them

; The attributes: 768 bytes from 22528, with the colour.

attrs:  ld a,(colour)   ; A = the colour BASIC POKEd
        ld hl,22528     ; HL = the first attribute
        ld bc,767       ; BC = the other 767 cells
                        ; and on into ldfill

; ldfill: put A in the first byte at HL, then copy it along BC more
; bytes with LDIR, and do that (times) times. Changes A, BC, DE, HL.

ldfill: ld (hl),a       ; the first byte, by hand, once
        ld a,(times)    ; A = how many fills
lrep:   push af         ; keep the count
        push hl         ; keep the start
        push bc         ; keep the length
        ld d,h
        ld e,l          ; DE = HL
        inc de          ; DE = the next address, HL+1
        ldir            ; copy (HL) to (DE), HL+1, DE+1, BC-1, until BC = 0
        pop bc          ; BC = the length again
        pop hl          ; HL = the start again
        pop af          ; A = the count again
        dec a           ; one fewer fill to do
        jr nz,lrep      ; not zero: fill again
        ret

; sdown: step 8's fill in screen order, top to bottom.

sdown:  ld a,(times)    ; A = how many fills
srep:   push af         ; keep the count on the stack
        ld hl,16384     ; HL = the top line of the screen
        ld c,192        ; C = 192 lines to fill
sline:  ld a,(pattern)  ; A = the pattern
        ld b,32         ; B = 32 bytes in a line
        ld e,l          ; E = L at the start of the line
sbyte:  ld (hl),a       ; fill one byte
        inc l           ; one column to the right
        djnz sbyte      ; B-1; not zero: next byte
        ld l,e          ; back to the start of the line
        call nxtdn      ; HL = the start of the line below
        call wait       ; HALT if BASIC asked for it
        dec c           ; one fewer line to do
        jr nz,sline     ; not zero: next line
        pop af          ; A = the count again
        dec a           ; one fewer fill to do
        jr nz,srep      ; not zero: fill again
        ret

; wait: HALT slow times (none if slow is 0). Changes A and D.

wait:   ld a,(slow)     ; A = HALTs to do
        and a           ; is it 0?
        ret z           ; yes: no waiting
        ld d,a          ; D = HALTs still to do
whalt:  halt            ; wait for the next interrupt
        dec d
        jr nz,whalt
        ret

; nxtdn: the next pixel line down. In: HL in the bitmap. Out: HL one
; pixel line lower. Changes A.

nxtdn:  inc h           ; down one pixel line (RRR + 1)
        ld a,h
        and 7           ; still inside the same cell?
        ret nz          ; yes: done
        ld a,l
        add a,32        ; next character row (CCC + 1)
        ld l,a
        ret c           ; carry: crossed into the next third, H is right
        ld a,h
        sub 8           ; same third: undo the carry into TT
        ld h,a
        ret

        end
