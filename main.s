#include <xc.inc>

;extrn	UART_Setup, UART_Transmit_Message   ; UART stuff
extrn	LCD_Setup, LCD_Write_Message	    ; LCD stuff
;extrn	delay_W_ms, delay_W_4us, delay_count_250ns, delay_500ns ;from utils
;extrn	mul_u16_x_u16 ;from utils
;extrn	counter_low, counter_high, ms_counter	    ;from utils
extrn	keypad_setup, keypad_read

    
psect udata_acs

res1:	ds 1
res2:	ds 1
res3:	ds 1
res4:	ds 1

    
psect code

setup:
    ;call UART_Setup
    call LCD_Setup
    call keypad_setup
    goto start
start:
    ;mul_u16_x_u16 0xEF, 0x3A, res1, res2, res3, res4
    ;lfsr 2, res1
    ;movlw 4
    ;call UART_Transmit_Message
    call keypad_read
    goto start
    end
