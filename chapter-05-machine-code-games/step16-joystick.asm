; step16-joystick.asm - Chapter 5, step 16
; A Kempston joystick, beside the keys. It is step 15's game, with one
; change: if joy is 1, rkeys also reads the Kempston port, 31, and ORs
; right, left and fire into the same bits as P, O and Space. Either the
; keys or the stick can be used, or both. Up and down are not used.
; A port with nothing on it gives back rubbish, so a byte with any of
; its top three bits set, which a Kempston never sends, is ignored.
;
; BASIC can set or read these bytes at the start of the code:
;   50000        halts   HALTs per pass of the loop; 0 means do not wait
;   50001        bspeed  passes per look at the keys, 1 to 255
;   50002        sspeed  passes per step of the shot, 1 to 255
;   50003-50004  moves   times the base has moved
;   50005-50006  passes  passes of the loop
;   50007-50008  ssteps  steps the shot has taken
;   50009        shots   shots fired
;   50010        x       the column of the base's middle, 0 to 31
;   50011        ptime   passes until the next look at the keys
;   50012        stime   passes until the shot's next step
;   50013        srow    the cell row of the shot's top line, or 255 for
;                        no shot
;   50014        scol    the shot's column
;   50015        bx      the column of the block's left-hand invader
;   50016        by      the row of the block's top row
;   50017        mspeed  passes per march step, 1 to 255
;   50018        mtime   passes until the next march step
;   50019        dx      the march: 1 right, 255 (-1) left
;   50020        frame   the invaders' frame, 0 or 1
;   50021        landed  1 once the block has landed, 0 until then
;   50022-50023  msteps  march steps taken
;   50024        hits    invaders shot
;   50025        nleft   invaders alive, 32 at the start
;   50026        elen    frames an explosion shows, 1 to 255
;   50027        etime   passes until the explosion is rubbed out
;   50028        erow    the explosion's row, or 255 for none
;   50029        ecol    the explosion's column
;   50030        seed    the random number state, 1 to 255; 0 = take one
;                        from the R register at the start
;   50031        dwait   passes from one bomb's end to the next drop
;   50032        dtime   passes until the next drop
;   50033        dspeed  passes per step of the bomb, 1 to 255
;   50034        dstime  passes until the bomb's next step
;   50035        brow    the cell row of the bomb's bottom line, or 255
;                        for no bomb
;   50036        bcol    the bomb's column
;   50037        dead    1 once the base has been hit
;   50038        bombs   bombs dropped
;   50039        cancels shots and bombs that cancelled
;   50040        chips   shield cells chipped by shots and bombs
;   50041        stomps  shield cells wiped out by invaders
;   50042-50043  score   the score
;   50044        lives   bases left, counting the one in play
;   50045        wave    the wave, 1 to 99
;   50046        over    why the game ended: 0 Q, 1 out of lives,
;                        2 they landed
;   50047        rlen    passes a lost base stays down, 1 to 255
;   50048        rtime   passes until the next base comes on
;   50049        quiet   0 for sound, anything else for none
;   50050        mfirst  mspeed on wave 1, 1 to 255
;   50051        bfirst  by on wave 1
;   50052        nlives  lives at the start of a game, 1 to 9
;   50053        px      the base's left-hand pixel column, 0 to 248
;   50054        pstep   pixels the base moves at a time, 1 to 8
;   50055        slines  pixel lines the shot moves a step, 1 to 8
;   50056        dlines  pixel lines the bomb moves a step, 1 to 8
;   50057        joy     1 to read a Kempston joystick as well as the
;                        keys, 0 for the keys only
;
; start sets everything else for a new game, so a game started again
; from BASIC starts afresh.
;
; Entry point:
;   RANDOMIZE USR 50058  start
;
; Build:  tools/build.sh chapter-05-machine-code-games/step16-joystick.bas chapter-05-machine-code-games/step16-joystick.asm joystick 10

        org 50000

halts:  db 1            ; 50000: HALTs per pass
bspeed: db 1            ; 50001: passes per look at the keys
sspeed: db 1            ; 50002: passes per step of the shot
moves:  dw 0            ; 50003: base moves
passes: dw 0            ; 50005: passes of the loop
ssteps: dw 0            ; 50007: shot steps
shots:  db 0            ; 50009: shots fired
x:      db 15           ; 50010: the base's column
ptime:  db 1            ; 50011: passes to the next key look
stime:  db 1            ; 50012: passes to the shot's next step
srow:   db 255          ; 50013: the shot's row; 255 = no shot
scol:   db 0            ; 50014: the shot's column
bx:     db 8            ; 50015: the block's left-hand column
by:     db 1            ; 50016: the block's top row
mspeed: db 25           ; 50017: passes per march step
mtime:  db 25           ; 50018: passes to the next march step
dx:     db 1            ; 50019: the march: 1 right, 255 left
frame:  db 0            ; 50020: the invaders' frame, 0 or 1
landed: db 0            ; 50021: 1 once the block has landed
msteps: dw 0            ; 50022: march steps
hits:   db 0            ; 50024: invaders shot
nleft:  db 32           ; 50025: invaders alive
elen:   db 12           ; 50026: frames an explosion shows
etime:  db 0            ; 50027: passes to the explosion's end
erow:   db 255          ; 50028: the explosion's row; 255 = none
ecol:   db 0            ; 50029: the explosion's column
seed:   db 0            ; 50030: the random number state
dwait:  db 50           ; 50031: passes between bombs
dtime:  db 50           ; 50032: passes to the next drop
dspeed: db 1            ; 50033: passes per bomb step
dstime: db 1            ; 50034: passes to the bomb's next step
brow:   db 255          ; 50035: the bomb's row; 255 = none
bcol:   db 0            ; 50036: the bomb's column
dead:   db 0            ; 50037: 1 once the base is hit
bombs:  db 0            ; 50038: bombs dropped
cancels: db 0           ; 50039: shots and bombs cancelled
chips:  db 0            ; 50040: shield cells chipped
stomps: db 0            ; 50041: shield cells wiped out by invaders
score:  dw 0            ; 50042: the score
lives:  db 3            ; 50044: bases left
wave:   db 1            ; 50045: the wave
over:   db 0            ; 50046: 0 Q, 1 out of lives, 2 landed
rlen:   db 50           ; 50047: passes a lost base stays down
rtime:  db 0            ; 50048: passes to the next base
quiet:  db 0            ; 50049: 0 for sound
mfirst: db 25           ; 50050: mspeed on wave 1
bfirst: db 1            ; 50051: by on wave 1
nlives: db 3            ; 50052: lives at the start
px:     db 120          ; 50053: the base's left-hand pixel column
pstep:  db 2            ; 50054: pixels a base move
slines: db 4            ; 50055: pixel lines a shot step
dlines: db 2            ; 50056: pixel lines a bomb step
joy:    db 0            ; 50057: 1 to read the joystick too

