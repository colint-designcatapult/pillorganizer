#pragma once
#include <stdint.h>

typedef enum {
    LED_IDLE,
    LED_BREATHE,
    LED_PROGRESS,
    LED_BLINK_AND_ROLLBACK
} led_task_t;

typedef union {
    struct {
        uint8_t red;
        uint8_t green;
    } breathe;
    struct {
        uint8_t red;
        uint8_t green;
        uint8_t progress; // 0-7
    } progress;
    struct {
        uint8_t red;
        uint8_t green;
    } blink_and_rollback;
    uint64_t raw;
} led_task_param_t;

void ledc_set_task(led_task_t task, led_task_param_t param);

// Initialize LED controller
void ledc_init();