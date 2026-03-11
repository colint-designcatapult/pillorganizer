#include <stdio.h>
#include <string.h>
#include "sdkconfig.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/semphr.h"

#include "esp_system.h"
#include "esp_spi_flash.h"
#include <esp_mac.h>
#include <esp_wifi.h>
#include <esp_netif.h>
#include "esp_log.h"
#include <esp_ota_ops.h>
#include "util.h"

#include "driver/ledc.h"
#include "driver/adc.h"
#include "driver/gpio.h"
#include "driver/touch_sensor.h"
#include "esp_sleep.h"

#include "pill_gpio.h"
#include "pill_state.h"
#include "nvs_wrapper.h"
#include "rtc_sntp.h"

#include "IS31FL3730.h"
#include "i2c_dev.h"

#include "config.h"
#include "engineering.h"
#include "event.h"
#include "esp_console.h"
#include "wifi.h"
#include "network.h"

#include "iot_telemetry.h"
#include "mqtt_handler.h"
#include "device_provisioning.h"

#include <time.h>

#include "core_mqtt.h"
#include "shadow.h"
#include "core_json.h"
#include "cJSON.h"
#include "esp_crt_bundle.h"


#define TAG "MAIN"

// Control plane base URL from Kconfig
#define CONTROL_PLANE_BASE_URL CONFIG_CONTROL_PLANE_URL
#define HTTP_RESPONSE_BUF_SIZE 8192

const int OTA_START_EVENT = BIT0;

/* For development only */
/*
static void heartbeat_task(void* arg) {
    for(;;) {
        for(int i = 0; i < FIRMWARE_REVISION; i++) {
            gpio_set_level(HEART_LED_PIN, 1);
            vTaskDelay(pdMS_TO_TICKS(100));
            gpio_set_level(HEART_LED_PIN, 0);
            vTaskDelay(pdMS_TO_TICKS(300));
        }

        vTaskDelay(pdMS_TO_TICKS(1000));
        esp_task_wdt_reset();
    }
}
*/

void check_and_print_time() {
    time_t now;
    struct tm timeinfo;
    
    // Get current system time
    time(&now);
    localtime_r(&now, &timeinfo);

    // If year is less than 2020, time isn't set yet
    if (timeinfo.tm_year < (2020 - 1900)) {
        ESP_LOGW("TIME_CHECK", "Time is not yet synchronized. MQTT may fail.");
    } else {
        char strftime_buf[64];
        strftime(strftime_buf, sizeof(strftime_buf), "%c", &timeinfo);
        ESP_LOGI("TIME_CHECK", "Current synchronized time: %s", strftime_buf);
    }
}

static int enter_deep_sleep(int argc, char **argv)
{
    ESP_LOGI(TAG, "Enter Deep Sleep Mode");
    vTaskDelay(pdMS_TO_TICKS(2000));
    
    esp_sleep_enable_ext0_wakeup(RESET_BTN, 0);
    
    //enter deep sleep
    esp_deep_sleep_start();
    return 0;
}


static int read_command(int argc, char **argv)
{
    engineering_print_samples();
    return 0;
}

static int logs_command(int argc, char **argv)
{
    if(argc == 2) {
        if(strcmp(argv[1], "on") == 0) {
            engineering_logs_on();
            return 0;
        } else if(strcmp(argv[1], "off") == 0) {
            engineering_logs_off();
            return 0;
        }
    }
    puts("Usage: logs [on|off]\n");
    return 0;
}

static int ip_command(int argc, char **argv)
{
    engineering_print_ids();
    return 0;
}

static int led_command(int argc, char **argv)
{    
    engineering_red_leds();
    return 0;
}

static int restart_command(int argc, char **argv)
{
    ESP_LOGI(TAG, "Restarting device...");
    mqtt_disconnect();
    vTaskDelay(pdMS_TO_TICKS(1000));
    esp_restart();
    return 0;
}

static int resetiot_command(int argc, char **argv)
{
    ESP_LOGI(TAG, "Clearing AWS IoT provisioning credentials and triggering fleet provisioning on reboot...");
    device_provisioning_clear();
    vTaskDelay(pdMS_TO_TICKS(1000));
    esp_restart();
    return 0;
}

static int resetwifi_command(int argc, char **argv)
{
    ESP_LOGI(TAG, "Clearing WiFi credentials and triggering BLE provisioning on reboot...");
    esp_wifi_restore();
    vTaskDelay(pdMS_TO_TICKS(1000));
    esp_restart();
    return 0;
}

