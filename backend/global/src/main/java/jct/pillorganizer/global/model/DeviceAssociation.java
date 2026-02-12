package jct.pillorganizer.global.model;

import io.micronaut.serde.annotation.Serdeable;
import lombok.*;
import software.amazon.awssdk.enhanced.dynamodb.extensions.annotations.DynamoDbVersionAttribute;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.*;

import java.time.Instant;

@DynamoDbBean
@Data
@AllArgsConstructor
@NoArgsConstructor
@Serdeable
public class DeviceAssociation {

    @Getter(onMethod_ = {@DynamoDbPartitionKey, @DynamoDbAttribute("DeviceUniqueId")})
    private String deviceUniqueID;

    @Getter(onMethod_ = {@DynamoDbAttribute("TenantId"),
            @DynamoDbSecondaryPartitionKey(indexNames = "DeviceTenantIndex")})
    private String tenantID;

    @Getter(onMethod_ = {@DynamoDbAttribute("ProvisioningStatus"),
            @DynamoDbSecondarySortKey(indexNames = {"DeviceTenant"})})
    private ProvisioningStatus provisioningStatus;

    @Getter(onMethod_ = @DynamoDbAttribute("CreatedAt"))
    private Instant createdAt;

    @Getter(onMethod_ = @DynamoDbAttribute("LastModified"))
    private Instant lastModified;

    @Getter(onMethod_ = @DynamoDbVersionAttribute)
    private Long version;

}
