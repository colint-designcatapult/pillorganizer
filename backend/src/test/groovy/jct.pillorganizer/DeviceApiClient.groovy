package jct.pillorganizer

import io.micronaut.http.annotation.Body
import io.micronaut.http.annotation.Consumes
import io.micronaut.http.annotation.Post
import io.micronaut.http.annotation.Produces
import io.micronaut.http.client.annotation.Client
import io.micronaut.protobuf.codec.ProtobufferCodec

@Client
interface DeviceApiClient {

    @Post('http://localhost:8080/api/v1_2/device/provision')
    @Produces(ProtobufferCodec.PROTOBUFFER_ENCODED)
    @Consumes(ProtobufferCodec.PROTOBUFFER_ENCODED)
    byte[] completeProvisioning(@Body byte[] body)

    @Post('http://localhost:8080/api/v1_2/device/auth')
    @Produces(ProtobufferCodec.PROTOBUFFER_ENCODED)
    @Consumes(ProtobufferCodec.PROTOBUFFER_ENCODED)
    byte[] loginDevice(@Body byte[] body);


}
