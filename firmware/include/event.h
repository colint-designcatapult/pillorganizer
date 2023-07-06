#pragma once
#include <time.h>
#include "pill_types.h"
#include "esp_event.h"


#ifdef __cplusplus
extern "C" {
#endif

#define EVENT_DECLARE_BASE(id) extern char id[]
#define EVENT_DEFINE_BASE(id) char id[] = #id


// System events
EVENT_DECLARE_BASE(SYSTEM_EVENT_BASE);
enum {
    SYSTEM_EVENT_PROVISION_COMPLETE,                 // Provisioning subsystem is completely destructed
    SYSTEM_EVENT_PROVISION_START                     // Equivalent to WIFI_PROV_START, but we control it more
};
typedef struct _SystemEventProvisionComplete {
    bool just_provisioned;
} SystemEventProvisionComplete;

//
// Bin events
//
EVENT_DECLARE_BASE(BIN_EVENT_BASE);
enum {
    BIN_EVENT_BITMASK_CHANGED,
    BIN_EVENT_OPEN_RAW,
    BIN_EVENT_CLOSE_RAW,
    BIN_EVENT,
    BIN_EVENT_SAMPLES
};
typedef struct _BinEventBitmaskChanged {
    uint16_t bitmask;
    uint16_t previous;
} BinEventBitmaskChanged;
typedef struct _BinEventRaw {
    bin_id_t bin;
} BinEventRaw;
typedef struct _BinEvent {
    bin_id_t bin;
    bin_event_type_t event;
    time_t timestamp;
} BinEvent;
typedef struct _BinEventSamples {
    uint32_t samples[16];
    uint32_t vbat_meas;
} BinEventSamples;

// Power events
EVENT_DECLARE_BASE(POWER_EVENT_BASE);
enum {
    POWER_EVENT_STATUS_CHANGE,
    POWER_EVENT_BATTERY_LEVEL_CHANGE,
    POWER_EVENT_PIN
};
typedef struct _PowerStatusChangeEvent {
    bool battery_present:1;
    bool plugged_in:1;
    bool charging:1;
} PowerStatusChangeEvent;
typedef struct _PowerBatteryLevelChangeEvent {
    uint8_t battery_level;
} PowerBatteryLevelChangeEvent;
typedef struct _PowerPinEvent {
    uint8_t pin;
} PowerPinEvent;

// Pill organizer state events
EVENT_DECLARE_BASE(STATE_EVENT_BASE);
enum {
    STATE_EVENT_STATE_UPDATE
};

void on_init();
void on_authentication_success();
void on_time_sync(struct timeval *tv);
void on_bin_open_raw(bin_id_t bin);
void on_bin_close_raw(bin_id_t bin);
void on_bin_event(bin_id_t bin, bin_event_type_t event, time_t timestamp);

SemaphoreHandle_t event_bin_queue_mutex();
QueueHandle_t event_bin_queue();

void event_register_handler_id(esp_event_handler_t handler, void* handler_arg, esp_event_base_t base, int32_t id);
void event_register_handler(esp_event_handler_t handler, void* handler_arg, esp_event_base_t base);
void event_unregister_id(esp_event_handler_t handler, esp_event_base_t base, int32_t id);
void event_unregister(esp_event_handler_t handler, esp_event_base_t base);

esp_err_t event_post(esp_event_base_t event_base, int32_t event_id, const void *event_data, size_t event_data_size, TickType_t ticks_to_wait);
esp_err_t event_isr_post(esp_event_base_t event_base, int32_t event_id, const void *event_data, size_t event_data_size, BaseType_t *task_unblocked);

#ifdef __cplusplus
}
#endif


#ifdef __cplusplus

class EventHandler {
public:
    virtual ~EventHandler();
    virtual void handle(esp_event_base_t base, int32_t id, void* event_data) = 0;
    virtual void set_instance(esp_event_handler_instance_t inst, esp_event_base_t base, int32_t event_id);
    virtual void unregister();
protected:
    esp_event_handler_instance_t _inst = {0};
    esp_event_base_t _event_base = {0};
    int32_t _event_id = 0;
};


void event_register_cpp_handler(EventHandler* handler, esp_event_base_t base);
void event_register_cpp_handler(EventHandler* handler, esp_event_base_t base, int32_t id);

template<char const* BASE, int32_t ID = ESP_EVENT_ANY_ID>
class AutoEventHandler : public EventHandler {
public:
    AutoEventHandler() {
        event_register_cpp_handler(this, BASE, ID);
    }
};


template<typename T>
esp_err_t event_post_cpp(esp_event_base_t event_base, int32_t event_id, const T& val, TickType_t ticks_to_wait) {
    return event_post(event_base, event_id, &val, sizeof(T), ticks_to_wait);
}

template<typename T>
esp_err_t event_isr_post_cpp(esp_event_base_t event_base, int32_t event_id, const T& val, BaseType_t *task_unblocked) {
    return event_isr_post(event_base, event_id, &val, sizeof(T), task_unblocked);
}

#endif
