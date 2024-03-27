;---------------------
; Title: Counter Design
;---------------------
;Program Details:
;The purpose of this program is to have a 7 segment turn on and increment when in our case 
;switch A is pressed and stop incrementing once it is released. It also needs to decrement
;the same way but pressing switch B and stop once it is released, if both switches are
;pressed then the counter resets to zero. the range in which this counter goes to is 
;0-F
; Outputs: RD0 (output)
; inputs:  RC0 and RC1 (inputs)
; Setup: The PICKIT4 can use its internal 5V. No external power is needed.
; Date: march 27, 2024
; File Dependencies / Libraries: It is required to include the 
;   AssemblyConfig.inc in the Header Folder
; Compiler: xc8, 2.4
; Author: Pablo Orozco
; Versions:
; V1.0: March 23, 2024
; V2: March 26, 2024
; Useful links: 
;       Datasheet: https://ww1.microchip.com/downloads/en/DeviceDoc/PIC18(L)F26-27-45-46-47-55-56-57K42-Data-Sheet-40001919G.pdf 
;       PIC18F Instruction Sets: https://onlinelibrary.wiley.com/doi/pdf/10.1002/9781119448457.app4 
;       List of Instrcutions: http://143.110.227.210/faridfarahmand/sonoma/courses/es310/resources/20140217124422790.pdf 

;---------------------
; Initialization
;---------------------
#include "AssemblyConfiguration.inc"
#include <xc.inc>

;---------------------
; Program Inputs
;---------------------
LOOP1  EQU 0XFF // in decimal
LOOP2  EQU 0XFF
LOOP3  EQU 4

;---------------------
; Program Constants
;---------------------
REG10   EQU     10h   // in HEX
REG11   EQU     11h
REG12	EQU	12h
BUFFER  EQU	3h
BUFFER2	EQU	2h




;---------------------
; Definitions
;---------------------
#define SWITCH_A    PORTC,0	; Switch A connected to RC0
#define SWITCH_B    PORTC,1	; Switch B connected to RC1
#define DISPLAY     PORTD	; 7-segment display connected to PORTC

;---------------------
; Main Program
;---------------------
    PSECT absdata,abs,ovrld     ; Do not change

    ORG	    0         ;Reset vector
    GOTO    _START1	
    ORG 0020H

; Initialize the program
_START1: 


    BANKSEL	PORTD 
    CLRF	PORTD	;Init PORTD
    BANKSEL	PORTC
    CLRF	PORTC
    BANKSEL	LATD	;Data Latch
    CLRF	LATD ;
    BANKSEL	ANSELD 
    CLRF	ANSELD	;digital I/O
    BANKSEL	LATC
    CLRF	LATC
    BANKSEL	ANSELC 
    CLRF	ANSELC
;	    
    MOVLW	0b00000011 ;Set RD0 AND RD1 as inputs
    MOVWF	TRISC

    MOVLW	0b00000000; Set RD as outputs
    MOVWF	TRISD

	;indirect addressing to find the program memory    
    MOVLW	0x0
    MOVWF	TBLPTRL
    MOVLW	0x02
    TBLRD*	; reads value in 0x200 into latch

MAIN:
    CLRF    WREG
    ; check if switch A is pressed(increment)
    BTFSC   SWITCH_A
    MOVLW   0x1
    MOVFF   WREG, BUFFER
    ; check if switch B is pressed(decrement)
    BTFSC   SWITCH_B
    MOVLW   0x2
    MOVFF   WREG, BUFFER
    ; check if both switches A and B are pressed (restart to zero)
    BTFSS   SWITCH_A ; if both on
    BRA	    0x6A     ; if set jump
    BTFSS   SWITCH_B
    BRA	    0x6A     ; if set jump
    MOVLW   0x3
    MOVFF   WREG, BUFFER

    BTFSC   SWITCH_A ; if both off
    BRA	    0x7A
    BTFSC   SWITCH_B
    BRA	    0x7A
    MOVLW   0x4
    MOVFF   WREG, BUFFER
    GOTO    _BUFFCHECK

_BUFFCHECK:
    ;SETF 0x3FD8
    MOVFF   BUFFER, BUFFER2
    MOVLW   0x3
    SUBWF   BUFFER2 ;set zero (3-2=1)
    BZ	    MAIN
    MOVFF   BUFFER, BUFFER2
    MOVLW   0x4
    SUBWF   BUFFER2 ;if equal
    BZ	    _ZERO   ;goto to beginning
    MOVFF   BUFFER, BUFFER2
    MOVLW   0x1
    SUBWF   BUFFER2
    BZ	    COUNT_UP	;increment
    MOVFF   BUFFER, BUFFER2
    MOVLW   0x2
    SUBWF   BUFFER2
    BZ	    COUNT_DOWN	;decrement
    MOVFF   BUFFER, BUFFER2

_DISPLAY:
    ; display on 7 segment
    MOVFF   TABLAT, WREG    ;output of 7 segment
    MOVFF   WREG, DISPLAY
    CLRF    BUFFER
    CLRF    BUFFER2
    GOTO    MAIN

_ZERO:
    ;displays zero
    MOVLW   0x0
    MOVWF   TBLPTRL
    MOVLW   0x02
    MOVWF   TBLPTRH ;pointer looks at 0x200
    TBLRD*
    GOTO    _DISPLAY

COUNT_UP:
    ; incrementation when switch A is pressed
    MOVLW    0x211
    CPFSEQ  TBLPTR
    BRA	    CONTINUE_COUNTUP
    BRA	    RESTART_COUNTUP

    CONTINUE_COUNTUP:
	TBLRD+*	;increment 0x200 to 0x201 then copy value
	MOVFF   TABLAT, WREG	
	MOVFF   WREG, DISPLAY	;display output
	call    _DELAY
	GOTO    _DISPLAY


COUNT_DOWN:
    ; decrementation when switch b is pressed
    MOVLW   0x1FF
    CPFSEQ  TBLPTR
    BRA	    CONTINUE_COUNTDOWN
    BRA	    RESTART_COUNTDOWN

    CONTINUE_COUNTDOWN:
	TBLRD*-	; copy first then decrement
	MOVFF   TABLAT, WREG
	MOVFF   WREG, DISPLAY	; display output
	call    _DELAY
	GOTO    _DISPLAY

RESTART_COUNTDOWN:
    ;reset F to 0
    MOVLW   0x10
    MOVWF   TBLPTRL
    MOVLW   0x02
    MOVWF   TBLPTRH
    TBLRD*
    GOTO    _DISPLAY

RESTART_COUNTUP:
    MOVLW   0x0
    MOVWF   TBLPTRL
    MOVLW   0x02
    MOVWF   TBLPTRH
    TBLRD*
    GOTO    _DISPLAY

_DELAY:
    MOVLW   LOOP1
    MOVWF   REG10
    MOVLW   LOOP2
    MOVWF   REG11
    MOVLW   LOOP3
    MOVWF   REG12

_LOOP:
    DECF    REG10,1
    BNZ	    _LOOP
    DECF    REG11,1
    BNZ	    _LOOP
    DECF    REG12,1
    BNZ	    _LOOP
    RETURN



    ORG 0x200

    DB 0xC0, 0xC0, 0xF9, 0xA4, 0xB0
    DB 0x99, 0x92, 0x82, 0xF8, 0X80
    DB 0x90, 0x08, 0x03, 0x46, 0x21, 0x06, 0x0E, 0x0E
    END
