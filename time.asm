PROCESSOR 10F320

#include <xc.inc>

// Decrement the parameter by one second. The high order byte is interpreted as
// minutes in BCD and the low order bit is interpreted as seconds in BCD.
GLOBAL time_mmss_dec
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
