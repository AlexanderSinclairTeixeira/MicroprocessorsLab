#include <xc.inc>

;;;;;;GLCD external stuff
extrn glcd_setup, psel_W, ysel_W, read_data, write_strip_W, delay_ms_W ;GLCD basic functions
extrn glcd_status, glcd_read, glcd_page, glcd_y, glcd_write ;GLCD basic variables

extrn glcd_set_all, glcd_set_pixel_W, glcd_set_8x8_block ;GLCD draw funcs - setting
extrn glcd_clr_all, glcd_clr_pixel_W, glcd_clr_8x8_block ;GLCD draw funcs - clearing
extrn glcd_bitnum, glcd_x, glcd_dx, glcd_dy, glcd_Y ;GLCD draw vars

extrn ascii_setup, ascii_write_W ;GLCD ascii funcs
    
;;;;;;game logic external stuff
extrn pos_start, switch_dirn ;direction funcs
extrn head_X, head_Y, dirn, hit_border ;direction vars

extrn rng_seed_setup, rng_next, apple_XY_to_X_Y, glcd_draw_apple ;apple funcs
extrn random_var, apple_XY, apple_X, apple_Y ;apple vars  

;;;;;;buffer external stuff
extrn buffer_init, buffer_write, buffer_read, check_is_full, head_X_Y_to_XY, tail_XY_to_X_Y ;buffer funcs
extrn head_XY, tail_XY, tail_X, tail_Y, full_is ;buffer vars

psect udata_acs
 ;main can use 0x00-0x0F
 ;glcd_basic, glcd_draw and glcd_ascii all share 0x10-0x1F
 ;direction_selection and apples share 0x20-0x2F
 ;buffer can use 0x40-0x48 plus the length of the buffer
    tempvar EQU 0x00

psect	code, abs	
main:
    org	0x0
    goto setup
	
int_hi:
    org 0x08	;high interrupt vector
    
setup:
    org 0x100	; Main code starts here at address 0x100
    ;stuff to do when the PIC18 turns on for the first time
    call portE_setup    
    call glcd_setup ;turn on the screen
    call ascii_setup ;load the ascii character set into bank 2
    call rng_seed_setup ;hardcoded for now
    call rng_next
    call rng_next
    call rng_next
    goto start

start:
    call buffer_init ; set the buffer pointers to the start
    call pos_start ;setup some game logic
    ;draw the starting screen and write to the buffer
    call glcd_clr_all
    REPT 3 ;start with length 3
	call switch_dirn ;increments head_X
	call head_X_Y_to_XY ;updates head_XY from head_X and head_Y
	call buffer_write ;pushes head_XY to the buffer
	call glcd_update_head ;puts head_X to glcd_pge and head_Y to glcd_Y
	call glcd_set_8x8_block ;draw the block
    ENDM
    
    movff random_var, apple_XY ;collect the random number
    call apple_XY_to_X_Y ;split up into apple_X and apple_Y
    call glcd_draw_apple ;place it on the screen
    call rng_next ;prepare a new random number
    goto event_loop ;game is ready to play!

event_loop:
    ;call apple_coverage_test
    ;goto event_loop
    
    movlw 0xFF
    call delay_ms_W ;wait some
    
    comf PORTE, W ;collect data from portE and complement as it had pullups on
    tstfsz WREG, A ;save a test by not writing if no input
        movwf dirn, A ;portE had something so write it
    call switch_dirn ;tests for new direction; if it fails use last valid direction
    btfsc hit_border, 0, A ;are we outside?
	goto game_over
    call head_X_Y_to_XY

    ;here put a test to see if head_XY is the same as apple_XY
    ;act on it
    
    ;here put a test to see if the head is colliding with the rest of the snake
    ;could do this by reading glcd, checking the buffer, checking if its clear ahead or set ahead, etc...
    
    ;we are safe for now so advance...
    call buffer_write ;save the head position
    call glcd_update_head ;get the new position to the glcd values
    call glcd_set_8x8_block ;draw the head
    
    call buffer_read ;read the tail position to tail_position
    call tail_XY_to_X_Y ;convert byte to separate tail_X and tail_Y
    call glcd_update_tail
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

;;;;;;;;;;;;;;;;;;;;;;;;;setup stuff
portE_setup:
    banksel PADCFG1 ;select whichever bank this register is in
    bsf REPU ;activate the pullups on port E
    movlb 0 ;set the BSR to zero again
    clrf LATE, A ;clear the latch just in case
    movlw 0xff
    movwf TRISE, A ;set as input
    return

;;;;;;;;;;;;;;;;;;; shortcut funcs
glcd_update_head:
    movf head_X, W
    movwf glcd_page, A
    movf head_Y, W, A
    movwf glcd_Y, A
    return

glcd_update_tail:
    movf tail_X, W
    movwf glcd_page, A
    movf tail_Y, W, A
    movwf glcd_Y, A
    return
    
glcd_update_apple:
    movf apple_X, W
    movwf glcd_page, A
    movf apple_Y, W, A
    movwf glcd_Y, A
    return

;;;;;;;;;;;;;;;;;;;;;;;;testing stuff
apple_coverage_test:
    movlw 0xFF
    call delay_ms_W ;wait some
    movff random_var, apple_XY ;collect the random number
    call apple_XY_to_X_Y ;split up into apple_X and apple_Y
    call glcd_update_apple
    call glcd_draw_apple ;place it on the screen
    call rng_next ;prepare a new random number
    return

end	main
