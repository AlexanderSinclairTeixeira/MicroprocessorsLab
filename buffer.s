#include <xc.inc>

extrn head_X, head_Y
    
global buffer_init, buffer_write, buffer_read, check_is_full, head_X_Y_to_XY, tail_XY_to_X_Y ;funcs
global head_XY, tail_XY, tail_X, tail_Y, full_is ;vars
    
psect udata_acs
    write_offset EQU 0x40
    read_offset EQU 0x41
    write_counter EQU 0x42
    read_counter EQU 0x43
    head_XY EQU 0x44
    tail_XY EQU 0x45
    tail_X EQU 0x46
    tail_Y EQU 0x47
    full_is EQU 0x48
    buffer_start EQU 0x49 ;where the buffer starts, do not use the next buffer_length locations
    buffer_length EQU 5 ;used as a literal for the maximum length of the buffer (for now, do not exceed 0x5F!)

psect buffer_code, class=CODE
buffer_init:
    ;reset the counters and the buffers to the start
    movlw 0x00
    movwf write_offset, A
    movwf read_offset, A
    movlw buffer_length
    movwf write_counter, A
    movwf read_counter, A
    movwf full_is, A
    return

   
buffer_write: ;writes the head_XY to the write pointer and increments, looping back around if necessary
    lfsr 0, buffer_start ;uses 12-bit word
    movf write_offset, W, A
    movff head_XY, PLUSW0
    incf write_offset, A
    decfsz write_counter, A
	return
    call write_reset
    return
   
buffer_read: ;reads the tail_XY to the read pointer and increments, looping back around if necessary
    lfsr 0, buffer_start
    movf read_offset, W, A
    movff PLUSW0, tail_XY
    incf read_offset, A
    decfsz read_counter, A
	return
    call read_reset
    return
   
write_reset:
    movlw buffer_length
    movwf write_counter, A
    movlw 0
    movwf write_offset, A
    return
   
read_reset:
    movlw buffer_length
    movwf read_counter, A
    movlw 0
    movwf read_offset, A
    return
   
check_is_full:
    ;checks if the buffer is full by seeing if the write pointer + 1 is equal to the read pointer
    incf write_offset, A
    movf read_offset, W, A
    subwf write_offset, A
    btfss STATUS,2 ; skips if is full
	return
    movlw 0xFF ;f for full
    movwf full_is, W, A
    return
    
head_X_Y_to_XY:
    movlw 0x07
    andwf head_X, W, A;double check x_pos is 0 to 7
    swapf WREG, W, A ; x_pos in high nibble
    movwf head_XY, A
    movlw 0x0F
    andwf head_Y, W, A ;double check y_pos is 0 to 15
    iorwf head_XY, F, A
    return

tail_XY_to_X_Y:
    movlw 0x0F
    andwf tail_XY, W, A
    movwf tail_Y, A
    movlw 0x07
    movwf tail_X, A
    movf tail_XY, W, A
    swapf WREG, W, A
    andwf tail_X, F, A
    return
    
;;;;;;;;;;;;;;
;start_buffer: debugging purposes
;   
; 
;   
;    call buffer_read
;    call buffer_read
;   
;   
;    call check_if_full
;   
;    movlw 0x00
;    movwf head_XY
;    call buffer_write
;    call buffer_write
;    call buffer_write
;    call buffer_write
;    call buffer_write
;    goto $