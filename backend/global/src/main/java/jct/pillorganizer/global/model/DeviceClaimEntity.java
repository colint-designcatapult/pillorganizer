package jct.pillorganizer.global.model;

import lombok.*;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbAttribute;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbFlatten;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbImmutable;

import java.time.Instant;

@Value
@Builder(toBuilder = true)
@DynamoDbImmutable(builder = DeviceClaimEntity.DeviceClaimEntityBuilder.class)
public class DeviceClaimEntity {

    @Getter(onMethod_ = {@DynamoDbFlatten})
    BaseControlPlaneEntity base;

    @Getter(onMethod_ = @DynamoDbAttribute("SerialNumber"))
    String serialNumber;

    @Getter(onMethod_ = @DynamoDbAttribute("ClaimId"))
    String claimId;

    @Getter(onMethod_ = @DynamoDbAttribute("ClaimToken"))
    String claimToken;

    @Getter(onMethod_ = @DynamoDbAttribute("UserId"))
    String userId;

    @Getter(onMethod_ = @DynamoDbAttribute("TenantId"))
    String tenantId;

    @Getter(onMethod_ = @DynamoDbAttribute("DeviceId"))
    String deviceId;

    @Getter(onMethod_ = @DynamoDbAttribute("ThingName"))
    String thingName;

    public static String pk(String serialNumber) {
        return "SN#" + serialNumber;
    }

    public static String sk(String claimId) {
        return "CLAIM#" + claimId;
    }

    public static String gsi1Pk(String userId) {
        return "USER#" + userId;
    }

    public static String gsi1Sk(String claimToken) {
        return "CLAIM#" + claimToken;
    }

    public static String gsi2Pk(String deviceId) {
        return "DEVICE#" + deviceId;
    }

    public static String gsi2Sk(String claimId) {
        return "CLAIM#" + claimId;
    }

    public static BaseControlPlaneEntity buildBase(String serialNumber, String claimId, String claimToken, String userId,
                                                   String deviceId) {
        return BaseControlPlaneEntity.builder()
                .pk(pk(serialNumber))
                .sk(sk(claimId))
                .entityType(DeviceControlPlaneEntityType.DEVICE_CLAIM)
                .gsi1Pk(gsi1Pk(userId))
                .gsi1Sk(gsi1Sk(claimToken))
                .gsi2Pk(gsi2Pk(deviceId))
                .gsi2Sk(gsi2Sk(claimId))
                .createdAt(Instant.now())
                .lastModified(Instant.now())
                .build();
    }
}