baserow: equ 21         ; the base's row
bordcr: equ 23624       ; system variable: the border colour, bits 3-5
font:   equ 15360       ; the ROM's characters, 8 bytes each, less 256
white:  equ 7           ; INK 7, PAPER 0: the status line's attribute
green:  equ 4           ; INK 4, PAPER 0: the base's attribute
yellow: equ 6           ; INK 6, PAPER 0: the shot's attribute
red:    equ 2           ; INK 2, PAPER 0: the bomb's attribute
shrow:  equ 18          ; the shields' top row; their bottom row is 19
kright: equ 1           ; the bits rkeys gives back: P,
kleft:  equ 2           ; O,
kfire:  equ 4           ; Space,
kquit:  equ 8           ; and Q
kport:  equ 31          ; the Kempston joystick's port

; start: a new game. Clear the counts and the score, set the lives and
; the wave, colour row 0 white and row 21 green, draw the base, set up
; wave 1 and the status line, then loop.

start:  ld hl,0
        ld (moves),hl
        ld (passes),hl
        ld (ssteps),hl  ; no moves, passes or shot steps yet
        ld (msteps),hl  ; and no march steps
        ld (score),hl   ; and no score
        xor a
        ld (shots),a    ; no shots
        ld (hits),a     ; no hits
        ld (bombs),a    ; no bombs
        ld (cancels),a
        ld (chips),a
        ld (stomps),a   ; and none of the others
        ld (dead),a     ; the base is whole
        ld (over),a     ; and the game is not over
        inc a
        ld (wave),a     ; wave 1
        ld a,(nlives)
        ld (lives),a    ; nlives bases, 3 as shipped
        ld a,15
        ld (x),a        ; the base in the middle: column 15,
        ld a,120
        ld (px),a       ; pixel 120
        ld a,255
        ld (sr1),a
        ld (sr2),a
        ld (br1),a
        ld (br2),a      ; no shot or bomb on the screen
        ld a,(seed)     ; has BASIC given us a seed?
        and a
        jr nz,seeded    ; yes
        ld a,r          ; no: use the R register
        or 1            ; and make sure it is not 0
        ld (seed),a
seeded:
        ld hl,22528     ; the attribute of row 0, column 0
        ld b,32         ; 32 cells
wrow:   ld (hl),white   ; white ink on black paper: the status line
        inc hl
        djnz wrow

        ld hl,22528+baserow*32 ; the attribute of row 21, column 0
        ld b,32         ; 32 cells
grow:   ld (hl),green   ; green ink on black paper
        inc hl
        djnz grow

        call basex      ; draw the base
        call newwave    ; the block, the shields and the status line

; The game loop: once a frame, unless halts says otherwise. The shot,
; the explosion, the lost base, the bomb, the march and the keys each
; have their own beat. Two places go back to BASIC with the game over:
; the base's beat, when no bases are left, and the march's, when the
; invaders land.

loop:   ld a,(halts)    ; A = HALTs to do
        and a           ; is it 0?
        jr z,go         ; yes: do not wait
        ld b,a
wait:   halt            ; wait for the next frame
        djnz wait

go:     ld hl,(passes)
        inc hl
        ld (passes),hl  ; one more pass

        ld a,(srow)
        inc a           ; 255 becomes 0: is there no shot?
        jr z,boom       ; none: on to the explosion
        ld hl,stime
        dec (hl)        ; one pass fewer to the shot's next step
        jr nz,boom      ; not yet
        ld a,(sspeed)
        ld (hl),a       ; start counting again
        call sstep      ; move the shot up a row

boom:   ld a,(erow)
        inc a           ; 255 becomes 0: is there no explosion?
        jr z,rbase      ; none: on to the base
        ld hl,etime
        dec (hl)        ; one pass fewer to its end
        call z,erub     ; its time is up: rub it out

rbase:  ld a,(dead)
        and a           ; is the base down?
        jr z,bomb       ; no: on to the bomb
        ld hl,rtime
        dec (hl)        ; one pass fewer to the next base
        jr nz,bomb      ; not yet
        ld a,(lives)
        and a           ; any bases left?
        jr nz,rnew      ; yes
        inc a
        ld (over),a     ; no: 1, out of lives
        ret             ; the game is over: back to BASIC
rnew:   call newbase    ; the next base, in the middle

bomb:   ld a,(brow)
        inc a           ; 255 becomes 0: is there no bomb?
        jr nz,bfall     ; there is: it falls
        ld hl,dtime
        dec (hl)        ; one pass fewer to the next drop
        jr nz,march     ; not yet
        ld a,(dwait)
        ld (hl),a       ; start counting again
        call drop       ; drop one
        jr march
bfall:  ld hl,dstime
        dec (hl)        ; one pass fewer to the bomb's next step
        jr nz,march     ; not yet
        ld a,(dspeed)
        ld (hl),a       ; start counting again
        call bstep      ; move the bomb down a row

march:  ld a,(rip)
        cp 4            ; is a march step rippling down the block?
        call nz,mrow    ; yes: move its next row
        ld hl,mtime
        dec (hl)        ; one pass fewer to the next march step
        jr nz,keys      ; not yet
        ld a,(rip)
        cp 4            ; has the last step moved all four rows?
        jr z,mgo        ; yes
        inc (hl)        ; no: mtime = 1, and try again next pass
        jr keys
mgo:    ld a,(mspeed)
        ld (hl),a       ; start counting again
        call mstep      ; march
        ld a,(over)
        and a           ; have they landed?
        ret nz          ; yes: the game is over, back to BASIC

keys:   ld hl,ptime
        dec (hl)        ; one pass fewer to the next key look
        jp nz,loop      ; not yet: jp, since loop is now too far for jr
        ld a,(bspeed)
        ld (hl),a       ; start counting again
        call rkeys      ; A = the keys held, one bit each
        bit 3,a         ; Q?
        ret nz          ; yes: back to BASIC
        ld c,a          ; keep the keys
        ld a,(dead)
        and a           ; has the base been hit?
        jp nz,loop      ; yes: only Q does anything now
        ld a,c          ; the keys again
        bit 2,a         ; Space?
        call nz,fire    ; yes: fire, if no shot is in flight
        and kright+kleft ; keep only P and O
        cp kright       ; only P?
        jr z,right
        cp kleft        ; only O?
        jp nz,loop      ; neither, or both: the base stays put
        call left
        jp loop
right:  call goright
        jp loop

; fire: start a shot above the base, unless one is in flight. Its top
; line is pixel line 161, line 1 of row 20, in x, the column of the
; base's middle. Keeps A, the keys, for the loop. Changes B, C, DE, HL.

fire:   push af         ; keep the keys
        ld a,(srow)
        inc a           ; 255: no shot in flight?
        jr nz,nofire    ; there is one: Space does nothing
        ld a,(x)
        ld (scol),a     ; the shot's column
        ld a,baserow*8-7
        ld (sy),a       ; its top line, 161
        ld a,(sspeed)
        ld (stime),a    ; its first step is a full beat away
        ld hl,shots
        inc (hl)        ; one more shot
        xor a
        call sound      ; sound 0: a click
        call stest      ; draw it, or hit what is there
nofire: pop af          ; the keys again
        ret

