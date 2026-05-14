/*
 * Engineering CLI
 *
 * UART-based command console for testing and debugging.
 * Available when CONFIG_FIRMWARE_ENGINEERING is enabled.
 *
 * Commands:
 *   provision <claim_id> <claim_token>  - Execute fleet provisioning flow
 *   serial                              - Print the device serial number
 *   identity                            - Show provisioning identity status
 *   reboot                              - Reboot the device
 *   reset                               - Factory reset and reboot
 *   set_led <red_bits> <green_bits> [blink_bits] - Override idle LED state (14-bit binary strings, locks out firmware)
 *   reset_led                           - Release the LED lock
 */
#include "eng_cli.h"

#if CONFIG_FIRMWARE_ENGINEERING

#include <stdio.h>
#include <string.h>
#include <esp_log.h>
#include <esp_console.h>
#include <esp_system.h>
#include <argtable3/argtable3.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <nvs.h>
#include <nvs_flash.h>

#include "device_config.h"
#include "claim.h"
#include "supervisor.h"
#include "ledc.h"

#define TAG "ENG_CLI"

/* ------------------------------------------------------------------ */
/*  Command: provision <claim_id> <claim_token>                       */
/* ------------------------------------------------------------------ */

static struct {
    struct arg_str *claim_id;
    struct arg_str *claim_token;
    struct arg_end *end;
} s_provision_args;

static int cmd_provision(int argc, char **argv)
{
    int nerrors = arg_parse(argc, argv, (void **)&s_provision_args);
    if (nerrors != 0) {
        arg_print_errors(stderr, s_provision_args.end, argv[0]);
        return 1;
    }

    const char *claim_id    = s_provision_args.claim_id->sval[0];
    const char *claim_token = s_provision_args.claim_token->sval[0];

    ESP_LOGI(TAG, "Setting claim credentials: id=%s token=%s", claim_id, claim_token);

    /* Feed the credentials into the existing claim subsystem. */
    claim_set_credentials(claim_id, claim_token);

    /* Notify the supervisor so it follows the normal provisioning path:
     *   credentials received → fetch temp certs → fleet provision           */
    ESP_LOGI(TAG, "Submitting EVENT_CLAIM_CREDENTIALS_RECEIVED to supervisor");
    esp_err_t err = supervisor_submit_event(EVENT_CLAIM_CREDENTIALS_RECEIVED);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to submit event: %s", esp_err_to_name(err));
        return 1;
    }

    printf("Provisioning started. Monitor log output for progress.\n");
    return 0;
}

static void register_provision_cmd(void)
{
    s_provision_args.claim_id = arg_str1(NULL, NULL, "<claim_id>", "Claim ID from the control plane");
    s_provision_args.claim_token = arg_str1(NULL, NULL, "<claim_token>", "Claim token from the control plane");
    s_provision_args.end = arg_end(2);

    const esp_console_cmd_t cmd = {
        .command  = "provision",
        .help     = "Execute fleet provisioning with the given claim credentials",
        .hint     = "<claim_id> <claim_token>",
        .func     = &cmd_provision,
        .argtable = &s_provision_args,
    };
    ESP_ERROR_CHECK(esp_console_cmd_register(&cmd));
}

/* ------------------------------------------------------------------ */
/*  Command: serial                                                   */
/* ------------------------------------------------------------------ */

static int cmd_serial(int argc, char **argv)
{
    char sn[SERIAL_NUMBER_STR_SIZE];
    devcfg_get_serial_number_str(sn, sizeof(sn));
    printf("Serial: %s\n", sn);
    return 0;
}

static void register_serial_cmd(void)
{
    const esp_console_cmd_t cmd = {
        .command = "serial",
        .help    = "Print the device serial number",
        .hint    = NULL,
        .func    = &cmd_serial,
    };
    ESP_ERROR_CHECK(esp_console_cmd_register(&cmd));
}

/* ------------------------------------------------------------------ */
/*  Command: identity                                                 */
/* ------------------------------------------------------------------ */

static int cmd_identity(int argc, char **argv)
{
    char sn[SERIAL_NUMBER_STR_SIZE];
    devcfg_get_serial_number_str(sn, sizeof(sn));

    char thing[128];
    bool has_thing = devcfg_get_thing_name_str(thing, sizeof(thing));
    bool has_perm  = devcfg_has_permanent_identity();

    printf("Serial number:      %s\n", sn);
    printf("Thing name:         %s\n", has_thing ? thing : "(not set)");
    printf("Permanent identity: %s\n", has_perm  ? "yes" : "no");
    return 0;
}

static void register_identity_cmd(void)
{
    const esp_console_cmd_t cmd = {
        .command = "identity",
        .help    = "Show device identity / provisioning status",
        .hint    = NULL,
        .func    = &cmd_identity,
    };
    ESP_ERROR_CHECK(esp_console_cmd_register(&cmd));
}

/* ------------------------------------------------------------------ */
/*  Command: reboot                                                   */
/* ------------------------------------------------------------------ */

static int cmd_reboot(int argc, char **argv)
{
    printf("Rebooting...\n");
    vTaskDelay(pdMS_TO_TICKS(200));
    esp_restart();
    return 0; /* unreachable */
}

static void register_reboot_cmd(void)
{
    const esp_console_cmd_t cmd = {
        .command = "reboot",
        .help    = "Reboot the device",
        .hint    = NULL,
        .func    = &cmd_reboot,
    };
    ESP_ERROR_CHECK(esp_console_cmd_register(&cmd));
}

/* ------------------------------------------------------------------ */
/*  Command: reset                                                    */
/* ------------------------------------------------------------------ */

