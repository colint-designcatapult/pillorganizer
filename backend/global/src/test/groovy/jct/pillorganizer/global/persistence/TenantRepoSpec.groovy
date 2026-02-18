package jct.pillorganizer.global.persistence

import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import spock.lang.Shared
import spock.lang.Subject

@MicronautTest
class TenantRepoSpec extends BaseDeviceControlPlaneSpec {

    @Inject
    @Shared
    @Subject
    DynamoDbTenantRepo repo

    def "should get tenant by id"() {
        given:
        def tenantId = "tenant-123"
        insertTenant(tenantId, "Test Tenant", "A test tenant", "https://api.test.com")

        when:
        def result = repo.get(tenantId)

        then:
        result.isPresent()
        with(result.get()) {
            it.tenantId() == tenantId
            it.name() == "Test Tenant"
            it.description() == "A test tenant"
            it.apiBase() == "https://api.test.com"
            it.version() == 1
        }
    }

    def "should return empty when tenant not found"() {
        when:
        def result = repo.get("non-existent-tenant")

        then:
        result.isEmpty()
    }

    def "should find all tenants"() {
        given:
        def tenant1Id = "tenant-1"
        def tenant2Id = "tenant-2"
        
        insertTenant(tenant1Id, "Tenant 1")
        insertTenant(tenant2Id, "Tenant 2")
        insertDevice("dev-1", tenant1Id, "SN-1") // Non-tenant record

        when:
        def result = repo.findAll()

        then:
        result.size() == 2
        result.any { it.tenantId() == tenant1Id }
        result.any { it.tenantId() == tenant2Id }
    }
}
