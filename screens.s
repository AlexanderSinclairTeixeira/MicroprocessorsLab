#include <xc.inc>

extrn glcd_update_apple, bin_to_BCD ;main_funcs
extrn difficulty, score, score_H, score_T, score_O, random_var, tempvar ;main vars

extrn psel_W, ysel_W, write_strip_W, delay_ms_W ;GLCD basic functions
extrn glcd_y, glcd_page ;GLCD basic vars

extrn glcd_set_all, glcd_clr_all, glcd_clr_8x8_block, glcd_draw_left, glcd_draw_right, glcd_draw_up, glcd_draw_down ; GLCD draw funcs
extrn glcd_Y ;GLCD draw vars

extrn ascii_write_W ;GLCD ascii funcs

extrn apple_XY_to_X_Y, rng_next, glcd_draw_apple ;apple funcs
extrn apple_XY ;apple vars

extrn insert_new_score, write_scores_to_flash
extrn letter_1st, letter_2nd, letter_3rd, letter_posn ;score vars

extrn dirn

;extrn highscores
highscores EQU 0x100

global menu_screen, game_over_screen
extrn tempvar2
#define left 1 ;for literal use only
#define right 2 ;for literal use only
#define up 4 ;for literal use only
#define down 8 ;for literal use only

;literal values only
easy EQU 100
med EQU 60
hard EQU 40

psect screen_code, class=CODE
menu_screen:
    call glcd_clr_all
    ; (empty)
    movlw 1         ; SNAKE!
    call psel_W
    movlw 44
    call ysel_W
    IRPC char, SNAKE
	movlw 'char'
	call ascii_write_W
    ENDM
    movlw "!"
    call ascii_write_W
    ; (empty)  
    movlw 3	    ; EASY <
    call psel_W
    movlw 24
    call ysel_W
    IRPC char, EASY
	movlw 'char'
	call ascii_write_W
    ENDM
    movlw 98
    call ysel_W
    call glcd_draw_left
    
    movlw 4	     ; MEDIUM ^
    call psel_W
    movlw 24
    call ysel_W
    IRPC char, MEDIUM
	movlw 'char'
	call ascii_write_W
    ENDM
    movlw 98
    call ysel_W
    call glcd_draw_up
    
    movlw 5	    ; HARD >
    call psel_W
    movlw 24
    call ysel_W
    IRPC char, HARD
	movlw 'char'
	call ascii_write_W
    ENDM
    movlw 98
    call ysel_W
    call glcd_draw_right
    
    movlw 6	        ; HIGHSCORES V
    call psel_W
    movlw 24
    call ysel_W
    IRPC char, HIGHSCORES
	movlw 'char'
	call ascii_write_W
    ENDM
    movlw 98
    call ysel_W
    call glcd_draw_down
    
    movlw 0x0
    movwf difficulty, A
    movlw 0xFF
    call delay_ms_W
    goto switch_difficulty

switch_difficulty:
    comf PORTE, W, A ;collect data from portE and complement as it had pullups on
    ;movf LATE, W, A ;;; add this for the SIMULATOR
    movwf difficulty, A
    ;is difficulty == left??
    movlw left
    subwf difficulty, W, A
    btfsc STATUS, 2, A ;2 is zero bit
	goto q_left
    
    ;is difficulty right??
    movlw right
    subwf difficulty, W, A
    btfsc STATUS, 2, A ;2 is zero bit
	goto q_right
    
    ;is difficulty up??
    movlw up
    subwf difficulty, W, A
    btfsc STATUS, 2 , A ;2 is zero bit
	goto q_up
    
    ;is difficulty down??
    movlw down
    subwf difficulty, W, A
    btfsc STATUS, 2 , A ;2 is zero bit
	goto q_down
    
    ;direction is neither of these so use last valid direction and switch again
    goto switch_difficulty
    
    q_left:
	movlw easy
	movwf difficulty, A
	return

    q_up:
	movlw med
	movwf difficulty, A
	return
	
    q_right:
	movlw hard
	movwf difficulty, A
	return
	
    q_down:
	call highscores_screen
	goto menu_screen
	
