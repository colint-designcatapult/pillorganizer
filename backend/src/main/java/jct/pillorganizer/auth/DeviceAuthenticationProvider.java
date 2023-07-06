package jct.pillorganizer.auth;

import io.micronaut.context.annotation.Bean;
import io.micronaut.http.HttpRequest;
import io.micronaut.security.authentication.AuthenticationFailureReason;
import io.micronaut.security.authentication.AuthenticationProvider;
import io.micronaut.security.authentication.AuthenticationRequest;
import io.micronaut.security.authentication.AuthenticationResponse;
import jakarta.inject.Inject;
import jct.pillorganizer.model.device.Device;
import jct.pillorganizer.repo.DeviceRepository;
import lombok.extern.flogger.Flogger;
import org.reactivestreams.Publisher;
import reactor.core.publisher.Mono;

import java.util.Base64;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Implements device authentication using their serial number and OOB provisioning key (shared secret). Device users
 * are given usernames in the format "$dev#(SERIAL NUMBER)" and are given the role "device" with the attributes "sn"
 * for the serial number and "id" for the device ID.
 */
@Bean
@Flogger
public class DeviceAuthenticationProvider implements AuthenticationProvider {


    @Inject
    DeviceRepository deviceRepository;

    @Override
    public Publisher<AuthenticationResponse> authenticate(HttpRequest<?> httpReq, AuthenticationRequest<?, ?> authReq) {
        if(!(authReq instanceof DeviceAuthenticationRequest devReq))
            return Mono.empty();

        byte[] oob = devReq.getSecret().getOobKey().toByteArray();
        Optional<Device> dev = deviceRepository.findBySerialNoAndCurrentProvisionOobKey(
                devReq.getIdentity(),
                devReq.getSecret().getOobKey().toByteArray()
        );

        if(dev.isPresent())
            log.atInfo().log("Device %d found", dev.get().getId());
        else
            log.atWarning().log("No device with SN %d found with OOB %s", devReq.getIdentity(), Base64.getEncoder().encodeToString(oob));

        return dev.map(device -> Mono.just(AuthenticationResponse.success(
                "$dev#" + devReq.getIdentity().toString(),
                List.of("device"),
                Map.of("sn", devReq.getIdentity(), "id", device.getId())
        )))
                .orElseGet(() -> Mono.just(AuthenticationResponse.failure(
                        AuthenticationFailureReason.CREDENTIALS_DO_NOT_MATCH)));
    }
}
