# ZX Spectrum Next Tests
Feature tests for [ZX Spectrum Next](https://www.specnext.com/) written in Z80 asssembly language.

Build and run with [Zeus](http://www.desdes.com/products/oldfiles/zeus.htm).

## MMUPaging.asm

Comparison of paging the top 16K by writing to port $7FFD (which also pages the ROM into the bottom 16K), and by using the Next MMU registers (which leaves the bottom 16K alone). 

Use the checkbox at the bottom left of the code window to select the options.

## DMACopy.asm

Examples of a DMA screen fill and DMA copy to the screen. With LDIR fill and copy for comparison. 

Use the checkbox at the bottom left of the code window to select the options.

## Level2Order.asm

Examples of setting all six combinations of screen layer order. 

Use the dropdown list at the bottom left of the code window to select the options:

| Value | Top        | Middle     | Bottom     |
| ----- | ---------- | ---------- | ---------- |
| SLU   | Sprites    | Layer 2    | ULA screen |
| LSU   | Layer 2    | Sprites    | ULA screen |
| SUL   | Sprites    | ULA screen | Layer 2    |
| LUS   | Layer 2    | ULA screen | Sprites    |
| USL   | ULA screen | Sprites    | Layer 2    |
| ULS   | ULA screen | Layer 2    | Sprites    |
