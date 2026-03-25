package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;

@Serdeable
public record ShadowStateDTO(@Nullable Integer version, @Nullable Integer timestamp, ShadowStateStateDTO state) {
}
