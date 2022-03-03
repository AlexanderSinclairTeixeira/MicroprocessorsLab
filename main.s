#include <xc.inc>

extrn glcd_setup, psel_W, ysel_W, write_strip_W
extrn glcd_status, glcd_read, glcd_page, glcd_y, glcd_strip


psect udata_acs
    y_counter EQU 0x10
 
psect code, abs
rst:
    org 0x0	;reset vector
    goto setup

int_hi:
    org 0x08	;high interrupt vector
    
setup:
    call glcd_setup
    movlw 0x0
    call ysel_W
    movlw 0x0
    call psel_W
    movlw 0x4
    movwf y_counter, A
    goto start

start:
    movlw 0b00110011
    call write_strip_W
    decfsz y_counter,A
    goto start
    movlw 4
    movlw 127
    movwf y_counter, A
    goto start
    goto $

end	    rst