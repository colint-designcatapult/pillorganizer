#ifndef _IS31FL3730_H_
#define _IS31FL3730_H_

#include <stdint.h>
#include <stdbool.h>
#pragma once

#define ISSI_ADDR           0x60
#define ISSI_I2C_FREQ       400000
#define ISSI_MASTER_PORT    0x00

#define ISSI_REG_CONFIG   0x00
#define ISSI_REG_LE       0x0D
#define ISSI_REG_BRIGHT   0x19
#define ISSI_REG_UPDATE   0x0C
#define ISSI_REG_RESET    0xFF

#define ISSI_REG_MATRIX1  0x01    
#define ISSI_REG_MATRIX2  0x0E    

// configuration regs
#define SHUTDOWN_EN       0x80

#define MODE_MATRIX_2     0x08
#define MODE_MATRIX_1_2   0x18

#define AUDIO_EN          0x04

#define MATRIX_8_8        0x00
#define MATRIX_7_9        0x01
#define MATRIX_6_10       0x02
#define MATRIX_5_11       0x03

#define CURR_SET_40       0x00
#define CURR_SET_45       0x01
#define CURR_SET_75       0x07
#define CURR_SET_5        0x08
#define CURR_SET_10       0x09
#define CURR_SET_35       0x0E
#define CURR_SET_20       0x0B
#define CURR_SET_25       0x0C

#define AGS_3DB           0x10
#define AGS_6DB           0x20
#define AGS_9DB           0x30
#define AGS_12DB          0x40
#define AGS_15DB          0x50
#define AGS_18DB          0x60
#define AGS_N6DB          0x70

#define NUM_COLS            10

// led registers
#define M1_C1             0x01
#define M1_C2             0x02
#define M1_C3             0x03
#define M1_C4             0x04
#define M1_C5             0x05
#define M1_C6             0x06
#define M1_C7             0x07
#define M1_C8             0x08
#define M1_C9             0x09
#define M1_C10            0x0A
#define M1_C11            0x0B

#define M2_C1             0x0E
#define M2_C2             0x0F
#define M2_C3             0x10
#define M2_C4             0x11
#define M2_C5             0x12
#define M2_C6             0x13
#define M2_C7             0x14
#define M2_C8             0x15
#define M2_C9             0x16
#define M2_C10            0x17
#define M2_C11            0x18

// GREEN LED's AM
#define MWFU_G_AM         0x02
#define TRS_G_AM          0x04

// GREEN LED's PM
#define MWFU_G_PM         0x01
#define TRS_G_PM          0x03

// RED LED's AM
#define MWFU_R_AM         0x0F
#define TRS_R_AM          0x11

// RED LED's PM
#define MWFU_R_PM         0x0E
#define TRS_R_PM          0x10

#define MON               0x01
#define TUE               0x01
#define WED               0x02
#define THU               0x02
#define FRI               0x04
#define SAT               0x04
#define SUN               0x08

#define BREATHE


void IS31FL3730_init(void);
void IS31FL3730_clear_LED_states(void);
void IS31FL3730_set_data(uint8_t matrix, uint8_t *data);
void IS31FL3730_set_row(uint8_t matrix, uint8_t row, uint8_t data);
void IS31FL3730_set_col(uint8_t matrix, uint8_t col, uint8_t data);
void IS31FL3730_set_pixel(uint8_t matrix, uint8_t x, uint8_t y, uint8_t c);
void IS31FL3730_set_brightness(uint8_t val);
void IS31FL3730_set_light_effect(uint8_t val);
void IS31FL3730_update_LED_states(void);
void IS31FL3730_shutdown(void);

#endif // _IS31FL3730_H_