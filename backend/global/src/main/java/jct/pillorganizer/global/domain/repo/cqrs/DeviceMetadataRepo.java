package jct.pillorganizer.global.domain.repo.cqrs;

import jct.pillorganizer.global.domain.model.view.DeviceMetadataView;

import java.util.Optional;

public interface DeviceMetadataRepo {
    Optional<DeviceMetadataView> findBySerialNumber(String serialNumber);
}
