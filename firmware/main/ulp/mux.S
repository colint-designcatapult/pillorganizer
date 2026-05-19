/*
 * ULP Assembly to poll channels via a CD4067B MUX
 * Sequence: Ch0-Ch15 (16 samples, one per 10ms timer tick)
 *
 * Pipeline design: each tick reads the channel selected on the previous tick
 * (which has now settled for 10ms), then selects the next channel and halts.
 * The CPU is woken once per complete 16-channel cycle (~160ms).
 *
 * Features 4x oversampling and DYNAMIC ATTENUATION.
 */
#include "soc/rtc_cntl_reg.h"
#include "soc/rtc_io_reg.h"
#include "soc/sens_reg.h"
#include "soc/soc_ulp.h"
#include "mux_config.h"

    .set adc_channel, MUX_ADC_CHANNEL

    #define ADC_ATTEN_SHIFT (MUX_ADC_CHANNEL * 2)

.bss
    /* ADC sample buffer (16 elements * 4 bytes each) */
    .global adc_readings_0
adc_readings_0:
    .skip 64

    /* Per-sample intensity snapshots (16 entries per cycle) */
    .global led_intensity_snap_0
led_intensity_snap_0:
    .skip 64

    /* Per-cycle red/green ON bits for sample indices 0..15 */
    .global led_red_bits_0
led_red_bits_0:
    .long 0
    .global led_green_bits_0
led_green_bits_0:
    .long 0

    /*
     * Index of the channel currently selected on the MUX — ready to read
     * this tick. Valid range: 0..15. Ignored when primed == 0.
     */
    .global current_sequence_idx
current_sequence_idx:
    .long 0

    /* 0 = MUX not yet set (bootstrap tick); 1 = pipeline running */
    .global primed
primed:
    .long 0

    /* LED snapshot written by the main CPU every LED task tick (20ms). */
    .global led_red_mask
led_red_mask:
    .long 0
    .global led_green_mask
led_green_mask:
    .long 0
    .global led_intensity
led_intensity:
    .long 0

.text
    .global entry
entry:
    jump real_entry

    .global channel_sequence
channel_sequence:
    .long 0
    .long 1
    .long 2
    .long 3
    .long 4
    .long 5
    .long 6
    .long 7
    .long 8
    .long 9
    .long 10
    .long 11
    .long 12
    .long 13
    .long 14
    .long 15

    .global channel_bitmask
channel_bitmask:
    .long 0x0001
    .long 0x0002
    .long 0x0004
    .long 0x0008
    .long 0x0010
    .long 0x0020
    .long 0x0040
    .long 0x0080
    .long 0x0100
    .long 0x0200
    .long 0x0400
    .long 0x0800
    .long 0x1000
    .long 0x2000
    .long 0x4000
    .long 0x8000

real_entry:
    /* Bootstrap: if MUX has never been set, prime it and halt */
    move r3, primed
    ld r0, r3, 0
    jump prime_mux, eq

    /* === PRIMED PATH ===
     * r2 = index of the channel set last tick (now settled, ready to read) */
    move r3, current_sequence_idx
    ld r2, r3, 0

    move r3, channel_sequence
    add r3, r3, r2
    ld r1, r3, 0                /* r1 = MUX channel number */

    /* ==========================================================
     * Dynamic ADC Attenuation: ch14 (battery) uses 11dB, rest 0dB
     * ========================================================== */
    move r0, r1
    sub r0, r0, 14
    jump set_atten_11db, eq

set_atten_0db:
    WRITE_RTC_REG(SENS_SAR_ATTEN1_REG, ADC_ATTEN_SHIFT, 2, 0)
    jump read_adc

set_atten_11db:
    WRITE_RTC_REG(SENS_SAR_ATTEN1_REG, ADC_ATTEN_SHIFT, 2, 3)

read_adc:
    /* ==========================================================
     * 4x Oversampling: discard first sample, average next four
     * ========================================================== */
    adc r0, 0, adc_channel + 1
    wait 4000

    move r1, 0

    adc r0, 0, adc_channel + 1
    add r1, r1, r0
    wait 100

    adc r0, 0, adc_channel + 1
    add r1, r1, r0
    wait 100

    adc r0, 0, adc_channel + 1
    add r1, r1, r0
    wait 100

    adc r0, 0, adc_channel + 1
    add r1, r1, r0

    rsh r1, r1, 2               /* r1 = average of 4 samples */

    /* ==========================================================
     * Write sample and LED metadata
     * ========================================================== */
    move r3, adc_readings_0
    add r3, r3, r2              /* word offset = channel index */
    st r1, r3, 0

    /* If this is the first index in the cycle, reset packed red/green bits */
    move r0, r2
    jump clear_cycle_bits, eq
    jump bits_ready
