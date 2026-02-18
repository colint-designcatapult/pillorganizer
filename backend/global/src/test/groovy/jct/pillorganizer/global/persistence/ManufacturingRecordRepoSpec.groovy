package jct.pillorganizer.global.persistence

import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import spock.lang.Shared
import spock.lang.Subject

@MicronautTest
class ManufacturingRecordRepoSpec extends BaseDeviceControlPlaneSpec {

    @Inject
    @Shared
    @Subject
    DynamoDbManufacturingRecordRepo repo

    def "should get manufacturing record by serial number"() {
        given:
        def serialNumber = "SN-123"
        def modelId = "MODEL-A"
        def bootstrapKey = "key-123"
        def manufacturingDate = "2023-01-01"
        
        insertManufacturingRecord(serialNumber, modelId, bootstrapKey, manufacturingDate)

        when:
        def result = repo.get(serialNumber)

        then:
        result.isPresent()
        with(result.get()) {
            it.serialNumber() == serialNumber
            it.modelId() == modelId
            it.bootstrapKey() == bootstrapKey
            it.manufacturingDate() == manufacturingDate
            it.version() == 1
        }
    }

    def "should return empty when manufacturing record not found"() {
        when:
        def result = repo.get("non-existent-sn")

        then:
        result.isEmpty()
    }
}
