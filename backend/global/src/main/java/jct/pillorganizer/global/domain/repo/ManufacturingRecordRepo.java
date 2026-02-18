package jct.pillorganizer.global.domain.repo;

import jct.pillorganizer.global.domain.model.ManufacturingRecord;

import java.util.Optional;

public interface ManufacturingRecordRepo {
    Optional<ManufacturingRecord> get(String serialNumber);
}
