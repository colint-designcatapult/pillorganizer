#include "util.h"

TaskHandle_t create_task_with_watchdog(TaskFunction_t pvTaskCode,
                            const char * const pcName, 
                            const uint32_t usStackDepth,
                            void * const pvParameters,
                            UBaseType_t uxPriority) {
    TaskHandle_t handle;
    if(xTaskCreate(pvTaskCode, pcName, usStackDepth, pvParameters, uxPriority, &handle) == pdPASS) {
        ESP_LOGI("UTIL", "Task %s created with handle", pcName);
        esp_task_wdt_add(handle);
        return handle;
    }
    return NULL;
}