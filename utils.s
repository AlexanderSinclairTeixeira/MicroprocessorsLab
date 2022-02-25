#include <xc.inc>

global mul_16x16, mul_16x16_u, hex_to_dec
global delay_W_ms, delay_W_4us, delay_500ns

psect udata_acs

counter_low:	ds 1   ; reserve 1 byte for counter
counter_high:	ds 1
ms_counter:	ds 1   ; reserve 1 byte for ms counter

    
psect code
    
delay_W_ms:
    ; delay number of ms in W
    movwf   ms_count, A
    inner_loop_1:
	movlw   250		; 250 * 4us = 1 ms delay
	call	delay_W_4us	
	decfsz	ms_count, A
	bra	inner_loop_1
    return
    
delay_W_4us:
    ; delay by W * 4us
    ; need to multiply W by 16
    ; if called from delay_ms_inner_loop, W=250
    movwf   LCD_cnt_l, A    ; save W to count_low temporarily
    swapf   LCD_cnt_l, F, A ; swap nibbles
    movlw   0x0f	    
    andwf   LCD_cnt_l, W, A ; move low nibble to W
    movwf   LCD_cnt_h, A    ; then to LCD_cnt_h
    movlw   0xf0	    
    andwf   LCD_cnt_l, F, A ; keep high nibble in LCD_cnt_l
    call    LCD_delay
    return

delay_count_250ns:
    ; delays by count_high:count_low * 250ns
    ; 4 instruction loop * 4 cycles per instruction @ 64MHz = 250ns	    
    movlw 	0x00		; W=0 for sub intruction to only use carry
    inner_loop_2:
	decf 	counter_low, F, A	; carry, i.e. not(borrow), bit CLEARED when 0x00 -> 0xff
	subwfb 	counter_high, F, A	; f - W(==0) - not(C) -> f
	; if not(C) == 1, so C==0, then our high counter has clocked over
	bc 	inner_loop_2 ; branch if carry
	; bc is a two-cycle instruction if it branches, otherwise just one
    return			; carry reset so return
    
    
delay_500ns:
    ; 4 instruction cycle * 8 instructions @ 64MHz = 500ns
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    return
    



    end