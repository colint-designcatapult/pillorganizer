/*
 * ULP Assembly to poll channels via a CD4067B MUX
 * Sequence: Ch14, Ch0-13, Ch15, Ch14 (17 samples total)
 * Features 4x oversampling per channel.
 * Wakes the main core unconditionally after all 17 channels are read.
 */
#include "soc/rtc_cntl_reg.h"
#include "soc/rtc_io_reg.h"
#include "soc/soc_ulp.h"
#include "mux_config.h"

    .set adc_channel, MUX_ADC_CHANNEL

.bss
    .global adc_readings
adc_readings: 
    .skip 68   /* 17 elements * 4 bytes each = 68 bytes */

    /* Renamed to clarify we are tracking the sequence index, not the raw channel */
    .global current_sequence_idx
current_sequence_idx: 
    .long 0

    .global data_ready
data_ready:
    .long 0

.text
    .global entry
entry:
    /* Jump over our lookup table so it doesn't execute as code */
    jump real_entry

/* * Embedded Lookup Table: 
 * Placed in .text to guarantee it flashes correctly to RTC memory 
 * without relying on C-side .bss initialization.
 */
    .global channel_sequence
channel_sequence:
    .long 14
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
    .long 15
    .long 14

real_entry:
    /* Reset sequence counter to 0 on every ULP wakeup */
    move r0, 0
    move r3, current_sequence_idx
    st r0, r3, 0

channel_loop:
    /* Load the current index (0 to 16) into r2 */
    move r3, current_sequence_idx
    ld r2, r3, 0

    /* Fetch the actual MUX channel from the lookup table into r1 */
    move r3, channel_sequence
    add r3, r3, r2
    ld r1, r3, 0

    /* ==========================================================
     * MUX Channel Selection (Using r1 as the target channel)
     * ========================================================== */
    and r0, r1, 1
    jumpr set_mux_a, 1, ge
    WRITE_RTC_REG(RTC_GPIO_OUT_W1TC_REG, RTC_GPIO_OUT_DATA_W1TC_S + 9, 1, 1)
    jump mux_b
set_mux_a:
    WRITE_RTC_REG(RTC_GPIO_OUT_W1TS_REG, RTC_GPIO_OUT_DATA_W1TS_S + 9, 1, 1)

mux_b:
    and r0, r1, 2
    jumpr set_mux_b, 1, ge
    WRITE_RTC_REG(RTC_GPIO_OUT_W1TC_REG, RTC_GPIO_OUT_DATA_W1TC_S + 8, 1, 1)
    jump mux_c
set_mux_b:
    WRITE_RTC_REG(RTC_GPIO_OUT_W1TS_REG, RTC_GPIO_OUT_DATA_W1TS_S + 8, 1, 1)

mux_c:
    and r0, r1, 4
    jumpr set_mux_c, 1, ge
    WRITE_RTC_REG(RTC_GPIO_OUT_W1TC_REG, RTC_GPIO_OUT_DATA_W1TC_S + 17, 1, 1)
    jump mux_d
set_mux_c:
    WRITE_RTC_REG(RTC_GPIO_OUT_W1TS_REG, RTC_GPIO_OUT_DATA_W1TS_S + 17, 1, 1)

mux_d:
    and r0, r1, 8
    jumpr set_mux_d, 1, ge
    WRITE_RTC_REG(RTC_GPIO_OUT_W1TC_REG, RTC_GPIO_OUT_DATA_W1TC_S + 7, 1, 1)
    jump delay_10ms
set_mux_d:
    WRITE_RTC_REG(RTC_GPIO_OUT_W1TS_REG, RTC_GPIO_OUT_DATA_W1TS_S + 7, 1, 1)

delay_10ms:
    wait 40000
    wait 40000


read_adc:
    /* ==========================================================
     * 4x Oversampling with Dummy Read
     * ========================================================== */
     
    /* 1. Dummy Read: Forces the internal ADC capacitor to connect 
          to the pin. We discard this value. */
    adc r0, 0, adc_channel + 1
    wait 4000                   /* Wait ~0.5ms for internal cap to charge/equalize */

    /* 2. Real Sampling */
    move r1, 0                  /* Clear r1 to act as our accumulator */
    
    adc r0, 0, adc_channel + 1  /* Sample 1 */
    add r1, r1, r0
    wait 100                    /* Wait ~12.5us between samples */
    
    adc r0, 0, adc_channel + 1  /* Sample 2 */
    add r1, r1, r0
    wait 100

    adc r0, 0, adc_channel + 1  /* Sample 3 */
    add r1, r1, r0
    wait 100

    adc r0, 0, adc_channel + 1  /* Sample 4 */
    add r1, r1, r0

    rsh r1, r1, 2               /* Divide by 4 (Right shift by 2) to get the average */

    /* Store the averaged ADC value directly */
    move r3, adc_readings
    add r3, r3, r2              /* r2 is our sequence index (0 to 16) */
    st r1, r3, 0

next_channel:
    add r2, r2, 1               /* Increment sequence counter */
    move r3, current_sequence_idx
    st r2, r3, 0
    
    move r0, r2
    sub r0, r0, 17              /* Check if we've hit 17 samples (index 17) */
    jump exit, eq               /* If yes, exit and wake */
    jump channel_loop           /* If no, loop back to the top */

exit:
    /* 1. Set the data_ready flag to 1 */
    move r3, data_ready
    move r0, 1
    st r0, r3, 0
    
    /* 2. Unconditionally wake the main core */
    wake

wait_for_cpu:
    /* 3. Wait for the main CPU to clear the flag to 0 */
    move r3, data_ready
    ld r0, r3, 0
    jumpr wait_for_cpu, 1, ge  

    /* 4. CPU has safely copied the data, start next sweep immediately */
    jump entry