#include <xc.inc>

extrn write_strip_W
extrn glcd_y, glcd_page
    
global ascii_setup, ascii_write_W

psect udata_acs ;can use 0x10-0x1F, but share with glcd_draw and glcd_debug
    ascii_char EQU 0x1B
    ascii_counter EQU 0x1C
 
psect data ;ascii, class=CONST ;to hold in progmem for now
    ;allowed characters (length 51)
    ; (space)!()*+,-./0123456789<=>?@ABCDEFGHIJKLMNOPQRSTUVQXYZ
    ascii_table:
	DB  0x00, 0x00, 0x00, 0x00, 0x00; (spacja) ascii 32, 0x20
	DB  0x00, 0x00, 0x5F, 0x00, 0x00; !   ascii 33, 0x21
	DB  0x00, 0x1C, 0x22, 0x41, 0x00; (   ascii 40, 0x28
	DB  0x00, 0x41, 0x22, 0x1C, 0x00; )
	DB  0x08, 0x2A, 0x1C, 0x2A, 0x08; *
	DB  0x08, 0x08, 0x3E, 0x08, 0x08; +
	DB  0x00, 0x50, 0x30, 0x00, 0x00; ,
	DB  0x08, 0x08, 0x08, 0x08, 0x08; -
	DB  0x00, 0x30, 0x30, 0x00, 0x00; .
	DB  0x20, 0x10, 0x08, 0x04, 0x02; /
	DB  0x3E, 0x51, 0x49, 0x45, 0x3E; 0   ascii 48, 0x30
	DB  0x00, 0x42, 0x7F, 0x40, 0x00; 1
	DB  0x42, 0x61, 0x51, 0x49, 0x46; 2
	DB  0x21, 0x41, 0x45, 0x4B, 0x31; 3
	DB  0x18, 0x14, 0x12, 0x7F, 0x10; 4
	DB  0x27, 0x45, 0x45, 0x45, 0x39; 5
	DB  0x3C, 0x4A, 0x49, 0x49, 0x30; 6
	DB  0x01, 0x71, 0x09, 0x05, 0x03; 7
	DB  0x36, 0x49, 0x49, 0x49, 0x36; 8
	DB  0x06, 0x49, 0x49, 0x29, 0x1E; 9   ascii 57, 0x39
	DB  0x00, 0x08, 0x14, 0x22, 0x41; <   ascii 60, 0x3C
	DB  0x14, 0x14, 0x14, 0x14, 0x14; =
	DB  0x41, 0x22, 0x14, 0x08, 0x00; >
	DB  0x02, 0x01, 0x51, 0x09, 0x06; ?
	DB  0x32, 0x49, 0x79, 0x41, 0x3E; @
	DB  0x7E, 0x11, 0x11, 0x11, 0x7E; A   ascii 65, 0x41
	DB  0x7F, 0x49, 0x49, 0x49, 0x36; B
	DB  0x3E, 0x41, 0x41, 0x41, 0x22; C
	DB  0x7F, 0x41, 0x41, 0x22, 0x1C; D
	DB  0x7F, 0x49, 0x49, 0x49, 0x41; E
	DB  0x7F, 0x09, 0x09, 0x01, 0x01; F
	DB  0x3E, 0x41, 0x41, 0x51, 0x32; G
	DB  0x7F, 0x08, 0x08, 0x08, 0x7F; H
	DB  0x00, 0x41, 0x7F, 0x41, 0x00; I
	DB  0x20, 0x40, 0x41, 0x3F, 0x01; J
	DB  0x7F, 0x08, 0x14, 0x22, 0x41; K
	DB  0x7F, 0x40, 0x40, 0x40, 0x40; L
	DB  0x7F, 0x02, 0x04, 0x02, 0x7F; M
	DB  0x7F, 0x04, 0x08, 0x10, 0x7F; N
	DB  0x3E, 0x41, 0x41, 0x41, 0x3E; O
	DB  0x7F, 0x09, 0x09, 0x09, 0x06; P
	DB  0x3E, 0x41, 0x51, 0x21, 0x5E; Q
	DB  0x7F, 0x09, 0x19, 0x29, 0x46; R
	DB  0x46, 0x49, 0x49, 0x49, 0x31; S
	DB  0x01, 0x01, 0x7F, 0x01, 0x01; T
	DB  0x3F, 0x40, 0x40, 0x40, 0x3F; U
	DB  0x1F, 0x20, 0x40, 0x20, 0x1F; V
	DB  0x7F, 0x20, 0x18, 0x20, 0x7F; W
	DB  0x63, 0x14, 0x08, 0x14, 0x63; X
	DB  0x03, 0x04, 0x78, 0x04, 0x03; Y
	DB  0x61, 0x51, 0x49, 0x45, 0x43; Z   ascii 90, 0x5A

