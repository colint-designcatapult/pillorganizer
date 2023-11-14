#include "pill_gpio.h"
#include "i2c_dev.h"
#include "IS31FL3730.h"
#include <string.h>
#include "event.h"
#include "engineering.h"
#include "nvs_wrapper.h"
#include "pill_state.h"
#include <esp_task_wdt.h>
#include "util.h"
#include "esp_timer.h"

static const char *TAG = "GPIO";

#define VDD_VOLTAGE(VDD) (VDD * 200 / 255)
esp_adc_cal_characteristics_t characteristics;

#define MUX_A_BIT  (0x08)
#define MUX_B_BIT  (0x04)
#define MUX_C_BIT  (0x02)
#define MUX_D_BIT  (0x01)
#define MUX_CHANNEL_COUNT (16)
#define MUX_CHANNEL_IS_BIN(x) (x < 14)


uint8_t channels[16] = {0x00, 0x08, 0x04, 0x0C, 0x02, 0x0A, 0x06, 0x0E, 0x01, 0x09, 0x05, 0x0D, 0x03, 0x0B, 0x07, 0x0F};
static uint8_t muxIndex = 0;
static uint8_t depthInddex = 0;
#define FILTER_LENGTH (8)
#define BATTERY_MUX_CHANNEL (14)
#define CHARGER_MUX_CHANNEL (15)
#define BATTERY_OFFSET      (200) //lost 200mV on Q4
#define VOLTAGE_RATIO       (1.4)
#define BATTERY_MAX_ADC     (3700)
#define BATTERY_MAX_CAL     (3700.0)

#define ESP_INTR_FLAG_DEFAULT (0)
#define READ_PORT(_x)                     (gpio_get_level(_x) == 0 ? true : false)

uint32_t adcChannels[MUX_CHANNEL_COUNT][FILTER_LENGTH] = { {0}, {0}, {0}, {0}, {0}, {0}, {0}, {0}, {0}, {0}, {0}, {0}, {0}, {0}, {0}, {0} };


uint32_t voltages[MUX_CHANNEL_COUNT] = {0};

static void fiveMsTimer_Run();
static void fiveSecondTimer_Run();
static void readAdcTimer_Run();
static void fiveMs_timer_init();
static void readAdc_timer_init();
static void twoHundredFiftyMsTimer_Run();
static void timers_init();

static esp_timer_handle_t pfiveMsTimer;
static esp_timer_handle_t p250MsTimer;
static esp_timer_handle_t preadAdcTimer;
static esp_timer_handle_t pfiveSecondTimer;
esp_timer_handle_t   pPgOnceShotTimerHandle = NULL;
esp_timer_handle_t   pChgOnceShotTimerHandle = NULL;

static void pg_debounce_cb(void *arg)
{
	//ESP_LOGI(TAG, "/PG Oneshot timer expire\n");
    if(READ_PORT(BAT_PGOOD_PIN) == true){
        //ESP_LOGI(TAG, "/PG signal Low, /CHG signal %d\n", gpio_get_level(BAT_CHARGE_PIN));
        //charger is plugged in, send the event to notify the app the charger is plugged in

        PowerStatusChangeEvent ev = {
            .battery_present = 1,
            .plugged_in = 1, //power plug in, charging undergoing
            .charging = 1
        };

        event_isr_post(POWER_EVENT_BASE, POWER_EVENT_PIN, &ev, sizeof(PowerStatusChangeEvent), NULL);
    }
    else {
    	//ESP_LOGI(TAG, "/PG signal High, /CHG signal %d\n", gpio_get_level(BAT_CHARGE_PIN));
        //charger is unplugged send the event to notify the app the charger is unplug

        PowerStatusChangeEvent ev = {
            .battery_present = 1,
            .plugged_in = 0, //power unplug, ignore the charging status
            .charging = 0
        };

        event_isr_post(POWER_EVENT_BASE, POWER_EVENT_PIN, &ev, sizeof(PowerStatusChangeEvent), NULL);
    }

    //delete the outstanding once shot timer handler
    if(pPgOnceShotTimerHandle != NULL)
    {
        ESP_ERROR_CHECK(esp_timer_delete( pPgOnceShotTimerHandle ));
        pPgOnceShotTimerHandle= NULL;
    }
}

