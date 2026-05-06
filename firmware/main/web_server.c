#include "web_server.h"
#include <esp_http_server.h>
#include <esp_log.h>
#include "nvs_wrapper.h"
#include <nvs.h>
#include <nvs_flash.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <esp_system.h>
#include "supervisor.h"
#include "supervisor_operation.h"

#define TAG "WEB_SERVER"

#if CONFIG_FIRMWARE_ENGINEERING

// Declare the external embedded HTML file
extern const uint8_t engineering_html_start[] asm("_binary_engineering_html_start");
extern const uint8_t engineering_html_end[] asm("_binary_engineering_html_end");

static httpd_handle_t server = NULL;

/**
 * Handler for GET /
 * Serves the engineering.html page
 */
static esp_err_t root_handler(httpd_req_t *req)
{
    ESP_LOGI(TAG, "Serving root request");

    // Calculate the size of the HTML file
    size_t html_size = engineering_html_end - engineering_html_start;
    
    // Set the content type to HTML
    httpd_resp_set_type(req, "text/html");
    
    // Send the entire HTML file
    httpd_resp_send(req, (const char *)engineering_html_start, html_size);
    
    return ESP_OK;
}

/**
 * Handler for GET /version
 * Returns the firmware version
 */
static esp_err_t version_handler(httpd_req_t *req)
{
    ESP_LOGI(TAG, "Serving version request");
    
    const char resp[] = "1.0.0";
    httpd_resp_set_type(req, "text/plain");
    httpd_resp_send(req, resp, -1);
    
    return ESP_OK;
}

/**
 * Handler for POST /reboot
 * Reboots the device
 */
static esp_err_t reboot_handler(httpd_req_t *req)
{
    ESP_LOGI(TAG, "Reboot requested via web interface");
    
    const char resp[] = "Device rebooting...";
    httpd_resp_set_type(req, "text/plain");
    httpd_resp_send(req, resp, -1);
    
    // Reboot the device
    vTaskDelay(pdMS_TO_TICKS(500));
    esp_restart();
    
    return ESP_OK;
}

/**
 * Handler for POST /reset
 * Factory reset: clears WiFi and device identity (requires reprovision)
 */
static esp_err_t reset_handler(httpd_req_t *req)
{
    ESP_LOGI(TAG, "Factory reset requested via web interface");
    
    // Clear all NVS (full factory reset)
    nvs_flash_erase();
    nvs_flash_init();
    
    const char resp[] = "Factory reset complete. Device will reboot and require reprovision.";
    httpd_resp_set_type(req, "text/plain");
    httpd_resp_send(req, resp, -1);
    
    // Reboot the device
    vTaskDelay(pdMS_TO_TICKS(1000));
    esp_restart();
    
    return ESP_OK;
}

/**
 * Handler for POST /reset-pending-bins
 * Resets future-dated bins to PENDING state while preserving past dose history
 * Useful for re-testing state transitions after changing schedules
 */
static esp_err_t reset_pending_bins_handler(httpd_req_t *req)
{
    ESP_LOGI(TAG, "Reset pending bins requested via web interface");
    
    // Submit event to supervisor thread - thread-safe and prevents race conditions
    supervisor_submit_event(EVENT_RESET_PENDING_BINS);
    
    const char resp[] = "Pending bins reset submitted. Processing on supervisor thread...";
    httpd_resp_set_type(req, "text/plain");
    httpd_resp_send(req, resp, -1);
    
    return ESP_OK;
}

static esp_err_t trigger_reload_handler(httpd_req_t *req)
{
    ESP_LOGI(TAG, "Manual reload trigger requested via web interface");
    
    esp_err_t err = supervisor_operation_trigger_reload();
    
    if (err == ESP_OK) {
        const char resp[] = "Reload triggered successfully. Open a bin to start refilling.";
        httpd_resp_set_type(req, "text/plain");
        httpd_resp_send(req, resp, -1);
    } else {
        const char resp[] = "Failed to trigger reload. Reload may already be in progress.";
        httpd_resp_set_type(req, "text/plain");
        httpd_resp_send(req, resp, -1);
    }
    
    return ESP_OK;
}

/**
 * Initialize the HTTP web server
 */
esp_err_t web_server_init(void)
{
    if (server != NULL) {
        ESP_LOGW(TAG, "Web server already initialized");
        return ESP_ERR_INVALID_STATE;
    }
    
    // Configure and create the httpd server
    httpd_config_t config = HTTPD_DEFAULT_CONFIG();
    config.max_uri_handlers = 6;  // root, version, reboot, reset, trigger-reload, reset-pending-bins
    
    ESP_LOGI(TAG, "Starting web server on port %d", config.server_port);
    
    if (httpd_start(&server, &config) != ESP_OK) {
        ESP_LOGE(TAG, "Failed to start web server");
        return ESP_FAIL;
    }
    
    // Register URI handlers
    httpd_uri_t root = {
        .uri      = "/",
        .method   = HTTP_GET,
        .handler  = root_handler,
        .user_ctx = NULL,
    };
    httpd_register_uri_handler(server, &root);
    
    httpd_uri_t version = {
        .uri      = "/version",
        .method   = HTTP_GET,
        .handler  = version_handler,
        .user_ctx = NULL,
    };
    httpd_register_uri_handler(server, &version);
    
    httpd_uri_t reboot = {
        .uri      = "/reboot",
        .method   = HTTP_POST,
        .handler  = reboot_handler,
        .user_ctx = NULL,
    };
    httpd_register_uri_handler(server, &reboot);
    
    httpd_uri_t reset = {
        .uri      = "/reset",
        .method   = HTTP_POST,
        .handler  = reset_handler,
        .user_ctx = NULL,
    };
    httpd_register_uri_handler(server, &reset);
    
    httpd_uri_t trigger_reload = {
        .uri      = "/trigger-reload",
        .method   = HTTP_POST,
        .handler  = trigger_reload_handler,
        .user_ctx = NULL,
    };
    httpd_register_uri_handler(server, &trigger_reload);

    httpd_uri_t reset_pending_bins = {
        .uri      = "/reset-pending-bins",
        .method   = HTTP_POST,
        .handler  = reset_pending_bins_handler,
        .user_ctx = NULL,
    };
    httpd_register_uri_handler(server, &reset_pending_bins);
    
    ESP_LOGI(TAG, "Web server initialized successfully");
    return ESP_OK;
}

/**
 * Stop the web server
 */
esp_err_t web_server_stop(void)
{
    if (server == NULL) {
        ESP_LOGW(TAG, "Web server not running");
        return ESP_ERR_INVALID_STATE;
    }
    
    httpd_stop(server);
    server = NULL;
    ESP_LOGI(TAG, "Web server stopped");
    
    return ESP_OK;
}

#else // CONFIG_FIRMWARE_ENGINEERING

/**
 * Stub implementations when engineering is disabled
 */
esp_err_t web_server_init(void)
{
    // Engineering disabled - no web server needed
    return ESP_OK;
}

esp_err_t web_server_stop(void)
{
    // Engineering disabled - nothing to stop
    return ESP_OK;
}

#endif // CONFIG_FIRMWARE_ENGINEERING
