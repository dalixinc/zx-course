; step6-examples.asm - Chapter 3, step 6
; Small examples, one idea each. Example n is at 50000+100*n.
; step6-examples.bas loads this and calls each one.
;
; Registers:
;   A  = a one-byte system variable; the character to print (RST 16)
;   B  = a loop counter (DJNZ); in pnum, 0 until a digit is printed
;   BC = the number handed back to BASIC; the number for the ROM
;        to print (examples 4, 5 and 11)
;   DE = STKEND (example 6); a system variable's address (example 9);
;        a power of ten (pnum)
;   HL = a two-byte value; where we are in a string or a table
;   IY is left alone.
;
; Build:  pasmo --tap --name excode step6-examples.asm step6-excode.tap

        org 50100
; Example 1: LD HL,(nn) reads a two-byte system variable.
ex1:    ld hl,(23730)   ; HL = RAMTOP, low byte from 23730, high from 23731
        ld b,h
        ld c,l          ; BC = HL, for USR
        ret

        org 50200
; Example 2: LD A,(nn) reads a one-byte system variable.
ex2:    ld a,(23693)    ; A = ATTR P
        ld c,a
        ld b,0          ; BC = A
        ret

        org 50300
; Example 3: open channel 2 and print two characters with RST 16.
ex3:    ld a,2
        call 5633       ; CHAN-OPEN: channel 2, the upper screen
        ld a,'H'
        rst 16          ; print the character in A
        ld a,'I'
        rst 16
        ret

        org 50400
; Example 4: the ROM prints BC: STACK-BC, then PRINT-FP.
ex4:    ld a,2
        call 5633
        ld bc,(23730)   ; BC = RAMTOP
        call 11563      ; STACK-BC: put BC on the calculator stack
        call 11747      ; PRINT-FP: print the number on top of it
        ret

        org 50500
; Example 5: OUT-NUM-1 prints BC, but only up to 9999.
ex5:    ld a,2
        call 5633
        ld bc,1234
        call 6683       ; OUT-NUM-1: prints 1234
        ld a,' '
        rst 16
        ld bc,12345
        call 6683       ; too big: watch what it prints
        ld a,' '
        rst 16
        ld bc,49999
        call 6683       ; and again
        ret

        org 50600
; Example 6: SBC HL,DE works out the free memory, RAMTOP-STKEND.
ex6:    ld hl,(23730)   ; HL = RAMTOP
        ld de,(23653)   ; DE = STKEND
        and a           ; clear the carry flag first
        sbc hl,de       ; HL = HL-DE
        ld b,h
        ld c,l
        ret

        org 50700
; Example 7: a string with control codes, printed by pstr.
ex7:    ld a,2
        call 5633
        ld hl,msg7
        call pstr
        ret
msg7:   db 20,1,"INVERSE",20,0," NORMAL",255

        org 50800
; Example 8: our own number printer, pnum.
ex8:    ld a,2
        call 5633
        ld hl,65367
        call pnum       ; prints 65367
        ld a,' '
        rst 16
        ld hl,0
        call pnum       ; prints 0, the units are always printed
        ld a,' '
        rst 16
        ld hl,7
        call pnum       ; prints 7, with no leading zeros
        ret

        org 50900
; Example 9: a table of addresses, read with LD E,(HL) / INC HL.
ex9:    ld a,2
        call 5633
        ld hl,tab9      ; HL = the start of the table
        ld b,3          ; B = 3 entries
loop9:  ld e,(hl)       ; E = the low byte of an address
        inc hl
        ld d,(hl)       ; DE = the address of a system variable
        inc hl          ; HL = the next entry
        push hl         ; keep the place in the table
        ld a,(de)       ; A = PEEK DE
        ld l,a
        inc de
        ld a,(de)       ; A = PEEK (DE+1)
        ld h,a          ; HL = the value
        call pnum
        ld a,' '
        rst 16
        pop hl
        djnz loop9
        ret
tab9:   dw 23635,23730,23675    ; PROG, RAMTOP, UDG

        org 51000
; Example 10: 100 numbers printed by pnum, to time it.
ex10:   ld a,2
        call 5633
        ld b,100
loop10: ld hl,at10
        call pstr       ; AT 21,26
        ld hl,65367
        call pnum       ; pnum keeps B
        djnz loop10
        ret
at10:   db 22,21,26,255

        org 51100
; Example 11: 100 numbers printed by the ROM, to time it.
ex11:   ld a,2
        call 5633
        ld b,100
loop11: push bc         ; the ROM routines change B
        ld hl,at10
        call pstr
        ld bc,65367
        call 11563      ; STACK-BC
        call 11747      ; PRINT-FP
        pop bc
        djnz loop11
        ret

        org 51200
; Example 12: 100 AT 21,26 and nothing else, to take away.
ex12:   ld a,2
        call 5633
        ld b,100
loop12: ld hl,at10
        call pstr
        djnz loop12
        ret

        org 51300
; Example 13: the ROM's CLS, 10 times, to time it.
ex13:   ld b,10
loop13: push bc
        call 3435       ; CLS
        pop bc
        djnz loop13
        ret

; pstr and pnum, the same as in step6-sysvars.asm.

        org 51400
pstr:   ld a,(hl)
        inc hl
        cp 255
        ret z
        rst 16
        jr pstr

pnum:   push bc
        push de
        ld b,0
        ld de,10000
        call digit
        ld de,1000
        call digit
        ld de,100
        call digit
        ld de,10
        call digit
        ld a,l
        add a,'0'
        rst 16
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
        jr nz,show
        inc b
        dec b
        ret z
show:   ld b,1
        rst 16
        ret
