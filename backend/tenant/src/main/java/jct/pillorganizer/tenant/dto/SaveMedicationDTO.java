package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.tenant.model.medication.MedicationShape;

import java.util.Set;

@Introspected
@Serdeable.Deserializable
@Serdeable.Serializable
public record SaveMedicationDTO(@Nullable Long id, String name, MedicationShape shape, long color, Set<Long> dispenseTimes) {
}
