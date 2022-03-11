#include <xc.inc>

extrn glcd_setup, psel_W, ysel_W, read_data, write_strip_W, delay_ms_W ;GLCD functions
extrn glcd_status, glcd_read, glcd_page, glcd_y, glcd_write ;GLCD variables

extrn glcd_set_all, glcd_set_pixel_W, glcd_set_rect, glcd_set_8x8_block ;GLCD set funcs
extrn glcd_clr_all, glcd_clr_pixel_W, glcd_clr_rect, glcd_clr_8x8_block ;GLCD clr funcs
extrn glcd_bitnum, glcd_x, glcd_dx, glcd_dy, glcd_Y ;GLCD draw vars

extrn pos_start, switch_dirn ;funcs
extrn x_pos, y_pos, dirn, left, right, up, down ;vars
    
psect udata_acs
    tempvar EQU 0x00

psect	code, abs
	
main:
    org	0x0
    goto setup
	
int_hi:
    org 0x08	;high interrupt vector
    
setup:
    org 0x100	; Main code starts here at address 0x100
    call glcd_setup
    call pos_start
    movff y_pos, glcd_Y
    movff x_pos, glcd_page
    call glcd_set_8x8_block
    goto start

start:
    ;movff PORTC, dirn, A
    ; ----OR-----
    movf PORTC, W
    ;addlw 0b11000000
    ;sublw 0x40
    ;addlw 0xFF
    ;comf WREG, W
    movwf dirn, A
    
    call switch_dirn
    movff y_pos, glcd_Y
    movff x_pos, glcd_page
    call glcd_set_8x8_block
    goto start

end	main
