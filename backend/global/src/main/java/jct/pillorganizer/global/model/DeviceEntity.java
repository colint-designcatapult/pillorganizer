package jct.pillorganizer.global.model;

import lombok.*;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbAttribute;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbBean;

@DynamoDbBean
@EqualsAndHashCode(callSuper = true)
@Data
@AllArgsConstructor
@NoArgsConstructor
public class DeviceEntity extends BaseControlPlaneEntity {
    @Getter(onMethod_ = @DynamoDbAttribute("DeviceId"))
    private String deviceId;

    @Getter(onMethod_ = @DynamoDbAttribute("SerialNumber"))
    private String serialNumber;

    @Getter(onMethod_ = @DynamoDbAttribute("ModelId"))
    private String modelId;

    @Getter(onMethod_ = @DynamoDbAttribute("BootstrapKey"))
    private String bootstrapKey;

    @Getter(onMethod_ = @DynamoDbAttribute("ProvisioningStatus"))
    private ProvisioningStatus provisioningStatus;

    @Getter(onMethod_ = @DynamoDbAttribute("TenantId"))
    private String tenantId;

    public static String pk(String deviceId) {
        return "DEVICE#" + deviceId;
    }

    public static String sk() {
        return "METADATA";
    }

    public static String gsi1Pk(String tenantId) {
        return "TENANT#" + tenantId;
    }

    public static String gsi1Sk(String deviceId) {
        return "DEVICE#" + deviceId;
    }

    public static String gsi2Pk(String serialNumber) {
        return "SN#" + serialNumber;
    }

    public static String gsi2Sk(String deviceId) {
        return "DEVICE#" + deviceId;
    }

}
