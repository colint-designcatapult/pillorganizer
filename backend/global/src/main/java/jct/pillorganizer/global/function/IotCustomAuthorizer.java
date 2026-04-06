package jct.pillorganizer.global.function;


import io.micronaut.context.ApplicationContext;
import io.micronaut.function.aws.MicronautRequestHandler;
import io.micronaut.serde.ObjectMapper;
import jakarta.inject.Inject;
import jct.pillorganizer.global.function.type.IotCoreCustomAuthorizerEvent;
import jct.pillorganizer.global.function.type.IotCoreCustomAuthorizerResponse;
import jct.pillorganizer.global.function.type.IotCoreProtocolDataHttp;
import jct.pillorganizer.global.function.type.IotCoreProtocolDataMqtt;
import jct.pillorganizer.global.service.IotAuthorizerService;
import lombok.extern.flogger.Flogger;

import java.io.IOException;
import java.time.Duration;
import java.util.List;
import java.util.Optional;

@Flogger
public class IotCustomAuthorizer extends MicronautRequestHandler<IotCoreCustomAuthorizerEvent,
        IotCoreCustomAuthorizerResponse> {

    @Inject
    IotAuthorizerService authorizerService;

    @Inject
    ObjectMapper objectMapper;

    private static final String HEADER_JWT = "x-jwt";
    private static final String HEADER_TENANT = "x-tenant-id";
    private static final String HEADER_DEVICE = "x-device-id";
    private static final IotCoreCustomAuthorizerResponse DENY_RESPONSE = new IotCoreCustomAuthorizerResponse(
            false, null, null, null, null);

    public IotCustomAuthorizer() {
        // Empty ctor for lambda
    }

    @Inject
    public IotCustomAuthorizer(ApplicationContext context, IotAuthorizerService authorizerService,
                               ObjectMapper objectMapper) {
        super(context);
        this.authorizerService = authorizerService;
        this.objectMapper = objectMapper;
    }

    @Override
    public IotCoreCustomAuthorizerResponse execute(IotCoreCustomAuthorizerEvent input) {
        log.atInfo().log("Executing authorizer for connection '%s'", input.connectionMetadata().id());

        if(input.protocolData() == null || input.protocolData().http() == null) {
            log.atInfo().log("HTTP protocol data missing");
            return DENY_RESPONSE;
        }

        IotCoreProtocolDataHttp httpData = input.protocolData().http();
        if(httpData.headers() == null) {
            log.atInfo().log("Missing HTTP headers");
            return DENY_RESPONSE;
        }

        String jwt = httpData.headers().get(HEADER_JWT);
        if(jwt == null) {
            log.atInfo().log("Missing HTTP `%s` header", HEADER_JWT);
            return DENY_RESPONSE;
        }

        String deviceId = httpData.headers().get(HEADER_DEVICE);
        if(deviceId == null) {
            log.atInfo().log("Missing HTTP `%s` header", HEADER_DEVICE);
            return DENY_RESPONSE;
        }

        String tenantId = httpData.headers().get(HEADER_TENANT);
        if(tenantId == null) {
            log.atInfo().log("Missing HTTP `%s` header", HEADER_TENANT);
            return DENY_RESPONSE;
        }

        Optional<IotAuthorizerService.IotAuthorization> authorization =
                this.authorizerService.authorizeIot(jwt, tenantId, deviceId)
                        .blockOptional(Duration.ofSeconds(10));

        return authorization.map(docs -> {
            IotCoreCustomAuthorizerResponse resp = new IotCoreCustomAuthorizerResponse(true, docs.principalId(),
                    docs.policyDocument(), 3600, 300);
            try {
                log.atInfo().log("Custom authorizer returning %s", objectMapper.writeValueAsString(resp));
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
            return resp;
        }).orElse(DENY_RESPONSE);
    }

}
