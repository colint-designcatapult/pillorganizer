#pragma once
#include <stdint.h>
#include <stdbool.h>
#include "supervisor.h"

#define LED_ALL_DOORS 0x3FFF

typedef enum {
    LED_IDLE,
    LED_BREATHE,
    LED_PROGRESS,
    LED_BLINK,
    LED_FIREWORK,
    LED_DEVICE_STATE
} led_task_t;

typedef union {
    struct {
        uint16_t red;
        uint16_t green;
    } breathe;
    struct {
        uint16_t red;
        uint16_t green;
    } blink;
    struct {
        uint16_t red;
        uint16_t green;
        uint8_t progress; // 0-7
    } progress;
    struct {
        uint16_t red;
        uint16_t green;
        uint8_t center_bin;   // 0-13, the epicenter of the firework
        bool implode;
    } firework;
    struct {
        uint16_t red;
        uint16_t green;
        uint16_t blink_mask;
    } device_state;
    uint64_t raw;
} led_task_param_t;

void ledc_set_task(led_task_t task, led_task_param_t param, uint32_t duration_ms);

// Initialize LED controller
void ledc_init();

void ledc_set_idle_task(led_task_t task, led_task_param_t param);