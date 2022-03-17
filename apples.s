#include <xc.inc>
   
global rng_setup_seed, rng_next, apple_XY_to_X_Y ;apple funcs
global random_var, apple_XY, apple_X, apple_Y ;apple vars    

psect udata_acs ;can use 0x30-0x3F
    random_var EQU 0x30
    apple_XY EQU 0x31 ;first nibble is X from 0 to 7, second nibble is Y from 0 to 15
    apple_X EQU 0x32
    apple_Y EQU 0x33

psect	apple_code, class=CODE

rng_setup_seed: ;hardcoded for now, try to get some entropic seed?
    movlw 0x75
    movwf random_var, A
    return
 
rng_next: 
    rlcf random_var, W ;rotate left, store result in W
    xorwf random_var, W ;XOR original with shifte and store result in W
    bsf random_var, 7, A ;assume we were supposed to set the leftmost bit
    btfss WREG, 7, A ;we are trying to move this bit to the original file
	bcf random_var, 7, A ;its clear, so clear the bit in the file
    rlncf random_var, F, A ;rotate left no carry to get the next random number
    incf random_var, A
    incf random_var, A
    return

apple_XY_to_X_Y:
    movlw 0x0F
    andwf apple_XY, W
    movwf apple_Y
    movlw 0x07
    movwf apple_X
    movf apple_XY, W
    swapf WREG, W
    andwf apple_X, F, A
    return
