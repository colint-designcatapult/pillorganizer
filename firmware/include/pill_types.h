#pragma once
#include <stdint.h>
#include <esp_netif_types.h>

#include "pill.pb.h"
#include <time.h>

#define BIN_COUNT       14
#define BIN_MON_PM      0
#define BIN_MON_AM      1
#define BIN_TUE_PM      2
#define BIN_TUE_AM      3
#define BIN_WED_PM      4
#define BIN_WED_AM      5
#define BIN_THU_PM      6
#define BIN_THU_AM      7
#define BIN_FRI_PM      8
#define BIN_FRI_AM      9
#define BIN_SAT_PM      10
#define BIN_SAT_AM      11
#define BIN_SUN_PM      12
#define BIN_SUN_AM      13

#define LED_OFF         0
#define LED_SOLID_GREEN 1
#define LED_FLASH_GREEN 2
#define LED_SOLID_RED   3
#define LED_FLASH_RED   4

#define BIN_DISABLED    0
#define BIN_TAKEN       1
#define BIN_MISSED      2
#define BIN_PENDING     3
#define BIN_TAKE_NOW    4

#define BIN_EVENT_OPENED 1
#define BIN_EVENT_CLOSED 2
#define BIN_EVENT_MISSED 3

#define BIN_FLAG_HAS     

typedef uint8_t bin_id_t;
#define BIN_NULL       ((bin_id_t)-1)

typedef uint8_t bin_status_t;
typedef uint8_t bin_event_type_t;

typedef esp_ip_addr_t wifi_ip_t;

typedef struct {
    union {
        struct {
            uint8_t         _pad[2];
            uint8_t         mac[6];
        } bytes;
        uint64_t        sn;
    } sn;
    uint8_t         bssid[6];
    char            ssid[33];
    bool            has_ip4:1;
    bool            has_ip6:1;
    esp_ip6_addr_t  ip6;
    esp_ip4_addr_t  ip4;
} wifi_info_t;

typedef struct _temp_state {
    time_t time_reg;
    bool open;
} temp_state_t;

typedef struct _bin_state {
    time_t       schedule_time;
    uint8_t      flags;
    bin_status_t status;
    bin_id_t     next_bin;
    bin_id_t     prev_bin;
} bin_state_t;

