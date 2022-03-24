#include <xc.inc>
   
global rng_seed_setup, rng_next, apple_XY_to_X_Y ;apple funcs
global random_var, apple_XY, apple_X, apple_Y ;apple vars    

psect udata_acs ;can use 0x20-0x2F, but share with direction_selection
    random_var EQU 0x26
    apple_XY EQU 0x27 ;first nibble is X from 0 to 7, second nibble is Y from 0 to 15
    apple_X EQU 0x28
    apple_Y EQU 0x29

psect	apple_code, class=CODE

rng_seed_setup: ;hardcoded for now, try to get some entropic seed?
    movlw 107
    movwf random_var, A
    return
 
rng_next: ;has a period of 16*8 - 1 !! can we get any better????
    rlcf random_var, W, A ;rotate left, store result in W
    xorwf random_var, W, A ;XOR original with shifte and store result in W
    bsf random_var, 7, A ;assume we were supposed to set the leftmost bit
    btfss WREG, 7, A ;we are trying to move this bit to the original file
	bcf random_var, 7, A ;its clear, so clear the bit in the file
    rlncf random_var, F, A ;rotate left no carry to get the next random number
    movlw 4 ;add for extra randomness! ;)
    addwf random_var, F, A
    return

apple_XY_to_X_Y:
    movlw 0x0F
    andwf apple_XY, W, A
    movwf apple_Y, A
    movlw 0x07
    movwf apple_X, A
    movf apple_XY, W, A
    swapf WREG, W, A
    andwf apple_X, F, A
    return
