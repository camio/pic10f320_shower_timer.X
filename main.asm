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

number:
    DS 2

shiftRegister:
    DS 2

display_buffer:
    DS 4

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
hardware_refresh:
    // DECF next_digit, W
    MOVF next_digit, W
    CALL ssdh_from_digit
    MOVWF shiftRegister  
    MOVLW display_buffer
    ADDWF next_digit,W
    // ADDLW -1
    MOVWF FSR
    MOVF INDF, W
    MOVWF shiftRegister+1
    
    MOVLW shiftRegister
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

hardware_initialize:
    BCF TRIS_SER ; Set RA's 0-2 to output mode
    BCF TRIS_RCLK
    BCF TRIS_SRCLK    
    CLRF next_digit
    RETURN

PSECT code
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