; sstep: move the shot up slines pixel lines: take it off the screen,
; move it, and test it where it is now. Once its top line would be on
; row 0 it goes, so it never touches the status line. Changes A, B, C,
; DE, HL.

sstep:  ld hl,(ssteps)
        inc hl
        ld (ssteps),hl  ; one more shot step
        call soff       ; off the screen
        ld a,(slines)
        ld b,a
        ld a,(sy)
        sub b           ; A = its new top line
        cp 8            ; on row 0 (or above, gone round past 0)?
        jr nc,smove     ; no
        ld a,255
        ld (srow),a     ; yes: no shot now
        ret
smove:  ld (sy),a

; stest: the shot's top line is at sy, in the cell row sy / 8, which
; becomes srow. A living invader on that cell is a hit; a shield cell
; eats it; a bomb it meets cancels it. Otherwise it is drawn. The shot
; is not on the screen while it is tested. Changes A, B, C, DE, HL.

stest:  ld a,(sy)
        rrca
        rrca
        rrca
        and 31          ; A = sy / 8: the cell row of its top line
        ld (srow),a
        call scell      ; B, C = that cell
        call invat      ; A = 1 if a living invader is there
        and a
        jr nz,hit       ; yes: a hit
        call scell
        call chip       ; has it come to a shield?
        jr c,sused      ; yes: the shield has eaten it
        call ctest      ; has it met the bomb?
        ret c           ; yes: both are gone
        call scell
        call attr
        ld (hl),yellow  ; its cell in yellow
        jp son          ; and draw it
sused:  ld a,255
        ld (srow),a     ; no shot now
        ret

; son: draw the shot at sy, scol, and note the cell rows it covers,
; sr1 and sr2, for put. soff: take it off, if it is on, and note that
; it is not. Each changes A.

son:    ld a,(srow)
        ld (sr1),a      ; the row of its top line
        ld a,(sy)
        add a,5         ; its bottom line
        rrca
        rrca
        rrca
        and 31
        ld (sr2),a      ; and the row of that
        jr sxor         ; draw it

soff:   ld a,(sr1)
        inc a           ; 255: not on the screen?
        ret z           ; then there is nothing to take off
        ld a,255
        ld (sr1),a
        ld (sr2),a      ; it will not be

; sxor: XOR the shot's six lines, two pixels wide, into the screen at
; pixel line sy, column scol: on if it was off, off if it was on. Keeps
; BC, DE, HL. Changes A.

sxor:   push bc
        push hl
        ld a,(sy)
        ld b,a
        ld a,(scol)
        ld c,a
        call pixad      ; HL = the byte of its top line
        ld b,6          ; 6 lines
sx1:    ld a,(hl)
        xor 24          ; 00011000: its two pixels flip
        ld (hl),a
        call nxtdn      ; the next line down
        djnz sx1
        pop hl
        pop bc
        ret

; hit: the shot has hit invader icol of block row irow, at row B, column
; C, and HL is its byte in the alive table, as invat left them. Kill it,
; end the shot, score it, and show the explosion on its cell. If it was
; the last, start the next wave. Changes A, B, C, DE, HL.

hit:    ld (hl),0       ; dead: the table says so, and that is all
        ld a,255
        ld (srow),a     ; the shot is used up
        ld hl,hits
        inc (hl)        ; one more hit
        ld hl,nleft
        dec (hl)        ; one fewer alive
        ld a,(irow)     ; its row in the block, from invat
        ld e,a
        ld d,0
        ld hl,points
        add hl,de
        ld e,(hl)       ; DE = its points: 30, 20, 20 or 10
        ld hl,(score)
        add hl,de
        ld (score),hl   ; onto the score
        push bc
        call erub       ; one explosion at a time: end the last one
        pop bc
        ld a,b
        ld (erow),a
        ld a,c
        ld (ecol),a     ; the explosion is here
        ld a,(elen)
        ld (etime),a    ; for elen passes
        call attr       ; HL = the cell's attribute
        ld (hl),yellow
        ld de,burst
        call put        ; draw the starburst over the invader
        call pscore     ; print the new score
        ld a,1
        call sound      ; sound 1: a click
        ld a,(nleft)
        and a           ; was that the last one?
        ret nz          ; no
        ld hl,wave      ; yes: the wave is cleared
        ld a,(hl)
        cp 99           ; the status line has two digits for it
        jr z,hit2
        inc (hl)        ; the next wave
hit2:   ld a,4
        call sound
        ld a,5
        call sound
        ld a,6
        call sound      ; three rising notes
        jp newwave      ; and the next wave starts at once

; erub: rub out the explosion, if there is one, and draw again any
; living invader that has marched onto its cell. Changes A, B, C, DE, HL.

erub:   ld hl,erow
        ld a,(hl)
        cp 255          ; is there an explosion?
        ret z           ; no
        ld (hl),255     ; there will not be
        ld b,a
        ld a,(ecol)
        ld c,a          ; B, C = its cell
        push bc
        ld de,blank
        call put        ; rub it out
        pop bc
        call invat      ; has a living invader come onto the cell?
        and a
        ret z           ; no
        jp dinv         ; yes: draw it again

; drop: drop a bomb, unless the base is hit or none are alive. Pick a
; column with rnd; if none of it is alive, try the next, round to 0
; after 7. The bomb starts on the row below the column's lowest living
; invader. Changes A, B, C, DE, HL.

drop:   ld a,(dead)
        and a
        ret nz          ; the base is hit: no more bombs
        ld a,(nleft)
        and a
        ret z           ; none alive: no bombs
        call rnd        ; A = a random byte
        and 7           ; A = 0 to 7: a column of the block
        ld (icol),a
        ld b,8          ; 8 columns to try at most
dcol:   push bc
        call colalive   ; is any invader in column icol alive?
        pop bc
        jr nz,dgot      ; yes
        ld a,(icol)
        inc a
        and 7           ; the next column, 7 going round to 0
        ld (icol),a
        djnz dcol
        ret             ; cannot happen while nleft is not 0
dgot:   ld a,3
        ld (irow),a     ; from the bottom row up
dlow:   call aliveat
        and a
        jr nz,dfound    ; the lowest living invader of the column
        ld hl,irow
        dec (hl)        ; the row above; one of them is alive
        jr dlow
dfound: call where      ; B, C = its cell
        inc b           ; the row below it
        ld a,b
        add a,a
        add a,a
        add a,a         ; A = 8 * row: the top line of that row
        ld (dy),a       ; is the bomb's top line
        ld a,c
        ld (bcol),a     ; the bomb starts there
        ld a,(dspeed)
        ld (dstime),a   ; a full beat to its first step
        ld hl,bombs
        inc (hl)        ; one more bomb
        ld a,2
        call sound      ; sound 2: a lower click
        jr btest        ; and see where it is

; bstep: take the bomb off the screen and move it down dlines pixel
; lines. Changes A, B, C, DE, HL.

bstep:  call boff       ; off the screen
        ld a,(dlines)
        ld hl,dy
        add a,(hl)
        ld (hl),a       ; dlines lines down

