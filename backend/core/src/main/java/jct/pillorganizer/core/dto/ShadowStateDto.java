package jct.pillorganizer.core.dto;

import io.micronaut.serde.annotation.Serdeable;

@Serdeable
public record ShadowStateDto<T>(ShadowStateStateDto<T> state, Integer version) {
}
