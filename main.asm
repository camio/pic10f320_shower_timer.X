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
#include "timer.inc"

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

    BSF PS0    ; Set prescaler to 1:64
    BCF PS1
    BSF PS2
    BCF PSA    ; Enable prescaler

    FNCALL main,hardware_initialize
    CALL hardware_initialize
    MOVLW SSDH_COLON
    MOVWF aux_buffer

    // 4,000,000 = clock cycles per second
    // 4,000,000/4 = 1,000,000 = instructions per second
    // 1,000,000/64 = 15,625 = 0x3D09 number of timer ticks per second w/ multiplier
    MOVLW 0x3D
    MOVWF ?pa_timer_initialize+0
    MOVLW 0x09
    MOVWF ?pa_timer_initialize+1
    FNCALL main,timer_initialize
    CALL timer_initialize

    CALL timer_start

    CLRF time_left
    CLRF time_left+1

    MOVF time_left,W
    MOVWF ?pa_hardware_drawHex16+0
    MOVF time_left+1,W
    MOVWF ?pa_hardware_drawHex16+1
    FNCALL main,hardware_drawHex16
    CALL hardware_drawHex16

loop:
    CALL timer_check
    ANDLW 0x01
    BTFSS ZERO
    GOTO decrement_clock
    GOTO redraw_and_loop
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

redraw_and_loop:
    FNCALL main,hardware_refresh
    CALL hardware_refresh
    GOTO loop

END resetVec
