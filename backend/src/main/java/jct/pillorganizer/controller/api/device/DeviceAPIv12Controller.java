package jct.pillorganizer.controller.api.device;

import javax.transaction.Transactional;

import com.google.protobuf.InvalidProtocolBufferException;

import io.micronaut.http.HttpResponse;
import io.micronaut.http.annotation.Body;
import io.micronaut.http.annotation.Consumes;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Post;
import io.micronaut.http.annotation.Produces;
import io.micronaut.protobuf.codec.ProtobufferCodec;
import io.micronaut.security.annotation.Secured;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.inject.Inject;
import jct.pillorganizer.auth.AuthService;
import jct.pillorganizer.auth.DeviceAuthService;
import jct.pillorganizer.device.DeviceStateWrapper;
import jct.pillorganizer.proto.Pill;
import jct.pillorganizer.service.DeviceProvisionService;
import jct.pillorganizer.service.DeviceStateService;
import lombok.extern.flogger.Flogger;

/**
 * Endpoints designed to be called only by pill organizers.
 */
@Controller("/api/v1_2/device")
@Secured({ "device" })
@Flogger
public class DeviceAPIv12Controller {

        @Inject
        DeviceStateService deviceStateService;

        @Inject
        DeviceAuthService deviceAuthService;

        @Inject
        DeviceProvisionService deviceProvisionService;

        @Inject
        AuthService authService;

        @Operation(summary = "Syncs a device's state", description = "Performs a two-way device sync, accepting a device's state, processing events, and returning "
                        +
                        "the server's authoritative state.")
        @Post("/sync")
        @Produces(ProtobufferCodec.PROTOBUFFER_ENCODED)
        @Consumes(ProtobufferCodec.PROTOBUFFER_ENCODED)
        @Secured({ "device" })
        @Transactional
        public HttpResponse<?> sync(@Body byte[] body) throws InvalidProtocolBufferException {
                Pill.SyncRequest req = Pill.SyncRequest.parseFrom(body);
                
                DeviceStateWrapper wrapper = deviceStateService.getDeviceStateWrapperForDeviceSync();
                
                log.atInfo().log("Device initiated sync, id: %d", deviceAuthService.getDeviceID());
                return HttpResponse.ok(wrapper.sync(req).toByteArray());
        }

        @Operation(summary = "Completes the provisioning process", description = "Indicates that the device has been successfully provisioned and connected to WiFi. The "
                        +
                        "device should update its state using the sync response provided by this endpoint.")
        @Post("/provision")
        @Produces(ProtobufferCodec.PROTOBUFFER_ENCODED)
        @Consumes(ProtobufferCodec.PROTOBUFFER_ENCODED)
        @Secured({ "device" })
        public HttpResponse<?> provision(@Body byte[] body) throws InvalidProtocolBufferException {
                Pill.DeviceProvisionRequest req = Pill.DeviceProvisionRequest.parseFrom(body);

                Pill.SyncResponse resp = deviceProvisionService.completeProvisioning(req);
                return HttpResponse.ok(resp.toByteArray());
        }

}