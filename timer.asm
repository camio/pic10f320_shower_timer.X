PROCESSOR 10F320

#include <xc.inc>

PSECT udata

GLOBAL timer_duration
timer_duration:
    DS 2

GLOBAL timer_counter_high
timer_counter_high:
    DS 1

PSECT code

// Initialize the timer such that it will be emitted after the given 16-bit
// duration. If PSA==1 the duration unit is instruction cycles, otherwise, it
// is in instruction cycles multipled by the inverse of the TMR0 rate specfied
// by PSA<2:0>.
GLOBAL timer_initialize
FNSIZE timer_initialize,1,2
GLOBAL ?pa_timer_initialize
GLOBAL ?au_timer_initialize
timer_initialize_tmp EQU ?au_timer_initialize+0
timer_initialize:
    MOVF ?pa_timer_initialize+0,W
    MOVWF timer_duration+0
    MOVF ?pa_timer_initialize+1,W
    MOVWF timer_duration+1

// Start the timer
GLOBAL timer_start
timer_start:
    BCF TMR0IE ; Disable timer 0 interrupt
    BCF T0CS   ; Enable timer 0
    CLRF timer_counter_high ; Clear the high-order counter byte
    CLRF TMR0  ; clear the low-order counter byte
    BCF TMR0IF ; clear the low-order counter's overflow flag

// Check if the timer has triggered. For proper usage, this function must be
// called at least once per 0x100 duration units.
GLOBAL timer_check
timer_check:
    BTFSC TMR0IF
    GOTO tick
    GOTO handle_no_timeout
tick:
    BCF TMR0IF
    INCF timer_counter_high,F

    MOVF timer_duration+0,W
    XORWF timer_counter_high,W
    BTFSC ZERO
    GOTO last_run

    INCF timer_duration+0,W
    XORWF timer_counter_high,W
    BTFSC ZERO
    GOTO handle_timeout

    // Otherwise
    GOTO handle_no_timeout

last_run:
    // 15,625 - 15,555 = 70 = number of timer ticks required on the last run
    // 255-70 = 185 number of timer ticks needed to adjust TMR0 to account for
    //          the last run
    //
    // Note that when TMR0 is written, its increment is inhibited for two
    // instruction cycles. This is hopefully okay because there hasn't been
    // 64 instruction cycles since the last interrupt.

    MOVLW 0xFF                   ; W=0xFF-(timer_duration+1)
    MOVWF timer_initialize_tmp
    MOVF timer_duration+1,W
    SUBWF timer_initialize_tmp,W

    ADDWF TMR0,F
    GOTO handle_no_timeout

handle_timeout:
    CLRF timer_counter_high
    RETLW 1

handle_no_timeout:
    RETLW 0
