package jct.pillorganizer.global.persistence.entity;

import jct.pillorganizer.global.domain.model.Tenant;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbBean;

@DynamoDbBean
public class TenantEntity extends BaseControlPlaneEntity {

    public static TenantEntity from(Tenant tenant) {
        TenantEntity entity = new TenantEntity();
        entity.setPk(pk(tenant.tenantId()));
        entity.setSk(skMetadata());
        entity.setGsi1Pk(gsi1Pk());
        entity.setGsi1Sk(gsi1Sk(tenant.tenantId()));
        entity.setEntityType(DeviceControlPlaneEntityType.TENANT);

        entity.setTenantId(tenant.tenantId());
        entity.setTenantName(tenant.name());
        entity.setTenantDescription(tenant.description());
        entity.setTenantApiBase(tenant.apiBase());
        entity.setVersion(tenant.version());
        return entity;
    }

    public static Tenant mapToDomain(BaseControlPlaneEntity entity) {
        return new Tenant(entity.getTenantId(), entity.getTenantName(), entity.getTenantDescription(), entity.getTenantApiBase(), entity.getVersion());
    }

    public static String pk(String tenantId) {
        return "TENANT#" + tenantId;
    }
    public static String skMetadata() {
        return "METADATA";
    }
    public static String gsi1Pk() {
        return "TENANT";
    }
    public static String gsi1Sk(String tenantId) {
        return "TENANT#" + tenantId;
    }
}
