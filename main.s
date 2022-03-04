#include <xc.inc>

extrn glcd_setup,psel_W,ysel_W,write_strip_W,LCD_delay_ms, bossman_delay


psect udata_acs
    y_counter EQU 0x10
    page_counter EQU 0x11
 
psect code, abs
rst:
    org 0x0	;reset vector
    goto setup

int_hi:
    org 0x08	;high interrupt vector
    
setup:
    movlw 0
    movwf y_counter
    movwf page_counter
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call glcd_setup
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    movlw 2 
    call psel_W
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    
    call ysel_W
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    goto start
    
write_byte:
    call bossman_delay
    call bossman_delay
    movlw 0b00000000
    call write_strip_W
    call bossman_delay
    call bossman_delay
    return
start:
    call write_byte
    
    goto start

    goto $
    

end	    rst