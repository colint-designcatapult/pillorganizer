package jct.pillorganizer.global.domain.model;

public record ManufacturingRecord(
        String serialNumber,
        String modelId,
        String bootstrapKey,
        String manufacturingDate,
        long version
) {
}