psect	udata_bank2 ; reserve data anywhere in RAM (here at 0x200)
    ascii_characters:    ds 255 ;reserve 255 bytes for all the characters

psect	ascii_code, class=CODE	
    ascii_setup:
	bcf	CFGS	; point to Flash program memory  
	bsf	EEPGD 	; access Flash program memory
	
	lfsr	0, ascii_characters	; Load FSR0 with address in RAM	
	
	movlw	low highword(ascii_table)
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	
	movlw	high(ascii_table)
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	
	movlw	low(ascii_table)
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	
	movlw	255	; number of bytes to read
	movwf 	ascii_counter, A ;double up as a table counter for now ;)
	loop:
	    tblrd*+ ; one byte from PM to TABLAT, post-increment TBLPTR
	    movff TABLAT, POSTINC0 ; move data from TABLAT to (FSR0), inc FSR0	
	    decfsz ascii_counter, A ; count down to zero
	    bra	loop		; keep going until finished
	return

    ascii_write_W:
	;with glcd_y and glcd_page already set, write the ascii from W to the screen
	; (space)!()*+,-./0123456789<=>?@ABCDEFGHIJKLMNOPQRSTUVQXYZ
	;these have ascii values of (in order)
	;32-33, 40-47, 48-57 (numbers 0-9), 60-64, 65-90 (uppercase letters)
	;invalid characters will show up as checkerboard pattern
	movwf ascii_char, A
	movlw 32
	subwf ascii_char, F ;put it back in the file
	btfss STATUS, 0 ;zero is carry bit
	    goto invalid ;ascii_char < 32 as carry was clear (so borrow occured)
	;asci_char was 32, 33, 34... now is 0, 1, 2...
	movlw 2
	subwf ascii_char, W ;back in W for now
	btfss STATUS, 0 ;zero is carry bit
	    goto valid ; ascii_char was 32 or 33, now holds 0 or 1
	;ascii_char was 34, 35, 36... now holds 2, 3, 4...
	movlw 6
	subwf ascii_char, F ;back in the file
	btfss STATUS, 0 ;zero is carry bit
	    goto invalid ;ascii_char was 34-37
	;ascii_char was 38, 39, 40... now holds 0, 1, 2...
	movlw 2
	subwf ascii_char, W
	btfss STATUS, 0 ;zero is carry bit
	    goto invalid ;ascii_char was 38 or 39
	;ascii_char was 40, 41, 42... now holds 2, 3, 4...
	movlw 20
	subwf ascii_char, W
	btfss STATUS, 0 ;zero is carry bit
	    goto valid ;ascii_char was 40-57, now holds 2-19
	;ascii_char was 58, 59, 60... now holds 20, 21, 22...
	movlw 2
	subwf ascii_char, F, A ;back in the file
	;ascii_char was 58, 59, 60... now holds 18, 19, 20...
	movlw 20
	subwf ascii_char, W
	btfss STATUS, 0 ;zero is carry bit
	    goto invalid ;ascii_char was 58 or 59
	;ascii_char was 60, 61, 62... now holds 20, 21, 22...
	movlw 51
	subwf ascii_char, W
	btfss STATUS, 0 ;zero is carry bit
	    goto valid ;ascii_char was 60-90, now holds 20-50
	goto invalid ;ascii_char was > 91
	
	valid:
	    ;multiply by 5, set the FSR, write 5 bytes
	    movlw 2
	    movwf FSR0H, A ;FSRs dont listen to banksel so manually set upper to bank 2
	    movlw 5
	    movwf ascii_counter, A
	    mulwf ascii_char, A
	    movff PRODL, FSR0L, A
	    write_bytes:
		movf POSTINC0, W
		call write_strip_W
		decfsz ascii_counter, A
		    goto write_bytes
		movlw 0
		call write_strip_W ;right-spaced
		return
		
	invalid:
	    movlw 5
	    movwf ascii_counter
	    movlw 0xAA
	    movwf ascii_char
	    write_invalid:
		call write_strip_W
		comf ascii_char, F
		decfsz ascii_counter
		    goto write_invalid
		movlw 0
		call write_strip_W ;right-spaced
		return
