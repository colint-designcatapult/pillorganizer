package jct.pillorganizer.global.model;

import lombok.*;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbAttribute;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbBean;

@DynamoDbBean
@EqualsAndHashCode(callSuper = true)
@Data
@AllArgsConstructor
@NoArgsConstructor
public class DeviceUserLinkEntity extends BaseControlPlaneEntity {
    @Getter(onMethod_ = @DynamoDbAttribute("UserId"))
    private String userId;

    @Getter(onMethod_ = @DynamoDbAttribute("DeviceId"))
    private String deviceId;

    @Getter(onMethod_ = @DynamoDbAttribute("PrimaryUser"))
    private Boolean primaryUser;

    @Getter(onMethod_ = @DynamoDbAttribute("TenantId"))
    private String tenantId;

    @Getter(onMethod_ = @DynamoDbAttribute("ModelId"))
    private String modelId;

    public static String pk(String deviceId) {
        return "DEVICE#" + deviceId;
    }

    public static String sk(String userId) {
        return "USER#" + userId;
    }

    public static String gsi1Pk(String userId) {
        return "USER#" + userId;
    }

    public static String gsi1Sk(String deviceId) {
        return "DEVICE#" + deviceId;
    }
}
