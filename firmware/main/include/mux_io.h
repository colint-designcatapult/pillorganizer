/* 
 * Sensor MUX Driver & I/O
 * 
 * Code for reading sensor data via the CD4067B MUX.
 */
#pragma once
#include <stdbool.h>
#include <stdint.h>

void mux_init();
void mux_fresh_boot();
void mux_wake_deep_sleep();
// Returns true if the system should boot normally, false if it should go back to sleep
bool mux_wake_deep_sleep_early();
void mux_prep_deep_sleep();
