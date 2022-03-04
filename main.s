#include <xc.inc>

extrn glcd_setup,psel_W,ysel_W,write_strip_W,LCD_delay_ms, bossman_delay


psect udata_acs
    y_counter EQU 0x10
    page_counter EQU 0x11
    page_counter_i EQU 0x12
 
psect code, abs
rst:
    org 0x0	;reset vector
    goto setup

int_hi:
    org 0x08	;high interrupt vector
    
setup:
    movlw 63
    movwf y_counter
    movlw 0 
    movwf page_counter
    movlw 8 
    movwf page_counter_i
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
    movlw 0 
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
    movlw 0x3D
    call write_strip_W
    call bossman_delay
    call bossman_delay
    return
start:
    call write_byte
    decfsz y_counter
    goto start
    incf page_counter
    decfsz page_counter_i
    goto next
    goto ends
next:
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    
    movf page_counter, W 
    call psel_W 
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    movlw 0
    call ysel_W
    
    goto start
    goto $
    
ends:
    goto $
end	    rst