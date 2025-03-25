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
#include "time.inc"

FNCONF udata,?au_,?pa_

; Reset vector
PSECT resetVec,class=CODE
resetVec:
    goto    main

PSECT udata
GLOBAL counter
counter:
    DS 1
// Amount of time left on the timer. The high-order byte is minutes in BCD and
// the low-order byte is seconds in BCD
time_left:
    DS 2

PSECT code

FNROOT main
main:
    BSF IRCF0 ; Set frequency to 4 Mhz
    BCF IRCF1
    BSF IRCF2

    BCF T0CS   ; Enable timer 0
    BCF TMR0IE ; Disable timer 0 interrupt
    BSF PS0    ; Set prescaler to 1:64
    BCF PS1
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

    CLRF counter
loop:
    BTFSC TMR0IF
    GOTO tick
    GOTO endtick
tick:
    BCF TMR0IF
    INCF counter,F

    // If counter is at 0x3D, go to last_run
    // 4,000,000 = clock cycles per second
    // 4,000,000/4 = 1,000,000 = instructions per second
    // 1,000,000/64 = 15,625 = number of timer ticks per second w/ multiplier
    // 15,555/255 = 61 = number of full timer interupts that fit within a second
    MOVLW 61
    XORWF counter,W
    BTFSC ZERO
    GOTO last_run

    // If counter is at 0x3E, go to decrement_clock
    MOVLW 0x3E
    XORWF counter,W
    BTFSC ZERO
    GOTO decrement_clock

    // Otherwise
    GOTO endtick

last_run:
    // 15,625 - 15,555 = 70 = number of timer ticks required on the last run
    // 255-70 = 185 number of timer ticks needed to adjust TMR0 to account for
    //          the last run
    //
    // Note that when TMR0 is written, its increment is inhibited for two
    // instruction cycles. This is hopefully okay because there hasn't been
    // 64 instruction cycles since the last interrupt.
    MOVLW 185
    ADDWF TMR0,F
    GOTO endtick

decrement_clock:
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
    CLRF counter
    GOTO endtick

endtick:
    FNCALL main,hardware_refresh
    CALL hardware_refresh
    GOTO loop

END resetVec
