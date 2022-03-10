#include <xc.inc>

extrn pos_start, switch_dirn    

psect code, abs
rst:
    org 0x0
    goto setup
    
setup:
    movlw 0x00
    movwf TRISH, A ;xpos output
    movwf TRISJ, A ;ypos output
    movwf TRISE, A ;dirn output
    movlw 0xFF
    movwf TRISF, A ; input
    call pos_start

start:
    call switch_dirn
    goto start
    
end	rst