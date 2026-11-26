; step4-examples.asm - Chapter 5, step 4
; Random number sources, one routine each. Example n starts at
; 50000+100*n and hands its answer back in BC. Driver: step4-examples.bas
;
;   50000  seed  the LFSR state, POKEd by BASIC
;
; Example 1, 50100: the LFSR with eight shifts, as step4-random.asm
; Example 2, 50200: LD A,R once
; Example 3, 50300: the low byte of FRAMES
; Example 4, 50400: LD A,R sixteen times in a tight loop, into 50700 on
; Example 5, 50500: the LFSR with one shift
;
; Build:  tools/build.sh chapter-05-machine-code-games/step4-examples.bas chapter-05-machine-code-games/step4-examples.asm examples 10

        org 50000

seed:   db 1            ; 50000

        org 50100       ; example 1: eight shifts
        ld a,(seed)
        ld b,8
e1:     srl a
        jr nc,e1b
        xor 184
e1b:    djnz e1
        ld (seed),a
        ld c,a
        ld b,0
        ret

        org 50200       ; example 2: R once
        ld a,r
        ld c,a
        ld b,0
        ret

        org 50300       ; example 3: FRAMES
        ld a,(23672)    ; the low byte of FRAMES
        ld c,a
        ld b,0
        ret

        org 50400       ; example 4: R in a tight loop
        ld hl,50700
        ld b,16
e4:     ld a,r
        ld (hl),a
        inc hl
        djnz e4
        ret

        org 50500       ; example 5: one shift
        ld a,(seed)
        srl a
        jr nc,e5
        xor 184
e5:     ld (seed),a
        ld c,a
        ld b,0
        ret

        end
