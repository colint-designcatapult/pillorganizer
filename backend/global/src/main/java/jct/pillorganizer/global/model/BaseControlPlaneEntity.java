package jct.pillorganizer.global.model;

import lombok.*;
import software.amazon.awssdk.enhanced.dynamodb.extensions.annotations.DynamoDbVersionAttribute;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.*;

import java.time.Instant;

@Value
@Builder(toBuilder = true)
@DynamoDbImmutable(builder = BaseControlPlaneEntity.BaseControlPlaneEntityBuilder.class)
public class BaseControlPlaneEntity {
    @Getter(onMethod_ = {@DynamoDbPartitionKey, @DynamoDbAttribute("PK")})
    String pk;

    @Getter(onMethod_ = {@DynamoDbSortKey, @DynamoDbAttribute("SK")})
    String sk;

    @Getter(onMethod_ = {@DynamoDbSecondaryPartitionKey(indexNames = "GSI1"), @DynamoDbAttribute("GSI1_PK")})
    String gsi1Pk;

    @Getter(onMethod_ = {@DynamoDbSecondarySortKey(indexNames = "GSI1"), @DynamoDbAttribute("GSI1_SK")})
    String gsi1Sk;

    @Getter(onMethod_ = {@DynamoDbSecondaryPartitionKey(indexNames = "GSI2"), @DynamoDbAttribute("GSI2_PK")})
    String gsi2Pk;

    @Getter(onMethod_ = {@DynamoDbSecondarySortKey(indexNames = "GSI2"), @DynamoDbAttribute("GSI2_SK")})
    String gsi2Sk;

    @Getter(onMethod_ = @DynamoDbAttribute("EntityType"))
    DeviceControlPlaneEntityType entityType;

    @Getter(onMethod_ = @DynamoDbAttribute("CreatedAt"))
    Instant createdAt;

    @Getter(onMethod_ = @DynamoDbAttribute("LastModified"))
    Instant lastModified;

    @Getter(onMethod_ = {@DynamoDbAttribute("Version"), @DynamoDbVersionAttribute})
    Long version;
}
