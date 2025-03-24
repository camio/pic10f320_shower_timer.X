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

#define SSDH_DIGIT_0 1
#define SSDH_DIGIT_1 (1<<1)
#define SSDH_DIGIT_2 (1<<2)
#define SSDH_DIGIT_3 (1<<3)
#define SSDH_BUZZER (1<<4)
#define SSDH_X0 (1<<5)
#define SSDH_X1 (1<<6)
#define SSDH_COLON (1<<7)
