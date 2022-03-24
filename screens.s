#include <xc.inc>

extrn glcd_update_apple ;main_funcs
extrn difficulty, score, random_var ;main vars

extrn psel_W, ysel_W, write_strip_W, delay_ms_W ;GLCD basic functions
extrn glcd_page ;GLCD basic vars

extrn glcd_set_all, glcd_clr_all, glcd_clr_8x8_block, glcd_draw_left, glcd_draw_right, glcd_draw_up, glcd_draw_down ; GLCD draw funcs
extrn glcd_Y ;GLCD draw vars

extrn ascii_write_W ;GLCD ascii funcs

extrn apple_XY_to_X_Y, rng_next, glcd_draw_apple ;apple funcs
extrn apple_XY ;apple vars

global menu_screen, game_over_screen

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
    ;;;;;;
    ;put the top 5 scores on rows 2-6
    ;;;;;;
    movlw 7
    call psel_W
    movlw 0
    call ysel_W
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
;    call glcd_draw_left
;    call glcd_draw_right
;    call glcd_draw_up
;    call glcd_draw_down
;    movlw " "
;    call ascii_write_W
    IRPC char, KEY
	movlw 'char'
	call ascii_write_W
    ENDM
    movlw " "
    call ascii_write_W
    IRPC char, T
	movlw 'char'
	call ascii_write_W
    ENDM
;    movlw " "
;    call ascii_write_W
;    IRPC char, RETUR
;	movlw 'char'
;	call ascii_write_W
;    ENDM
;    movlw "N"
;    call ascii_write_W
    
    highscores_loop:
	movlw 0xFF
	call delay_ms_W
	comf PORTE, W, A ;poll PORTE
	btfsc ZERO ; has anything been pressed?
	    goto highscores_loop
	return

game_over_screen:
    bcf TMR0ON ; bit 7 is timer enable (clear for off)
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
    movf score, W, A
    addlw 0x30 ;only works for single digits for now!!!
    call ascii_write_W
    
    movlw 0xFF
    call delay_ms_W
    movlw 0xFF
    call delay_ms_W
    movlw 0xFF
    call delay_ms_W
    movlw 0xFF
    call delay_ms_W
    movlw 0xFF
    call delay_ms_W
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


