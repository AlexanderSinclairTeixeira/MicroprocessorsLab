#include <xc.inc>

extrn glcd_setup, psel_W, ysel_W, read_data, write_strip_W, delay_ms_W ;GLCD functions
extrn glcd_status, glcd_read, glcd_page, glcd_y, glcd_write ;GLCD variables

extrn glcd_set_all, glcd_set_pixel_W, glcd_set_rect, glcd_set_8x8_block ;GLCD set funcs
extrn glcd_clr_all, glcd_clr_pixel_W, glcd_clr_rect, glcd_clr_8x8_block ;GLCD clr funcs
extrn glcd_bitnum, glcd_x, glcd_dx, glcd_dy, glcd_Y ;GLCD draw vars

extrn pos_start, switch_dirn ;direction funcs
extrn x_pos, y_pos, dirn, hit_border ;direection vars

extrn ascii_setup, ascii_write_W ;ascii funcs

extrn rng_setup_seed, rng_next, apple_XY_to_X_Y, glcd_draw_apple ;apple funcs
extrn random_var, apple_XY, apple_X, apple_Y ;apple vars  

extrn buffer_init, buffer_write, buffer_read, check_is_full, head_position_X_Y_to_XY, tail_position_XY_to_X_Y;buffer funcs
extrn head_position, tail_position, tail_X, tail_Y, full_is ;buffer vars
    
psect udata_acs
 ;main can use 0x00-0x0F
 ;glcd_debug, glcd_draw and ascii_5x8 all share 0x10-0x1F
 ;direction_selection can use 0x20-0x2F
 ;apples can use 0x30-0x3F
 ;buffer can use 0x40-0x4F
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
    call buffer_init ; set the buffer pointers to the start
    call pos_start ;setup some game logic
    
    ;draw the starting screen and write to the buffer
    call glcd_clr_all
    
    REPT 3
       call switch_dirn
	call glcd_set_8x8_block ;draw the starting screen 
	call head_position_X_Y_to_XY
	call buffer_write
    ENDM
    
    movff random_var, apple_XY
    call apple_XY_to_X_Y
    call glcd_draw_apple
    
    goto event_loop

event_loop:
    movlw 0xFF
    call delay_ms_W
    comf PORTE, W
    tstfsz WREG, A
        movwf dirn, A
    call switch_dirn ;moves x_pos and y_pos to glcd_X and glcd_Y automatically
    btfsc hit_border, 0, A
	goto game_over

    call glcd_set_8x8_block ;draw the head
    call head_position_X_Y_to_XY
    call buffer_write ;save the head position
    
    call buffer_read ;read the tail position to tail_position
    call tail_position_XY_to_X_Y ;convert byte to separate tail_X and tail_Y
    movf tail_X, W ;update the glcd 
    movwf glcd_page, A
    movf tail_Y, W, A
    movwf glcd_Y, A
    call glcd_clr_8x8_block ;delete!
    
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