static void IRAM_ATTR pg_gpio_isr_handler(void* arg) 
{ 
    //Setup oneshot 100ms timer
    const esp_timer_create_args_t oneshot_timer_args =
    {
        .callback = &pg_debounce_cb,
        .name     = "one-shot"
    };

    esp_timer_handle_t pg_oneshot_timer;
    ESP_ERROR_CHECK(esp_timer_create(&oneshot_timer_args, &pg_oneshot_timer));
	ESP_ERROR_CHECK(esp_timer_start_once(pg_oneshot_timer, 200 * 1000));	
    pPgOnceShotTimerHandle = pg_oneshot_timer;		
}

static void chg_debounce_cb(void *arg)
{
    //this one shot timer is called after oneshot timer expire
    //we only focus on the charger signal going high for fully charge battery
	//ESP_LOGI(TAG, "/CHG Oneshot timer expire\n");
   	//ESP_LOGI(TAG, "/CHG signal High trigger this \n");

    //this condition only true if the charger is still plug in
    //if the charger is unplug, don't update the information
    if(READ_PORT(BAT_PGOOD_PIN) == true){
        PowerBatteryLevelChangeEvent ev = {
            .battery_level = 100
        };

        event_isr_post(POWER_EVENT_BASE, POWER_EVENT_BATTERY_LEVEL_CHANGE, &ev, sizeof(PowerBatteryLevelChangeEvent), NULL);
    }

    //delete the outstanding once shot timer handler
    if(pChgOnceShotTimerHandle != NULL)
    {
        ESP_ERROR_CHECK(esp_timer_delete( pChgOnceShotTimerHandle ));
        pChgOnceShotTimerHandle= NULL;
    }
}

static void IRAM_ATTR chg_gpio_isr_handler(void* arg) 
{
    const esp_timer_create_args_t oneshot_timer_args =
    {
        .callback = &chg_debounce_cb,
        .name     = "one-shot"
    };

    esp_timer_handle_t chg_oneshot_timer;
    ESP_ERROR_CHECK(esp_timer_create(&oneshot_timer_args, &chg_oneshot_timer));
	ESP_ERROR_CHECK(esp_timer_start_once(chg_oneshot_timer, 200 * 1000));
    pChgOnceShotTimerHandle = chg_oneshot_timer;
}


static void fiveMs_timer_init()
{
    const esp_timer_create_args_t stArgsFiveMs = {
		            .callback = &fiveMsTimer_Run,
		            .name = "5MsTimer_task",
	};

    ESP_ERROR_CHECK(esp_timer_create(&stArgsFiveMs, &pfiveMsTimer));
	esp_timer_start_periodic(pfiveMsTimer, 5 * 1000); //5 * 1000 * 1us = 5ms    

    //Initialize the mux selection to channel 0
    
    muxIndex = (MUX_CHANNEL_COUNT - 1); //load 15 the 1st interrupt will set to 0
    depthInddex = (FILTER_LENGTH - 1); //load 7 the 1st interrupt will set to 0
}

static void twoHundredFifty_timer_init()
{
    const esp_timer_create_args_t stArgs250Ms = {
		.callback = &twoHundredFiftyMsTimer_Run,
		.name = "250MsTimer_task",
	};

    ESP_ERROR_CHECK(esp_timer_create(&stArgs250Ms, &p250MsTimer));
	esp_timer_start_periodic(p250MsTimer, 250 * 1000); //250 * 1000 * 1us = 250ms    
}

static void fiveSecond_timer_init()
{
    const esp_timer_create_args_t stArgsFiveSecond = {
		            .callback = &fiveSecondTimer_Run,
		            .name = "5SecondTimer_task",
	};

    ESP_ERROR_CHECK(esp_timer_create(&stArgsFiveSecond, &pfiveSecondTimer));
	esp_timer_start_periodic(pfiveSecondTimer, 5000 * 1000); //5000 * 1000 * 1us = 5s    
}

