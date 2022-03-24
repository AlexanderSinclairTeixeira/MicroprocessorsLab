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
extrn head_X, head_Y, dirn, restart ;direction vars

extrn rng_seed_setup, rng_next, apple_XY_to_X_Y, glcd_draw_apple ;apple funcs
extrn random_var, apple_XY, apple_X, apple_Y ;apple vars  

;;;;;;buffer external stuff
extrn buffer_init, buffer_write, buffer_read, check_is_full, head_X_Y_to_XY, tail_XY_to_X_Y ;buffer funcs
extrn head_XY, tail_XY, tail_X, tail_Y, full_is ;buffer vars

;;;;;;for the screen stuff
extrn menu_screen, game_over_screen
global difficulty, score, glcd_update_apple, random_var

extrn buffer_search_init
global apple_start, apple_legit

psect udata_acs
 ;main can use 0x00-0x0F
 ;glcd_basic, glcd_draw and glcd_ascii all share 0x10-0x1F
 ;direction_selection and apples share 0x20-0x2F
 ;buffer can use 0x40-0x48, but share with highscores
 ;the buffer itself is stored in bank 0 starting at 0x80
    tempvar EQU 0x00
    difficulty EQU 0x01
    score EQU 0x02
    timer_counter EQU 0x03

psect	code, abs	
main:
    org	0x0
    goto setup
	
int_hi:
    org 0x008	;high interrupt vector
    ;GIE is automatically cleared (no more interrupts)
    decf timer_counter, F, A
    bcf TMR0IF ; bit 2 is interrupt flag (must be cleared in each interrupt)
    retfie ;automatically sets the GIE bit
    
int_lo:
    org 0x018	;low interrupt vector

setup:
    org 0x100	; Main code starts here at address 0x100
    ;stuff to do when the PIC18 turns on for the first time
    call portE_setup    
    call glcd_setup ;turn on the screen
    call ascii_setup ;load the ascii character set into bank 2
    call interrupt_setup ;enable the interrupt bits etc
    call rng_seed_setup ;hardcoded for now
    ;call rng_next
    goto start

start:
    ; start screen and select game mode
    call menu_screen
    call buffer_init ; set the buffer pointers to the start
    call pos_start ;setup some game logic
    movlw 0x0
    movwf score, A
    ;draw the initial screen and write to the buffer
    call glcd_clr_all
    movlw 0xFF
    call delay_ms_W
    movlw 0xFF
    call delay_ms_W
    movlw 0xFF
    call delay_ms_W
    REPT 3 ;start with length 3
	call switch_dirn ;increments head_X
	call head_X_Y_to_XY ;updates head_XY from head_X and head_Y
	call buffer_write ;pushes head_XY to the buffer
	call glcd_update_head ;puts head_X to glcd_pge and head_Y to glcd_Y
	call glcd_set_8x8_block ;draw the block
    ENDM
    
    movf random_var, W, A
    movwf apple_XY, A ;collect the random number
    bcf WREG, 7, A ;clear the top bit as max x value is 7
    call apple_XY_to_X_Y ;split up into apple_X and apple_Y
    call glcd_update_apple
    call glcd_draw_apple ;place it on the screen
    call rng_next ;prepare a new random number
    call timer0_setup
    goto event_loop ;game is ready to play!

event_loop:
    ;poll portE for input
    ;;;changed comf PORTE to movf LATE for SIMULATOR
    comf PORTE, W, A ;collect data from portE and complement as it had pullups on
    tstfsz WREG, A ;save a test by not writing if no input
        movwf dirn, A ;portE had something so write it
    
    ;check if out timer has run out and we need to advance
    movf timer_counter, W, A
    btfsc ZERO ;has the countdown finished? ;;;commented out for SIMULATOR 
        call advance ;step forward
    btfss restart, 0, A ;do we need to restart?
        goto event_loop ;no, return to top of event loop
    goto start ;yes, go back to the start
    