highscores_screen:
    call glcd_clr_all
    movlw 0  
    call psel_W
    movlw 24
    call ysel_W
    IRPC char, HIGHSCORES
	movlw 'char'
	call ascii_write_W
    ENDM
    movlw 2
    call psel_W
    movlw 24
    call ysel_W
    
    lfsr 1, highscores
    movlw 5
    movwf tempvar2, A
    print_line:
	movf POSTINC1, W, A
	movwf score, A
	call bin_to_BCD
	IRP score_digit, score_H, score_T, score_O
	    movf score_digit, W, A
	    addlw 0x30 ;convert to ascii number
	    call ascii_write_W
	ENDM
	
	    movf POSTINC1, W, A
	    ;addlw 0x41 ;convert to ascii letter
	    call ascii_write_W
	    movf POSTINC1, W, A
	    ;addlw 0x41 ;convert to ascii letter
	    call ascii_write_W
	    movf POSTINC1, W, A
	    ;addlw 0x41 ;convert to ascii letter
	    call ascii_write_W

	incf glcd_page, A
	movf glcd_page, W, A
	call psel_W
	movlw 24
	call ysel_W
    decfsz tempvar2, F, A
	goto print_line
    IRPC char, PRESS
	movlw 'char'
	call ascii_write_W
    ENDM
    movlw " "
    call ascii_write_W
    IRPC char, ANY
	movlw 'char'
	call ascii_write_W
    ENDM
    movlw " "
    call ascii_write_W    
    IRPC char, KEY
	movlw 'char'
	call ascii_write_W
    ENDM
    
    highscores_loop:
	movlw 0xFF
	call delay_ms_W
	comf PORTE, W, A ;poll PORTE
	;movf LATE, W, A ;;;;; for the SIMULATOR
	btfsc ZERO ; has anything been pressed?
	    goto highscores_loop
	return

game_over_screen:
    bcf TMR2ON ; bit 7 is timer enable (clear for off)
    call glcd_set_all
    movlw 1
    movwf glcd_Y, A
    movwf glcd_page, A
    REPT 6
	movlw 1
	movwf glcd_Y, A
	REPT 14
	    call glcd_clr_8x8_block
	    incf glcd_Y, F, A
	    movlw 10
	    call delay_ms_W
	ENDM
	incf glcd_page, F, A
	movlw 60
	call delay_ms_W
    ENDM
    movlw 32
    call ysel_W
    movlw 2
    call psel_W
    IRPC char, GAME
	movlw 'char'
	call ascii_write_W
	movlw 100
	call delay_ms_W
    ENDM
    movlw " "
    call ascii_write_W
    IRPC char, OVER
	movlw 'char'
	call ascii_write_W
	movlw 100
	call delay_ms_W
    ENDM
    movlw "!"
    call ascii_write_W
    
    movlw 32
    call ysel_W
    movlw 3
    call psel_W
    IRPC char, SCORE
	movlw 'char'
	call ascii_write_W
	movlw 100
        call delay_ms_W
    ENDM
    movlw " "
    call ascii_write_W
    call bin_to_BCD
    IRP score_digit, score_H, score_T, score_O
	movf score_digit, W, A
	addlw 0x30
	call ascii_write_W
    ENDM
    movlw 'A'
    movwf letter_1st
    movwf letter_2nd
    movwf letter_3rd
    movlw 1
    movwf letter_posn, A
    movlw 0
    movwf dirn, A
    call enter_name
    return

draw_letters:
    movlw 44
    call ysel_W
    movlw 5
    call psel_W
    call glcd_draw_left
    IRP letter_x, letter_1st, letter_2nd, letter_3rd
        incf glcd_y, A
	movf letter_x, W, A
        call ascii_write_W
	incf glcd_y, A
    ENDM
    call glcd_draw_right
    return

