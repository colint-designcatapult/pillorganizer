#pragma once
#include "pill.pb.h"
#include <esp_partition.h>
#include <esp_ota_ops.h>

/*
 * Consolidated OTA update protocol
 */

// Uniquely identifies the OTA source for mutual exclusion (more than one method shouldn't attempt OTA at a time)
 typedef enum _ota_source {
    OTA_METHOD_HTTP_GET = 1,
    OTA_METHOD_WEBSERVER,
    OTA_METHOD_PROTOCOMM,
    OTA_METHOD_BLE
 } ota_source;

 typedef struct __attribute__((__packed__)) _ota_update_request {
    /* Counts the number of "update" operations - every update increment this by one */
    uint16_t counter;
    /* total size of the firmware, in bytes */
    uint32_t fwsize;
 } ota_update_request;

 typedef struct _ota_update_response {
    /* total number of bytes written */
    uint32_t bytesWritten;
 } ota_update_response;

/*
 * Serializes the current firmware revision number into a buffer. The buffer is a 32-bit little endian signed integer
 * representing the currently running firmware revision.
 * \param indata input buffer to the request (currently unused)
 * \param insize side of the indata buffer
 * \param outdata buffer where the current version info is written to
 * \param outbufsize the size of the outdata buffer
 * \param number of bytes actually written to outdata
 * \returns ESP_ERR_NO_MEM if the output buffer size isn't large enough
 */
esp_err_t ota_get_current_version(void* indata, size_t insize, void* outdata, size_t outbufsize, size_t* bytesWritten);

/*
 * Performs an OTA update operation. This protocol accepts a byte buffer with the header `ota_update_request` and the
 * remaining bytes a part of the firmware. The firmware update is incrementally read in and accepted until all bytes
 * of the firmware update are received. Note that this function times out if it is in progress and is not complete
 * in one minute.
 * \returns ESP error code
 *      ESP_ERR_NOT_FINISHED if another source is currently using OTA
 *      ESP_ERR_INVALID_ARG insize is not large enough to contain an `ota_update_request` struct
 *      ESP_ERR_INVALID_STATE if the internal counter doesn't match the one provided in the request
 */
esp_err_t ota_update(ota_source source, void* indata, size_t insize, void* outdata, size_t outbufsize, size_t* bytesWritten);




typedef struct _ota_progress_t {
    bool verified;
    size_t bytes_written;
    const esp_partition_t* partition;
    esp_ota_handle_t handle;
} ota_progress_t;

esp_err_t ota_start(ota_progress_t* prog);
esp_err_t ota_upload_part(ota_progress_t* prog, void* data, size_t size);
esp_err_t ota_cancel(ota_progress_t* prog);
esp_err_t ota_finish(ota_progress_t* prog);


/*
 * OLD OTA Code - deprecated and should be removed as soon as new OTA stabilized
 */

void ota_handle_sync(SyncResponse* sync);
void ota_init();
