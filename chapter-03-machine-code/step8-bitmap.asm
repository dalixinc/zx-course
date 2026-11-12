; step8-bitmap.asm - Chapter 3, step 8
; The bitmap fill in machine code: the twin of step 2's bitmap fill.
; Four routines that fill 6144 bytes, called from BASIC, and two small
; screen-address routines (next line down, attribute address) with test
; entry points so BASIC can try them.
;
; BASIC passes its choices in through five parameter bytes at the start:
;   50000  pattern  the byte to fill with (step 2 used 170, 10101010)
;   50001  times    how many fills to do, 1 to 255 (0 means 256)
;   50002  where    two bytes, the first address, low byte first
;                   (16384, the bitmap; 6144 bytes from here are filled)
;   50004  slow     HALTs after each line of 32 bytes in rows and sdown,
;                   0 for none (full speed), 1 or more to slow them down
;
; Entry points:
;   RANDOMIZE USR 50005  fill   loop over 6144 bytes, in memory order
;   RANDOMIZE USR 50030  fldir  LDIR, in memory order
;   RANDOMIZE USR 50056  rows   192 lines of 32 bytes, in memory order
;   RANDOMIZE USR 50085  sdown  192 lines of 32 bytes, in screen order,
;                               top to bottom, using nxtdn
;   PRINT USR 50155      tdown  next line down from where, in BC
;   PRINT USR 50164      tattr  attribute address for where, in BC
;   PRINT USR 50173      tincl  where after INC L, in BC
;   PRINT USR 50180      tinch  where after INC H, in BC
;
; Registers in fill:
;   HL = the address being filled
;   BC = bytes still to fill, 6144 down to 0
;   D  = fills still to do
;   E  = the pattern
;   A  = a scratch copy of B, for the zero test
;
; Registers in fldir:
;   HL = the address LDIR copies from (one byte behind DE)
;   DE = the address LDIR copies to
;   BC = bytes still to copy, 6143 down to 0
;   A  = the pattern, then the count of fills (kept on the stack)
;
; Registers in rows and sdown:
;   HL = the address being filled
;   B  = bytes still to fill in this line, 32 down to 0
;   C  = lines still to fill, 192 down to 0
;   D  = HALTs still to do after this line
;   E  = (sdown only) L at the start of the line
;   A  = the pattern, then scratch
;   the count of fills is kept on the stack
;
; nxtdn: in HL = a bitmap address; out HL = the address one pixel line
;   down. A is changed. attr: in HL = a bitmap address; out HL = the
;   address of the attribute for that cell. A is changed.
;
; Build:  pasmo --tap --name bitcode step8-bitmap.asm step8-bitcode.tap
; It is loaded by the drivers, step8-bitmap.bas and step8-examples.bas,
; with LOAD ""CODE.

        org 50000

pattern: db 170         ; 50000: the pattern, POKEd by BASIC
times:  db 1            ; 50001: how many fills
where:  dw 16384        ; 50002-50003: where to start
slow:   db 0            ; 50004: HALTs per line in rows and sdown

; 1. The loop: step 7's loop, with 6144 bytes instead of 768.

fill:   ld a,(times)    ; A = how many fills
        ld d,a          ; D = fills still to do
frep:   ld a,(pattern)  ; A = the pattern BASIC POKEd
        ld e,a          ; E = the pattern, because the loop needs A
        ld hl,(where)   ; HL = first address to fill
        ld bc,6144      ; BC = 6144 bytes to fill
floop:  ld (hl),e       ; fill one byte
        inc hl          ; next address
        dec bc          ; one fewer to do
        ld a,b
        or c            ; Z is set only when BC = 0
        jr nz,floop     ; not zero: next byte
        dec d           ; one fewer fill to do
        jr nz,frep      ; not zero: fill again
        ret

; 2. LDIR: fill the first byte, then copy it along 6143 times.

fldir:  ld a,(times)    ; A = how many fills
lrep:   push af         ; keep the count on the stack
        ld a,(pattern)  ; A = the pattern BASIC POKEd
        ld hl,(where)   ; HL = first address
        ld (hl),a       ; fill the first byte by hand
        ld de,(where)
        inc de          ; DE = the next address, HL+1
        ld bc,6143      ; BC = the other 6143 bytes
        ldir            ; copy (HL) to (DE), HL+1, DE+1, BC-1, until BC = 0
        pop af          ; A = the count again
        dec a           ; one fewer fill to do
        jr nz,lrep      ; not zero: fill again
        ret

; 3. rows: 192 lines of 32 bytes, in memory order. The next line is
;    simply the next address, so this fills in the same order as fill.

rows:   ld a,(times)    ; A = how many fills
rrep:   push af         ; keep the count on the stack
        ld hl,(where)   ; HL = first address
        ld c,192        ; C = 192 lines to fill
rline:  ld a,(pattern)  ; A = the pattern
        ld b,32         ; B = 32 bytes in a line
rbyte:  ld (hl),a       ; fill one byte
        inc hl          ; next address
        djnz rbyte      ; B-1; not zero: next byte
        call wait       ; HALT if BASIC asked for it
        dec c           ; one fewer line to do
        jr nz,rline     ; not zero: next line
        pop af          ; A = the count again
        dec a           ; one fewer fill to do
        jr nz,rrep      ; not zero: fill again
        ret

; 4. sdown: 192 lines of 32 bytes, in screen order, top to bottom.
;    The same as rows, except for how it gets to the next line.

sdown:  ld a,(times)    ; A = how many fills
srep:   push af         ; keep the count on the stack
        ld hl,(where)   ; HL = first address, the top line
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

; wait: HALT slow times (none if slow is 0). Each HALT waits for the
; next interrupt, a fiftieth of a second. Changes A and D.

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

; attr: the attribute address for a bitmap address. In: HL in the
; bitmap. Out: HL = 22528 + 32 * character row + column. Changes A.

attr:   ld a,h
        rrca
        rrca
        rrca            ; TT is now in bits 0 and 1
        and 3           ; keep TT
        or 88           ; 88 is $58, the attributes' high byte
        ld h,a          ; L is already CCCXXXXX
        ret

; Test entries for BASIC: PRINT USR gives back BC.

tdown:  ld hl,(where)   ; HL = the address BASIC POKEd
        call nxtdn
        ld b,h
        ld c,l          ; BC = the answer, for USR
        ret

tattr:  ld hl,(where)   ; HL = the address BASIC POKEd
        call attr
        ld b,h
        ld c,l          ; BC = the answer, for USR
        ret

tincl:  ld hl,(where)   ; HL = the address BASIC POKEd
        inc l           ; one column to the right
        ld b,h
        ld c,l          ; BC = the answer, for USR
        ret

tinch:  ld hl,(where)   ; HL = the address BASIC POKEd
        inc h           ; one pixel line down
        ld b,h
        ld c,l          ; BC = the answer, for USR
        ret

        end
