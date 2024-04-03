;---------------------
; Title: Counter Design
;---------------------
; Program Details:
; The purpose of this program is to have a 7-segment display turn on and increment when switch A is pressed and stop incrementing once it is released.
; It also needs to decrement the same way when switch B is pressed and stop once it is released.
; If both switches are pressed simultaneously, the counter resets to zero.
; The range of the counter is from 0 to F.
; Outputs: RD0 (output)
; Inputs: RC0 and RC1 (inputs)
; Setup: The PICKIT4 can use its internal 5V. No external power is needed.
; Date: March 27, 2024
; File Dependencies / Libraries: It is required to include the AssemblyConfig.inc in the Header Folder
; Compiler: xc8, 2.4
; Author: Pablo Orozco
; Versions:
; V1.0: March 23, 2024
; V2: March 26, 2024
; V3: March 28, 2024 (Modified for the desired functionality)
; V4: March 28, 2024 (Revised to address issues)
; Useful links: 
;       Datasheet: https://ww1.microchip.com/downloads/en/DeviceDoc/PIC18(L)F26-27-45-46-47-55-56-57K42-Data-Sheet-40001919G.pdf 
;       PIC18F Instruction Sets: https://onlinelibrary.wiley.com/doi/pdf/10.1002/9781119448457.app4 
;       List of Instructions: http://143.110.227.210/faridfarahmand/sonoma/courses/es310/resources/20140217124422790.pdf 


#include "AssemblyConfig.inc"
#include "xc.inc"

; Program Constants
INNER_LOOP       EQU 0xFF
INNER_LOOP_REG   EQU 0x20
INNER_LOOP_2     EQU 0xFF
INNER_LOOP_2_REG EQU 0x24

; Constants
#define BUTTON_1  PORTC, 0
#define BUTTON_2  PORTC, 1

; Main Program
PSECT absdata,abs,ovrld
    ORG 0x00           ; Reset vector
    GOTO InitializePorts
    ORG 0x0020         ; Begin assembly at 0020H
    
InitializePorts:
    ; Initialize ports for inputs/outputs
    BANKSEL PORTD
    CLRF PORTD
    BANKSEL LATD
    CLRF LATD
    BANKSEL ANSELD
    CLRF ANSELD
    BANKSEL TRISD
    CLRF TRISD ; Set PORTD to outputs
   
    BANKSEL PORTC
    CLRF PORTC
    BANKSEL LATC
    CLRF LATC
    BANKSEL ANSELC
    CLRF ANSELC
    BANKSEL TRISC
    MOVLW 0b00000011 ; Set RC0 & RC1 as inputs
    MOVWF TRISC  

    CALL SetupRegisters
    CALL CheckReset
    
ButtonSetup:
    BTFSS BUTTON_2 ; If pressed, skip
    GOTO Button2Pressed
    BTFSS BUTTON_1 ; If pressed, skip
    GOTO Button1Pressed
    GOTO ButtonSetup ; Constantly checking if a button is pushed

SetupRegisters:
    MOVLW 0x00 ; Setting the upper table pointer
    MOVWF TBLPTRU
    MOVLW 0x01 ; Setting the higher table pointer
    MOVWF TBLPTRH
    RETURN

CheckReset:
    MOVLW 0x60 ; Setting lower table pointer
    MOVWF TBLPTRL
    TBLRD*      ; Read from table latch
    MOVFF TABLAT, PORTD ; Displaying 0
    RCALL Delay   ; Rough 1 sec delay
    RETURN

Button2Pressed:
    BTFSS BUTTON_1 ; Checks if both buttons are pressed
    GOTO CheckReset ; If button 1 now pressed too, go to CheckReset
    RCALL DisplayValue
    RCALL CheckTableDecrement
    RCALL Delay   ; Roughly 1 sec delay
    DECF TBLPTRL, F ; Decrements from table pointer of seg table
    GOTO Button2Pressed ; Loop decrementation

CheckTableDecrement:
    MOVLW 0x5F ; Pointed at before our seg table    
    CPFSGT TBLPTRL ; If pointer is still within boundaries, skip    
    GOTO ResetNegativeRegs ; Pointer is outside boundaries, reset
    BTFSC BUTTON_2 ; Checks if button_2 is still pressed 
    GOTO ButtonSetup ; If not pressed, go to button setup to hold value 
    RETURN ; Return to decrementation loop

ResetNegativeRegs:
    MOVLW 0x00 ; Setting the upper table pointer
    MOVWF TBLPTRU
    MOVLW 0x01 ; Setting the higher table pointer
    MOVWF TBLPTRH
    MOVLW 0x6F ; Setting the higher table pointer
    MOVWF TBLPTRL
    RETURN

Button1Pressed:
    BTFSS BUTTON_2 ; Checks if both are pressed
    GOTO CheckReset ; If now button_2 is pushed too, go to reset
    RCALL DisplayValue ; Function to display value 
    RCALL CheckTableIncrement ; Checks seg table pointers
    RCALL Delay   ; Calls roughly 1 min delay
    INCF TBLPTRL, F ; Increments table pointers to be ahead of display
    GOTO Button1Pressed ; Loop incrementation

DisplayValue:
    TBLRD*
    MOVFF TABLAT, PORTD
    RETURN
    
CheckTableIncrement:
    MOVLW 0x70 ; Puts value that is last on the seg table in WREG    
    CPFSLT TBLPTRL ; Compares WREG to our lower table pointer (ahead)    
    GOTO ResetPositiveRegs ; If out of bounds, resets table pointers 
    BTFSC BUTTON_1 ; If in bounds, rechecks button pressed
    GOTO ButtonSetup ; If button_1 is pressed, value is held and buttons are rechecked
    RETURN ; Returns to incrementation loop
    
ResetPositiveRegs:
    MOVLW 0x00 ; Setting the upper table pointer
    MOVWF TBLPTRU
    MOVLW 0x01 ; Setting the higher table pointer
    MOVWF TBLPTRH
    MOVLW 0x60 ; Setting the higher table pointer
    MOVWF TBLPTRL
    RETURN

Delay:
    MOVLW INNER_LOOP_2
    MOVWF INNER_LOOP_2_REG
    
OuterLoop:  
    MOVLW INNER_LOOP
    MOVWF INNER_LOOP_REG
    
InnerLoop:
    DECF INNER_LOOP_REG,F
    NOP
    NOP
    BNZ InnerLoop
    DECF INNER_LOOP_2_REG
    BZ EndOfLoop
    GOTO OuterLoop
EndOfLoop:
    RETURN
    
ORG 0x160
SEG_TABLE:   DB  0xC0, 0xF9, 0xA4, 0xB0, 0x99, 0x92 ;0-5 in display
   DB  0x82, 0xF8, 0x80, 0x90,0x88 ; 6-10 in display
   DB  0x83, 0xC6, 0xA1, 0x86 ; B-E in display
   DB 0x8E; F (15) in display
