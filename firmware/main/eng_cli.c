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
 */
#include "eng_cli.h"

#if CONFIG_FIRMWARE_ENGINEERING

#include <stdio.h>
#include <string.h>
#include <esp_log.h>
#include <esp_console.h>
#include <esp_system.h>
#include <esp_vfs_dev.h>
#include <driver/uart.h>
#include <argtable3/argtable3.h>
#include <linenoise/linenoise.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <nvs.h>
#include <nvs_flash.h>

#include "device_config.h"
#include "claim.h"
#include "supervisor.h"

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
/*  Console task                                                      */
/* ------------------------------------------------------------------ */

static void eng_cli_task(void *arg)
{
    /* Prompt */
    const char *prompt = "eng> ";

    printf("\n"
           "======================================\n"
           "  Engineering CLI  (type 'help')\n"
           "======================================\n\n");

    while (true) {
        char *line = linenoise(prompt);
        if (line == NULL) {
            /* Timeout / EOF — wait a bit and retry */
            vTaskDelay(pdMS_TO_TICKS(100));
            continue;
        }

        /* Skip empty lines */
        if (strlen(line) > 0) {
            linenoiseHistoryAdd(line);

            int ret;
            esp_err_t err = esp_console_run(line, &ret);
            if (err == ESP_ERR_NOT_FOUND) {
                printf("Unknown command: %s\n", line);
            } else if (err == ESP_ERR_INVALID_ARG) {
                /* empty input — ignore */
            } else if (err != ESP_OK) {
                printf("Error: %s\n", esp_err_to_name(err));
            }
        }

        linenoiseFree(line);
    }

    vTaskDelete(NULL);
}

/* ------------------------------------------------------------------ */
/*  Public API                                                        */
/* ------------------------------------------------------------------ */

esp_err_t eng_cli_init(void)
{
    /* Configure UART for console I/O */
    esp_console_config_t console_config = {
        .max_cmdline_args   = 8,
        .max_cmdline_length = 256,
    };
    ESP_ERROR_CHECK(esp_console_init(&console_config));

    /* Configure linenoise */
    linenoiseSetMultiLine(1);
    linenoiseSetMaxLineLen(console_config.max_cmdline_length);
    linenoiseHistorySetMaxLen(20);
    linenoiseAllowEmpty(false);

    /* Register built-in 'help' command */
    esp_console_register_help_command();

    /* Register engineering commands */
    register_provision_cmd();
    register_serial_cmd();
    register_identity_cmd();
    register_reboot_cmd();
    register_reset_cmd();

    /* Start CLI task with generous stack for linenoise + argtable */
    xTaskCreate(eng_cli_task, "eng_cli", 4096, NULL, 5, NULL);

    ESP_LOGI(TAG, "Engineering CLI initialized");
    return ESP_OK;
}

#else /* CONFIG_FIRMWARE_ENGINEERING */

esp_err_t eng_cli_init(void)
{
    return ESP_OK;
}

#endif /* CONFIG_FIRMWARE_ENGINEERING */
