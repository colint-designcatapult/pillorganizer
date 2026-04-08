package jct.pillorganizer.tenant.mock

import io.micronaut.context.annotation.Factory
import io.micronaut.context.annotation.Requires
import jakarta.inject.Singleton
import io.micronaut.context.annotation.Replaces
import software.amazon.awssdk.core.SdkBytes
import software.amazon.awssdk.services.iotdataplane.IotDataPlaneClient
import software.amazon.awssdk.services.iotdataplane.model.UpdateThingShadowRequest
import software.amazon.awssdk.services.iotdataplane.model.UpdateThingShadowResponse
import spock.mock.DetachedMockFactory

@Factory
@Requires(env = "test")
class TenantMocksFactory {
    DetachedMockFactory mockFactory = new DetachedMockFactory()

    @Singleton
    @Replaces(IotDataPlaneClient)
    IotDataPlaneClient iotDataPlaneClient() {
        return [
            updateThingShadow: { args -> UpdateThingShadowResponse.builder().payload(SdkBytes.fromUtf8String("{}")).build() }
        ] as IotDataPlaneClient
    }
}
