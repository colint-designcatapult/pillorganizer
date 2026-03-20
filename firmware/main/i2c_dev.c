#include "i2c_dev.h"

#include <stdio.h>
#include "pill_pins.h"
#include "driver/i2c.h"

static const char TAG[] = "I2C_DEV"; 

void i2c_detect(void)
{

    uint8_t address;
    for (int i = 0; i < 128; i += 16) {
        for (int j = 0; j < 16; j++) {
            address = i + j;
            i2c_cmd_handle_t cmd = i2c_cmd_link_create();
            i2c_master_start(cmd);
            i2c_master_write_byte(cmd, (address << 1) | I2C_MASTER_WRITE, ACK_CHECK_EN);
            i2c_master_stop(cmd);
            esp_err_t ret = i2c_master_cmd_begin(I2C_MASTER_PORT, cmd, pdMS_TO_TICKS(1000));
            //ESP_LOGI(TAG, "i2c_master_cmd_begin: %x", ret);
            i2c_cmd_link_delete(cmd);
            
            if (ret == ESP_OK) {
                ESP_LOGI(TAG, "i2c device detected at address: %x", address);            
            } 
        }
    }
}

esp_err_t i2c_master_init(int32_t freq)
{
    i2c_config_t conf = {
        .mode = I2C_MODE_MASTER,
        .sda_io_num = IS31_SDA,
        .scl_io_num = IS31_SCL,
        .sda_pullup_en = GPIO_PULLUP_ENABLE,
        .scl_pullup_en = GPIO_PULLUP_ENABLE,
        .master.clk_speed = freq,
    };

    esp_err_t ret = i2c_driver_install(I2C_MASTER_PORT, conf.mode, 0, 0, 0);
    ret = i2c_param_config(I2C_MASTER_PORT, &conf);
    
    return ret;
}

/*
------------------------------------------------------------------------
| start bit | Slave Addr | ACK | Reg Addr | ACK | Data | ACK | stop bit
------------------------------------------------------------------------
*/
void i2c_write_register(int8_t i2c_addr, uint8_t reg, uint8_t data) {
    i2c_cmd_handle_t cmd = i2c_cmd_link_create();
    // start bit
    esp_err_t ret = i2c_master_start(cmd);

    // send request to device
    ret = i2c_master_write_byte(cmd, (i2c_addr << 1) | I2C_MASTER_WRITE, ACK_CHECK_EN);     

    // send register to modify
    ret = i2c_master_write_byte(cmd, reg, ACK_CHECK_EN);      
    // todo: refactor out errorchecks

    ESP_ERROR_CHECK(ret);           

    // write the data
    ret = i2c_master_write_byte(cmd, data, ACK_CHECK_EN);          

    ESP_ERROR_CHECK(ret);      

    // stop bit
    ret = i2c_master_stop(cmd);

    ESP_ERROR_CHECK(ret);

    ESP_ERROR_CHECK(i2c_master_cmd_begin(I2C_MASTER_PORT, cmd, pdMS_TO_TICKS(CONFIG_I2CDEV_TIMEOUT)));
    i2c_cmd_link_delete(cmd);
}

void i2c_read_register(uint8_t reg, int8_t i2c_addr, uint8_t* data, size_t size) {
    i2c_cmd_handle_t cmd = i2c_cmd_link_create();
    // start bit
    esp_err_t ret = i2c_master_start(cmd);

    // send request to device
    i2c_master_write_byte(cmd, (i2c_addr << 1) | I2C_MASTER_WRITE, true);

    // request register to read
    i2c_master_write_byte(cmd, reg, ACK_CHECK_EN);

    // start bit
    ret = i2c_master_start(cmd);
    
    // send read request
    i2c_master_write_byte(cmd, ( i2c_addr << 1 ) | I2C_MASTER_READ, ACK_CHECK_EN);
    
    // read the register
    i2c_master_read(cmd, data, size, I2C_MASTER_LAST_NACK);
    
    // stop bit
    i2c_master_stop(cmd);
    i2c_master_cmd_begin(I2C_MASTER_PORT, cmd, pdMS_TO_TICKS(CONFIG_I2CDEV_TIMEOUT));
    i2c_cmd_link_delete(cmd);
}

void i2c_write_buffer(int8_t i2c_addr, uint8_t *buffer, uint8_t size) {
    i2c_cmd_handle_t cmd = i2c_cmd_link_create();
    esp_err_t ret = i2c_master_start(cmd);

    // send write request to device
    ret = i2c_master_write_byte(cmd, (i2c_addr << 1) | I2C_MASTER_WRITE, ACK_CHECK_EN);     

    for (int i = 0; i < size; i++)
    {
        // write the data
        ret = i2c_master_write_byte(cmd, buffer[i], ACK_CHECK_EN);  
    }

    ret = i2c_master_stop(cmd);

    i2c_master_cmd_begin(I2C_MASTER_PORT, cmd, pdMS_TO_TICKS(CONFIG_I2CDEV_TIMEOUT));
    i2c_cmd_link_delete(cmd);
}
