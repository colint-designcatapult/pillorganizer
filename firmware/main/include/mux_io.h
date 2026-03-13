/* 
 * Sensor MUX Driver & I/O
 * 
 * Code for reading sensor data via the CD4067B MUX.
 */
#pragma once

void mux_init();
void mux_fresh_boot();
void mux_wake_deep_sleep();
void mux_wake_deep_sleep_early();
void mux_prep_deep_sleep();