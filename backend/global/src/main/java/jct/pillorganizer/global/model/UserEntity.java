package jct.pillorganizer.global.model;

import lombok.*;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbAttribute;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbBean;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbFlatten;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbImmutable;

import java.time.Instant;

@Value
@Builder
@DynamoDbImmutable(builder = UserEntity.UserEntityBuilder.class)
public class UserEntity {
    @Getter(onMethod_ = {@DynamoDbFlatten})
    BaseControlPlaneEntity base;

    @Getter(onMethod_ = @DynamoDbAttribute("UserId"))
    String userId;

    @Getter(onMethod_ = @DynamoDbAttribute("UserName"))
    String userName;

    @Getter(onMethod_ = @DynamoDbAttribute("UserSub"))
    String userSub;

    public static String pk(String userId) {
        return "USER#" + userId;
    }

    public static String sk(String userSub) {
        return "SUB#" + userSub;
    }

    public static String gsi1Pk() {
        return "USER";
    }

    public static String gsi1Sk(String userId) {
        return "USER#" + userId;
    }

    public static String gsi2Pk(String userSub) {
        return "SUB#" + userSub;
    }

    public static String gsi2Sk() {
        return "METADATA";
    }

    public static BaseControlPlaneEntity buildBase(String userId, String userSub) {
        return BaseControlPlaneEntity.builder()
                .pk(pk(userId))
                .sk(sk(userSub))
                .entityType(DeviceControlPlaneEntityType.USER)
                .gsi1Pk(gsi1Pk())
                .gsi1Sk(gsi1Sk(userId))
                .gsi2Pk(gsi2Pk(userSub))
                .gsi2Sk(gsi2Sk())
                .createdAt(Instant.now())
                .lastModified(Instant.now())
                .build();
    }
}
