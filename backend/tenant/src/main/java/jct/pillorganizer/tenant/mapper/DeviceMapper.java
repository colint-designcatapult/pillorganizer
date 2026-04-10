package jct.pillorganizer.tenant.mapper;

import io.micronaut.context.annotation.Mapper;
import jct.pillorganizer.core.TenantDetails;
import jct.pillorganizer.core.dto.DeviceAccessDto;
import jct.pillorganizer.tenant.model.device.DeviceUser;

public interface DeviceMapper {

    /*
            String deviceId,
        String claimId,
        String nickname,
        String serialNo,
        String modelId,
        String tenantId,
        String apiBase,
        boolean primaryUser,
        String thingName
        String tenantName
     */
    @Mapper.Mapping(to = "deviceId", from = "#{deviceUser.device.id}")
    @Mapper.Mapping(to = "claimId", from = "#{deviceUser.device.physicalDevice?.claimId}")
    @Mapper.Mapping(to = "nickname", from = "#{deviceUser.device.nickname}")
    @Mapper.Mapping(to = "serialNo", from = "#{deviceUser.device.physicalDevice?.serialNo}")
    @Mapper.Mapping(to = "modelId", from = "#{deviceUser.device.physicalDevice?.deviceClass}")
    @Mapper.Mapping(to = "tenantId", from = "#{tenantDetails.id}")
    @Mapper.Mapping(to = "apiBase", from = "#{tenantDetails.apiBase}")
    @Mapper.Mapping(to = "primaryUser", from = "#{deviceUser.primaryUser}")
    @Mapper.Mapping(to = "thingName", from = "#{deviceUser.device.physicalDevice?.thingName}")
    @Mapper.Mapping(to = "tenantName", from = "#{tenantDetails.name}")
    @Mapper.Mapping(to = "notifications", from = "#{deviceUser.subscriptionArn != null}")
    DeviceAccessDto toAccessDTO(DeviceUser deviceUser, TenantDetails tenantDetails);

}
