; Count on a seven segment display in HEX

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
// Amount of time left on the timer. The high-order byte is minutes in BCD and
// the low-order byte is seconds in BCD
time_left:
    DS 2

PSECT code

// Decrement the parameter by one second. The high order byte is interpreted as
// minutes in BCD and the low order bit is interpreted as seconds in BCD.
FNSIZE time_mmss_dec,0,2
GLOBAL ?pa_time_mmss_dec
time_mmss_dec_minutes EQU ?pa_time_mmss_dec+0
time_mmss_dec_seconds EQU ?pa_time_mmss_dec+1
time_mmss_dec:
    // if seconds is 0x00, handle that in time_mmss_dec_handle_00_seconds
    MOVF time_mmss_dec_seconds,F
    BTFSC ZERO
    GOTO time_mmss_dec_handle_00_seconds

    // if seconds is 0xX0, handle that in time_mmss_dec_handle_X0_seconds
    MOVLW 0x0F
    ANDWF time_mmss_dec_seconds,W
    BTFSC ZERO
    GOTO time_mmss_dec_handle_X0_seconds

    // otherwise, just decrement
    DECF time_mmss_dec_seconds,F
    RETURN

time_mmss_dec_handle_X0_seconds:
    MOVLW 0x07
    SUBWF time_mmss_dec_seconds,F
    RETURN

time_mmss_dec_handle_00_seconds:
    MOVLW 0x59
    MOVWF time_mmss_dec_seconds

    // decrement a minute
    // if minutes is 0x00, handle that in time_mmss_dec_handle_00_minutes
    MOVF time_mmss_dec_minutes,F
    BTFSC ZERO
    GOTO time_mmss_dec_handle_00_minutes

    // if minutes is 0xX0, handle that in time_mmss_dec_handle_X0_minutes
    MOVLW 0x0F
    ANDWF time_mmss_dec_minutes,W
    BTFSC ZERO
    GOTO time_mmss_dec_handle_X0_minutes

    // otherwise, just decrement
    DECF time_mmss_dec_minutes,F
    RETURN
time_mmss_dec_handle_X0_minutes:
    MOVLW 0x07
    SUBWF time_mmss_dec_minutes,F
    RETURN
time_mmss_dec_handle_00_minutes:
    MOVLW 0x99
    MOVWF time_mmss_dec_minutes
    RETURN

FNROOT main
main:
    ;BCF IRCF0 ; Set frequency to 31 kHz
    ;BCF IRCF1
    ;BCF IRCF2

    BCF T0CS   ; Enable timer 0
    BCF TMR0IE ; Disable timer 0 interrupt
    BSF PS0    ; Set prescaler to 1:256
    BSF PS1
    BSF PS2
    BCF PSA    ; Enable prescaler
    CLRF TMR0  ; clear the timer

    FNCALL main,hardware_initialize
    CALL hardware_initialize
    MOVLW SSDH_COLON
    MOVWF aux_buffer

    CLRF time_left
    CLRF time_left+1

    MOVF time_left,W
    MOVWF ?pa_hardware_drawHex16+0
    MOVF time_left+1,W
    MOVWF ?pa_hardware_drawHex16+1
    FNCALL main,hardware_drawHex16
    CALL hardware_drawHex16

loop:
    BTFSC TMR0IF
    GOTO tick
    GOTO endtick
tick:
    BCF TMR0IF

    // time = time_mmss_dec(time)
    MOVF time_left,W
    MOVWF ?pa_time_mmss_dec+0
    MOVF time_left+1,W
    MOVWF ?pa_time_mmss_dec+1
    FNCALL main,time_mmss_dec
    CALL time_mmss_dec
    MOVF ?pa_time_mmss_dec+0,W
    MOVWF time_left+0
    MOVF ?pa_time_mmss_dec+1,W
    MOVWF time_left+1

    // hardware_drawHex16(number)
    MOVF time_left,W
    MOVWF ?pa_hardware_drawHex16+0
    MOVF time_left+1,W
    MOVWF ?pa_hardware_drawHex16+1
    FNCALL main,hardware_drawHex16
    CALL hardware_drawHex16
endtick:
    FNCALL main,hardware_refresh
    CALL hardware_refresh
    GOTO loop

END resetVec