advance:
    ;reset the counter so it starts ticking down again
    movf difficulty, W, A
    movwf timer_counter, A
    ;tests for new direction and advance
    call switch_dirn ; if it fails use last valid direction
    ;this automatically checks if we have hit the border
    btfsc restart, 0, A ;are we outside?
	goto game_over_screen
    ;if not then it automatically advances head_X or head_Y by 1
    call head_X_Y_to_XY ;split to head_X and head_Y
    call glcd_update_head ;push the new position to the glcd values
    
    test_apple:        
	;test to see if head_XY is the same as apple_XY
	movf apple_XY, W, A
	subwf head_XY, W, A
	btfss ZERO ; check if the apple coords are the same as the new head coords
	    goto test_empty ;it is clear so we did not eat, go to next test
	;hence we ate an apple so the next spot is safe
	call buffer_write ;save the head position
	call glcd_set_8x8_block ;draw the head
	incf score, F, A
	apple_start:
	    movf random_var, W, A
	    bcf WREG, 7, A ;clear the top bit as max x value is 7
	    movwf apple_XY, A ;collect the random number
	    call rng_next ;prepare a new random number
	    goto buffer_search_init
	    apple_legit:
	    call apple_XY_to_X_Y ;split up into apple_X and apple_Y
	    call glcd_update_apple
	    call glcd_draw_apple ;place it on the screen
	return ;no need to delete the tail
    
    test_empty:
	;test to see if the head is colliding with the rest of the snake
	movf glcd_Y, W, A ;must be 0 - 15, i.e. 0b00000000 to 0b00001111
	andlw 0b00001111 ;make sure it doesnt overflow
	rlncf WREG, W, A ;multiply by 8
	rlncf WREG, W, A
	rlncf WREG, W, A
	call ysel_W
	movf glcd_page, W, A
	call psel_W
	call read_data ;read from the glcd to glcd_read
	movf glcd_read, W, A ;collect it
	btfss ZERO ;check if it is empty
	    goto game_over_screen ; not empty so you bit yourself!
	;we are safe for now so draw the first block...
	call buffer_write ;save the head position
	call glcd_set_8x8_block ;draw the head
	;...and delete the last block
	call buffer_read ;read the tail position to tail_position
	call tail_XY_to_X_Y ;convert byte to separate tail_X and tail_Y
	call glcd_update_tail
	call glcd_clr_8x8_block ;delete!
	return

;;;;;;;;;;;;;;;;;;;;;;;;setup stuff
portE_setup:
    banksel PADCFG1 ;select whichever bank this register is in
    bsf REPU ;activate the pullups on port E
    movlb 0 ;set the BSR to zero again
    clrf LATE, A ;clear the latch just in case
    movlw 0xff
    movwf TRISE, A ;set as input
    return
    
timer0_setup:
    ;T0PS<2:0> sets the prescaler (from 111->256x down to 000->2x)
    ; 110 -> 128x
    ;banksel T0CON
    bsf T0PS2 ; bit 2 of the prescaler
    bsf T0PS1 ; bit 1 of the prescaler
    bcf T0PS0 ; bit 0 of the prescaler
    ; now setup the remaining bits
    bcf PSA ; bit 3 is prescaler assignment, clear for prescaler output
    ; bit 4 is for rising/falling edge for external clock sources, so we do not care
    bcf T0CS ; bit 5 is clock source (clear for use as a timer, F_osc/4)
    bsf T08BIT ; bit 6 is set for 8 bit, clear for 16 bit
    bsf TMR0ON ; bit 7 is timer enable (set for on)
    return
  
interrupt_setup:
    ;;;;bcf TMR7GIE ;this for the SIMULATOR being buggy
    bsf IPEN ;Interrupt Priority Enable bit (set to enable priority levels)
    bsf GIEH ;bit 7 is Global Interrupt Enable High (when IPEN is set), set to enable
    bsf GIEL;bit 6 is Global Interrupt Enable Low (when IPEN is set), set to enable
    bsf TMR0IE ; bit 5 is timer0 Interrupt Enable, set to enable
    bcf TMR0IF ; bit 2 is interrupt flag (must be cleared in each interrupt)
    return    
    
;;;;;;;;;;;;;;;;;;; shortcut funcs
glcd_update_head:
    movf head_X, W, A
    movwf glcd_page, A
    movf head_Y, W, A
    movwf glcd_Y, A
    return

glcd_update_tail:
    movf tail_X, W, A
    movwf glcd_page, A
    movf tail_Y, W, A
    movwf glcd_Y, A
    return
    
glcd_update_apple:
    movf apple_X, W, A
    movwf glcd_page, A
    movf apple_Y, W, A
    movwf glcd_Y, A
    return

end	main
