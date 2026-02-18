package jct.pillorganizer.global.model;

import lombok.*;
import software.amazon.awssdk.enhanced.dynamodb.extensions.annotations.DynamoDbVersionAttribute;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.*;

import java.time.Instant;

@AllArgsConstructor
@NoArgsConstructor
@EqualsAndHashCode
@Setter
public abstract class BaseControlPlaneEntity {
    @Getter(onMethod_ = {@DynamoDbPartitionKey, @DynamoDbAttribute("PK")})
    private String pk;

    @Getter(onMethod_ = {@DynamoDbSortKey, @DynamoDbAttribute("SK")})
    private String sk;

    @Getter(onMethod_ = {@DynamoDbSecondaryPartitionKey(indexNames = "GSI1"), @DynamoDbAttribute("GSI1_PK")})
    private String gsi1Pk;

    @Getter(onMethod_ = {@DynamoDbSecondarySortKey(indexNames = "GSI1"), @DynamoDbAttribute("GSI1_SK")})
    private String gsi1Sk;

    @Getter(onMethod_ = {@DynamoDbSecondaryPartitionKey(indexNames = "GSI2"), @DynamoDbAttribute("GSI2_PK")})
    private String gsi2Pk;

    @Getter(onMethod_ = {@DynamoDbSecondarySortKey(indexNames = "GSI2"), @DynamoDbAttribute("GSI2_SK")})
    private String gsi2Sk;

    @Getter(onMethod_ = @DynamoDbAttribute("EntityType"))
    private DeviceControlPlaneEntityType entityType;

    @Getter(onMethod_ = @DynamoDbAttribute("CreatedAt"))
    private Instant createdAt;

    @Getter(onMethod_ = @DynamoDbAttribute("LastModified"))
    private Instant lastModified;

    @Getter(onMethod_ = {@DynamoDbAttribute("Version"), @DynamoDbVersionAttribute})
    private Long version;
}