static int cmd_reset(int argc, char **argv)
{
    printf("Factory reset — erasing NVS and rebooting...\n");
    nvs_flash_erase();
    nvs_flash_init();
    vTaskDelay(pdMS_TO_TICKS(200));
    esp_restart();
    return 0; /* unreachable */
}

static void register_reset_cmd(void)
{
    const esp_console_cmd_t cmd = {
        .command = "reset",
        .help    = "Factory-reset the device (erase NVS) and reboot",
        .hint    = NULL,
        .func    = &cmd_reset,
    };
    ESP_ERROR_CHECK(esp_console_cmd_register(&cmd));
}

/* ------------------------------------------------------------------ */
/*  Command: set_led <red_bits> <green_bits>                          */
/* ------------------------------------------------------------------ */

#define SET_LED_BITS 14

static struct {
    struct arg_str *red;
    struct arg_str *green;
    struct arg_str *blink;
    struct arg_end *end;
} s_set_led_args;

/* Parse a binary string of exactly SET_LED_BITS '0'/'1' chars into a uint16_t. */
static bool parse_led_bitmask(const char *s, uint16_t *out)
{
    size_t len = strlen(s);
    if (len != SET_LED_BITS) {
        printf("Error: bitmask must be exactly %d binary digits (got %zu)\n", SET_LED_BITS, len);
        return false;
    }
    uint16_t val = 0;
    for (int i = 0; i < SET_LED_BITS; i++) {
        if (s[i] == '1') {
            val |= (1u << i);
        } else if (s[i] != '0') {
            printf("Error: invalid character '%c' — only '0' and '1' are allowed\n", s[i]);
            return false;
        }
    }
    *out = val;
    return true;
}

static int cmd_set_led(int argc, char **argv)
{
    int nerrors = arg_parse(argc, argv, (void **)&s_set_led_args);
    if (nerrors != 0) {
        arg_print_errors(stderr, s_set_led_args.end, argv[0]);
        return 1;
    }

    uint16_t red = 0, green = 0, blink = 0;
    if (!parse_led_bitmask(s_set_led_args.red->sval[0], &red)) return 1;
    if (!parse_led_bitmask(s_set_led_args.green->sval[0], &green)) return 1;
    if (s_set_led_args.blink->count > 0) {
        if (!parse_led_bitmask(s_set_led_args.blink->sval[0], &blink)) return 1;
    }

    led_task_param_t param = {0};
    param.device_state.red        = red;
    param.device_state.green      = green;
    param.device_state.blink_mask = blink;

    ledc_eng_unlock();
    ledc_set_idle_task(LED_DEVICE_STATE, param);
    ledc_eng_lock();

    printf("LED idle state set and locked: red=0x%04X green=0x%04X blink=0x%04X\n", red, green, blink);
    return 0;
}

static void register_set_led_cmd(void)
{
    s_set_led_args.red   = arg_str1(NULL, NULL, "<red_bits>",   "14-bit binary mask for red LEDs (e.g. 11000000000000)");
    s_set_led_args.green = arg_str1(NULL, NULL, "<green_bits>", "14-bit binary mask for green LEDs (e.g. 00000000000000)");
    s_set_led_args.blink = arg_str0(NULL, NULL, "[blink_bits]", "14-bit binary mask for blinking LEDs (optional, default all-off)");
    s_set_led_args.end   = arg_end(3);

    const esp_console_cmd_t cmd = {
        .command  = "set_led",
        .help     = "Override idle LED state with LED_DEVICE_STATE using 14-bit binary red/green/blink masks",
        .hint     = "<red_bits> <green_bits> [blink_bits]",
        .func     = &cmd_set_led,
        .argtable = &s_set_led_args,
    };
    ESP_ERROR_CHECK(esp_console_cmd_register(&cmd));
}

/* ------------------------------------------------------------------ */
/*  Command: reset_led                                                */
/* ------------------------------------------------------------------ */

static int cmd_reset_led(int argc, char **argv)
{
    ledc_eng_unlock();
    printf("LED lock released — idle state control returned to firmware.\n");
    return 0;
}

static void register_reset_led_cmd(void)
{
    const esp_console_cmd_t cmd = {
        .command = "reset_led",
        .help    = "Release the eng LED lock, returning idle state control to the firmware",
        .hint    = NULL,
        .func    = &cmd_reset_led,
    };
    ESP_ERROR_CHECK(esp_console_cmd_register(&cmd));
}

/* ------------------------------------------------------------------ */
/*  Public API                                                        */
/* ------------------------------------------------------------------ */

esp_err_t eng_cli_init(void)
{
    esp_console_repl_t *repl = NULL;

    esp_console_repl_config_t repl_config = ESP_CONSOLE_REPL_CONFIG_DEFAULT();
    repl_config.prompt           = "eng>";
    repl_config.max_cmdline_length = 256;
    repl_config.task_stack_size  = 4096;

    esp_console_dev_uart_config_t uart_config = ESP_CONSOLE_DEV_UART_CONFIG_DEFAULT();

    esp_console_register_help_command();
    register_provision_cmd();
    register_serial_cmd();
    register_identity_cmd();
    register_reboot_cmd();
    register_reset_cmd();
    register_set_led_cmd();
    register_reset_led_cmd();

    ESP_ERROR_CHECK(esp_console_new_repl_uart(&uart_config, &repl_config, &repl));
    ESP_ERROR_CHECK(esp_console_start_repl(repl));

    ESP_LOGI(TAG, "Engineering CLI initialized");
    return ESP_OK;
}

#else /* CONFIG_FIRMWARE_ENGINEERING */

esp_err_t eng_cli_init(void)
{
    return ESP_OK;
}

#endif /* CONFIG_FIRMWARE_ENGINEERING */
