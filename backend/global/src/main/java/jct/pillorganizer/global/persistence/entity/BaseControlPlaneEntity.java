package jct.pillorganizer.global.persistence.entity;

import io.micronaut.serde.annotation.Serdeable;
import jct.pillorganizer.global.domain.model.*;
import lombok.*;
import software.amazon.awssdk.enhanced.dynamodb.extensions.annotations.DynamoDbVersionAttribute;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.*;

import java.time.Instant;

@DynamoDbBean
@Data
@AllArgsConstructor
@NoArgsConstructor
@Serdeable
public class BaseControlPlaneEntity {

    /**
     * Primary Partition Key (PK).
     * <p>
     * Formats:
     * <ul>
     *   <li>Manufacturing Record: {@code SN#{SerialNumber}}</li>
     *   <li>Tenant: {@code TENANT#{TenantId}}</li>
     *   <li>Device: {@code DEVICE#{DeviceId}}</li>
     *   <li>User: {@code USER#{UserId}}</li>
     *   <li>Device-User Access: {@code DEVICE#{DeviceId}}</li>
     * </ul>
     */
    @Getter(onMethod_ = {@DynamoDbPartitionKey, @DynamoDbAttribute("PK")})
    private String pk;

    /**
     * Primary Sort Key (SK).
     * <p>
     * Formats:
     * <ul>
     *   <li>Manufacturing Record: {@code METADATA}</li>
     *   <li>Tenant: {@code METADATA}</li>
     *   <li>Device: {@code METADATA}</li>
     *   <li>User: {@code METADATA}</li>
     *   <li>Device-User Access: {@code USER#{UserId}}</li>
     * </ul>
     */
    @Getter(onMethod_ = {@DynamoDbSortKey, @DynamoDbAttribute("SK")})
    private String sk;

    /**
     * GSI1 Partition Key: Parent Context Index
     * <p>
     * Formats:
     * <ul>
     *   <li>Manufacturing Record: {@code null}</li>
     *   <li>Tenant: {@code TENANT}</li>
     *   <li>Device: {@code TENANT#{TenantId}}</li>
     *   <li>User: {@code USER#{UserId}}</li>
     *   <li>Device-User Access: {@code USER#{UserId}}</li>
     * </ul>
     */
    @Getter(onMethod_ = {@DynamoDbSecondaryPartitionKey(indexNames = "GSI1"), @DynamoDbAttribute("GSI1_PK")})
    private String gsi1Pk;

    /**
     * GSI1 Sort Key.
     * <p>
     * Formats:
     * <ul>
     *   <li>Manufacturing Record: {@code null}</li>
     *   <li>Tenant: {@code TENANT#{TenantId}</li>
     *   <li>Device: {@code DEVICE#{DeviceId}}</li>
     *   <li>User: {@code METADATA}</li>
     *   <li>Device-User Access: {@code DEVICE#{DeviceId}}</li>
     * </ul>
     */
    @Getter(onMethod_ = {@DynamoDbSecondarySortKey(indexNames = "GSI1"), @DynamoDbAttribute("GSI1_SK")})
    private String gsi1Sk;

    /**
     * GSI2 Partition Key: Secondary Identifier Index
     * <p>
     * Formats:
     * <ul>
     *   <li>Manufacturing Record: {@code SN#{SerialNumber}}</li>
     *   <li>Tenant: {@code null}</li>
     *   <li>Device: {@code SN#{SerialNumber}}</li>
     *   <li>User: {@code null</li>
     *   <li>Device-User Access: {@code null}</li>
     * </ul>
     */
    @Getter(onMethod_ = {@DynamoDbSecondaryPartitionKey(indexNames = "GSI2"), @DynamoDbAttribute("GSI2_PK")})
    private String gsi2Pk;

    /**
     * GSI2 Sort Key.
     * <p>
     * Formats:
     * <ul>
     *   <li>Manufacturing Record: {@code METADATA}</li>
     *   <li>Tenant: {@code null</li>
     *   <li>Device: {@code DEVICE#{DeviceId}}</li>
     *   <li>User: {@code null}</li>
     *   <li>Device-User Access: {@code null}</li>
     * </ul>
     */
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

    // =================================================================

    // Device & Manufacturing Record

    @Getter(onMethod_ = @DynamoDbAttribute("SerialNumber"))
    private String serialNumber;

    @Getter(onMethod_ = @DynamoDbAttribute("ModelId"))
    private String modelId;

    @Getter(onMethod_ = @DynamoDbAttribute("BootstrapKey"))
    private String bootstrapKey;

    @Getter(onMethod_ = @DynamoDbAttribute("ManufacturingDate"))
    private String manufacturingDate;

    @Getter(onMethod_ = @DynamoDbAttribute("DeviceId"))
    private String deviceId;

    @Getter(onMethod_ = @DynamoDbAttribute("TenantId"))
    private String tenantId;

    @Getter(onMethod_ = @DynamoDbAttribute("ProvisioningStatus"))
    private ProvisioningStatus provisioningStatus;

    @Getter(onMethod_ = @DynamoDbAttribute("DeviceName"))
    private String deviceName;

    @Getter(onMethod_ = @DynamoDbAttribute("DeviceDescription"))
    private String deviceDescription;

    // Tenant

    @Getter(onMethod_ = @DynamoDbAttribute("TenantName"))
    private String tenantName;

    @Getter(onMethod_ = @DynamoDbAttribute("TenantDescription"))
    private String tenantDescription;

    @Getter(onMethod_ = @DynamoDbAttribute("TenantApiBase"))
    private String tenantApiBase;

    // User

    @Getter(onMethod_ = @DynamoDbAttribute("UserId"))
    private String userId;

    @Getter(onMethod_ = @DynamoDbAttribute("Email"))
    private String email;

    @Getter(onMethod_ = @DynamoDbAttribute("UserName"))
    private String userName;

    // Device User Access

    @Getter(onMethod_ = @DynamoDbAttribute("PrimaryUser"))
    private Boolean primaryUser;
}
