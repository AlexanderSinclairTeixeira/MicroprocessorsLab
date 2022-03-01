#include <xc.inc>

psect udata_acs
    glcd_status EQU 0x00
    y_counter EQU 0x01
    big_bois EQU 0x02
 
psect code, abs
rst:
    org 0x0
    goto setup
    
setup: ;setup to ports and name the pins! so I dont get confused
    #define    CS1 0
    #define    CS2 1
    #define    RS  2
    #define    RW_  3
    #define    E   4
    #define    RST 5
    movlw 0x00
    movwf TRISB, A
    movwf TRISD, A
    call delay_1us
    call display_on
    call clock
    movlw 32
    movwf y_counter, A
    goto start
  
start:
    call lr_select
    ;call clock
    call page_select
    call clock
    call status_read
    call clock
    call y_address
    call clock
    call write_strip
    call clock
    call read_data
    call clock
    call y_address
    call clock
    decfsz y_counter,A
    ;goto start
    goto $
    
display_on:
    bcf PORTB, RS, A
    bcf PORTB, RW_, A
    movlw 0b00111111
    movwf PORTD, A
    call clock
    clrf LATD, A
    clrf WREG, A
    call delay_1us
    return
lr_select: ;select the half of the screen that I care about
    ;set the cs0 pin
    bsf PORTB, CS1, A ;hopefully this selects bit zero!!
    ;set the cs1 pin
    bcf PORTB, CS2, A
    return
   
page_select: ;select the page on the screen dont touch the cs pins anymore!!
    ;set the page bits can modify so this is already in w when the subroutine is called
    movlw 0 ;a number from 0 - 7 i.e. the page I want
    movwf PORTD, A
   
    ;So here we first set the page and then modify the other bits so it knows that it is doing a page select command
   
    ;set the instruction to 'set page'
    bsf PORTD, 7, A ;d7,d5,d4,d3
    bsf PORTD, 5, A
    bsf PORTD, 4, A
    bsf PORTD, 3, A
   
    bcf PORTB, RS, A ;RS RW D6
    bcf PORTB, RW_, A
    bcf PORTB, 6, A
    ;then go to the next step
    return

read_data:
    bsf PORTB, RS, A
    bsf PORTB, RW_, A
    movlw 0xFF
    movwf TRISD, A
    clrf LATD, A
    call clock
    movff TRISD, big_bois, A
    movlw 0x00
    movwf TRISD, A
    return
y_address: ;select the y adress
    movlw 0 ;a number from 0-63 takes bits 0-5
    movwf PORTD, A
   
    ;set the instruction bits
    bcf PORTB, RS, A
    bcf PORTB, RW_, A
    bcf PORTD, 6, A
   
    bsf PORTD, 7, A
    return
   

write_strip: ;write a pixel strip to ram
    ;data pins change it to take from the working directory later
    ;this just takes a hard coded value for now
    movlw 0x55
    movwf PORTD, A
    ;instruction pins
    bsf PORTB, RS, A
    bcf PORTB, RW_, A
    return

status_read:
    bsf TRISD,7,A
    bsf TRISD,5,A
    bsf TRISD,4,A
   
    bsf PORTB, RS, A
    bcf PORTB, RW_, A
    bcf PORTD, 6, A
    bcf PORTD, 3, A
    bcf PORTD, 2, A
    bcf PORTD, 1, A
    bcf PORTD, 0, A
    call clock
    clrf LATD, A
    call delay_1us
    movff PORTD, glcd_status, A
    bcf TRISD,7,A
    bcf TRISD,5,A
    bcf TRISD,4,A
    return
    
clock: ;set the clock to run
    bcf PORTB, E, A
    call delay_1us
    bsf PORTB, E, A
    call delay_1us
    bcf PORTB, E, A
    return
   
delay_1us: ; a 1us delay that would go between clock cycles
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
