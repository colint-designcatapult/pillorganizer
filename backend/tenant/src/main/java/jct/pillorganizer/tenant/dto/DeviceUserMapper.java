package jct.pillorganizer.tenant.dto;

import io.micronaut.context.annotation.Mapper;
import jakarta.inject.Singleton;

@Singleton
public interface DeviceUserMapper {
    @Mapper.Mapping(to = "id", from = "deviceId")
    @Mapper.Mapping(to = "customName", from = "nickname")
    DeviceUserDTO toDTO(DeviceUserProjection projection);
}
