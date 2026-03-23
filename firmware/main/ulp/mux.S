/*
 * ULP Assembly to poll channels via a CD4067B MUX
 * Sequence: Ch14, Ch0-13, Ch15, Ch14 (17 samples total)
 * Features 4x oversampling and DYNAMIC ATTENUATION.
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
    .global adc_readings
adc_readings: 
    .skip 68   /* 17 elements * 4 bytes each */

    /* --- ADD THESE FOR THE RESET CHECK --- */
    .global button_counter
button_counter:
    .long 0

    .global reset_flag
reset_flag:
    .long 0
    /* ------------------------------------- */

    .global current_sequence_idx
current_sequence_idx: 
    .long 0

    .global data_ready
data_ready:
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
    /* ==========================================================
     * Reset Button Check (GPIO36 / RTC_GPIO0) - ONCE PER WAKEUP
     * ========================================================== */
    /* Read the state of GPIO36. The 1-bit result goes into R0. */
    READ_RTC_REG(RTC_GPIO_IN_REG, RTC_GPIO_IN_NEXT_S + 0, 1)

    /* If R0 >= 1 (Button is High/Unpressed), reset the streak counter */
    jumpr reset_streak, 1, ge

    /* Button is Low (Pressed). Load counter. */
    move r3, button_counter
    ld r0, r3, 0
    
    /* Cap the counter at 2 so it doesn't overflow during a long hold */
    jumpr skip_inc, 2, ge
    add r0, r0, 1
    st r0, r3, 0

skip_inc:
    /* Require 2 consecutive Low reads (~340ms) to declare a solid press */
    jumpr button_done, 2, lt

    /* SOLID PRESS DETECTED! Set flag. */
    move r3, reset_flag
    move r0, 1
    st r0, r3, 0
    jump button_done

reset_streak:
    /* Button released: Clear counter and flag */
    move r3, button_counter
    move r0, 0
    st r0, r3, 0
    
    move r3, reset_flag
    move r0, 0
    st r0, r3, 0

button_done:
    /* ==========================================================
     * Start the 17-Channel MUX Sequence
     * ========================================================== */
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
    move r0, r1                  /* Copy target MUX channel into r0 */
    sub r0, r0, 14               /* Is it channel 14? */
    jump set_atten_11db, eq      /* If yes, jump to 11dB config */

set_atten_0db:
    /* For all other channels, set ADC attenuation to 0dB (Write '0') */
    WRITE_RTC_REG(SENS_SAR_ATTEN1_REG, ADC_ATTEN_SHIFT, 2, 0)
    jump read_adc

set_atten_11db:
    /* For Channel 14, set ADC attenuation to 11dB (Write '3') */
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

    move r3, adc_readings
    add r3, r3, r2              
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
    move r3, data_ready
    move r0, 1
    st r0, r3, 0
    
    wake

wait_for_cpu:
    move r3, data_ready
    ld r0, r3, 0
    jumpr wait_for_cpu, 1, ge  

    jump entry