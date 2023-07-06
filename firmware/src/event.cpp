#include "event.h"
#include "esp_log.h"
#include "wifi.h"

// todo: should probably fix linkage in the future
extern "C" {
    #include "pill_state.h"
    #include "network.h"
    #include "ota.h"
    #include "pill_gpio.h"
    #include "engineering.h"
}


#define TAG "EVENT"

extern "C" {

EVENT_DEFINE_BASE(SYSTEM_EVENT_BASE);
EVENT_DEFINE_BASE(BIN_EVENT_BASE);
EVENT_DEFINE_BASE(POWER_EVENT_BASE);
EVENT_DEFINE_BASE(STATE_EVENT_BASE);

#define STORED_EVENTS_MAX 28

typedef struct {
    uint8_t storage_area[sizeof(BinEvent) * STORED_EVENTS_MAX];
    StaticQueue_t queue;
} bin_event_queue_t;
bin_event_queue_t bin_event_queue_storage = { 0 };
QueueHandle_t bin_event_queue_handle = NULL;
SemaphoreHandle_t bin_event_queue_semph_handle = NULL;

QueueHandle_t event_bin_queue() {
    return bin_event_queue_handle;
}

SemaphoreHandle_t event_bin_queue_mutex() {
    return bin_event_queue_semph_handle;
}

void on_time_sync(struct timeval *tv)
{
    char strftime_buf[64];
    struct tm* timeinfo = gmtime(&tv->tv_sec);

    // Set timezone to Pacific Standard Time and print local time
    strftime(strftime_buf, sizeof(strftime_buf), "%c", timeinfo);
    ESP_LOGI(TAG, "Time synchronized to UTC: %s", strftime_buf);

    state_rebuild_schedule(false);
}


void on_bin_event(bin_id_t bin, bin_event_type_t event, time_t timestamp)
{
    BinEvent be = {
        .bin = bin, .event = event, .timestamp = timestamp
    };

    ESP_LOGI(TAG, "Queing event %d on bin %d time %d", event, bin, (int)timestamp);
    BaseType_t t;
    if((t = xQueueSendToBack(bin_event_queue_handle, &be, 0)) != pdTRUE) {
        ESP_LOGE(TAG, "Failed to add bin event to queue %d", t);

        BinEvent trash;
        xQueueReceive(bin_event_queue_handle, &trash, 0);

        // Try again
        xQueueSendToBack(bin_event_queue_handle, &be, 0);
    }
    event_post_cpp(BIN_EVENT_BASE, BIN_EVENT, be, pdMS_TO_TICKS(100));
}



void on_init()
{
    // Init event loop
    ESP_ERROR_CHECK(esp_event_loop_create_default());

    // Init bin event queue
    bin_event_queue_handle = xQueueCreateStatic(
        STORED_EVENTS_MAX,
        sizeof(BinEvent),
        bin_event_queue_storage.storage_area,
        &bin_event_queue_storage.queue
    );
    bin_event_queue_semph_handle = xSemaphoreCreateMutex();
    xSemaphoreGive(bin_event_queue_semph_handle);

    engineering_init();

    wifi_init_early();
    state_init();
    network_init();
    init_gpio();
    ota_init();
}




void cpp_event_dispatcher(void* event_handler_arg,
                                        esp_event_base_t event_base,
                                        int32_t event_id,
                                        void* event_data) {
    ((EventHandler*)event_handler_arg)->handle(event_base, event_id, event_data);
}


void event_register_handler_id(esp_event_handler_t handler, void* handler_arg, esp_event_base_t base, int32_t id) {
    ESP_ERROR_CHECK(esp_event_handler_register(base, id, handler, handler_arg));
}

void event_register_handler(esp_event_handler_t handler, void* handler_arg, esp_event_base_t base) {
    event_register_handler_id(handler, handler_arg, base, ESP_EVENT_ANY_ID);
}

void event_unregister_id(esp_event_handler_t handler, esp_event_base_t base, int32_t id) {
    esp_event_handler_unregister(base, id, handler);
}

void event_unregister(esp_event_handler_t handler, esp_event_base_t base) {
    event_unregister_id(handler, base, ESP_EVENT_ANY_ID);
}

esp_err_t event_post(esp_event_base_t event_base, int32_t event_id, const void *event_data, size_t event_data_size, TickType_t ticks_to_wait) {
    return esp_event_post(event_base, event_id, event_data, event_data_size, ticks_to_wait);
}

esp_err_t event_isr_post(esp_event_base_t event_base, int32_t event_id, const void *event_data, size_t event_data_size, BaseType_t *task_unblocked) {
    return esp_event_isr_post(event_base, event_id, event_data, event_data_size, task_unblocked);
}


}


void EventHandler::set_instance(esp_event_handler_instance_t inst, esp_event_base_t base, int32_t event_id) {
    this->_inst = inst;
    this->_event_base = base;
    this->_event_id = event_id;
}

void EventHandler::unregister() {
    if(_inst != 0) {
        esp_event_handler_instance_unregister(_event_base, _event_id, _inst);
        _inst = {0};
    }
}

EventHandler::~EventHandler() {
    unregister();
}


void event_register_cpp_handler(EventHandler* handler, esp_event_base_t base, int32_t id) {
    esp_event_handler_instance_t inst;
    ESP_ERROR_CHECK(esp_event_handler_instance_register(base, id, cpp_event_dispatcher, handler, &inst));
    handler->set_instance(inst, base, id);
}


void event_register_cpp_handler(EventHandler* handler, esp_event_base_t base) {
    event_register_cpp_handler(handler, base, ESP_EVENT_ANY_ID);
}