static int exit_command(int argc, char **argv)
{    
    //read firmware version 
    printf("Firmware Version: %d, Built:%s, Date:%s, Board Rev: %d\n",
            FIRMWARE_REVISION, FIRMWARE_BUILD, FIRMWARE_DATE, BOARD_REV);   

    //toggle the leds
    engineering_toggle_leds();

    //read wifi mac
    uint8_t mac[6];
    esp_efuse_mac_get_default(mac);
    printf( "MAC: %02X:%02X:%02X:%02X:%02X:%02X\n", mac[0], mac[1], mac[2], mac[3], mac[4], mac[5] ); 

    //read all ADC channels
    engineering_print_samples();

    return 0;
}

typedef struct {
    char* buf;
    int   len;
    int   max_len;
} http_resp_t;

static esp_err_t http_event_cb(esp_http_client_event_t *evt)
{
    http_resp_t *r = (http_resp_t *)evt->user_data;
    if (evt->event_id == HTTP_EVENT_ON_DATA && r) {
        int to_copy = evt->data_len;
        if (r->len + to_copy >= r->max_len) {
            to_copy = r->max_len - r->len - 1;
        }
        if (to_copy > 0) {
            memcpy(r->buf + r->len, evt->data, to_copy);
            r->len += to_copy;
        }
    }
    return ESP_OK;
}

// POST to control plane to get temporary certificates for Fleet Provisioning.
// Caller must free *cert_pem_out and *key_pem_out on success.
static esp_err_t fetch_temp_certs(const char* serial_number,
                                   const char* c_claim_id,
                                   const char* c_claim_token,
                                   char** cert_pem_out,
                                   char** key_pem_out)
{
    *cert_pem_out = NULL;
    *key_pem_out  = NULL;

    ESP_LOGI(TAG, "fetch_temp_certs: sending claim credentials to control plane");
    ESP_LOGI(TAG, "  Serial: %s", serial_number);
    ESP_LOGI(TAG, "  Claim ID: %s", c_claim_id);
    ESP_LOGI(TAG, "  Claim Token: %s", c_claim_token);

    // Build URL: /device/claim_cert
    char url[256];
    snprintf(url, sizeof(url), CONTROL_PLANE_BASE_URL "/device/claim_cert");
    ESP_LOGI(TAG, "  POST URL: %s", url);

    // Build JSON body
    cJSON *body_json = cJSON_CreateObject();
    cJSON_AddStringToObject(body_json, "serialNumber", serial_number);
    cJSON_AddStringToObject(body_json, "claimId",      c_claim_id);
    cJSON_AddStringToObject(body_json, "claimToken",   c_claim_token);
    char *body_str = cJSON_PrintUnformatted(body_json);
    cJSON_Delete(body_json);
    if (!body_str) return ESP_ERR_NO_MEM;

    // Response accumulator
    char *resp_buf = (char *)calloc(1, HTTP_RESPONSE_BUF_SIZE);
    if (!resp_buf) { free(body_str); return ESP_ERR_NO_MEM; }
    http_resp_t resp = { .buf = resp_buf, .len = 0, .max_len = HTTP_RESPONSE_BUF_SIZE };

    esp_http_client_config_t config = {
        .url               = url,
        .method            = HTTP_METHOD_POST,
        .timeout_ms        = 30000,
        .crt_bundle_attach = esp_crt_bundle_attach,
        .event_handler     = http_event_cb,
        .user_data         = &resp,
    };

    esp_http_client_handle_t client = esp_http_client_init(&config);
    esp_http_client_set_header(client, "Content-Type", "application/json");
    esp_http_client_set_post_field(client, body_str, strlen(body_str));

    ESP_LOGI(TAG, "fetch_temp_certs: performing HTTP POST (body size: %d)...", strlen(body_str));
    esp_err_t err = esp_http_client_perform(client);
    int status = esp_http_client_get_status_code(client);
    esp_http_client_cleanup(client);
    free(body_str);

    if (err != ESP_OK) {
        ESP_LOGE(TAG, "fetch_temp_certs HTTP error: %s", esp_err_to_name(err));
        free(resp_buf);
        return err;
    }
    if (status != 200) {
        ESP_LOGE(TAG, "fetch_temp_certs HTTP status %d, body: %.*s", status, resp.len, resp_buf);
        free(resp_buf);
        return ESP_FAIL;
    }

    resp_buf[resp.len] = '\0';
    ESP_LOGI(TAG, "fetch_temp_certs: HTTP 200 OK, response received (%d bytes)", resp.len);
    ESP_LOGD(TAG, "fetch_temp_certs: response body: %s", resp_buf);

    cJSON *response = cJSON_Parse(resp_buf);
    free(resp_buf);
    if (!response) { ESP_LOGE(TAG, "fetch_temp_certs: invalid JSON response"); return ESP_FAIL; }

    cJSON *cert_pem  = cJSON_GetObjectItem(response, "certificatePem");
    cJSON *priv_key  = cJSON_GetObjectItem(response, "privateKey");

    if (!cJSON_IsString(cert_pem) || !cJSON_IsString(priv_key)) {
        ESP_LOGE(TAG, "fetch_temp_certs: missing certificatePem or privateKey in response");
        cJSON_Delete(response);
        return ESP_FAIL;
    }

    *cert_pem_out = strdup(cert_pem->valuestring);
    *key_pem_out  = strdup(priv_key->valuestring);
    cJSON_Delete(response);

    if (!*cert_pem_out || !*key_pem_out) {
        free(*cert_pem_out); free(*key_pem_out);
        *cert_pem_out = *key_pem_out = NULL;
        ESP_LOGE(TAG, "fetch_temp_certs: failed to allocate memory for cert/key");
        return ESP_ERR_NO_MEM;
    }

    ESP_LOGI(TAG, "fetch_temp_certs: ✓ temp cert (%zu bytes) and key (%zu bytes) received successfully",
             strlen(*cert_pem_out), strlen(*key_pem_out));
    return ESP_OK;
}