enter_name:
    call draw_select_arrows
    call draw_letters
    call switch_letter
    movf letter_posn, W, A
    btfsc ZERO ;do we want to go back?
	return
    sublw 4
    btfsc ZERO
	goto save_score
    goto enter_name
    save_score:
	call insert_new_score
	;call write_scores_to_flash
	return
    
draw_select_arrows:
    IRP row, 4, 6
        movlw row
	movwf glcd_page, A
	movlw 4
	movwf glcd_Y, A
	REPT 8
	    call glcd_clr_8x8_block
	    incf glcd_Y, A
	ENDM
    ENDM
    call letter_posn_to_glcd_y
    movf glcd_y, W, A
    call ysel_W
    movlw 4
    call psel_W
    call glcd_draw_up
    call letter_posn_to_glcd_y
    movf glcd_y, W, A
    call ysel_W
    movlw 6
    call psel_W
    call glcd_draw_down
    return

letter_posn_to_glcd_y:
    movf letter_posn, W, A
    mullw 8
    movf PRODL, W, A
    addlw 44
    movwf glcd_y, A
    return
    
switch_letter:
    movlw 0xFF
    call delay_ms_W
    comf PORTE, W, A ;collect data from portE and complement as it had pullups on
    ;movf LATE, W, A ;;;;;;;for the SIMULATOR
    movwf dirn, A
    ;is dirn == left??
    movlw left
    subwf dirn, W, A
    btfsc STATUS, 2, A ;2 is zero bit
	goto l_left
    ;is dirn == right??
    movlw right
    subwf dirn, W, A
    btfsc STATUS, 2, A ;2 is zero bit
	goto l_right
    ;is dirn == up??
    movlw up
    subwf dirn, W, A
    btfsc STATUS, 2 , A ;2 is zero bit
	goto l_up
    ;is dirn == down??
    movlw down
    subwf dirn, W, A
    btfsc STATUS, 2 , A ;2 is zero bit
	goto l_down
    ;direction is neither of these so use last valid direction and switch again
    goto switch_letter
    l_left:
	decf letter_posn, A
	return
    l_right:
	incf letter_posn, A
	return
    l_up:
	call mov_letter_W
	decf WREG, W, A
	call mov_W_letter
	sublw 65
	btfsc CARRY
	    call underflowed
	return
    l_down:
	call mov_letter_W
	incf WREG, W, A
	call mov_W_letter
	sublw 91
	btfsc ZERO
	    call overflowed
	return
	
underflowed:
    movlw 90
    call mov_W_letter
    return

overflowed:
    movlw 65
    call mov_W_letter
    return

mov_letter_W:
    movlw 1
    cpfsgt letter_posn
	goto letter_1st_to_W
    movlw 2
    cpfsgt letter_posn
	goto letter_2nd_to_W
    letter_3rd_to_W:
	movf letter_3rd, W, A
	return
    letter_1st_to_W:
	movf letter_1st, W, A
	return
    letter_2nd_to_W:
	movf letter_2nd, W, A
	return

mov_W_letter:
    movwf tempvar
    movlw 1
    cpfsgt letter_posn
	goto it_was_1
    movlw 2
    cpfsgt letter_posn
	goto it_was_2
    it_was_3:
	movf tempvar, W, A
	movwf letter_3rd, A
	return
    it_was_1:
    	movf tempvar, W, A
	movwf letter_1st, A
	return
    it_was_2:
    	movf tempvar, W, A
	movwf letter_2nd, A
	return	

;;;;;;;;;;;;;;;;;;;;;;;;testing stuff
apple_coverage_test:
    ;put the next two lines at the start of the main loop
    ;call apple_coverage_test
    ;goto event_loop
    movlw 0xFF
    call delay_ms_W ;wait some
    movff random_var, apple_XY ;collect the random number
    call apple_XY_to_X_Y ;split up into apple_X and apple_Y
    call glcd_update_apple
    call glcd_draw_apple ;place it on the screen
    call rng_next ;prepare a new random number
    return