static void vbatMeasureOn()
{
    gpio_set_level(VBAT_MEAS_PIN, 1);
}

static void vbatMeasureOff()
{
    gpio_set_level(VBAT_MEAS_PIN, 0);
}


static void fiveMsTimer_Run()
{
    if(++muxIndex >= MUX_CHANNEL_COUNT)
    {
        muxIndex = 0;
    }

    if(muxIndex == 14)
    {
        //turn on the VBAT_Meas signal before the sampling
        vbatMeasureOn();
    }
    else
    {
        vbatMeasureOff();
    }


    gpio_set_level(MUX_PIN_A, ((channels[muxIndex] & MUX_A_BIT) == MUX_A_BIT));
    gpio_set_level(MUX_PIN_B, ((channels[muxIndex] & MUX_B_BIT) == MUX_B_BIT));
    gpio_set_level(MUX_PIN_C, ((channels[muxIndex] & MUX_C_BIT) == MUX_C_BIT));
    gpio_set_level(MUX_PIN_D, ((channels[muxIndex] & MUX_D_BIT) == MUX_D_BIT));

    esp_timer_start_once(preadAdcTimer, 2000); //read ADC after 2ms after the mux pins switched
}

static void fiveSecondTimer_Run()
{
    //update battery levels
    //Vbatt = (Vmux * 1.4 + 200) mV, assume 3700 is the max
    uint16_t Vmux = voltages[BATTERY_MUX_CHANNEL];
    uint16_t Vbatt = Vmux * VOLTAGE_RATIO + BATTERY_OFFSET;

    if(Vbatt > BATTERY_MAX_ADC) //cap at 3700
    {
        Vbatt = BATTERY_MAX_ADC;
    }

    PowerBatteryLevelChangeEvent stBatteryLevel;
    //battery percentage from 0mV to 3700mV 0% to 100%
    stBatteryLevel.battery_level = (uint8_t)( ((float)Vbatt * 1.0 / BATTERY_MAX_CAL) * 100.0); 
    //ESP_LOGI(TAG, "Batt Per:%d, %d, %d\n", Vmux, Vbatt, stBatteryLevel.battery_level);
    event_post(POWER_EVENT_BASE, POWER_EVENT_BATTERY_LEVEL_CHANGE, &stBatteryLevel, sizeof(stBatteryLevel), pdMS_TO_TICKS(10));            
}

static void twoHundredFiftyMsTimer_Run()
{
    // Push samples to event bus every 250ms
    BinEventSamples se;
    memcpy(se.samples, voltages, sizeof(voltages));
    event_post(BIN_EVENT_BASE, BIN_EVENT_SAMPLES, &se, sizeof(se), pdMS_TO_TICKS(10));            
}

static void readAdc_timer_init()
{
    //5ms periodically timer
    const esp_timer_create_args_t oneshot_timer_args = {
        .callback = &readAdcTimer_Run,
        .name = "Read-ADC"
    };

    ESP_ERROR_CHECK(esp_timer_create(&oneshot_timer_args, &preadAdcTimer));
}

static void readAdcTimer_Run()
{
    //gpio_set_level(TEST_LED_PIN, 1);

    if(++depthInddex >= FILTER_LENGTH)
    {
        depthInddex = 0;
    }

    uint32_t voltage;
    esp_adc_cal_get_voltage(ADC_CHAN_MUX, &characteristics, &voltage);

    adcChannels[muxIndex][depthInddex] = voltage;
    
    //gpio_set_level(TEST_LED_PIN, 0);
}

static void timers_init()
{
    fiveMs_timer_init();
    twoHundredFifty_timer_init();
    fiveSecond_timer_init();
    readAdc_timer_init();
}

