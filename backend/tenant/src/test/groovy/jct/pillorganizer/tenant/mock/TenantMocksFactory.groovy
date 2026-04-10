package jct.pillorganizer.tenant.mock

import io.micronaut.context.annotation.Factory
import io.micronaut.context.annotation.Requires
import jakarta.inject.Singleton
import io.micronaut.context.annotation.Replaces
import software.amazon.awssdk.services.iotdataplane.IotDataPlaneClient
import software.amazon.awssdk.services.sns.SnsClient
import spock.mock.DetachedMockFactory

@Factory
@Requires(env = "test")
class TenantMocksFactory {
    DetachedMockFactory mockFactory = new DetachedMockFactory()

    @Singleton
    @Replaces(IotDataPlaneClient)
    IotDataPlaneClient iotDataPlaneClient() {
        return mockFactory.Mock(IotDataPlaneClient)
    }

    @Singleton
    @Replaces(SnsClient)
    SnsClient snsClient() {
        return mockFactory.Mock(SnsClient)
    }
}
