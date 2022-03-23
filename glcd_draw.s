#include <xc.inc>

extrn psel_W, ysel_W, read_data, write_strip_W, delay_ms_W, delay_1us;functions
extrn glcd_status, glcd_read, glcd_page, glcd_y, glcd_write ;variables

global glcd_set_all, glcd_set_pixel_W, glcd_set_8x8_block, glcd_draw_apple, glcd_draw_left, glcd_draw_right, glcd_draw_up, glcd_draw_down
global glcd_clr_all, glcd_clr_pixel_W, glcd_clr_8x8_block
global glcd_bitnum, glcd_x, glcd_dx, glcd_dy, glcd_Y

psect udata_acs ;can use 0x10-0x1F, but share with glcd_basic and ascii_5x8
    glcd_bitnum EQU 0x16
    glcd_x EQU 0x17 ;x-coord of pixel
    glcd_dx EQU 0x18 ;change in x rect
    glcd_dy EQU 0x19 ;change in y rect
    glcd_Y EQU 0x1A ;block y from 0 to 15
 
psect glcd_code, class=CODE
glcd_set_all:
    movlw 0x00
    call psel_W
    movlw 0x00
    call ysel_W
    start_page_set:
	movf glcd_page, W, A
	call psel_W
	movf glcd_y, W, A
	call ysel_W
	movlw 0xFF ;;;;;;;;;;;;;
	call write_strip_W
	tstfsz glcd_y, A
	    goto start_page_set
    incf glcd_page, A
    movf glcd_page, W, A
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
	movf glcd_page, W, A
	call psel_W
	movf glcd_y, W, A
	call ysel_W
	movlw 0x00 ;;;;;;;;;;;;;;;
	call write_strip_W
	tstfsz glcd_y, A
	    goto start_page_clr
    incf glcd_page, A
    movf glcd_page, W, A
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
    movf glcd_y, W, A
    call ysel_W
    call read_data
    movf glcd_x, W, A
    andlw 0b00000111 ;keep only bottom 3, this is the bitnum
    movwf glcd_bitnum, A
    call bin_to_idx ;convert glcd_bitnum to index in-place
    movf glcd_read, W, A
    iorwf glcd_bitnum, W, A
    call write_strip_W
    return

glcd_clr_pixel_W:
    ;Using an x value in W, with glcd_y already set
    ;x goes from 0-63, i.e. 0b00000000 - 0b00111111
    andlw 0b00111111 ;set top two to zero
    movwf glcd_x, A
    rrncf WREG, W, A ;divide by 8 to get page number
    rrncf WREG, W, A
    rrncf WREG, W, A
    call psel_W ;automatically handles clearing the top 3 bits
    movf glcd_y, W, A
    call ysel_W
    call read_data
    movf glcd_x, A
    andlw 0b00000111 ;keep only bottom 3, this is the bitnum
    movwf glcd_bitnum, A
    call bin_to_idx ;convert glcd_bitnum to index in-place
    comf glcd_bitnum, A ;invert because we want to clear this bit
    movf glcd_read, W, A
    andwf glcd_bitnum, W, A
    call write_strip_W
    return
    
;;;;;;;incomplete
;glcd_set_rect:
;    ;glcd_x, glcd_y, glcd_dx, glcd_dy all set already
;    movf glcd_y, A
;    call psel_W
;    return
;
;glcd_clr_rect:
;    return

glcd_set_8x8_block:
    ;paint an 8x8 block with glcd_Y already set
    movf glcd_Y, W, A ;must be 0 - 15, i.e. 0b00000000 to 0b00001111
    andlw 0b00001111 ;make sure it doesnt overflow
    rlncf WREG, W, A ;multiply by 8
    rlncf WREG, W, A
    rlncf WREG, W, A
    call ysel_W
    movf glcd_page, W, A
    call psel_W
    movlw 0xFF
    REPT 8
        call write_strip_W
    ENDM    
    return
    
glcd_clr_8x8_block:
        ;paint an 8x8 block with glcd_Y already set
    movf glcd_Y, W, A ;must be 0 - 15, i.e. 0b00000000 to 0b00001111
    andlw 0b00001111 ;make sure it doesnt overflow
    rlncf WREG, W, A ;multiply by 8
    rlncf WREG, W, A
    rlncf WREG, W, A
    call ysel_W
    movf glcd_page, W, A
    call psel_W
    movlw 0x00
    REPT 8
        call write_strip_W
    ENDM    
    return

glcd_draw_apple:
    ;paint an 8x8 apple with glcd_X and glcd_Y already set
    movf glcd_Y, W, A ;must be 0 - 15, i.e. 0b00000000 to 0b00001111
    andlw 0b00001111 ;make sure it doesnt overflow
    rlncf WREG, W, A ;multiply by 8
    rlncf WREG, W, A
    rlncf WREG, W, A
    call ysel_W
    movf glcd_page, W, A
    call psel_W
    movlw 0x00
    call write_strip_W
    movlw 0x78
    call write_strip_W 
    movlw 0xEC
    call write_strip_W
    movlw 0xF4
    call write_strip_W 
    movlw 0xFE
    call write_strip_W
    movlw 0xFD
    call write_strip_W 
    movlw 0x79
    call write_strip_W
    movlw 0x00
    call write_strip_W 
    return

glcd_draw_left:
    IRP number, 0x08, 0x1C, 0x1C, 0x3E, 0x3E, 0x7F, 0x7F, 0x00
	movlw number
	call write_strip_W
    ENDM
    return

glcd_draw_right:
    IRP number, 0x7F, 0x7F, 0x3E, 0x3E, 0x1C, 0x1C, 0x08, 0x00
	movlw number
	call write_strip_W
    ENDM
    return

glcd_draw_up:
    IRP number, 0x60, 0x78, 0x7E, 0x7F, 0x7E, 0x78, 0x60, 0x00
	movlw number
	call write_strip_W
    ENDM
    return    

glcd_draw_down:
    IRP number, 0x03, 0x0F, 0x3F, 0x7F, 0x3F, 0x0F, 0x03, 0x00
	movlw number
	call write_strip_W
    ENDM
    return

;;;;;;;;;;;;;; utils
bin_to_idx: ;comverts glcd_bitnum from a binary number from 0 to 7 to a single digit binary index in-place
    ;e.g. 00000101 (5) -> 00100000 (only bit 5 is set, remember zero indexed so from 0 to 7) 
    movlw 0xFF
    incf WREG, A ; W=0 and carry=1
    shift_loop:
	tstfsz glcd_bitnum, A
	    goto shift
	movwf glcd_bitnum, A
	return
    shift:
	rlcf WREG, W, A
	decfsz glcd_bitnum, A;doesnt affect the zero flag
	nop
	goto shift_loop
