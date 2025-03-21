; Count a binary number using a shift register

PROCESSOR 10F320
    
; CONFIG
  CONFIG  FOSC = INTOSC         ; Oscillator Selection bits (INTOSC oscillator: CLKIN function disabled)
  CONFIG  BOREN = OFF           ; Brown-out Reset Enable (Brown-out Reset disabled)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable (WDT disabled)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = OFF           ; MCLR Pin Function Select bit (MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  LVP = OFF             ; Low-Voltage Programming Enable (High-voltage on MCLR/VPP must be used for programming)
  CONFIG  LPBOR = OFF           ; Brown-out Reset Selection bits (BOR disabled)
  CONFIG  BORV = LO             ; Brown-out Reset Voltage Selection (Brown-out Reset Voltage (Vbor), low trip point selected.)
  CONFIG  WRT = OFF             ; Flash Memory Self-Write Protection (Write protection off)

#include <xc.inc>

; Reset vector
PSECT resetVec,class=CODE
resetVec:
    goto    main

; Caller-saved function local variables
PSECT udata
X:
    DS 1   
Y:
    DS 1   
Z:
    DS 1
    
PSECT udata
counter:
    DS 1

digit:
    DS 1

shiftRegister:
    DS 2

#define LAT_SER   LATA0
#define LAT_RCLK  LATA1
#define LAT_SRCLK LATA2

#define TRIS_SER  TRISA0
#define TRIS_RCLK TRISA1
#define TRIS_SRCLK TRISA2

#define SSDL_A 1
#define SSDL_B (1 << 1)
#define SSDL_C (1 << 2)
#define SSDL_D (1 << 3)
#define SSDL_E (1 << 4)
#define SSDL_F (1 << 5)
#define SSDL_G (1 << 6)
#define SSDL_DP (1 << 7)
    
#define SSDL_CH_0 SSDL_A | SSDL_B | SSDL_C | SSDL_D | SSDL_E | SSDL_F
#define SSDL_CH_1 SSDL_B | SSDL_C
#define SSDL_CH_2 SSDL_A | SSDL_B | SSDL_D | SSDL_E | SSDL_G
#define SSDL_CH_3 SSDL_A | SSDL_B | SSDL_C | SSDL_D | SSDL_G
#define SSDL_CH_4 SSDL_B | SSDL_C | SSDL_F | SSDL_G
#define SSDL_CH_5 SSDL_A | SSDL_C | SSDL_D | SSDL_F | SSDL_G
#define SSDL_CH_6 SSDL_A | SSDL_C | SSDL_D | SSDL_E | SSDL_F | SSDL_G
#define SSDL_CH_7 SSDL_A | SSDL_B | SSDL_C
#define SSDL_CH_8 SSDL_A | SSDL_B | SSDL_C | SSDL_D | SSDL_E | SSDL_F | SSDL_G
#define SSDL_CH_9 SSDL_A | SSDL_B | SSDL_C | SSDL_F | SSDL_G

#define SSDL_CH_A SSDL_A | SSDL_B | SSDL_C | SSDL_E | SSDL_F | SSDL_G    
#define SSDL_CH_B SSDL_C | SSDL_D | SSDL_E | SSDL_F | SSDL_G  
#define SSDL_CH_C SSDL_A | SSDL_D | SSDL_E | SSDL_F  
#define SSDL_CH_D SSDL_B | SSDL_C | SSDL_D | SSDL_E | SSDL_G    
#define SSDL_CH_E SSDL_A | SSDL_D | SSDL_E | SSDL_F | SSDL_G
#define SSDL_CH_F SSDL_A | SSDL_E | SSDL_F | SSDL_G

#define SSDH_D1 1
#define SSDH_D2 (1<<1)
#define SSDH_D3 (1<<2)
#define SSDH_D4 (1<<3)
#define SSDH_BUZZER (1<<4)
#define SSDH_X1 (1<<5)
#define SSDH_X2 (1<<6)   
#define SSDH_X3 (1<<7)
    
PSECT code
 
delay:
    BTFSS TMR0IF
    GOTO delay
    BCF TMR0IF  
    RETURN

; Returns the seven segement display for hex digit in W.
; - precondition: 0 <= W <= 0x0F
chr:
    ADDWF PCL,F
    RETLW SSDL_CH_0
    RETLW SSDL_CH_1
    RETLW SSDL_CH_2
    RETLW SSDL_CH_3
    RETLW SSDL_CH_4
    RETLW SSDL_CH_5
    RETLW SSDL_CH_6
    RETLW SSDL_CH_7
    RETLW SSDL_CH_8
    RETLW SSDL_CH_9
    RETLW SSDL_CH_A
    RETLW SSDL_CH_B
    RETLW SSDL_CH_C
    RETLW SSDL_CH_D
    RETLW SSDL_CH_E
    RETLW SSDL_CH_F

; Sets the shift register's value to the two-byte word pointed to by W
setOutput:
    MOVWF FSR   ; X=*W
    MOVF INDF,W
    MOVWF X
        
    MOVLW 0x02 ; bank(Z)=0x02
    MOVWF Z
    
setOutput_for_each_bank:
    MOVLW 0x08 ; bit(Y)=0x08
    MOVWF Y
setOutput_for_each_bit:    
    BSF LAT_SER
    RLF X,F
    BTFSS CARRY
    BCF LAT_SER
    BSF LAT_SRCLK ; Tick SRCLK
    BCF LAT_SRCLK
    DECFSZ Y,F
    GOTO setOutput_for_each_bit

    INCF FSR    ; X=*(W+1)
    MOVF INDF,W
    MOVWF X
    
    DECFSZ Z,F
    GOTO setOutput_for_each_bank
    
    BSF LAT_RCLK ; Tick RCLK
    BCF LAT_RCLK
    
    RETURN

PSECT code
main:
    BCF IRCF0 ; Set frequency to 31 kHz
    BCF IRCF1
    BCF IRCF2
        
    BCF T0CS   ; Enable timer 0
    BCF TMR0IE ; Disable timer 0 interrupt
    BSF PS0    ; Set prescaler to 1:2
    BSF PS1
    BCF PS2
    BCF PSA    ; Enable prescaler
    CLRF TMR0  ; clear the timer
    
    BCF TRIS_SER ; Set RA's 0-2 to output mode
    BCF TRIS_RCLK
    BCF TRIS_SRCLK

    CLRF digit
loop:
    MOVLW 0x10
    XORWF digit,W
    BTFSC ZERO
    GOTO end_loop

    MOVLW SSDH_D4
    MOVWF shiftRegister
    MOVF digit,W
    CALL chr
    MOVWF shiftRegister+1
    MOVLW shiftRegister
    CALL setOutput
    
    CALL delay
    
    INCF digit,F
    GOTO loop
end_loop:
    GOTO main
    
/*    
    ; Set shift register to 0x0FFF
    MOVLW SSDH_D4
    MOVWF shiftRegister
    MOVLW SSDL_A | SSDL_B | SSDL_C
    MOVWF shiftRegister+1   
    MOVLW shiftRegister
    CALL setOutput

loop:
    MOVLW SSDH_D1
    MOVWF shiftRegister
    MOVLW SSDL_CH_A
    MOVWF shiftRegister+1   
    MOVLW shiftRegister
    CALL setOutput
    
    MOVLW SSDH_D2
    MOVWF shiftRegister
    MOVLW SSDL_CH_D
    MOVWF shiftRegister+1   
    MOVLW shiftRegister
    CALL setOutput
        
    MOVLW SSDH_D3
    MOVWF shiftRegister
    MOVLW SSDL_CH_B
    MOVWF shiftRegister+1   
    MOVLW shiftRegister
    CALL setOutput
    
    MOVLW SSDH_D4
    MOVWF shiftRegister
    MOVLW SSDL_CH_E
    MOVWF shiftRegister+1   
    MOVLW shiftRegister
    CALL setOutput

    
    GOTO loop
*/    
    
;    CLRF counter
;loop:
;    BTFSS TMR0IF
;    GOTO loop
;    BCF TMR0IF
 
;    ; call setOutput with counter
;    MOVF counter,W
;    CALL setOutput
    
;    INCF counter, F
;    GOTO loop
    
END resetVec