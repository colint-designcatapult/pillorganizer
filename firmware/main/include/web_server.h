#ifndef WEB_SERVER_H
#define WEB_SERVER_H

#include <esp_err.h>

/**
 * Initialize the HTTP web server
 * This should be called after WiFi is connected
 */
esp_err_t web_server_init(void);

/**
 * Stop the web server
 */
esp_err_t web_server_stop(void);

#endif // WEB_SERVER_H
