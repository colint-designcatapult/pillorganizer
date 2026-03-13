#include "power.h"

 void powermgt_boot_pre() {
    esp_sleep_wakeup_cause_t cause = esp_sleep_get_wakeup_cause();

 }

 void powermgt_boot_post() {

 }