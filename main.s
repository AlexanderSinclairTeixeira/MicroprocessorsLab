#include <xc.inc>

extrn glcd_setup, psel_W, ysel_W, write_strip_W, delay_ms_W
extrn glcd_status, glcd_read, glcd_page, glcd_y


psect udata_acs
    y_counter EQU 0x10
    write_val EQU 0x11
 
psect code, abs
rst:
    org 0x0	;reset vector
    goto setup

int_hi:
    org 0x08	;high interrupt vector
    
setup:
    call glcd_setup
    movlw 0x00
    movwf glcd_page, A
    movwf glcd_y, A
    movwf write_val, A
    REPT 50
	movlw 0xFF
	call delay_ms_W
    ENDM
    goto start

start:
    movf glcd_page, W
    call psel_W
    movf glcd_y, W
    call ysel_W
    movf write_val, W
    call write_strip_W
    incf write_val, A
    tstfsz glcd_y, A
    goto start
    incf glcd_page, A
    movf glcd_page, W
    call psel_W
    movlw 0x00
    movwf write_val, A
    movwf glcd_y, A
    goto start
;    btfss glcd_page, 3, A
;    goto page_end
;    inc_page:
;        incf glcd_page, A
;	movf glcd_page, W
;	call psel_W
;	goto start
;    page_end:
;	comf write_val, A
;	movlw 0xFF
;	call delay_ms_W
;        goto start

end	    rst