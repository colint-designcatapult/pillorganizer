/* 
 * Pill Organizer Pin Definitions
 * 
 * Board revision:   F
 * Schematic number: 5091-01-3001
 * Schematic date:   8/01/2023
 */
#pragma once

/* ========================================================== 
 * MUX Pin Definitions / Configuration
 * ==========================================================*/

#include "../ulp/mux_config.h"

#define MUX_CHANNELS 16

/* MUX channel selector pins */
#define MUX_PIN_A GPIO_NUM_32
#define MUX_PIN_B GPIO_NUM_33
#define MUX_PIN_C GPIO_NUM_27
#define MUX_PIN_D GPIO_NUM_26

#define I2C_FREQ    			400000

#define DAC_1_PIN           	GPIO_NUM_25	 // DAC 1

#define VBAT_SCALED_PIN     	GPIO_NUM_14  // VBAT_SCALED

#define BAT_PGOOD_PIN       	GPIO_NUM_19  // /PG
#define BAT_CHARGE_PIN      	GPIO_NUM_23  // /CHG

/* #define HEART_LED_PIN       	GPIO_NUM_15	 */ // HEARTBEAT
#define TEST_LED_PIN        	GPIO_NUM_18  // LEDTEST
#define TP18                 	GPIO_NUM_16  // TP18 test point

#define IS31_CS					GPIO_NUM_17	 // IS31_CS
#define IS31_SDA        		GPIO_NUM_21  // SDA
#define IS31_SDB        		IS31_CS  	 // SDB
#define IS31_SCL        		GPIO_NUM_22  // SCL

#define V_REF               	1100

#define PWM_BITS            	13
#define PWM_FREQ           	 	5000
#define PWM_TEST_DUTY       	5000
#define PWM_TIMER           	LEDC_TIMER_0
#define PWM_MODE           		LEDC_HIGH_SPEED_MODE
#define PWM_CHANNEL         	LEDC_CHANNEL_0
#define LEDC_TEST_FADE_TIME 	(1000)

//#define ADC_CHAN_VBAT_MEAS		ADC_CHANNEL_6 //this ADC_CHANNEL_6 can't be used since there is no input to sample
#define ADC_CHAN_MUX			ADC_CHANNEL_7

#define RESET_BTN               GPIO_NUM_36

#define TP47                    GPIO_NUM_4
#define VBAT_MEAS_PIN           GPIO_NUM_34
