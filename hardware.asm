PROCESSOR 10F320

#include <xc.inc>

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

GLOBAL hardware_refresh
GLOBAL hardware_drawHex16
GLOBAL hardware_initialize

PSECT udata

GLOBAL display_buffer
display_buffer:
    DS 4

GLOBAL next_digit
next_digit:
    DS 1

PSECT code
// Draws, on the display_buffer, the 16-bit hex number pointed to by W 
hardware_drawHex16:
    MOVWF FSR

    SWAPF INDF,W
    ANDLW 0x0F
    CALL chr
    MOVWF display_buffer
    
    MOVF INDF,W
    ANDLW 0x0F
    CALL chr
    MOVWF display_buffer+1

    INCF FSR,F
    
    SWAPF INDF,W
    ANDLW 0x0F
    CALL chr
    MOVWF display_buffer+2
    
    MOVF INDF,W
    ANDLW 0x0F
    CALL chr
    MOVWF display_buffer+3
    
    RETURN

// Return the high byte of the output port corresponding to the specified digit
// (0 counted)
ssdh_from_digit:
    ADDWF PCL,F
    RETLW SSDH_D1 ; TODO: rename these starting with 0
    RETLW SSDH_D2
    RETLW SSDH_D3
    RETLW SSDH_D4

// Render one frame to the display of `display_buffer`. A single frame
// corresponds to a single digit. This function, when called repeatedly, will
// strobe between the different digits.
FNSIZE hardware_refresh,2,0
GLOBAL ?au_hardware_refresh
hardware_refresh_shiftRegisterHigh EQU ?au_hardware_refresh
hardware_refresh_shiftRegisterLow EQU ?au_hardware_refresh+1
FNCALL hardware_refresh,setOutput
hardware_refresh:
    MOVF next_digit, W
    CALL ssdh_from_digit
    MOVWF hardware_refresh_shiftRegisterHigh
    MOVLW display_buffer
    ADDWF next_digit,W
    MOVWF FSR
    MOVF INDF, W
    MOVWF hardware_refresh_shiftRegisterLow
    
    MOVLW hardware_refresh_shiftRegisterHigh
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
FNSIZE setOutput,3,0
GLOBAL ?au_setOutput
setOutput_x EQU ?au_setOutput+0
setOutput_bit EQU ?au_setOutput+1
setOutput_bank EQU ?au_setOutput+2
setOutput:
    MOVWF FSR   ; X=*W
    MOVF INDF,W
    MOVWF setOutput_x
        
    MOVLW 0x02 ; bank(Z)=0x02
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

    INCF FSR    ; X=*(W+1)
    MOVF INDF,W
    MOVWF setOutput_x
    
    DECFSZ setOutput_bank,F
    GOTO setOutput_for_each_bank
    
    BSF LAT_RCLK ; Tick RCLK
    BCF LAT_RCLK
    
    RETURN

hardware_initialize:
    BCF TRIS_SER ; Set RA's 0-2 to output mode
    BCF TRIS_RCLK
    BCF TRIS_SRCLK    
    CLRF next_digit
    RETURN