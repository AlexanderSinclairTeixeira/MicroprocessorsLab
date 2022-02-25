#include <xc.inc>

extrn delay_W_ms, delay_W_4us, delay_count_250ns, delay_500ns
extrn counter_low, counter_high, ms_counter
global keypad_setup, keypad_read, rows, cols

psect udata_acs

rows EQU 0x10
cols EQU 0x11
    
    
psect code
 
keypad_setup:
    movlw 0x00
    movwf TRISC
    movwf TRISD
    movlb 0x0f
    bsf REPU
    clrf LATE, A
    return
    
keypad_read:
    ; PORTE<0:3> inputs, PORTE<4:7> outputs
    movlw 0b00001111
    movwf TRISE, A
    call delay_500ns
    call delay_500ns
    movff PORTE, rows
    
    ; PORTE<0:3> outputs, PORTE<4:7> inputs
    movlw 0b11110000
    movwf TRISE, A
    call delay_500ns
    call delay_500ns
    movff PORTE, cols, A
    
    movff rows, PORTC, A 
    movff cols, PORTD, A
    return
    