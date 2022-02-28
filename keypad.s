#include <xc.inc>

;extrn delay_W_ms, delay_W_4us, delay_count_250ns, delay_500ns
extrn delay_W_4us
global keypad_setup, keypad_read, keypad_decode

psect udata_acs

col_ix EQU 0x10
row_ix EQU 0x11
temp_counter EQU 0x12
decode_val EQU 0x13
    
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
    movff PORTE, col_ix
    comf col_ix, F, A

    ; PORTE<4:7> inputs, PORTE<0:3> outputs
    movlw 0b11110000
    movwf TRISE, A
    movlw 1
    call delay_W_4us
    movff PORTE, row_ix
    comf row_ix, F, A
    return

keypad_decode:
    movf row_ix, W, A
    andwf col_ix, W, A
    tstfsz WREG, A
    goto nonzero
    retlw 0
    nonzero:
	swapf row_ix, F, A
	movlw 0 
	movwf decode_val, A
	movlw 4
	movwf temp_counter, A
    loop1:
	btfss row_ix, 0, A
	goto loop2
	rrcf row_ix, F, A
	bcf STATUS, STATUS_C_POSN, A
	addwf decode_val, F, A
	decfsz temp_counter, F, A
	goto loop1
    movwf temp_counter, A
    loop2:
	btfss col_ix, 0, A
	goto lookup
	rrcf col_ix, F, A
	bcf STATUS, STATUS_C_POSN, A
	incf decode_val, F, A
	decfsz temp_counter, F, A
	goto loop2
    lookup:
    goto $ + 2 + decode_val
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

	retlw 'X'
    