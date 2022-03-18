#include <xc.inc>

extrn glcd_setup, psel_W, ysel_W, read_data, write_strip_W, delay_ms_W ;GLCD functions
extrn glcd_status, glcd_read, glcd_page, glcd_y, glcd_write ;GLCD variables

extrn glcd_set_all, glcd_set_pixel_W, glcd_set_rect, glcd_set_8x8_block ;GLCD set funcs
extrn glcd_clr_all, glcd_clr_pixel_W, glcd_clr_rect, glcd_clr_8x8_block ;GLCD clr funcs
extrn glcd_bitnum, glcd_x, glcd_dx, glcd_dy, glcd_Y ;GLCD draw vars

extrn pos_start, switch_dirn ;direction funcs
extrn x_pos, y_pos, dirn, hit_border ;direection vars

extrn ascii_setup, ascii_write_W ;ascii funcs

extrn rng_setup_seed, rng_next, apple_XY_to_X_Y ;apple funcs
extrn random_var, apple_XY, apple_X, apple_Y ;apple vars  
extrn glcd_draw_apple
    
psect udata_acs
 ;main can use 0x00-0x0F
 ;glcd_debug, glcd_draw and ascii_5x8 all share 0x10-0x1F
 ;direction_selection can use 0x20-0x2F
 ;apples can use 0x30-0x3F
    tempvar EQU 0x00

psect	code, abs	
main:
    org	0x0
    goto setup
	
int_hi:
    org 0x08	;high interrupt vector
    
setup:
    org 0x100	; Main code starts here at address 0x100
    
    banksel PADCFG1 ;select whichever bank this register is in
    bsf REPU ;activate the pullups on port E
    movlb 0 ;set the BSR to zero again
    clrf LATE, A ;clear the latch just in case
    movlw 0xff
    movwf TRISE, A ;set as input
    
    call glcd_setup ;turn on the screen
    call ascii_setup ;load the ascii character set into bank 2
    call rng_setup_seed ;hardcoded for now
    goto start

start:
    call glcd_clr_all
    call pos_start ;setup some game logic
    movff y_pos, glcd_Y
    movff x_pos, glcd_page
    ;call glcd_set_8x8_block ;draw the starting screen 
    movff random_var, apple_XY
    call apple_XY_to_X_Y
    call glcd_draw_apple
    goto event_loop

event_loop:
    movlw 0xFF
    call delay_ms_W
    movlw 0xFF
    call delay_ms_W
    movff apple_X, glcd_page
    movff apple_Y, glcd_Y
    call glcd_clr_8x8_block
    call rng_next
    movff random_var, apple_XY
    call apple_XY_to_X_Y
    call glcd_draw_apple
    goto event_loop

    
    
    movlw 0xFF
    call delay_ms_W
    comf PORTE, W
    tstfsz WREG, A
        movwf dirn, A
    call switch_dirn
    btfsc hit_border, 0, A
	goto game_over
    call glcd_set_8x8_block
    goto event_loop
    
game_over:
    call glcd_set_all
    movlw 32
    call ysel_W
    movlw 2
    call psel_W
    IRPC char, GAME
	movlw 'char'
	call ascii_write_W
    ENDM
    movlw " "
    call ascii_write_W
    IRPC char, OVER
	movlw 'char'
	call ascii_write_W
    ENDM
    movlw "!"
    call ascii_write_W
    movlw 0xFF
    call delay_ms_W
    movlw 0xFF
    call delay_ms_W
    movlw 0xFF
    call delay_ms_W
    goto start

    
end	main
