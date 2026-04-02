/*
 * ULP Assembly to poll channels via a CD4067B MUX
 * Sequence: Ch14, Ch0-13, Ch15, Ch14 (17 samples total)
 * Features 4x oversampling, DYNAMIC ATTENUATION, and DOUBLE BUFFERING.
 */
#include "soc/rtc_cntl_reg.h"
#include "soc/rtc_io_reg.h"
#include "soc/sens_reg.h"  
#include "soc/soc_ulp.h"
#include "mux_config.h"

    .set adc_channel, MUX_ADC_CHANNEL
    
    /* Calculate the exact bit shift for your specific ESP32 ADC pin */
    #define ADC_ATTEN_SHIFT (MUX_ADC_CHANNEL * 2)

.bss
    /* Buffer 0 */
    .global adc_readings_0
adc_readings_0: 
    .skip 68   /* 17 elements * 4 bytes each */

    /* Buffer 1 */
    .global adc_readings_1
adc_readings_1: 
    .skip 68   

    /* Tracks which buffer the ULP is currently filling (0 or 1) */
    .global active_buffer
active_buffer:
    .long 0

    .global current_sequence_idx
current_sequence_idx: 
    .long 0

.text
    .global entry
entry:
    jump real_entry

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
    move r0, 0
    move r3, current_sequence_idx
    st r0, r3, 0

channel_loop:
    move r3, current_sequence_idx
    ld r2, r3, 0

    move r3, channel_sequence
    add r3, r3, r2
    ld r1, r3, 0

    /* ==========================================================
     * MUX Channel Selection
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

    /* ==========================================================
     * Dynamic ADC Attenuation Switching
     * ========================================================== */
set_attenuation:
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
     * 4x Oversampling
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

    rsh r1, r1, 2              

    /* ==========================================================
     * Write to Double Buffer
     * ========================================================== */
    move r3, active_buffer
    ld r0, r3, 0
    and r0, r0, 1
    jumpr write_buf_1, 1, ge   /* If active_buffer >= 1, jump to write_buf_1 */

write_buf_0:
    move r3, adc_readings_0
    jump do_write

write_buf_1:
    move r3, adc_readings_1

do_write:
    add r3, r3, r2              /* Add word offset (r2) */
    st r1, r3, 0

next_channel:
    add r2, r2, 1               
    move r3, current_sequence_idx
    st r2, r3, 0
    
    move r0, r2
    sub r0, r0, 17              
    jump exit, eq               
    jump channel_loop           

exit:
    /* Flip active_buffer (0 -> 1, 1 -> 0) */
    move r3, active_buffer
    ld r0, r3, 0
    add r0, r0, 1
    and r0, r0, 1
    st r0, r3, 0
    
    /* Wake the CPU. Notice wait_for_cpu is entirely removed. */
    wake

    jump entry