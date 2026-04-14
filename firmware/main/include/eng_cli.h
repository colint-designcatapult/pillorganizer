/*
 * Engineering CLI
 *
 * UART-based console for issuing test commands when running in the
 * QEMU emulator (or on real hardware with engineering features enabled).
 */
#pragma once

#include <esp_err.h>

/**
 * Initialize and start the engineering CLI console.
 * Registers all available commands and starts a background task that
 * reads lines from UART and dispatches them.
 */
esp_err_t eng_cli_init(void);
