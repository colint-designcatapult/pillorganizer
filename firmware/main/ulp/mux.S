/*
 * ULP Assembly to poll 16 channels via a CD4067B MUX
 * Uses simple threshold detection (10) for Door Open/Close events.
 * Features 4x oversampling per channel.
 */
#include "soc/rtc_cntl_reg.h"
#include "soc/rtc_io_reg.h"
#include "soc/soc_ulp.h"
#include "mux_config.h"

    .set adc_channel, MUX_ADC_CHANNEL

.bss
    .global adc_readings
adc_readings: 
    .skip 64   /* 16 elements * 4 bytes each */

    .global prev_readings
prev_readings:
    .skip 64  

    .global event_flags
event_flags:
    .skip 64

    .global init_flags
init_flags:
    .skip 64

    .global current_mux_channel
current_mux_channel: 
    .long 0

    .global wakeup_flag
wakeup_flag:
    .long 0

    .text
    .global entry
entry:
    move r0, 0
    move r3, current_mux_channel
    st r0, r3, 0

channel_loop:
    move r3, current_mux_channel
    ld r2, r3, 0

    /* ==========================================================
     * MUX Channel Selection 
     * ========================================================== */
    and r0, r2, 1
    jumpr set_mux_a, 1, ge
    WRITE_RTC_REG(RTC_GPIO_OUT_W1TC_REG, RTC_GPIO_OUT_DATA_W1TC_S + 9, 1, 1)
    jump mux_b
set_mux_a:
    WRITE_RTC_REG(RTC_GPIO_OUT_W1TS_REG, RTC_GPIO_OUT_DATA_W1TS_S + 9, 1, 1)

mux_b:
    and r0, r2, 2
    jumpr set_mux_b, 1, ge
    WRITE_RTC_REG(RTC_GPIO_OUT_W1TC_REG, RTC_GPIO_OUT_DATA_W1TC_S + 8, 1, 1)
    jump mux_c
set_mux_b:
    WRITE_RTC_REG(RTC_GPIO_OUT_W1TS_REG, RTC_GPIO_OUT_DATA_W1TS_S + 8, 1, 1)

mux_c:
    and r0, r2, 4
    jumpr set_mux_c, 1, ge
    WRITE_RTC_REG(RTC_GPIO_OUT_W1TC_REG, RTC_GPIO_OUT_DATA_W1TC_S + 17, 1, 1)
    jump mux_d
set_mux_c:
    WRITE_RTC_REG(RTC_GPIO_OUT_W1TS_REG, RTC_GPIO_OUT_DATA_W1TS_S + 17, 1, 1)

mux_d:
    and r0, r2, 8
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
     * 4x Oversampling
     * ========================================================== */
    move r1, 0                  /* Clear r1 to act as our accumulator */
    
    adc r0, 0, adc_channel + 1  /* Sample 1 */
    add r1, r1, r0
    
    adc r0, 0, adc_channel + 1  /* Sample 2 */
    add r1, r1, r0
    
    adc r0, 0, adc_channel + 1  /* Sample 3 */
    add r1, r1, r0
    
    adc r0, 0, adc_channel + 1  /* Sample 4 */
    add r1, r1, r0
    
    rsh r1, r1, 2               /* Divide by 4 (Right shift by 2) to get the average */

    /* Store the averaged ADC value */
    move r3, adc_readings
    add r3, r3, r2     
    st r1, r3, 0

    /* Check initialization flag */
    move r3, init_flags
    add r3, r3, r2
    ld r0, r3, 0
    jumpr is_initialized, 1, ge  
    
    /* First Run: Set flag and baseline prev_read */
    move r0, 1
    st r0, r3, 0
    jump update_prev_and_next

is_initialized:
    /* Load prev_read into r3 first, so we don't clobber r0 just yet */
    move r3, prev_readings
    add r3, r3, r2
    ld r3, r3, 0

    /* ------------------------------------------------ */
    /* Check Thresholds                                 */
    /* ------------------------------------------------ */
    /* Check if prev_read < 10 */
    move r0, r3                 /* Move prev_read into r0 for math & jumpr */
    sub r0, r0, 10
    and r0, r0, 0x8000          /* MSB is 1 if result is negative */
    jumpr prev_was_low, 1, ge   /* Jumps if r0 >= 1 (meaning prev_read < 10) */

prev_was_high:
    /* We are here if prev_read >= 10 */
    /* Now check if current read (r1) < 10 */
    move r0, r1                 /* Move current read into r0 for math & jumpr */
    sub r0, r0, 10
    and r0, r0, 0x8000
    jumpr trigger_close, 1, ge  /* If negative (r0 has 0x8000), read < 10, trigger CLOSE */
    jump update_prev_and_next   /* Otherwise, no change */

prev_was_low:
    /* We are here if prev_read < 10 */
    /* Now check if current read (r1) >= 10 */
    move r0, r1                 /* Move current read into r0 for math & jumpr */
    sub r0, r0, 10
    and r0, r0, 0x8000
    jumpr update_prev_and_next, 1, ge /* If negative (r0 has 0x8000), read < 10, no change */
    jump trigger_open                 /* Otherwise (r0 is 0), read >= 10, trigger OPEN */

trigger_open:
    move r0, 1                  /* Event 1 = OPEN */
    jump trigger_event

trigger_close:
    move r0, 2                  /* Event 2 = CLOSE */

trigger_event:
    /* Store Event Type in event_flags */
    move r3, event_flags
    add r3, r3, r2
    st r0, r3, 0

    /* Set Wakeup Flag */
    move r3, wakeup_flag
    move r0, 1
    st r0, r3, 0

update_prev_and_next:
    /* Store current read (r1) into prev_readings for the next loop */
    move r3, prev_readings
    add r3, r3, r2
    st r1, r3, 0

next_channel:
    add r2, r2, 1
    move r3, current_mux_channel
    st r2, r3, 0
    
    move r0, r2
    sub r0, r0, 16
    jump exit, eq
    jump channel_loop

exit:
    move r3, wakeup_flag
    ld r0, r3, 0
    jumpr skip_wake, 1, lt

    /* Clear Wakeup Flag and Wake Main */
    move r0, 0
    st r0, r3, 0
    wake

skip_wake:
    halt