; btest: the bomb's top line is at dy, and its bottom line, dy + 7, in
; the cell row that becomes brow. On the base's row it has hit the base,
; if the base covers any of its pixel columns, or it goes into the
; ground. Above that, test it against a shield and the shot, then draw
; it. If a living invader is on its cell, the cell keeps the invader's
; colour. Changes A, B, C, DE, HL.

btest:  ld a,(dy)
        add a,7         ; its bottom line
        rrca
        rrca
        rrca
        and 31          ; A = the cell row of its bottom line
        ld (brow),a
        cp baserow      ; on the base's row?
        jr c,bair       ; no: still in the air
        ld a,(bcol)
        add a,a
        add a,a
        add a,a         ; A = 8 * bcol, the bomb's left-hand pixel
        ld hl,px
        sub (hl)        ; A = that - px, round past 0 if negative
        add a,7         ; -7 to 7 becomes 0 to 14
        cp 15           ; within 7 pixels of the base, either way?
        jr c,bhit       ; yes: the base is hit
        jr bused        ; no: it is gone, into the ground
bair:   call bcell      ; B, C = the cell of its bottom line
        call chip       ; has it come to a shield?
        jr c,bused      ; yes: the shield has eaten it
        call ctest      ; has it met the shot?
        ret c           ; yes: both are gone
        call bcell
        call invat      ; is a living invader on its cell?
        and a
        jr nz,bon       ; yes: leave the colour, and draw it
        call bcell
        call attr
        ld (hl),red     ; no: red ink on black paper
        jr bon
bused:  ld a,255
        ld (brow),a     ; no bomb now
        ret

; bon: draw the bomb at dy, bcol, and note its cell rows, br1 and br2,
; for put. boff: take it off, if it is on. Each changes A.

bon:    ld a,(dy)
        rrca
        rrca
        rrca
        and 31
        ld (br1),a      ; the row of its top line
        ld a,(brow)
        ld (br2),a      ; and of its bottom line
        jr bxor

boff:   ld a,(br1)
        inc a           ; 255: not on the screen?
        ret z
        ld a,255
        ld (br1),a
        ld (br2),a

; bxor: XOR the bomb's 8 lines into the screen at pixel line dy, column
; bcol. Keeps BC, DE, HL. Changes A.

bxor:   push bc
        push de
        push hl
        ld a,(dy)
        ld b,a
        ld a,(bcol)
        ld c,a
        call pixad      ; HL = the byte of its top line
        ld de,bombg
        ld b,8          ; 8 lines
bx1:    ld a,(de)
        xor (hl)
        ld (hl),a       ; flip its pixels on this line
        inc de
        call nxtdn
        djnz bx1
        pop hl
        pop de
        pop bc
        ret

; bcell: B = the cell row of the bomb's bottom line, C = its column.
; Changes A.

bcell:  ld a,(brow)
        ld b,a
        ld a,(bcol)
        ld c,a
        ret

; bhit: the bomb has hit the base. End the bomb and the shot, take the
; base off and put a starburst on the cell of its middle, take a life,
; and keep the base down for rlen passes; the base's beat in the loop
; does the rest. Changes A, B, C, DE, HL.

bhit:   ld a,1
        ld (dead),a     ; the base is hit
        ld a,255
        ld (brow),a     ; no bomb (it is not on the screen)
        call soff       ; the shot off the screen, if it is on
        ld a,255
        ld (srow),a     ; and no shot
        call basex      ; the base off the screen
        ld a,(x)
        ld c,a
        ld b,baserow    ; B, C = the cell of its middle
        call attr
        ld (hl),yellow
        ld de,burst
        call put        ; the starburst there
        ld hl,lives
        dec (hl)        ; one base fewer
        call plives     ; print it
        ld a,(rlen)
        ld (rtime),a    ; down for rlen passes
        ld a,3
        jp sound        ; sound 3: a long low note

; ctest: if a shot and a bomb are both in flight, in the same column,
; and their pixel lines overlap, they have met: take both off the
; screen, end both, and return with the carry set. The shot covers lines
; sy to sy + 5 and the bomb dy to dy + 7, so they overlap when sy - dy
; is -5 to 7. Otherwise return with the carry clear. Changes A, B, HL.

ctest:  ld a,(brow)
        inc a
        jr z,noc        ; no bomb
        ld a,(srow)
        inc a
        jr z,noc        ; no shot
        ld a,(bcol)
        ld hl,scol
        cp (hl)         ; the same column?
        jr nz,noc
        ld a,(dy)
        ld b,a
        ld a,(sy)
        sub b           ; A = sy - dy
        add a,5         ; -5 to 7 becomes 0 to 12
        cp 13
        jr nc,noc       ; they do not overlap
        call boff
        call soff       ; both off the screen
        ld a,255
        ld (brow),a
        ld (srow),a     ; neither is in flight now
        ld hl,cancels
        inc (hl)        ; one more cancel
        scf             ; they met
        ret
noc:    and a           ; clear the carry: they have not met
        ret

; rnd: the next random byte, in A and in seed. Step 6's 8-bit LFSR, run
; for eight steps. Each step shifts the byte right, and if a 1 fell off
; the end, XORs in the taps, 184. Over 255 calls it gives every value
; from 1 to 255 once, and then repeats. Changes A and B.

rnd:    ld a,(seed)
        ld b,8          ; eight shifts
rnd1:   srl a           ; bit 0 falls into the carry
        jr nc,rnd2      ; it was 0: nothing more to do
        xor 184         ; it was 1: XOR in the taps, 10111000
rnd2:   djnz rnd1
        ld (seed),a
        ret

; shat: is the cell at row B, column C a shield cell? If not, the carry
; is set. If it is, the carry is clear, HL is its byte in the damage
; map, A is its level, the zero flag is set if the level is 0, and shy
; (0 top, 1 bottom) and shx (0, 1 or 2 across) say which cell of its
; shield it is. The shields start in columns 3, 11, 19 and 27, eight
; apart, so column - 3 is 8 * shield + place, with the place in the
; bottom three bits. Keeps B, C. Changes A, DE, HL.

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

; shdraw: draw the shield cell at row B, column C at level A, using shy
; and shx from shat: level 3 is the cell's own shape, 2 damaged, 1
; badly damaged, 0 nothing. Changes A, B, DE, HL.

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

; chip: if the cell at row B, column C is a shield cell above level 0,
; take one off its level, draw it, count it, and return with the carry
; set: whatever came here is used up. If not, return with the carry
; clear. Changes A, DE, HL, and B if it chips.

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

; stomp: an invader is being drawn at row B, column C. If that is a
; shield cell still above level 0, it is gone: set its level to 0 and
; count it. The invader's picture covers it. Keeps B, C, DE. Changes A,
; HL.

stomp:  ld a,b
        cp shrow        ; above the shields?
        ret c           ; yes: nothing to do, quickly
        push de         ; keep the invader's graphic
        call shat
        jr c,stomp1     ; not a shield cell
        jr z,stomp1     ; already gone
        ld (hl),0       ; wiped out
        ld hl,stomps
        inc (hl)
stomp1: pop de
        ret

