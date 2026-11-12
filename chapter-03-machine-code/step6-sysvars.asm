; step6-sysvars.asm - Chapter 3, step 6
; The system variables, read from machine code: the twin of step 1.
; It prints the same table as step 1 (after CLEAR 49999), with the
; ROM's print routine, and times itself with FRAMES.
;
; Registers:
;   A  = the character to print (RST 16); a one-byte system variable
;   B  = rows of the table still to print (row loop, with DJNZ);
;        in pnum, 0 until the first digit has been printed
;   DE = the address of a system variable (row loop);
;        a power of ten, 10000 down to 10 (pnum);
;        STKEND, or the start time (for the subtractions)
;   HL = where we are in a string or in the table (pstr, row loop);
;        the number to print (pnum)
;   IY is left alone: the ROM needs it, and so does BASIC.
;
; Build:  pasmo --tapbas --name sysvars step6-sysvars.asm step6-sysvars.tap
; The loader does CLEAR 49999, loads the code to 50000 and runs it.
; Press ENTER to go back to BASIC.

        org 50000

start:  ld hl,(23672)   ; HL = FRAMES, the low two bytes
        ld (t0),hl      ; keep it: the start time

        ld a,0
        out (254),a     ; BORDER 0
        ld a,7
        ld (23693),a    ; ATTR P = 7: PAPER 0, INK 7
        ld (23624),a    ; BORDCR = 7: border 0, lower screen ink 7
        call 3435       ; the ROM's CLS
        ld a,2
        call 5633       ; open channel 2, the upper screen

        ld hl,fixed     ; the title, the fixed map, the heading
        call pstr

        ld hl,table     ; HL = the first row of the table
        ld b,7          ; B = 7 rows
row:    call pstr       ; AT row,0; name; TAB 7 - HL moves past it
        ld e,(hl)       ; E = low byte of the address
        inc hl
        ld d,(hl)       ; D = high byte: DE = the system variable
        inc hl          ; HL = the next row of the table
        push hl         ; keep the place in the table
        ld h,d
        ld l,e          ; HL = DE, the address
        call pnum       ; print the address
        ld hl,tab14
        call pstr       ; TAB 14
        ld a,(de)       ; A = PEEK DE, the low byte
        ld l,a
        inc de
        ld a,(de)       ; A = PEEK (DE+1), the high byte
        ld h,a          ; HL = the two-byte value
        call pnum       ; print the value
        pop hl          ; HL = the next row of the table
        djnz row        ; B = B-1; round again until all 7 are done

        ld hl,free
        call pstr       ; AT 14,0;"FREE";TAB 14
        ld hl,(23730)   ; HL = RAMTOP
        ld de,(23653)   ; DE = STKEND
        and a           ; clear the carry flag
        sbc hl,de       ; HL = RAMTOP-STKEND
        call pnum

        ld hl,chars
        call pstr       ; AT 20,0;"CHARS "
        ld hl,(23606)   ; HL = CHARS, two bytes
        call pnum
        ld hl,attrp
        call pstr       ; "  ATTR P "
        ld a,(23693)    ; A = ATTR P, one byte
        ld l,a
        ld h,0          ; HL = A
        call pnum
        ld hl,bordcr
        call pstr       ; "  BORDCR "
        ld a,(23624)    ; A = BORDCR, one byte
        ld l,a
        ld h,0
        call pnum

        ld hl,(23672)   ; HL = FRAMES now
        ld de,(t0)      ; DE = FRAMES at the start
        and a
        sbc hl,de       ; HL = frames taken so far
        push hl         ; pstr needs HL
        ld hl,took
        call pstr       ; AT 16,0;"TABLE TOOK "
        pop hl
        call pnum
        ld hl,frms
        call pstr       ; " FRAMES"

        ld a,0
        ld (23560),a    ; LAST K = 0, so the ENTER that started us is gone
