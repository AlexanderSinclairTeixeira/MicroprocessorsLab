#include <xc.inc>

#define    GLCD_CS1 0 ;chip select left
#define    GLCD_CS2 1 ;chip select right
#define    GLCD_RS  2 ;high for data, low for instruction
#define    GLCD_RW  3 ;high for read, low for write
#define    GLCD_E   4 ;clock: cycle time 1us and triggers on falling edge
#define    GLCD_RST 5 ;reset (active high so write 1 for reset)

global glcd_setup, psel_W, ysel_W, write_strip_W
global glcd_status, glcd_read, glcd_page, glcd_y, glcd_strip
    
psect udata_acs
    glcd_status EQU 0x00
    glcd_read EQU 0x01
    glcd_page EQU 0x02
    glcd_y EQU 0x03
    glcd_strip EQU 0x04
 
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
    clrf LATD, A
    call delay_1us ;stabilise
    call glcd_on
    return

glcd_on:
    call write_inst_pin_setup
    movlw 0b00111111 ;last bit set for on
    call send_D_and_clock
    return
    
glcd_off:
    call write_inst_pin_setup
    movlw 0b00111110 ;last bit clear for off
    call send_D_and_clock
    return
   
psel_W:
    movwf glcd_page
    call wait_till_free
    call write_inst_pin_setup
    ;WREG contains a number from 0b000 - 0b111 i.e. the page number 0 - 7
    ;now set the page on the chip from the value in working register
    movf glcd_page, A
    ;movlw 2 ;;;;;;;;;;; DEBUG
    addlw 0b10111000 ;turn into page select instruction
    call send_D_and_clock
    return
    
ysel_W:
    movwf glcd_y
    call wait_till_free
    call write_inst_pin_setup
    ;select the y adress from WREG 0b00000000 - 0b01111111, i.e. 0 - 127
    ;now set the strip on the page from the value in working register
    call csel_L ;assume left, i.e. 0 <= W < 64
    movf glcd_y
    btfsc WREG, 6, A ;skip the next instruction if bit 6 of W is clear
    call csel_R ;if it is set, we are in 64-127, so on the right chip
    ;movlw 0 ;;;;;;;;;;;;;DEBUG
    bsf WREG, 6, A ;turn into instruction
    call send_D_and_clock
    return

;display_start:
    ;used for scrolling i think?
    ;call write_inst
    ;needs implementing (maybe?)
    ;return
    
write_strip_W:
    ;write a pixel strip from W to glcd ram
    ;increases y address automatically
    movwf glcd_strip
    call wait_till_free
    call write_data_pin_setup
    movf glcd_strip, A
    ;movlw 0b11010010 ;;;;;;;DEBUG
    call send_D_and_clock
    return

read_data:
    call wait_till_free
    call read_data_pin_setup
    movlw 0xFF
    movwf TRISD, A ;set PORTD as input
    clrf LATD, A ;dont want any interference
    call clock ;send instruction and get the data
    movff PORTD, glcd_read, A
    movlw 0x00
    movwf TRISD, A ;PORTD back to output
    clrf LATD, A
    call delay_1us
    return
   
read_status:
    ;B0PR0000
    ;B=Busy: 0-ready, 1-in operation
    ;P=power: 0-on, 1-off
    ;R=Reset: 0-normal, 1-reset
    call read_inst_pin_setup
    movlw 0xFF
    movwf TRISD, A ;set PORTD as input
    clrf LATD, A ;dont want any interference
    call clock ;send instruction and get the data
    movff PORTD, glcd_status, A
    movlw 0x00
    movwf TRISD, A;PORTD back to output
    clrf LATD, A
    call delay_1us
    return
    
wait_till_free:
    call read_status
    btfsc glcd_status, 7, A ;top bit is "Busy"
    goto wait_till_free
    return
   
;inner function calls to save being repetitive
send_D_and_clock:
    movwf PORTD, A
    call clock
    ;clrf LATD, A
    call delay_1us
    return

read_inst_pin_setup:
    bcf PORTB, GLCD_RS, A ;instruction
    bsf PORTB, GLCD_RW, A ;reading
    return

read_data_pin_setup:
    bsf PORTB, GLCD_RS, A ;data
    bsf PORTB, GLCD_RW, A ;reading
    return

write_inst_pin_setup:
    bcf PORTB, GLCD_RS, A ;instruction
    bcf PORTB, GLCD_RW, A ;writing
    return

write_data_pin_setup:
    bsf PORTB, GLCD_RS, A ;data
    bcf PORTB, GLCD_RW, A ;writing
    return

csel_L:
    bcf PORTB, GLCD_CS1, A    ;set the cs0 pin
    bsf PORTB, GLCD_CS2, A    ;clear the cs1 pin
    return

csel_R:
    bsf PORTB, GLCD_CS1, A    ;clear the cs0 pin
    bcf PORTB, GLCD_CS2, A    ;set the cs1 pin
    return

;timing stuff
clock: ;set the clock to run (falling edge)
    bsf PORTB, GLCD_E, A
    call delay_1us
    bcf PORTB, GLCD_E, A
    call delay_1us
    return
   
delay_1us: ;16 instructions * 4 Q cycles @ 64MHz = 1us delay
    REPT 32
	nop
    ENDM
    return