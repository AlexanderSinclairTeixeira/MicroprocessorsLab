#include <xc.inc>

extrn delay_W_ms, delay_W_4us, delay_count_250ns, delay_500ns
extrn counter_low, counter_high, ms_counter
global keypad_setup, keypad_read, rows, cols

psect udata_acs

rows ds: 1
cols ds: 1
    
    
psect code
 
keypad_setup:
    banksel 0xF
    bsf PADCFG1, REPU, B
    clrf LATE
    return
    
keypad_read:
    ; PORTE<0:3> inputs, PORTE<4:7> outputs
    movlw 0b00001111
    movwf TRISE, A
    call delay_500ns
    call delay_500ns
    call delay_500ns
    call delay_500ns
    movf PORTE, rows
    
    ; PORTE<0:3> outputs, PORTE<4:7> inputs
    movlw 0b11110000
    movwf TRISE, A
    call delay_500ns
    call delay_500ns
    call delay_500ns
    call delay_500ns
    movf PORTE, cols
    
    movf rows, PORTC    
    movf cols, PORTD
    return
    