void adc_read_task(void *arg)
{
    // Wait 100 ms so this task is registered most likely
    vTaskDelay(pdMS_TO_TICKS(100));

	adc1_config_width(ADC_WIDTH_BIT_12);
    //adc1_config_channel_atten(ADC_CHAN_VBAT_MEAS, ADC_ATTEN_DB_11);
    adc1_config_channel_atten(ADC_CHAN_MUX, ADC_ATTEN_DB_11);
    esp_adc_cal_characterize(ADC_UNIT_1, ADC_ATTEN_DB_11, ADC_WIDTH_BIT_12, V_REF, &characteristics);

    timers_init();

    uint16_t prev_bin_mask = 0;
    int reset_ctr = 0;
    //uint64_t last_sample = 0;

    for(;;) {   
        //this task is coming averagely about 115us
        esp_task_wdt_reset();
//gpio_set_level(TP47,1);
        if(gpio_get_level(RESET_BTN) == 0) {
            //gpio_set_level(TP16,1);
            if(reset_ctr++ >= 3) {
                //this only take about 490us
                //gpio_set_level(TP16,0);
                ESP_LOGI(TAG, "Reset Btn press execute nvs_factory_reset\n");
                nvs_factory_reset();
                engineering_restart(1000);
            }
        } else {
            reset_ctr = 0;
        }
        

        uint32_t sum = 0;
        uint32_t max = 0;

        for(uint8_t adcCh = 0; adcCh < MUX_CHANNEL_COUNT; adcCh++)
        {
            uint32_t adcAvgSum = 0;
                
            for(uint8_t depth = 0; depth < FILTER_LENGTH; depth++)
            {
                adcAvgSum += adcChannels[adcCh][depth];
            }


            uint32_t sample_voltage = adcAvgSum / FILTER_LENGTH; //average the sumation 
            voltages[adcCh] = sample_voltage; 

            // Add sample to sum/max calculation (if channel is a bin)
            if(MUX_CHANNEL_IS_BIN(adcCh)) {
                sum += sample_voltage;
                if(sample_voltage > max)
                    max = sample_voltage;
            }
        }

        //uint32_t vbat_meas = adc1_get_raw(ADC_CHAN_VBAT_MEAS);

        // Exclude max voltage from the average
        uint32_t avg = (sum - max) / (BIN_COUNT - 1);
        uint32_t thresh = avg * 2;

        uint16_t bin_mask = 0;
        
        for(bin_id_t bin = 0; bin < BIN_COUNT; bin++) {
            if(voltages[bin] > thresh || voltages[bin] > 1200) {
                #if GPIO_PRINT_BINS
                ESP_LOGI(TAG, "Bin %d voltage %lumV <--- TRIGGERED, T %lu", bin, voltages[bin], thresh);
                #endif
                bin_mask |= (1 << bin);
            } else {
                #if GPIO_PRINT_BINS
                ESP_LOGI(TAG, "\tBin %d voltage %dmV", bin, voltages[bin]);
                #endif
                bin_mask &= ~(1 << bin);
            }
        }

#if GPIO_PRINT_BINS
        ESP_LOGI(TAG, "\tChannel 14 voltage %dmV", voltages[14]);
        ESP_LOGI(TAG, "\tChannel 15 voltage %dmV", voltages[15]);
#endif
        if(prev_bin_mask != bin_mask) {
            BinEventBitmaskChanged bm = {
                .bitmask = bin_mask,
                .previous = prev_bin_mask
            };
            event_post(BIN_EVENT_BASE, BIN_EVENT_BITMASK_CHANGED, &bm, sizeof(bm), pdMS_TO_TICKS(10));
            prev_bin_mask = bin_mask;
        }
#if(0) //comment out this code to move to 5s
        uint64_t current_sample_time = esp_timer_get_time();
        uint64_t time_since_last_sample = current_sample_time - last_sample;

        // Push samples to event bus every 250ms
        if(time_since_last_sample > 250000) {
            //gpio_set_level(TP47,1);
            BinEventSamples se;
            memcpy(se.samples, voltages, sizeof(voltages));
            event_post(BIN_EVENT_BASE, BIN_EVENT_SAMPLES, &se, sizeof(se), pdMS_TO_TICKS(10));            

            last_sample = current_sample_time;
            //gpio_set_level(TP47,0);
        }
#endif

#if GPIO_PRINT_BINS
        ESP_LOGI(TAG, "\t ---- bin voltage poll complete (max observed= %dmV, average= %dmV, threshold= %dmV)", max, avg, thresh);
#endif

    }
}

