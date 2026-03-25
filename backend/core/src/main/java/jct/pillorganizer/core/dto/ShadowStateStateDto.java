package jct.pillorganizer.core.dto;

import io.micronaut.serde.annotation.Serdeable;

@Serdeable
public record ShadowStateStateDto<T>(
        T desired,
        T reported,
        T delta
) {
}
