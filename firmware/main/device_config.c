#include "device_config.h"
#include <esp_mac.h>
#include <esp_log.h>
#include <string.h>
#include <sys/param.h>
#include <nvs.h>
#include <cJSON.h>
#include "sdkconfig.h"

#if CONFIG_EMULATOR_MODE
#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include "esp_vfs_fat.h"
#include "driver/sdmmc_host.h"
#include "sdmmc_cmd.h"
#endif

#define TAG "devcfg"

static uint8_t s_mac[6];

#if CONFIG_EMULATOR_MODE
/* In emulator mode the serial number is sourced from sdkconfig rather than
 * the eFuse MAC address (which is all-zeros inside QEMU). */
static char s_emu_serial[SERIAL_NUMBER_STR_SIZE];
#endif

#define NVS_DEV_STATE_NS "dev_state"
#define NVS_DEV_SCHEDULE_NS "dev_sched"

/* Two-tier persistence: RTC memory cache (fast) + NVS (durable, explicit flush only) */
RTC_DATA_ATTR uint32_t                  g_rtc_state_magic  = 0;
RTC_DATA_ATTR device_persistent_state_t g_rtc_device_state = {0};

/* ------------------------------------------------------------------ */
/*  Emulator: SD card VFS identity storage                            */
/* ------------------------------------------------------------------ */

#if CONFIG_EMULATOR_MODE

#define SDCARD_MOUNT_POINT    "/sdcard"
#define SDCARD_CERT_PATH      SDCARD_MOUNT_POINT "/cert.pem"
#define SDCARD_KEY_PATH       SDCARD_MOUNT_POINT "/key.pem"
#define SDCARD_THING_PATH     SDCARD_MOUNT_POINT "/thing.txt"

/* Set to true when the SD card was successfully mounted at init time. */
static bool s_sdcard_mounted = false;
static sdmmc_card_t *s_sdcard = NULL;

/* Returns true if the file exists and is non-empty. */
static bool emu_file_exists(const char *path)
{
    FILE *f = fopen(path, "r");
    if (!f) return false;
    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fclose(f);
    return size > 0;
}

/* Reads entire file into a heap-allocated buffer. Caller must free(). */
static char *emu_read_file(const char *path)
{
    FILE *f = fopen(path, "r");
    if (!f) return NULL;

    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fseek(f, 0, SEEK_SET);

    if (size <= 0) { fclose(f); return NULL; }

    char *buf = malloc(size + 1);
    if (!buf) { fclose(f); return NULL; }

    size_t n = fread(buf, 1, size, f);
    fclose(f);
    buf[n] = '\0';
    return buf;
}

/* Writes a null-terminated string to a file, replacing any existing content. */
static esp_err_t emu_write_file(const char *path, const char *content)
{
    FILE *f = fopen(path, "w");
    if (!f) {
        ESP_LOGE(TAG, "Cannot open %s for writing (errno %d)", path, errno);
        return ESP_FAIL;
    }
    size_t len = strlen(content);
    size_t written = fwrite(content, 1, len, f);
    fclose(f);
    return (written == len) ? ESP_OK : ESP_FAIL;
}

/* Removes a file; falls back to truncation if unlink is unsupported. */
static void emu_delete_file(const char *path)
{
    if (unlink(path) == 0) return;
    FILE *f = fopen(path, "w");
    if (f) fclose(f);
}

#endif /* CONFIG_EMULATOR_MODE */

