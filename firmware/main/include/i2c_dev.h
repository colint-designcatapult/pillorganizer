#ifndef _I2C_DEV_H_
#define _I2C_DEV_H_

#include <stdint.h>
#include <stdbool.h>
#include "esp_log.h"
#include "esp_err.h"

#define I2C_MASTER_PORT         0x00
#define ACK_CHECK_EN            0x01            // I2C master will check ack from slave
#define ACK_CHECK_DIS           0x00            // I2C master will not check ack from slave 


#define CONFIG_I2CDEV_TIMEOUT 1000

void i2c_detect(void);
esp_err_t i2c_master_init(int32_t freq);
void i2c_write_register(int8_t i2c_addr, uint8_t reg, uint8_t data);
void i2c_write_buffer(int8_t i2c_addr, uint8_t *buffer, uint8_t size);
void i2c_read_register(uint8_t reg, int8_t i2c_addr, uint8_t* data, size_t size);

#endif  // _I2C_DEV_H_