live:   ld hl,frames
        call pstr       ; AT 21,0;"FRAMES "
        ld hl,(23672)   ; FRAMES, read in one instruction
        call pnum
        ld hl,lastk
        call pstr       ; "  LAST K "
        ld a,(23560)    ; A = LAST K
        ld l,a
        ld h,0
        call pnum
        ld hl,spaces
        call pstr       ; "   ", to wipe out old digits
        ld a,(23560)
        cp 13           ; was the last key ENTER?
        jr nz,live      ; no: go round again
        ret             ; yes: back to BASIC

; pstr - print a string, ending with the byte 255
; In:  HL = the address of the string
; Out: HL = the address just after the 255
; Uses A. The string can hold control codes: 22,row,col is AT,
; 23,col,0 is TAB, 20,1 and 20,0 are INVERSE 1 and INVERSE 0.
pstr:   ld a,(hl)       ; A = the next byte of the string
        inc hl
        cp 255          ; the end marker?
        ret z           ; yes: done
        rst 16          ; no: print it
        jr pstr

; pnum - print HL in decimal, with no leading zeros
; In:  HL = the number, 0 to 65535
; Uses A and HL. BC and DE are saved and given back.
pnum:   push bc
        push de
        ld b,0          ; B = 0: no digit printed yet
        ld de,10000
        call digit      ; the ten thousands
        ld de,1000
        call digit      ; the thousands
        ld de,100
        call digit      ; the hundreds
        ld de,10
        call digit      ; the tens
        ld a,l          ; what is left is 0 to 9, the units
        add a,'0'       ; turn it into a character code
        rst 16          ; always print the units, even 0
        pop de
        pop bc
        ret

; digit - print how many times DE goes into HL, and leave the rest in HL
; In:  HL = the number, DE = a power of ten, B = 0 if no digit yet
; Out: HL = HL minus that many DE, B = 1 if a digit was printed
digit:  ld a,'0'-1      ; A = one less than the code for "0"
dloop:  inc a           ; one more DE goes in
        and a           ; clear the carry flag
        sbc hl,de       ; HL = HL-DE; carry set if it went below 0
        jr nc,dloop     ; no carry: try again
        add hl,de       ; one too many: put it back
        cp '0'          ; is the digit 0?
        jr nz,show      ; no: print it
        inc b
        dec b           ; Z is set if B is 0
        ret z           ; a leading zero: print nothing
show:   ld b,1          ; from now on, print every digit
        rst 16
        ret

; The data. 22 = AT, 23 = TAB, 20 = INVERSE, 255 = the end.

t0:     dw 0            ; FRAMES at the start

fixed:  db 22,0,0,20,1," 48K MEMORY MAP EXPLORER        ",20,0
        db 22,1,0,"0-16383     ROM"
        db 22,2,0,"16384-22527 SCREEN BITMAP"
        db 22,3,0,"22528-23295 ATTRIBUTES"
        db 22,4,0,"23296-23551 PRINTER BUFFER"
        db 22,5,0,"23552-23733 SYSTEM VARIABLES"
        db 22,6,0,20,1,"NAME   AT     VALUE             ",20,0,255

; One row: AT row,0; the name; TAB 7; then the address of the variable.
table:  db 22,7,0,"PROG",23,7,0,255
        dw 23635
        db 22,8,0,"VARS",23,7,0,255
        dw 23627
        db 22,9,0,"E LINE",23,7,0,255
        dw 23641
        db 22,10,0,"STKEND",23,7,0,255
        dw 23653
        db 22,11,0,"RAMTOP",23,7,0,255
        dw 23730
        db 22,12,0,"UDG",23,7,0,255
        dw 23675
        db 22,13,0,"P RAMT",23,7,0,255
        dw 23732

tab14:  db 23,14,0,255
free:   db 22,14,0,"FREE",23,14,0,255
chars:  db 22,20,0,"CHARS ",255
attrp:  db "  ATTR P ",255
bordcr: db "  BORDCR ",255
took:   db 22,16,0,"TABLE TOOK ",255
frms:   db " FRAMES",255
frames: db 22,21,0,"FRAMES ",255
lastk:  db "  LAST K ",255
spaces: db "   ",255

        end start
