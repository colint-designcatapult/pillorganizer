# Battery Subsystem Architecture & Implementation

This document outlines the design and operation of the battery management subsystem, addressing the constraints of the hardware defect and the specific behaviors of the BQ24074 charging IC.

## 1. Background & Hardware Constraints

Due to a hardware/PCB defect, battery voltage monitoring is compromised. 
* **ADC Saturation**: The battery pin (routed through MUX Channel 14) saturates the ADC at `4095` until the true battery voltage drops to approximately `3.55V`. By this point, the battery capacity is already depleted to critically low levels (5-10%).
* **Floating Pin Behavior**: When no battery is connected, the BQ24074 charger IC outputs a ~2 Hz square wave on both the battery terminal and the `/CHG` (charge indicator) pin.
* **Crosstalk**: The 2 Hz pulse on the battery terminal induces massive analog cross-talk across the MUX, risking false triggers on the door sensors if not mitigated.
* **VBUS Monitoring**: Scaled USB voltage is read via MUX Channel 15 (5V translates to ~0.6V at the ADC).

> [!WARNING]
> Because of ADC saturation, the firmware cannot provide a linear 0-100% battery percentage. Instead, it relies on discrete thresholds to protect the device from brownouts.

## 2. Voltage Acquisition & ULP Synchronization

The Deep Sleep ULP (Ultra Low Power) co-processor polls the MUX array. In each cycle, it captures an array of 17 readings.
* `local_buffer[0]` (`bat_start`): The battery pin reading at the *start* of the MUX scan.
* `local_buffer[16]` (`bat_end`): The battery pin reading at the *end* of the MUX scan.
* `local_buffer[15]` (`vbus`): The VBUS voltage level.

Taking two battery readings at opposite ends of the scan cycle makes the firmware more resilient against missing a low-edge of the 2 Hz square wave during execution.

## 3. Determining Battery Presence

Because of the 2 Hz square wave when unpopulated, the system implements a dual-verification strategy to distinguish a real battery from a floating pin:

### A. ADC Edge Detection
A real Li-Po battery delivers a stable continuous voltage. The square wave constantly drops to near zero.
* **Disconnect Detection**: If either `bat_start` or `bat_end` falls below `BAT_PULSE_ADC_THRESHOLD` (1500), it confirms the 2 Hz wave is present. The state is immediately forced to `BATTERY_PRESENCE_DISCONNECTED`.
* **Connect Debouncing**: If both readings remain high for 5 consecutive ULP cycles (`BAT_CONSECUTIVE_HIGHS_FOR_CONNECTED`), the system presumes a battery might be attached.

### B. USB Supply Interference & /CHG Pin Verification
If USB is connected (`VBUS > 500`), the 5V rail can keep the MUX ADC artificially high, blinding the ADC edge detection. Thus, if the system thinks the battery is disconnected while USB is plugged in, it **will not** auto-recover to a `CONNECTED` state purely via the ADC.

Instead, the system relies on the `/CHG` interrupt logic (in `battery_submit_charge_pin`):
* **Square Wave Bouncing**: If the `/CHG` pin toggles faster than 1 second apart, a bounce counter increments. 4 rapid toggles confirm there is no battery.
* **Stabilization**: If the pin settles for more than 2 seconds, the bounce history is cleared. If the system previously marked the battery as missing, this stable period allows it to safely transition back to `CONNECTED`.

## 4. Mitigating Analog Crosstalk (Door Protection)

When no battery is populated, the high phase of the 2 Hz pulse bleeds into the adjacent MUX channels. This would normally corrupt the Exponential Moving Average (EMA) and Mean Absolute Deviation (MAD) logic that dictates if a door is OPEN or CLOSED.

**The Fix (`mux_io.c`):**
```c
if (battery_get_presence() == BATTERY_PRESENCE_DISCONNECTED && (bat_start_val > 1500 || bat_end_val > 1500)) {
    // Throw away these ULP reads so they don't corrupt the EMA/MAD door baselines.
    return wake_flags; 
}
```
If the system knows there's no battery, and it's currently observing the peak of the square wave, it aborts the door evaluation loop entirely for that cycle.

## 5. Battery Level Decoding & Debouncing

When a valid battery is seated, the ADC is evaluated to assess remaining capacity:

* `>= 4095` (`BAT_LEVEL_FULL`): The voltage is > 3.55V. The battery has healthy capacity.
* `>= 3900` (`BAT_LEVEL_CRITICAL`): The voltage is <= 3.55V but > 3.45V. Only ~5% capacity remains.
* `< 3900` (`BAT_LEVEL_SHUTOFF`): The voltage is dangerously low (<= 3.45V). The system must enter hibernation/deep sleep immediately to prevent cell damage.

> [!IMPORTANT]  
> All level transitions require **10 consecutive identical readings** (`BAT_CONSECUTIVE_READINGS_FOR_LEVEL`) before being applied. This heavily debounces the signals, preventing brief voltage sags (like turning on Wi-Fi or LEDs) from accidentally triggering a system shut-off.

## 6. Interrupt Handling & Event Propagation

The system reacts dynamically to charging state shifts:
1. `main.c` registers hardware ISRs (`gpio_isr_handler_add`) for the active-low `BAT_CHARGE_PIN` and `BAT_PGOOD_PIN`.
2. The ISRs defer processing to a dedicated FreeRTOS task via a queue to minimize interrupt latency.
3. The background task calls `battery_submit_charge_pin()` and `battery_submit_pgood_pin()`.
4. If `battery.c` determines that either the real charge state, power-good state, battery level, or battery presence changed, it pushes an `EVENT_BATTERY_CHANGE` to the central supervisor.

Because the battery state is structured as an `RTC_DATA_ATTR`, it survives deep sleep, ensuring the tracking (and presence debouncing) continues seamlessly across waking cycles.
