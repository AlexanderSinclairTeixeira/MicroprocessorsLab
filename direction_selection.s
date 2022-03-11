#include <xc.inc>
  
left EQU 1 ;label some useful terms
right EQU 2
up EQU 3
down EQU 4

#define x_max 7
#define y_max 15

global pos_start, switch_dirn ;funcs
global x_pos, y_pos, dirn, left, right, up, down ;vars

psect udata_acs
    left EQU 1 ;for literal use only
    right EQU 2 ;for literal use only
    up EQU 3 ;for literal use only
    down EQU 4 ;for literal use only

    x_pos EQU 0x20
    y_pos EQU 0x21
    dirn EQU 0x22 ; save a byte in memory for storing the direction
 
psect game_code, class=CODE
pos_start:
    movlw 0xFF
    movwf TRISC
    ;set the initial coordiantes
    movlw 3
    movwf x_pos, A
    movwf y_pos, A
    ;movwf PORTH, A
    ;movwf PORTJ, A
    ;set the initial direction
    movlw right
    movwf dirn, A
    return
   
switch_dirn:
    movf PORTC, W
    addlw 0b11000000
    movwf dirn, A
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
   
    output_posn: ;output x to port H and y to port J
	movf x_pos, W, A
	;movwf PORTJ, A
	movf y_pos, W, A
	;movwf PORTH, A
    return
   
p_left:
    movf y_pos, W, A
    addlw 0x00 ; update the zero flag
    btfsc STATUS, 2, A ;2 is zero bit
	goto hit_border ;is it is set, we have reached zero so game over
    decf y_pos, F, A ;otherwise decrement y
    goto output_posn
   
p_right:
    movlw y_max ;moves 15 to W
    subwf y_pos, W, A ;f - W -> W, i.e. y_pos - y_max
    btfsc STATUS, 0, A ;zero is carry bit
	goto hit_border ;is it is set, we have reached y_max so game over
    incf y_pos, F, A
    goto output_posn
    
p_up:
    movf x_pos, W, A
    addlw 0x00
    btfsc STATUS, 2, A ;2 is zero bit
	goto hit_border ;is it is set, we have reached zero so game over
    movlw 1
    subwf x_pos, F, A
    goto output_posn
   
p_down:
    movlw x_max
    subwf x_pos, W, A
    btfsc STATUS, 0, A ;zero is carry bit
	goto hit_border ;is it is set, we have reached x_max so game over
    movlw 1
    addwf x_pos, F, A
    goto output_posn

hit_border:
    movlw 0xFF
    goto pos_start



