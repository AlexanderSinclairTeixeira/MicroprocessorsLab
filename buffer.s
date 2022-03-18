#include <xc.inc>

psect udata_acs
#define buffer_start 0x40
#define buffer_length 5 ;used for a counter value
write_pointer EQU 0x25
read_pointer EQU 0x26
read_counter EQU 0x27
write_counter EQU 0x28
tail_position EQU 0x29
position EQU 0x30
full_is EQU 0x31

psect code, abs
buffer_init:
    movlw 0x55
    movwf position
    movlw 0x00
    movwf write_pointer
    movwf read_pointer
    movlw buffer_length
    movwf write_counter
    movwf read_counter
    movwf full_is

start:
   
 
   
    call buffer_read
    call buffer_read
   
   
    call check_if_full
   
    movlw 0x00
    movwf position
    call buffer_write
    call buffer_write
    call buffer_write
    call buffer_write
    call buffer_write
    goto $
   
buffer_write:
    ;set coordinate at the position of the write pointer
    ;increment the fsr
    lfsr 0, buffer_start
    movf write_pointer, W
    movff position,PLUSW0
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
   
check_if_full:
    ;checks if the buffer is full by seeing if the write pointer + 1 is equal to the read pointer
    incf write_pointer
    movf read_pointer, W
    subwf write_pointer
    btfss STATUS,2 ; skips if is full
    return
    movlw 0xFF ;f for full
    movwf full_is, W
    return