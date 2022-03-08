#include <xc.inc>

extrn psel_W, ysel_W, read_data, write_strip_W, delay_ms_W, delay_1us;functions
extrn glcd_status, glcd_read, glcd_page, glcd_y, glcd_write ;variables

global glcd_set_all, glcd_clr_all, glcd_set_pixel_W, glcd_clear_pixel_W, glcd_set_rect, glcd_clear_rect
global glcd_bitnum, glcd_x, glcd_a, glcd_b

psect udata_acs
    glcd_bitnum EQU 0x06
    glcd_x EQU 0x07
    glcd_a EQU 0x08
    glcd_b EQU 0x09
 
psect glcd_code, class=CODE
 
glcd_set_all:
    movlw 0x00
    call psel_W
    movlw 0x00
    call ysel_W
    start_page_set:
	movf glcd_page, W
	call psel_W
	movf glcd_y, W
	call ysel_W
	movlw 0xFF ;;;;;;;;;;;;;
	call write_strip_W
	tstfsz glcd_y, A
	    goto start_page_set
    incf glcd_page, A
    movf glcd_page, W
    andlw 0b00000111 ;make the top bits all zero
    tstfsz WREG, A ;check if page number has overflowed
	goto start_page_set
    return
    
glcd_clr_all:
    movlw 0x00
    call psel_W
    movlw 0x00
    call ysel_W
    start_page_clr:
	movf glcd_page, W
	call psel_W
	movf glcd_y, W
	call ysel_W
	movlw 0x00 ;;;;;;;;;;;;;;;
	call write_strip_W
	tstfsz glcd_y, A
	    goto start_page_clr
    incf glcd_page, A
    movf glcd_page, W
    andlw 0b00000111 ;make the top bits all zero
    tstfsz WREG, A ;check if page number has overflowed
	goto start_page_clr
    return
 
glcd_set_pixel_W:
    ;Using an x value in W, with glcd_y already set
    ;x goes from 0-63, i.e. 0b00000000 - 0b00111111
    andlw 0b00111111 ;set top two to zero
    movwf glcd_x, A
    rrncf WREG, W, A ;divide by 8 to get page number
    rrncf WREG, W, A
    rrncf WREG, W, A
    call psel_W ;automatically handles clearing the top 3 bits
    movlw glcd_y
    call ysel_W
    call read_data
    movf glcd_x, A
    andlw 0b00000111 ;keep only bottom 3, this is the bitnum
    movwf glcd_bitnum, A
;    bsf glcd_read, WREG, A
    movf glcd_read, A
    call write_strip_W
    return

glcd_clear_pixel_W:
    return
    
glcd_set_rect:
    return

glcd_clear_rect:
    return

    