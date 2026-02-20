package jct.pillorganizer.global.model;

import lombok.*;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbAttribute;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbBean;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbFlatten;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbImmutable;

import java.time.Instant;

@Value
@Builder
@DynamoDbImmutable(builder = DeviceUserLinkEntity.DeviceUserLinkEntityBuilder.class)
public class DeviceUserLinkEntity {
    @Getter(onMethod_ = {@DynamoDbFlatten})
    BaseControlPlaneEntity base;

    @Getter(onMethod_ = @DynamoDbAttribute("UserId"))
    String userId;

    @Getter(onMethod_ = @DynamoDbAttribute("DeviceId"))
    String deviceId;

    @Getter(onMethod_ = @DynamoDbAttribute("PrimaryUser"))
    Boolean primaryUser;

    @Getter(onMethod_ = @DynamoDbAttribute("TenantId"))
    String tenantId;

    @Getter(onMethod_ = @DynamoDbAttribute("ModelId"))
    String modelId;

    public static String pk(String userId) {
        return "USER#" + userId;
    }

    public static String sk(String deviceId) {
        return "DEVICE#" + deviceId;
    }

    public static String gsi1Pk(String deviceId) {
        return "DEVICE#" + deviceId;
    }

    public static String gsi1Sk(String userId) {
        return "USER#" + userId;
    }

    public static BaseControlPlaneEntity buildBase(String deviceId, String userId) {
        return BaseControlPlaneEntity.builder()
                .pk(pk(userId))
                .sk(sk(deviceId))
                .entityType(DeviceControlPlaneEntityType.DEVICE_USER_LINK)
                .gsi1Pk(gsi1Pk(deviceId))
                .gsi1Sk(gsi1Sk(userId))
                .createdAt(Instant.now())
                .lastModified(Instant.now())
                .build();
    }
}
