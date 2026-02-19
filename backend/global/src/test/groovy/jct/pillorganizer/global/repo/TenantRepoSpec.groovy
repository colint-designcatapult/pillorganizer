package jct.pillorganizer.global.repo

import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.global.model.DeviceControlPlaneEntityType
import jct.pillorganizer.global.model.TenantEntity
import jct.pillorganizer.global.persistence.BaseDeviceControlPlaneSpec
import spock.lang.Shared
import spock.lang.Subject

@MicronautTest
class TenantRepoSpec extends BaseDeviceControlPlaneSpec {

    @Inject
    @Shared
    @Subject
    TenantRepo repo

    def "should get Tenant by id"() {
        given:
        def tenantId = "tenant-1"
        def tenantName = "Test Tenant"
        def tenantApiBase = "http://tenant-api.example"

        this.insertTenant(tenantId, tenantName, tenantApiBase)

        when:
        def tenant = repo.findByTenantId(tenantId)

        then:
        tenant.get().tenantId == tenantId
        tenant.get().tenantName == tenantName
        tenant.get().tenantApiBase == tenantApiBase
    }

    def "should get all Tenants"() {
        given:
        def tenant1Id = "tenant-1"
        def tenant1Name = "Test Tenant 1"
        def tenant1ApiBase = "http://tenant-api-1.example"

        def tenant2Id = "tenant-2"
        def tenant2Name = "Test Tenant 2"
        def tenant2ApiBase = "http://tenant-api-2.example"

        this.insertTenant(tenant1Id, tenant1Name, tenant1ApiBase)
        this.insertTenant(tenant2Id, tenant2Name, tenant2ApiBase)

        when:
        def tenants = repo.findAll()

        then:
        tenants.size() == 2
        tenants.any { it.tenantId == tenant1Id && it.tenantName == tenant1Name && it.tenantApiBase == tenant1ApiBase }
        tenants.any { it.tenantId == tenant2Id && it.tenantName == tenant2Name && it.tenantApiBase == tenant2ApiBase }
    }

    def "should save Tenant"() {
        given:
        def tenantId = "tenant-new"
        def tenantName = "New Tenant"
        def tenantApiBase = "http://new-tenant-api.example"

        def tenant = TenantEntity.builder()
                .base(TenantEntity.buildBase(tenantId))
                .tenantId(tenantId)
                .tenantName(tenantName)
                .tenantApiBase(tenantApiBase)
                .build()

        when:
        repo.save(tenant)

        then:
        def savedTenant = repo.findByTenantId(tenantId)
        savedTenant.get().tenantId == tenantId
        savedTenant.get().tenantName == tenantName
        savedTenant.get().tenantApiBase == tenantApiBase
        savedTenant.get().base.entityType == DeviceControlPlaneEntityType.TENANT
    }

    def "should fail to find non-existent Tenant"() {
        when:
        def tenant = repo.findByTenantId("tenant-does-not-exist")

        then:
        tenant.isEmpty()
    }

}
