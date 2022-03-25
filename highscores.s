#include <xc.inc>

extrn score

global  load_scores, insert_new_score, write_scores_to_flash ;funcs
global  letter_1st, letter_2nd, letter_3rd, letter_posn, highscores ;vars

psect udata_acs ;can use 0x50 - 0x5F
    temp_value EQU 0x50
    letter_1st EQU 0x51
    letter_2nd EQU 0x52
    letter_3rd EQU 0x53
    score_counter EQU 0x54
    letter_posn EQU 0x55
 
psect data
    ;stores score, letter, letter, letter
    score_table: ds 20

psect udata_bank1 ; reserve data anywhere in RAM (here at 0x100)
    highscores: ds 20 ;reserve 20 bytes for the names and scores

psect highscore_code, class=CODE   
load_scores:
    bcf	CFGS	; point to Flash program memory  
    bsf	EEPGD 	; access Flash program memory
    
    lfsr	0, highscores	; Load FSR0 with address in RAM	
    
    movlw	low highword(score_table)
    movwf	TBLPTRU, A		; load upper bits to TBLPTRU
    
    movlw	high(score_table)
    movwf	TBLPTRH, A		; load high byte to TBLPTRH
    
    movlw	low(score_table)
    movwf	TBLPTRL, A		; load low byte to TBLPTRL
    
    movlw	20	; number of bytes to read
    movwf 	score_counter, A
    loop:
	tblrd*+ ; one byte from PM to TABLAT, post-increment TBLPTR
	movff TABLAT, POSTINC0 ; move data from TABLAT to (FSR0), inc FSR0	
	decfsz score_counter, A ; count down to zero
	bra loop		; keep going until finished
    return
    
insert_new_score:
    movlw 5
    movwf score_counter, A
    lfsr 0, highscores
    check_next:
	; old - new
	movf score, W, A
	subwf INDF0, W, A ; INDF0 - score -> WREG
	btfsc NEGATIVE ; set whe neg, clr whe pos or zero (i.e. player didnt bring anything ew to the table)
	    goto replace
	movlw 4
	addwf FSR0, A
	decfsz score_counter, F, A
	    goto check_next
	return ; score was not high enough to add in
    replace:
	;swap the new score with the old 
	movf INDF0, W, A
	movwf temp_value, A
	movf score, W, A
	movwf POSTINC0, A
	movf temp_value, W, A
	movwf score, A
	;swap the new 1st letter with the old
	movf INDF0, W, A
	movwf temp_value, A
	movf letter_1st, W, A
	movwf POSTINC0, A
	movf temp_value, W, A
	movwf letter_1st, A
	;swap the new 2d letter with the old
	movf INDF0, W, A
	movwf temp_value, A
	movf letter_2nd, W, A
	movwf POSTINC0, A
	movf temp_value, W, A
	movwf letter_2nd, A
	;swap the new 3rd letter with the old
	movf INDF0, W, A
	movwf temp_value, A
	movf letter_3rd, W, A
	movwf POSTINC0, A
	movf temp_value, W, A
	movwf letter_3rd, A
	decfsz score_counter, F, A
	    goto replace
        return
    
write_scores_to_flash:
    ;ERASE_BLOCK
	MOVLW low highword(score_table) ; load TBLPTR with the base
	MOVWF TBLPTRU, A ; address of the memory block
	MOVLW high(score_table)
	MOVWF TBLPTRH, A
	MOVLW low(score_table)
	MOVWF TBLPTRL, A
	BSF EEPGD ; point to Flash program memory
	BCF CFGS ; access Flash program memory
	BSF WREN ; enable write to memory
	BSF FREE ; enable Row Erase operation
	BCF GIE ; disable interrupts
	MOVLW 0x55 ;required sentence
	MOVWF EECON2, A ; write 55h
	MOVLW 0xAA
	MOVWF EECON2, A ; write 0AAh
	BSF WR ; start erase (CPU stall)
	BSF GIE ; re-enable interrupts
	TBLRD*- ; dummy read decrement
	lfsr 0, highscores
    ;WRITE_BUFFER_TO_HREGS
	MOVLW 20 ; number of bytes in holding register
	MOVWF score_counter, A
	WRITE_BYTE_TO_HREGS:
	    MOVFF POSTINC0, WREG ; get low byte of buffer data
	    MOVWF TABLAT, A ; present data to table latch
	    TBLWT+* ; write data, perform a short write
	    ; to internal TBLWT holding register.
	    DECFSZ score_counter, A ; loop until buffers are full
		BRA WRITE_BYTE_TO_HREGS
    ;WRITE_HREGS_TO_PROGMEM
	BSF EEPGD ; point to Flash program memory
	BCF CFGS ; access Flash program memory
	BSF WREN ; enable write to memory
	BCF GIE ; disable interrupts
	MOVLW 0x55
	MOVWF EECON2, A ; write 55h
	MOVLW 0xAA
	MOVWF EECON2, A ; write 0AAh
	BSF WR ; start program (CPU stall)
	BSF GIE ; re-enable interrupts
	BCF WREN ; disable write to memory    
    return