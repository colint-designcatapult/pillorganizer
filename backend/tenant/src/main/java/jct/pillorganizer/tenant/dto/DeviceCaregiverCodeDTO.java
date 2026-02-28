package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;

@Introspected
@Serdeable.Serializable
@Serdeable.Deserializable
public record DeviceCaregiverCodeDTO(long id, String patientID, String deviceID, long code, long expiresAt, boolean deleted) {
}
