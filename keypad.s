#include <xc.inc>

;extrn delay_W_ms, delay_W_4us, delay_count_250ns, delay_500ns
extrn delay_W_4us
global keypad_setup, keypad_read

psect udata_acs

col_row_ix EQU 0x10
decode_val EQU 0x20
    
psect code
 
keypad_setup:
    movlw 0x00
    movwf TRISD, A
    movlb 0x0f
    bsf REPU
    clrf LATE, A
    return
    
keypad_read:
    ; PORTE<4:7> outputs, PORTE<0:3> inputs
    movlw 0b00001111
    movwf TRISE, A
    movlw 1
    call delay_W_4us
    movff PORTE, col_row_ix
    
    ; PORTE<4:7> inputs, PORTE<0:3> outputs
    movlw 0b11110000
    movwf TRISE, A
    movlw 1
    call delay_W_4us
    movf PORTE, W, A
    
    iorwf col_row_ix, F, A
    comf col_row_ix, F, A
    
    movff col_row_ix, PORTD, A
    return

keypad_decode:
        
    retlw '1'
    retlw '2'
    retlw '3'
    retlw 'A'
    
    retlw '4'
    retlw '5'
    retlw '6'
    retlw 'B'
    
    retlw '7'
    retlw '8'
    retlw '9'
    retlw 'C'
    
    retlw '*'
    retlw '0'
    retlw '#'
    retlw 'D'
    