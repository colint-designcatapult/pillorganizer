#pragma once
#include <esp_task.h>
#include <esp_task_wdt.h>
#include <esp_log.h>    


#ifdef __cplusplus
extern "C" {
#endif

TaskHandle_t create_task_with_watchdog(TaskFunction_t pvTaskCode,
                            const char * const pcName, 
                            const uint32_t usStackDepth,
                            void * const pvParameters,
                            UBaseType_t uxPriority);
                            
#ifdef __cplusplus
}
#endif
