PROCESSOR 10F320

#include <xc.inc>

#include "hardware_defs.inc"

PSECT udata

GLOBAL display_buffer
display_buffer:
    DS 4

// The 4 highest bits of this byte represent the desired setting of the 4
// highest bits of the shift register output. The 4 lowest bits of this byte
// must always be set to 0.
GLOBAL aux_buffer
aux_buffer:
    DS 1

GLOBAL next_digit
next_digit:
    DS 1

PSECT code

// Draws, on the display_buffer, the 16-bit hex number pointed to by W
GLOBAL hardware_drawHex16
FNSIZE hardware_drawHex16,0,2
GLOBAL ?pa_hardware_drawHex16
hardware_drawHex16_valueHigh EQU ?pa_hardware_drawHex16+0
hardware_drawHex16_valueLow EQU ?pa_hardware_drawHex16+1
hardware_drawHex16:
    SWAPF hardware_drawHex16_valueHigh,W
    ANDLW 0x0F
    CALL chr
    MOVWF display_buffer

    MOVF hardware_drawHex16_valueHigh,W
    ANDLW 0x0F
    CALL chr
    MOVWF display_buffer+1

    SWAPF hardware_drawHex16_valueLow,W
    ANDLW 0x0F
    CALL chr
    MOVWF display_buffer+2

    MOVF hardware_drawHex16_valueLow,W
    ANDLW 0x0F
    CALL chr
    MOVWF display_buffer+3

    RETURN

// Return the high byte of the output port corresponding to the specified digit
// (0 counted)
ssdh_from_digit:
    ADDWF PCL,F
    RETLW SSDH_DIGIT_0
    RETLW SSDH_DIGIT_1
    RETLW SSDH_DIGIT_2
    RETLW SSDH_DIGIT_3

// Render one frame to the display of `display_buffer`. A single frame
// corresponds to a single digit. This function, when called repeatedly, will
// strobe between the different digits.
GLOBAL hardware_refresh
hardware_refresh:
    MOVF next_digit, W
    CALL ssdh_from_digit
    ; W has the bit pattern for the digit.
    IORWF aux_buffer,W
    ; W has the digit bit pattern combined with the auxiliary bits
    MOVWF ?pa_setOutput+0
    MOVLW display_buffer
    ADDWF next_digit,W
    MOVWF FSR
    MOVF INDF, W
    MOVWF ?pa_setOutput+1

    FNCALL hardware_refresh,setOutput
    CALL setOutput

    // Option 1: Fix value before decrementing the counter. Counter ranges
    // beteen 0 and 3. Uses 6 instructions.

    MOVF next_digit, W
    BTFSC ZERO
    MOVLW 0x04
    MOVWF  next_digit
    DECF next_digit, F
    RETURN

    /*
    // Option 2: Fix value after decrementing the counter. Counter ranges
    // between 1 and 4. Uses 5 instructions, but requires 2 elsewhere.
    DECFSZ next_digit,F
    RETURN
    MOVLW 0x04
    MOVWF next_digit
    RETURN
    */

    /*
    // Option 3: Explicitly handle base case when incrementing the counter.
    // Counter ranges between 0 and 3. Uses 8 instructions.
    MOVLW 0x03
    SUBWF next_digit,W
    BTFSC ZERO
    GOTO foo
    INCF next_digit,F
    RETURN
foo:
    CLRF next_digit
    RETURN
    */

    /*
    // Option 4: Fix value (cleverly) after incrementing the counter. Counter
    // ranges between 0 and 3. Uses 7 instructions.
    MOVLW 0xFD
    ADDWF next_digit, F
    BTFSC ZERO
    MOVLW 0x01
    ADDLW -1
    SUBWF next_digit, F
    RETURN
     */

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
FNSIZE setOutput,3,2
GLOBAL ?au_setOutput
setOutput_x EQU ?au_setOutput+0
setOutput_bit EQU ?au_setOutput+1
setOutput_bank EQU ?au_setOutput+2
GLOBAL ?pa_setOutput
setOutput_valueHigh EQU ?pa_setOutput+0
setOutput_valueLow EQU ?pa_setOutput+1
setOutput:
    MOVF setOutput_valueHigh,W
    MOVWF setOutput_x

    MOVLW 0x02 ; bank=0x02
    MOVWF setOutput_bank

setOutput_for_each_bank:
    MOVLW 0x08 ; bit(Y)=0x08
    MOVWF setOutput_bit
setOutput_for_each_bit:
    BSF LAT_SER
    RLF setOutput_x,F
    BTFSS CARRY
    BCF LAT_SER
    BSF LAT_SRCLK ; Tick SRCLK
    BCF LAT_SRCLK
    DECFSZ setOutput_bit,F
    GOTO setOutput_for_each_bit

    MOVF setOutput_valueLow,W
    MOVWF setOutput_x

    DECFSZ setOutput_bank,F
    GOTO setOutput_for_each_bank

    BSF LAT_RCLK ; Tick RCLK
    BCF LAT_RCLK

    RETURN

GLOBAL hardware_initialize
hardware_initialize:
    BCF TRIS_SER ; Set RA's 0-2 to output mode
    BCF TRIS_RCLK
    BCF TRIS_SRCLK
    CLRF next_digit
    CLRF aux_buffer
    CLRF display_buffer
    CLRF display_buffer+1
    CLRF display_buffer+2
    CLRF display_buffer+3
    RETURN