void devcfg_init()
{
#if CONFIG_EMULATOR_MODE
    /* Optimistically try to mount a virtual SD card.  If no card is attached
     * (e.g. the emulator was started without one), silently fall back to the
     * standard NVS-backed identity storage. */
    sdmmc_host_t host = SDMMC_HOST_DEFAULT();
    sdmmc_slot_config_t slot_config = SDMMC_SLOT_CONFIG_DEFAULT();
    esp_vfs_fat_sdmmc_mount_config_t mount_config = {
        .format_if_mount_failed = false,
        .max_files = 4,
        .allocation_unit_size = 0,
    };
    esp_err_t sd_err = esp_vfs_fat_sdmmc_mount(SDCARD_MOUNT_POINT, &host,
                                                &slot_config, &mount_config,
                                                &s_sdcard);
    if (sd_err == ESP_OK) {
        s_sdcard_mounted = true;
        ESP_LOGI(TAG, "SD card mounted at " SDCARD_MOUNT_POINT " — using SD identity storage");
    } else {
        s_sdcard_mounted = false;
        ESP_LOGI(TAG, "No SD card detected (err %s) — using NVS identity storage",
                 esp_err_to_name(sd_err));
    }

    /* Copy the Kconfig-provided serial number, truncate to fit. */
    strncpy(s_emu_serial, CONFIG_EMULATOR_SERIAL_NUMBER, SERIAL_NUMBER_STR_SIZE - 1);
    s_emu_serial[SERIAL_NUMBER_STR_SIZE - 1] = '\0';
    ESP_LOGI(TAG, "Emulator mode: using configured serial number");
#else
    // Load MAC address (for serial number)
    esp_efuse_mac_get_default(s_mac);
#endif

    char sn[SERIAL_NUMBER_STR_SIZE];
    devcfg_get_serial_number_str(sn, sizeof(sn));

    bool perm_id = devcfg_has_permanent_identity();

    char thing[128];
    bool thing_set = devcfg_get_thing_name_str(thing, sizeof(thing));

    ESP_LOGI(TAG, "Device configuration initialized");
    ESP_LOGI(TAG, "Serial number:          %s", sn);
    ESP_LOGI(TAG, "Thing name:             %s", thing_set ? thing : "(not set)");
    ESP_LOGI(TAG, "Permanent identity      %s", perm_id ? "yes" : "no");
    
}

void devcfg_get_serial_number(uint8_t sn[SERIAL_NUMBER_SIZE], size_t size)
{
#if CONFIG_EMULATOR_MODE
    /* Provide a synthetic MAC-like blob derived from the emulator serial. */
    memset(sn, 0, MIN(SERIAL_NUMBER_SIZE, size));
    size_t copy_len = MIN(SERIAL_NUMBER_SIZE, strlen(s_emu_serial));
    memcpy(sn, s_emu_serial, MIN(copy_len, size));
#else
    memcpy(sn, s_mac, MIN(SERIAL_NUMBER_SIZE, size));
#endif
}

void devcfg_get_serial_number_str(char serial_number[SERIAL_NUMBER_STR_SIZE], size_t size)
{
#if CONFIG_EMULATOR_MODE
    strncpy(serial_number, s_emu_serial, size - 1);
    serial_number[size - 1] = '\0';
#else
    snprintf(serial_number, size, "%02x%02x%02x%02x%02x%02x", s_mac[0], s_mac[1], s_mac[2], s_mac[3], s_mac[4], s_mac[5]);
    serial_number[SERIAL_NUMBER_STR_SIZE - 1] = '\0';
#endif
}

// Checks if all three required identity components exist
bool devcfg_has_permanent_identity(void)
{
#if CONFIG_EMULATOR_MODE
    if (s_sdcard_mounted) {
        return emu_file_exists(SDCARD_CERT_PATH) &&
               emu_file_exists(SDCARD_KEY_PATH)  &&
               emu_file_exists(SDCARD_THING_PATH);
    }
#endif
    nvs_handle_t h;
    if (nvs_open("storage", NVS_READONLY, &h) != ESP_OK) {
        return false;
    }

    size_t len;
    bool has_identity = true;

    // Passing NULL to nvs_get_str queries the length. If it returns ESP_OK, the key exists.
    if (nvs_get_str(h, "DEVICE_CERT", NULL, &len) != ESP_OK) has_identity = false;
    if (nvs_get_str(h, "DEVICE_KEY", NULL, &len) != ESP_OK)  has_identity = false;
    if (nvs_get_str(h, "THING_NAME", NULL, &len) != ESP_OK)  has_identity = false;

    nvs_close(h);
    return has_identity;
}

