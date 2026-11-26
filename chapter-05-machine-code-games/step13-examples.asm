; step13-examples.asm - Chapter 5, step 13
; The shields' two routines: shat, which turns a screen cell into a
; byte of the damage map, and chip, which takes a level off it and
; draws the cell. They are copied from step13-shields.asm, with shdraw,
; put, cell and attr, which chip needs.
;
; BASIC POKEs the inputs first:
;   50000  row   a screen row
;   50001  col   a screen column
;   50002  shy   set by shat: 0 top, 1 bottom row of a shield
;   50003  shx   set by shat: 0, 1 or 2 across
;   50004  chips counted by chip
;   50500  shmap the damage map, 24 bytes
;
; Example 1 at 50100: BC = the cell's place in the map, 0 to 23, or
;                     65535 if it is not a shield cell
; Example 2 at 50200: BC = the cell's new level if chip took one off,
;                     or 255 if there was nothing to chip
;
; Build:  tools/build.sh chapter-05-machine-code-games/step13-examples.bas chapter-05-machine-code-games/step13-examples.asm examples 20

shrow:  equ 18          ; the shields' top row
green:  equ 4           ; INK 4, PAPER 0

        org 50000

row:    db 0            ; 50000
col:    db 0            ; 50001
shy:    db 0            ; 50002
shx:    db 0            ; 50003
chips:  db 0            ; 50004

; Example 1: where in the map?

        org 50100
        ld a,(row)
        ld b,a
        ld a,(col)
        ld c,a
        call shat       ; HL = its byte, or the carry if none
        ld bc,65535
        ret c           ; not a shield cell
        ld de,shmap
        and a
        sbc hl,de       ; HL = its place in the map
        ld b,h
        ld c,l
        ret

; Example 2: chip it.

        org 50200
        ld a,(row)
        ld b,a
        ld a,(col)
        ld c,a
        call chip       ; carry set if it chipped
        ld bc,255
        ret nc          ; nothing to chip
        ld a,(row)
        ld b,a
        ld a,(col)
        ld c,a
        call shat       ; A = the new level
        ld c,a
        ld b,0
        ret

; The routines, from step13-shields.asm.

        org 50250

shat:   ld a,b
        sub shrow       ; A = row - 18
        cp 2            ; 0 or 1? Rows above 18 go round to 255 or so
        jr nc,noshl     ; no: not a shield row
        ld (shy),a
        ld a,c
        sub 3           ; A = column - 3, round to 253 or more left of 3
        cp 27           ; 0 to 26: from the first shield to the last
        jr nc,noshl
        ld e,a
        and 7           ; A = the place in a group of eight columns
        cp 3            ; 0, 1 or 2 is a shield; 3 to 7 is a gap
        jr nc,noshl
        ld (shx),a
        ld d,a          ; D = the place across, 0 to 2
        ld a,e
        rrca
        rrca
        rrca
        and 3           ; A = the shield, 0 to 3
        ld e,a
        add a,a
        add a,e         ; A = 3 * shield
        add a,d         ; A = 3 * shield + place: 0 to 11
        ld e,a
        ld a,(shy)
        and a           ; the top row?
        jr z,shtop
        ld a,e
        add a,12        ; the bottom row's 12 bytes come after the top's
        ld e,a
shtop:  ld d,0
        ld hl,shmap
        add hl,de       ; HL = its byte in the map
        ld a,(hl)       ; A = its level
        and a           ; zero flag from the level; the carry is clear
        ret
noshl:  scf             ; not a shield cell
        ret
shdraw: cp 3
        jr c,shworn     ; below 3: the same three pictures for every cell
        ld a,(shy)
        ld e,a
        add a,a
        add a,e         ; A = 3 * shy
        ld hl,shx
        add a,(hl)      ; A = 3 * shy + shx, 0 to 5
        add a,3         ; the shapes come after the three worn pictures
shworn: add a,a         ; two bytes an address
        ld e,a
        ld d,0
        ld hl,shgfx
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)       ; DE = the picture
        call attr
        ld (hl),green   ; green, the base's ink
        jp put
chip:   call shat
        jr c,nochip     ; not a shield cell
        jr z,nochip     ; a hole: level 0
        dec (hl)        ; one level less
        ld a,(hl)
        call shdraw     ; draw it at the new level
        ld hl,chips
        inc (hl)        ; one more chip
        scf             ; eaten
        ret
nochip: and a           ; clear the carry
        ret
put:    call cell       ; HL = the top byte of the cell
        ld b,8          ; 8 pixel lines in a cell
pline:  ld a,(de)       ; A = one line of the graphic
        ld (hl),a       ; onto the screen
        inc de
        inc h           ; next pixel line down the cell
        djnz pline
        ret
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
attr:   ld a,b          ; A = 000TTRRR
        rrca
        rrca
        rrca            ; A = RRR000TT
        and 3           ; A = 000000TT, the third
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

shgfx:  dw blank,gO,gN ; levels 0, 1 and 2
        dw gK,gJ,gL  ; level 3, top row: corner, block, corner
        dw gJ,gM,gJ  ; level 3, bottom row: block, arch, block

gJ:    db 126,255,255,255,255,255,255,126 ; UDG J, a full block
gK:    db 15,31,63,127,255,255,255,255 ; UDG K, the top-left corner
gL:    db 240,248,252,254,255,255,255,255 ; UDG L, the top-right corner
gM:    db 255,255,255,231,195,195,195,195 ; UDG M, the arch
gN:    db 110,219,189,118,221,183,111,218 ; UDG N, damaged
gO:    db 74,144,37,66,148,9,82,136 ; UDG O, badly damaged
blank:  db 0,0,0,0,0,0,0,0

        org 50500
shmap:  db 3,3,3,3,3,3,3,3,3,3,3,3 ; 50500: the top row
        db 3,3,3,3,3,3,3,3,3,3,3,3 ; the bottom row

        end