/*
// Basically PWM fade setup
void ledc_fade_task(void *pvParameter)
{
	ledc_timer_config_t timer = {
		.duty_resolution = PWM_BITS,
		.freq_hz = PWM_FREQ,
		.speed_mode = PWM_MODE,
		.timer_num = PWM_TIMER,
		.clk_cfg = LEDC_AUTO_CLK,
	};

	ledc_timer_config(&timer);

	ledc_channel_config_t channel = {
		.channel = PWM_CHANNEL,
		.duty = 0,
		.gpio_num = PWM_PIN,
		.speed_mode = PWM_MODE,
		.timer_sel = PWM_TIMER,
	};

	ledc_channel_config(&channel);

	ledc_fade_func_install(0);

	for(;;) 
	{
		ledc_set_fade_with_time(PWM_MODE, PWM_CHANNEL, PWM_TEST_DUTY, LEDC_TEST_FADE_TIME);
    	ledc_fade_start(PWM_MODE, PWM_CHANNEL, LEDC_FADE_NO_WAIT);

		//ESP_LOGI(TAG, "Fade 1");
		vTaskDelay(1000 / portTICK_PERIOD_MS); // task blocking call, wait for fade

		ledc_set_fade_with_time(PWM_MODE, PWM_CHANNEL, 0, LEDC_TEST_FADE_TIME);
        ledc_fade_start(PWM_MODE, PWM_CHANNEL, LEDC_FADE_NO_WAIT);
        
		//ESP_LOGI(TAG, "Fade 2");
		vTaskDelay(1000 / portTICK_PERIOD_MS); // task blocking call, wait for fade
    }
}
*/

void IS31FL3730_task(void *pvParameter)
{

    for(;;) {
        i2c_write_register(ISSI_ADDR, MWFU_R_AM, 0);
        i2c_write_register(ISSI_ADDR, MWFU_R_PM, 0);
        i2c_write_register(ISSI_ADDR, TRS_R_PM, 0);
        i2c_write_register(ISSI_ADDR, TRS_R_AM, 0);

        i2c_write_register(ISSI_ADDR, MWFU_G_AM, 127);
        i2c_write_register(ISSI_ADDR, MWFU_G_PM, 127);
        i2c_write_register(ISSI_ADDR, TRS_G_PM, 127);
        i2c_write_register(ISSI_ADDR, TRS_G_AM, 127);
        i2c_write_register(ISSI_ADDR, ISSI_REG_UPDATE, 0x00);
        vTaskDelay(pdMS_TO_TICKS(1000));

        i2c_write_register(ISSI_ADDR, MWFU_R_AM, 127);
        i2c_write_register(ISSI_ADDR, MWFU_R_PM, 127);
        i2c_write_register(ISSI_ADDR, TRS_R_PM, 127);
        i2c_write_register(ISSI_ADDR, TRS_R_AM, 127);
        i2c_write_register(ISSI_ADDR, ISSI_REG_UPDATE, 0x00);
        vTaskDelay(pdMS_TO_TICKS(1000));

        i2c_write_register(ISSI_ADDR, MWFU_G_AM, 0);
        i2c_write_register(ISSI_ADDR, MWFU_G_PM, 0);
        i2c_write_register(ISSI_ADDR, TRS_G_PM, 0);
        i2c_write_register(ISSI_ADDR, TRS_G_AM, 0);
        i2c_write_register(ISSI_ADDR, ISSI_REG_UPDATE, 0x00);
        vTaskDelay(pdMS_TO_TICKS(1000));

    }
}