// Retrieves the thing name into the provided buffer
bool devcfg_get_thing_name_str(char* thing_name_out, size_t size)
{
    if (!thing_name_out || size == 0) return false;

#if CONFIG_EMULATOR_MODE
    if (s_sdcard_mounted) {
        FILE *f = fopen(SDCARD_THING_PATH, "r");
        if (!f) return false;
        size_t n = fread(thing_name_out, 1, size - 1, f);
        fclose(f);
        thing_name_out[n] = '\0';
        if (n > 0 && thing_name_out[n - 1] == '\n') thing_name_out[--n] = '\0';
        return n > 0;
    }
#endif
    nvs_handle_t h;
    if (nvs_open("storage", NVS_READONLY, &h) != ESP_OK) {
        return false;
    }

    esp_err_t err = nvs_get_str(h, "THING_NAME", thing_name_out, &size);
    nvs_close(h);

    return (err == ESP_OK);
}

// Saves the thing name
esp_err_t devcfg_set_thing_name(const char* thing_name)
{
    if (!thing_name) return ESP_ERR_INVALID_ARG;

#if CONFIG_EMULATOR_MODE
    if (s_sdcard_mounted) {
        return emu_write_file(SDCARD_THING_PATH, thing_name);
    }
#endif
    nvs_handle_t h;
    esp_err_t err = nvs_open("storage", NVS_READWRITE, &h);
    if (err != ESP_OK) return err;

    err = nvs_set_str(h, "THING_NAME", thing_name);
    if (err == ESP_OK) {
        err = nvs_commit(h);
    }
    
    nvs_close(h);
    return err;
}

// Saves both the certificate and private key
esp_err_t devcfg_set_permanent_cert(const char* cert, const char* privkey)
{
    if (!cert || !privkey) return ESP_ERR_INVALID_ARG;

#if CONFIG_EMULATOR_MODE
    if (s_sdcard_mounted) {
        esp_err_t err = emu_write_file(SDCARD_CERT_PATH, cert);
        if (err == ESP_OK) err = emu_write_file(SDCARD_KEY_PATH, privkey);
        return err;
    }
#endif
    nvs_handle_t h;
    esp_err_t err = nvs_open("storage", NVS_READWRITE, &h);
    if (err != ESP_OK) return err;

    err = nvs_set_str(h, "DEVICE_CERT", cert);
    if (err == ESP_OK) {
        err = nvs_set_str(h, "DEVICE_KEY", privkey);
    }
    
    if (err == ESP_OK) {
        err = nvs_commit(h);
    }
    
    nvs_close(h);
    return err;
}

// Clears all identity credentials
void devcfg_reset_identity(void)
{
#if CONFIG_EMULATOR_MODE
    if (s_sdcard_mounted) {
        emu_delete_file(SDCARD_CERT_PATH);
        emu_delete_file(SDCARD_KEY_PATH);
        emu_delete_file(SDCARD_THING_PATH);
        return;
    }
#endif
    nvs_handle_t h;
    if (nvs_open("storage", NVS_READWRITE, &h) == ESP_OK) {
        nvs_erase_key(h, "DEVICE_CERT");
        nvs_erase_key(h, "DEVICE_KEY");
        nvs_erase_key(h, "THING_NAME");
        nvs_commit(h);
        nvs_close(h);
    }
}

void devcfg_reset_state()
{
    g_rtc_state_magic = 0; // Invalidate RTC cache
    g_rtc_device_state = (device_persistent_state_t){0}; // Clear RTC cache

    // Erase persisted state from NVS so it isn't reloaded after reboot
    nvs_handle_t h;
    if (nvs_open(NVS_DEV_STATE_NS, NVS_READWRITE, &h) == ESP_OK) {
        nvs_erase_all(h);
        nvs_commit(h);
        nvs_close(h);
    }
}

