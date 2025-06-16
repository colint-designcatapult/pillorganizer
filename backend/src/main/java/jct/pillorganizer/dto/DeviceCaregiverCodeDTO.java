package jct.pillorganizer.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;

import java.sql.Timestamp;

@Introspected
@Serdeable.Serializable
@Serdeable.Deserializable
public record DeviceCaregiverCodeDTO(long id, long patientID, long deviceID, long code, Timestamp expiresAt, boolean deleted) {
}
