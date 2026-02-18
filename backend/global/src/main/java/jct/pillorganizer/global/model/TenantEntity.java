package jct.pillorganizer.global.model;

import lombok.*;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbAttribute;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbBean;

@DynamoDbBean
@EqualsAndHashCode(callSuper = true)
@Data
@AllArgsConstructor
@NoArgsConstructor
public class TenantEntity extends BaseControlPlaneEntity {
    @Getter(onMethod_ = @DynamoDbAttribute("TenantId"))
    private String tenantId;

    @Getter(onMethod_ = @DynamoDbAttribute("TenantName"))
    private String tenantName;

    @Getter(onMethod_ = @DynamoDbAttribute("TenantApiBase"))
    private String tenantApiBase;

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
}