; dshield: set every byte of the damage map to 3, then draw every cell
; of rows 18 and 19 that shat says is a shield cell. Changes A, B, C, DE,
; HL.

dshield: ld hl,shmap
        ld b,24         ; 24 cells
dsh1:   ld (hl),3       ; whole
        inc hl
        djnz dsh1
        ld b,shrow      ; row 18 first
dsh2:   ld c,0          ; from column 0
dsh3:   call shat       ; a shield cell?
        jr c,dsh4       ; no
        push bc
        call shdraw     ; draw it, at level 3
        pop bc
dsh4:   inc c
        ld a,c
        cp 32
        jr nz,dsh3
        inc b
        ld a,b
        cp shrow+2      ; done row 19?
        jr nz,dsh2
        ret

; count: nleft = the number of 1s in the alive table. Changes A, B, HL.

count:  ld hl,alive
        ld b,32         ; 32 invaders
        xor a
cnt1:   add a,(hl)      ; add its byte, 0 or 1
        inc hl
        djnz cnt1
        ld (nleft),a
        ret

; scell: B = the shot's row, C = its column. Changes A.

scell:  ld a,(srow)
        ld b,a
        ld a,(scol)
        ld c,a
        ret

; rkeys: read every key the game uses, in one go, and give back one
; bit for each that is held: bit 0 P, bit 1 O, bit 2 Space, bit 3 Q.
; Step 7's, with the joystick ORed in: right as P, left as O and fire
; as Space. Changes A and C.

rkeys:  ld a,223        ; half-row P, O, I, U, Y
        in a,(254)      ; bit 0 is P, bit 1 is O; 0 means held
        cpl             ; now 1 means held
        and 3           ; keep P and O: bits 0 and 1 already
        ld c,a
        ld a,127        ; half-row Space, Sym Shift, M, N, B
        in a,(254)
        cpl
        and 1           ; Space is bit 0
        add a,a
        add a,a         ; move it to bit 2
        or c
        ld c,a
        ld a,251        ; half-row Q, W, E, R, T
        in a,(254)
        cpl
        and 1           ; Q is bit 0
        rlca
        rlca
        rlca            ; move it to bit 3
        or c
        ld c,a          ; C = the keys
        ld a,(joy)
        and a           ; a joystick?
        ld a,c
        ret z           ; no: the keys alone
        in a,(kport)    ; A = 000FUDLR: fire, up, down, left, right;
                        ; 1 means pressed, the other way from the keys
        cp 32           ; any of the top three bits set?
        jr nc,nojoy     ; then it is not a Kempston: ignore it
        bit 4,a         ; fire?
        jr z,j1
        set 2,c         ; yes: as if Space were held
j1:     and 3           ; right and left are bits 0 and 1, like P and O
        or c            ; with the keys
        ret
nojoy:  ld a,c          ; the keys alone
        ret

; left: move the base pstep pixels left, no further than pixel 0. Take
; it off, move it, and draw it again. Changes A, B, C, DE, HL.

left:   ld a,(px)
        and a           ; already at pixel 0?
        ret z           ; yes
        call basex      ; off
        ld a,(pstep)
        ld b,a
        ld a,(px)
        sub b           ; pstep pixels left
        jr nc,pmove
        xor a           ; past 0: stop at 0
        jr pmove

; goright: the same, to the right, no further than pixel 248, where the
; base's right-hand edge is the screen's.

goright: ld a,(px)
        cp 248          ; already at the right?
        ret nc          ; yes
        call basex      ; off
        ld a,(pstep)
        ld hl,px
        add a,(hl)      ; pstep pixels right
        cp 249
        jr c,pmove
        ld a,248        ; past 248: stop at 248

pmove:  ld (px),a       ; the new place
        add a,4
        rrca
        rrca
        rrca
        and 31
        ld (x),a        ; x = (px + 4) / 8, the column of its middle
        call basex      ; draw it there
        ld hl,(moves)
        inc hl
        ld (moves),hl   ; one more move
        ret

; basex: XOR the base into row 21 at pixel column px. Its 8 pixels
; across can sit across two bytes, so each line is shifted right px AND
; 7 times, with the pixels that fall off the right-hand end caught in C
; for the next byte. Changes A, B, C, DE, HL.

basex:  ld a,(px)
        rrca
        rrca
        rrca
        and 31
        ld c,a          ; C = the byte column of its left-hand pixel
        ld b,baserow*8  ; its top line, 168
        call pixad      ; HL = that byte
        ld de,base
        ld b,8          ; 8 lines
bs1:    push bc
        ld a,(px)
        and 7           ; the shift, 0 to 7
        ld b,a
        ld a,(de)       ; A = this line of the base
        ld c,0          ; C = the pixels for the next byte
        jr z,bs3        ; a shift of 0: nothing to do
bs2:    srl a           ; one pixel right; the right-hand one into the carry
        rr c            ; and from the carry into C
        djnz bs2
bs3:    xor (hl)
        ld (hl),a       ; flip the left-hand byte's pixels
        inc l
        ld a,c
        xor (hl)
        ld (hl),a       ; and the right-hand byte's
        dec l
        inc h           ; the next line down: all 8 are in row 21
        inc de
        pop bc
        djnz bs1
        ret

; pixad: HL = the screen address of pixel line B, 0 to 191, byte column
; C, 0 to 31. Chapter 3, step 8's address bits: the line y is
; y7 y6 y5 y4 y3 y2 y1 y0, and the address is
;   H = 0 1 0 y7 y6 y2 y1 y0     L = y5 y4 y3 C C C C C
; Changes A.

pixad:  ld a,b
        and 7           ; y2 y1 y0: the line in its cell
        or 64           ; 010 on top
        ld h,a
        ld a,b
        rrca
        rrca
        rrca            ; y7 y6 now in bits 4 and 3
        and 24
        or h
        ld h,a          ; H = 010 y7 y6 y2 y1 y0
        ld a,b
        rlca
        rlca            ; y5 y4 y3 now in bits 7, 6 and 5
        and 224
        or c
        ld l,a          ; L = y5 y4 y3 and the column
        ret

; nxtdn: HL = the address one pixel line below HL, in the same column.
; Chapter 3, step 8's routine. Changes A.

nxtdn:  inc h           ; down one pixel line
        ld a,h
        and 7           ; still inside the same cell?
        ret nz          ; yes: done
        ld a,l
        add a,32        ; next character row
        ld l,a
        ret c           ; carry: into the next third, H is right
        ld a,h
        sub 8           ; same third: undo the carry into the third
        ld h,a
        ret

; put: copy the 8 bytes at DE into the cell at row B, column C. If the
; shot or the bomb is on that cell, it is taken off first and put back
; after, so that the XOR drawing stays right. Changes A, B, DE and HL.

put:    ld a,(scol)
        cp c            ; the shot's column?
        jr nz,pbomb     ; no
        ld a,(sr1)
        cp b            ; one of the shot's rows?
        jr z,pshot
        ld a,(sr2)
        cp b
        jr nz,pbomb     ; no
