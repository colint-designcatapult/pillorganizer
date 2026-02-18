package jct.pillorganizer.global.domain.model.view;

import jct.pillorganizer.global.domain.model.Device;
import jct.pillorganizer.global.domain.model.ManufacturingRecord;

public record DeviceMetadataView(
        ManufacturingRecord manufacturingRecord,
        Device device
) {
}
