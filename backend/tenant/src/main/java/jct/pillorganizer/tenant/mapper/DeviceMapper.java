package jct.pillorganizer.tenant.mapper;

import io.micronaut.context.annotation.Mapper;
import jct.pillorganizer.core.TenantDetails;
import jct.pillorganizer.core.dto.DeviceAccessDto;
import jct.pillorganizer.tenant.model.device.DeviceUser;

public interface DeviceMapper {

    @Mapper.Mapping(to = "id", from = "#{deviceUser.device.id}")
    @Mapper.Mapping(to = "nickname", from = "#{deviceUser.device.nickname}")
    @Mapper.Mapping(to = "deviceId", from = "#{deviceUser.device.physicalDevice.deviceId}")
    @Mapper.Mapping(to = "serialNo", from = "#{deviceUser.device.physicalDevice.serialNo}")
    @Mapper.Mapping(to = "modelId", from = "#{deviceUser.device.physicalDevice.deviceClass}")
    DeviceAccessDto toAccessDTO(DeviceUser deviceUser, TenantDetails tenantDetails);

}