void init_gpio(void)
{
    gpio_config_t io_conf = {};
/*    
	// HEART_LED_PIN

    io_conf.intr_type = GPIO_INTR_DISABLE;
    io_conf.mode = GPIO_MODE_OUTPUT;
    io_conf.pin_bit_mask = (1ULL << HEART_LED_PIN);
    io_conf.pull_down_en = 0;
    io_conf.pull_up_en = 0;  
    gpio_config(&io_conf);
*/
	// DAC on pin 25 - range is 0-255
	//esp_err_t dac_i2s_enable();
	//dac_output_enable(DAC_CHANNEL_1);
    //dac_output_voltage(DAC_CHANNEL_1, 50);

	// MUX_PIN_A
    memset(&io_conf, 0, sizeof(io_conf));
    io_conf.intr_type = GPIO_INTR_DISABLE;
    io_conf.mode = GPIO_MODE_OUTPUT;
    io_conf.pin_bit_mask = (1ULL << MUX_PIN_A);
    io_conf.pull_down_en = 0;
    io_conf.pull_up_en = 0;  
    gpio_config(&io_conf);

	// MUX_PIN_B
	memset(&io_conf, 0, sizeof(io_conf));
	io_conf.intr_type = GPIO_INTR_DISABLE;
    io_conf.mode = GPIO_MODE_OUTPUT;
    io_conf.pin_bit_mask = (1ULL << MUX_PIN_B);
    io_conf.pull_down_en = 0;
    io_conf.pull_up_en = 0;  
    gpio_config(&io_conf);

	// MUX_PIN_C
	memset(&io_conf, 0, sizeof(io_conf));
	io_conf.intr_type = GPIO_INTR_DISABLE;
    io_conf.mode = GPIO_MODE_OUTPUT;
    io_conf.pin_bit_mask = (1ULL << MUX_PIN_C);
    io_conf.pull_down_en = 0;
    io_conf.pull_up_en = 0;  
    gpio_config(&io_conf);

	// MUX_PIN_D
	memset(&io_conf, 0, sizeof(io_conf));
	io_conf.intr_type = GPIO_INTR_DISABLE;
    io_conf.mode = GPIO_MODE_OUTPUT;
    io_conf.pin_bit_mask = (1ULL << MUX_PIN_D);
    io_conf.pull_down_en = 0;
    io_conf.pull_up_en = 0;  
    gpio_config(&io_conf);

    // TEST POINTS
	memset(&io_conf, 0, sizeof(io_conf));
	io_conf.intr_type = GPIO_INTR_DISABLE;
    io_conf.mode = GPIO_MODE_OUTPUT;
    io_conf.pin_bit_mask = ((1ULL << TP47)|(1ULL << VBAT_MEAS_PIN)|(1ULL << TP18));
    io_conf.pull_down_en = 0;
    io_conf.pull_up_en = 0;  
    gpio_config(&io_conf);

	// BAT_PGOOD_PIN
	memset(&io_conf, 0, sizeof(io_conf));
	io_conf.intr_type = GPIO_INTR_ANYEDGE;
    io_conf.mode = GPIO_MODE_INPUT;
    io_conf.pin_bit_mask = (1ULL << BAT_PGOOD_PIN);
    io_conf.pull_down_en = 0;
    io_conf.pull_up_en = 1;  
    gpio_config(&io_conf);

	// BAT_CHARGE_PIN
	memset(&io_conf, 0, sizeof(io_conf));
	io_conf.intr_type = GPIO_INTR_POSEDGE;
    io_conf.mode = GPIO_MODE_INPUT;
    io_conf.pin_bit_mask = (1ULL << BAT_CHARGE_PIN);
    io_conf.pull_down_en = 0;
    io_conf.pull_up_en = 1;  
    gpio_config(&io_conf);

    // IS31 CS
    memset(&io_conf, 0, sizeof(io_conf));
	io_conf.intr_type = GPIO_INTR_DISABLE;
    io_conf.mode = GPIO_MODE_OUTPUT;
    io_conf.pin_bit_mask = (1ULL << IS31_CS);
    io_conf.pull_down_en = 0;
    io_conf.pull_up_en = 0;  
    gpio_config(&io_conf);
    // Hold this at high
    gpio_set_level(IS31_CS, 1);

    // Reset Button
	memset(&io_conf, 0, sizeof(io_conf));
	io_conf.intr_type = GPIO_INTR_DISABLE;
    io_conf.mode = GPIO_MODE_INPUT;
    io_conf.pin_bit_mask = (1ULL << RESET_BTN);
    io_conf.pull_down_en = 0;  
    gpio_config(&io_conf);


    // I2C stuff
    esp_err_t ret = i2c_master_init(I2C_FREQ);
    ESP_LOGI(TAG, "i2c_master_init(): %x", ret);

    IS31FL3730_init();
    IS31FL3730_set_brightness(127);

    // for testing only
    //xTaskCreate(&IS31FL3730_task, "flash LED task", 2048, NULL, 1, NULL);

    
    // GPIO event queue obsoleted - push directly into event bus
	/*gpio_evt_queue = xQueueCreate(10, sizeof(uint32_t));
	xTaskCreate(gpio_isr_task, "gpio_isr_task", 2048, NULL, 2, NULL);*/
	
    gpio_install_isr_service( ESP_INTR_FLAG_DEFAULT );
    
    //set up isr for power good charger cable plug/unplug
    gpio_isr_handler_add(BAT_PGOOD_PIN, pg_gpio_isr_handler, (void*) BAT_PGOOD_PIN);

    //set up isr for charger complete/not complete
	gpio_isr_handler_add(BAT_CHARGE_PIN, chg_gpio_isr_handler, (void*) BAT_CHARGE_PIN);

    create_task_with_watchdog(led_task, "LED Task", 4096, NULL, 1);    
}

