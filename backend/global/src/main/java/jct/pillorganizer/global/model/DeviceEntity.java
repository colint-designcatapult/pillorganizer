package jct.pillorganizer.global.model;

import lombok.*;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbAttribute;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbFlatten;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbImmutable;

import java.time.Instant;

@Value
@Builder
@DynamoDbImmutable(builder = DeviceEntity.DeviceEntityBuilder.class)
public class DeviceEntity {

    @Getter(onMethod_ = {@DynamoDbFlatten})
    BaseControlPlaneEntity base;

    @Getter(onMethod_ = @DynamoDbAttribute("DeviceId"))
    String deviceId;

    @Getter(onMethod_ = @DynamoDbAttribute("SerialNumber"))
    String serialNumber;

    @Getter(onMethod_ = @DynamoDbAttribute("ModelId"))
    String modelId;

    @Getter(onMethod_ = @DynamoDbAttribute("BootstrapKey"))
    String bootstrapKey;

    @Getter(onMethod_ = @DynamoDbAttribute("ProvisioningStatus"))
    ProvisioningStatus provisioningStatus;

    @Getter(onMethod_ = @DynamoDbAttribute("TenantId"))
    String tenantId;

    public static String pk(String deviceId) {
        return "DEVICE#" + deviceId;
    }

    public static String sk() {
        return "METADATA";
    }

    public static String gsi1Pk(String tenantId) {
        return "TENANT#" + tenantId;
    }

    public static String gsi1Sk(String deviceId) {
        return "DEVICE#" + deviceId;
    }

    public static String gsi2Pk(String serialNumber) {
        return "SN#" + serialNumber;
    }

    public static String gsi2Sk(String deviceId) {
        return "DEVICE#" + deviceId;
    }

    public static BaseControlPlaneEntity buildBase(String deviceId, String serialNumber, String tenantId) {
        var builder = BaseControlPlaneEntity.builder()
                .pk(pk(deviceId))
                .sk(sk())
                .entityType(DeviceControlPlaneEntityType.DEVICE)
                .gsi2Pk(gsi2Pk(serialNumber))
                .gsi2Sk(gsi2Sk(deviceId))
                .createdAt(Instant.now())
                .lastModified(Instant.now());

        if(tenantId != null) {
            builder.gsi1Pk(gsi1Pk(tenantId))
                    .gsi1Sk(gsi1Sk(deviceId));

        }
        return builder.build();
    }

    public static BaseControlPlaneEntity buildBase(String deviceId, String serialNumber) {
        return buildBase(deviceId, serialNumber, null);
    }

}
