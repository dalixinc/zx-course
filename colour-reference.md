# Spectrum colours — at a glance

Eight colours, numbered 0 to 7. INK uses that number in bits 2–0 of the attribute byte. PAPER uses the same number shifted up into bits 5–3, which is the same as multiplying by 8.

| Colour  | INK | INK bits 2–0 | PAPER (×8) | PAPER in the attribute byte |
|---------|----:|:------------:|-----------:|:---------------------------:|
| black   |   0 |      000     |          0 |         00000000            |
| blue    |   1 |      001     |          8 |         00001000            |
| red     |   2 |      010     |         16 |         00010000            |
| magenta |   3 |      011     |         24 |         00011000            |
| green   |   4 |      100     |         32 |         00100000            |
| cyan    |   5 |      101     |         40 |         00101000            |
| yellow  |   6 |      110     |         48 |         00110000            |
| white   |   7 |      111     |         56 |         00111000            |

The PAPER binary is the full attribute byte with only the PAPER bits set: bits 5–3 hold the colour, the other bits are 0.

## The attribute byte

```
  bit  7       6       5  4  3    2  1  0
       FLASH   BRIGHT  PAPER      INK
```

The value to `POKE` (or to use in a machine-code load) is:

```
  128 * FLASH  +  64 * BRIGHT  +  8 * PAPER  +  INK
```

FLASH and BRIGHT are 0 or 1. PAPER and INK are 0 to 7.

Black never changes when BRIGHT is set. FLASH swaps INK and PAPER several times a second.

### Example 1 — blue ink, black paper

No flash, no bright, PAPER 0 (black), INK 1 (blue). This is the colour of the first character row in the Lesson 1 program.

```
  128*0  +  64*0  +  8*0  +  1  =  1
  binary:  0 0 000 001    =  00000001
```

### Example 2 — bright yellow ink on blue paper

No flash, BRIGHT 1, PAPER 1 (blue), INK 6 (yellow).

```
  128*0  +  64*1  +  8*1  +  6  =  64 + 8 + 6  =  78
  binary:  0 1 001 110    =  01001110
```

78 is 64 + 8 + 6, which is bit 6, bit 3, and bits 2–1: `01001110`.