pshot:  call sxor       ; take the shot off
        call pbomb      ; the bomb too, if it is there, then the cell
        jp sxor         ; and put the shot back
pbomb:  ld a,(bcol)
        cp c            ; the bomb's column?
        jr nz,rawput    ; no: just draw
        ld a,(br1)
        cp b            ; one of the bomb's rows?
        jr z,pbomb2
        ld a,(br2)
        cp b
        jr nz,rawput    ; no
pbomb2: call bxor       ; take the bomb off
        call rawput     ; draw the cell
        jp bxor         ; and put the bomb back

; rawput: put, as it was: the 8 bytes at DE into the cell.

rawput: call cell       ; HL = the top byte of the cell
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

; attr: HL = the attribute address of the cell at row B, column C:
; 010110TT RRRCCCCC, which is 22528 + 32*row + column. Step 3's.
; Changes A.

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

; dblock: draw every living invader of the block. Changes A, B, C,
; DE, HL.

dblock: xor a
        ld (irow),a        ; block row 0
dbrow:  xor a
        ld (icol),a        ; invader 0 of the row
dbinv:  call dinv       ; draw it, if it is alive
        ld hl,icol
        inc (hl)        ; the next invader
        ld a,(hl)
        cp 8            ; done all 8?
        jr nz,dbinv
        ld hl,irow
        inc (hl)        ; the next row
        ld a,(hl)
        cp 4            ; done all 4?
        jr nz,dbrow
        ret

; dinv: draw invader icol of block row irow, in its row's colour, if it is
; alive. Changes A, B, C, DE, HL.

dinv:   call aliveat    ; A = 1 if it is alive
        and a
        ret z           ; not alive: nothing to draw
        call rtype      ; DE = its graphic, A = its ink
        push af
        call where      ; B, C = its cell on the screen
        call stomp      ; on a shield cell? then that cell is gone
        call attr       ; HL = the cell's attribute
        pop af
        ld (hl),a       ; the row's ink, on black paper
        jp put          ; draw it, and put returns

; aliveat: A = the alive byte of invader icol in block row irow, and HL its
; address, alive + 8*irow + icol. Changes DE.

aliveat: ld a,(irow)
        add a,a
        add a,a
        add a,a         ; A = 8*irow
        ld hl,icol
        add a,(hl)      ; A = 8*irow + icol
        ld e,a
        ld d,0
        ld hl,alive
        add hl,de       ; HL = its byte in the table
        ld a,(hl)
        ret

; where: B = the screen row of invader icol in block row irow, by + 2*irow,
; and C its column, bx + 2*icol; but from obx and oby if its row has
; not moved yet in a rippling march step (irow is not below rip).
; owhere: always from obx and oby, where the block was before this
; march step. Both go on to wpair, with HL = the address of a column
; byte with its row byte after it. Changes A, HL.

where:  ld a,(irow)
        ld hl,rip
        cp (hl)         ; carry if irow < rip: its row has moved
        ld hl,bx        ; the block as it is (LD keeps the flags)
        jr c,wpair
owhere: ld hl,obx       ; the block as it was
wpair:  ld a,(icol)
        add a,a
        add a,(hl)
        ld c,a          ; C = column + 2*icol
        inc hl          ; the row byte comes next
        ld a,(irow)
        add a,a
        add a,(hl)
        ld b,a          ; B = row + 2*irow
        ret

; rtype: DE = the graphic and A = the ink of block row irow, from the
; rows table, three bytes a row, in the frame of its row: frame if the
; row has moved, the other frame if it has not yet. Changes B, HL.

rtype:  ld a,(irow)
        ld hl,rip
        cp (hl)         ; has its row moved?
        ld a,(frame)
        jr c,rtnow      ; yes: this frame
        xor 1           ; not yet: the other
rtnow:  ld b,a          ; B = the row's frame
        ld a,(irow)
        ld e,a
        add a,a
        add a,e         ; A = 3*irow
        ld e,a
        ld d,0
        ld hl,rows
        add hl,de       ; HL = this row's entry
        ld e,(hl)
        inc hl
        ld d,(hl)       ; DE = the graphic, frame 0
        ld a,b          ; the row's frame
        add a,a
        add a,a
        add a,a         ; A = 0 for frame 0, 8 for frame 1
        add a,e
        ld e,a
        jr nc,rtnc
        inc d           ; DE = the graphic of this frame
rtnc:   inc hl
        ld a,(hl)       ; A = the ink
        ret

; invat: is the cell at row B, column C an invader's place in the
; block? If it is, irow and icol are set to it, and A is its alive byte;
; if not, A = 0. In a rippling march step the rows that have moved are
; where the block is, and the rest where it was, so both are tried.
; Keeps B and C. Changes DE, HL.

invat:  ld hl,bx
        call inbl       ; an invader's place in the block as it is?
        jr nz,invold    ; no
        ld a,(irow)
        ld hl,rip
        cp (hl)         ; and has that row moved?
        jp c,aliveat    ; yes: A = its alive byte
invold: ld hl,obx
        call inbl       ; in the block as it was?
        jr nz,noinv     ; no
        ld a,(irow)
        ld hl,rip
        cp (hl)         ; a row that has not moved yet?
        jp nc,aliveat   ; yes: A = its alive byte
noinv:  xor a           ; not an invader's place
        ret

; inbl: is the cell at row B, column C an invader's place in a block
; whose left-hand column is at HL and top row at HL + 1? If it is, the
; zero flag is set and irow and icol are set to it. Keeps B and C.
; Changes A, HL.

inbl:   ld a,c
        sub (hl)        ; A = column - left; left of it goes round
        cp 15           ; past 0 to 255 or so, so one test does both
        jr nc,inno      ; outside: columns 0, 2, ... 14
        bit 0,a
        jr nz,inno      ; an odd column: a gap
        rrca            ; A = (column - left) / 2, since bit 0 is 0
        ld (icol),a
        inc hl          ; the row byte comes next
        ld a,b
        sub (hl)        ; A = row - top
        cp 7
        jr nc,inno      ; outside: block rows are 0, 2, 4 and 6
        bit 0,a
        jr nz,inno      ; an odd row: between two block rows
        rrca
        ld (irow),a
        xor a           ; zero flag set: found
        ret
inno:   or 1            ; zero flag clear: not found
        ret

; mstep: one step of the march. Find the living edges; at an edge,
; step down (or land), otherwise step sideways; then change frame, and
; set rip to 0: the march beat moves the rows, one a pass, from the
; next pass on. Changes A, B, C, DE, HL.

mstep:  ld a,(landed)
        and a
        ret nz          ; landed: the march is over
        ld a,(dead)
        and a
        ret nz          ; the base is hit: so is the march
        call edges      ; lm, rm = the living edge columns
        ret c           ; none alive: nothing to march
        ld hl,(msteps)
        inc hl
        ld (msteps),hl  ; one more march step
        ld hl,(bx)      ; L = bx, H = by
        ld (obx),hl     ; where the block is now: obx, oby
        ld a,(dx)
        dec a           ; 1 (right) becomes 0
        jr nz,mleft
        ld a,(rm)       ; marching right: the right-hand edge
        add a,a
        ld hl,bx
        add a,(hl)      ; A = the column of the right-hand edge
        cp 31           ; at the right of the screen?
        jr z,mdown
        jr mside