// Retrieves the permanent certificate.
// NOTE: The caller must free() the returned pointer when done.
const char* devcfg_get_permanent_cert(void)
{
#if CONFIG_EMULATOR_MODE
    if (s_sdcard_mounted) {
        return emu_read_file(SDCARD_CERT_PATH);
    }
#endif
    nvs_handle_t h;
    if (nvs_open("storage", NVS_READONLY, &h) != ESP_OK) {
        return NULL;
    }

    size_t len = 0;
    // Call with NULL first to get the required string length (including null terminator)
    if (nvs_get_str(h, "DEVICE_CERT", NULL, &len) != ESP_OK) {
        nvs_close(h);
        return NULL;
    }

    char* cert = (char*)malloc(len);
    if (!cert) {
        nvs_close(h);
        return NULL;
    }

    if (nvs_get_str(h, "DEVICE_CERT", cert, &len) != ESP_OK) {
        free(cert);
        cert = NULL;
    }

    nvs_close(h);
    return cert;
}

// Retrieves the permanent private key.
// NOTE: The caller must free() the returned pointer when done.
const char* devcfg_get_permanent_key(void)
{
#if CONFIG_EMULATOR_MODE
    if (s_sdcard_mounted) {
        return emu_read_file(SDCARD_KEY_PATH);
    }
#endif
    nvs_handle_t h;
    if (nvs_open("storage", NVS_READONLY, &h) != ESP_OK) {
        return NULL;
    }

    size_t len = 0;
    // Call with NULL first to get the required string length (including null terminator)
    if (nvs_get_str(h, "DEVICE_KEY", NULL, &len) != ESP_OK) {
        nvs_close(h);
        return NULL;
    }

    char* key = (char*)malloc(len);
    if (!key) {
        nvs_close(h);
        return NULL;
    }

    if (nvs_get_str(h, "DEVICE_KEY", key, &len) != ESP_OK) {
        free(key);
        key = NULL;
    }

    nvs_close(h);
    return key;
}


// New macro: logs the error and jumps to the cleanup block to ensure nvs_close is called
#define CHECK_GOTO(x) do { \
    err = (x); \
    if (err != ESP_OK) { \
        ESP_LOGE(TAG, "NVS Error %s at line %d", esp_err_to_name(err), __LINE__); \
        goto cleanup; \
    } \
} while(0)

/**
 * @brief Saves a device schedule to NVS atomically.
 */
esp_err_t devcfg_set_device_schedule(const device_schedule_t* sched) {
    if (!sched) return ESP_ERR_INVALID_ARG;

    nvs_handle_t handle;
    esp_err_t err = nvs_open(NVS_DEV_SCHEDULE_NS, NVS_READWRITE, &handle);
    if (err != ESP_OK) return err;

    // 1. Transaction Start (Invalidate)
    CHECK_GOTO(nvs_set_u8(handle, "sch_valid", 0));
    CHECK_GOTO(nvs_commit(handle));

    // 2. Write Fields
    CHECK_GOTO(nvs_set_str(handle, "sch_id", sched->id));
    CHECK_GOTO(nvs_set_u8(handle, "sch_type", (uint8_t)sched->type));
    CHECK_GOTO(nvs_set_u8(handle, "sch_eff", (uint8_t)sched->take_effect));

    // Persist timezone strings (may be empty on first write)
    CHECK_GOTO(nvs_set_str(handle, "sch_tz_iana", sched->timezone_iana));
    CHECK_GOTO(nvs_set_str(handle, "sch_tz_posix", sched->timezone_posix));

    if (sched->type == SCHED_SIMPLE) {
        uint8_t bin_count = sched->schedule.simple_schedule.bin_count;
        if (bin_count > 14) bin_count = 14; 
        
        CHECK_GOTO(nvs_set_u8(handle, "sch_bcnt", bin_count));

        char key[16];
        for (uint8_t i = 0; i < bin_count; i++) {
            snprintf(key, sizeof(key), "sch_b_%d", i);
            CHECK_GOTO(nvs_set_blob(handle, key, 
                                   &sched->schedule.simple_schedule.bins[i], 
                                   sizeof(device_bin_schedule_t)));
        }
    }
    CHECK_GOTO(nvs_commit(handle));

    // 3. Transaction Commit (Validate)
    CHECK_GOTO(nvs_set_u8(handle, "sch_valid", 1));
    CHECK_GOTO(nvs_commit(handle));

    ESP_LOGI(TAG, "Schedule saved successfully.");

cleanup:
    // This guarantees the handle is always closed, success or fail
    nvs_close(handle);
    return err;
}

