package jct.pillorganizer.global.model;

import lombok.*;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbAttribute;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbBean;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbFlatten;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbImmutable;

import java.time.Instant;

@Value
@Builder
@DynamoDbImmutable(builder = TenantEntity.TenantEntityBuilder.class)
public class TenantEntity {
    @Getter(onMethod_ = {@DynamoDbFlatten})
    BaseControlPlaneEntity base;

    @Getter(onMethod_ = @DynamoDbAttribute("TenantId"))
    String tenantId;

    @Getter(onMethod_ = @DynamoDbAttribute("TenantName"))
    String tenantName;

    @Getter(onMethod_ = @DynamoDbAttribute("TenantApiBase"))
    String tenantApiBase;

    public static String pk(String tenantId) {
        return "TENANT#" + tenantId;
    }

    public static String sk() {
        return "METADATA";
    }

    public static String gsi1Pk() {
        return "TENANT";
    }

    public static String gsi1Sk(String tenantId) {
        return "TENANT#" + tenantId;
    }

    public static BaseControlPlaneEntity buildBase(String tenantId) {
        return BaseControlPlaneEntity.builder()
                .pk(pk(tenantId))
                .sk(sk())
                .entityType(DeviceControlPlaneEntityType.TENANT)
                .gsi1Pk(gsi1Pk())
                .gsi1Sk(tenantId)
                .createdAt(Instant.now())
                .lastModified(Instant.now())
                .build();
    }
}
