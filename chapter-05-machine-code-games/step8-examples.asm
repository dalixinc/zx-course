; step8-examples.asm - Chapter 5, step 8
; Two small ideas the shot uses: INC A as a test for 255, and a call
; that is only made when a flag says so.
;
; BASIC POKEs the input first:
;   50000  val    the byte to test
;   50001  count  how many times bump has run
;
; Example 1 at 50100: BC = 1 if val is 255, 0 if not, with INC A
; Example 2 at 50200: the same with CP 255
; Example 3 at 50300: calls bump with CALL NZ if val is not 0;
;                     BC = count afterwards
;
; Build:  tools/build.sh chapter-05-machine-code-games/step8-examples.bas chapter-05-machine-code-games/step8-examples.asm examples 20

        org 50000

val:    db 0            ; 50000: the byte to test
count:  db 0            ; 50001: times bump has run

        org 50100
        ld a,(val)
        inc a           ; 255 + 1 = 0, and the zero flag is set
        ld bc,0         ; ld does not change the flags
        ret nz          ; not 255: BC = 0
        inc c           ; 255: BC = 1
        ret

        org 50200
        ld a,(val)
        cp 255          ; the zero flag is set if A = 255
        ld bc,0
        ret nz
        inc c
        ret

        org 50300
        ld a,(val)
        and a           ; the zero flag is set if A = 0
        call nz,bump    ; not 0: call bump; 0: go straight on
        ld a,(count)
        ld c,a
        ld b,0          ; BC = count
        ret

bump:   ld hl,count
        inc (hl)        ; one more call
        ret

        end