/**
 * @brief Loads a device schedule from NVS. 
 */
esp_err_t devcfg_get_device_schedule(device_schedule_t* sched) {
    if (!sched) return ESP_ERR_INVALID_ARG;

    // Zero out struct so missing fields default to 0/null
    memset(sched, 0, sizeof(device_schedule_t));

    nvs_handle_t handle;
    esp_err_t err = nvs_open(NVS_DEV_SCHEDULE_NS, NVS_READONLY, &handle);
    if (err != ESP_OK) {
        return (err == ESP_ERR_NVS_NOT_FOUND) ? ESP_OK : err;
    }

    // 1. Transaction Check (STRICT)
    uint8_t valid = 0;
    err = nvs_get_u8(handle, "sch_valid", &valid);
    if (err != ESP_OK || valid == 0) {
        ESP_LOGE(TAG, "Schedule corrupted or incomplete transaction.");
        err = ESP_ERR_NVS_NOT_FOUND;
        goto cleanup;
    }

    // 2. Load Fields Gracefully
    size_t id_len = SCHEDULE_ID_SIZE;
    err = nvs_get_str(handle, "sch_id", sched->id, &id_len);
    if (err != ESP_OK && err != ESP_ERR_NVS_NOT_FOUND) goto cleanup;

    uint8_t type_val = 0;
    if (nvs_get_u8(handle, "sch_type", &type_val) == ESP_OK) {
        sched->type = (device_schedule_type_t)type_val;
    }

    uint8_t eff_val = 0;
    if (nvs_get_u8(handle, "sch_eff", &eff_val) == ESP_OK) {
        sched->take_effect = (device_schedule_take_effect_t)eff_val;
    }

    // Load timezone strings (ignore if not yet stored)
    size_t iana_len = TIMEZONE_IANA_SIZE;
    if (nvs_get_str(handle, "sch_tz_iana", sched->timezone_iana, &iana_len) == ESP_OK) {
        sched->timezone_iana[TIMEZONE_IANA_SIZE - 1] = '\0';
    }

    size_t posix_len = TIMEZONE_POSIX_SIZE;
    if (nvs_get_str(handle, "sch_tz_posix", sched->timezone_posix, &posix_len) == ESP_OK) {
        sched->timezone_posix[TIMEZONE_POSIX_SIZE - 1] = '\0';
    }

    if (sched->type == SCHED_SIMPLE) {
        uint8_t bin_count = 0;
        if (nvs_get_u8(handle, "sch_bcnt", &bin_count) == ESP_OK) {
            if (bin_count > 14) bin_count = 14; 
            sched->schedule.simple_schedule.bin_count = bin_count;

            char key[16];
            for (uint8_t i = 0; i < bin_count; i++) {
                snprintf(key, sizeof(key), "sch_b_%d", i);
                size_t blob_len = sizeof(device_bin_schedule_t);
                err = nvs_get_blob(handle, key, 
                                   &sched->schedule.simple_schedule.bins[i], 
                                   &blob_len);
                
                // If a specific bin is missing, ignore. If it's a real error, bail out.
                if (err != ESP_OK && err != ESP_ERR_NVS_NOT_FOUND) goto cleanup;
            }
        }
    }

    ESP_LOGI(TAG, "Schedule %s loaded (missing fields defaulted to 0).", sched->id);
    err = ESP_OK; // Reset error before exit

cleanup:
    nvs_close(handle);
    return err;
}

// Temporary POD structure to strip out pointers for safe blob storage
typedef struct {
    bin_status_t status;
    time_t scheduled_time;
    rtc_utc_timestamp_ms event_time;
} bin_pod_state_t;

/**
 * @brief Writes device state to RTC memory cache.
 * NVS is NOT written here. Call devcfg_flush_state_to_nvs() explicitly on flush triggers.
 */
