#include <xc.inc>

global random_var, apple_XY, apple_X, apple_Y ;apple vars    

psect udata_acs ;can use 0x30-0x3F
    random_var EQU 0x30
    apple_XY EQU 0x31
    apple_X EQU 0x32
    apple_Y EQU 0x33

psect	apple_code, class=CODE

rng_setup_seed:
    movlw 0x54
    movwf random_var, A
    return
 
rng_next: 
    rlcf random_var, W ;rotate left, store result in W
    xorwf random_var, W ;XOR original with shifte and store result in W
    bsf random_var, 7, A ;assume we were supposed to set the leftmost bit
    btfss WREG, 7, A ;we are trying to move this bit to the original file
	bcf random_var, 7, A ;its clear, so clear the bit in the file
    rlncf random_var, F, A ;rotate left no carry to get the next random number
    return




