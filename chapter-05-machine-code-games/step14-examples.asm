; step14-examples.asm - Chapter 5, step 14
; Three of the game's new pieces: pdec, which prints a number as decimal
; digits; ptext and pchar, which print text from the ROM's character
; set; and the sums newwave does for each wave's row and speed. They
; are copied from step14-game.asm, with put and cell, which pchar needs.
;
; BASIC POKEs the inputs first:
;   50000        row     the screen row to print on
;   50001        col     the screen column to start at
;   50002-50003  num     the number for Example 1
;   50004        digits  how many digits, 1 to 5
;   50005        wave    the wave for Example 3
;   50006        bfirst  the block's top row on wave 1
;   50007        mfirst  passes per march step on wave 1
;
; Example 1 at 50100: print num in digits digits at row, col
; Example 2 at 50200: print a line of text at row, col
; Example 3 at 50300: BC = 256 * the wave's top row + its passes per
;                     march step
;
; Build:  tools/build.sh chapter-05-machine-code-games/step14-examples.bas chapter-05-machine-code-games/step14-examples.asm examples 20

font:   equ 15360       ; the ROM's characters, 8 bytes each, less 256

        org 50000

row:    db 0            ; 50000
col:    db 0            ; 50001
num:    dw 0            ; 50002
digits: db 5            ; 50004
wave:   db 1            ; 50005
bfirst: db 1            ; 50006
mfirst: db 25           ; 50007
pdn:    db 0            ; 50008: pdec's count of digits left

; Example 1: a number.

        org 50100
        ld a,(row)
        ld b,a
        ld a,(col)
        ld c,a          ; B, C = where to print
        ld hl,(num)     ; HL = the number
        ld a,(digits)   ; A = how many digits
        jp pdec         ; and pdec returns to BASIC

; Example 2: text.

        org 50200
        ld a,(row)
        ld b,a
        ld a,(col)
        ld c,a
        ld hl,text
        jp ptext

text:   db "ROM LETTERS: ABC abc 0123 !?*",255

; Example 3: the wave's row and speed, as newwave works them out.

        org 50300
        ld a,(wave)
        dec a
        ld hl,bfirst
        add a,(hl)      ; A = bfirst + wave - 1
        cp 9            ; row 8 or above?
        jr c,nw1        ; yes: that is the row
        ld a,(hl)       ; no: row 8, unless bfirst itself is lower
        cp 9
        jr nc,nw1
        ld a,8
nw1:    ld d,a          ; D = the row
        ld a,(wave)
        ld b,a          ; B = the wave
        ld a,(mfirst)   ; A = the speed on wave 1
nw2:    dec b           ; a wave after the first?
        jr z,nw3        ; no: A is the speed
        cp 7            ; would 3 less be under 4?
        jr c,nw3        ; yes: keep it
        sub 3           ; no: 3 passes a step faster
        jr nw2
nw3:    ld c,a          ; C = the speed
        ld b,d          ; B = the row
        ret

        org 50400

; pdec: print HL as A decimal digits, 1 to 5, with zeros in front, at
; row B, column C. Each digit is how many times its power of ten can be
; taken away. Changes A, B, C, DE, HL.

pdec:   ld (pdn),a      ; the digits to print
        neg
        add a,5         ; A = 5 - digits: the powers to skip
        add a,a         ; two bytes each
        ld e,a
        ld d,0
        push hl         ; keep the number
        ld hl,tens
        add hl,de
        ex de,hl        ; DE = the first power to use
        pop hl
pd1:    push de         ; keep the place in the table
        ex de,hl        ; HL = the place, DE = the number
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a          ; HL = this power of ten
        ex de,hl        ; HL = the number, DE = the power
        ld a,'0'-1      ; the digit, one below "0"
pd2:    inc a           ; one more
        and a           ; clear the carry for SBC
        sbc hl,de       ; take the power away
        jr nc,pd2       ; not below 0 yet: again
        add hl,de       ; once too often: put it back
        push hl         ; keep what is left
        push bc         ; and the cell
        call pchar      ; print the digit
        pop bc
        pop hl
        inc c           ; the next column
        pop de
        inc de
        inc de          ; the next power of ten
        ld a,(pdn)
        dec a
        ld (pdn),a      ; one digit fewer to go
        jr nz,pd1
        ret

; ptext: print the text at HL, which ends with 255, from row B, column
; C, across. Changes A, DE, HL.

ptext:  ld a,(hl)       ; the next character
        cp 255          ; the end marker?
        ret z           ; yes: done
        push hl
        push bc
        call pchar      ; print it
        pop bc
        pop hl
        inc hl
        inc c           ; the next column
        jr ptext

; pchar: draw character A, 32 to 127, at row B, column C, from the
; ROM's character set: 8 bytes a character, at 15360 + 8 * code.
; Changes A, B, DE, HL.

pchar:  ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl       ; HL = 8 * code
        ld de,font
        add hl,de
        ex de,hl        ; DE = the character's 8 bytes
        jp put          ; draw them, and put returns

; put: copy the 8 bytes at DE into the cell at row B, column C.
; Changes A, B, DE and HL.

put:    call cell       ; HL = the top byte of the cell
        ld b,8          ; 8 pixel lines in a cell
pline:  ld a,(de)       ; A = one line of the graphic
        ld (hl),a       ; onto the screen
        inc de
        inc h           ; next pixel line down the cell
        djnz pline
        ret

; cell: HL = the screen address of the top line of the cell at row B,
; column C: 010TT000 RRRCCCCC. Changes A.

cell:   ld a,b          ; A = 000TTRRR
        and 24          ; A = 000TT000
        or 64           ; A = 010TT000
        ld h,a
        ld a,b
        and 7           ; A = 00000RRR
        rrca
        rrca
        rrca            ; A = RRR00000
        or c            ; A = RRRCCCCC
        ld l,a
        ret


; The powers of ten for pdec.

tens:   dw 10000,1000,100,10,1

        end
