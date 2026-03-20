#include <stdio.h>
#include "esp_log.h"
#include "esp_err.h"
#include "i2c_dev.h"
#include "driver/gpio.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include <IS31FL3730.h>

uint8_t _buf_matrix_1[NUM_COLS];
uint8_t _buf_matrix_2[NUM_COLS];


static const char TAG[] = "IS31FL3730"; 

void IS31FL3730_shutdown(void)
{
    i2c_write_register(ISSI_ADDR, ISSI_REG_CONFIG, SHUTDOWN_EN);
}

void IS31FL3730_init() {
    i2c_detect();

    i2c_write_register(ISSI_ADDR, ISSI_REG_RESET, 0x00);
    //ESP_LOGI(TAG, "ISSI_REG_RESET");
    vTaskDelay(10 / portTICK_PERIOD_MS);
    i2c_write_register(ISSI_ADDR, ISSI_REG_CONFIG, ((MODE_MATRIX_1_2 | MATRIX_5_11) & ~AUDIO_EN));
    //ESP_LOGI(TAG, "ISSI_REG_CONFIG");
    i2c_write_register(ISSI_ADDR, ISSI_REG_BRIGHT, 174);
    //ESP_LOGI(TAG, "ISSI_REG_BRIGHT");
    i2c_write_register(ISSI_ADDR, ISSI_REG_LE, CURR_SET_10);
    vTaskDelay(10 / portTICK_PERIOD_MS);
    
    uint8_t out;
    i2c_read_register(ISSI_ADDR, ISSI_REG_LE, &out, sizeof(out));
    ESP_LOGI(TAG, "Current set to 10mA - 0x09 1001, read back at 0x%x", out);

    //ESP_LOGI(TAG, "ISSI_REG_LE");
    IS31FL3730_clear_LED_states();
}

void IS31FL3730_update_LED_states(void) {
  uint8_t *buffer;
  uint8_t led_state_buffer[22];
  buffer = led_state_buffer;

  // select the first column register in matrix 1; add the data of all the 
  // row registers; the IS31FL3730 will auto increment the column registers
  *buffer = ISSI_REG_MATRIX1;
  buffer++;
  
  for (uint8_t i = 0; i < NUM_COLS; i++) {
    // add row bit mask data to buffer
    *buffer = _buf_matrix_1[i];
    buffer++;
  }

  // select the first column register in matrix 2; add the data of all the 
  // row registers; the IS31FL3730 will auto increment the column registers
  *buffer = ISSI_REG_MATRIX2;
  buffer++;

  for (uint8_t i = 0; i < NUM_COLS; i++) {
    // add row bit mask data to buffer
    *buffer = _buf_matrix_2[i];
    buffer++;

    //ESP_LOGI(TAG, "i: %x j: %x reg: %x data: %x", i, j, led_state_buffer[i], led_state_buffer[i]);
  }

  i2c_write_buffer(ISSI_ADDR, led_state_buffer, 22);
  i2c_write_register(ISSI_ADDR, ISSI_REG_UPDATE, 0x00);
}
 
void IS31FL3730_clear_LED_states(void) {
  for (uint8_t i = 0; i < NUM_COLS; i++) {
      _buf_matrix_1[i] = 0;
      _buf_matrix_2[i] = 0;
  }
  IS31FL3730_update_LED_states();
}
 
void IS31FL3730_set_light_effect(uint8_t val) {
  i2c_write_register(ISSI_ADDR, ISSI_REG_LE, val);
}
 
void IS31FL3730_set_brightness(uint8_t val) {
  val = (val > 127) ? 127 : val;
  i2c_write_register(ISSI_ADDR, ISSI_REG_BRIGHT, val);
}
 
void IS31FL3730_set_pixel(uint8_t matrix, uint8_t x, uint8_t y, uint8_t state) {
  if (matrix == 0) {
    if (state) { 
      _buf_matrix_1[y] |= (1 << x);
    } else {
      _buf_matrix_1[y] &= ~(1 << x);
    } 

  }else if (matrix == 1) {
    if (state) {
      _buf_matrix_2[x] |= (1 << y);
    } else {
      _buf_matrix_2[x] &= ~(1 << y);
    } 
  }
}