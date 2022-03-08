#include <xc.inc>

extrn glcd_setup, psel_W, ysel_W, write_strip_W, delay_ms_W, delay_500ns, delay_1us
extrn glcd_status, glcd_read, glcd_page, glcd_y
    
extrn glcd_set_all, glcd_clr_all, glcd_set_pixel_W, glcd_clear_pixel_W, glcd_set_rect, glcd_clear_rect
extrn glcd_bitnum, glcd_x, glcd_a, glcd_b



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
    call glcd_clr_all    
    movlw 0x00
    movwf TRISC, A
    movwf LATC, A
    
    goto start

start:
;    goto start
    call glcd_set_all
    comf LATC, A
    call glcd_clr_all
    comf LATC, A
    goto start
    
;	goto $
;	movf glcd_page, W, A
;	call psel_W
;	movf glcd_y, W, A
;	call ysel_W
;	movf write_val, W, A
;	call write_strip_W
;	incf write_val, A
;	tstfsz glcd_y, A
;	    goto start
;    incf glcd_page, A
;    movf glcd_page, W, A
;    call psel_W
;    movlw 0x00
;    movwf write_val, A
;    movwf glcd_y, A
;    goto start

end	    rst