package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;

@Serdeable
public record ShadowStateStateDTO(@Nullable Object desired, @Nullable Object reported, @Nullable Object delta) {
}
