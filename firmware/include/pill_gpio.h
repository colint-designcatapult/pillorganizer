#ifndef _PILL_ADC_H_
#define _PILL_ADC_H_

#define CONFIG_ADC_SUPPRESS_DEPRECATE_WARN true

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/queue.h"
#include "driver/ledc.h"
#include "driver/adc.h"
#include "driver/dac.h"
#include <driver/dac_common.h>
#include "esp_adc_cal.h"
#include "esp_log.h"
#include "driver/i2c.h"
#include "config.h"

#if BOARD_REV == 1

#define I2C_FREQ    			400000

#define MUX_PIN_A           	GPIO_NUM_17  // MUX A1       
#define MUX_PIN_B           	GPIO_NUM_18  // MUX B1
#define MUX_PIN_C           	GPIO_NUM_19	 // MUX C1
#define MUX_PIN_D           	GPIO_NUM_23	 // MUX D1 
#define MUX_DIS_PIN         	GPIO_NUM_34  // MUX INHIBIT
#define PHOTO_SAMPLE_PIN    	GPIO_NUM_35  // MUX ADC

#define PWM_PIN             	GPIO_NUM_4	 // PWM
#define DAC_1_PIN           	GPIO_NUM_25	 // DAC 1

#define VBAT_MEAS_PIN       	GPIO_NUM_13  // VBAT_Meas
#define VBAT_SCALED_PIN     	GPIO_NUM_14  // VBAT_SCALED
#define VBUS_ADC_PIN        	GPIO_NUM_16  // VBUS_ADC

#define BAT_PGOOD_PIN       	GPIO_NUM_32  // /PG
#define BAT_CHARGE_PIN      	GPIO_NUM_33  // /CHG

#define HEART_LED_PIN       	GPIO_NUM_26	 // HEARTBEAT
#define TEST_LED_PIN        	GPIO_NUM_27  // LEDTEST

#define IS31_CS					GPIO_NUM_15	 // IS31_CS
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

#define ADC_CHAN_VBAT_MEAS		ADC_CHANNEL_4
#define ADC_CHAN_VBAT_SCALED	ADC_CHANNEL_6
#define ADC_CHAN_MUX			ADC_CHANNEL_7

#elif BOARD_REV == 2

#define I2C_FREQ    			400000

#define MUX_PIN_A           	GPIO_NUM_32  // MUX A1       
#define MUX_PIN_B           	GPIO_NUM_33  // MUX B1
#define MUX_PIN_C           	GPIO_NUM_27	 // MUX C1
#define MUX_PIN_D           	GPIO_NUM_26	 // MUX D1 
#define MUX_DIS_PIN         	GPIO_NUM_13  // MUX INHIBIT
#define PHOTO_SAMPLE_PIN    	GPIO_NUM_35  // MUX ADC

#define PWM_PIN             	GPIO_NUM_4	 // PWM
#define DAC_1_PIN           	GPIO_NUM_25	 // DAC 1

#define VBAT_MEAS_PIN       	GPIO_NUM_34  // VBAT_Meas
#define VBAT_SCALED_PIN     	GPIO_NUM_14  // VBAT_SCALED
#define VBUS_ADC_PIN        	GPIO_NUM_16  // VBUS_ADC

#define BAT_PGOOD_PIN       	GPIO_NUM_19  // /PG
#define BAT_CHARGE_PIN      	GPIO_NUM_23  // /CHG

#define HEART_LED_PIN       	GPIO_NUM_15	 // HEARTBEAT
#define TEST_LED_PIN        	GPIO_NUM_18  // LEDTEST

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

#define ADC_CHAN_VBAT_MEAS		ADC_CHANNEL_6
#define ADC_CHAN_MUX			ADC_CHANNEL_7

#define RESET_BTN               GPIO_NUM_36

#endif

enum {
	VP_PWM = 0,
	VP_ADC,
	VP_UPTIME,
};

typedef enum _special_led_effect {
    LED_EFFECT_NORMAL,
    LED_EFFECT_FLASH_GREEN,
    LED_EFFECT_FLASH_RED,
    LED_EFFECT_FLASH_GREEN_AND_RED
} special_led_effect;

void led_set_effect(special_led_effect effect, int ticks);
void init_gpio(void);
void adc_read_task(void *arg);
void ledc_fade_task(void *arg);
void led_task(void* arg);

#endif // _ADC_H_