package jct.pillorganizer.global.persistence.entity

import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jct.pillorganizer.global.BaseIntegrationSpec
import jct.pillorganizer.global.domain.model.Device
import jct.pillorganizer.global.domain.model.DeviceUserAccess
import jct.pillorganizer.global.domain.model.ManufacturingRecord
import jct.pillorganizer.global.domain.model.ProvisioningStatus
import jct.pillorganizer.global.domain.model.Tenant
import jct.pillorganizer.global.domain.model.User

@MicronautTest
class ControlPlaneEntitySpec extends BaseIntegrationSpec {

    def "should map Tenant entity to and from domain"() {
        given:
        def tenant = new Tenant("tenant-1", "Test Tenant", "Description",
                "https://api.test.com", 1L)

        when:
        def entity = TenantEntity.from(tenant)

        then:
        entity.pk == "TENANT#tenant-1"
        entity.sk == "METADATA"
        entity.gsi1Pk == "TENANT"
        entity.gsi1Sk == "TENANT#tenant-1"
        entity.entityType == DeviceControlPlaneEntityType.TENANT
        entity.tenantId == "tenant-1"
        entity.tenantName == "Test Tenant"
        entity.tenantDescription == "Description"
        entity.tenantApiBase == "https://api.test.com"
        entity.version == 1L

        when:
        def mappedDomain = TenantEntity.mapToDomain(entity)

        then:
        mappedDomain == tenant
    }

    def "should map Device entity to and from domain"() {
        given:
        def device = new Device("dev-1", "tenant-1", "SN-1",
                "MODEL-X", ProvisioningStatus.ACTIVE, 1L)

        when:
        def entity = DeviceEntity.from(device)

        then:
        entity.pk == "DEVICE#dev-1"
        entity.sk == "METADATA"
        entity.gsi1Pk == "TENANT#tenant-1"
        entity.gsi1Sk == "DEVICE#dev-1"
        entity.gsi2Pk == "SN#SN-1"
        entity.gsi2Sk == "DEVICE#dev-1"
        entity.entityType == DeviceControlPlaneEntityType.DEVICE
        entity.deviceId == "dev-1"
        entity.tenantId == "tenant-1"
        entity.serialNumber == "SN-1"
        entity.modelId == "MODEL-X"
        entity.provisioningStatus == ProvisioningStatus.ACTIVE
        entity.version == 1L

        when:
        def mappedDomain = DeviceEntity.mapToDomain(entity)

        then:
        mappedDomain == device
    }

    def "should map ManufacturingRecord entity to and from domain"() {
        given:
        def record = new ManufacturingRecord("SN-1", "MODEL-X", "key-123", "2023-01-01", 1L)

        when:
        def entity = ManufacturingRecordEntity.from(record)

        then:
        entity.pk == "SN#SN-1"
        entity.sk == "METADATA"
        entity.gsi2Pk == "SN#SN-1"
        entity.gsi2Sk == "METADATA"
        entity.entityType == DeviceControlPlaneEntityType.MANUFACTURING_RECORD
        entity.serialNumber == "SN-1"
        entity.modelId == "MODEL-X"
        entity.bootstrapKey == "key-123"
        entity.manufacturingDate == "2023-01-01"
        entity.version == 1L

        when:
        def mappedDomain = ManufacturingRecordEntity.mapToDomain(entity)

        then:
        mappedDomain == record
    }

    def "should map User entity to and from domain"() {
        given:
        def user = new User("user-1", "test@example.com", "Test User", 1L)

        when:
        def entity = UserEntity.from(user)

        then:
        entity.pk == "USER#user-1"
        entity.sk == "METADATA"
        entity.gsi1Pk == "USER#user-1"
        entity.gsi1Sk == "METADATA"
        entity.entityType == DeviceControlPlaneEntityType.USER
        entity.userId == "user-1"
        entity.email == "test@example.com"
        entity.userName == "Test User"
        entity.version == 1L

        when:
        def mappedDomain = UserEntity.mapToDomain(entity)

        then:
        mappedDomain == user
    }

    def "should map DeviceUserAccess entity to and from domain"() {
        given:
        def access = new DeviceUserAccess("user-1", "dev-1", "tenant-1", "SN-1",
                "MODEL-X", "Test User", true, 1L)

        when:
        def entity = DeviceUserAccessEntity.from(access)

        then:
        entity.pk == "DEVICE#dev-1"
        entity.sk == "USER#user-1"
        entity.gsi1Pk == "USER#user-1"
        entity.gsi1Sk == "DEVICE#dev-1"
        entity.entityType == DeviceControlPlaneEntityType.DEVICE_USER_ACCESS
        entity.userId == "user-1"
        entity.deviceId == "dev-1"
        entity.tenantId == "tenant-1"
        entity.serialNumber == "SN-1"
        entity.modelId == "MODEL-X"
        entity.userName == "Test User"
        entity.primaryUser == true
        entity.version == 1L

        when:
        def mappedDomain = DeviceUserAccessEntity.mapToDomain(entity)

        then:
        mappedDomain == access
    }
}