clear_cycle_bits:
    move r1, 0
    move r3, led_red_bits_0
    st r1, r3, 0
    move r3, led_green_bits_0
    st r1, r3, 0
bits_ready:
    move r3, channel_bitmask
    add r3, r3, r2
    ld r0, r3, 0                /* r0 = sample-index bit */

    move r3, led_red_mask
    ld r3, r3, 0
    and r0, r3, r0
    jumpr set_red_bit, 1, ge
    jump red_done
set_red_bit:
    move r3, led_red_bits_0
    ld r1, r3, 0
    add r1, r1, r0
    st r1, r3, 0
red_done:
    move r3, channel_bitmask
    add r3, r3, r2
    ld r0, r3, 0                /* reload channel bit for green test */
    move r3, led_green_mask
    ld r3, r3, 0
    and r0, r3, r0
    jumpr set_green_bit, 1, ge
    jump green_done
set_green_bit:
    move r3, led_green_bits_0
    ld r1, r3, 0
    add r1, r1, r0
    st r1, r3, 0
green_done:

    move r3, led_intensity
    ld r0, r3, 0
    move r3, led_intensity_snap_0
    add r3, r3, r2
    st r0, r3, 0

advance_index:
    /* Advance index; check if full cycle is complete */
    add r2, r2, 1
    move r0, r2
    sub r0, r0, 16
    jump finish_cycle, eq

    /* Cycle not done: persist new index and queue next channel */
    move r3, current_sequence_idx
    st r2, r3, 0
    jump set_next_mux

finish_cycle:
    wake

    /* Reset index to 0; MUX will be primed for ch0 below */
    move r2, 0
    move r3, current_sequence_idx
    st r2, r3, 0
    jump set_next_mux

prime_mux:
    /* First tick ever: mark pipeline as primed and select ch0 */
    move r3, primed
    move r0, 1
    st r0, r3, 0

    move r2, 0
    move r3, current_sequence_idx
    st r2, r3, 0
    /* fall through to set_next_mux */

set_next_mux:
    /* Load the channel number for index r2 and drive MUX select lines.
     * The 10ms timer period provides the required settle time before the
     * next tick reads this channel. */
    move r3, channel_sequence
    add r3, r3, r2
    ld r1, r3, 0                /* r1 = MUX channel to select */

    /* Pin A (bit 0) */
    and r0, r1, 1
    jumpr mux_set_a, 1, ge
    WRITE_RTC_REG(RTC_GPIO_OUT_W1TC_REG, RTC_GPIO_OUT_DATA_W1TC_S + 9, 1, 1)
    jump mux_pin_b
mux_set_a:
    WRITE_RTC_REG(RTC_GPIO_OUT_W1TS_REG, RTC_GPIO_OUT_DATA_W1TS_S + 9, 1, 1)

mux_pin_b:
    /* Pin B (bit 1) */
    and r0, r1, 2
    jumpr mux_set_b, 1, ge
    WRITE_RTC_REG(RTC_GPIO_OUT_W1TC_REG, RTC_GPIO_OUT_DATA_W1TC_S + 8, 1, 1)
    jump mux_pin_c
mux_set_b:
    WRITE_RTC_REG(RTC_GPIO_OUT_W1TS_REG, RTC_GPIO_OUT_DATA_W1TS_S + 8, 1, 1)

mux_pin_c:
    /* Pin C (bit 2) */
    and r0, r1, 4
    jumpr mux_set_c, 1, ge
    WRITE_RTC_REG(RTC_GPIO_OUT_W1TC_REG, RTC_GPIO_OUT_DATA_W1TC_S + 17, 1, 1)
    jump mux_pin_d
mux_set_c:
    WRITE_RTC_REG(RTC_GPIO_OUT_W1TS_REG, RTC_GPIO_OUT_DATA_W1TS_S + 17, 1, 1)

mux_pin_d:
    /* Pin D (bit 3) */
    and r0, r1, 8
    jumpr mux_set_d, 1, ge
    WRITE_RTC_REG(RTC_GPIO_OUT_W1TC_REG, RTC_GPIO_OUT_DATA_W1TC_S + 7, 1, 1)
    jump do_halt
mux_set_d:
    WRITE_RTC_REG(RTC_GPIO_OUT_W1TS_REG, RTC_GPIO_OUT_DATA_W1TS_S + 7, 1, 1)

do_halt:
    halt