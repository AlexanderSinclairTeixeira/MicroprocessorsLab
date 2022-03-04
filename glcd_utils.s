#include <xc.inc>

#define    GLCD_CS1 0 ;chip select left
#define    GLCD_CS2 1 ;chip select right
#define    GLCD_RS  2 ;high for data, low for instruction
#define    GLCD_RW  3 ;high for read, low for write
#define    GLCD_E   4 ;clock: cycle time 1us and triggers on falling edge
#define    GLCD_RST 5 ;reset (active high so write 1 for reset)

global glcd_setup,psel_W,ysel_W,write_strip_W,LCD_delay_ms,bossman_delay

psect udata_acs
    glcd_status EQU 0x00
    glcd_read EQU 0x01
    glcd_page EQU 0x02
    glcd_y EQU 0x03
    glcd_write EQU 0x04
    glcd_strip EQU 0x05
 
    LCD_cnt_l:	ds 1   ; reserve 1 byte for variable LCD_cnt_l
    LCD_cnt_h:	ds 1   ; reserve 1 byte for variable LCD_cnt_h
    LCD_cnt_ms:	ds 1   ; reserve 1 byte for ms counter
    LCD_tmp:	ds 1   ; reserve 1 byte for temporary use
    LCD_counter:	ds 1   ; reserve 1 byte for counting through nessage    
 
psect glcd_code, class=CODE
    
glcd_setup:
    call bossman_delay
    movlw 0x00
    call bossman_delay
    movwf TRISB, A ;port B is output
    call bossman_delay
    movwf TRISD, A ;port D is output
    call bossman_delay
    call chip_select
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call glcd_on
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call bossman_delay
    call chip_select
    return

chip_select:
    call bossman_delay
    bcf PORTB, GLCD_CS1, A
    call bossman_delay
    bsf PORTB, GLCD_CS2, A
    call bossman_delay
    return
    
glcd_on:
    call bossman_delay
    bcf PORTB, GLCD_RS, A ;instruction
    call bossman_delay
    bcf PORTB, GLCD_RW, A ;writing
    call bossman_delay
    movlw 0b00111111 ;last bit set for on
    call bossman_delay
    movwf PORTD, A
    call bossman_delay
    call clock
    return

psel_W:
    ;WREG contains a number from 0b000 - 0b111 i.e. the page number 0 - 7
    ;now set the page on the chip from the value in working register
    call	bossman_delay
    call LCD_delay_ms
    call	bossman_delay
    bcf PORTB, GLCD_RS, A ;instruction
    call	bossman_delay
    bcf PORTB, GLCD_RW, A ;writing
    call	bossman_delay
    ;movlw 0 ;debug----------------------------
    call	bossman_delay
    addlw 0b10111000 ;turn into page select instructio
    call	bossman_delay
    movwf PORTD, A
    call bossman_delay
    call clock
    return    
    
ysel_W:
    ;select the y adress from WREG 0b00000000 - 0b01111111, i.e. 0 - 127
    ;now set the strip on the page from the value in working register
    call bossman_delay
    bcf PORTB, GLCD_RS, A ;instruction
    call bossman_delay
    bcf PORTB, GLCD_RW, A ;writing
    call bossman_delay
    movlw 0 ;debug----------------------------
    call bossman_delay
    movwf PORTD, A
    call bossman_delay
    bsf PORTD, 6, A ;turn into instruction
    call bossman_delay
    call clock
    return    
    
write_strip_W:
    ;write a pixel strip from W to glcd ram
    ;increases y address automatically
    call bossman_delay
    bsf PORTB, GLCD_RS, A ;data
    call bossman_delay
    bcf PORTB, GLCD_RW, A ;writing
    call bossman_delay
    ;movlw 0b00000000 ;debug----------------------------
    call bossman_delay
    movwf PORTD, A
    call clock
    return
    
clock: ;set the clock to run (falling edge)
    call bossman_delay
    bsf PORTB, GLCD_E, A
    call bossman_delay
    bcf PORTB, GLCD_E, A
    call bossman_delay
    return
    
    
    
; ** a few delay routines below here as LCD timing can be quite critical ****
bossman_delay:
    REPT 0xFF
	call LCD_delay_ms
    ENDM
LCD_delay_ms:		    ; delay given in ms in W
	nop
	movwf	LCD_cnt_ms, A
	return
lcdlp2:	movlw	250	    ; 1 ms delay
	call	LCD_delay_x4us	
	decfsz	LCD_cnt_ms, A
	bra	lcdlp2
	return
    
LCD_delay_x4us:		    ; delay given in chunks of 4 microsecond in W
	movwf	LCD_cnt_l, A	; now need to multiply by 16
	swapf   LCD_cnt_l, F, A	; swap nibbles
	movlw	0x0f	    
	andwf	LCD_cnt_l, W, A ; move low nibble to W
	movwf	LCD_cnt_h, A	; then to LCD_cnt_h
	movlw	0xf0	    
	andwf	LCD_cnt_l, F, A ; keep high nibble in LCD_cnt_l
	call	LCD_delay
	return

LCD_delay:			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
lcdlp1:	decf 	LCD_cnt_l, F, A	; no carry when 0x00 -> 0xff
	subwfb 	LCD_cnt_h, F, A	; no carry when 0x00 -> 0xff
	bc 	lcdlp1		; carry, then loop again
	return			; carry reset so return


    end

