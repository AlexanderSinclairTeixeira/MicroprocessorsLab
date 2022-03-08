#include <xc.inc>

#define    GLCD_CS1 0 ;chip select left
#define    GLCD_CS2 1 ;chip select right
#define    GLCD_RS  2 ;high for data, low for instruction
#define    GLCD_RW  3 ;high for read, low for write
#define    GLCD_E   4 ;clock: cycle time 1us and triggers on falling edge
#define    GLCD_RST 5 ;reset (active high so write 1 for reset)

global glcd_setup, psel_W, ysel_W, write_strip_W, delay_ms_W
global glcd_status, glcd_read, glcd_page, glcd_y, glcd_write
    
psect udata_acs
    glcd_status EQU 0x00
    glcd_read EQU 0x01
    glcd_page EQU 0x02
    glcd_y EQU 0x03
    glcd_write EQU 0x04
    count_ms EQU 0x05
 
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
    call delay_250ns
    call glcd_on
    return

glcd_on:
    bcf LATB, GLCD_RS, A ;instruction
    call delay_250ns
    bcf LATB, GLCD_RW, A ;writing
    movlw 0b00111111 ;last bit set for on
    movwf LATD, A
    call csel_L
    call clock
    call csel_R
    call clock
    return
    
glcd_off:
    bcf PORTB, GLCD_RS, A ;instruction
    call delay_250ns
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
    call csel_L ;assume left, i.e. 0 <= W < 64
    btfsc glcd_y, 6, A ;skip the next instruction if bit 6 of glcd_y is clear
    call csel_R ;if it is set, we are in 64-127, so on the right chip
    
    bcf PORTB, GLCD_RS, A ;instruction
    call delay_250ns
    bcf PORTB, GLCD_RW, A ;writing
    movf glcd_y, W ; load up the y value
    bsf WREG, 6, A ;turn into desired instruction
    call delay_250ns
    movwf PORTD, A
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
    call delay_250ns
    bcf PORTB, GLCD_RW, A ;writing
    movf glcd_page, W ;load up the page number
    addlw 0b10111000 ;turn into page select instruction
    movwf PORTD, A
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
    call delay_250ns
    
    bsf LATB, GLCD_RS, A ;data
    call delay_250ns
    bcf LATB, GLCD_RW, A ;writing
    movf glcd_write, W ; load up the write value
    movwf LATD, A
    call clock ; this increases the GLCD's internal y address automatically
    incf glcd_y, A
    bcf glcd_y, 7, A ;make sure top bit is 0 (overflows are a feature not a bug??)
    return

read_data:
    movlw 0xFF
    movwf TRISD, A ;set PORTD as input
    call csel_L ;assume left, i.e. 0 <= W < 64
    btfsc glcd_y, 6, A ;skip the next instruction if bit 6 of glcd_y is clear
    call csel_R ;if it is set, we are in 64-127, so on the right chip
    
    bsf LATB, GLCD_RS, A ;data
    call delay_250ns
    bsf LATB, GLCD_RW, A ;reading
    call delay_500ns
    bsf LATB, GLCD_E, A ;send instruction
    call delay_500ns
    bcf LATB, GLCD_E, A ;clock on falling edge
    call delay_500ns
    movff PORTD, glcd_read, A ; and get the data from the port pins
    movlw 0x00
    movwf TRISD, A ;PORTD back to output
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
    
    bcf LATB, GLCD_RS, A ;instruction
    call delay_250ns
    bsf LATB, GLCD_RW, A ;reading
    call delay_500ns
    bsf LATB, GLCD_E, A ;send instruction
    call delay_500ns
    bcf LATB, GLCD_E, A ;clock on falling edge
    call delay_500ns
    movff PORTD, glcd_status, A ;and get the data from the port pins
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
    bcf LATB, GLCD_CS1, A    ;clear the cs1 pin
    call delay_250ns
    bsf LATB, GLCD_CS2, A    ;set the cs2 pin
    ;call delay_250ns
    return

csel_R:
    bsf LATB, GLCD_CS1, A    ;set the cs1 pin
    call delay_250ns
    bcf LATB, GLCD_CS2, A    ;clear the cs2 pin
    ;call delay_250ns
    return

;timing stuff
clock: ;set the clock to run (falling edge)
    call delay_500ns
    bsf LATB, GLCD_E, A
    call delay_500ns
    bcf LATB, GLCD_E, A
    call delay_500ns
    return

delay_ms_W:   ; delay given in ms in W
    movwf	count_ms, A
    REPT 4
	LOCAL delay_inner_loop
	delay_inner_loop:
	    movlw	250	    ; 1 ms delay
	    call	delay_500ns	
	    call	delay_500ns	
	    decfsz	count_ms, A
	    bra	delay_inner_loop
	    return
    ENDM
    return
    
delay_250ns: ;4 instructions * 4 Q cycles @ 64MHz = 250ns delay
    nop
    nop
    nop
    return
    
delay_500ns: ;8 instructions * 4 Q cycles @ 64MHz = 500ns delay
    REPT 7
	nop
    ENDM
    return