special_led_effect led_effect = LED_EFFECT_NORMAL;
int led_effect_ticks = 0;


void led_set_effect(special_led_effect effect, int ticks) {
    led_effect = effect;
    led_effect_ticks = ticks;
}

void led_task(void* arg)
{
    uint16_t g_am_mwfu_mask = 0;
    uint16_t g_am_trs_mask = 0;
    uint16_t g_pm_mwfu_mask = 0;
    uint16_t g_pm_trs_mask = 0;
    uint16_t r_am_mwfu_mask = 0;
    uint16_t r_am_trs_mask = 0;
    uint16_t r_pm_mwfu_mask = 0;
    uint16_t r_pm_trs_mask = 0;

    for(;;) {
        esp_task_wdt_reset();

        if(led_effect == LED_EFFECT_NORMAL) {
            const bin_state_t* st = state_acquire_ro();

            for(bin_id_t bin = 0; bin < BIN_COUNT; bin++) {
                uint16_t* g_mask = 0, *r_mask = 0;
                uint16_t idx = 0;
    #pragma GCC diagnostic push
    #pragma GCC diagnostic ignored "-Wimplicit-fallthrough"
                switch(bin) {
                    case BIN_SUN_AM:
                        idx++;
                    case BIN_FRI_AM:
                        idx++;
                    case BIN_WED_AM:
                        idx++;
                    case BIN_MON_AM:
                        g_mask = &g_am_mwfu_mask;
                        r_mask = &r_am_mwfu_mask;
                        break;
                    case BIN_SUN_PM:
                        idx++;
                    case BIN_FRI_PM:
                        idx++;
                    case BIN_WED_PM:
                        idx++;
                    case BIN_MON_PM:
                        g_mask = &g_pm_mwfu_mask;
                        r_mask = &r_pm_mwfu_mask;
                        break;
                    case BIN_SAT_AM:
                        idx++;
                    case BIN_THU_AM:
                        idx++;
                    case BIN_TUE_AM:
                        g_mask = &g_am_trs_mask;
                        r_mask = &r_am_trs_mask;
                        break;
                    case BIN_SAT_PM:
                        idx++;
                    case BIN_THU_PM:
                        idx++;
                    case BIN_TUE_PM:
                        g_mask = &g_pm_trs_mask;
                        r_mask = &r_pm_trs_mask;
                        break;
                }
    #pragma GCC diagnostic pop
                bin_status_t state = st[bin].status;
                if(state == BIN_TAKE_NOW) {


                    *g_mask ^= (1 << idx);
                    *r_mask &= ~(1 << idx);
                } else if(state == BIN_TAKEN) {
                    *g_mask |= (1 << idx);
                    *r_mask &= ~(1 << idx);
                } else if(state == BIN_MISSED) {
                    *r_mask |= (1 << idx);
                    *g_mask &= ~(1 << idx);
                } else {
                    *g_mask &= ~(1 << idx);
                    *r_mask &= ~(1 << idx);
                }
            }

            state_release_ro(st);
        } else if(led_effect == LED_EFFECT_HOLD_GREEN) {

            int mask = 0xffff;

            r_pm_mwfu_mask = 0;
            r_am_mwfu_mask = 0;
            r_pm_trs_mask  = 0;
            r_am_trs_mask  = 0;

            g_pm_mwfu_mask = mask;
            g_am_mwfu_mask = mask;
            g_pm_trs_mask  = mask;
            g_am_trs_mask  = mask;
            
        }
        else if(led_effect == LED_EFFECT_HOLD_RED) {

            int mask = 0xffff;

            g_pm_mwfu_mask = 0;
            g_am_mwfu_mask = 0;
            g_pm_trs_mask = 0;
            g_am_trs_mask = 0;

            r_pm_mwfu_mask = mask;
            r_am_mwfu_mask = mask;
            r_pm_trs_mask = mask;
            r_am_trs_mask = mask;
            
        }
        else {
            if(led_effect == LED_EFFECT_FLASH_GREEN || led_effect == LED_EFFECT_FLASH_GREEN_AND_RED) {
                int mask = led_effect_ticks % 2 == 0 ? 0xffff : 0;
                r_pm_mwfu_mask = 0;
                r_am_mwfu_mask = 0;
                r_pm_trs_mask = 0;
                r_am_trs_mask = 0;

                g_pm_mwfu_mask = mask;
                g_am_mwfu_mask = mask;
                g_pm_trs_mask = mask;
                g_am_trs_mask = mask;

                if(led_effect == LED_EFFECT_FLASH_GREEN_AND_RED && led_effect_ticks <= 8) {
                    led_effect = LED_EFFECT_FLASH_RED;
                }

            } else if(led_effect == LED_EFFECT_FLASH_RED) {
                //ESP_LOGI(TAG, "Turn Red LEDs on");
                int mask = led_effect_ticks % 2 == 0 ? 0xffff : 0;
                g_pm_mwfu_mask = 0;
                g_am_mwfu_mask = 0;
                g_pm_trs_mask = 0;
                g_am_trs_mask = 0;

                r_pm_mwfu_mask = mask;
                r_am_mwfu_mask = mask;
                r_pm_trs_mask = mask;
                r_am_trs_mask = mask;
            }

            led_effect_ticks--;

            if(led_effect_ticks <= 0) {
                led_effect = LED_EFFECT_NORMAL;
                led_effect_ticks = 0;
            }
        }

        i2c_write_register(ISSI_ADDR, MWFU_G_PM, g_pm_mwfu_mask);
        i2c_write_register(ISSI_ADDR, MWFU_G_AM, g_am_mwfu_mask);
        i2c_write_register(ISSI_ADDR, TRS_G_PM, g_pm_trs_mask);                            
        i2c_write_register(ISSI_ADDR, TRS_G_AM, g_am_trs_mask);
        i2c_write_register(ISSI_ADDR, MWFU_R_PM, r_pm_mwfu_mask);
        i2c_write_register(ISSI_ADDR, MWFU_R_AM, r_am_mwfu_mask);
        i2c_write_register(ISSI_ADDR, TRS_R_PM, r_pm_trs_mask);                            
        i2c_write_register(ISSI_ADDR, TRS_R_AM, r_am_trs_mask);

        i2c_write_register(ISSI_ADDR, ISSI_REG_UPDATE, 0x00);    
        vTaskDelay(pdMS_TO_TICKS(500));
    }
}
