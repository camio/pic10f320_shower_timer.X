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
#include "hardware.inc"

FNCONF udata,?au_,?pa_
  
; Reset vector
PSECT resetVec,class=CODE
resetVec:
    goto    main
    
PSECT udata
counter:
    DS 1

number:
    DS 2
    
PSECT code
    
delay:
    BTFSS TMR0IF
    GOTO delay
    BCF TMR0IF  
    RETURN

PSECT code
FNROOT main
FNCALL main,hardware_refresh
main:
    ;BCF IRCF0 ; Set frequency to 31 kHz
    ;BCF IRCF1
    ;BCF IRCF2
        
    BCF T0CS   ; Enable timer 0
    BCF TMR0IE ; Disable timer 0 interrupt
    BSF PS0    ; Set prescaler to 1:2
    BSF PS1
    BCF PS2
    BCF PSA    ; Enable prescaler
    CLRF TMR0  ; clear the timer
    
    CALL hardware_initialize

    MOVLW 0xFA
    MOVWF number
    MOVLW 0xCE
    MOVWF number+1
    
    MOVLW number
    CALL hardware_drawHex16
    
loop:
    CALL hardware_refresh
    GOTO loop
    
END resetVec