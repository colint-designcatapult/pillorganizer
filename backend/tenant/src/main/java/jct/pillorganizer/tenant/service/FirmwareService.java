package jct.pillorganizer.tenant.service;

import io.micronaut.context.annotation.Bean;

/**
 * Firmware service
 */
@Bean
public class FirmwareService {

    /**
     * Returns the latest version of the CabiNET firmware.
     * @return latest version of the CabiNET firmware, as an integer.
     */
    public int getLatestVersion() {
        return 34;  // Changed to trigger OTA update
    }

}
