; step3-examples.asm - Chapter 5, step 3
; Three small routines for the lesson. Example n starts at 50000+100*n
; and hands its answer back in BC. The driver is step3-examples.bas.
;
; BASIC POKEs the inputs first:
;   50000  col   a column, 0 to 31   (col and row are read as a pair)
;   50001  row   a row, 0 to 23
;   50002-50003  pair  example 3 writes BC here
;
; Build:  tools/build.sh chapter-05-machine-code-games/step3-examples.bas chapter-05-machine-code-games/step3-examples.asm examples 10

        org 50000

col:    db 0            ; 50000
row:    db 0            ; 50001
pair:   dw 0            ; 50002

; Example 1: BC = the attribute address of (row, col).

        org 50100
        ld bc,(col)     ; C = col, B = row
        call attr
        ld b,h
        ld c,l          ; BC = HL, for USR
        ret

; Example 2: BC = the attribute byte of (row, col), as ATTR gives it.

        org 50200
        ld bc,(col)
        call attr
        ld c,(hl)       ; C = the attribute
        ld b,0
        ret

; Example 3: LD (nn),BC. Put 2*256+7 in BC and store it at pair:
; 50002 gets 7 (C) and 50003 gets 2 (B).

        org 50300
        ld bc,2*256+7   ; B = 2, C = 7
        ld (pair),bc    ; C to 50002, B to 50003
        ret

; attr: HL = the attribute address of row B, column C. The same code as
; step3-bricks.asm. Changes A.

        org 50400
attr:   ld a,b          ; A = 000TTRRR
        rrca
        rrca
        rrca            ; A = RRR000TT
        and 3           ; A = 000000TT
        or 88           ; A = 010110TT
        ld h,a
        ld a,b
        and 7           ; A = 00000RRR
        rrca
        rrca
        rrca            ; A = RRR00000
        or c            ; A = RRRCCCCC
        ld l,a
        ret

        end
