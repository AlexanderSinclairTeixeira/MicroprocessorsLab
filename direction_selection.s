#include <xc.inc>

extrn glcd_page, glcd_Y


#define X_max 7
#define Y_max 15
#define left 1 ;for literal use only
#define right 2 ;for literal use only
#define up 4 ;for literal use only
#define down 8 ;for literal use only

global pos_start, switch_dirn ;funcs
global head_X, head_Y, dirn, hit_border ;vars

psect udata_acs ;can use 0x20-0x2F, but share with apples
    head_X EQU 0x20
    head_Y EQU 0x21
    dirn EQU 0x22 ; save a byte in memory for storing the direction
    dirn_last_valid EQU 0x23
    hit_border EQU 0x24 ;have we hit the border?
 
psect game_code, class=CODE
pos_start:
    ;set the initial coordiantes
    movlw 3
    movwf head_X, A
    movlw 1
    movwf head_Y, A
    ;set the initial direction
    movlw right
    movwf dirn, A
    movwf dirn_last_valid, A
    movlw 0
    movwf hit_border, A
    return
   
switch_dirn:
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
    
    ;direction is neither of these so use last valid direction and switch again
    movff dirn_last_valid, dirn
    goto switch_dirn

   
p_left:
    movf head_Y, W, A
    addlw 0x00 ; update the zero flag
    btfsc STATUS, 2, A ;2 is zero bit
	comf hit_border, A ;is it is set, we have reached zero so game over
    decf head_Y, F, A ;otherwise decrement y
    movff dirn, dirn_last_valid ;update the last valid direction with this newest value
    return
   
p_right:
    movlw Y_max ;moves 15 to W
    subwf head_Y, W, A ;f - W -> W, i.e. head_Y - Y_max
    btfsc STATUS, 0, A ;zero is carry bit
	comf hit_border, A;is it is set, we have reached Y_max so game over
    incf head_Y, F, A
    movff dirn, dirn_last_valid ;update the last valid direction with this newest value
    return
    
p_up:
    movf head_X, W, A
    addlw 0x00
    btfsc STATUS, 2, A ;2 is zero bit
	comf hit_border, A;is it is set, we have reached zero so game over
    movlw 1
    subwf head_X, F, A
    movff dirn, dirn_last_valid ;update the last valid direction with this newest value
    return
   
p_down:
    movlw X_max
    subwf head_X, W, A
    btfsc STATUS, 0, A ;zero is carry bit
	comf hit_border, A;is it is set, we have reached X_max so game over
    movlw 1
    addwf head_X, F, A
    movff dirn, dirn_last_valid ;update the last valid direction with this newest value
    return
