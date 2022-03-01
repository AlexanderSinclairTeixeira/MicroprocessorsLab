#include <xc.inc>

;test all of this on the emulator
setup: ;setup to ports and name the pins! so I dont get confused
    movlw 0x00
    movwf TRISB, A
    movwf TRISD, A
   
    CS1 EQU 0
    CS2 EQU 1
    RS  EQU 2
    RW  EQU 3
    E   EQU 4
    RST EQU 5
   

lr_selcet: ;select the half of the screen that I care about
    ;set the cs0 pin
    bsf PORTB, CS1 ;hopefully this selects bit zero!!
    ;set the cs1 pin
    bcf PORTB, CS2
   
page_select: ;select the page on the screen dont touch the cs pins anymore!!
    ;set the page bits can modify so this is already in w when the subroutine is called
    movlw 0 ;a number from 0 - 7 i.e. the page I want
    movwf PORTD
   
    ;So here we first set the page and then modify the other bits so it knows that it is doing a page select command
   
    ;set the instruction to 'set page'
    bsf PORTD, 7 ;d7,d5,d4,d3
    bsf PORTD, 5
    bsf PORTD, 4
    bsf PORTD, 3
   
    bcf PORTB,RS ;RS RW D6
    bcf PORTB, RW
    bcf PORTB,6
    ;then go to the next step

y_adress: ;select the y adress
    movlw 0 ;a number from 0-63 takes bits 0-5
    movwf PORTD
   
    ;set the instruction bits
    bcf PORTB, RS
    bcf PORTB, RW
    bcf PORTD, 6
   
    bsf PORTD, 7
   

write_strip: ;write a pixel strip to ram
    ;data pins change it to take from the working directory later
    ;this just takes a hard coded value
    movlw 0xFF;remove this line later
    movwf PORTD
   
    ;instruction pins
   
    bsf PORTB, RS
   
    bcf PORTB, RW
clock: ;set the clock to run
    bsf PORTB,E
    bcf PORTB,E
   
delay_1us: ; a 1us delay that would go between clock cycles
    nop


