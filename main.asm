; Display a count down and alarm when it reaches zero

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
GLOBAL alarm_state
alarm_state:
    DS 1
porta_last_state:
    DS 1
porta_current_state:
    DS 1

// Amount of time left on the timer. The high-order byte is minutes in BCD and
// the low-order byte is seconds in BCD
GLOBAL time_left
time_left:
    DS 2

PSECT code

FNROOT main
main:
    ; Default frequency, 4Mhz, is fine.
    MOVLW 01010000B
    MOVWF OSCCON

    ; Set prescaler enabled to 1:64, weak pull-ups enabled, and interrupt on falling edge of INT piin
    MOVLW 00000101B
    MOVWF OPTION_REG

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

    MOVF PORTA,W
    MOVWF porta_last_state

    CLRF time_left
    MOVLW 0x59
    MOVWF time_left+1

    MOVF time_left,W
    MOVWF ?pa_hardware_drawHex16+0
    MOVF time_left+1,W
    MOVWF ?pa_hardware_drawHex16+1
    FNCALL main,hardware_drawHex16
    CALL hardware_drawHex16

loop:
    BTFSS TMR0IF
    GOTO end_button_check

    ; check for button state change
    MOVF PORTA,W
    MOVWF porta_current_state

    MOVF porta_last_state,W
    XORWF porta_current_state,W
    ANDLW 00001000
    BTFSC ZERO
    GOTO end_button_check

    ; handle button state change
    MOVF porta_current_state,W
    MOVWF porta_last_state
    BTFSS porta_last_state,3
    GOTO add_more_time

end_button_check:

    CALL timer_check
    ANDLW 0x01
    BTFSS ZERO
    GOTO decrement_clock
    GOTO redraw_and_loop

add_more_time:
    MOVLW 0x0F
    ANDWF time_left,W
    XORLW 0x09
    MOVLW 0x01
    BTFSC ZERO
    MOVLW 0x07
    ADDWF time_left,F
    GOTO draw_hex

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

draw_hex:
    // hardware_drawHex16(number)
    MOVF time_left,W
    MOVWF ?pa_hardware_drawHex16+0
    MOVF time_left+1,W
    MOVWF ?pa_hardware_drawHex16+1
    FNCALL main,hardware_drawHex16
    CALL hardware_drawHex16

    MOVF time_left,F
    BTFSS ZERO
    GOTO redraw_and_loop
    MOVF time_left+1,F
    BTFSC ZERO
    GOTO alarm

redraw_and_loop:
    FNCALL main,hardware_refresh
    CALL hardware_refresh
    GOTO loop

alarm:
    CLRF alarm_state

    // Start 0.5s timer (0x1E84 duration units)
    MOVLW 0x1E
    MOVWF ?pa_timer_initialize+0
    MOVLW 0x84
    MOVWF ?pa_timer_initialize+1
    FNCALL main,timer_initialize
    CALL timer_initialize
    CALL timer_start
alarm_loop:
    CALL timer_check
    ANDLW 0x01
    BTFSS ZERO
    GOTO buzz_flip
    GOTO alarm_loop_continue
buzz_flip:
    MOVLW 0x01
    XORWF alarm_state,F
    BTFSS ZERO
    GOTO buzz_off
buzz_on:
    MOVLW SSDH_BUZZER
    MOVWF aux_buffer
    MOVLW SSDL_CH_0
    MOVWF display_buffer+0
    MOVWF display_buffer+1
    MOVWF display_buffer+2
    MOVWF display_buffer+3
    GOTO alarm_loop_continue
buzz_off:
    MOVLW SSDH_COLON
    MOVWF aux_buffer
    CLRF display_buffer+0
    CLRF display_buffer+1
    CLRF display_buffer+2
    CLRF display_buffer+3
alarm_loop_continue:
    CALL hardware_refresh
    GOTO alarm_loop

END resetVec