static void fleet_provisioning_task(void* arg)
{
    ESP_LOGI(TAG, "Fleet Provisioning Task Started");

    // the lifetime of the task so we can reconnect after any WiFi drop.
    char* device_cert = NULL;
    char* device_key = NULL;
    char* root_ca = NULL;
    char thing_name[128] = {0};

    extern const uint8_t aws_root_ca_start[] asm("_binary_root_ca_pem_start");
    extern const uint8_t aws_root_ca_end[]   asm("_binary_root_ca_pem_end");

    if (device_provisioning_is_provisioned()) {
        // Guard: if certs exist but success flag doesn't, they are orphaned (crash during provisioning)
        if (!device_provisioning_is_complete()) {
            ESP_LOGW(TAG, "✗ Certs found but provisioning not marked complete");
            ESP_LOGW(TAG, "✗ Likely crashed during fleet provisioning - clearing orphaned credentials");
            wifi_reset_claim_credentials();  // Clear any stale claim credentials from the crash
            device_provisioning_clear();
            vTaskDelay(pdMS_TO_TICKS(1000));
            esp_restart();
        }
        
        size_t cert_len = 0, key_len = 0;
        size_t root_ca_len = aws_root_ca_end - aws_root_ca_start;

        root_ca = (char*)malloc(root_ca_len + 1);
        if (root_ca) {
            memcpy(root_ca, aws_root_ca_start, root_ca_len);
            root_ca[root_ca_len] = '\0';
        }

        if (network_load_thing_name(thing_name, sizeof(thing_name)) != ESP_OK ||
            network_load_cert_from_nvs("DEVICE_CERT", &device_cert, &cert_len) != ESP_OK ||
            network_load_cert_from_nvs("DEVICE_KEY", &device_key, &key_len) != ESP_OK) {
            ESP_LOGE(TAG, "Failed to load provisioned credentials from NVS");
            if (root_ca) free(root_ca);
            root_ca = NULL;
        }
    }

    for (;;) {
        // Wait for WiFi
        if (!wifi_is_connected()) {
            vTaskDelay(pdMS_TO_TICKS(1000));
            continue;
        }

        // Already connected to MQTT - nothing to do
        if (mqtt_is_connected()) {
            vTaskDelay(pdMS_TO_TICKS(2000));
            continue;
        }

        if (device_provisioning_is_provisioned()) {
            if (root_ca && device_cert && device_key && thing_name[0] != '\0') {
                ESP_LOGI(TAG, "Connecting as Thing: %s", thing_name);
                esp_err_t ret = mqtt_connect_with_certs(thing_name, root_ca, device_cert, device_key);
                if (ret == ESP_OK) {
                    ESP_LOGI(TAG, "✓ Successfully connected to AWS IoT");
                    mqtt_clear_auth_failure_record();  // Clear failure tracking on success
                } else {
                    ESP_LOGE(TAG, "✗ Failed to connect to AWS IoT");
                    mqtt_record_auth_failure_start();  // Record first failure time
                    
                    // Check if auth failures have persisted for 48 hours
                    if (mqtt_check_auth_failure_timeout(48)) {
                        ESP_LOGE(TAG, "✗ MQTT auth failures for 48+ hours - cert likely revoked");
                        ESP_LOGE(TAG, "✗ Clearing credentials and restarting provisioning...");
                        wifi_reset_claim_credentials();
                        wifi_deinit_provisioning();
                        device_provisioning_clear();  // Clears certs, thing name, and WiFi credentials
                        vTaskDelay(pdMS_TO_TICKS(1000));
                        esp_restart();
                    } else {
                        ESP_LOGD(TAG, "Retrying in 5s (auth failures may be transient)...");
                        vTaskDelay(pdMS_TO_TICKS(5000));
                    }
                }
            } else {
                ESP_LOGE(TAG, "Credentials not loaded, cannot connect");
                vTaskDelay(pdMS_TO_TICKS(5000));
            }
        } else {
            // Not provisioned - check that claim credentials are ready (set by wifi.cpp after BLE exchange)
            if (!wifi_claim_credentials_received()) {
                ESP_LOGD(TAG, "Waiting for claim credentials from app via BLE...");
                vTaskDelay(pdMS_TO_TICKS(1000));
                continue;
            }

            ESP_LOGI(TAG, "✓ Claim credentials received from app via BLE");
            ESP_LOGI(TAG, "Device NOT provisioned - fetching temp certs from control plane...");

            // Get serial number
            uint8_t mac[6];
            size_t  mac_len = 6;
            network_get_serial_number(mac, &mac_len);
            char serial_number[32];
            snprintf(serial_number, sizeof(serial_number), "ESP32-%02X%02X%02X%02X%02X%02X",
                     mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
            ESP_LOGI(TAG, "Device serial: %s", serial_number);

            // Get claim credentials that arrived from app via BLE
            char local_claim_id[128]    = {0};
            char local_claim_token[256] = {0};
            wifi_get_claim_credentials(local_claim_id,    sizeof(local_claim_id),
                                       local_claim_token, sizeof(local_claim_token));
            ESP_LOGD(TAG, "Retrieved claim credentials from BLE session");

            // HTTP POST to control plane -> temporary certificate PEM and private key PEM
            char* temp_cert_pem = NULL;
            char* temp_key_pem  = NULL;
            esp_err_t http_ret = fetch_temp_certs(serial_number, local_claim_id, local_claim_token,
                                                  &temp_cert_pem, &temp_key_pem);

            if (http_ret != ESP_OK) {
                ESP_LOGE(TAG, "✗ Failed to fetch temp certs (error: 0x%X) - clearing WiFi and restarting", http_ret);
                wifi_set_fleet_provisioning_status(FLEET_PROV_STATUS_FAILED);
                vTaskDelay(pdMS_TO_TICKS(5000));  // Give app time to poll failure status
                wifi_reset_claim_credentials();
                wifi_deinit_provisioning();
                esp_wifi_restore();
                esp_restart();
            }

            ESP_LOGI(TAG, "✓ Temp certs received - starting AWS IoT Fleet Provisioning...");
            esp_err_t prov_ret = device_provisioning_start(temp_cert_pem, temp_key_pem, local_claim_id, local_claim_token);

            free(temp_cert_pem);
            free(temp_key_pem);

            if (prov_ret == ESP_OK) {
                ESP_LOGI(TAG, "✓ Fleet Provisioning SUCCEEDED - device now registered with AWS IoT");
                // Mark provisioning as complete - proves we made it through reconnection with permanent certs
                device_provisioning_mark_success();
                ESP_LOGI(TAG, "✓ Notifying app via BLE status endpoint...");
                wifi_set_fleet_provisioning_status(FLEET_PROV_STATUS_SUCCESS);
                // Allow app time to poll the success status before BLE shuts down
                ESP_LOGI(TAG, "Waiting 10s for app to poll success status...");
                vTaskDelay(pdMS_TO_TICKS(10000));
                wifi_deinit_provisioning();
                vTaskDelay(pdMS_TO_TICKS(1000));
                ESP_LOGI(TAG, "✓ PROVISIONING COMPLETE. Rebooting to connect with permanent credentials...");
                esp_restart();
            } else {
                ESP_LOGE(TAG, "✗ Fleet Provisioning FAILED (error: 0x%X) - clearing WiFi and restarting", prov_ret);
                wifi_set_fleet_provisioning_status(FLEET_PROV_STATUS_FAILED);
                vTaskDelay(pdMS_TO_TICKS(5000));  // Give app time to poll failure status
                wifi_reset_claim_credentials();
                wifi_deinit_provisioning();
                device_provisioning_clear();  // Remove any partial cert/key/thing-name written before the failure
                esp_wifi_restore();
                esp_restart();
            }
        }
    }
}



void app_main(void)
{

    const esp_partition_t *running = esp_ota_get_running_partition();
    esp_ota_img_states_t ota_state;
    if (esp_ota_get_state_partition(running, &ota_state) == ESP_OK) {
        if (ota_state == ESP_OTA_IMG_PENDING_VERIFY) {
            // run diagnostic function ...
            bool diagnostic_is_ok = true;
            if (diagnostic_is_ok) {
                ESP_LOGI(TAG, "Diagnostics completed successfully! Continuing execution ...");
                esp_ota_mark_app_valid_cancel_rollback();
            } else {
                ESP_LOGE(TAG, "Diagnostics failed! Start rollback to the previous version ...");
                esp_ota_mark_app_invalid_rollback_and_reboot();
            }
        }
    }


    ESP_LOGI(TAG, "JCTPillOrganizer firmware version %d_%s %s loaded, board rev %d", FIRMWARE_REVISION, FIRMWARE_BUILD, FIRMWARE_DATE, BOARD_REV);

    init_nvs();
    on_init();

    create_task_with_watchdog(&adc_read_task, "ADC Poll Task", 4096, NULL, 1);
    //create_task_with_watchdog(&heartbeat_task, "Heartbeat task", 2048, NULL, 1);

    esp_console_dev_uart_config_t uart_config = ESP_CONSOLE_DEV_UART_CONFIG_DEFAULT();
    esp_console_repl_config_t rc = ESP_CONSOLE_REPL_CONFIG_DEFAULT();
    rc.prompt = "pill>";
    esp_console_repl_t* o;

    esp_console_cmd_t enter_deep_sleep_cmd = {
        .command = "sleep",
        .help = "Read all photoresistor values from the MUX",
        .func = &enter_deep_sleep
    };

    esp_console_cmd_t read_cmd = {
        .command = "r",
        .help = "Read all photoresistor values from the MUX",
        .func = &read_command
    };

    esp_console_cmd_t logs_cmd = {
        .command = "logs",
        .help = "Turns logging on or off.",
        .func = &logs_command,
    };

    esp_console_cmd_t ip_cmd = {
        .command = "ip",
        .help = "Print IP address/serial number",
        .func = &ip_command,
    };

    esp_console_cmd_t led_cmd = {
        .command = "n",
        .help = "toggle red and green led",
        .func = &led_command,
    };

    esp_console_cmd_t exit_cmd = {
        .command = "e",
        .help = "toggle red and green led",
        .func = &exit_command,
    };

    esp_console_cmd_t restart_cmd = {
        .command = "restart",
        .help = "Restart the device",
        .func = &restart_command,
    };

    esp_console_cmd_t resetiot_cmd = {
        .command = "resetiot",
        .help = "Clear stored AWS IoT credentials and re-run fleet provisioning on reboot",
        .func = &resetiot_command,
    };

    esp_console_cmd_t resetwifi_cmd = {
        .command = "resetwifi",
        .help = "Clear WiFi credentials and trigger BLE provisioning on reboot",
        .func = &resetwifi_command,
    };

    esp_console_new_repl_uart(&uart_config, &rc, &o);
    esp_console_cmd_register(&read_cmd);
    esp_console_cmd_register(&logs_cmd);
    esp_console_cmd_register(&ip_cmd);
    esp_console_cmd_register(&led_cmd);
    esp_console_cmd_register(&exit_cmd);
    esp_console_cmd_register(&enter_deep_sleep_cmd);
    esp_console_cmd_register(&restart_cmd);
    esp_console_cmd_register(&resetiot_cmd);
    esp_console_cmd_register(&resetwifi_cmd);


    //engineering_logs_off();
    esp_console_start_repl(o);

    wifi_init();

    // Start fleet provisioning task
    xTaskCreate(&fleet_provisioning_task, "Fleet Provisioning", 8192, NULL, 5, NULL);

    vTaskDelay(pdMS_TO_TICKS(2000));

    check_and_print_time();

    // START THE MQTT CLIENT HERE
    // mqtt_app_start();

    // Start MQTT event monitoring
    // iot_telemetry_start();

    // todo: remove this
    // replace with power management
    while(true) {
        vTaskDelay(pdMS_TO_TICKS(1000));
        esp_task_wdt_reset();
    }
}