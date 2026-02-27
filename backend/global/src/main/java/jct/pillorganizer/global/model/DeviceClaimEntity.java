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

    @Getter(onMethod_ = @DynamoDbAttribute("ClaimToken"))
    String claimToken;

    @Getter(onMethod_ = @DynamoDbAttribute("UserId"))
    String userId;

    @Getter(onMethod_ = @DynamoDbAttribute("TenantId"))
    String tenantId;

    @Getter(onMethod_ = @DynamoDbAttribute("DeviceId"))
    String deviceId;

    public static String pk(String serialNumber) {
        return "SN#" + serialNumber;
    }

    public static String sk(String claimToken) {
        return "CLAIM#" + claimToken;
    }

    public static String gsi1Pk(String userId) {
        return "USER#" + userId;
    }

    public static String gsi1Sk(String claimToken) {
        return "CLAIM#" + claimToken;
    }

    public static BaseControlPlaneEntity buildBase(String serialNumber, String claimToken, String userId) {
        return BaseControlPlaneEntity.builder()
                .pk(pk(serialNumber))
                .sk(sk(claimToken))
                .entityType(DeviceControlPlaneEntityType.DEVICE_CLAIM)
                .gsi1Pk(gsi1Pk(userId))
                .gsi1Sk(gsi1Sk(claimToken))
                .createdAt(Instant.now())
                .lastModified(Instant.now())
                .build();
    }
}
