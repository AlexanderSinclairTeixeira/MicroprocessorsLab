#include <xc.inc>

extrn glcd_setup, psel_W, ysel_W, write_strip_W, delay_ms_W, delay_500ns, delay_1us
extrn glcd_status, glcd_read, glcd_page, glcd_y
    
extrn glcd_set_all, glcd_set_pixel_W, glcd_set_rect, glcd_set_8x8_block
extrn glcd_clr_all, glcd_clr_pixel_W, glcd_clr_rect, glcd_clr_8x8_block
extrn glcd_bitnum, glcd_x, glcd_dx, glcd_dy, glcd_Y



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
    call glcd_setup ;initialises ports B and D, turns on both controllers
    call glcd_clr_all ;clears the whole screen
    movlw 0x00
    movwf TRISC, A ;initialise port C for output
    movwf LATC, A
    
    movlw 2
    movwf glcd_Y, A
    movlw 3
    movwf glcd_page, A
    call glcd_set_8x8_block
    goto start

start:
    movlw 0xFF
    call delay_ms_W
    ;call glcd_clr_8x8_block
    incf glcd_Y, A
    ;incf glcd_page, A
    call glcd_set_8x8_block
    goto start

end	    rst