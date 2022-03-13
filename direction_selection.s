#include <xc.inc>

extrn glcd_set_all, glcd_clr_all, delay_ms_W
extrn glcd_page, glcd_Y


#define x_max 7
#define y_max 15
#define left 1 ;for literal use only
#define right 2 ;for literal use only
#define up 4 ;for literal use only
#define down 8 ;for literal use only

global pos_start, switch_dirn ;funcs
global x_pos, y_pos, dirn, hit_border ;vars

psect udata_acs ;can use 0x20-0x2F
    x_pos EQU 0x20
    y_pos EQU 0x21
    dirn EQU 0x22 ; save a byte in memory for storing the direction
    hit_border EQU 0x23 ;have we hit the border?
 
psect game_code, class=CODE
pos_start:
    call glcd_clr_all
    ;movlw 0xFF 
    ;movwf TRISE, A ;configure port E as an output
    ;banksel PADCFG1 ;select the bank for pullup cofig
    ;bcf PADCFG1, 6, B ;clearing bit 6 in PADCFG1 activates the weak pullup resistors
    ;set the initial coordiantes
    movlw 3
    movwf x_pos, A
    movwf y_pos, A
    ;movwf PORTH, A
    ;movwf PORTJ, A
    ;set the initial direction
    movlw right
    movwf dirn, A
    movlw 0
    movwf hit_border, A
    return
   
switch_dirn:
    ;movf PORTC, W
    ;addlw 0b11000000
    ;movwf dirn, A
    ;;;;;;movff PORTC, dirn, A
    
    ;is direction == left??
    movlw left
    subwf dirn, W, A
    btfsc STATUS, 2, A ;2 is zero bit
	goto p_left
    
    ;is direction == right??
    movlw right
    subwf dirn, W, A
    btfsc STATUS, 2, A ;2 is zero bit
	goto p_right
    
    ;is direction == up??
    movlw up
    subwf dirn, W, A
    btfsc STATUS, 2 , A ;2 is zero bit
	goto p_up
    
    ;is direction == down??
    movlw down
    subwf dirn, W, A
    btfsc STATUS, 2 , A ;2 is zero bit
	goto p_down
   
    update_posn:
	movf x_pos, W
	movwf glcd_page, A
	movf y_pos, W, A
	movwf glcd_Y, A
    return
   
p_left:
    movf y_pos, W, A
    addlw 0x00 ; update the zero flag
    btfsc STATUS, 2, A ;2 is zero bit
	comf hit_border, A ;is it is set, we have reached zero so game over
    decf y_pos, F, A ;otherwise decrement y
    goto update_posn
   
p_right:
    movlw y_max ;moves 15 to W
    subwf y_pos, W, A ;f - W -> W, i.e. y_pos - y_max
    btfsc STATUS, 0, A ;zero is carry bit
	comf hit_border, A;is it is set, we have reached y_max so game over
    incf y_pos, F, A
    goto update_posn
    
p_up:
    movf x_pos, W, A
    addlw 0x00
    btfsc STATUS, 2, A ;2 is zero bit
	comf hit_border, A;is it is set, we have reached zero so game over
    movlw 1
    subwf x_pos, F, A
    goto update_posn
   
p_down:
    movlw x_max
    subwf x_pos, W, A
    btfsc STATUS, 0, A ;zero is carry bit
	comf hit_border, A;is it is set, we have reached x_max so game over
    movlw 1
    addwf x_pos, F, A
    goto update_posn