mleft:  ld a,(lm)       ; marching left: the left-hand edge
        add a,a
        ld hl,bx
        add a,(hl)      ; A = the column of the left-hand edge
        and a           ; at column 0?
        jr z,mdown
mside:  ld a,(dx)
        ld hl,bx
        add a,(hl)
        ld (hl),a       ; bx = bx + dx: one column sideways
        jr mmove
mdown:  ld a,(by)
        cp 20-6         ; would the bottom row come down past row 20?
        jr nc,land      ; yes: they have landed
        inc a
        ld (by),a       ; by = by + 1: one row down
        ld a,(dx)
        neg
        ld (dx),a       ; and back the other way
mmove:  ld a,(frame)
        xor 1
        ld (frame),a    ; the other frame
        xor a
        ld (rip),a      ; no row has moved yet
        ret

; land: the march is over, and so is the game: over = 2, and the loop
; goes back to BASIC.

land:   ld a,1
        ld (landed),a
        inc a
        ld (over),a     ; 2: they landed
        ret

; mrow: move block row rip from where the block was to where it is,
; one invader at a time: rub it out where it was, then draw it where it
; is. rip goes up first, so that where and rtype see the row as moved.
; The invaders are two cells apart, so the new cell never holds another
; invader, and none is missing from the screen for more than a moment.
; Changes A, B, C, DE, HL.

mrow:   ld a,(rip)
        ld (irow),a     ; the row to move
        inc a
        ld (rip),a      ; it counts as moved from now on
        xor a
        ld (icol),a     ; from invader 0
mrinv:  call aliveat
        and a
        jr z,mrnext     ; not alive: nothing to move
        call owhere     ; B, C = where it was
        ld de,blank
        call put        ; rub it out
        call dinv       ; draw it where it is, in the new frame
mrnext: ld hl,icol
        inc (hl)
        ld a,(hl)
        cp 8            ; done all 8?
        jr nz,mrinv
        ret

; edges: lm = the left-hand column, 0 to 7, with an invader alive in
; it, and rm the right-hand one. Carry set if there is none. Changes
; A, B, DE, HL.

edges:  xor a
        ld (icol),a     ; from the left
eleft:  call colalive
        jr nz,egotl     ; a living invader in this column
        ld hl,icol
        inc (hl)
        ld a,(hl)
        cp 8
        jr nz,eleft
        scf             ; none in any column
        ret
egotl:  ld a,(icol)
        ld (lm),a
        ld a,7
        ld (icol),a     ; and from the right
eright: call colalive
        jr nz,egotr
        ld hl,icol
        dec (hl)
        jr eright       ; it stops at lm at the latest
egotr:  ld a,(icol)
        ld (rm),a
        and a           ; clear the carry: found
        ret

; colalive: A = not 0, and the zero flag clear, if any invader in
; column icol is alive. Changes B, DE, HL.

colalive: ld a,(icol)
        ld e,a
        ld d,0
        ld hl,alive
        add hl,de       ; HL = the top invader of the column
        ld de,8         ; 8 bytes on in the table is the next row
        xor a
        ld b,4          ; 4 rows
calive: or (hl)         ; A = A OR this invader's byte
        add hl,de
        djnz calive
        and a           ; set the zero flag from A
        ret

; newwave: set up a wave: wave 1 at the start of a game, the next when
; one is cleared. The block goes back to column 8, a row lower each wave
; (bfirst on wave 1, no lower than row 8 after that) and 3 passes a step
; faster (mfirst on wave 1, down to no less than 4). All 32 invaders are
; alive again, the play area is cleared, the shields are whole, and the
; status line is printed. The score and the lives carry on. Changes A,
; B, C, DE, HL.

newwave: ld a,(wave)
        dec a
        ld hl,bfirst
        add a,(hl)      ; A = bfirst + wave - 1
        cp 9            ; row 8 or above?
        jr c,nw1        ; yes: that is the row
        ld a,(hl)       ; no: row 8, unless bfirst itself is lower
        cp 9
        jr nc,nw1
        ld a,8
nw1:    ld (by),a
        ld a,8
        ld (bx),a       ; the block's left-hand column
        ld a,1
        ld (dx),a       ; marching right
        xor a
        ld (frame),a    ; frame 0
        ld (landed),a   ; not landed
        ld a,4
        ld (rip),a      ; and no march step rippling

        ld a,(wave)
        ld b,a          ; B = the wave
        ld a,(mfirst)   ; A = the speed on wave 1
nw2:    dec b           ; a wave after the first?
        jr z,nw3        ; no: A is the speed
        cp 7            ; would 3 less be under 4?
        jr c,nw3        ; yes: keep it
        sub 3           ; no: 3 passes a step faster
        jr nw2
nw3:    ld (mspeed),a
        ld (mtime),a    ; a full beat to the first march step
        ld a,(dwait)
        ld (dtime),a    ; and to the first bomb

        ld hl,alive
        ld b,32
nw4:    ld (hl),1       ; every invader alive
        inc hl
        djnz nw4
        ld a,255
        ld (srow),a     ; no shot
        ld (erow),a     ; no explosion
        ld (brow),a     ; no bomb
        ld (sr1),a
        ld (sr2),a
        ld (br1),a
        ld (br2),a      ; and none on the screen: clear rubs them out
        call clear      ; rows 1 to 20 cleared
        call dshield    ; the four shields, whole
        call dblock     ; the block
        call count      ; nleft = 32
        jp status       ; and the status line

; clear: rub out rows 1 to 20: for each row, its 8 pixel lines of 32
; bytes. Leaves the attributes. Changes A, B, C, D, E, HL.

clear:  ld b,1          ; row 1 first
clr1:   ld c,0
        call cell       ; HL = the row's top-left byte
        ld d,8          ; 8 pixel lines
clr2:   push hl
        ld e,32         ; 32 bytes across
clr3:   ld (hl),0
        inc l           ; the next byte of the line
        dec e
        jr nz,clr3
        pop hl
        inc h           ; the next pixel line down
        dec d
        jr nz,clr2
        inc b           ; the next row
        ld a,b
        cp baserow      ; done row 20?
        jr nz,clr1
        ret

; newbase: rub out the starburst where the lost base was, and bring on
; the next base at pixel 120, column 15. Changes A, B, C, DE, HL.

newbase: ld a,(x)
        ld c,a
        ld b,baserow    ; the burst's cell
        call attr
        ld (hl),green   ; green again, for the base when it comes here
        ld de,blank
        call put        ; rub out the burst
        ld a,15
        ld (x),a        ; the middle: column 15,
        ld a,120
        ld (px),a       ; pixel 120
        call basex      ; the new base
        xor a
        ld (dead),a     ; in play again
        ret

; status: print the whole status line on row 0: the words, then the
; numbers. Changes A, B, C, DE, HL.

