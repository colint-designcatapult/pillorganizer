package jct.pillorganizer.tenant.service;

import io.micronaut.core.type.Argument;
import io.micronaut.json.JsonMapper;
import jakarta.inject.Singleton;
import lombok.extern.flogger.Flogger;

import java.io.IOException;
import java.io.InputStream;
import java.util.Map;

/**
 * Converts IANA timezone identifiers (e.g. {@code America/New_York}) to
 * POSIX TZ strings (e.g. {@code EST5EDT,M3.2.0,M11.1.0}) using the
 * nayarsystems/posix_tz_db lookup table bundled in resources.
 */
@Singleton
@Flogger
public class TimezoneService {

    private final Map<String, String> zones;

    public TimezoneService(JsonMapper objectMapper) {
        try (InputStream is = TimezoneService.class.getResourceAsStream("/posix_tz_db.json")) {
            if (is == null) {
                throw new IllegalStateException("posix_tz_db.json not found in classpath");
            }
            zones = objectMapper.readValue(is.readAllBytes(), Argument.mapOf(String.class, String.class));
            log.atInfo().log("Loaded %d IANA timezone entries", zones.size());
        } catch (IOException e) {
            throw new IllegalStateException("Failed to load POSIX TZ database", e);
        }
    }

    /**
     * Converts an IANA timezone string to its POSIX TZ equivalent.
     *
     * @param ianaTimezone the IANA timezone identifier (e.g. {@code America/Los_Angeles})
     * @return the POSIX TZ string (e.g. {@code PST8PDT,M3.2.0,M11.1.0})
     * @throws IllegalArgumentException if the timezone is null, blank, or not found in the database
     */
    public String toPosix(String ianaTimezone) {
        if (ianaTimezone == null || ianaTimezone.isBlank()) {
            throw new IllegalArgumentException("Timezone must not be null or blank");
        }
        String posix = zones.get(ianaTimezone);
        if (posix == null) {
            throw new IllegalArgumentException("Unknown IANA timezone: " + ianaTimezone);
        }
        return posix;
    }
}