esp_err_t devcfg_set_device_state(const device_persistent_state_t* state) {
    if (!state) return ESP_ERR_INVALID_ARG;
    memcpy(&g_rtc_device_state, state, sizeof(device_persistent_state_t));
    g_rtc_state_magic = RTC_STATE_MAGIC;
    return ESP_OK;
}

/**
 * @brief Flushes the RTC-cached device state to NVS atomically.
 * Must be called on: bin → TAKEN, schedule changed, or ESP_RST_BROWNOUT at boot.
 */
esp_err_t devcfg_flush_state_to_nvs(void) {
    if (g_rtc_state_magic != RTC_STATE_MAGIC) {
        ESP_LOGE(TAG, "Cannot flush: RTC state cache is not valid");
        return ESP_ERR_INVALID_STATE;
    }

    const device_persistent_state_t* state = &g_rtc_device_state;

    nvs_handle_t handle;
    esp_err_t err = nvs_open(NVS_DEV_STATE_NS, NVS_READWRITE, &handle);
    if (err != ESP_OK) return err;

    // 1. Transaction Start (Invalidate)
    CHECK_GOTO(nvs_set_u8(handle, "state_valid", 0));
    CHECK_GOTO(nvs_commit(handle));

    // 2. Write Fields
    CHECK_GOTO(nvs_set_u64(handle, "modified_at", (uint64_t)state->modified_at));
    CHECK_GOTO(nvs_set_u64(handle, "synced_at", (uint64_t)state->synced_at));
    CHECK_GOTO(nvs_set_u64(handle, "epoch_week", (time_t)state->epoch_week));
    CHECK_GOTO(devcfg_set_device_schedule(&state->schedule));

    // Persist timezone strings (always written so cleared values don't linger in NVS)
    CHECK_GOTO(nvs_set_str(handle, "tz_iana", state->timezone_iana));
    CHECK_GOTO(nvs_set_str(handle, "tz_posix", state->timezone_posix));

    bin_pod_state_t bins_pod[14] = {0};
    for (int i = 0; i < 14; i++) {
        bins_pod[i].status = state->bins[i].status;
        bins_pod[i].scheduled_time = state->bins[i].scheduled_time;
        bins_pod[i].event_time = state->bins[i].event_time;

        char key[16];
        snprintf(key, sizeof(key), "bin_sch_%d", i);

        if (state->bins[i].schedule_id[0] != '\0') {
            CHECK_GOTO(nvs_set_str(handle, key, state->bins[i].schedule_id));
        } else {
            esp_err_t erase_err = nvs_erase_key(handle, key);
            if (erase_err != ESP_OK && erase_err != ESP_ERR_NVS_NOT_FOUND) {
                err = erase_err;
                ESP_LOGE(TAG, "NVS Erase Error %s at line %d", esp_err_to_name(err), __LINE__);
                goto cleanup;
            }
        }
    }

    CHECK_GOTO(nvs_set_blob(handle, "bins_pod", bins_pod, sizeof(bins_pod)));
    CHECK_GOTO(nvs_commit(handle));

    // 3. Transaction Commit (Validate)
    CHECK_GOTO(nvs_set_u8(handle, "state_valid", 1));
    CHECK_GOTO(nvs_commit(handle));

    ESP_LOGI(TAG, "Device state flushed to NVS.");

cleanup:
    nvs_close(handle);
    return err;
}

/**
 * @brief Loads device state. Prefers RTC memory cache; falls back to NVS on first boot. 
 */
