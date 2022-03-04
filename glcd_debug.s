#include <xc.inc>

#define    GLCD_CS1 0 ;chip select left
#define    GLCD_CS2 1 ;chip select right
#define    GLCD_RS  2 ;high for data, low for instruction
#define    GLCD_RW  3 ;high for read, low for write
#define    GLCD_E   4 ;clock: cycle time 1us and triggers on falling edge
#define    GLCD_RST 5 ;reset (active high so write 1 for reset)

global glcd_setup, psel_W, ysel_W, write_strip_W
global glcd_status, glcd_read, glcd_page, glcd_y, glcd_write, glcd_strip
    
psect udata_acs
    glcd_status EQU 0x00
    glcd_read EQU 0x01
    glcd_page EQU 0x02
    glcd_y EQU 0x03
    glcd_write EQU 0x04
    glcd_strip EQU 0x05
    count_ms EQU 0x06
 
psect glcd_code, class=CODE

; main functions to control the display
; 
; glcd_setup, glcd_on, glcd_off, psel_W, ysel_W, write_strip_W, read_data_read_status
; above all have timing included
; display_start not implemented yet

glcd_setup:
    movlw 0x00
    movwf TRISB, A ;port B is output
    movwf TRISD, A ;port D is output
    ;movlw 250
    ;call delay_ms_W
    call glcd_on
    return

glcd_on:
    bcf PORTB, GLCD_RS, A ;instruction
    bcf PORTB, GLCD_RW, A ;writing
    movlw 0b00111111 ;last bit set for on
    movwf PORTD, A
    ;movlw 250
    ;call delay_ms_W
    call csel_L
    call clock
    ;movlw 250
    ;call delay_ms_W
    call csel_R
    call clock
    return
    
glcd_off:
    bcf PORTB, GLCD_RS, A ;instruction
    bcf PORTB, GLCD_RW, A ;writing
    movlw 0b00111110 ;last bit clear for off
    movwf PORTD, A
    call csel_L
    call clock
    call csel_R
    call clock
    return

ysel_W:
    ;select the y adress from WREG 0b00000000 - 0b01111111, i.e. 0 - 127
    ;now set the strip on the page from the value in working register
    bcf WREG, 7, A ;make sure top bit is 0 (overflows are a feature not a bug??)
    movwf glcd_y, A ;save the working directory to RAM
    ;call wait_till_free    
    call csel_L ;assume left, i.e. 0 <= W < 64
    btfsc glcd_y, 6, A ;skip the next instruction if bit 6 of glcd_y is clear
    call csel_R ;if it is set, we are in 64-127, so on the right chip
    
    bcf PORTB, GLCD_RS, A ;instruction
    bcf PORTB, GLCD_RW, A ;writing
    movf glcd_y, W ; load up the y value
    bsf WREG, 6, A ;turn into desired instruction
    movwf PORTD, A
    ;movlw 250
    ;call delay_ms_W
    call clock
    return
    
psel_W:
    ;WREG contains a number from 0b000 - 0b111 i.e. the page number 0 - 7
    ;now set the page on the chip from the value in working register
    IRP bitnum, 7, 6, 5, 4, 3
	bcf WREG, bitnum, A ;make sure top bits are 0
    ENDM
    movwf glcd_page, A ;save the page number to RAM
    call csel_L ;assume left, i.e. 0 <= W < 64
    btfsc glcd_y, 6, A ;skip the next instruction if bit 6 of glcd_y is clear
    call csel_R ;if it is set, we are in 64-127, so on the right chip

    bcf PORTB, GLCD_RS, A ;instruction
    bcf PORTB, GLCD_RW, A ;writing
    movf glcd_page, W ;load up the page number
    addlw 0b10111000 ;turn into page select instruction
    movwf PORTD, A
    ;movlw 250
    ;call delay_ms_W
    call clock
    return
    

;display_start:
    ;used for scrolling i think?
    ;call write_inst
    ;needs implementing (maybe?)
    ;return
    
write_strip_W:
    ;write a pixel strip from W to glcd ram
    ;increases y address automatically
    movwf glcd_write
    call csel_L ;assume left, i.e. 0 <= W < 64
    btfsc glcd_y, 6, A ;skip the next instruction if bit 6 of glcd_y is clear
    call csel_R ;if it is set, we are in 64-127, so on the right chip
    
    bsf PORTB, GLCD_RS, A ;data
    bcf PORTB, GLCD_RW, A ;writing
    movf glcd_write, W ; load up the write value
    movwf PORTD, A
    ;movlw 250
    ;call delay_ms_W
    call clock
    incf glcd_y, A
    return

read_data:
    movlw 0xFF
    movwf TRISD, A ;set PORTD as input
    call csel_L ;assume left, i.e. 0 <= W < 64
    btfsc glcd_y, 6, A ;skip the next instruction if bit 6 of glcd_y is clear
    call csel_R ;if it is set, we are in 64-127, so on the right chip
    
    bsf PORTB, GLCD_RS, A ;data
    bsf PORTB, GLCD_RW, A ;reading
    call delay_1us
    bsf PORTB, GLCD_E, A ;send instruction
    call delay_1us
    bcf PORTB, GLCD_E, A ;clock on falling edge
    call delay_1us
    movff PORTD, glcd_read, A ; and get the data
    movlw 0x00
    movwf TRISD, A ;PORTD back to output
    ;call delay_1us
    incf glcd_y, A
    return
   
read_status:
    ;B0PR0000
    ;B=Busy: 0-ready, 1-in operation
    ;P=power: 0-on, 1-off
    ;R=Reset: 0-normal, 1-reset
    movlw 0xFF
    movwf TRISD, A ;set PORTD as input
    call csel_L ;assume left, i.e. 0 <= W < 64
    btfsc glcd_y, 6, A ;skip the next instruction if bit 6 of W is clear
    call csel_R ;if it is set, we are in 64-127, so on the right chip
    
    bcf PORTB, GLCD_RS, A ;instruction
    bsf PORTB, GLCD_RW, A ;reading
    call delay_1us
    bsf PORTB, GLCD_E, A ;send instruction
    call delay_1us
    bcf PORTB, GLCD_E, A ;clock on falling edge
    call delay_1us
    movff PORTD, glcd_status, A ;and get the data
    movlw 0x00
    movwf TRISD, A;PORTD back to output
    return
    
wait_till_free:
    call read_status
    btfsc glcd_status, 7, A ;top bit is 1 when "Busy"
    goto wait_till_free
    return
   
;inner function calls to save being repetitive
csel_L:
    bcf PORTB, GLCD_CS1, A    ;clear the cs1 pin
    bsf PORTB, GLCD_CS2, A    ;set the cs2 pin
    call delay_1us
    return

csel_R:
    bsf PORTB, GLCD_CS1, A    ;set the cs1 pin
    bcf PORTB, GLCD_CS2, A    ;clear the cs2 pin
    call delay_1us
    return

;timing stuff
clock: ;set the clock to run (falling edge)
    call delay_1us
    bsf PORTB, GLCD_E, A
    call delay_1us
    bcf PORTB, GLCD_E, A
    call delay_1us
    return
   
delay_1us: ;16 instructions * 4 Q cycles @ 64MHz = 1us delay
    ;REPT 48
	;nop
    ;ENDM
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    return
    
delay_ms_W:   ; delay given in ms in W
    movwf	count_ms, A
    REPT 4
    LOCAL delay_inner_loop
    delay_inner_loop:
	movlw	250	    ; 1 ms delay
	call	delay_1us	
	decfsz	count_ms, A
	bra	delay_inner_loop
	return
    ENDM