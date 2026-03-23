#pragma once
#include <stdint.h>

#define LED_ALL_DOORS 0x3FFF

typedef enum {
    LED_IDLE,
    LED_BREATHE,
    LED_PROGRESS,
    LED_BLINK
} led_task_t;

typedef union {
    struct {
        uint16_t red;
        uint16_t green;
    } breathe;
    struct {
        uint16_t red;
        uint16_t green;
        uint8_t progress; // 0-7
    } progress;
    struct {
        uint16_t red;
        uint16_t green;
    } blink;
    uint64_t raw;
} led_task_param_t;

void ledc_set_task(led_task_t task, led_task_param_t param, uint32_t duration_ms);

// Initialize LED controller
void ledc_init();