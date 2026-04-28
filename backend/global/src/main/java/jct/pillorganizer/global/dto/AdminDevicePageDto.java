package jct.pillorganizer.global.dto;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;

import java.util.List;

@Serdeable.Serializable
public record AdminDevicePageDto(
        List<AdminDeviceSummaryDto> items,
        @Nullable String nextCursor
) {}

