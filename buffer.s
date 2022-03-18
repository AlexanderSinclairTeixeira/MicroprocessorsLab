#include <xc.inc>

extrn x_pos, y_pos
    
global buffer_init, buffer_write, buffer_read, check_is_full, head_position_X_Y_to_XY, tail_position_XY_to_X_Y ;funcs
global head_position, tail_position, tail_X, tail_Y, full_is ;vars
    
psect udata_acs
    buffer_length EQU 5 ;used as a literal for a counter value
    write_pointer EQU 0x40
    read_pointer EQU 0x41
    write_counter EQU 0x42
    read_counter EQU 0x43
    head_position EQU 0x44
    tail_position EQU 0x45
    tail_X EQU 0x46
    tail_Y EQU 0x47
    full_is EQU 0x48
    buffer_start EQU 0x49 ;where the buffer starts, do not use the next buffer_length locations

psect buffer_code, class=CODE
buffer_init:
    movlw 0x00
    movwf write_pointer
    movwf read_pointer
    movlw buffer_length
    movwf write_counter
    movwf read_counter
    movwf full_is
    return

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
;    movwf head_position
;    call buffer_write
;    call buffer_write
;    call buffer_write
;    call buffer_write
;    call buffer_write
;    goto $
   
buffer_write:
    ;set coordinate at the position of the write pointer
    ;increment the fsr
    lfsr 0, buffer_start
    movf write_pointer, W
    movff head_position,PLUSW0
    incf write_pointer
    decfsz write_counter
    return
    call write_reset
    return
   
buffer_read:
    lfsr 0, buffer_start
    movf read_pointer, W
    movff PLUSW0,tail_position
    incf read_pointer
    decfsz read_counter
    return
    call read_reset
    return
   
write_reset:
    movlw buffer_length
    movwf write_counter
    movlw 0
    movwf write_pointer
    return
   
read_reset:
    movlw buffer_length
    movwf read_counter
    movlw 0
    movwf read_pointer
    return
   
check_is_full:
    ;checks if the buffer is full by seeing if the write pointer + 1 is equal to the read pointer
    incf write_pointer
    movf read_pointer, W
    subwf write_pointer
    btfss STATUS,2 ; skips if is full
    return
    movlw 0xFF ;f for full
    movwf full_is, W
    return
    
head_position_X_Y_to_XY:
    movlw 0x07
    andwf x_pos, W ;double check x_pos is 0 to 7
    swapf WREG, W, A ; x_pos in high nibble
    movwf head_position, A
    movlw 0x0F
    andwf y_pos, W ;double check y_pos is 0 to 15
    iorwf head_position, F, A
    return

tail_position_XY_to_X_Y:
    movlw 0x0F
    andwf tail_position, W
    movwf tail_Y
    movlw 0x07
    movwf tail_X
    movf tail_position, W
    swapf WREG, W
    andwf tail_X, F, A
    return