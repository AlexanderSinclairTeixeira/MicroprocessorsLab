#include <xc.inc>

psect udata_acs
#define buffer_start 0x30
#define buffer_end 0x3F ;will increase the length later!!
#define buffer_length 5 ;used for a counter value
write_pointer EQU 0x25
read_pointer EQU 0x26
read_counter EQU 0x27
write_counter EQU 0x28
position EQU 0x29;xy coordiantes in 1 byte

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

start:
    call buffer_write
    goto start
    
buffer_write:
    ;set coordinate at the position of the write pointer
    ;increment the fsr
    lfsr 0, buffer_start
    movf write_pointer, W
    movff position,PLUSW0
    incf write_pointer
    decf position
    decfsz write_counter
    return
    call write_reset
    return
   
buffer_read:
    lfsr 0, buffer_start
    movlw 1
    addwf read_pointer
    movf read_pointer, W
    decfsz read_counter
    call read_reset
    movlw 0xFF
    movwf PLUSW0
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