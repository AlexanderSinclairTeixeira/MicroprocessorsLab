#include <xc.inc>

#define    CS1 0 ;chip select left
#define    CS2 1 ;chip select right
#define    RS  2 ;high for data, low for instruction
#define    RW_  3 ;high for read, low for write
#define    E   4 ;clock: cycle time 1us and triggers on falling edge
#define    RST 5 ;reset (active high so write 1 for reset)

psect udata_acs
    glcd_status EQU 0x00
    glcd_read EQU 0x01
    y_counter EQU 0x02
 
psect code, abs
rst:
    org 0x0	;reset vector
    goto setup

int_hi:
    org 0x08	;high interrupt vector
    
setup:
    movlw 0x00
    movwf TRISB, A ;port B is output
    movwf TRISD, A ;port D is output
    clrf LATD, A
    call delay_1us ;stabilise
    call display_on
    movlw 32
    movwf y_counter, A
    goto start
  
start:
    movlw 0
    call psel_W
    call ysel_W
    movlw 0x55
    call write_strip_W
    decfsz y_counter,A
    goto start
    goto $

; main functions to control the display
; display_on, display_off, psel_W, ysel_W, write_strip_W, read_data_read_status
; above all have timing included
; display_start not implemented yet
display_on:
    call write_inst_pin_setup
    movlw 0b00111111 ;last bit set for on
    call send_D_and_clock
    return
    
display_off:
    call write_inst_pin_setup
    movlw 0b00111110 ;last bit clear for off
    call send_D_and_clock
    return
   
psel_W:
    call write_inst_pin_setup
    ;WREG contains a number from 0b000 - 0b111 i.e. the page number 0 - 7
    ;now set the page on the chip from the value in working register
    addlw 0b10111000 ;turn into page select instruction
    call send_D_and_clock
    return
    
ysel_W:
    call write_inst_pin_setup
    ;select the y adress from WREG 0b00000000 - 0b01111111, i.e. 0 - 127
    ;now set the strip on the page from the value in working register
    call csel_L ;assume left, i.e. 0 <= W < 64
    btfsc WREG, 6, A ;skip the next instruction if bit 6 of W is clear
    call csel_R ;if it is set, we are in 64-127, so on the right chip
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
    call write_data_pin_setup
    call send_D_and_clock
    return

read_data:
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
   
;inner function calls to save being repetitive
send_D_and_clock:
    movwf PORTD, A
    call clock
    clrf LATD, A
    call delay_1us
    return

read_inst_pin_setup:
    bcf PORTB, RS, A ;instruction
    bsf PORTB, RW_, A ;reading
    return

read_data_pin_setup:
    bsf PORTB, RS, A ;data
    bsf PORTB, RW_, A ;reading
    return

write_inst_pin_setup:
    bcf PORTB, RS, A ;instruction
    bcf PORTB, RW_, A ;writing
    return

write_data_pin_setup:
    bsf PORTB, RS, A ;data
    bcf PORTB, RW_, A ;writing
    return

csel_L:
    bsf PORTB, CS1, A    ;set the cs0 pin
    bcf PORTB, CS2, A    ;clear the cs1 pin
    return

csel_R:
    bcf PORTB, CS1, A    ;clear the cs0 pin
    bsf PORTB, CS2, A    ;set the cs1 pin
    return

;timing stuff
clock: ;set the clock to run (falling edge)
    bsf PORTB, E, A
    call delay_1us
    bcf PORTB, E, A
    call delay_1us
    return
   
delay_1us: ;16 instructions * 4 Q cycles @ 64MHz = 1us delay
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

end	    rst