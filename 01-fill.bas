1 REM R=character row 0-23
2 REM X=column 0-31
3 REM C=colour, INK 1-7
4 REM A=screen address
10 BORDER 0: PAPER 0: INK 7: CLS
20 REM Colour each character row (INK 1-7, PAPER 0)
30 FOR R=0 TO 23
40 LET C=1+(R-7*INT(R/7))
50 FOR X=0 TO 31
60 POKE 22528+R*32+X,C
70 NEXT X
80 NEXT R
90 REM Fill the bitmap in address order
100 FOR A=16384 TO 22527
110 POKE A,255
120 NEXT A
130 PAUSE 0
