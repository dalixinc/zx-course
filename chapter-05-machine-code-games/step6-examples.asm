; step6-examples.asm - Chapter 5, step 6
; Printing from machine code, in small pieces. Example n starts at
; 50000+100*n. Driver: step6-examples.bas
;
; BASIC POKEs the inputs first:
;   50000        row     the row to print at, 0 to 21
;   50001        col     the column, 0 to 31
;   50002        chr     a character code, 32 to 127
;   50003-50004  num     a number, 0 to 65535
;   50005        lives   a digit, 0 to 9
;
; Example 1, 50100: ROM print of one character at row, col, by RST 16
; Example 2, 50200: ROM print of a string with AT inside it (pstr)
; Example 3, 50300: ROM print of the number num at row, col (pnum)
; Example 4, 50400: the game's status line: SCORE num, LIVES lives
; Example 5, 50500: our own print of one character, with put, at row, col
; Null, 50700: just RET, to time a call from BASIC that does nothing
;
; Build:  tools/build.sh chapter-05-machine-code-games/step6-examples.bas chapter-05-machine-code-games/step6-examples.asm examples 10

chanopen: equ 5633      ; ROM: open the channel for the stream in A
chars:    equ 23606     ; system variable: the character set, less 256

        org 50000

row:    db 0            ; 50000
col:    db 0            ; 50001
chr:    db 65           ; 50002
num:    dw 0            ; 50003
lives:  db 3            ; 50005

; Example 1: AT row,col and then the character, as four bytes to RST 16.

        org 50100
        ld a,2          ; the upper screen,
        call chanopen   ; the stream RST 16 prints to
        ld a,22         ; the code for AT
        rst 16
        ld a,(row)
        rst 16          ; AT's first byte: the row
        ld a,(col)
        rst 16          ; AT's second byte: the column
        ld a,(chr)
        rst 16          ; the character itself
        ret

; Example 2: a string, ending in 255, with an AT inside it.

        org 50200
        ld a,2
        call chanopen
        ld hl,msg
        jp pstr         ; print it, and pstr returns for us

; Example 3: AT row,col, then the number.

        org 50300
        ld a,2
        call chanopen
        ld a,22
        rst 16
        ld a,(row)
        rst 16
        ld a,(col)
        rst 16
        ld hl,(num)
        jp pnum         ; the number, with no leading zeros

; Example 4: the status line of the game.

        org 50400
        ld a,2
        call chanopen
        ld hl,stext1    ; AT 0,1; "SCORE "
        call pstr
        ld hl,(num)
        call pnum
        ld hl,stext2    ; AT 0,22; "LIVES "
        call pstr
        ld a,(lives)
        add a,'0'       ; a digit's character code
        rst 16
        ret

; Example 5: our own print. The character set is in the ROM, eight
; bytes to a character, from (chars)+256. Copy the eight bytes of the
; character with put, as the game copies its ball.

        org 50500
        ld a,(chr)
        ld l,a
        ld h,0          ; HL = the character code
        add hl,hl
        add hl,hl
        add hl,hl       ; HL = 8 * the code
        ld de,(chars)
        add hl,de       ; HL = the character's 8 bytes
        ex de,hl        ; DE = the graphic, as put wants it
        ld a,(row)
        ld b,a
        ld a,(col)
        ld c,a
        jp put

; The routines the examples share.

        org 50600
pstr:   ld a,(hl)
        inc hl
        cp 255          ; the end marker?
        ret z
        rst 16
        jr pstr

pnum:   push bc
        push de
        ld b,0          ; B = 0: no digit printed yet
        ld de,10000
        call digit
        ld de,1000
        call digit
        ld de,100
        call digit
        ld de,10
        call digit
        ld a,l          ; what is left is 0 to 9, the units
        add a,'0'
        rst 16          ; always print the units, even 0
        pop de
        pop bc
        ret

digit:  ld a,'0'-1
dloop:  inc a
        and a
        sbc hl,de
        jr nc,dloop
        add hl,de
        cp '0'
        jr nz,dshow
        inc b
        dec b           ; Z is set if B is 0
        ret z           ; a leading zero: print nothing
dshow:  ld b,1
        rst 16
        ret

put:    call cell       ; HL = the top byte of the cell
        ld b,8
pline:  ld a,(de)
        ld (hl),a
        inc de
        inc h
        djnz pline
        ret

cell:   ld a,b
        and 24
        or 64
        ld h,a
        ld a,b
        and 7
        rrca
        rrca
        rrca
        or c
        ld l,a
        ret

        org 50700
        ret             ; the call that does nothing

        org 50800
msg:    db 22,20,2,"A STRING, ENDED BY 255",255
stext1: db 22,0,1,"SCORE ",255
stext2: db 22,0,22,"LIVES ",255

        end