esp_err_t devcfg_get_device_state(device_persistent_state_t* state) {
    if (!state) return ESP_ERR_INVALID_ARG;

    // Fast path: RTC cache is valid (survives deep sleep and brownout)
    if (g_rtc_state_magic == RTC_STATE_MAGIC) {
        memcpy(state, &g_rtc_device_state, sizeof(device_persistent_state_t));
        return ESP_OK;
    }

    // Fallback: load from NVS (first boot after full flash or RTC corruption)
    // Zero out buffers so any missing fields naturally default to 0/null
    memset(state, 0, sizeof(device_persistent_state_t));

    nvs_handle_t handle;
    esp_err_t err = nvs_open(NVS_DEV_STATE_NS, NVS_READONLY, &handle);
    if (err != ESP_OK) {
        // If the namespace doesn't exist at all (e.g., fresh device), return OK 
        // with the safely zeroed state.
        return (err == ESP_ERR_NVS_NOT_FOUND) ? ESP_OK : err;
    }

    // 1. Transaction Check (STRICT)
    uint8_t valid = 0;
    err = nvs_get_u8(handle, "state_valid", &valid);
    if (err != ESP_OK || valid == 0) {
        ESP_LOGE(TAG, "Device state corrupted or incomplete transaction.");
        err = ESP_ERR_NVS_NOT_FOUND; 
        goto cleanup;
    }

    // 2. Load Fields Gracefully
    uint64_t mod_at = 0;
    if (nvs_get_u64(handle, "modified_at", &mod_at) == ESP_OK) {
        state->modified_at = (rtc_utc_timestamp_ms)mod_at;
    }

    uint64_t sync_at = 0;
    if (nvs_get_u64(handle, "synced_at", &sync_at) == ESP_OK) {
        state->synced_at = (rtc_utc_timestamp_ms)sync_at;
    }

    uint64_t epoch_week = 0;
    if (nvs_get_u64(handle, "epoch_week", &epoch_week) == ESP_OK) {
        state->epoch_week = (time_t)epoch_week;
    }

    // Attempt to load schedule, ignore if it's missing but fail on real NVS errors
    err = devcfg_get_device_schedule(&state->schedule);
    if (err != ESP_OK && err != ESP_ERR_NVS_NOT_FOUND) goto cleanup;

    // Load timezone strings (ignore if not yet stored; fields default to empty via memset above)
    state->timezone_iana[0] = '\0';
    size_t iana_len = TIMEZONE_IANA_SIZE;
    if (nvs_get_str(handle, "tz_iana", state->timezone_iana, &iana_len) == ESP_OK) {
        state->timezone_iana[TIMEZONE_IANA_SIZE - 1] = '\0';
    }
    state->timezone_posix[0] = '\0';
    size_t posix_len = TIMEZONE_POSIX_SIZE;
    if (nvs_get_str(handle, "tz_posix", state->timezone_posix, &posix_len) == ESP_OK) {
        state->timezone_posix[TIMEZONE_POSIX_SIZE - 1] = '\0';
    }

    bin_pod_state_t bins_pod[14];
    size_t req_size = sizeof(bins_pod);
    err = nvs_get_blob(handle, "bins_pod", bins_pod, &req_size);

    if (err == ESP_OK && req_size == sizeof(bins_pod)) {
        for (int i = 0; i < 14; i++) {
            state->bins[i].status = bins_pod[i].status;
            state->bins[i].scheduled_time = bins_pod[i].scheduled_time;
            state->bins[i].event_time = bins_pod[i].event_time;

            char key[16];
            snprintf(key, sizeof(key), "bin_sch_%d", i);
            
            size_t str_len = SCHEDULE_ID_SIZE;
            esp_err_t str_err = nvs_get_str(handle, key, state->bins[i].schedule_id, &str_len);
            
            if (str_err == ESP_OK) {
                // Ensure null termination just in case
                state->bins[i].schedule_id[SCHEDULE_ID_SIZE - 1] = '\0';
            } else if (str_err != ESP_ERR_NVS_NOT_FOUND) {
                // Only bail out on actual hardware/corruption errors for strings
                ESP_LOGE(TAG, "NVS Read Error %s at line %d", esp_err_to_name(str_err), __LINE__);
                err = str_err;
                goto cleanup;
            }
        }
    } else if (err != ESP_ERR_NVS_NOT_FOUND && err != ESP_OK) {
        goto cleanup;
    }

    ESP_LOGI(TAG, "Device state loaded (missing fields defaulted to 0).");
    err = ESP_OK; // Reset error to ensure we return success if we intentionally skipped missing fields

cleanup:
    nvs_close(handle);
    return err;
}