status: ld hl,stext
        ld bc,0         ; B = row 0, C = column 0
        call ptext      ; the words, and spaces between them
        call pscore
        call pwave      ; then the numbers, and plives returns

; plives, pscore, pwave: print one number of the status line. Each
; changes A, B, C, DE, HL.

plives: ld a,(lives)
        ld l,a
        ld h,0          ; HL = the lives
        ld bc,28        ; row 0, column 28
        ld a,1          ; one digit
        jr pdec

pscore: ld hl,(score)
        ld bc,6         ; row 0, column 6
        ld a,5          ; five digits
        jr pdec

pwave:  ld a,(wave)
        ld l,a
        ld h,0
        ld bc,18        ; row 0, column 18
        ld a,2          ; two digits

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

; sound: play sound number A, 0 to 6, unless quiet is not 0: step 6's.
; Keeps every register except A and the flags. Each sound in the table
; is a delay count (2 bytes, low first), which sets the pitch, and a
; number of whole cycles, which sets the length.

sound:  push bc
        push de
        push hl
        ld c,a          ; keep the sound's number
        ld a,(quiet)
        and a           ; is the sound switched off?
        jr nz,sdone     ; yes: nothing to do
        ld a,c
        add a,a         ; A = 2 * number
        add a,c         ; A = 3 * number, the size of each entry
        ld e,a
        ld d,0
        ld hl,sounds
        add hl,de       ; HL = this sound's entry
        ld e,(hl)
        inc hl
        ld d,(hl)       ; DE = the delay count
        inc hl
        ld b,(hl)       ; B = the number of cycles

        ld a,(bordcr)   ; the border colour is in bits 3 to 5
        rrca
        rrca
        rrca            ; now in bits 0 to 2
        and 7
        ld c,a          ; C = the border colour, speaker off

cycle:  ld a,c
        or 16           ; bit 4 on: the speaker cone goes out
        out (254),a
        call delay
        ld a,c          ; bit 4 off: it comes back
        out (254),a
        call delay
        djnz cycle      ; B-1; not zero: another cycle
sdone:  pop hl
        pop de
        pop bc
        ret

; delay: count DE down to 0. Changes A and HL.

delay:  ld h,d
        ld l,e
dloop:  dec hl
        ld a,h
        or l
        jr nz,dloop
        ret

; The sounds. The delay n gives a note of 3500000 / (52 * n + 110)
; hertz, and each cycle takes 52 * n + 110 T-states. The three clicks
; are kept under 4500 T-states, about a sixteenth of a frame, since they
; play in the middle of a pass; the others play when the game waits.

sounds: dw 20
        db 3            ; 0 fire: about 3000 Hz, 3 cycles, 1 ms
        dw 40
        db 2            ; 1 hit: about 1600 Hz, 2 cycles, 1.3 ms
        dw 80
        db 1            ; 2 drop: about 820 Hz, 1 cycle, 1.2 ms
        dw 400
        db 30           ; 3 base lost: about 168 Hz, 30 cycles, 0.18 s
        dw 255
        db 5            ; 4 wave: about 262 Hz, C, 0.02 s
        dw 202
        db 7            ; 5 about 330 Hz, E
        dw 170
        db 8            ; 6 about 392 Hz, G

; The status line's words, the points for each block row, and the
; powers of ten for pdec.

stext:  db "SCORE        WAVE     LIVES     ",255
points: db 30,20,20,10  ; block rows 0, 1, 2 and 3
tens:   dw 10000,1000,100,10,1

; The block's working bytes and tables.

irow:   db 0            ; the block row being drawn, 0 to 3
icol:   db 0            ; the invader in that row, 0 to 7
obx:    db 0            ; bx before this march step
oby:    db 0            ; by before it: it must follow obx
lm:     db 0            ; the left-hand living column, 0 to 7
rm:     db 0            ; the right-hand living column
sy:     db 0            ; the shot's top pixel line
sr1:    db 255          ; the cell rows the shot covers on the screen,
sr2:    db 255          ; or 255 when it is not on the screen
dy:     db 0            ; the bomb's top pixel line
br1:    db 255          ; the cell rows the bomb covers on the screen,
br2:    db 255          ; or 255
rip:    db 4            ; block rows moved in this march step; 4 = all
pdn:    db 0            ; digits left for pdec to print
shy:    db 0            ; a shield cell's row in its shield, 0 or 1
shx:    db 0            ; its place across, 0 to 2

; shmap: the damage map, 12 bytes for the top row of the four shields,
; then 12 for the bottom row. 3 whole, 2 damaged, 1 badly, 0 gone.

shmap:  ds 24

; shgfx: the shield pictures by level, then the six shapes of a whole
; shield, top row then bottom row.

shgfx:  dw blank,gO,gN ; levels 0, 1 and 2
        dw gK,gJ,gL  ; level 3, top row: corner, block, corner
        dw gJ,gM,gJ  ; level 3, bottom row: block, arch, block

; alive: one byte for each invader, row by row, 1 = alive.

alive:  db 1,1,1,1,1,1,1,1
        db 1,1,1,1,1,1,1,1
        db 1,1,1,1,1,1,1,1
        db 1,1,1,1,1,1,1,1

; rows: for each block row, its graphic (a word) and its ink.

rows:   dw inv1
        db 3            ; magenta
        dw inv2
        db 5            ; cyan
        dw inv2
        db 5            ; cyan
        dw inv3
        db 7            ; white

; The graphics, Chapter 4's UDGs A and B, from its DATA lines 990 to
; 997, its invaders, UDGs D to I, from lines 1000 to 1055 of its
; step 4, its explosion, UDG P, from its step 5, its bomb, UDG C,
; from its step 6, and its shields, UDGs J to O, from its step 7. Each invader
; type's frame 1 is 8 bytes after its frame 0.

base:   db 24,24,24,126,255,255,255,255
inv1:   db 60,126,255,219,255,90,165,66 ; UDG D, the top row, frame 0
        db 60,126,255,219,255,90,66,165 ; UDG E, its frame 1
inv2:   db 66,36,126,219,255,189,165,36 ; UDG F, the middle rows, frame 0
        db 36,165,126,219,255,189,36,165 ; UDG G, frame 1
inv3:   db 60,255,255,231,255,90,165,129 ; UDG H, the bottom row, frame 0
        db 60,255,255,231,255,90,129,165 ; UDG I, frame 1
burst:  db 165,90,189,126,126,189,90,165 ; UDG P, the explosion
bombg:  db 28,62,99,28,62,99,28,8 ; UDG C, the bomb
gJ:    db 126,255,255,255,255,255,255,126 ; UDG J, a full block
gK:    db 15,31,63,127,255,255,255,255 ; UDG K, the top-left corner
gL:    db 240,248,252,254,255,255,255,255 ; UDG L, the top-right corner
gM:    db 255,255,255,231,195,195,195,195 ; UDG M, the arch
gN:    db 110,219,189,118,221,183,111,218 ; UDG N, damaged
gO:    db 74,144,37,66,148,9,82,136 ; UDG O, badly damaged
blank:  db 0,0,0,0,0,0,0,0

        end
