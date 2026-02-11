package jct.pillorganizer.tenant.auth;

import io.micronaut.aop.InterceptorBean;
import io.micronaut.aop.MethodInterceptor;
import io.micronaut.aop.MethodInvocationContext;
import io.micronaut.core.annotation.AnnotationValue;
import io.micronaut.security.authentication.AuthenticationException;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.tenant.model.device.Device;
import lombok.extern.flogger.Flogger;

import java.util.Objects;


@Singleton
@InterceptorBean(DeviceABAC.class)
@Flogger
public class DeviceABACInterceptor implements MethodInterceptor<Object, Object> {

    @Inject
    AuthService authService;

    @Override
    public Object intercept(MethodInvocationContext<Object, Object> context) {
        for(var pair : context.getParameters().entrySet()) {
            var value = pair.getValue();
            var opt = value.findAnnotation(DeviceABAC.class);
            if(opt.isPresent()) {
                AnnotationValue<DeviceABAC> deviceABAC = opt.get();
                var enumOpt = deviceABAC.enumValue("idType", DeviceABACIDType.class);
                if(enumOpt.isPresent()) {
                    var idType = enumOpt.get();
                    if(Objects.equals(idType, DeviceABACIDType.DEVICE)) {
                        Object id = pair.getValue().getValue();
                        return authorizeByDeviceID(id, context);
                    }
                }
            } else if(value.getType().equals(Device.class)) {
                Device device = (Device) pair.getValue().getValue();
                return authorizeByDeviceID(device.getId(), context);
            }
        }
        throw new AuthenticationException("Failed to find ABAC attribute");
    }

    private Object authorizeByDeviceID(Object id, MethodInvocationContext<Object, Object> context) {
        if(id instanceof Long) {
            return authorizeByDeviceID((long)id, context);
        } else {
            throw new IllegalArgumentException("ID not long");
        }
    }

    private RuntimeException unauthorized() {
        return new AuthenticationException("Access denied to device");
    }

    private Object authorizeByDeviceID(long id, MethodInvocationContext<Object, Object> context) {
        if(context.getReturnType().isReactive()) {
            return authService.accessDeviceAsync(id)
                    .mapNotNull((d) -> {
                        if(d != null) {
                            log.atFinest().log("Authorized user access to device %d", id);
                            return context.proceed();
                        } else {
                            throw unauthorized();
                        }
                    });
        } else {
            if(authService.accessDevice(id) != null) {
                log.atFinest().log("Authorized user access to device %d", id);
                return context.proceed();
            } else {
                throw unauthorized();
            }
        }
    }

}
