#include <xc.inc>

extrn glcd_setup, psel_W, ysel_W, write_strip_W

psect udata_acs
    y_counter: ds 1
 
psect code, abs
rst:
    org 0x0	;reset vector
    goto setup

int_hi:
    org 0x08	;high interrupt vector
    
setup:
    call glcd_setup
    movlw 32
    movwf y_counter, A
    goto start

start:
    movlw 0
    call psel_W
    call ysel_W
    movlw 0x55
    call write_strip_W
    decfsz y_counter,A
    goto start
    goto $

end	    rst