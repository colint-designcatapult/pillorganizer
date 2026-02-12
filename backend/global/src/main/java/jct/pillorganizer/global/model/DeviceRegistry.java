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
public class DeviceRegistry {

    @Getter(onMethod_ = {@DynamoDbPartitionKey, @DynamoDbAttribute("SerialNumber")})
    @Setter
    private String serialNumber;

    @Getter(onMethod_ = {@DynamoDbSortKey, @DynamoDbSecondaryPartitionKey(indexNames = "DeviceUniqueIdIndex"),
            @DynamoDbAttribute("DeviceUniqueId")})
    private String deviceUniqueID;

    @Getter(onMethod_ = @DynamoDbAttribute("HardwareRevision"))
    private String hardwareRevision;

    @Getter(onMethod_ = @DynamoDbAttribute("ManufacturingDate"))
    private Instant manufacturingDate;

    @Getter(onMethod_ = @DynamoDbVersionAttribute)
    private Long version;

}
