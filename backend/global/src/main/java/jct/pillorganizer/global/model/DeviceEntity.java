package jct.pillorganizer.global.model;

import lombok.*;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbAttribute;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbFlatten;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbImmutable;

import java.time.Instant;

@Value
@Builder(toBuilder = true)
@DynamoDbImmutable(builder = DeviceEntity.DeviceEntityBuilder.class)
public class DeviceEntity {

    @Getter(onMethod_ = {@DynamoDbFlatten})
    BaseControlPlaneEntity base;

    @Getter(onMethod_ = @DynamoDbAttribute("SerialNumber"))
    String serialNumber;

    @Getter(onMethod_ = @DynamoDbAttribute("DeviceId"))
    String deviceId;

    @Getter(onMethod_ = @DynamoDbAttribute("TenantId"))
    String tenantId;

    @Getter(onMethod_ = @DynamoDbAttribute("ClaimId"))
    String claimId;

    @Getter(onMethod_ = @DynamoDbAttribute("ThingName"))
    String thingName;

    public static String pk(String serialNumber) {
        return "SN#" + serialNumber;
    }

    public static String sk() {
        return "METADATA";
    }

    public static String gsi1Pk(String tenantId) {
        return "TENANT#" + tenantId;
    }

    public static String gsi1Sk(String serialNumber) {
        return "SN#" + serialNumber;
    }

    public static String gsi2Pk(String deviceId) {
        return "DEVICE#" + deviceId;
    }

    public static String gsi2Sk() {
        return "METADATA";
    }

    public static BaseControlPlaneEntity buildBase(String serialNumber, String tenantId, String deviceId) {
        return BaseControlPlaneEntity.builder()
                .pk(pk(serialNumber))
                .sk(sk())
                .entityType(DeviceControlPlaneEntityType.DEVICE)
                .gsi1Pk(gsi1Pk(tenantId))
                .gsi1Sk(gsi1Sk(serialNumber))
                .gsi2Pk(gsi2Pk(deviceId))
                .gsi2Sk(gsi2Sk())
                .createdAt(Instant.now())
                .lastModified(Instant.now())
                .build();
    }
}
