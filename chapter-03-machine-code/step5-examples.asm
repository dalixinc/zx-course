; step5-examples.asm - Chapter 3, step 5
; Sixteen tiny examples, one idea each. Example n starts at 50000+100*n,
; so example 1 is at 50100, example 2 at 50200, and so on.
; The gaps between them are filled with zeros by pasmo.
;
; Registers, for every example:
;   BC = the answer handed back to BASIC by USR.
;        Examples that are about the flags end with PUSH AF / POP BC,
;        so B = A (the result) and C = F (the flags):
;        USR gives 256*A+F. In F, bit 6 is Z and bit 0 is C.
;   A  = the number being worked on.
;   HL = an address (example 2).
;   DE = a second number (example 10).
;
; Two bytes at 50000 pass numbers in and out:
;   50000 inbox:  BASIC POKEs a number here before the call.
;   50001 outbox: a routine stores its answer here; BASIC PEEKs it.
;
; Build:  pasmo --tap --name excode step5-examples.asm step5-excode.tap

        org 50000
inbox:  db 0
outbox: db 0

; ---- 1. LD r,n: B and C make BC. USR gives 1*256+2 = 258.
        org 50100
ex1:    ld b,1
        ld c,2
        ret

; ---- 2. LD with memory: copy the inbox to the outbox.
;         USR gives the number, and PEEK 50001 shows it too.
        org 50200
ex2:    ld a,(inbox)    ; A = the byte at 50000, like PEEK
        ld hl,outbox    ; HL = 50001
        ld (hl),a       ; store A at the address in HL, like POKE
        ld c,a
        ld b,0          ; BC = A
        ret

; ---- 3. ADD: 200+100 = 300, too big for a byte.
;         A = 300-256 = 44, and the carry flag is set.
        org 50300
ex3:    ld a,200
        add a,100
        push af
        pop bc          ; B = A, C = F
        ret

; ---- 4. SUB: 5-7 goes below zero.
;         A = 256-2 = 254, and the carry flag is set (a borrow).
        org 50400
ex4:    ld a,5
        sub 7
        push af
        pop bc
        ret

; ---- 5. INC: 255+1 wraps to 0. Z is set. INC leaves carry alone:
;         SCF sets carry first, and it is still set afterwards.
        org 50500
ex5:    scf             ; carry = 1
        ld a,255
        inc a           ; A = 0, Z = 1, carry unchanged
        push af
        pop bc
        ret

; ---- 6. DEC: 1-1 = 0. Z is set. DEC leaves carry alone too.
        org 50600
ex6:    scf
        ld a,1
        dec a           ; A = 0, Z = 1, carry unchanged
        push af
        pop bc
        ret

; ---- 7. CP and conditional jumps: compare the inbox with 100.
;         USR gives 0 if equal, 1 if less, 2 if more.
        org 50700
ex7:    ld a,(inbox)
        cp 100          ; work out A-100, set the flags, keep A
        jp z,same       ; Z: A was 100
        jr c,less       ; carry: A was less than 100
        ld bc,2         ; otherwise it was more
        ret
less:   ld bc,1
        ret
same:   ld bc,0
        ret

; ---- 8. DJNZ: add 10+9+8+...+1 = 55.
;         B counts down. DJNZ leaves B at 0, so BC = 55.
        org 50800
ex8:    ld b,10         ; B = loop counter
        ld a,0          ; A = running total
add8:   add a,b         ; A = A+B
        djnz add8       ; B = B-1, and go round again if B is not 0
        ld c,a          ; B is already 0, so BC = A
        ret

; ---- 9. CALL and RET: call a subroutine that doubles A, twice.
;         5 doubled is 10, doubled again is 20.
        org 50900
ex9:    ld a,5
        call double
        call double
        ld c,a
        ld b,0
        ret
double: add a,a         ; A = A+A
        ret             ; back to the instruction after the CALL

; ---- 10. PUSH and POP: the stack is last in, first out.
;          Push BC then DE, pop them back the other way round:
;          the two numbers swap, and USR gives 5678.
        org 51000
ex10:   ld bc,1234
        ld de,5678
        push bc         ; stack: 1234
        push de         ; stack: 5678 on top of 1234
        pop bc          ; BC = 5678, the last one pushed
        pop de          ; DE = 1234
        ret

; ---- 11. RLCA: rotate A left. Bit 7 goes to bit 0 and to carry.
;          10010110 becomes 00101101 (45), carry 1.
        org 51100
ex11:   ld a,%10010110
        rlca
        push af
        pop bc
        ret

; ---- 12. RRCA: rotate A right. Bit 0 goes to bit 7 and to carry.
;          10010110 becomes 01001011 (75), carry 0.
        org 51200
ex12:   ld a,%10010110
        rrca
        push af
        pop bc
        ret

; ---- 13. RLA: rotate left through carry. The old carry goes into
;          bit 0, and bit 7 goes into carry. OR A clears carry first.
;          10010110 becomes 00101100 (44), carry 1.
        org 51300
ex13:   ld a,%10010110
        or a            ; carry = 0, A unchanged
        rla
        push af
        pop bc
        ret

; ---- 14. RRA: rotate right through carry. The old carry goes into
;          bit 7, and bit 0 goes into carry. SCF sets carry first.
;          10010110 becomes 11001011 (203), carry 0.
        org 51400
ex14:   ld a,%10010110
        scf             ; carry = 1
        rra
        push af
        pop bc
        ret

; ---- 15. SLA: shift left. A 0 comes in at bit 0, bit 7 goes to carry.
;          It doubles A: 01001011 (75) becomes 10010110 (150), carry 0.
        org 51500
ex15:   ld a,%01001011
        sla a
        push af
        pop bc
        ret

; ---- 16. SRL: shift right. A 0 comes in at bit 7, bit 0 goes to carry.
;          It halves A: 01001011 (75) becomes 00100101 (37), carry 1,
;          the remainder.
        org 51600
ex16:   ld a,%01001011
        srl a
        push af
        pop bc
        ret
